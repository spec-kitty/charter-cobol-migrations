#!/usr/bin/env python3
"""fdinv2 invoice fixture builder.

Authors synthetic-but-realistic invoice files for the parity harness.
Writes the GnuCOBOL relative-file framing verified in F-B002:
  N fixed records of 134 bytes each + 32-byte space trailer.

Fixture scenarios (each produces a separately named output dir):
  clean        — 2 invoices (each with 2 lines), statuses ready-to-post
  pending      — as clean, but invoice 2 header has ih-status='P' & line
                 not "L" printed → triggers SL122 path
  credit_note  — one credit-note (ih-type=3) + its lines
  mixed        — 5 rows exercising every sl055 skip-rule branch

This is the *input contract*; `sl055` under COBOL and `acas_sales::posting`
under Rust both consume these bytes, and the harness compares outputs.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

RECORD = 134
TRAILER = 32
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


def put_binary_char(b: bytearray, pos: int, n: int) -> None:
    b[pos] = n & 0xFF


def invoice_header(rec: bytearray, nos: int, let: bytes, customer: bytes,
                   kind: int, net_cents: int, vat_cents: int,
                   carr_cents: int, disc_cents: int,
                   status_main: bytes = b" ", lflag: bytes = b"L",
                   update: bytes = b" ") -> None:
    """ih-* variant. Field offsets per fdinv2.cob, verified frame."""
    field_put_num(rec, 0, nos, 8)
    rec[8] = let[0]
    rec[9] = 0                                   # ih-test = 0 → header
    field_put(rec, 10, customer.ljust(6, b" "), 6)
    field_put_num(rec, 16, 0, 1)                 # ih-check (modulus check-digit)
    put_binary_long(rec, 17, EPOCH_DAYS)
    field_put(rec, 21, b"ORDER0010", 10)
    rec[31] = kind                               # ih-type
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
    put_binary_char(rec, 120, 2)                 # ih-lines
    put_binary_char(rec, 121, 0)                 # ih-deduct-days
    put_binary_short(rec, 122, 0)                # ih-deduct-amt (999v99 comp = 2B)
    put_binary_short(rec, 124, 0)                # ih-deduct-vat
    put_binary_char(rec, 126, 30)                # ih-days — credit days
    put_binary_long(rec, 127, EPOCH_DAYS + 30)   # ih-cr = credit-by date
    rec[131] = 0x20                              # ih-day-book-flag
    rec[132] = update[0]                         # ih-update — blank = unworked
    rec[133] = 0x20                              # trailing filler


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
    # rest filler — already zeroed by init


def build_file(rows: list[bytearray], record_size: int = RECORD) -> bytes:
    out = bytearray()
    for r in rows:
        assert len(r) == record_size, f"record {len(r)}B != expected {record_size}B"
        out.extend(r)
    out.extend(b" " * TRAILER)
    return bytes(out)


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
    (root / "invoice.dat").write_bytes(build_file(rows))

    # Empty-but-allocated analysis/value/oi2 so COBOL can open+extend them
    # (1 pre-filled record of spaces = COBOL "empty" row; row size from FD).
    for name, rec_size in [
        ("analysis.dat", 73),   # fdanal record frame
        ("value.dat",    37),   # fdval record frame
        ("openitm2.dat", 100),  # fdoi2 staging frame
    ]:
        row0 = bytearray(b" " * rec_size)
        (root / name).write_bytes(build_file([row0], record_size=rec_size))


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
    (root / "invoice.dat").write_bytes(build_file(rows))
    for name, rec_size in [("analysis.dat", 73), ("value.dat", 37), ("openitm2.dat", 100)]:
        row0 = bytearray(b" " * rec_size)
        (root / name).write_bytes(build_file([row0], record_size=rec_size))


def main() -> None:
    out_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "fixtures")
    scenarios = sys.argv[2:] if len(sys.argv) > 2 else ["clean", "pending"]
    for s in scenarios:
        d = out_dir / s
        d.mkdir(parents=True, exist_ok=True)
        {"clean": scenario_clean, "pending": scenario_pending}[s](d)
        print(f"  fixture {s}: {len(list(d.glob('*')))} files → {d}")


if __name__ == "__main__":
    main()
