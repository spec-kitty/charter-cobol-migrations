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
from collections.abc import Callable
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent
RUNS_DIR = HARNESS_ROOT / "runs"
SRC_BUILD = Path("/tmp/acas-build")

# ---------------------------------------------------------------------------
# Keystroke schedules
# ---------------------------------------------------------------------------
# Offsets are seconds after spawn on the pty.  Screen ACCEPTs in ACAS are
# `with update` (fields pre-filled from the system record), so a bare CR
# keeps the current/initial value.  We only type where the default would
# fail validation:
#   * p-start / p-end      – must be valid UK dates (Date-Form defaults to 1)
#   * Page-Lines 048       – 000 would auto-correct anyway, set explicitly
#   * Current Cycle 12     – nonzero so ACAS.cbl (scycle) believes setup ran
#   * Cycle Period 03      – 3 = Monthly (12-cycle year)
# Every other SYS002 field takes ENTER to keep the zero/space default, which
# the validation blocks then normalise (dates checked, ranges forced etc.).
SETUP_KEYSTROKES: list[tuple[float, bytes]] = [
    # --- SY009 first-run setup gate -------------------------------------
    (1.5, b"Harness Test Co\r"),  # company name
    (2.5, b"\r"),                 # verify name (prefilled Y)
    (3.2, b"\r"),                 # Using General Ledger  (Y)
    (3.6, b"\r"),                 # Using Purchase Ledger (Y)
    (4.0, b"\r"),                 # Using Sales Ledger    (Y)
    (4.4, b"\r"),                 # Using Invoicing       (Y)
    (4.8, b"\r"),                 # Using Stock Control   (Y)
    (5.2, b"\r"),                 # Using Order Entry     (Y)
    (5.8, b"Y\r"),                # confirm setup
    # --- SYS002 Screen 1 : User Data ------------------------------------
    # 6 address-ish fields first (addr1..4, postcode, country) -> skip
    (8.0,  b"\r" * 6),
    (8.3,  b"\r"),                # Date Format      keep 1 (UK)
    (8.6,  b"01/04/2026\r"),      # Period start
    (8.9,  b"31/03/2027\r"),      # Period end
    (9.2,  b"048\r"),             # System Print Lines
    (9.5,  b"\r" * 5),            # VAT rates 1,4,2,5,3 -> 00.00
    (9.8,  b"12\r"),              # Current Cycle (scycle != 0 -> setup done)
    (10.1, b"\r"),                # VAT Reg no   blank
    (10.4, b"\r"),                # VAT Printed  -> forced "N"
    (10.7, b"\r"),                # Current Quarter 00
    (11.0, b"\r"),                # Pass-Word    blank
    (11.3, b"03\r"),              # Cycle Period 03 = Monthly
    (11.6, b"\r"),                # Data File Handling 0 (Cobol files)
    (11.9, b"\r"),                # Dual file type flag  0
    (12.6, b"\r"),                # "User Data Complete" OK to file (prefilled Y)
    # --- SYS002 Screen 2 : OPS Data 1 -----------------------------------
    (15.0, b"\r"),                # host            0 = single user
    (15.3, b"\r"),                # op-system       0 -> forced 6 (Linux)
    (15.6, b"\r"),                # data capture    0 = std
    # op-system resolves to Linux -> ops-data-2 (cups spooler names) accepts
    (16.2, b"\r" * 3),            # spool names 1..3 (blank -> warning only)
    (16.8, b"\r"),                # "OPS Data 1 Complete" verify Y
    # --- SYS002 Screen 4 : G-L Data -------------------------------------
    (19.5, b"\r" * 14),           # all 14 gl-data fields -> defaults
    (20.3, b"\r"),                # "G-L Data Complete" verify Y
    # --- SYS002 Screen 5 : S-L Data 1 -----------------------------------
    (23.0, b"\r" * 15),           # sl-data fields -> defaults
    (23.8, b"\r"),                # "S-L Data Complete" verify Y
    # --- SYS002 Screen 6 : S-L Data 2 -----------------------------------
    (26.0, b"\r" * 4),            # company heading flags -> forced "N"
    (26.6, b"\r"),                # "S-L Data 2 Complete" verify Y
    # --- SYS002 Screen 7 : P-L Data --------------------------------------
    (29.0, b"\r" * 6),            # pl-data fields -> defaults
    (29.6, b"\r"),                # "P-L Data Complete" verify Y
    # --- SYS002 Screen 8 : Stock Data ------------------------------------
    (32.0, b"\r" * 12),           # stock-data fields -> defaults
    (32.8, b"\r"),                # "Stock Data Complete" verify Y
    # --- SYS002 print-params ---------------------------------------------
    (35.5, b"N\r"),               # "Do you want printed copy (Y/N)" -> N
    # --- ACAS main menu ---------------------------------------------------
    # record written, SYS002 exits, ACAS repaints "ACAS System Menu".
    (39.0, b"X\r"),               # exit ACAS cleanly
]

MAINMENU_TIMEOUT = 48.0


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


# Scenario registry: name -> callable(run_dir) -> manifest dict.
# Add new scenarios (sl010, sl910, ...) here and to the argparse choices in
# main(); each entry owns its timeout and keystroke schedule.
SCENARIOS: dict[str, "Callable[[Path], dict]"] = {}


def scenario(name):
    """Decorator registering a scenario under `name`."""
    def wrap(fn):
        SCENARIOS[name] = fn
        return fn
    return wrap


@scenario("boot")
def scenario_boot(run_dir: Path) -> dict:
    """Slice 0: boot ACAS bare; the SY009 env-gate abort is EXPECTED."""
    return _run_and_record(run_dir, "boot", timeout=6.0, keystrokes=[(1.0, b"\r")])


@scenario("mainmenu")
def scenario_mainmenu(run_dir: Path) -> dict:
    """Drive ACAS through first-run setup, all of SYS002, to the main menu.

    Deterministic keystroke schedule (`SETUP_KEYSTROKES` above) passes:
      1. SY009 company/ledger gate
      2. SYS002 Screen 1 "User Data"  (dates, print lines, cycle=12)
      3. SYS002 Screen 2 "OPS Data 1" (+ cups spooler screen forced by Linux)
      4. SYS002 Screens 4-8 "G-L / S-L 1 / S-L 2 / P-L / Stock" data
      5. SYS002 print-params (declined)
      6. ACAS System Menu — entered and exited via "X".
    Deepest state achievable is the ACAS System Menu; after SYS002 writes
    the system record (scycle=12), ACAS.cbl repaints the menu instead of
    re-entering setup.  Golden master should show menu text in the tail.
    """
    return _run_and_record(run_dir, "mainmenu", timeout=MAINMENU_TIMEOUT,
                           keystrokes=SETUP_KEYSTROKES)


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
    if keystrokes is None:
        raise ValueError(f"scenario '{label}' supplied no keystroke schedule")
    result = _drive_pty_env(cmdline, SRC_BUILD, keystrokes, timeout, env)
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
    r.add_argument("--scenario", default="boot", choices=sorted(SCENARIOS))
    r.add_argument("--label", default=None)
    d = sub.add_parser("diff")
    d.add_argument("a")
    d.add_argument("b")
    args = p.parse_args()

    if args.cmd == "run":
        label = args.label or args.scenario
        run_dir = new_run_dir(label)
        m = SCENARIOS[args.scenario](run_dir)
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
