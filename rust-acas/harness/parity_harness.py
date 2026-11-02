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
    """Slice 0: boot ACAS, expect SY009 env-var abort, capture transcript."""
    result = drive_pty(
        cmd=["./ACAS"],
        cwd=SRC_BUILD,
        keystrokes=[(1.0, b"\r")],   # acknowledge any early prompt
        timeout=6.0,
    )
    (run_dir / "screen.transcript.bin").write_bytes(result)
    manifest = {
        "scenario": "boot",
        "expected": "SY009 environment-variables abort (fresh box, no ACAS_SYS env)",
        "observed_bytes": len(result),
        "observed_text_head": result[:400].decode("utf-8", "replace"),
        "hash_screen": sha256_of(run_dir / "screen.transcript.bin"),
        "contains_SY009": b"SY009" in result,
    }
    (run_dir / "manifest.json").write_text(json.dumps(manifest, indent=2))
    return manifest


def main() -> None:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--scenario", default="boot", choices=["boot"])
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
            print(json.dumps(m, indent=2))
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
