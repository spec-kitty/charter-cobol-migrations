"""pl050 purchase invoice-proof scenarios (WP09).

Menu G of `purchase` opens the proof: one row per unapplied invoice header of
any type, its analysis lines, the prompt-pay and carriage block, and the three
group totals. The artifact under test is `prt-1`.

Screen-driving quirks this scenario encodes (measured; F-B050):

* the system menu letter is `C` and both letters are `accept ... auto`, so no
  CR follows either one;
* `purchase` runs no start-of-day program (unlike `sales`, which runs `sl000`),
  so nothing sits between the two letters;
* the purchase menu exits with `X`, then the system menu with `X` + CR;
* `pl050` itself accepts nothing: it prints and returns;
* the ledger gate is `B-L` (system byte 317, "level-2"), which the setup golden
  already carries at `1` — no seeding needed;
* menu `G` refuses with error 14 (`** No Invoices To Proof/Post **`) unless
  `p-flag-i` (byte 499) is `1` *and* `file-status (26)` (byte 308) is non-zero.
  Nothing in the chain sets either, so the scenario seeds both (DP-029). `pl050`
  itself has no such gate.
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
CASE = "pl050-proof"
GOLDEN = FIXTURES / "golden" / "pl050"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# C → Purchase Ledger at the system menu, then G → Purchase Transactions Proof.
HEAD = [(2.0, b"C\r"), (3.6, b"\r"), (6.5, b"G")]

CASES = {
    "proof": "pinvoice.flat",
    "busy": "busy-pinvoice.flat",
    "empty": "empty-pinvoice.flat",
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


def _prepare(ledgers: Path, invoice: str) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[317] = ord("1")      # `B-L` level-2 — the purchase menu's gate
    system[499] = ord("1")      # `p-flag-i` — invoices waiting (DP-029)
    system[308] = ord("1")      # `file-status (26)` — the invoice file is ready
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("purchled.dat", "pinvoice.dat", "purchase.flat", "pinvoice.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    shutil.copy2(FIXTURES / "generated" / CASE / "purchase.flat", ledgers / "purchase.flat")
    shutil.copy2(FIXTURES / "generated" / CASE / invoice, ledgers / "pinvoice.flat")
    _loader("mkpldx", ledgers)
    _loader("loadpur", ledgers)
    _loader("loadpinv", ledgers)


def _drive(run_dir: Path, label: str, invoice: str) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, invoice)
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
    keys = HEAD + [(75.0, b"X"), (80.0, b"X\r")]
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, 88.0, env)
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


def _case(invoice: str, label: str):
    def run(run_dir: Path) -> dict:
        manifest = _drive(run_dir, label, invoice)
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(FIXTURES / "generated" / CASE / "purchase.flat", keep / "purchase.flat")
        shutil.copy2(FIXTURES / "generated" / CASE / invoice, keep / invoice)
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, _invoice in CASES.items():
    SCENARIOS[f"pl050-{_name}"] = _case(_invoice, f"pl050-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    report = run_dir / "artifacts" / "prt-1"
    if report.exists():
        shutil.copy2(report, dest / "prt-1")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
