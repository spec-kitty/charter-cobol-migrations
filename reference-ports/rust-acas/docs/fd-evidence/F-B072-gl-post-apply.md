# F-B072 — the GL posting chain's four records, measured

Verified 2026-11-04 against GnuCOBOL 3.1.2 (probe `/tmp/wpprobe/g72/p.cbl`):
every field was MOVE-d a distinct sentinel onto the program's own FD overlay,
the record was WRITTEN, read back and dumped; `FUNCTION LENGTH` supplied the
sizes. Nothing here is inferred from a group name.

The chain is `gl070` (pre-process) → `gl071` (sort) → `gl072` (batch update),
run back to back from menu `H` of `general.cbl` (`load08`).

## Part 1 — record sizes

```
LEN pre=70 post=70 ledg=126 batch=96
```

| file | copybook | select | bytes |
|---|---|---|---|
| `pretrans.tmp` | `gl070`/`gl071` inline | line sequential, no key | 70 |
| `postrans.tmp` | `gl071`/`gl072` inline | line sequential, no key | 70 |
| `ledger.dat` (file-5) | `fdledger.cob` | indexed, key `ledger-key` | 126 |
| `batch.dat` (file-7) | `fdbatch.cob` | indexed, key `batch-key` | 96 |

`pre-trans-record` and `post-trans-record` are the **same 70-byte layout**
under two names; gl071's SORT moves one to the other field for field, so the
sort is the only thing that changes between them.

## Part 2 — `pre-trans-record` / `post-trans-record`, 70 bytes

`pre-amount` is `PIC s9(8)v99` **display**, exactly like `post-amount`
(F-B009 Part 3): ten digit bytes, sign as an overpunch on the last one.

| Offset | Field | PIC |
|---|---|---|
| 0..4 | (pre\|post)-batch | 9(5) |
| 5..9 | (pre\|post)-post | 9(5) |
| 10..11 | -code | xx |
| 12..19 | -date | x(8) |
| 20..25 | -ac | 9(6) |
| 26..27 | -pc | 99 |
| 28..37 | -amount | s9(8)v99 display, overpunched |
| 38..69 | -legend | x(32) |

## Part 3 — `ledger-record` (fdledger.cob), 126 bytes

`ledger-key` is 8 bytes: `ledger-nos 9(6)` then `ledger-pc 9(2)`. The first six
render an eight-digit account with its last two digits as decimals — gl072
prints `divide ledger-nos by 100` into `l6-account pic 9999.99`.

| Offset | Field | PIC |
|---|---|---|
| 0..5 | ledger-nos | 9(6) |
| 6..7 | ledger-pc | 9(2) |
| 8 | ledger-type | 9 |
| 9 | ledger-place | x |
| 10 | ledger-level | 9 |
| 11..15 | filler | x(5) |
| 16..39 | ledger-name | x(24) |
| 40..45 | ledger-balance | s9(8)v99 comp-3 |
| 46..51 | ledger-last | s9(8)v99 comp-3 |
| 52..75 | ledger-q1..q4 | 4 × s9(8)v99 comp-3 |
| 76..125 | filler | x(50) |

`ledger-last` and the four quarters are **not touched by gl072** — the update
writes `ledger-balance` only and rewrites the whole record.

## Part 4 — `batch-record` (fdbatch.cob) fields gl072 uses

| Offset | Field | PIC | Use |
|---|---|---|---|
| 0 | ledger | 9 | forced to 1 (G/L) by `get-batch` |
| 1..5 | batch-nos | 9(5) | the key |
| 6..7 | items | 99 | unused here |
| 8 | batch-status | 9 | must be 1 (`status-closed`) or gl070 skips the batch |
| 9 | cleared-status | 9 | must be 0 (`waiting`) or gl070 skips the batch |
| 10..11 | bcycle | 99 | gl070 skips a batch whose cycle is not `scycle` |
| 12..27 | dates (entered/proofed/posted/stored) | 4 × binary-long | `posted` (20..24) overwritten with `run-date` |
| 52..75 | description | x(24, 52..76) | copied verbatim onto `l3-desc` |

## Part 5 — the leg split (`gl071b-pre-process`)

One posting record becomes up to three pre-trans rows:

1. debit leg — `pre-ac = post-dr`, `pre-amount = post-amount`, plus
   `vat-amount` when `post-vat-side = "CR"`;
2. credit leg — `pre-ac = post-cr`, the same sum when
   `post-vat-side = "DR"`, then the amount is multiplied by −1;
3. VAT leg — only when `vat-ac` and `vat-amount` are both non-zero; the amount
   is negated when `post-vat-side = "CR"`.

`pre-date` is the posting's own `dd/mm/yy`, not the run date, and
`pre-code`/`pre-legend` are copied unchanged onto every leg.

A posting whose 10-byte key is all zeros, or whose batch is not the one being
posted, is skipped before any of this.

## Part 6 — the report lines, and the editing fossils on them

Measured the same way (probe `/tmp/wpprobe/g72/l.cbl`, `FUNCTION LENGTH` plus a
sentinel per field): `line-1` and `line-3` are 120 bytes, `line-7` is 80, and
`line-6` is 118 (a 132-byte record leaves the last 14 columns blank).

`line-6` columns, in the copybook's own order: `l6-account` 1..7, filler 8..13,
`l6-pc` 14..15, filler 16..20, `l6-balance` 21..33, `l6-tran` 34..38, filler
39..42, `l6-date` 43..54, `l6-debit` 55..65, filler 66..69, `l6-credit`
70..80, filler 81..86, `l6-legend` 87..118. `line-7` is 54 spaces, eleven `=`,
four spaces, eleven `=`.


- `l6-account pic 9999.99` is fed `ledger-nos / 100` — the trailing two digits
  of the account number become its printed decimals, always `.00` here.
- `l6-balance pic z(7)9.99cr blank when zero`, `l6-debit`/`l6-credit`
  `pic z(7)9.99 blank when zero`, `l6-tran pic bbbz9 blank when zero`: a zero
  prints as spaces of the field's full width.
- The `end-account` row's date is `to-day` — the **run date** — while the
  detail rows carry the posting's own date.
- `new-account` seeds `tot-dr`/`tot-cr` from the brought-forward balance
  (debit when positive, credit when it is not), and a failed keyed read leaves
  the record area holding the previous account, so the brought-forward row of a
  missing account repeats the last one's name and balance.

## Part 7 — the page check runs one row late

`add 1 to line-cnt` happens **after** the row is written, and the check
`if line-cnt > Page-Lines` follows the write. With `Page-Lines` at 48 the 49th
body row prints on page 1 and the account close/heading lands after it. Once
the check fires it performs `end-account`, `headings`, sets `read-ledger = "R"`
and `new-account` — so the account is re-read and its brought-forward row
repeats for the new page.

## Part 8 — what gl072 refuses

- `get-batch` sets `we-error = 999` when the keyed batch read fails or the
  batch is not `waiting`; every posting of that batch is then skipped, but the
  heading block for it has **already printed** with whatever description the
  failed read left behind.
- `open i-o batch-file ledger-file` and `open input post-trans` are unchecked —
  a failure leaves the file closed and the program walks the read loop anyway.

## Part 9 — the packed money encoding, measured

`s9(8)v99 comp-3` is eleven nibbles of digits and one of sign in six bytes,
not ten digits: GnuCOBOL writes a leading pad digit, then the ten digits of the
value, then `0x0c` (plus) or `0x0d` (minus) in the low nibble of the sixth
byte. `move 15350.00` onto the field of probe `/tmp/wpprobe/g72p/p5.cbl` gives
`00 00 15 35 00 0c`, and reading the seed bytes `00 00 15 00 00 0c` back
through the same field yields `15000.00` (probe `p3.cbl`) — so a port must
treat the digit run as eleven wide with the implied point after the tenth.

The same probe pins the display side: `pic z(7)9.99cr` is 13 bytes and renders
`15000.00` as `   15000.00` plus two blanks (`CR` when negative), and
`pic bbbz9` renders 34 as `   34`.
