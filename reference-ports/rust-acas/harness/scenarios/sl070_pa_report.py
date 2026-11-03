"""sl070 product-analysis report parity scenarios (WP07).

`sl070` is the P/A code program. Entered cold (which is how the menu always
enters it here) its `init01` sees `file-status (15) = zero` and performs
`p-a-setup`, which **rewrites** the analysis file with the sixteen standard
codes and mirrors each one into the value file with zeroed counters. Only
then does the menu come up. Menu 3 prints the `S` (sales) subset, menu 4
prints everything including the purchase codes and an extra ledger column.

Artifacts under test are `prt-1` (the report), `analysis.dat` and
`value.dat` (dumped to flat streams, F-B007). The setup half is covered by
the same run: the two tables *are* the p-a-setup output.

Screen-driving quirks this scenario encodes:

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter follows it;
* the menu accept is `auto`: the letter alone completes it, so it is sent
  without a trailing CR — a stray CR would end sl070's own menu accept with
  a zero reply and redraw it;
* sl070's menu accept is `auto` too, so `3` / `4` are single bytes, and `9`
  leaves the program afterwards without a CR;
* the report is followed by `call "SYSTEM" using Print-Report`, so the menu
  takes a moment to come back before `9` can be sent.
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
GOLDEN = FIXTURES / "golden" / "sl070"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger; CR pasts sl000's date; L → Set-Up Sales Analysis Codes.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"L")]

# menu 3 = Print P/A records (S ledgeronly), menu 4 = Print All P/A records.
SELECTIONS: dict = {
    "system": [(9.0, b"3")],
    "all": [(9.0, b"4")],
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
    # No analysis/ value tables: sl070's own p-a-setup mints them.
    for stale in ("analysis.dat", "value.dat", "analysis.flat", "value.flat"):
        (ledgers / stale).unlink(missing_ok=True)


def _dump(run_dir: Path, ledgers: Path) -> dict:
    out = run_dir / "artifacts"
    out.mkdir()
    # `prt-1` is assigned relative to the program's cwd, the build tree.
    report = H_BUILD / "prt-1"
    if report.exists():
        shutil.copy2(report, out / "prt-1")

    scratch = run_dir / "dump"
    scratch.mkdir()
    for table, dumper in (("analysis", "dumpsanal"), ("value", "dumpval")):
        source = ledgers / f"{table}.dat"
        if not source.exists():
            (scratch / f"{table}.flat").write_bytes(b"")
            continue
        shutil.copy2(source, scratch / f"{table}.dat")
        _loader(dumper, scratch)
        shutil.copy2(scratch / f"{table}.flat", out / f"{table}.flat")

    return {
        "report_bytes": report.stat().st_size if report.exists() else 0,
        "analysis_rows": (out / "analysis.flat").stat().st_size // 36,
        "value_rows": (out / "value.flat").stat().st_size // 66,
    }


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
    # Leave sl070 with 9, let the menu redraw, then X to leave the ledger.
    keys = HEAD + selection + [(13.5, b"9"), (17.0, b"X\r")]
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, 26.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    counts = _dump(run_dir, ledgers)
    manifest = {
        "scenario": label,
        "text_tail": transcript[-600:].decode("utf-8", "replace"),
        **counts,
    }
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


def _case(name: str, selection: list, label: str):
    def run(run_dir: Path) -> dict:
        _prepare(_ledgers())
        manifest = _drive(run_dir, label, selection)
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, _selection in SELECTIONS.items():
    SCENARIOS[f"sl070-{_name}"] = _case(_name, _selection, f"sl070-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    for artifact in ("prt-1", "analysis.flat", "value.flat"):
        source = run_dir / "artifacts" / artifact
        if source.exists():
            shutil.copy2(source, dest / artifact)
    shutil.copy2(run_dir / "input" / "system.dat", dest / "input-system.dat")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
