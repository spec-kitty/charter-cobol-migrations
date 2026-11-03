# F-B015 — `sl020` sales-ledger enquiry: the work file, the row edits, the page

Verified 2026-11-03 against GnuCOBOL 3.1.2 probes (`/tmp/wpprobe/q/`) and
`cobol-original/sales/sl020.cbl`.

`sl020` is an enquiry, but three quarters of it is file and print work with no
CRT in it: `set-up-work-file` builds a private work file out of the invoice
file, `get-unposted` sums it per customer, the enquiry body ages the customer's
open items, and `print-screen` lays the whole thing out on `prt-1`. Those four
parts are ported; the screen accept loops stay with WP12.

## Part 1 — `set-up-work-file` is gated by `s-flag-i` (measured from source)

```
if s-flag-i not = 1 go to eof-test.
open output work-file.
open input  invoice-file.
```

A caller that has not asked for the work file (the flag is a `pic 9` from the
system record, almost always blank or zero in a fresh run) gets no work file and
`work-file-data` stays `"N"`. `get-unposted` then short-circuits on the same
flag, so the "Unposted" column stays zero, and every later `start work-file`
is skipped. Right after the guard the program still displays `SL117 No Work
File Created..No Data` as a screen line.

The work file is opened `output` on top of the previous run's file, so it is
truncated every time the flag asks for one.

## Part 2 — what the work file keeps, and what it means

```
read invoice-file next record
if ih-test not = zero            go to read-invoice   (headers only)
if ih-status = "z"               go to read-invoice   (applied only)
if ih-type = 1 or 4              go to read-invoice   (receipts, proformas)
work-amount = ih-net + ih-extra + ih-carriage + ih-discount + ih-vat
            + ih-c-vat + ih-e-vat + ih-deduct-amt + ih-deduct-vat
if ih-type = 3 multiply -1 by work-amount
write work-record
```

`ih-discount` is **added**: the leg is already negative on disk when the invoice
was analysed, and `sl020` does not re-sign it. `ih-type = 2` (goods) and `3`
(credit note) are the only types that reach the file; everything else is
filtered before the sum.

The work file is keyed `customer + invoice` and *is not sorted for output* —
it is written in invoice-file order and read back sequentially by `get-unposted`,
which compares `work-customer` against the customer on screen and stops at the
first row of the next customer.

## Part 3 — the row edit fields, measured (`/tmp/wpprobe/q/pr.cbl`, `pr2.cbl`)

`l7-invoice` is `pic z(7)9 blank when zero`: a zero prints **eight spaces**, the
`9` position included — `blank when zero` beats the mandatory digit. Every other
value prints with the usual suppression, and more than eight digits lose the
top one.

`l7-amount` / `l7-paid` / `l7-balance` are `pic zz,zzz,zz9.99`:

| source | printed |
|---|---|
| 0.00 | `        0.00` |
| 5.00 | `        5.00` |
| 100.00 | `      100.00` |
| 1234.56 | `    1,234.56` |
| 1234567.00 | `1,234,567.00` |
| −100.00 | `      100.00` |
| 100000000.00 | `        0.00` |

An insertion comma is replaced by a space when everything to its left is
suppressed; a comma between two printed digits stays. The picture carries no
sign, so a negative value prints its absolute value — no `cr`, no `-`. A ninth
integer digit is dropped from the left. The same rules govern `l21-*`, whose
pictures differ only in width (`zzz`, `z(6),zzz`, `zzzz,zzz`, `zzz9`).

## Part 4 — the item loop carries `amount-out` between rows

`amount-out` is assigned **only** inside `if oi-type = 2 or 3`. Every other type
reaches `calc-age` with whatever the previous item left there, so an ageing
bucket can be fed by a row that shows no balance at all. Types 1 and 5/6 exit
through `bypass-ageing` instead.

`oi-paid` is negated (`multiply -1 by oi-paid`) before the `subtract ... giving
amount-out`, so a credit note's balance is `legs + |paid|`, not `legs - paid`.

Types 5 (payment) and 6 (journal payment) have `oi-invoice` set to zero first,
so the Number column prints blank (Part 3); a payment row points at no invoice.

## Part 5 — `unstring ... count a pointer a` shares one field (measured, `s2.cbl`)

Both `count` and `pointer` name `a`. GnuCOBOL stores the count and then leaves
the field holding the **next pointer**, so the statements walk the address
segment by segment: `a` after three unstrings of `LINE1\LINE2\LINE3` is 7, 13,
49 and the three address lines carry `LINE1`, `LINE2`, `LINE3`. Two adjacent
delimiters therefore yield an empty line, not a shifted one. `sales-address` is
the full 96-byte `addr1 + addr2` pair, not `addr1`.

Three further edges, measured in `/tmp/wpprobe/u/u.cbl` and `u2.cbl` against a
source of `12 Old Wharf\Hull\\` followed by `Humberside` at 49:

| unstring | pointer in | pointer out | line |
|---|---|---|---|
| 1 | 1 | 14 | `12 Old Wharf` |
| 2 | 14 | 19 | `Hull` |
| 3 | 19 | 20 | empty (delimiter on the pointer) |
| 4 | 20 | 97 | 29 spaces then `H` |
| 5 | 97 | 97 | spaces |

- A delimiter sitting on the pointer moves the pointer by one and yields an
  empty line.
- With **no delimiter left in the source** the whole remainder is moved —
  clipped at `address-line`'s 36 bytes, so the tail is lost — and the pointer is
  set to the source length plus one (`97` for a 96-byte source, measured in
  `u.cbl`). This is how the fourth line of `CUST033` prints the `H` of
  `Humberside` at column 40 of the report.
- A pointer already past the end moves spaces and stays put.
- The receiver is space-filled first, and `lN-address` is 30 bytes wide, so a
  completed segment loses everything past 30 characters.

## Part 6 — the 100-row overflow (source)

```
add 1 to a.
if a > 100  move ">> screen overflow <<" to l7-desc (100)
            move 100 to a
            go to item-comp-1.
```

`a` is set back to exactly 100, so the two later `if a > 100` tests are already
false and the overflowing item still writes its amount, paid and balance into
row 100, and still ages. Only the description and number columns of row 100 are
frozen at the literal; they survive because every later overflow re-writes the
same literal.

## Part 7 — the spool write mechanics (measured, `w.cbl`, `w2.cbl`)

`01 print-record` here is `pic x(80)`, not 132. `write ... after advancing n`
emits `n - 1` empty lines and then the record. `after page` puts a form feed at
the end of the previous line and continues on it, exactly as F-B012 Part 1
measured for the 132-wide reports.

`selprint.cob` comments its `organization line sequential` clause out ("removed
org line seq as causing double line printing in OC CE"), so the spool is
`ORGANIZATION RECORD SEQUENTIAL` and **nothing is trimmed**: a 77-byte `line-20`
lands as 80 bytes (77 + three spaces), a wholly blank record lands as 80 spaces,
and the only zero-length lines in a report are the empty lines the advancing
count produces. Measured in `/tmp/wpprobe/q/w7.cbl` and `w9.cbl`, with `w2.cbl` as the
line-sequential control (which does trim).

`print-screen` writes `line-0` once as the page-1 heading, repeats it as a page
break whenever the row counter reaches 59, and closes with `line-20` and
`line-21` each `after 2`.

## Part 8 — a failed keyed start is not an exit (measured)

`main-display-end` `move`s the typed key into `sales-key` (as part of
`move customer-in to sales-key oi3-customer l2-account work-customer`) and only
then `start`s the file. On a key past the last record the start answers status
`23`, and the following `read ... next` answers `46` — **neither is `at end`**,
so the `go to main-display-end` clause does not fire. The record area is not
transferred either, so it keeps whatever it held: on a fresh program the key
bytes just moved in, and NULs everywhere else (probe `/tmp/wpprobe/u/s02.cbl`;
golden `fixtures/golden/sl020/no-match`).

The comparison `if sales-key not = customer-in` therefore passes, and the whole
customer block prints with a NUL name and address and zero money. The item loop
*does* test `fs-reply` after its read, so the same `46` ends it immediately and
the report carries no rows.

A later no-match in the same run does not print NULs: the sales record area
still holds the previous customer's bytes.

Related: `zz060-Convert-Date` runs `maps04`, which answers spaces for zero *and
for negative* day numbers (probe `/tmp/wpprobe/u/m4.cbl`); the date column is
blank in both cases. Large values are clamped, not rejected (`m5.cbl`:
`4294967295` → `21/09/9814`).
