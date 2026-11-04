#!/usr/bin/env python3
"""Open-item and sales fixtures for the sl095 payment proof report (menu J).

`sl095` reads the file `sl090` has just sorted and prints two blocks: a payment
block and a journal block, each with its own totals, plus an appropriation
sub-line under every invoice the *preceding* payment named.

The stream is laid out so the sort puts the interesting adjacencies in place:

* in one batch slot `s-type` descends, so a journal (6) and a payment (5) come
  before the account rows (2) that follow them — that is what makes the
  customer-carry (`save-customer`) reachable at all;
* the appropriation sub-line is clamped by `sav-approp`, the *payment's* own
  net; the first invoice is paid more than that and is cut back, the second is
  paid less and prints its own figure;
* one invoice's legs are less than its payment, so its balance goes negative
  and carries `CR`;
* an unknown customer (CUST043) prints the `!! Customer Unknown` literal and
  still adds to the totals;
* a closed payment (status 1), a type 9, a type 4, an invoice under a different
  customer, and an invoice with no payment are each skipped — but a closed
  *invoice* still prints, because only the payment path tests `s-open`;
* a receipt (1) and a credit note (3) never reach `sl095` — the sort drops them.

The frames are written in ascending `(customer, invoice)` key order because
`loadoi3` uses sequential access, where an out-of-order write answers status 22
and silently drops the record.

Layout is `fdoi3.cob`/`wsoi.cob`, 114 bytes (F-B008/F-B090).
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
    """`s9(7)v99` — nine digits, five bytes."""
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
              paid: int = 0, extra: int = 0, carriage: int = 0,
              discount: int = 0, e_vat: int = 0, c_vat: int = 0,
              deduct: int = 0, deduct_vat: int = 0, status: int = 0) -> bytes:
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
    b[54:59] = packed_item(net)        # oi-approp redefines oi-net
    b[59:64] = packed_item(extra)
    b[64:69] = packed_item(carriage)
    b[69:74] = packed_item(vat)
    b[74:79] = packed_item(discount)
    b[79:84] = packed_item(e_vat)
    b[84:89] = packed_item(c_vat)
    b[89:94] = packed_item(paid)
    b[94] = ord(str(status))
    b[95] = 0
    b[96:100] = struct.pack(">i", deduct)
    b[100:104] = struct.pack(">i", deduct_vat)
    b[104] = 0
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
        # slot (0,1) — the journal sorts ahead of the payment in this slot
        open_item("CUST042", 916, today - 40, (0, 1), 6, "Unapplied cash", net=9_000, paid=5_000),
        # slot (0,2) — the payment whose appropriation the sub-lines clamp to
        open_item("CUST042", 917, today - 14, (0, 2), 5, "Cheque", net=4_000, paid=10_000),
        # slot (0,3) — two invoices for the paying customer
        open_item("CUST042", 918, today - 11, (0, 3), 2, "Enamel batch", net=20_000,
                  vat=3_500, extra=700, carriage=300, discount=200, e_vat=100,
                  c_vat=150, deduct=400, deduct_vat=50, paid=5_000),
        open_item("CUST042", 919, today - 10, (0, 3), 2, "Glaze", net=1_000, vat=175,
                  paid=2_500),
        # slot (0,4) — a *closed* invoice: the invoice path never tests `s-open`
        open_item("CUST042", 931, today - 9, (0, 4), 2, "Settled", net=500, vat=87,
                  paid=2_500, status=1),
        # slot (1,1) — unknown customer, counted in the totals all the same
        open_item("CUST043", 920, today - 9, (1, 1), 5, "Draft", net=2_500, paid=2_500),
        # slot (1,2) — closed, so `s-open` fails
        open_item("CUST041", 921, today - 8, (1, 2), 5, "Old cheque", net=0,
                  paid=123_456, status=1),
        # slot (1,3) — type 9 is neither 5 nor 6, and type 4 is a proforma
        open_item("CUST041", 922, today - 7, (1, 3), 9, "Old payment", net=0, paid=99_900),
        open_item("CUST041", 929, today - 7, (1, 3), 4, "Proforma", net=700, paid=99_900),
        # slot (1,4) — invoice under a customer that is not the carried one
        open_item("CUST041", 923, today - 6, (1, 4), 2, "Dies", net=500, vat=8_750, paid=77_700),
        # slot (2,1) — a payment for CUST041 so the next slot has a carried key
        open_item("CUST041", 926, today - 5, (2, 1), 5, "Giro", net=0, paid=50_000),
        # slot (2,2) — reachable, but with a zero appropriation to clamp to
        open_item("CUST041", 925, today - 4, (2, 2), 2, "Press", net=50, vat=875, paid=10_000),
        # slot (2,3) — an invoice nobody paid
        open_item("CUST041", 924, today - 3, (2, 3), 2, "Punch", net=300, paid=0),
        # dropped by the sort: a receipt and a credit note
        open_item("CUST041", 927, today - 2, (3, 1), 1, "Receipt", net=0, paid=1_000),
        open_item("CUST041", 928, today - 1, (3, 1), 3, "Cr. note", net=250, vat=43_750),
    ]
    # `loadoi3` writes an INDEXED table in sequential mode, so the frames must
    # arrive in ascending key order or every later write fails (status 22).
    rows.sort(key=lambda row: (row[0:7], struct.unpack("<I", row[7:11])[0]))
    (target / "openitm3.flat").write_bytes(b"".join(rows))


def build_busy(target: Path) -> None:
    """A page-break dataset: 26 payments, all for the known CUST042."""
    target.mkdir(parents=True, exist_ok=True)
    today = days(2026, 11, 3)
    sales = [sales_row("CUST042", "Epsilon Enamels", "22 Foundry St\\Stoke\\\\", "Staffs")]
    (target / "sales.flat").write_bytes(b"".join(sales))
    rows = [
        open_item("CUST042", 900 + n, today - 60 + n, (1, n + 1), 5, f"Cheque {n}", net=0,
                  paid=(n + 1) * 10_00)
        for n in range(26)
    ]
    rows.sort(key=lambda row: (row[0:7], struct.unpack("<I", row[7:11])[0]))
    (target / "openitm3.flat").write_bytes(b"".join(rows))


if __name__ == "__main__":
    which = sys.argv[2] if len(sys.argv) > 2 else "proof"
    (build_busy if which == "busy" else build)(Path(sys.argv[1]))
