"""sl055 extract parity scenarios (WP04).

ACAS opens invoice/value/analysis as INDEXED files, so the flat fixture frames
must be loaded into BDB tables before the COBOL side can run at all — a flat
frame opens with status 35 and the program silently does nothing (F-B007).
The `fixtures/cobol_loader/` helpers do the loading and the dumping; this
scenario drives the order:

    seed system.dat → load analysis/value/invoice → run sl055
    → dump the value + analysis tables back to flat streams

`sl055-seed` runs the program against an EMPTY invoice stream: on first use
sl055 calls sl070, which writes the stock ACAS analysis/value rows. Those rows
are part of the input contract for every later run, so the seed output is
captured once under `fixtures/generated/sl055-seed/` and reused.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

import parity_harness as H

# Own registry rather than H.SCENARIOS: when the harness is executed as a
# script, `import parity_harness` yields a second module instance and the
# decorators would otherwise register into a dict nobody reads.
SCENARIOS: dict = {}


def scenario(name):
    def wrap(fn):
        SCENARIOS[name] = fn
        return fn
    return wrap


ROOT = Path(__file__).resolve().parent.parent.parent      # reference-ports/rust-acas
FIXTURES = ROOT / "fixtures"
LOADER = FIXTURES / "cobol_loader"
SEED = FIXTURES / "generated" / "sl055-seed"
GOLDEN = FIXTURES / "golden" / "sl055"

# ACAS menu path: B (Sales Ledger) → G (Sales Transactions Post = sl055).
# Everything after is ENTER-through of the post-run screens.
MENU_KEYS = [(2.0, b"B\r"), (5.0, b"G\r")] + [(8.0 + i, b"\r") for i in range(20)]


def _loader(name: str, cwd: Path, *args: str) -> None:
    binary = LOADER / name
    if not binary.exists():
        raise SystemExit(f"build the loaders first: {LOADER}/build.sh")
    subprocess.run([str(binary), *args], cwd=cwd, check=True, capture_output=True)


def _ledgers() -> Path:
    ledgers = Path("/tmp/acas-harness-env/ACAS")
    ledgers.mkdir(parents=True, exist_ok=True)
    return ledgers


def _prepare(ledgers: Path, source: Path) -> None:
    """Reset the ledger dir to `source`'s tables as real BDB files."""
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the sl055-seed scenario first")
    shutil.copy2(gold_system, ledgers / "system.dat")

    for stale in ("invoice.dat", "analysis.dat", "value.dat", "openitm2.dat",
                  "invoice.flat", "analysis.flat", "value.flat"):
        (ledgers / stale).unlink(missing_ok=True)

    # The case owns the invoice rows; the tables start from the seed (the
    # stock ACAS analysis/value rows sl070 writes on first use).
    shutil.copy2(source / "invoice.flat", ledgers / "invoice.flat")
    shutil.copy2(SEED / "analysis.flat", ledgers / "analysis.flat")
    shutil.copy2(SEED / "value.flat", ledgers / "value.flat")
    _loader("mkidx", ledgers)
    _loader("loadana", ledgers)
    _loader("loadval", ledgers)
    _loader("loadinv", ledgers)
    (ledgers / "openitm2.dat").write_bytes(b"")


def _dump(run_dir: Path, ledgers: Path) -> dict[str, str]:
    """Copy the produced tables into the run dir and flatten the indexed ones.

    The dumps are the artifact under test: they carry the logical records in
    key order, without the BDB page framing.
    """
    out = run_dir / "artifacts"
    out.mkdir()
    for name in ("openitm2.dat", "value.dat", "analysis.dat"):
        shutil.copy2(ledgers / name, out / name)

    scratch = run_dir / "dump"
    scratch.mkdir()
    shutil.copy2(ledgers / "value.dat", scratch / "value.dat")
    shutil.copy2(ledgers / "analysis.dat", scratch / "analysis.dat")
    _loader("dumpval", scratch)
    _loader("dumpsanal", scratch)

    return {
        "openitm2": H.sha256_of(out / "openitm2.dat"),
        "value": H.sha256_of(scratch / "value.flat"),
        "analysis": H.sha256_of(scratch / "analysis.flat"),
        "value_rows": str((scratch / "value.flat").stat().st_size // 66),
        "openitm2_rows": str((out / "openitm2.dat").stat().st_size // 114),
    }


def _drive(run_dir: Path, label: str) -> dict:
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
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, MENU_KEYS, 30.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    manifest = {
        "scenario": label,
        "text_tail": transcript[-600:].decode("utf-8", "replace"),
        "sl122_shown": b"SL122" in transcript,
        **_dump(run_dir, ledgers),
    }
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


@scenario("sl055-seed")
def scenario_sl055_seed(run_dir: Path) -> dict:
    """First-ever run on an empty invoice stream: sl070 seeds the stock rows."""
    ledgers = _ledgers()
    gold_system = FIXTURES / "generated" / "setup" / "system.dat"
    shutil.copy2(gold_system, ledgers / "system.dat")
    for stale in ("invoice.dat", "analysis.dat", "value.dat", "openitm2.dat",
                  "invoice.flat", "analysis.flat", "value.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    (ledgers / "invoice.flat").write_bytes(b"")
    (ledgers / "analysis.flat").write_bytes(b"")
    (ledgers / "value.flat").write_bytes(b"")
    _loader("mkidx", ledgers)
    _loader("loadana", ledgers)
    _loader("loadval", ledgers)
    _loader("loadinv", ledgers)
    (ledgers / "openitm2.dat").write_bytes(b"")

    manifest = _drive(run_dir, "sl055-seed")

    SEED.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ledgers / "system.dat", SEED / "system.dat")
    for name in ("analysis", "value"):
        shutil.copy2(run_dir / "dump" / f"{name}.flat", SEED / f"{name}.flat")
    (SEED / "invoice.flat").write_bytes(b"")
    (SEED / "openitm2.dat").write_bytes(b"")
    manifest["seeded_to"] = str(SEED)
    return manifest


def _case(name: str):
    def run(run_dir: Path) -> dict:
        source = FIXTURES / "generated" / name
        if not (source / "invoice.flat").exists():
            raise SystemExit(f"generate fixtures first: fdinv2_builder.py {source.parent} {name}")
        ledgers = _ledgers()
        _prepare(ledgers, source)
        manifest = _drive(run_dir, f"sl055-{name}")
        # Overwrite with the case's *starting* tables so the run dir is
        # self-describing: input and produced artifacts side by side.
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(source / "invoice.flat", keep / "invoice.flat")
        shutil.copy2(SEED / "analysis.flat", keep / "analysis.flat")
        shutil.copy2(SEED / "value.flat", keep / "value.flat")
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _case_name in ("clean", "pending", "credit_note", "mixed", "comment_lines"):
    SCENARIOS[f"sl055-{_case_name.replace('_', '-')}"] = _case(_case_name)


def promote(run_dir: Path, case: str) -> Path:
    """Copy a run's produced artifacts into the committed golden tree."""
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(run_dir / "artifacts" / "openitm2.dat", dest / "openitm2.dat")
    shutil.copy2(run_dir / "dump" / "value.flat", dest / "value.flat")
    shutil.copy2(run_dir / "dump" / "analysis.flat", dest / "analysis.flat")
    for f in ("invoice.flat", "analysis.flat", "value.flat"):
        shutil.copy2(run_dir / "input" / f, dest / f"input-{f}")
    return dest


if __name__ == "__main__":                     # promote <run-dir> <case>
    print(promote(Path(sys.argv[1]), sys.argv[2]))
