"""sl055 → sl060 chained posting scenarios (WP05).

`sales.cbl` `load07` runs `sl055` and then `sl060` without returning to the
menu, so on the COBOL side the two halves are one keystroke sequence. The
scenario therefore has to carry sl055 to completion, answer sl060's
"OK to post Sales transactions (YES/NO)?" prompt, and then let the posting
report finish.

Artifacts under test are the four things sl060 writes:

    salesled.dat   the rewritten sales rows
    openitm3.dat   the open-item ledger (OTM2 bytes, key order)
    posting.dat    one GL posting per open item
    batch.dat      the sales batch header

plus `prt-1`, the posting report. All indexed/relative tables are dumped to
flat streams so the hashes cover logical records, not BDB pages (F-B007).
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
GOLDEN = FIXTURES / "golden" / "sl060"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

MENU_KEYS = (
    [(2.0, b"B\r"), (5.0, b"G\r")]                       # Sales → post transactions
    + [(8.0 + i, b"\r") for i in range(18)]              # sl055 screens
    + [(26.0, b"YES\r")]                                 # sl060: OK to post?
    + [(28.0 + i * 2.0, b"\r") for i in range(12)]       # report + return
)


def _loader(name: str, cwd: Path) -> None:
    binary = LOADER / name
    if not binary.exists():
        raise SystemExit(f"missing loader {name}; build: {LOADER}/build.sh")
    subprocess.run([str(binary)], cwd=cwd, check=True, capture_output=True)


def _ledgers() -> Path:
    ledgers = Path("/tmp/acas-harness-env/ACAS")
    ledgers.mkdir(parents=True, exist_ok=True)
    return ledgers


def _prepare(ledgers: Path, source: Path) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the sl055-seed scenario first")
    shutil.copy2(gold_system, ledgers / "system.dat")
    (H_BUILD / "prt-1").unlink(missing_ok=True)

    for stale in ("invoice.dat", "analysis.dat", "value.dat", "openitm2.dat",
                  "openitm3.dat", "salesled.dat", "posting.dat", "batch.dat",
                  "prt-1", "invoice.flat", "analysis.flat", "value.flat",
                  "sales.flat"):
        (ledgers / stale).unlink(missing_ok=True)

    shutil.copy2(source / "invoice.flat", ledgers / "invoice.flat")
    shutil.copy2(SEED / "analysis.flat", ledgers / "analysis.flat")
    shutil.copy2(SEED / "value.flat", ledgers / "value.flat")
    shutil.copy2(source / "sales.flat", ledgers / "sales.flat")
    _loader("mkidx", ledgers)
    _loader("loadana", ledgers)
    _loader("loadval", ledgers)
    _loader("loadinv", ledgers)
    _loader("loadsal", ledgers)
    (ledgers / "openitm2.dat").write_bytes(b"")


def _dump(run_dir: Path, ledgers: Path) -> dict:
    out = run_dir / "artifacts"
    out.mkdir()
    # The report is assigned `prt-1` relative to the program's cwd, which is
    # the build tree, not the ledger dir.
    report = H_BUILD / "prt-1"
    if report.exists():
        shutil.copy2(report, out / "prt-1")

    scratch = run_dir / "dump"
    scratch.mkdir()
    dumpers = {"salesled": "dumpsales", "openitm3": "dumpoi3",
               "posting": "dumppost", "batch": "dumpbatch"}
    for table, dumper in dumpers.items():
        source = ledgers / f"{table}.dat"
        if not source.exists():
            (scratch / f"{table}.flat").write_bytes(b"")
            continue
        shutil.copy2(source, scratch / f"{table}.dat")
        _loader(dumper, scratch)

    return {
        "salesled": (scratch / "salesled.flat").stat().st_size,
        "openitm3_rows": (scratch / "openitm3.flat").stat().st_size // 114,
        "posting_rows": (scratch / "posting.flat").stat().st_size // 98,
        "batch_rows": (scratch / "batch.flat").stat().st_size // 96,
    }


def _drive(run_dir: Path, label: str) -> dict:
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
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, MENU_KEYS, 70.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    counts = _dump(run_dir, ledgers)
    manifest = {"scenario": label, "text_tail": transcript[-600:].decode("utf-8", "replace"),
                **counts}
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


def _case(name: str):
    def run(run_dir: Path) -> dict:
        source = FIXTURES / "generated" / name
        for needed in ("invoice.flat", "sales.flat"):
            if not (source / needed).exists():
                raise SystemExit(f"generate fixtures first: {source}")
        ledgers = _ledgers()
        _prepare(ledgers, source)
        manifest = _drive(run_dir, f"sl060-{name}")
        keep = run_dir / "input"
        keep.mkdir()
        for f in ("invoice.flat", "analysis.flat", "value.flat", "sales.flat", "system.dat"):
            origin = SEED / f if f in ("analysis.flat", "value.flat", "system.dat") else source / f
            shutil.copy2(origin, keep / f)
        return manifest
    return run


for _case_name in ("clean", "credit_note", "mixed", "pending", "comment_lines"):
    SCENARIOS[f"sl060-{_case_name.replace('_', '-')}"] = _case(_case_name)


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    for table in ("salesled", "openitm3", "posting", "batch"):
        flat = run_dir / "dump" / f"{table}.flat"
        if flat.exists():
            shutil.copy2(flat, dest / f"{table}.flat")
    if (run_dir / "artifacts" / "prt-1").exists():
        shutil.copy2(run_dir / "artifacts" / "prt-1", dest / "prt-1")
    for f in ("invoice.flat", "analysis.flat", "value.flat", "sales.flat", "system.dat"):
        shutil.copy2(run_dir / "input" / f, dest / f"input-{f}")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
