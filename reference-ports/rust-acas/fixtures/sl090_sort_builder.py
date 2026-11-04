#!/usr/bin/env python3
"""Open-item and sales fixtures for the sl090 payment-proof sort (menu J).

`sl090` is a sort, so the fixture exists to make the *order* checkable: batch
number leads, batch item follows, `s-type` descends inside a slot and date then
invoice settle the rest. The rows that must not survive — a receipt (type 1), a
credit note (type 3) and a batch-zero row — sit in the middle of the stream so
a naive copy is visibly wrong.

Layout is `fdoi3.cob`/`wsoi.cob`, 114 bytes (F-B008/F-B090): key 0-6, invoice
7-10, date 11-14, `oi-batch` 15-20 (`comp`, high byte first), `oi-type` 21,
description 22-46, hold 47, unapl 48, money from 49.

Two customers exist so the sales file `sl095` opens afterwards has rows to pair
against; the sort itself ignores the name.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

SALES = 300
OPEN_ITEM = 114
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    a = (14 - m) // 12
    y1 = y + 4800 - a
    m1 = m + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


def packed_item(cents: int) -> bytes:
    """`s9(7)v99 comp-3` — nine digits, five bytes."""
    nibbles = f"{abs(cents) % 1_000_000_000:09d}"
    out = bytearray()
    for pair in range(0, 8, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[8]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def packed_wide(cents: int) -> bytes:
    nibbles = "0" + f"{abs(cents) % 10_000_000_000:010d}"
    out = bytearray()
    for pair in range(0, 10, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[10]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def sales_row(key: str, name: str, addr1: str, addr2: str, **money: int) -> bytes:
    b = bytearray(b" " * SALES)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7:37] = name.ljust(30).encode()[:30]
    b[37:85] = addr1.ljust(48).encode()[:48]
    b[85:133] = addr2.ljust(48).encode()[:48]
    b[193] = ord("1")
    b[204:206] = b"30"
    b[206:208] = struct.pack(">h", 0)
    b[212:216] = struct.pack("<i", money.get("limit", 0))
    b[248:254] = packed_wide(money.get("current", 0))
    b[254:260] = packed_wide(0)
    for slot in range(4):
        b[260 + slot * 6: 266 + slot * 6] = packed_wide(0)
    b[284:290] = packed_wide(money.get("unapplied", 0))
    return bytes(b)


def open_item(key: str, invoice: int, day: int, batch: tuple[int, int],
              item_type: int, desc: str, *, net: int = 0, vat: int = 0,
              paid: int = 0) -> bytes:
    b = bytearray(b" " * OPEN_ITEM)
    b[0:7] = key.ljust(7).encode()[:7]
    b[7:11] = struct.pack("<I", invoice)
    b[11:15] = struct.pack("<i", day)
    b[15:19] = struct.pack(">I", batch[0])
    b[19:21] = struct.pack(">H", batch[1])
    b[21] = ord(str(item_type))
    b[22:47] = desc.ljust(25).encode()[:25]
    b[47] = ord(" ")
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
    b[105:109] = struct.pack("<i", 0)
    b[109] = ord(" ")
    b[110:114] = struct.pack("<i", 0)
    return bytes(b)


def build(target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    today = days(2026, 11, 3)

    sales = [
        sales_row("CUST041", "Delta Dies Ltd", "4 Kiln Way\\Derby\\\\", "Derbyshire",
                  current=1_200_00, limit=8_000),
        sales_row("CUST042", "Epsilon Enamels", "22 Foundry St\\Stoke\\\\", "Staffs",
                  current=640_00, limit=4_000),
    ]
    (target / "sales.flat").write_bytes(b"".join(sales))

    rows = [
        # batch 0 — no number, but the item still counts as a batch slot
        open_item("CUST041", 111, today - 30, (0, 1), 2, "Steel dies", net=200_00, vat=35_00),
        open_item("CUST042", 211, today - 12, (0, 2), 5, "Cash", net=0, paid=150_00),
        open_item("CUST041", 112, today - 14, (0, 2), 2, "Press tools", net=310_00, vat=54_25),
        # dropped: receipt, credit note, batch-zero pair
        open_item("CUST041", 117, today - 9, (3, 1), 1, "Receipt", net=0, paid=99_00),
        open_item("CUST041", 118, today - 8, (3, 1), 3, "Cr. note", net=45_00, vat=7_88),
        open_item("CUST042", 0, today - 7, (0, 0), 5, "Unbatched cash", net=0, paid=60_00),
        # batch 2 — the type runs 5 then 2 because it sorts downwards
        open_item("CUST041", 113, today - 20, (2, 1), 2, "Die blocks", net=90_00, vat=15_75),
        open_item("CUST042", 212, today - 5, (2, 1), 5, "Cheque", net=0, paid=210_00),
        open_item("CUST041", 114, today - 6, (2, 1), 6, "Unapplied", net=0, paid=75_00),
        # batch 5 — same slot, date decides
        open_item("CUST041", 120, today - 40, (5, 1), 2, "Older", net=55_00, vat=9_62),
        open_item("CUST041", 121, today - 10, (5, 1), 2, "Newer", net=65_00, vat=11_38),
        # batch 7 — item decides, and 100 must not sort before 7 lexically
        open_item("CUST042", 213, today - 3, (7, 2), 2, "Enamel", net=120_00, vat=21_00),
        open_item("CUST041", 115, today - 4, (7, 1), 5, "Giro", net=0, paid=130_00),
        open_item("CUST041", 116, today - 2, (100, 1), 2, "Late batch", net=88_00, vat=15_40),
    ]
    rows.sort(key=lambda row: (row[0:7], struct.unpack("<I", row[7:11])[0]))
    (target / "openitm3.flat").write_bytes(b"".join(rows))


if __name__ == "__main__":
    build(Path(sys.argv[1]))
