"""gl072 batch-update scenarios (menu H, WP08 pass 1).

Menu `H` of `general` runs the posting chain in one breath: `gl070`
pre-processes the open GL batches into `pretrans.tmp`, `gl071` sorts it and
`gl072` applies it to `ledger.dat` and prints the posting report.

Screen-driving quirks this scenario encodes (measured):

* the general menu forces the start-of-day date screen first (`gl000` and
  `general.cbl`'s `menu-reply value "A"`), so entry takes a CR before the
  menu letter;
* the fixture is seeded with `scycle` at 12 rather than earned ("A" of the
  date screen), because `gl070` filters batches on `bcycle` and nothing in
  the chain sets the cycle — DP-021;
* every batch that should post is **closed and waiting**: `gl070` posts nothing
  while an open batch exists, and Phase 1 shows the open ones and leaves. The
  `open` case seeds one to pin that refusal (no report, no ledger change);
* batch 4 is processed and batch 5 is another cycle; their rows stay in
  `posting.dat` and must be skipped by `gl070`;
* batch 6 carries 25 postings (50 legs) against the seeded 48-line page.

Artifacts under test: the `ledger.flat` dump (balances are the only thing
`gl072` writes) and `prt-1`; `batch.flat` is captured so the cleared/posted
stamps are visible.
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
SEED = FIXTURES / "generated" / "setup"
GOLDEN = FIXTURES / "golden" / "gl072"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# System menu A → General; the date screen takes a CR; H posts; X leaves both.
HEAD = [(2.0, b"A\r"), (3.6, b"\r"), (6.5, b"H")]
TAIL = [(30.0, b"X"), (33.0, b"X\r")]
# The `open` case leaves through the batch list instead: X there, X at the
# menu, X at the system menu.
# The Phase 1 screen pages one batch at a time; the open batch is last, so
# five N presses reach it and the transcript records the refusal.
OPEN_TAIL = [(9.0, b"N"), (10.5, b"N"), (12.0, b"N"), (13.5, b"N"),
             (15.0, b"N"), (16.5, b"N"), (18.0, b"X"), (21.0, b"X"),
             (24.0, b"X\r")]

CASES = {
    "post": "ledger, batch and posting fixtures",
    "open": "one open batch stops the run at the Phase 1 screen",
    "empty": "a single waiting batch with no postings",
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


def _prepare(ledgers: Path, case: str) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[20] = 12                  # `scycle` (F-B011) — DP-021
    system[22] = 48                  # `page-lines`; the seed already holds 48
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("ledger.dat", "batch.dat", "posting.dat", "ledger.flat",
                  "batch.flat", "pretrans.tmp", "postrans.tmp"):
        (ledgers / stale).unlink(missing_ok=True)
    for name in ("ledger.flat", "batch.flat", "posting.flat"):
        shutil.copy2(FIXTURES / "generated" / f"gl072-{case}" / name, ledgers / name)
    _loader("loadledger", ledgers)
    _loader("loadbatch", ledgers)
    _loader("loadpost", ledgers)
    (ledgers / "ledger.flat").unlink(missing_ok=True)
    (ledgers / "batch.flat").unlink(missing_ok=True)


def _drive(run_dir: Path, label: str, case: str) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, case)
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
    tail = OPEN_TAIL if case == "open" else TAIL
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, HEAD + tail, 40.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    artifacts = run_dir / "artifacts"
    artifacts.mkdir()
    subprocess.run([str(LOADER / "dumpledger")], cwd=ledgers, check=False,
                   capture_output=True)
    subprocess.run([str(LOADER / "dumpbatch")], cwd=ledgers, check=False,
                   capture_output=True)
    for name in ("ledger.flat", "batch.flat"):
        if (ledgers / name).exists():
            shutil.copy2(ledgers / name, artifacts / name)
    report = H_BUILD / "prt-1"
    if report.exists():
        shutil.copy2(report, artifacts / "prt-1")

    manifest = {
        "scenario": label,
        "ledger_bytes": (ledgers / "ledger.flat").stat().st_size
        if (ledgers / "ledger.flat").exists() else -1,
        "report_bytes": report.stat().st_size if report.exists() else 0,
        "text_tail": transcript[-400:].decode("utf-8", "replace"),
    }
    if GOLDEN.exists():
        for name in ("ledger.flat", "batch.flat", "prt-1"):
            candidate = artifacts / name
            committed = GOLDEN / f"gl072-{case}" / name
            if candidate.exists() and committed.exists():
                manifest[f"sha_{name}"] = (
                    "match" if candidate.read_bytes() == committed.read_bytes()
                    else "DIFF")
    return manifest


def _register() -> None:
    for case, note in CASES.items():
        def run(run_dir: Path, case: str = case, note: str = note) -> dict:
            return _drive(run_dir, f"gl072-{case}: {note}", case)
        SCENARIOS[f"gl072-{case}"] = run


_register()
