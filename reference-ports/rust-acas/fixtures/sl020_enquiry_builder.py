#!/usr/bin/env python3
"""Sales, open-item and invoice fixtures for the sl020 ledger enquiry (menu 3).

`sl020` prints one customer's header block, every open item it has, and an
ageing summary. The dump builder cannot serve: it authors no open items and no
invoice headers, and the enquiry's "Unposted" column needs headers of both
signs.

Three customers cover the branches:

* `CUST011` — five items across all four ageing buckets, a credit note, a
  payment (blank number column) and a held item (`Q` mark);
* `CUST022` — one item with no ageing edge, plus a credit limit and an
  unapplied balance;
* `CUST033` — no open items at all, so only the totals block prints.

Layouts: `fdsl.cob` 300 bytes, `fdoi3.cob` 114 bytes, `fdinv2.cob` 134 bytes.
Two-byte `comp` and `comp-3` signs follow F-B006/F-B008/F-B009; day numbers are
relative to the F-B001 epoch so the buckets stay fixed.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

SALES = 300
OPEN_ITEM = 114
INVOICE = 134
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    a = (14 - m) // 12
    y1 = y + 4800 - a
    m1 = m + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


def packed_wide(cents: int) -> bytes:
    """`s9(8)v99 comp-3` — eleven digits, six bytes, sign in the last nibble."""
    nibbles = "0" + f"{abs(cents) % 10_000_000_000:010d}"
    out = bytearray()
    for pair in range(0, 10, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[10]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def packed_item(cents: int) -> bytes:
    """`s9(7)v99 comp-3` — nine digits, five bytes, sign in the last nibble."""
    nibbles = f"{abs(cents) % 1_000_000_000:09d}"
    out = bytearray()
    for pair in range(0, 8, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[8]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def sales_row(key: str, name: str, addr1: str, addr2: str, **money: int) -> bytes:
    b = bytearray(b" " * SALES)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7:37] = name.ljust(30).encode()[:30]
    b[37:85] = addr1.ljust(48).encode()[:48]
    b[85:133] = addr2.ljust(48).encode()[:48]
    b[193] = ord("1")                                    # sales-status: live
    b[204:206] = b"30"                                   # sales-credit
    b[206:208] = struct.pack(">h", 0)                    # sales-discount
    b[212:216] = struct.pack("<i", money.get("limit", 0))
    b[248:254] = packed_wide(money.get("current", 0))
    b[254:260] = packed_wide(0)
    for slot in range(4):
        b[260 + slot * 6: 266 + slot * 6] = packed_wide(money.get("q", [0, 0, 0, 0])[slot])
    b[284:290] = packed_wide(money.get("unapplied", 0))
    return bytes(b)


def open_item(key: str, invoice: int, day: int, item_type: int, desc: str,
              *, net: int = 0, vat: int = 0, paid: int = 0, hold: str = " ",
              cr: int = 0) -> bytes:
    b = bytearray(b" " * OPEN_ITEM)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7:11] = struct.pack("<I", invoice)
    b[11:15] = struct.pack("<i", day)
    b[21] = ord(str(item_type))
    b[22:47] = desc.ljust(25).encode()[:25]
    b[47] = ord(hold)
    b[48] = ord(" ")
    b[49:54] = packed_item(0)
    b[54:59] = packed_item(net)
    b[59:64] = packed_item(0)
    b[64:69] = packed_item(0)
    b[69:74] = packed_item(vat)
    b[74:79] = packed_item(0)
    b[79:84] = packed_item(0)
    b[84:89] = packed_item(0)
    b[89:94] = packed_item(paid)
    b[94] = ord("0")
    b[96:100] = struct.pack(">i", 0)
    b[100:104] = struct.pack(">i", 0)
    b[105:109] = struct.pack("<i", cr)
    b[109] = ord(" ")
    return bytes(b)


def invoice_header(number: int, customer: str, day: int, invoice_type: int,
                   desc: str, net: int, vat: int) -> bytes:
    b = bytearray(b" " * INVOICE)
    b[0:8] = f"{number:08d}".encode()
    b[8] = ord("L")
    b[9] = 0                                             # ih-test: header
    b[10:16] = customer[:6].ljust(6).encode()
    b[16] = ord(customer[6:7] or " ")
    b[17:21] = struct.pack("<i", day)
    b[21:31] = f"ORDER-{number:04d}".encode()[:10]
    b[31] = ord(str(invoice_type))
    b[32:42] = f"REF-{number:06d}".encode()[:10]
    b[42:74] = desc.ljust(32).encode()[:32]
    for slot in range(8):
        b[74 + slot * 5: 79 + slot * 5] = packed_item(0)
    b[79:84] = packed_item(net)                          # ih-net
    b[94:99] = packed_item(vat)                          # ih-vat
    b[114] = ord("I")                                    # ih-status
    b[115:120] = b"abcde"
    b[120] = 1
    b[122:126] = struct.pack(">i", 0)
    b[126:130] = struct.pack(">i", 0)
    b[131:134] = struct.pack("<i", 0)[:3]
    return bytes(b)


def build(target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    run_day = days(2026, 11, 3)

    sales = [
        sales_row("CUST011", "Alpha Analytical Ltd", "1 Mill Lane\\Bristol\\\\",
                  "Avon", current=1_500_00, q=[100_00, 200_00, 300_00, 400_00],
                  limit=5_000, unapplied=250_00),
        sales_row("CUST022", "Beta Bolts", "9 Forge Road\\Leeds\\\\",
                  "Yorkshire", current=750_00, q=[0, 0, 0, 0], limit=2_000),
        sales_row("CUST033", "Gamma Gaskets", "12 Old Wharf\\Hull\\\\",
                  "Humberside", current=0, q=[0, 0, 0, 0], limit=1_000),
    ]
    (target / "sales.flat").write_bytes(b"".join(sales))

    items = [
        open_item("CUST011", 41, run_day - 5, 2, "Steel brackets", net=200_00, vat=35_00),
        open_item("CUST011", 42, run_day - 35, 2, "Fixing kits", net=310_00, vat=54_25),
        open_item("CUST011", 43, run_day - 75, 2, "Anchor bolts", net=90_00, vat=15_75, hold="Q"),
        open_item("CUST011", 44, run_day - 120, 2, "Steel plate", net=400_00, vat=70_00),
        open_item("CUST011", 45, run_day - 10, 3, "Returned goods", net=120_00, vat=21_00, paid=20_00, cr=run_day - 9),
        open_item("CUST011", 0, run_day - 2, 5, "", paid=500_00),
        open_item("CUST022", 51, run_day - 45, 2, "Washers", net=750_00, vat=131_25),
    ]
    items.sort(key=lambda row: (row[0:7], struct.unpack("<I", row[7:11])[0]))
    (target / "openitm3.flat").write_bytes(b"".join(items))

    invoices = [
        invoice_header(41, "CUST011", run_day - 5, 2, "Steel brackets", 200_00, 35_00),
        invoice_header(42, "CUST011", run_day - 35, 2, "Fixing kits", 310_00, 54_25),
        invoice_header(45, "CUST011", run_day - 10, 3, "Returned goods", -120_00, 21_00),
        invoice_header(51, "CUST022", run_day - 45, 2, "Washers", 750_00, 131_25),
    ]
    invoices.sort(key=lambda row: row[0:9])
    (target / "invoice.flat").write_bytes(b"".join(invoices))


if __name__ == "__main__":
    build(Path(sys.argv[1]))
