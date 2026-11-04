"""sl095 payment-proof report scenarios (WP07).

Menu J of `sales` runs `sl090` (the sort) and then `sl095` (the proof report) in
the same breath. The artifact under test here is `prt-1` — the report. The
sorted file is captured alongside it as the report's own input, so the Rust
test can replay the exact records COBOL saw.

Screen-driving quirks this scenario encodes (measured; F-B090, F-B095):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter carries it;
* `s-flag-p` (system byte 569) is seeded: without a payment run in progress
  sl090 raises errors 30/15 and exits without touching either file, and sl095
  refuses on the same byte. Nothing in the menu sets it — DP-016/DP-018;
* `sales-ledger` (byte 560) is seeded for DP-010's reason;
* neither program accepts anything, so the case needs no keystrokes between the
  letter and the two letters that leave the menus.

The three cases:

* `proof` — the full report: both buckets, the appropriation sub-lines, the
  customer carry, the unknown-customer literal and the skips;
* `busy` — 26 payments, for the page eject in front of a row and at loop-end;
* `no-flag` — the refusal: no `prt-1` at all.
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
GOLDEN = FIXTURES / "golden" / "sl095"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger at the system menu, CR pasts sl000's date, then J → Payment
# Proof. 9 leaves the sales menu, X the system.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"J")]

# case name -> (dataset directory, flag, label). The refusal case reuses the
# `proof` dataset: with `s-flag-p` clear neither program opens anything, so the
# rows never matter.
CASES = {
    "proof": ("proof", True, "the whole report: both buckets and the sub-lines"),
    "busy": ("busy", True, "26 payments: the page mechanics"),
    "no-flag": ("proof", False, "s-flag-p clear: both programs refuse, no report"),
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


def _prepare(ledgers: Path, dataset: str, flag: bool) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[560] = ord("Y")          # `sales-ledger` (F-B011)
    system[569] = ord("1") if flag else ord("0")   # `s-flag-p` (F-B011)
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "openitm3.dat", "oisort.wrk", "sales.flat", "openitm3.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    source = FIXTURES / "generated" / f"sl095-{dataset}"
    shutil.copy2(source / "sales.flat", ledgers / "sales.flat")
    shutil.copy2(source / "openitm3.flat", ledgers / "openitm3.flat")
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)
    _loader("loadoi3", ledgers)


def _drive(run_dir: Path, label: str, dataset: str, flag: bool) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, dataset, flag)
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

    artifacts = run_dir / "artifacts"
    artifacts.mkdir()
    sorted_file = ledgers / "oisort.wrk"
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


def _case(dataset: str, flag: bool, label: str):
    def run(run_dir: Path) -> dict:
        manifest = _drive(run_dir, label, dataset, flag)
        keep = run_dir / "input"
        keep.mkdir()
        source = FIXTURES / "generated" / f"sl095-{dataset}"
        shutil.copy2(source / "sales.flat", keep / "sales.flat")
        shutil.copy2(source / "openitm3.flat", keep / "openitm3.flat")
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, (_dataset, _flag, _label) in CASES.items():
    SCENARIOS[f"sl095-{_name}"] = _case(_dataset, _flag, _label)


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    for name in ("prt-1", "oisort.wrk"):
        src = run_dir / "artifacts" / name
        if src.exists():
            shutil.copy2(src, dest / name)
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
