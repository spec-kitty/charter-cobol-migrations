#!/usr/bin/env python3
"""Ledger, batch and posting fixtures for the gl072 batch update (menu H).

`gl072` is the writer of ledger balances, so the fixture exists to put every
control path of the program on the page at once:

* batches: two ordinary posting batches and one whose legs overflow a page,
  all closed and waiting because `gl070` posts nothing while an open batch
  exists; a processed batch and a batch from another cycle, both skipped;
  and a row with an all-zero key, skipped by `gl070` itself;
* legs: debit, credit, both VAT sides, a zero-VAT posting, a zero key, and a
  posting whose debit account does not exist — the record area then still holds
  the previous account, so its brought-forward row repeats it (F-B072 Part 6);
* balances: positive, negative and zero accounts, plus one account no posting
  touches at all.

Layouts are measured in `docs/fd-evidence/F-B072-gl-post-apply.md`: ledger 126
bytes, batch 96, posting 98 with the amount overpunched (F-B009 Part 3).

Accounts are written as an eight-digit number followed by the two-digit p.c.,
and the account fields themselves are the six bytes `ledger-nos` has: an
eight-digit literal assigned to a six-byte slice grows the record silently, so
every account goes through `[:6]` (DP-022).
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

LEDGER = 126
BATCH = 96
POSTING = 98

OVERPUNCH = "pqrstuvwxy"
CYCLE = 12
RUN_DAY = 155_535  # 2026-11-02, F-B001


def overpunch(cents: int) -> bytes:
    """Ten display digits with the sign on the last one (F-B009 Part 3)."""
    digits = f"{abs(cents) % 10_000_000_000:010d}"
    last = digits[-1]
    if cents < 0:
        last = OVERPUNCH[int(last)]
    return (digits[:-1] + last).encode()


def packed(cents: int) -> bytes:
    """`s9(8)v99 comp-3` — ten digits, sign in the final nibble."""
    nibbles = f"{abs(cents) % 10_000_000_000:010d}"
    out = bytearray()
    for pair in range(0, 10, 2):
        out.append(int(nibbles[pair]) << 4 | int(nibbles[pair + 1]))
    out.append(0x00 << 4 | (0x0D if cents < 0 else 0x0C))
    return bytes(out)


def ledger_row(nos: str, pc: str, name: str, balance: int, *, kind: str = "1") -> bytes:
    b = bytearray(b" " * LEDGER)
    b[0:6] = nos.encode()[:6]
    b[6:8] = pc.encode()[:2]
    b[8] = ord(kind)
    b[9] = ord("B")
    b[10] = ord("1")
    b[16:40] = name.ljust(24).encode()[:24]
    b[40:46] = packed(balance)
    b[46:52] = packed(0)
    for slot in range(4):
        b[52 + slot * 6: 58 + slot * 6] = packed(0)
    return bytes(b)


def batch_row(number: int, description: str, *, status: int = 0, cleared: int = 0,
              cycle: int = CYCLE) -> bytes:
    b = bytearray(b" " * BATCH)
    b[0] = ord("1")                       # gl-batch
    b[1:6] = f"{number:05d}".encode()
    b[6:8] = b"00"                        # items
    b[8] = ord(str(status))
    b[9] = ord(str(cleared))
    b[10:12] = f"{cycle:02d}".encode()
    b[12:28] = struct.pack("<4i", 0, 0, 0, 0)
    for slot in range(4):
        b[28 + slot * 6: 34 + slot * 6] = packed(0)
    b[52:76] = description.ljust(24).encode()[:24]
    b[76:78] = b"00"                      # bdefault
    b[78:80] = b"  "                      # convention
    b[80:86] = b"000000"                  # batch-def-ac
    b[86:88] = b"00"
    b[88:90] = b"JD"
    b[90] = ord("N")
    b[91:96] = f"{number:05d}".encode()
    return bytes(b)


def posting_row(batch: int, post: int, *, dr: tuple[str, str], cr: tuple[str, str],
                amount: int, legend: str, date: bytes = b"01/04/26",
                vat: tuple[str, str, str, int] | None = None) -> bytes:
    b = bytearray(b" " * POSTING)
    b[0:5] = f"{batch:05d}".encode()
    b[5:10] = f"{post:05d}".encode()
    b[10:12] = b"JD"
    b[12:20] = date
    b[20:26] = dr[0].encode()[:6]      # post-dr is 9(6); the pc is separate
    b[26:28] = dr[1].encode()[:2]
    b[28:34] = cr[0].encode()[:6]
    b[34:36] = cr[1].encode()[:2]
    b[36:46] = overpunch(amount)
    b[46:78] = legend.ljust(32).encode()[:32]
    ac, pc, side, vat_amount = vat or ("000000", "00", "  ", 0)
    b[78:84] = ac.encode()[:6]
    b[84:86] = pc.encode()[:2]
    b[86:88] = side.encode()[:2]
    b[88:98] = overpunch(vat_amount)
    return bytes(b)


def build(case: str) -> dict[str, bytes]:
    ledger = [
        ledger_row("00001000", "00", "SALES DAY BOOK", 150_000),
        ledger_row("00002000", "00", "SALES LEDGER CONTROL", -42_000),
        ledger_row("00003000", "00", "VAT ACCOUNT", 0),
        ledger_row("00004000", "00", "CREDIT NOTES", 0),
        ledger_row("00005000", "00", "CASH BOOK", -7_500),
        ledger_row("00007000", "00", "PURCHASE CONTROL", 33_333),
        ledger_row("00008000", "00", "OVERFLOW DEBIT", 9_000),
        ledger_row("00009000", "00", "OVERFLOW CREDIT", -9_000),
        ledger_row("00099900", "00", "UNTOUCHED", 12_345),
        # `00006000` is deliberately absent: the debit leg of posting 4 misses.
    ]
    batches = [
        batch_row(1, "ORDINARY BATCH", status=1),
        batch_row(2, "SECOND BATCH", status=1),
        batch_row(3, "THIRD BATCH", status=1),
        batch_row(4, "PROCESSED BATCH", status=1, cleared=1),
        batch_row(5, "OTHER CYCLE", status=1, cycle=11),
        batch_row(6, "OVERFLOW BATCH", status=1),
    ]
    postings = [
        posting_row(0, 0, dr=("00001000", "00"), cr=("00002000", "00"),
                    amount=50_000, legend="ZERO KEY ROW"),
        posting_row(1, 1, dr=("00001000", "00"), cr=("00002000", "00"),
                    amount=50_000, legend="SALES DAY BOOK",
                    vat=("00003000", "00", "CR", 10_000)),
        posting_row(1, 2, dr=("00001000", "00"), cr=("00004000", "00"),
                    amount=-25_000, legend="CREDIT NOTE"),
        posting_row(1, 3, dr=("00005000", "00"), cr=("00002000", "00"),
                    amount=12_345, legend="VAT ON THE OTHER SIDE",
                    vat=("00003000", "00", "DR", 2_345)),
        posting_row(1, 4, dr=("00006000", "00"), cr=("00002000", "00"),
                    amount=7_000, legend="MISSING ACCOUNT"),
        posting_row(2, 1, dr=("00007000", "00"), cr=("00003000", "00"),
                    amount=1_000, legend="SECOND BATCH ROW"),
        # Batch 3 posts; 4 (processed) and 5 (other cycle) are skipped by
        # gl070's filter.
        posting_row(3, 1, dr=("00001000", "00"), cr=("00002000", "00"),
                    amount=1_111, legend="THIRD BATCH ROW"),
        posting_row(4, 1, dr=("00001000", "00"), cr=("00002000", "00"),
                    amount=2_222, legend="PROCESSED"),
        posting_row(5, 1, dr=("00001000", "00"), cr=("00002000", "00"),
                    amount=3_333, legend="OTHER CYCLE"),
    ]
    # 25 alternating legs on batch 6: 50 rows, against a 48-line page.
    for index in range(1, 26):
        if index % 2:
            dr, cr = ("00008000", "00"), ("00009000", "00")
        else:
            dr, cr = ("00009000", "00"), ("00008000", "00")
        postings.append(
            posting_row(6, index, dr=dr, cr=cr, amount=index * 100,
                        legend=f"OVERFLOW ROW {index:02d}")
        )

    if case == "post":
        return {
            "ledger.flat": b"".join(ledger),
            "batch.flat": b"".join(batches),
            "posting.flat": b"".join(postings),
        }
    if case == "empty":
        # One closed, waiting batch and no postings at all: `gl070` runs right
        # through and hands `gl072` an empty stream, which still prints its
        # closing account block.
        return {
            "ledger.flat": b"".join(ledger),
            "batch.flat": batch_row(1, "EMPTY BATCH", status=1),
            "posting.flat": b"",
        }
    if case == "open":
        # One open batch stops the run at gl070's Phase 1 screen. It goes last
        # so the keys stay ascending — the INDEXED WRITE drops an out-of-order
        # record with status 22 (DP-020's lesson).
        batches.append(batch_row(7, "STILL OPEN"))
        return {
            "ledger.flat": b"".join(ledger),
            "batch.flat": b"".join(batches),
            "posting.flat": b"".join(postings),
        }
    raise SystemExit(f"unknown case {case}")


def main() -> None:
    target = Path(__file__).resolve().parent
    for case in ("post", "open", "empty"):
        out = target / "generated" / f"gl072-{case}"
        out.mkdir(parents=True, exist_ok=True)
        for name, blob in build(case).items():
            (out / name).write_bytes(blob)
        print(f"{case}: {out}")


if __name__ == "__main__":
    sys.exit(main())
