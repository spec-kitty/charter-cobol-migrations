# F-B095 — `sl095` payment proof: field widths, the unsigned accumulators, and the one-row page overflow

Verified 2026-11-03 against GnuCOBOL 3.1.2 (`/tmp/wpprobe/p95/p.cbl`) and
`cobol-original/sales/sl095.cbl`. Goldens: `fixtures/golden/sl095/{proof,busy}`,
captured by `harness/scenarios/sl095_proof.py` from `fixtures/sl095_proof_builder.py`.

`sl095` is the second half of menu `J` of `sales`. `sl090` sorts the open items
into `oisort.wrk`; `sl095` reads that file and prints a *Payment* block and a
*Journal* block, each with four totals, plus an appropriation sub-line beneath
every invoice that follows a payment for the same customer. It is ported as
`payment_proof_report.rs`; the caller owns all three file handles.

## Part 1 — `line-6` is exactly 132 bytes; the columns are where the copybook puts them

```
lena=5 lenb=4 lenv=11 lenap=11 lendn=9 leniv=9 lenidt=10 leniap=9 lenibal=13
lenl6=132
```

`line-6` composes to exactly the record width, so nothing is clipped (unlike
`sl050`'s `line-5`, F-B016 Part 1). 1-based columns: `l6-b-nos` 1..5,
`l6-slash` 6, `l6-b-item` 7..10, `l6-trans` 11..12, `l6-date` 13..23,
`l6-ac` 24..31, `l6-name` 32..60, `l6-value` 61..71, `l6-approp` 72..82,
`l6-dedn` 83..91, `l6-invoice` 92..100, `l6-i-date` 101..110,
`l6-i-approp` 111..119, `l6-i-balance` 120..132.

`l6-name` is 29 bytes against a 30-byte `sales-name`, so the last character of
the longest legal name never prints.

Measured renderings (the same probe):

```
zero -> "[     /                     ...       0.00       ]"   b-nos/b-item/value/approp/dedn/invoice all blank
2    -> "[    2/002 ]"                                          b-item keeps its leading zeroes
999999 -> "99999" / "999"                                       `z(4)9` and `999b` truncate the high digit
10000000 into `z(7)9b` -> "10000000 "                           the mandatory `9` survives, the `b` blanks
```

## Part 2 — `work-1` is unsigned, so the balance can lose its sign twice

`work-1 pic 9(6)v99 comp-3` has no sign. Two consequences, both measured:

* every leg is `add ... giving work-1`, and a negative sum is stored as its
  **absolute value** — `move -50000 to work-1` reads back `050000.00`;
* the six integer digits hold the sum **modulo 10^6**: `900000 + 900000` reads
  back `800000.00`, not an overflow condition.

`subtract oi-paid from work-1 giving l6-i-balance` is what puts the sign back:
`0 - 500` gives `500.00CR`. A negative balance therefore only appears when the
payment is larger than the (always positive) leg sum — a credit note's negative
legs are first flattened to positive by Part 2's first bullet.

## Part 3 — `l9-value` is unsigned, so unapplied cash cannot go negative

`l9-value pic z(6)9.99` has no sign and no `cr`. `subtract t-approp from t-pay
giving l9-value` at `loop-end` therefore prints `-4000` as `40.00`. The `proof`
golden shows exactly that in the journal block (payments 50.00, appropriations
90.00, unapplied cash **40.00**).

## Part 4 — the page check runs one row late, and the eject lands mid-line

```
if       line-cnt > Page-Lines
         perform headings
write    print-record  from  line-6 after 2  lines.
```

The check precedes the write, but `line-cnt` is compared *before* this row's own
contribution, so the row that pushes the count past `Page-Lines` is still printed
on the full page and the eject happens at the *next* row. With `page-lines = 48`
and `line-cnt` reaching 48 after twenty-one rows, the twenty-second row prints
on page 1 as well and the form feed is appended to the end of that row's line by
`write ... after page` (F-B012 Part 1). The `busy` golden carries the 265-byte
line: row 22, `0C`, then `line-1` of page 2.

Page 1 is therefore always one payment row too long. Nothing in the program
notices.

## Part 5 — sub-lines are gated on the carried customer, not on the invoice

`process-invoice` prints only when `oi-paid` is non-zero **and** `oi-customer`
equals `save-customer`, which only a payment row sets (`move oi-customer to
save-customer`, reachable only from the type 5/6 path). An invoice whose
customer has not just paid is silently dropped; so is any invoice before the
first payment.

`l6-i-approp` is the *payment's* appropriation, clamped: `if oi-paid >
sav-approp` prints `sav-approp`, otherwise `oi-paid`. `sav-approp` is zero until
a payment sets it, so a payment with no appropriation blanks the column.

`s-open` is tested only on the payment path. A **closed invoice** (status 1)
still prints its sub-line — the `proof` golden carries invoice 931 that way —
while a closed payment is skipped.

## Part 6 — the type filter, and what never arrives

Only types 5 (payment) and 6 (journal, unapplied cash) print a row; `1`, `2`,
`3`, `4`, `7`, `9` fall through to `read-loop` (type `2` after the invoice
branch). Types 1 and 3 and batch-zero rows are already gone by then — `sl090`
dropped them (F-B090 Parts 1/5) — so `sl095`'s own filter is only reachable for
a file that did not come through the sort.

Type numbering is local again (F-B016 Part 2): `2` is the invoice here, and the
`P`/`J` marker is decided by `6` vs. everything else.

## Part 7 — a failed keyed read prints a literal and is *not* an error

```
read     sales-file record invalid key
          move  "X"  to  name-found.
```

`invalid key` (status 23) prints `!! Customer Unknown` into `l6-name` and the
payment is still added to the totals. There is no flag, no warning line and no
exit — unlike `sl050`'s sticky `ws-error` (F-B016 Part 5). The failed read also
leaves `sales-record` holding the previous record, but only `sales-name` is
ever consumed and it is overwritten by the literal, so nothing leaks.

The `open input sales-file` is unchecked: if it fails, every read answers
`invalid key` and *every* row prints the literal. That path is unreachable
through menu `J`, which opens the same file in `sl090` first.

## Part 8 — side effects: `oi-3-flag` and `s-flag-p`

`init01` writes `"Y"` into `oi-3-flag` and `2` into `s-flag-p` (system byte
569) before any file is touched. `sl090` only *tests* that byte; `sl095` closes
the run by raising it to 2, which is what stops a second proof from a caller
that reads the flag back. Both moves are skipped on the refusal path — that path
exits from `init01` before they run.

## Reproduce

```
python3 fixtures/sl095_proof_builder.py fixtures/generated/sl095-proof
python3 fixtures/sl095_proof_builder.py fixtures/generated/sl095-busy busy
python3 harness/parity_harness.py run --scenario sl095-proof
python3 harness/parity_harness.py run --scenario sl095-busy
python3 harness/parity_harness.py run --scenario sl095-no-flag
```

The `proof` case was re-run twice after capture and reproduced `4dc5bb4c…` and
`5d224fa3…` byte for byte; `busy` reproduced `5de7231b…`/`fc65b75c…`.

Known fixture trap: `loadoi3` writes an INDEXED table in sequential access, so
an out-of-order frame answers status 22 and the record is silently dropped —
the builder sorts by `(customer, invoice)` before writing. A fixture with
thirteen rows loaded as five until this was found.
