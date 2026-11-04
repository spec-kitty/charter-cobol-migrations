#!/usr/bin/env python3
"""Supplier and purchase-invoice fixtures for the pl050 invoice-proof report.

`pl050` is the purchase mirror of the sales proof (menu G of `purchase`). It
walks `pinvoice.dat` sequentially, prints a row for every unapplied header plus
one analysis row per line the header declares, and totals three groups.

Three datasets:

* `proof` — the branch set: one of each type the program distinguishes (receipt
  1, invoice 2, credit note 3), proformas (4 — *not* skipped here, unlike the
  sales proof, and out of range for the three-entry totals table), an applied
  header, an unknown supplier, a comment line that cuts its invoice's analysis
  short, the prompt-pay/carriage block, and a closing header with no lines so
  the final read reports end of file from the main loop.

Frames are written in key order, not the order the cases are introduced: the
table is INDEXED and an out-of-order append answers status 21 and vanishes.
* `busy` — thirty receipts, enough for the mid-page break at
  `line-cnt > page-lines` and a second page.
* `empty` — no invoice rows at all: the totals block on its own page.

Layouts: `fdpl.cob` 300 bytes, `fdpinv.cob` 129 bytes. The overlays that read
them are `wspinv.cob`'s `invoice-header` (100 bytes) and `invoice-line`
(75 bytes); both are copied out of the 129-byte record, so bytes 100..128 are
never looked at. `comp-3`/`comp` signs and endianness follow F-B006, day numbers
are relative to the F-B001 epoch so the printed dates stay fixed.

The file is INDEXED, so the flat frames here are only for the Rust side: the
loaders (`loadpur`, `loadpinv`) stream them into BDB tables first (F-B007).
This is its own builder rather than an extension of the sl050 one — the
purchase records are re-cut and no sales loader writes them (DP-030).
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

PURCH = 300
INVOICE = 129
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    a = (14 - m) // 12
    y1 = y + 4800 - a
    m1 = m + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


def packed(cents: int) -> bytes:
    """`pic s9(7)v99 comp-3` — 9 digits of hundredths, then the sign nibble."""
    nibbles = f"{abs(cents) % 1_000_000_000:09d}"
    out = bytearray()
    for pair in range(0, 8, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[8]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def supplier_row(key: str, name: str) -> bytes:
    """One `purch-record`. Offsets: key 0, status 7, notes-tag 8, name 9."""
    b = bytearray(b" " * PURCH)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7] = ord("1")                       # supplier-live
    b[8] = ord("0")                       # notes-tag
    b[9:39] = name.ljust(30).encode()[:30]
    b[39:87] = b"1 Proof Way\\Bristol\\\\\\\\".ljust(48)[:48]
    b[195:197] = struct.pack(">h", 0)     # purch-discount 99v99 comp
    b[197] = 0                            # purch-credit
    for slot in range(198, 242, 4):       # the nine binary-long counters
        b[slot:slot + 4] = struct.pack(">i", 0)
    for slot in range(242, 284, 5):       # current, last, four quarters, unapplied
        b[slot:slot + 5] = packed(0)
    return bytes(b)


def header(number: int, supplier: str, day: int, invoice_type: int, *,
           net: int = 0, vat: int = 0, carriage: int = 0, c_vat: int = 0,
           lines: int = 0, status: str = "I", deduct_amt: int = 0) -> bytes:
    """One invoice header: `ih-test` zero on the record's item-nos byte."""
    b = bytearray(b" " * INVOICE)
    b[0:8] = f"{number:08d}".encode()
    b[8] = 0                              # ih-test
    b[9:16] = supplier.ljust(7).encode()[:7]
    b[16:20] = struct.pack("<i", day)     # ih-date, binary-long (F-B001)
    b[20:30] = f"ORDER-{number:04d}".encode()[:10]
    b[30] = ord(str(invoice_type))
    b[31:41] = f"REF-{number:06d}".encode()[:10]
    b[41:46] = packed(0)                  # ih-p-c
    b[46:51] = packed(net)
    b[51:56] = packed(0)                  # ih-extra (never printed here)
    b[56:61] = packed(carriage)
    b[61:66] = packed(vat)
    b[66:71] = packed(0)                  # ih-discount (never printed here)
    b[71:76] = packed(0)                  # ih-e-vat (never printed here)
    b[76:81] = packed(c_vat)
    b[81] = ord(status)
    b[82] = lines
    b[83] = 0                             # ih-deduct-days
    b[84:88] = struct.pack(">i", deduct_amt)   # 999v99 comp
    b[88:92] = struct.pack(">i", 0)            # ih-deduct-vat
    b[92] = 0                             # ih-days
    b[93:97] = b"\0\0\0\0"                # ih-cr
    b[97] = ord(" ")                      # ih-day-book-flag
    b[98] = ord(" ")                      # ih-update
    return bytes(b)


def line(number: int, item: int, product: str, pa: str, net: int, vat: int,
         code: int, desc: str) -> bytes:
    """One invoice line: item-nos 1.., read through the 75-byte overlay."""
    b = bytearray(b" " * INVOICE)
    b[0:8] = f"{number:08d}".encode()
    b[8] = item
    b[9:21] = product.ljust(12).encode()[:12]
    b[21:23] = pa.ljust(2).encode()[:2]
    b[26:28] = struct.pack(">h", 1)       # il-qty
    b[28] = ord("2")                      # il-type
    b[29:53] = desc.ljust(24).encode()[:24]
    b[55:60] = packed(net)
    b[60:65] = packed(net)                # il-unit
    b[65:67] = struct.pack(">h", 0)       # il-discount 99v99 comp
    b[67:72] = packed(vat)
    b[72] = ord(str(code))
    b[73] = ord(" ")
    return bytes(b)


def build(target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    day = days(2026, 11, 3)

    (target / "purchase.flat").write_bytes(b"".join([
        supplier_row("SUP001", "Alpha Supplies Ltd"),
        supplier_row("SUP002", "Beta Parts"),
        supplier_row("SUP003", "Gamma Metals"),
    ]))

    rows: list[bytes] = [
        # Receipt (type 1, group 1) with two lines, one per VAT code 1 and 3.
        header(1, "SUP001", day - 2, 1, net=500_00, vat=105_00, lines=2),
        line(1, 1, "STEEL-01", "V1", 300_00, 63_00, 1, "Steel strip"),
        line(1, 2, "STEEL-02", "V3", 200_00, 42_00, 3, "Steel rod"),
        # Invoice with prompt pay and carriage: both deduction-block rows.
        header(2, "SUP002", day - 4, 2, net=120_00, vat=25_20,
               carriage=5_00, c_vat=1_05, deduct_amt=2_50, lines=1),
        line(2, 1, "BOLT-M8", "V1", 120_00, 25_20, 1, "Bolts"),
        # Credit note: every figure negated, including the prompt pay.
        header(3, "SUP003", day - 6, 3, net=40_00, vat=8_40,
               carriage=2_00, c_vat=42, deduct_amt=1_00, lines=1),
        line(3, 1, "RETURN-1", "  ", 40_00, 8_40, 0, "Returned metal"),
        # Proforma: *not* skipped here; it prints as `Cr. Note` and lands in
        # group 4, one past the three-entry totals table.
        header(4, "SUP001", day - 7, 4, net=77_00, vat=16_17, lines=1),
        line(4, 1, "PRO-9", "V1", 77_00, 16_17, 1, "Quotation"),
        # Second proforma, this one with a prompt-pay deduction: its totals
        # land in entry 4, whose `total-ded` write runs over `line-cnt`.
        header(41, "SUP002", day - 7, 4, net=5_00, vat=1_05, deduct_amt=2_50,
               lines=1),
        line(41, 1, "PRO-10", "V2", 5_00, 1_05, 2, "Quotation two"),
        # Already applied: skipped outright. (Never reached from entry 4 — the
        # page counter has been through an out-of-bounds write by now.)
        header(5, "SUP002", day - 8, 2, net=66_00, vat=13_86, status="z"),
        # Unknown supplier: `Supplier Unknown` and the closing warning line.
        header(6, "ZZZZZZ", day - 10, 2, net=99_99, vat=21_00, lines=1),
        line(6, 1, "PART-9", "V2", 10_00, 2_10, 2, "Part supply"),
        # Comment line cuts the analysis: the second line is never read as one
        # and comes back through the main loop as a non-header record.
        header(7, "SUP003", day - 12, 1, net=15_00, vat=3_15, lines=2),
        line(7, 1, "/COMMENT", "  ", 0, 0, 0, "Note to follow"),
        line(7, 2, "HMER-1", "V1", 15_00, 3_15, 1, "Hammer"),
        # Closing header with no lines: the last record is a header, so the
        # final read reports end of file from the main loop (F-B016 Part 3).
        header(8, "SUP003", day - 14, 2, net=12_00, vat=2_52),
    ]
    # The file is INDEXED and `loadpinv` appends: an out-of-order frame answers
    # status 21 and is dropped without an error, so the frames must be in key
    # order (invoice, then item) or the tail of the fixture simply disappears
    # (DP-028). `41` therefore sorts *after* `8`, not in builder order.
    rows.sort(key=lambda frame: (frame[0:8], frame[8]))
    (target / "pinvoice.flat").write_bytes(b"".join(rows))

    busy_rows = [
        header(100 + n, "SUP001", day - n, 1, net=10_00 * n, vat=2_10 * n)
        for n in range(1, 31)
    ]
    (target / "busy-pinvoice.flat").write_bytes(b"".join(busy_rows))
    (target / "empty-pinvoice.flat").write_bytes(b"")


if __name__ == "__main__":
    build(Path(sys.argv[1]))
