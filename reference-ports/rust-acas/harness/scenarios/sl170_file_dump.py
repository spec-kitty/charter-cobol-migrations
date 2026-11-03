"""sl170 customer-file dump parity scenarios (WP07).

sl170 reads the sales ledger and prints a two-column dump of every customer
the selection admits. The artifact under test is `prt-1` — the whole report,
headers, page ejects and the truncated third column included.

Screen-driving quirks this scenario encodes (measured, see F-B012 Part 4):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter follows it;
* the menu's accept is `auto`: the letter alone completes it, so it is sent
  without a trailing CR — a stray CR would end sl170's screen accept with
  every field still blank;
* the selection screen must be typewritten *after* it is up. Fields are entered
  in order with TAB; each burst stays short because the screen runtime drops
  the last character or two of a long one. The report is committed by the CR.
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
GOLDEN = FIXTURES / "golden" / "sl170"
H_BUILD = Path("/tmp/acas-build")
CASE = "dump"

SCENARIOS: dict = {}

# B → Sales Ledger; CR pasts sl000's date; V → Customer File Dump; then the
# selection, then X to leave the ledger.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"V")]
TAIL = [(12.0, b"X\r")]

# Each selection is (label, [(second, bytes)]) typed into display-03.
SELECTIONS: dict = {
    "all": [],
    "key": [(8.0, b"CUSTD3")],
    "status-dormant": [(8.0, b"\tD")],
    "credit-under-40": [(8.0, b"\t\t40"), (9.4, b"\tL")],
    "credit-over-40": [(8.0, b"\t\t40"), (9.4, b"\tG")],
    "activity-over-10": [(8.0, b"\t\t\t\t00010"), (9.6, b"\tG")],
    "average-under-1000": [(8.0, b"\t\t\t\t\t\t01000"), (9.8, b"\tL")],
    "overdue-over-100": [(8.0, b"\t\t\t\t\t\t\t\t00100"), (10.0, b"\tG")],
    "no-match": [(8.0, b"ZZZZ")],
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
    shutil.copy2(gold_system, ledgers / "system.dat")
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "sales.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    shutil.copy2(FIXTURES / "generated" / CASE / "sales.flat", ledgers / "sales.flat")
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)


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
    keys.append((max(k for k, _ in keys) + 1.6, b"\r"))
    keys += TAIL
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


def _case(name: str, selection: list, label: str):
    def run(run_dir: Path) -> dict:
        _prepare(_ledgers())
        manifest = _drive(run_dir, label, selection)
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(FIXTURES / "generated" / CASE / "sales.flat", keep / "sales.flat")
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, _selection in SELECTIONS.items():
    SCENARIOS[f"sl170-{_name}"] = _case(_name, _selection, f"sl170-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    report = run_dir / "artifacts" / "prt-1"
    if report.exists():
        shutil.copy2(report, dest / "prt-1")
    for f in ("sales.flat", "system.dat"):
        shutil.copy2(run_dir / "input" / f, dest / f"input-{f}")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
