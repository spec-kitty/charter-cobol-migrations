"""sl010 customer-report parity scenarios (WP07).

Menu 4 of `sl010` prints the customer listing: every selected customer as a
name/address pair, then its delivery address block and its notes line when the
record carries the tag. The artifact under test is `prt-1` — the whole report,
including both page ejects.

Screen-driving quirks this scenario encodes (measured; F-B014):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter carries it;
* both menu accepts are `auto` (`sales.cbl` line 375, `sl010` line 528): the
  letter or digit alone completes them, so neither is sent with a CR;
* the selection screen's twelve fields are entered with TAB, in `display-03`
  order, then committed with a bare CR;
* `accept-data` sends a blank `enter-date-in` straight to `main-end` without
  printing, so every case must fill the entry date.
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
CASE = "sl010-report"
GOLDEN = FIXTURES / "golden" / "sl010"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger at the system menu, CR pasts sl000's date, B again →
# Customer File Maintenance at the sales menu, 4 → Print Customer records at
# sl010's own menu. All three menu accepts are `auto`, so no CR follows them.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"B"), (9.4, b"4")]

# One byte per TAB: display-03 fields are cust-in, status, credit, credit-op,
# invoice, invoice-op, average, average-op, overdue, overdue-op, enter-date,
# enter-date-op.
def _tabs(n: int) -> bytes:
    return b"\t" * n


# Entry date in the seed's UK form; an operator on the band where one applies.
DATE = b"01/11/2026"

SELECTIONS: dict = {
    # everything blank but the required entry date: the whole ledger.
    "all": [(10.8, _tabs(10) + DATE)],
    # six-character key probe, no band.
    "key": [(10.8, b"CUSTS2")],
    # live customers only.
    "status-live": [(10.8, b"\t" + b"L")],
    # credit period greater than 20 days.
    "credit-over-20": [(10.8, _tabs(2) + b"20" + b"\t" + b"G")],
    # no key matches.
    "no-match": [(10.8, b"ZZZZZZ")],
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


def _prepare(ledgers: Path) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    # `s-l-exists` gates `slcreate`; the seed leaves `sales-ledger` blank, and
    # a `Y` there would recreate (and so truncate) the tables prepared below.
    system = bytearray(gold_system.read_bytes())
    system[560] = ord("Y")          # `sales-ledger` (F-B011 offset table)
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "sales.flat", "delivery.dat", "delivery.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    shutil.copy2(FIXTURES / "generated" / CASE / "sales.flat", ledgers / "sales.flat")
    shutil.copy2(FIXTURES / "generated" / CASE / "delivery.flat", ledgers / "delivery.flat")
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)
    _loader("loaddel", ledgers)


def _drive(run_dir: Path, label: str, selection: list) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
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
    keys = HEAD + selection
    # Commit the selection with a bare CR, well after the last typed burst.
    keys.append((max(k for k, _ in keys) + 1.8, b"\r"))
    # Let the report spool, return to sl010's menu with 9, leave the ledger.
    keys += [(keys[-1][0] + 22.0, b"9"), (keys[-1][0] + 26.0, b"X\r")]
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, keys[-1][0] + 32.0, env)
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


def _case(name: str, selection: list, label: str):
    def run(run_dir: Path) -> dict:
        _prepare(_ledgers())
        manifest = _drive(run_dir, label, selection)
        keep = run_dir / "input"
        keep.mkdir()
        for f in ("sales.flat", "delivery.flat"):
            shutil.copy2(FIXTURES / "generated" / CASE / f, keep / f)
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, _selection in SELECTIONS.items():
    SCENARIOS[f"sl010-{_name}"] = _case(_name, _selection, f"sl010-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    report = run_dir / "artifacts" / "prt-1"
    if report.exists():
        shutil.copy2(report, dest / "prt-1")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
