#!/usr/bin/env python3
"""Sales and invoice fixtures for the sl050 invoice-proof report (menu F).

`sl050` walks the invoice file sequentially, prints a header row for every
*unapplied* non-proforma header and then one analysis row per line the header
declares, plus the discount/carriage/late-charge/extra block, and totals three
groups. The dump builder cannot serve: it authors no invoice lines.

Two datasets:

* `sl050-proof` — the branch coverage set. One of each header type (receipt,
  invoice, credit note, proforma), one already-applied header, one header whose
  customer is not on the ledger (the `!! Customer Unknown` path), a comment
  line (`/` product) that cuts its invoice's analysis short, an invoice that
  declares two lines but only has one before end of file, and the
  discount/carriage/extra/deduction block on two rows.
* `sl050-busy` — thirty receipt headers, enough rows to force the mid-page
  break at `line-cnt > page-lines - 2` and a second page.

Layouts: `fdsl.cob` 300 bytes, `fdinv2.cob` 134 bytes. `comp-3`/`comp` signs
and endianness follow F-B006; day numbers are relative to the F-B001 epoch so
the printed dates stay fixed.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

SALES = 300
INVOICE = 134
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    a = (14 - m) // 12
    y1 = y + 4800 - a
    m1 = m + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


def packed_wide(cents: int) -> bytes:
    nibbles = "0" + f"{abs(cents) % 10_000_000_000:010d}"
    out = bytearray()
    for pair in range(0, 10, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[10]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def packed_item(cents: int) -> bytes:
    nibbles = f"{abs(cents) % 1_000_000_000:09d}"
    out = bytearray()
    for pair in range(0, 8, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[8]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def sales_row(key: str, name: str) -> bytes:
    b = bytearray(b" " * SALES)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7:37] = name.ljust(30).encode()[:30]
    b[37:85] = b"1 Proof Way\\Bristol\\\\".ljust(48)[:48]
    b[193] = ord("1")
    b[204:206] = b"30"
    b[206:208] = struct.pack(">h", 0)
    b[212:216] = struct.pack("<i", 1000)
    b[248:254] = packed_wide(0)
    b[254:260] = packed_wide(0)
    b[284:290] = packed_wide(0)
    return bytes(b)


def header(number: int, customer: str, day: int, invoice_type: int, desc: str, *,
           net: int = 0, vat: int = 0, extra: int = 0, carriage: int = 0,
           discount: int = 0, e_vat: int = 0, c_vat: int = 0, lines: int = 0,
           status: str = "I", deduct_amt: int = 0, deduct_vat: int = 0) -> bytes:
    b = bytearray(b" " * INVOICE)
    b[0:8] = f"{number:08d}".encode()
    b[8] = ord("L")
    b[9] = 0
    b[10:16] = customer[:6].ljust(6).encode()
    b[16] = ord(customer[6:7]) if len(customer) > 6 else ord(" ")
    b[17:21] = struct.pack("<i", day)
    b[21:31] = f"ORDER-{number:04d}".encode()[:10]
    b[31] = ord(str(invoice_type))
    b[32:42] = f"REF-{number:06d}".encode()[:10]
    b[42:74] = desc.ljust(32).encode()[:32]
    figures = [0, net, extra, carriage, vat, discount, e_vat, c_vat]
    for slot, value in enumerate(figures):
        b[74 + slot * 5: 79 + slot * 5] = packed_item(value)
    b[114] = ord(status)
    b[115:120] = b"     "
    b[120] = lines
    b[121] = 0
    b[122:126] = struct.pack(">I", deduct_amt)          # ih-deduct-amt comp
    b[126:130] = struct.pack(">I", deduct_vat)
    b[130] = 0
    b[131:134] = b"\0\0\0"
    return bytes(b)


def line(number: int, item: int, product: str, pa: str, net: int, vat: int,
         code: int, desc: str, line_type: str = "2") -> bytes:
    b = bytearray(b" " * INVOICE)
    b[0:8] = f"{number:08d}".encode()
    b[8] = ord("L")
    b[9] = item
    b[10:23] = product.ljust(13).encode()[:13]
    b[23:25] = pa.ljust(2).encode()[:2]
    b[25:27] = struct.pack("<h", 1)
    b[27] = ord(line_type)
    b[28:60] = desc.ljust(32).encode()[:32]
    b[60:65] = packed_item(net)
    b[65:70] = packed_item(net)
    b[70:72] = struct.pack(">h", 0)
    b[72:77] = packed_item(vat)
    b[77] = ord(str(code))
    b[78] = ord(" ")
    b[79] = ord(" ")
    return bytes(b)


def build(target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    day = days(2026, 11, 3)

    sales = [
        sales_row("CUST011", "Alpha Analytical Ltd"),
        sales_row("CUST022", "Beta Bolts"),
        sales_row("CUST033", "Gamma Gaskets"),
    ]
    (target / "sales.flat").write_bytes(b"".join(sales))

    rows: list[bytes] = [
        # Receipt: type 1, group 1, no analysis rows.
        header(1, "CUST011", day - 2, 1, "Cash sale", net=500_00),
        # Invoice with a normal line and then a comment line, which cuts the
        # rest of this invoice's analysis (and leaves its second line unread).
        header(2, "CUST022", day - 4, 2, "Goods invoice", net=120_00, vat=21_00,
               lines=2),
        line(2, 1, "STEEL-01", "V1", 120_00, 21_00, 1, "Steel strip"),
        line(2, 2, "/COMMENT", "  ", 0, 0, 0, "Note to follow"),
        # Credit note: negated, every deduction block prints.
        header(3, "CUST011", day - 6, 3, "Returned goods", net=40_00, vat=7_00,
               extra=1_00, carriage=2_00, discount=5_00, e_vat=25, c_vat=40,
               lines=1, deduct_amt=3_00, deduct_vat=50),
        line(3, 1, "RETURN-1", "V2", 40_00, 7_00, 2, "Returned strip", "3"),
        # Proforma: skipped outright.
        header(4, "CUST022", day - 7, 4, "Proforma", net=77_00),
        # Already applied: skipped.
        header(5, "CUST022", day - 8, 2, "Applied invoice", net=66_00, status="z"),
        # Discount, carriage and extra print; no deduction, no lines.
        header(6, "CUST033", day - 10, 2, "Sundries", net=30_00, discount=10_00,
               carriage=5_00, extra=2_00),
        # Unknown customer: `!! Customer Unknown` and the warning flag. It
        # declares two lines but has one, so the second analysis read takes the
        # *next* header as a line.
        header(7, "ZZZZZZ", day - 12, 2, "Ghost invoice", net=99_99, lines=2),
        line(7, 1, "PART-9", "V3", 10_00, 1_75, 3, "Part payment"),
        # Last record is a header with no lines, so the final read reports end
        # of file from the main loop rather than from an analysis.
        header(8, "CUST033", day - 14, 2, "Closing invoice", net=12_00),
    ]
    (target / "invoice.flat").write_bytes(b"".join(rows))

    busy = [sales_row("CUST011", "Alpha Analytical Ltd")]
    busy_rows = [
        header(100 + n, "CUST011", day - n, 1, f"Receipt {n}", net=10_00 * n)
        for n in range(1, 31)
    ]
    (target / "busy-sales.flat").write_bytes(b"".join(busy))
    (target / "busy-invoice.flat").write_bytes(b"".join(busy_rows))


if __name__ == "__main__":
    build(Path(sys.argv[1]))
