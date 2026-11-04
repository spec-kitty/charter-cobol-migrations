"""sl090 payment-proof sort scenarios (WP07).

Menu J of `sales` calls `sl090` (the sort) and then `sl095` (the proof report)
in the same breath. The artifact under test is `oisort.wrk` — the sorted
open-item file the sort gives out; the `prt-1` sl095 writes is captured too but
belongs to the sl095 pass.

Screen-driving quirks this scenario encodes (measured; F-B090):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter carries it;
* `s-flag-p` (system byte 569) is seeded: without a payment run in progress
  sl090 raises errors 30/15 and exits without touching either file. Nothing in
  the menu sets it — DP-016;
* `sales-ledger` (byte 560) is seeded for DP-010's reason;
* sl090 accepts nothing, so the case needs no keystrokes between the letter and
  the two letters that leave the menus.

The `batch-zero` case also carries a `(0, 0)` row, which the sort drops, next
to the `(0, n)` rows it keeps.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent      # reference-ports/rust-acas
FIXTURES = ROOT / "fixtures"
LOADER = FIXTURES / "cobol_loader"
SEED = FIXTURES / "generated" / "sl055-seed"
CASE = "sl090-sort"
GOLDEN = FIXTURES / "golden" / "sl090"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger at the system menu, CR pasts sl000's date, then J → Payment
# Proof. 9 leaves the sales menu, X the system.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"J")]

CASES = {
    "sort": (True, "sorted open items — every sort key exercised"),
    "no-flag": (False, "s-flag-p clear: the program refuses and writes nothing"),
}


def _loader(name: str, cwd: Path) -> None:
    binary = LOADER / name
    if not binary.exists():
        raise SystemExit(f"missing loader {name}; build: {LOADER}/build.sh")
    subprocess.run([str(binary)], cwd=cwd, check=True, capture_output=True)


def _ledgers() -> Path:
    ledgers = Path("/tmp/acas-harness-env/ACAS")
    ledgers.mkdir(parents=True, exist_ok=True)
    return ledgers


def _prepare(ledgers: Path, flag: bool) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[560] = ord("Y")          # `sales-ledger` (F-B011)
    system[569] = ord("1") if flag else ord("0")   # `s-flag-p` (F-B011)
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "openitm3.dat", "oisort.wrk", "sales.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    shutil.copy2(FIXTURES / "generated" / CASE / "sales.flat", ledgers / "sales.flat")
    shutil.copy2(FIXTURES / "generated" / CASE / "openitm3.flat", ledgers / "openitm3.flat")
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)
    _loader("loadoi3", ledgers)


def _drive(run_dir: Path, label: str, flag: bool) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, flag)
    env = dict(os.environ)
    home = Path("/tmp/acas-harness-env")
    for sub in ("ACAS", "IRS", "bin"):
        (home / sub).mkdir(parents=True, exist_ok=True)
    env.update({
        "ACAS_LEDGERS": str(home / "ACAS"),
        "ACAS_IRS": str(home / "IRS"),
        "ACAS_BIN": str(home / "bin"),
        "TERM": "xterm-256color",
        "COB_LIBRARY_PATH": ":".join(str(p) for p in [
            H.SRC_BUILD, H.SRC_BUILD / "common", H.SRC_BUILD / "general",
            H.SRC_BUILD / "sales", H.SRC_BUILD / "purchase",
            H.SRC_BUILD / "stock", H.SRC_BUILD / "incomplete_records_system",
        ]),
    })
    keys = HEAD + [(40.0, b"9"), (44.0, b"X\r")]
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, 52.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    sorted_file = ledgers / "oisort.wrk"
    artifacts = run_dir / "artifacts"
    artifacts.mkdir()
    if sorted_file.exists():
        shutil.copy2(sorted_file, artifacts / "oisort.wrk")

    report = H_BUILD / "prt-1"
    if report.exists():
        shutil.copy2(report, artifacts / "prt-1")

    manifest = {
        "scenario": label,
        "sorted_bytes": sorted_file.stat().st_size if sorted_file.exists() else -1,
        "report_bytes": report.stat().st_size if report.exists() else 0,
        "text_tail": transcript[-400:].decode("utf-8", "replace"),
    }
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


def _case(flag: bool, label: str):
    def run(run_dir: Path) -> dict:
        manifest = _drive(run_dir, label, flag)
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(FIXTURES / "generated" / CASE / "sales.flat", keep / "sales.flat")
        shutil.copy2(FIXTURES / "generated" / CASE / "openitm3.flat", keep / "openitm3.flat")
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, (_flag, _label) in CASES.items():
    SCENARIOS[f"sl090-{_name}"] = _case(_flag, _label)


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("oisort.wrk", "prt-1"):
        src = run_dir / "artifacts" / name
        if src.exists():
            shutil.copy2(src, dest / name)
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
