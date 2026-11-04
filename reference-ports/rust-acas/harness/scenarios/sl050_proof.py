"""sl050 invoice-proof scenarios (WP07).

Menu F of `sales` opens the proof: one row per unapplied, non-proforma invoice
header, its analysis lines, the deduction block and the three group totals.
The artifact under test is `prt-1`.

Screen-driving quirks this scenario encodes (measured; F-B016):

* the sales menu runs `sl000` (start of day) before it draws, so the date
  screen needs one CR and the menu letter carries it;
* `sl050` itself accepts nothing: it prints and returns, so the case needs no
  keystrokes between the letter and the two letters that leave the menus;
* the proof refuses to run at all unless `file-status (16)` is non-zero, and
  nothing in the sales chain sets it — the scenario seeds system byte 298
  (DP-013);
* `sales-ledger` (byte 560) is seeded for DP-010's reason;
* the case letters are `accept ... auto`, so no CR follows them.
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
CASE = "sl050-proof"
GOLDEN = FIXTURES / "golden" / "sl050"
H_BUILD = Path("/tmp/acas-build")

SCENARIOS: dict = {}

# B → Sales Ledger at the system menu, CR pasts sl000's date, then F →
# Sales Transactions Proof at the sales menu.
HEAD = [(2.0, b"B\r"), (3.6, b"\r"), (6.5, b"F")]

CASES = {
    "proof": ("invoice.flat", "sales.flat"),
    "busy": ("busy-invoice.flat", "busy-sales.flat"),
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


def _prepare(ledgers: Path, invoice: str, sales: str) -> None:
    gold_system = SEED / "system.dat"
    if not gold_system.exists():
        raise SystemExit("no seeded system.dat; run the setup-clean scenario first")
    system = bytearray(gold_system.read_bytes())
    system[560] = ord("Y")          # `sales-ledger` (F-B011)
    system[298] = ord("1")          # `file-status (16)` — invoice file ready
    (ledgers / "system.dat").write_bytes(bytes(system))
    (H_BUILD / "prt-1").unlink(missing_ok=True)
    for stale in ("salesled.dat", "sales.flat", "invoice.dat", "invoice.flat"):
        (ledgers / stale).unlink(missing_ok=True)
    shutil.copy2(FIXTURES / "generated" / CASE / sales, ledgers / "sales.flat")
    shutil.copy2(FIXTURES / "generated" / CASE / invoice, ledgers / "invoice.flat")
    _loader("mkidx", ledgers)
    _loader("loadsal", ledgers)
    _loader("loadinv", ledgers)


def _drive(run_dir: Path, label: str, invoice: str, sales: str) -> dict:
    import parity_harness as H

    ledgers = _ledgers()
    _prepare(ledgers, invoice, sales)
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
    keys = HEAD + [(46.0, b"9"), (50.0, b"X\r")]
    transcript = H._drive_pty_env(["./ACAS"], H.SRC_BUILD, keys, 58.0, env)
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


def _case(invoice: str, sales: str, label: str):
    def run(run_dir: Path) -> dict:
        manifest = _drive(run_dir, label, invoice, sales)
        keep = run_dir / "input"
        keep.mkdir()
        shutil.copy2(FIXTURES / "generated" / CASE / sales, keep / sales)
        shutil.copy2(FIXTURES / "generated" / CASE / invoice, keep / invoice)
        shutil.copy2(SEED / "system.dat", keep / "system.dat")
        return manifest
    return run


for _name, (_invoice, _sales) in CASES.items():
    SCENARIOS[f"sl050-{_name}"] = _case(_invoice, _sales, f"sl050-{_name}")


def promote(run_dir: Path, case: str) -> Path:
    dest = GOLDEN / case
    dest.mkdir(parents=True, exist_ok=True)
    report = run_dir / "artifacts" / "prt-1"
    if report.exists():
        shutil.copy2(report, dest / "prt-1")
    return dest


if __name__ == "__main__":
    print(promote(Path(sys.argv[1]), sys.argv[2]))
