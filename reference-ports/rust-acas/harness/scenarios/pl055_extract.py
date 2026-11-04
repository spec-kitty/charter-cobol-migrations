"""pl055 extract parity scenarios (WP09).

`purchase.cbl` `load08` (menu H) runs `pl055` and then `pl060` in one breath —
the extract and the posting are one keystroke on the COBOL side. The artifacts
under test here are pl055's own:

    pinvoice.flat  the invoice file after pl055's rewrites (`ih-status`/`il-
                   update` set to `z`), dumped in key order
    openitm4.dat   the staged open-item-4 headers
    value.flat     the value table, dumped in key order
    analysis.flat  the analysis table, dumped in key order
    counters.flat  the two system month counters pl055 moves (F-B055 Part 5)

pl060 runs afterwards and leaves its own artifacts (purchled, post, batch,
`prt-1`); they are not gated on in this pass.

Two seeded facts:

* `p-flag-i` (system byte 499) must be 1 or `load08` refuses with error 14 and
  never calls the program — nothing in the menu chain sets it (DP-026).
* `scycle` must be nonzero or `purchase.cbl` diverts into `sys002` setup.

The analysis/value tables are seeded from the fixture rather than earned,
because pl055 has no first-use seeder (`pl130` is the real one and is not
ported — DP-025).
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

import parity_harness as H

SCENARIOS: dict = {}


def scenario(name):
    def wrap(fn):
        SCENARIOS[name] = fn
        return fn
    return wrap


ROOT = Path(__file__).resolve().parent.parent.parent      # reference-ports/rust-acas
FIXTURES = ROOT / "fixtures"
LOADER = FIXTURES / "cobol_loader"
SEED_SYSTEM = FIXTURES / "generated" / "setup" / "system.dat"
GOLDEN = FIXTURES / "golden" / "pl055"
H_BUILD = Path("/tmp/acas-build")

# ACAS menu path: C (+CR) → Purchase Ledger, then H (Invoice post extract,
# pl055 + pl060). Both menu letters are `accept ... auto`, so H carries no CR.
# Everything after is ENTER-through of pl055's screens, then pl060's YES/NO.
HEAD = [(2.0, b"C\r"), (3.6, b"\r"), (6.5, b"H")]
TAIL = [(46.0, b"NO\r"), (50.0, b"X"), (54.0, b"X\r")]
MENU_KEYS = HEAD + [(9.0 + i * 1.5, b"\r") for i in range(22)] + TAIL


def _loader(name: str, cwd: Path) -> None:
    binary = LOADER / name
    if not binary.exists():
        raise SystemExit(f"build the loaders first: {LOADER}/build.sh")
    subprocess.run([str(binary)], cwd=cwd, check=True, capture_output=True)


def _ledgers() -> Path:
    ledgers = Path("/tmp/acas-harness-env/ACAS")
    ledgers.mkdir(parents=True, exist_ok=True)
    return ledgers


def _prepare(ledgers: Path, source: Path) -> None:
    """Reset the ledger dir to the case's tables as real BDB files."""
    if not SEED_SYSTEM.exists():
        raise SystemExit("no setup golden; run the setup-clean scenario first")
    system = bytearray(SEED_SYSTEM.read_bytes())
    system[317] = ord("1")           # `B-L` level-2 — the purchase menu gate
    system[499] = ord("1")           # `p-flag-i` — load08's own gate (DP-026)
    system[308] = ord("1")           # `file-status (26)` — invoice file ready
    # pl055 exits straight away (error 29) unless the value and analysis files
    # were already open from an earlier program; nothing in the purchase menu
    # opens them first, so their status bytes are seeded too (DP-026).
    system[295] = ord("1")           # `file-status (13)` — value file
    system[297] = ord("1")           # `file-status (16)`… pl055 tests (15)
    (ledgers / "system.dat").write_bytes(bytes(system))

    for stale in ("pinvoice.dat", "analysis.dat", "value.dat", "openitm4.dat",
                  "pinvoice.flat", "analysis.flat", "value.flat", "openitm4.flat",
                  "purchled.dat", "posting.dat", "batch.dat", "purchase.flat"):
        (ledgers / stale).unlink(missing_ok=True)

    (H_BUILD / "prt-1").unlink(missing_ok=True)
    shutil.copy2(source / "purchase.flat", ledgers / "purchase.flat")
    shutil.copy2(source / "pinvoice.flat", ledgers / "pinvoice.flat")
    shutil.copy2(source / "analysis.flat", ledgers / "analysis.flat")
    shutil.copy2(source / "value.flat", ledgers / "value.flat")
    _loader("mkpldx", ledgers)
    _loader("mkidx", ledgers)
    _loader("loadana", ledgers)
    _loader("loadval", ledgers)
    _loader("loadpur", ledgers)
    _loader("loadpinv", ledgers)


def _dump(run_dir: Path, ledgers: Path) -> dict[str, str]:
    out = run_dir / "artifacts"
    out.mkdir()
    shutil.copy2(ledgers / "openitm4.dat", out / "openitm4.dat")
    if (H_BUILD / "prt-1").exists():
        shutil.copy2(H_BUILD / "prt-1", out / "prt-1")

    # The two month counters of system-record-4 (pl-invoices/pl-credit-notes,
    # bytes 3176..3187, s9(8)v99 comp-3 each) — F-B055 Part 5. They are the one
    # thing pl055 moves that lives outside the four dumped files.
    system = (ledgers / "system.dat").read_bytes()
    (out / "counters.flat").write_bytes(system[3176:3188])

    scratch = run_dir / "dump"
    scratch.mkdir()
    shutil.copy2(ledgers / "pinvoice.dat", scratch / "pinvoice.dat")
    shutil.copy2(ledgers / "value.dat", scratch / "value.dat")
    shutil.copy2(ledgers / "analysis.dat", scratch / "analysis.dat")
    _loader("dumppinv", scratch)
    _loader("dumpval", scratch)
    _loader("dumpsanal", scratch)

    return {
        "pinvoice": H.sha256_of(scratch / "pinvoice.flat"),
        "openitm4": H.sha256_of(out / "openitm4.dat"),
        "value": H.sha256_of(scratch / "value.flat"),
        "analysis": H.sha256_of(scratch / "analysis.flat"),
        "counters": H.sha256_of(out / "counters.flat"),
        "prt-1": H.sha256_of(out / "prt-1") if (out / "prt-1").exists() else "",
        "pinvoice_rows": str((scratch / "pinvoice.flat").stat().st_size // 129),
        "openitm4_rows": str((out / "openitm4.dat").stat().st_size // 109),
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
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, MENU_KEYS, 70.0, env)
    (run_dir / "screen.transcript.bin").write_bytes(transcript)

    manifest = {
        "scenario": label,
        "text_tail": transcript[-600:].decode("utf-8", "replace"),
        "pl201_shown": b"PL201" in transcript,
        **_dump(run_dir, ledgers),
    }
    (run_dir / "manifest.json").write_text(H.json.dumps(manifest, indent=2))
    return manifest


def _case(name: str):
    def run(run_dir: Path) -> dict:
        source = FIXTURES / "generated" / f"pl055-{name.replace('_', '-')}"
        if not (source / "pinvoice.flat").exists():
            raise SystemExit(f"generate fixtures first: pl055_invoice_builder.py {source.parent}")
        ledgers = _ledgers()
        _prepare(ledgers, source)
        manifest = _drive(run_dir, f"pl055-{name}")
        keep = run_dir / "input"
        keep.mkdir()
        for f in ("pinvoice.flat", "analysis.flat", "value.flat", "purchase.flat"):
            shutil.copy2(source / f, keep / f)
        shutil.copy2(ledgers / "system.dat", keep / "system.dat")
        return manifest
    return run


for _case_name in ("clean", "credit_note", "mixed", "empty"):
    SCENARIOS[f"pl055-{_case_name.replace('_', '-')}"] = _case(_case_name)


def promote(run_dir: Path, case: str) -> Path:
    """Copy a run's produced artifacts into the committed golden tree."""
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(run_dir / "dump" / "pinvoice.flat", dest / "pinvoice.flat")
    shutil.copy2(run_dir / "artifacts" / "openitm4.dat", dest / "openitm4.dat")
    shutil.copy2(run_dir / "dump" / "value.flat", dest / "value.flat")
    shutil.copy2(run_dir / "dump" / "analysis.flat", dest / "analysis.flat")
    shutil.copy2(run_dir / "artifacts" / "counters.flat", dest / "counters.flat")
    if (run_dir / "artifacts" / "prt-1").exists():
        shutil.copy2(run_dir / "artifacts" / "prt-1", dest / "prt-1")
    return dest


if __name__ == "__main__":                     # promote <run-dir> <case>
    print(promote(Path(sys.argv[1]), sys.argv[2]))
