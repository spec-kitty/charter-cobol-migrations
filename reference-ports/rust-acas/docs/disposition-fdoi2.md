# Disposition ledger — fdoi2.cob / fdoi3.cob (open-item records, sl060)

sl060's input is the `open-item-file-2` staging sl055 writes; its output
`open-item-file-3` is the same 114-byte record (`fdoi3.cob` redefines only the
key over it, F-B009 Part 5). Offsets are the ones GnuCOBOL actually reads and
writes, measured in `docs/fd-evidence/F-B008`; `oi-header` is exactly 114
bytes, so **no field of this record is truncated in either direction** — the
truncation fossils live on the invoice record (F-B006), not here.

## open-item-record-2 / -3 — the raw FD, 114 bytes

**Disposition: carry.** `OpenItem2` (introduced under WP04) already has a
field-per-offset codec; sl060 reuses it unchanged and the OTM3 write is the
same 114 bytes in key order.

| COBOL field | PIC | Disposition | Rust landing site | Rationale |
|---|---|---|---|---|
| oi-key (oi-nos + oi-check) | x(6) + 9 | carry | `CustomerKey` | same 7-byte customer key the invoice/sales record uses; never validated to ASCII |
| oi-invoice | binary-long | carry | `InvoiceNumber(u32)` | key part 2; LE on the wire |
| oi-date | binary-long | carry | `i32` days since 1900 | converted to text only for the print line |
| oi-b-nos | 9(5) comp | carry | `u32` (always 0 from sl055) | written back untouched; sl060 never sets it |
| oi-b-item | 999 comp | carry | `u32` (always 0) | as above |
| oi-type | 9 | absorb → enum | `OpenItemType` | drives every branch below; digit character preserved on wire |
| oi-description | x(25) | carry | `[u8; 25]` | never interpreted |
| oi-hold-flag | x | carry | `u8` | |
| oi-unapl | x | carry | `u8` | |
| oi-p-c | s9(7)v99 comp-3 | carry | `Money` (i64 hundredths, 5 packed bytes) | decreased by credit-note apportionment, never negated on extract |
| oi-net (= oi-approp) | s9(7)v99 comp-3 | carry | `Money` | mask already applied by sl055; `oi-approp` is the same storage |
| oi-extra / oi-carriage / oi-vat / oi-discount / oi-e-vat / oi-c-vat | s9(7)v99 comp-3 | carry | `Money` each | summed into `work-net` / `work-vat` unchanged |
| oi-paid | s9(7)v99 comp-3 | carry | `Money` | **raised** by apportionment |
| oi-status | 9 (+88 s-open/s-closed) | absorb → bool | `closed: bool` | `s-closed` gates both read loops; the digit byte is regenerated from the bool |
| oi-deduct-days | binary-char | carry | `u8` | late-charge window in days |
| oi-deduct-amt | s999v99 comp | carry | `i32` (4 BE bytes) | zeroed when a credit note clears the deduction |
| oi-deduct-vat | s999v99 comp | carry | `i32` (4 BE bytes) | ditto |
| oi-days | binary-char | carry | `u8` | unused by sl060, preserved |
| oi-cr | binary-long | carry | `i32` (LE) | the credit note's own number; the apportionment key |
| oi-applied | x | carry | `u8` | unused by sl060, preserved |
| oi-date-cleared | binary-long | carry | `i32` | unused by sl060, preserved |

## Behaviors held on the record (not fields)

These are the fossil behaviors sl060 depends on and that a "cleaner" port would
lose. Each has a test.

1. **`oi-type` out of range crashes.** `total-net (a)` / `total-vat (a)` are
   subscripted by the *digit* of `oi-type`, and only buckets 1..3 exist. Types
   4/5/6/9 never reach OTM2 from sl055, so the Rust port keeps a 3-slot array
   and would panic rather than silently widen. (F-B010)
2. **The posting record is written once per open item, not per line.** The
   `ca000-BL-Write` banner says "for EACH line item in EACH invoice", but it is
   only `perform`ed once per OTM2 record, outside any line loop — sl055 already
   collapsed lines. Behaviour over comment.
3. **`post-legend` truncates silently.** STRING without `ON OVERFLOW` into a
   32-byte field: the invoice digits and `" : "` and customer name are cut at
   32 bytes, and the customer name in the sales file is what is copied.
4. **`sales-average` is integer-truncated.** `divide sales-activety into work-2
   giving sales-average` into a binary-long, so the running average floors.
5. **`work-2` is `s9(14) comp-3`, `work-1`/`work-a` are `s9(7)v99`.** The
   average multiply is 7-byte packed to 8-byte packed; a receipt/invoice pushes
   `sales-average` down even at small volumes.

## Recorded departures

Non-field departures for the parity gate, each with a STATUS.log entry.

### DP-004 — sales-file is read `record invalid key` but the customer-missing
path is a *write* path (2026-11-03, WP05)

`aa020-Read-Loop` moves the customer to the key, reads `record invalid key` and
on `INVALID KEY` sets `ws-reply = "X"`, `initialize sales-record`, writes
`"*** Customer Unknown ***"` into the name/print line and then, at the end of
the iteration, `write sales-record` (a new row, status forced live) instead of
`rewrite`. The Rust kernel takes the sales table as a `BTreeMap` keyed by
`CustomerKey` and inserts on miss — same ordering, no I/O.
