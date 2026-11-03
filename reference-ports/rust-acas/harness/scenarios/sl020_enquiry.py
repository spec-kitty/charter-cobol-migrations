"""sl020 sales-ledger enquiry parity scenarios (WP07).

Menu 3 of `sales` opens the enquiry: the customer's header block, a row per
open item, and the ageing totals. The artifact under test is `prt-1` — the
whole report, page block and totals included.

Screen-driving quirks this scenario encodes (measured; F-B015):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter carries it;
* three operator-state bytes are seeded rather than earned: `sales-ledger`
  (byte 560, DP-010's reason), `file-status (19)` (byte 301 — the enquiry
  refuses to run unless a start-of-day has marked the ledger ready) and
  `s-flag-i` (byte 568 — the work-file request). DP-011.
* the customer key and the action letter are both plain accepts, so each is
  sent with a CR;
* `P` prints, `E` leaves the enquiry, `9` leaves the sales menu, `X` the system.
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
CASE = "sl020-enquiry"
GOLDEN = FIXTURES / "golden" / "sl020"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger at the system menu, CR pasts sl000's date, B again → the
# sales menu, 3 → Ledger Enquiry.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"C")]

# customer key, print, leave, leave the menu, leave the system.
def _drive_keys(customer: bytes) -> list:
    return [
        (14.0, customer + b"\r"),
        (17.5, b"P\r"),
        (24.0, b"E\r"),
        (27.0, b"9"),
        (30.0, b"X\r"),
    ]


CASES = {
    "CUST011": (b"CUST011", True),
    "CUST022": (b"CUST022", True),
    "CUST033": (b"CUST033", True),
    "no-match": (b"ZZZZZZ", True),
    "no-work-file": (b"CUST011", False),
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


def _prepare(ledgers: Path, work_file: bool) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[560] = ord("Y")          # `sales-ledger` (F-B011)
    system[301] = ord("1")          # `file-status (19)` — ledger ready
    system[568] = ord("1") if work_file else ord("0")   # `s-flag-i`
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "sales.flat", "openitm3.dat", "openitm3.flat",
                  "invoice.dat", "invoice.flat", "delivery.dat", "delivery.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    for name in ("sales.flat", "openitm3.flat", "invoice.flat"):
        shutil.copy2(FIXTURES / "generated" / CASE / name, ledgers / name)
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)
    _loader("loadoi3", ledgers)
    _loader("loadinv", ledgers)


def _drive(run_dir: Path, label: str, customer: bytes, work_file: bool) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, work_file)
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
    keys = HEAD + _drive_keys(customer)
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, keys[-1][0] + 8.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    report = H_BUILD / "prt-1"
    artifacts = run_dir / "artifacts"
    artifacts.mkdir()
    if report.exists():
        shutil.copy2(report, artifacts / "prt-1")

    manifest = {
        "scenario": label,
        "report_bytes": report.stat().st_size if report.exists() else 0,
        "text_tail": transcript[-400:].decode("utf-8", "replace"),
    }
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


def _case(customer: bytes, work_file: bool, label: str):
    def run(run_dir: Path) -> dict:
        manifest = _drive(run_dir, label, customer, work_file)
        keep = run_dir / "input"
        keep.mkdir()
        for f in ("sales.flat", "openitm3.flat", "invoice.flat"):
            shutil.copy2(FIXTURES / "generated" / CASE / f, keep / f)
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, (_customer, _work) in CASES.items():
    SCENARIOS[f"sl020-{_name}"] = _case(_customer, _work, f"sl020-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    report = run_dir / "artifacts" / "prt-1"
    if report.exists():
        shutil.copy2(report, dest / "prt-1")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
