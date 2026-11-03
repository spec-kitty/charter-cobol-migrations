#!/usr/bin/env python3
"""fdinv2 invoice fixture builder.

Authors synthetic-but-realistic invoice files for the parity harness.
Writes bare 134-byte records, no trailer and no page header: both sides take
these as the *rows* of the indexed tables (the COBOL loader streams them in,
F-B007), so framing lives with the transport, not the fixture.

Fixture scenarios (each produces a separately named output dir):
  clean        — 2 invoices (each with 2 lines), statuses ready-to-post
  pending      — as clean, but invoice 2 header has ih-status='P' & line
                 not "L" printed → triggers SL122 path
  credit_note  — one credit-note (ih-type=3) + its lines
  mixed        — rows exercising every sl055 skip-rule branch

This is the *input contract*; `sl055` under COBOL and `acas_sales::posting`
under Rust both consume these bytes, and the harness compares outputs.

Flat frames are only the *transport*. ACAS opens invoice/value/analysis as
INDEXED, and a flat frame is not openable through an indexed FD (open returns
status 35 and the whole run silently does nothing — F-B007). The same bytes are
also written as `<table>.flat`, which `fixtures/cobol_loader/` streams into
real BDB files before the COBOL side runs. The analysis/value tables start
empty; sl070 seeds the ACAS default rows on the first run.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

RECORD = 134


class FileKind:
    """FD record sizes (bytes), re-measured off GnuCOBOL writes — see F-B005."""

    ANALYSIS = 36    # fdanal.cob "36 bytes"
    VALUE = 66       # fdval.cob "record size 66 bytes"
    OPEN_ITEM2 = 114 # fdoi2.cob "114 bytes"
EPOCH_DAYS = 155534  # F-B001: 2026-11-02, per system.dat run-date


def field_put(b: bytearray, pos: int, data: bytes, size: int) -> None:
    """Copy `data` up to `size`, space-pad right (COBOL ALPHANUMERIC send)."""
    b[pos:pos+size] = data[:size].ljust(size, b" ")


def field_put_num(b: bytearray, pos: int, n: int, digits: int) -> None:
    """PIC 9(n) — right-justified zero-padded numeric."""
    s = f"{n:0{digits}d}"[-digits:]
    b[pos:pos+digits] = s.encode()


def put_comp3(b: bytearray, pos: int, cents: int) -> None:
    """s9(7)v99 comp-3 (packed decimal), 5 bytes total.
    cents = i64 of whole-value in hundredths. Stores magnitude*100 packed.
    """
    sign = 0x0C if cents >= 0 else 0x0D   # C=+ D=- F=unsigned (COBOL comp-3 default C)
    v = abs(cents)  # cents already scaled ×100
    digits = f"{v:09d}"  # 7 int + 2 frac = 9 digits
    bytes5 = bytes(int(digits[i:i+2], 16) for i in (0, 2, 4, 6))
    last = (int(digits[8]) << 4) | sign
    b[pos:pos+5] = bytes(bytes5) + bytes([last])


def put_binary_long(b: bytearray, pos: int, n: int) -> None:
    b[pos:pos+4] = struct.pack("<i", n)


def put_binary_short(b: bytearray, pos: int, n: int) -> None:
    b[pos:pos+2] = struct.pack("<h", n)


def put_comp4(b: bytearray, pos: int, n: int) -> None:
    """`999v99 comp` — 4-byte big-endian binary (F-B006). Value is hundredths."""
    b[pos:pos+4] = struct.pack(">I", n)


def put_binary_char(b: bytearray, pos: int, n: int) -> None:
    b[pos] = n & 0xFF


def invoice_header(rec: bytearray, nos: int, let: bytes, customer: bytes,
                   kind: int, net_cents: int, vat_cents: int,
                   carr_cents: int, disc_cents: int,
                   status_main: bytes = b" ", lflag: bytes = b"L",
                   update: bytes = b" ") -> None:
    """ih-* variant. Field offsets measured off GnuCOBOL writes — F-B006.

    `status_main` is `ih-status`; `update` is `ih-update`, which sits past the
    134-byte record and therefore never lands in the file (kept in the
    signature so callers can still say what they mean).
    """
    field_put_num(rec, 0, nos, 8)
    rec[8] = let[0]
    rec[9] = 0                                   # ih-test = 0 → header
    field_put(rec, 10, customer.ljust(6, b" "), 6)
    field_put_num(rec, 16, 0, 1)                 # ih-check (modulus check-digit)
    put_binary_long(rec, 17, EPOCH_DAYS)
    field_put(rec, 21, b"ORDER0010", 10)
    # ih-type is PIC 9 — a *digit character* on disk, like il-type. Writing the
    # raw value makes every `if ih-type = n` comparison in sl055 false.
    rec[31] = str(kind).encode()[0]               # ih-type
    field_put(rec, 32, b"REF-000001", 10)
    field_put(rec, 42, b"Fixture invoice", 32)
    put_comp3(rec, 74, net_cents + vat_cents)    # ih-p-c (price&carriage)
    put_comp3(rec, 79, net_cents)                # ih-net
    put_comp3(rec, 84, 0)                        # ih-extra
    put_comp3(rec, 89, carr_cents)               # ih-carriage
    put_comp3(rec, 94, vat_cents)                # ih-vat
    put_comp3(rec, 99, disc_cents)               # ih-discount
    put_comp3(rec, 104, 0)                       # ih-e-vat (EU/other)
    put_comp3(rec, 109, 0)                       # ih-c-vat (carriage-vat)
    rec[114] = status_main[0]                    # ih-status
    rec[115] = 0x20                              # ih-status-P pick
    rec[116] = lflag[0]                          # ih-status-L invoice-printed
    rec[117] = 0x20                              # ih-status-C cleared
    rec[118] = 0x20                              # ih-status-A applied
    rec[119] = 0x20                              # ih-status-I lines-deleted
    put_binary_char(rec, 120, 2)                     # ih-lines
    put_binary_char(rec, 121, 0)                     # ih-deduct-days
    put_comp4(rec, 122, 0)                           # ih-deduct-amt (999v99 comp, 4B BE)
    put_comp4(rec, 126, 0)                           # ih-deduct-vat
    put_binary_char(rec, 130, 30)                    # ih-days — credit days
    rec[131:134] = struct.pack("<i", EPOCH_DAYS + 30)[:3]  # ih-cr: low 3 B only …
    # … but the header overlay is 137 B against a 134-B record (F-B006): the
    # cr high byte, ih-day-book-flag (135) and ih-update (136) are truncated by
    # every ACAS write, so 131..133 is all that ever reaches this file.


def invoice_line(rec: bytearray, nos: int, let: bytes, line_no: int,
                 product: bytes, pa: bytes, net_cents: int, vat_cents: int,
                 inv_type: bytes = b"1", update: bytes = b" ") -> None:
    field_put_num(rec, 0, nos, 8)
    rec[8] = let[0]
    rec[9] = line_no
    field_put(rec, 10, product.ljust(13, b" "), 13)
    field_put(rec, 23, pa.ljust(2, b" "), 2)
    put_binary_short(rec, 25, 1)                 # il-qty
    rec[27] = inv_type[0]                        # il-type  (x field: "3"=credit)
    field_put(rec, 28, b"Widget: fixture", 32)
    put_comp3(rec, 60, net_cents)                # il-net
    put_comp3(rec, 65, net_cents)                # il-unit
    put_binary_short(rec, 70, 0)                 # il-discount (99v99 comp = 2B)
    put_comp3(rec, 72, vat_cents)                # il-vat
    rec[77] = 0x31                                 # il-vat-code "1"
    rec[78] = update[0]                          # il-update
    field_put(rec, 79, b" ", 55)                 # trailing filler + unwritten frame


def write_tables(root: Path, analysis: list[bytearray] | None = None,
                 value: list[bytearray] | None = None) -> None:
    """Write the three side tables.

    `analysis.flat`/`value.flat` are the loader inputs (F-B007); the `.dat`
    twins keep the Rust-side tests pointed at a stable name. Empty means an
    empty stream — the loader produces an empty indexed file from it.
    """
    for name, size, rows in [
        ("analysis", FileKind.ANALYSIS, analysis or []),
        ("value",    FileKind.VALUE, value or []),
        ("openitm2", FileKind.OPEN_ITEM2, []),
    ]:
        if name == "openitm2":
            blob = b""            # sequential: no trailer, COBOL appends
        else:
            blob = b"".join(bytes(r) for r in rows)
        (root / f"{name}.flat").write_bytes(blob)
        (root / f"{name}.dat").write_bytes(blob)


def write_invoice(root: Path, rows: list[bytearray]) -> None:
    blob = b"".join(bytes(r) for r in rows)
    (root / "invoice.dat").write_bytes(blob)
    (root / "invoice.flat").write_bytes(blob)


def scenario_clean(root: Path) -> None:
    """2 invoices, 2 lines each; both printed (L) & ready to post."""
    rows = []
    for inv_no, customer, net, vat in [
        (1001, b"CUST01", 100_000, 20_000),   # £1000.00 + £200.00 VAT
        (1002, b"CUST02", 50_000,  10_000),
    ]:
        h = bytearray(RECORD); invoice_header(h, inv_no, b" ", customer, 1, net, vat, 0, 0, lflag=b"L")
        rows.append(h)
        for ln in (1, 2):
            l = bytearray(RECORD)
            invoice_line(l, inv_no, b" ", ln, b"WIDGET-A", b"01", net // 2, vat // 2, inv_type=b"1")
            rows.append(l)
    write_invoice(root, rows)
    write_tables(root)


def scenario_pending(root: Path) -> None:
    """Invoice 2 has pending + unprinted. SL122 path."""
    rows = []
    h = bytearray(RECORD)
    invoice_header(h, 1001, b" ", b"CUST01", 1, 100_000, 20_000, 0, 0, lflag=b"L")
    rows.append(h)
    for ln in (1, 2):
        l = bytearray(RECORD)
        invoice_line(l, 1001, b" ", ln, b"WIDGET-A", b"01", 50_000, 10_000)
        rows.append(l)
    h2 = bytearray(RECORD)
    invoice_header(h2, 1002, b" ", b"CUST02", 1, 50_000, 10_000, 0, 0,
                   status_main=b"P", lflag=b" ")
    rows.append(h2)
    l2 = bytearray(RECORD)
    invoice_line(l2, 1002, b" ", 1, b"WIDGET-B", b"01", 50_000, 10_000)
    rows.append(l2)
    write_invoice(root, rows)
    write_tables(root)


def scenario_credit_note(root: Path) -> None:
    """One invoice, then a credit note for a third of it.

    type 3 must negate the line value, the specials legs, the oi2 money
    figures and the deduct fields — and still carry `cr` through unchanged.
    """
    rows = []
    h = bytearray(RECORD)
    invoice_header(h, 1001, b" ", b"CUST01", 1, 100_000, 20_000, 500, 300, lflag=b"L")
    rows.append(h)
    for ln in (1, 2):
        l = bytearray(RECORD)
        invoice_line(l, 1001, b" ", ln, b"WIDGET-A", b"01", 50_000, 10_000)
        rows.append(l)
    h3 = bytearray(RECORD)
    invoice_header(h3, 1002, b" ", b"CUST01", 3, 30_000, 6_000, 200, 100, lflag=b"L")
    h3[121] = 4                                   # ih-deduct-days
    put_comp4(h3, 122, 12_500)                    # ih-deduct-amt 125.00
    put_comp4(h3, 126, 2_500)                     # ih-deduct-vat  25.00
    rows.append(h3)
    l3 = bytearray(RECORD)
    invoice_line(l3, 1002, b" ", 1, b"WIDGET-A", b"01", 10_000, 2_000, inv_type=b"3")
    rows.append(l3)
    write_invoice(root, rows)
    write_tables(root)


def scenario_mixed(root: Path) -> None:
    """One row set that trips every skip rule in da010/da020/dd000."""
    rows = []
    # 1001 — posts: two lines, one already analysied, one comment line
    h = bytearray(RECORD)
    invoice_header(h, 1001, b" ", b"CUST01", 1, 100_000, 20_000, 0, 0, lflag=b"L")
    rows.append(h)
    l = bytearray(RECORD); invoice_line(l, 1001, b" ", 1, b"WIDGET-A", b"01", 50_000, 10_000)
    rows.append(l)
    l = bytearray(RECORD); invoice_line(l, 1001, b" ", 2, b"WIDGET-A", b"01", 50_000, 10_000, update=b"z")
    rows.append(l)
    # 1002 — proforma: skipped whole (ih-type 4)
    h = bytearray(RECORD)
    invoice_header(h, 1002, b" ", b"CUST02", 4, 40_000, 8_000, 0, 0, lflag=b"L")
    rows.append(h)
    # 1003 — applied but not analysed: no oi2 record, but the totals still count
    h = bytearray(RECORD)
    invoice_header(h, 1003, b" ", b"CUST03", 1, 60_000, 12_000, 0, 0,
                   status_main=b"z", lflag=b"L")
    rows.append(h)
    # 1004 — pending & unprinted: skip + SL122 flag
    h = bytearray(RECORD)
    invoice_header(h, 1004, b" ", b"CUST04", 1, 80_000, 16_000, 0, 0, status_main=b"P")
    rows.append(h)
    l = bytearray(RECORD); invoice_line(l, 1004, b" ", 1, b"WIDGET-B", b"02", 80_000, 16_000)
    rows.append(l)
    # 1005 — prints but il-status-L cleared: also skipped & flagged
    h = bytearray(RECORD)
    invoice_header(h, 1005, b" ", b"CUST05", 1, 20_000, 4_000, 0, 0, lflag=b" ")
    rows.append(h)
    write_invoice(root, rows)
    write_tables(root)


def scenario_comment_lines(root: Path) -> None:
    """A line whose product starts `/` is a comment: counters untouched."""
    rows = []
    h = bytearray(RECORD)
    invoice_header(h, 1001, b" ", b"CUST01", 1, 10_000, 2_000, 0, 0, lflag=b"L")
    rows.append(h)
    l = bytearray(RECORD)
    invoice_line(l, 1001, b" ", 1, b"/NOTE", b"01", 9_999, 1_999)
    l[10] = ord("/")
    rows.append(l)
    write_invoice(root, rows)
    write_tables(root)


def main() -> None:
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "fixtures")
    scenarios = sys.argv[2:] if len(sys.argv) > 2 else [
        "clean", "pending", "credit_note", "mixed", "comment_lines"]
    for s in scenarios:
        d = out_dir / s
        d.mkdir(parents=True, exist_ok=True)
        {
            "clean": scenario_clean,
            "pending": scenario_pending,
            "credit_note": scenario_credit_note,
            "mixed": scenario_mixed,
            "comment_lines": scenario_comment_lines,
        }[s](d)
        print(f"  fixture {s}: {len(list(d.glob('*')))} files → {d}")


if __name__ == "__main__":
    main()
