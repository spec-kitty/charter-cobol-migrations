#!/usr/bin/env python3
"""Sales-ledger fixture for the customer-file dump (sl170).

`sales_builder.py` derives a uniform sales file from an invoice case: every
customer live, credit 30, every money field blank. That is enough for the
posting chain but it exercises almost no branch of a *report*, so this builder
hand-authors a small ledger instead — one row per case the dump has to get
right (live/dead, credit and activity bands, blank money, negatives, the email
legend, a page break at the fifth row).

Layout: `copybooks/fdsl.cob`, 300 bytes. Two-byte `comp` fields are big-endian
and four-byte `binary-long` little-endian, as measured in F-B006/F-B009.
`last-inv` and `last-pay` are day numbers relative to the F-B001 epoch
(1600-12-31) so the overdue bands stay stable as the clock moves.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

RECORD = 300
EPOCH_JDN = 2_305_813


def days(y: int, m: int, d: int) -> int:
    """JDN of a date minus the ACAS epoch."""
    y0, m0 = y, m
    a = (14 - m0) // 12
    y1 = y0 + 4800 - a
    m1 = m0 + 12 * a - 3
    jdn = d + (153 * m1 + 2) // 5 + 365 * y1 + y1 // 4 - y1 // 100 + y1 // 400 - 32045
    return jdn - EPOCH_JDN


def packed(cents: int) -> bytes:
    digits = f"{abs(cents) % 10_000_000_000:010d}"
    nibbles = "0" + digits
    out = bytearray()
    for pair in range(0, 10, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(int(nibbles[10]) << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


class Row:
    def __init__(self, key: str, name: str) -> None:
        self.b = bytearray(b" " * RECORD)
        self.b[0:7] = key.ljust(7).encode()
        self.b[7:37] = name.ljust(30).encode()[:30]
        self.b[37:85] = b"1 Example Street".ljust(48)
        self.b[85:133] = b"Somewhere".ljust(48)
        self.b[133:146] = b"01234 567890".ljust(13)
        self.status(1)

    def status(self, live: int) -> "Row":
        self.b[193] = ord(str(live))
        return self

    def credit(self, n: int) -> "Row":
        self.b[204:206] = f"{n:02d}".encode()
        return self

    def discount(self, hundredths: int) -> "Row":
        self.b[206:208] = struct.pack(">h", hundredths)
        return self

    def late_min_max(self, lo: int, hi: int) -> "Row":
        # `binary-short` is native little-endian; `comp` (the discount) is
        # big-endian. Measured, F-B011 Part 2.
        self.b[208:210] = struct.pack("<h", lo)
        self.b[210:212] = struct.pack("<h", hi)
        return self

    def longs(self, limit: int, activety: int, last_inv: int, last_pay: int, average: int) -> "Row":
        for at, value in ((212, limit), (216, activety), (220, last_inv),
                          (224, last_pay), (228, average)):
            self.b[at:at + 4] = struct.pack("<i", value)
        return self

    def money(self, current: int | None, last: int | None, unapplied: int | None) -> "Row":
        if current is not None:
            self.b[248:254] = packed(current)
        if last is not None:
            self.b[254:260] = packed(last)
        if unapplied is not None:
            self.b[284:290] = packed(unapplied)
        return self

    def turnover(self, *values: int) -> "Row":
        for slot, value in enumerate(values):
            self.b[260 + slot * 6:266 + slot * 6] = packed(value)
        return self

    def email(self, address: str, invoice: int, statement: int, letters: int) -> "Row":
        self.b[150:180] = address.encode().ljust(30)
        self.b[196] = ord(str(invoice))
        self.b[197] = ord(str(statement))
        self.b[198] = ord(str(letters))
        return self

    def flags(self, late: int, dunning: int, notes: int) -> "Row":
        self.b[194] = ord(str(late))
        self.b[195] = ord(str(dunning))
        self.b[200] = ord(str(notes))
        return self


def build(out_dir: Path) -> Path:
    rows = [
        # 1. everything set: CR money, a credit band, an email legend.
        Row("CUSTD10", "Acorn Trading Co")
        .credit(7).discount(1000).late_min_max(5, 30)
        .longs(500_000, 3, days(2026, 10, 24), days(2026, 10, 1), 2500)
        .money(123_456, -9999, 3456)
        .turnover(150_000, 175_000, 120_000, 90_000)
        .email("acorn@example.test", 1, 0, 0)
        .flags(0, 0, 1),
        # 2. dormant, blank money.
        Row("CUSTD20", "Birchwood Supplies").status(0).credit(30)
        .longs(0, 0, 0, 0, 0).flags(0, 0, 0),
        # 3. long credit, big numbers, late + dunning.
        Row("CUSTD30", "Cedar Engineering Ltd")
        .credit(60).longs(9_999_999, 42, days(2025, 9, 30), days(2025, 10, 31), 999_999)
        .money(999_999_999, 88_888_888, 0)
        .turnover(999_999, 888_888, 777_777, 666_666)
        .flags(1, 1, 0),
        # 4. blank credit and blank money, negative balance.
        Row("CUSTD40", "Dunmore & Sons")
        .longs(0, 1, days(2026, 11, 1), 0, 100)
        .money(-123_456, 0, 0).flags(0, 0, 0),
        # 5. every email switch on: the legend chain.
        Row("CUSTD50", "Elmfield Partners")
        .credit(30).longs(250_000, 7, days(2026, 10, 30), days(2026, 10, 20), 75_000)
        .money(50_000, 25_000, 0)
        .email("elmfield@example.test", 1, 1, 1).flags(0, 0, 0),
        # 6. past the page break: one plain live customer.
        Row("CUSTD60", "Foxhill Motors")
        .credit(30).longs(0, 2, 0, 0, 400)
        .money(0, 0, 0).flags(0, 0, 0),
    ]
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / "sales.flat"
    out.write_bytes(b"".join(bytes(row.b) for row in rows))
    return out


if __name__ == "__main__":
    print(build(Path(sys.argv[1])))
