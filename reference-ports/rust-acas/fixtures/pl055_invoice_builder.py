#!/usr/bin/env python3
"""Purchase invoice, analysis and value fixtures for the pl055 extract (menu H).

`pl055` is the analysis pass of the purchase posting chain, so the fixture
exists to put every branch of the read loop on disk at once:

* an ordinary invoice and its two lines (counters and sums both move);
* a credit note (`ih-type = 3`): money negated, the month counter still
  positive, the deduction bucket still positive (pl055 never flips it);
* a receipt (`ih-type = 1`): posted, but contributing nothing to the month;
* a proforma (`ih-type = 4`): pl055 has no proforma check, so it posts anyway;
* a header already `analysed` but not applied: staged, totals skipped;
* a header `analysed` and applied: skipped entirely, not staged;
* a line already `il-analyised`: skipped;
* a line whose analysis code does not exist: `create-anal` fires, the
  "Emergency Name" row is minted and PL201/PL202 come up at the end.

Layout is `fdpinv2.cob`, 129 bytes (F-B055): invoice digits 0-7, item 8,
supplier 9-15, `ih-date` 16-19 (`binary-long`, LE), order 20-29, type 30,
ref 31-40, the eight packed figures from 41, `ih-status` 81, `ih-lines` 82,
`ih-deduct-days` 83, `ih-deduct-amt` 84-87 (`comp`, BE), `ih-deduct-vat`
88-91, `ih-days` 92, `ih-cr` 93-96, `ih-day-book-flag` 97, `ih-update` 98,
filler 99-128. The line overlay is 74 bytes over the same frame.

The analysis and value tables are seeded with three codes because pl055 has no
"first use" seeder of its own — sales has sl070, purchase has pl130, and neither
is ported yet (DP-025). Codes are `P` + a two-character `il-pa`, with the group
row `P` + first character + space beside them.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

RECORD = 129
PURCH = 300
ANALYSIS = 36
VALUE = 66
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    a = (14 - m) // 12
    y1 = y + 4800 - a
    m1 = m + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


DATE = days(2026, 11, 2)
CLEAR = days(2026, 11, 30)


def packed_item(cents: int) -> bytes:
    """`s9(7)v99 comp-3` — nine digits, five bytes, sign in the low nibble."""
    nibbles = f"{abs(cents) % 1_000_000_000:09d}"
    out = bytearray()
    for pair in range(0, 8, 2):
        out.append(int(nibbles[pair:pair + 2], 16))
    out.append((int(nibbles[8]) << 4) | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def packed_long(cents: int) -> bytes:
    """`s9(8)v99 comp-3` — ten digits, six bytes, leading pad nibble."""
    nibbles = f"{abs(cents) % 10_000_000_000:010d}"
    out = bytearray([int(nibbles[0])])
    for pair in range(1, 9, 2):
        out.append(int(nibbles[pair:pair + 2], 16))
    out.append((int(nibbles[9]) << 4) | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def put_text(buf: bytearray, at: int, text: str, size: int) -> None:
    buf[at:at + size] = text.encode()[:size].ljust(size, b" ")


def header(invoice: int, supplier: int, kind: int, figures: list[int], *,
           status: str = "p", update: str = " ", order: str = "",
           ref: str = "", lines: int = 1, deduct_days: int = 0,
           deduct_amt: int = 0, deduct_vat: int = 0, day: int = DATE) -> bytes:
    b = bytearray(b" " * RECORD)
    b[0:8] = f"{invoice:08d}".encode()
    b[8] = 0
    b[9:15] = f"{supplier:06d}".encode()
    b[15] = 0x33
    b[16:20] = struct.pack("<i", day)
    put_text(b, 20, order, 10)
    b[30] = ord(str(kind))
    put_text(b, 31, ref, 10)
    for index, cents in enumerate(figures):
        b[41 + index * 5:41 + (index + 1) * 5] = packed_item(cents)
    b[81] = ord(status)
    b[82] = lines
    b[83] = deduct_days
    b[84:88] = struct.pack(">I", deduct_amt)
    b[88:92] = struct.pack(">I", deduct_vat)
    b[92] = 30
    b[93:97] = struct.pack("<i", CLEAR)
    b[97] = ord("b")
    b[98] = ord(update)
    return bytes(b)


def line(invoice: int, item: int, pa: str, cents: int, *, kind: str = "1",
         vat: int = 0, update: str = " ", product: str = "PART-0000001A") -> bytes:
    b = bytearray(b" " * RECORD)
    b[0:8] = f"{invoice:08d}".encode()
    b[8] = item
    put_text(b, 9, product, 13)
    put_text(b, 22, pa, 2)
    b[26:28] = struct.pack(">h" if False else "<h", 1)
    b[28] = ord(kind)
    put_text(b, 29, f"LINE {item} OF {invoice}", 24)
    b[55:60] = packed_item(cents)
    b[60:65] = packed_item(cents)
    b[65:67] = struct.pack(">H", 0)
    b[67:72] = packed_item(vat)
    b[72] = ord("1")
    b[73] = ord(update)
    return bytes(b)


def supplier_row(supplier: int, name: str) -> bytes:
    """One `purch-record` (300 bytes) so pl060 can name its payees."""
    b = bytearray(b" " * PURCH)
    b[0:7] = f"{supplier:06d}3".encode()
    b[7] = ord("1")
    b[8] = ord("0")
    put_text(b, 9, name, 30)
    put_text(b, 39, "1 PROOF WAY", 48)
    b[195:197] = struct.pack(">h", 0)
    b[197] = 0
    for slot in range(198, 242, 4):
        b[slot:slot + 4] = struct.pack(">i", 0)
    for slot in range(242, 284, 5):
        b[slot:slot + 5] = packed_item(0)
    return bytes(b)


def analysis_row(code: str, gl: str, desc: str) -> bytes:
    b = bytearray(b" " * ANALYSIS)
    put_text(b, 0, f"P{code}", 3)
    put_text(b, 3, gl, 6)
    put_text(b, 9, desc, 24)
    put_text(b, 33, "YSP", 3)
    return bytes(b)


def seeded_purchase_tables() -> tuple[bytes, bytes]:
    """Three analysis codes with their group rows, and their empty value rows."""
    codes = [("XA", "850100", "PURCHASE - PARTS"), ("XB", "850200", "PURCHASE - SERVICE"),
             ("ZC", "850300", "PURCHASE - CARRIAGE")]
    analysis = bytearray()
    value = bytearray()

    def value_row(code: str, gl: str, desc: str) -> bytes:
        return analysis_row(code, gl, desc) + b"\x00" * 12 + packed_long(0) * 3

    groups: set[str] = set()
    for code, gl, desc in codes:
        analysis += analysis_row(code, gl, desc)
        value += value_row(code, gl, desc)
        # A group row exists only once per first character: a second write of
        # the same key answers status 22 and `loadval` stops on any non-zero
        # status, so a duplicate silently truncates the rest of the table.
        if code[0] not in groups:
            groups.add(code[0])
            analysis += analysis_row(code[0], gl, desc + " GROUP")
            value += value_row(code[0], gl, desc)
    return bytes(analysis), bytes(value)


def invoice_clean() -> list[bytes]:
    return [
        header(1001, 900001, 2, [1100, 2000, 0, 500, 300, 0, 0, 200],
               order="PO-88112", ref="INV-1001", lines=2, deduct_days=14, deduct_amt=250),
        line(1001, 1, "XA", 1200, vat=240),
        line(1001, 2, "XB", 800, vat=160),
        header(1002, 900002, 2, [550, 1000, 0, 0, 200, 0, 0, 100],
               order="PO-88113", ref="INV-1002", lines=1),
        line(1002, 1, "XA", 1000, vat=200),
    ]


def invoice_credit_note() -> list[bytes]:
    return [
        header(2001, 900001, 2, [1100, 2000, 0, 0, 300, 0, 0, 200],
               order="PO-88201", ref="INV-2001", lines=1),
        line(2001, 1, "XA", 2000, vat=400),
        header(2002, 900003, 3, [1100, 1500, 0, 400, 300, 0, 0, 150],
               order="PO-88202", ref="CN-2002", lines=1, deduct_days=7, deduct_amt=500),
        line(2002, 1, "XA", 1500, kind="3", vat=300),
    ]


def invoice_mixed() -> list[bytes]:
    rows = [
        # already analysed AND applied: skipped, not staged
        header(3001, 900004, 2, [1100, 900, 0, 0, 180, 0, 0, 0],
               status="z", update="Z", ref="INV-3001", lines=1),
        line(3001, 1, "XA", 900, vat=180, update="Z"),
        # a receipt: posted, contributes nothing to the month counter
        header(3002, 900005, 1, [2200, 3000, 0, 0, 600, 0, 0, 300],
               ref="REC-3002", lines=1),
        line(3002, 1, "XB", 3000, vat=600),
        # a proforma: pl055 has no proforma check, so it posts anyway
        header(3003, 900006, 4, [1100, 700, 0, 0, 140, 0, 0, 0],
               ref="PRF-3003", lines=1),
        line(3003, 1, "XA", 700, vat=140),
        # analysed but not applied: staged, totals and month counter skipped
        header(3004, 900007, 2, [1100, 800, 0, 0, 160, 0, 0, 0],
               update="Z", ref="INV-3004", lines=1),
        line(3004, 1, "XA", 800, vat=160),
        # an unknown analysis code: create-anal fires
        header(3005, 900008, 2, [1100, 400, 0, 0, 80, 0, 0, 0],
               ref="INV-3005", lines=1),
        line(3005, 1, "QZ", 400, vat=80),
        # carriage on the single-character code: no group row
        header(3006, 900009, 2, [1100, 600, 0, 150, 120, 0, 0, 0],
               ref="INV-3006", lines=1),
        line(3006, 1, "ZC", 600, vat=120),
        # already analysed line: skipped, no counters move
        header(3007, 900010, 2, [1100, 500, 0, 0, 100, 0, 0, 0],
               ref="INV-3007", lines=1),
        line(3007, 1, "XB", 500, vat=100, update="Z"),
    ]
    return rows


CASES = {
    "clean": invoice_clean,
    "credit_note": invoice_credit_note,
    "mixed": invoice_mixed,
    "empty": lambda: [],
}


def write_case(out: Path, name: str) -> Path:
    dest = out / f"pl055-{name.replace('_', '-')}"
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "pinvoice.flat").write_bytes(b"".join(CASES[name]()))
    analysis, value = seeded_purchase_tables()
    (dest / "analysis.flat").write_bytes(analysis)
    (dest / "value.flat").write_bytes(value)
    (dest / "purchase.flat").write_bytes(
        b"".join(supplier_row(n, f"SUPPLIER {n}") for n in range(900001, 900011))
    )
    return dest


if __name__ == "__main__":
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("generated")
    cases = sys.argv[2:] or list(CASES)
    for case in cases:
        print(write_case(root, case.replace("-", "_")))
