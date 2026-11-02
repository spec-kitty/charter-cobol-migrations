#!/usr/bin/env python3
"""ACAS parity harness — Phase 1 (Slice 0 smoke).

Drives the compiled COBOL ACAS in a controlled environment:
  - builds in an isolated sandbox dir
  - seeds environment variables ACAS expects (file paths)
  - drives interactive screens via pty + pre-programmed keystroke script
  - captures all outputs: screen transcript, ISAM file diffs, print-spool files
  - stores run artifacts as golden masters

Usage:
  python3 harness.py run --scenario boot
  python3 harness.py diff <runA> <runB>

The harness assumes /tmp/acas-build already contains compiled binaries.
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import pty
import hashlib
import select
import shutil
import subprocess
import sys
import time
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent
RUNS_DIR = HARNESS_ROOT / "runs"
SRC_BUILD = Path("/tmp/acas-build")


def sha256_of(p: Path) -> str:
    h = hashlib.sha256()
    h.update(p.read_bytes())
    return h.hexdigest()


def snapshot_tree(root: Path) -> dict[str, str]:
    """Map relative path -> sha256 for every file in root."""
    out: dict[str, str] = {}
    for p in sorted(root.rglob("*")):
        if p.is_file():
            out[str(p.relative_to(root))] = sha256_of(p)
    return out


def new_run_dir(label: str) -> Path:
    ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    d = RUNS_DIR / f"{ts}-{label}"
    d.mkdir(parents=True, exist_ok=False)
    return d


def drive_pty(cmd: list[str], cwd: Path, keystrokes: list[tuple[float, bytes]],
              timeout: float = 20.0) -> bytes:
    """Run cmd attached to a pty, injecting keystrokes at scheduled offsets."""
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(cwd)
        os.execvp(cmd[0], cmd)
    transcript = bytearray()
    t0 = time.monotonic()
    idx = 0
    while True:
        now = time.monotonic() - t0
        while idx < len(keystrokes) and now >= keystrokes[idx][0]:
            try:
                os.write(fd, keystrokes[idx][1])
            except OSError:
                pass
            idx += 1
        if now > timeout:
            break
        r, _, _ = select.select([fd], [], [], 0.2)
        if fd in r:
            try:
                chunk = os.read(fd, 4096)
            except OSError:
                break
            if not chunk:
                break
            transcript.extend(chunk)
    try:
        os.close(fd)
    except OSError:
        pass
    try:
        os.kill(pid, 9)
    except ProcessLookupError:
        pass
    os.waitpid(pid, 0)
    return bytes(transcript)


def scenario_boot(run_dir: Path) -> dict:
    """Slice 0: boot ACAS bare; the SY009 env-gate abort is EXPECTED."""
    return _run_and_record(run_dir, "boot", timeout=6.0)


def scenario_mainmenu(run_dir: Path) -> dict:
    """Drive ACAS through first-run setup and reach the main menu.

    Deterministic keystroke schedule derived from reading setup code:
      1. company name (ACAS Harness Ltd.)
      2. verify Y (single-char field, ENTER)
      3. six ledger Y/N toggles — all Y (single-char update accepts at fields)
      4. confirm Y
      5. wait for main menu to paint
      6. nothing more: capture the painted menu as golden master.
    """
    ks = [
        (1.5, b"Harness Test Co\r"),
        (2.5, b"\r"),        # confirm company name (prefilled Y)
        (3.2, b"\r"),        # using GL
        (3.6, b"\r"),        # using Purchase
        (4.0, b"\r"),        # using Sales
        (4.4, b"\r"),        # using Invoicing
        (4.8, b"\r"),        # using Stock
        (5.2, b"\r"),        # using Order Entry
        (5.8, b"Y\r"),       # confirm setup
    ]
    return _run_and_record(run_dir, "mainmenu", timeout=15.0, keystrokes=ks)


def drive_cfg(scenario: str) -> tuple[list[tuple[float, bytes]], float]:
    return {
        "boot": ([(1.0, b"\r")], 6.0),
        "mainmenu": ([(3.0, b"X\r")], 10.0),
    }[scenario]


def _run_and_record(run_dir: Path, label: str, timeout: float,
                    keystrokes: list[tuple[float, bytes]] | None = None) -> dict:
    env = dict(os.environ)
    # Synthesize harness env inline (no shell sourcing needed)
    home = Path("/tmp/acas-harness-env")
    for sub in ("ACAS", "IRS", "bin"):
        (home / sub).mkdir(parents=True, exist_ok=True)
    env.update({
        "ACAS_LEDGERS": str(home / "ACAS"),
        "ACAS_IRS": str(home / "IRS"),
        "ACAS_BIN": str(home / "bin"),
        "TERM": "xterm-256color",
        # libcob module search: ACAS CALLs plain module names; every subsystem
        # dir under the build tree plus cwd.
        "COB_LIBRARY_PATH": ":".join(
            str(p) for p in [
                SRC_BUILD,
                SRC_BUILD / "common",
                SRC_BUILD / "general",
                SRC_BUILD / "sales",
                SRC_BUILD / "purchase",
                SRC_BUILD / "stock",
                SRC_BUILD / "incomplete_records_system",
            ]
        ),
    })
    if label == "boot":
        # boot = NO env; verify the gate fires
        for k in ("ACAS_LEDGERS", "ACAS_IRS", "ACAS_BIN"):
            env.pop(k, None)
    cmdline = ["./ACAS"]
    if label != "boot" and False:
        cmdline = ["./ACAS"]  # override via env first
    result = _drive_pty_env(cmdline, SRC_BUILD, keystrokes or drive_cfg(label)[0],
                            timeout, env)
    (run_dir / "screen.transcript.bin").write_bytes(result)
    files_after = snapshot_tree(SRC_BUILD)
    manifest = {
        "scenario": label,
        "observed_bytes": len(result),
        "text_heads": result[-800:].decode("utf-8", "replace"),
        "hash_screen": sha256_of(run_dir / "screen.transcript.bin"),
        "sy009_abort": b"SY009" in result,
        "file_hashes": files_after,
    }
    (run_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    return manifest


def _drive_pty_env(cmd: list[str], cwd: Path, keystrokes: list[tuple[float, bytes]],
                   timeout: float, env: dict) -> bytes:
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(cwd)
        os.execvpe(cmd[0], cmd, env)
    transcript = bytearray()
    t0 = time.monotonic()
    idx = 0
    while True:
        now = time.monotonic() - t0
        while idx < len(keystrokes) and now >= keystrokes[idx][0]:
            try:
                os.write(fd, keystrokes[idx][1])
            except OSError:
                pass
            idx += 1
        if now > timeout:
            break
        r, _, _ = select.select([fd], [], [], 0.2)
        if fd in r:
            try:
                chunk = os.read(fd, 4096)
            except OSError:
                break
            if not chunk:
                break
            transcript.extend(chunk)
    try:
        os.close(fd)
    except OSError:
        pass
    try:
        os.kill(pid, 9)
    except ProcessLookupError:
        pass
    os.waitpid(pid, 0)
    return bytes(transcript)


def main() -> None:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--scenario", default="boot", choices=["boot", "mainmenu"])
    r.add_argument("--label", default=None)
    d = sub.add_parser("diff")
    d.add_argument("a")
    d.add_argument("b")
    args = p.parse_args()

    if args.cmd == "run":
        label = args.label or args.scenario
        run_dir = new_run_dir(label)
        if args.scenario == "boot":
            m = scenario_boot(run_dir)
        elif args.scenario == "mainmenu":
            m = scenario_mainmenu(run_dir)
        else:
            raise SystemExit(f"unknown scenario {args.scenario}")
        print(json.dumps({k: v for k, v in m.items() if k != "file_hashes"}, indent=2))
        print(f"\nrun dir: {run_dir}")
    elif args.cmd == "diff":
        a_dir = RUNS_DIR / args.a
        b_dir = RUNS_DIR / args.b
        sa = snapshot_tree(a_dir)
        sb = snapshot_tree(b_dir)
        keys = sorted(set(sa) | set(sb))
        for k in keys:
            ha, hb = sa.get(k), sb.get(k)
            status = "same" if ha == hb else ("ADDED" if ha is None else ("REMOVED" if hb is None else "DIFF"))
            print(f"{status:8s} {k}")


if __name__ == "__main__":
    main()
