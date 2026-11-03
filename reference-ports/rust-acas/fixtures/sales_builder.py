#!/usr/bin/env python3
"""Sales-ledger fixture builder.

sl060 reads the sales file for every staged open item and `rewrite`s the row,
so the chained scenario needs a sales file that already holds the customers
its invoices name. This derives one 300-byte row per distinct customer out of
a case's `invoice.flat` — the same bytes the invoice side carries — and gives
each a deterministic name so the report and the posting legend are stable
without anyone hand-authoring 300-byte records.

Layout: F-B009 Part 2. Customers are the 7 bytes at offset 11 of a header
record (item-nos 0); `sales-status` is 1 (live) so no window re-opening is
exercised, and `sales-credit` is the ACAS default 30 days.
"""
from __future__ import annotations

import sys
from pathlib import Path

RECORD = 300
HEADER_MARK = 9  # item-nos


def build(case_dir: Path) -> Path:
    source = (case_dir / "invoice.flat").read_bytes()
    if len(source) % 134:
        raise SystemExit(f"{case_dir}/invoice.flat is not a multiple of 134")
    customers: list[bytes] = []
    for at in range(0, len(source), 134):
        record = source[at:at + 134]
        if record[HEADER_MARK] != 0:
            continue
        key = record[10:17]
        if key not in customers:
            customers.append(key)

    rows = bytearray()
    for key in customers:
        row = bytearray(b" " * RECORD)
        row[0:7] = key
        row[7:7 + 30] = f"{key.decode('ascii', 'replace')} Trading Co".ljust(30).encode()[:30]
        row[37:37 + 48] = b"1 Example Street".ljust(48)
        row[193] = ord("1")        # sales-status: live
        row[204:206] = b"30"       # sales-credit, days
        rows += row

    out = case_dir / "sales.flat"
    out.write_bytes(bytes(rows))
    return out


if __name__ == "__main__":
    print(build(Path(sys.argv[1])))
