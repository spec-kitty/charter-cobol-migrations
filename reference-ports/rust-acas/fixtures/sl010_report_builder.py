#!/usr/bin/env python3
"""Sales + delivery fixtures for the sl010 customer report (menu 4).

`sl010`'s listing prints a customer row, its address, an optional delivery
address block and an optional notes line. The dump builder cannot serve here:
it authors no delivery records, no address delimiters and no over-long page.

This builder authors a 16-row ledger that forces every branch of the report:

* an address `\`-delimited (the ACAS convention the report rewrites to `,`)
* both delivery and notes tags, with and without the matching record present
* a blank credit and a blank money field
* a negative balance
* a phone with an extension (the `x` extension string)
* enough plain customers to cross `page-lines` (48) twice

Layout: `copybooks/fdsl.cob`, 300 bytes; delivery layout `copybooks/fddel.cob`,
134 bytes with the 8-byte `type + sales-key` key. Two-byte `comp` is big-endian,
`binary-long` is little-endian (F-B006/F-B009). Day numbers are relative to the
F-B001 epoch so the overdue band stays stable.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

RECORD = 300
DELIVERY = 134
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
    def __init__(self, key: str, name: str, addr1: str, addr2: str) -> None:
        self.b = bytearray(b" " * RECORD)
        self.b[0:7] = key.ljust(7).encode()[:7]
        self.b[7:37] = name.ljust(30).encode()[:30]
        self.b[37:85] = addr1.ljust(48).encode()[:48]
        self.b[85:133] = addr2.ljust(48).encode()[:48]
        self.status(1)

    def status(self, live: int) -> "Row":
        self.b[193] = ord(str(live))
        return self

    def phone(self, number: str, ext: str = "") -> "Row":
        self.b[133:146] = number.ljust(13).encode()[:13]
        self.b[146:150] = ext.ljust(4).encode()[:4]
        return self

    def fax(self, number: str) -> "Row":
        self.b[180:193] = number.ljust(13).encode()[:13]
        return self

    def credit(self, n: int | None) -> "Row":
        if n is not None:
            self.b[204:206] = f"{n:02d}".encode()
        return self

    def discount(self, hundredths: int) -> "Row":
        self.b[206:208] = struct.pack(">h", hundredths)
        return self

    def late_min_max(self, lo: int, hi: int) -> "Row":
        self.b[208:210] = struct.pack("<h", lo)
        self.b[210:212] = struct.pack("<h", hi)
        return self

    def longs(self, limit: int, activety: int, last_inv: int, last_pay: int, average: int,
              create_date: int) -> "Row":
        for at, value in ((212, limit), (216, activety), (220, last_inv),
                          (224, last_pay), (228, average), (244, create_date)):
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

    def email(self, address: str, invoice: int, statement: int, letters: int) -> "Row":
        self.b[150:180] = address.encode().ljust(30)
        self.b[196] = ord(str(invoice))
        self.b[197] = ord(str(statement))
        self.b[198] = ord(str(letters))
        return self

    def flags(self, late: int, dunning: int, delivery: int, notes: int) -> "Row":
        self.b[194] = ord(str(late))
        self.b[195] = ord(str(dunning))
        self.b[199] = ord(str(delivery))
        self.b[200] = ord(str(notes))
        return self


def delivery(kind: str, key: str, name: str, lines: list[str]) -> bytes:
    """One `fddel.cob` record: type, key, 30-byte name, 96-byte address."""
    assert kind in ("D", "N")
    body = bytearray(b" " * DELIVERY)
    body[0] = ord(kind)
    body[1:8] = key.ljust(7).encode()
    body[8:38] = name.encode().ljust(30)[:30]
    joined = "\\".join(lines)
    body[38:134] = joined.encode().ljust(96)[:96]
    return bytes(body)


ADDRESS = ("14 Ash Row", "Ashwick\\Ashtown")


def build(out_dir: Path) -> tuple[Path, Path]:
    rows = [
        # 1. delivery + notes records present, CR money, email legend, both flags.
        Row("CUSTS10", "Acorn Trading Co", *ADDRESS)
        .phone("01234 567890", "").fax("01234 567891")
        .credit(7).discount(1000).late_min_max(5, 30)
        .longs(500_000, 3, days(2026, 10, 24), days(2026, 10, 1), 2500, days(2024, 1, 2))
        .money(123_456, -9999, 3456)
        .email("acorn@example.test", 1, 1, 1).flags(1, 1, 1, 1),
        # 2. plain live customer.
        Row("CUSTS20", "Birchwood Supplies", "9 Birch Lane", "Birchton")
        .credit(30).longs(100_000, 1, days(2026, 10, 20), 0, 100, days(2025, 6, 1))
        .money(0, 0, 0).flags(0, 0, 0, 0),
        # 3. dormant, blank credit, blank money.
        Row("CUSTS30", "Cedar Engineering Ltd", "2 Cedar Way", "Cedarton")
        .status(0).longs(0, 0, 0, 0, 0, 0).flags(0, 0, 0, 0),
        # 4. negative balance, delivery tag set but NO delivery record.
        Row("CUSTS40", "Dunmore &amp; Sons", "5 Dunmore Rd", "Dunville")
        .credit(60).longs(250_000, 4, days(2026, 11, 1), 0, 400, days(2026, 1, 9))
        .money(-123_456, 0, 0).flags(0, 0, 1, 0),
        # 5. notes tag set but NO notes record; extension phone.
        Row("CUSTS50", "Elmfield Partners", "3 Elm Court", "Elmsted")
        .phone("01999 111222", "417").credit(30)
        .longs(75_000, 7, days(2026, 10, 30), days(2026, 10, 20), 75_000, days(2023, 3, 4))
        .money(50_000, 25_000, 0).email("elmfield@example.test", 1, 0, 0)
        .flags(0, 0, 0, 1),
    ]
    # 6..16. plain customers, enough to cross `page-lines` and come back.
    for index, suffix in enumerate("6789ABCDEFG", start=6):
        key = f"CUSTS{suffix}0"
        rows.append(
            Row(key, f"Customer {index:02d} Ltd", f"{index} Test Street", "Testville")
            .credit(30).longs(0, 1, 0, 0, 500, days(2026, 2, index))
            .money(0, 0, 0).flags(0, 0, 0, 0)
        )

    out_dir.mkdir(parents=True, exist_ok=True)
    sales = out_dir / "sales.flat"
    sales.write_bytes(b"".join(bytes(row.b) for row in rows))

    deliv = out_dir / "delivery.flat"
    deliv.write_bytes(
        delivery("D", "CUSTS10", "Acorn Warehouse", ["Unit 4\\Ashwick Ind Est", "Ashwick"])
        + delivery("N", "CUSTS10", "", ["Deliver after 9am", "Ring the bell twice"])
    )
    return sales, deliv


if __name__ == "__main__":
    print(*build(Path(sys.argv[1])))
