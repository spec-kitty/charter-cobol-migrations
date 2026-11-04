# F-B090 — `sl090` payment-proof sort: the refusal gate, the batch layout, and the key order

Measured 2026-11-03 with GnuCOBOL 3.1.2.0 through ACAS itself: the refusal was
captured by running menu J with `s-flag-p` clear
(`harness/runs/20261103-182042-sl090-no-flag`), the order from the accepted run
(`harness/runs/20261103-181936-sl090-sort`, reproduced twice at `7604d63d…`),
and the record layout from the offset probe below. `sl090.cbl` is 202 lines and
does nothing else.

## Part 1 — `if s-flag-p = 0` is a hard gate, and it writes no file

`init01` raises errors **30** and then **15** through `maps99` and goes to
`menu-exit` before any `open`. On screen the sequence is

```
SL090 (3.01.02)
T-030 Error not in error.txt. Hit return to close
15
```

and `oisort.wrk` is **absent** afterwards — not empty, absent. The sort never
reaches `input-to-sort`, so `oi-3-flag` (byte 562) is not set either; only the
`move "Y" to oi-3-flag` *after* the gate would do that.

Consequence for the port: a refusal is not "an empty sorted file", it is "no
file at all". [`SortOutcome::Refused`] carries the distinction, and the
`no-flag` golden deliberately has no artifact.

## Part 2 — `oi-batch` is at 15..21, `oi-type` at 21

The probe (`/tmp/wpprobe/s090/p.cbl`) moved a distinct sentinel into every field
of `oi-header` and dumped all 114 bytes. Zero-based readings:

| Offset | Bytes | Field |
|---|---|---|
| 15..19 | `00 00 82 35` | `oi-b-nos` = 33333, **big endian** |
| 19..21 | `bc 01` | `oi-b-item` = 444, high byte first |
| 21 | `35` (`'5'`) | `oi-type` |

`comp` in GnuCOBOL is native binary, big endian; both digits of `s-b-nos` are
read as one 4-byte word and the two of `s-b-item` as a 2-byte word, because the
sort keys are `s-b-nos` then `s-b-item` — the *pair*, not the digits.

F-B008's money offsets (`oi-p-c` at 49) are confirmed by the same probe, so the
114-byte layout is the one the rest of the sales code already uses.

## Part 3 — a failed input open still leaves a file

```
open input open-item-file-3
if fs-reply not = zero
     close open-item-file-3
     open output open-item-file-s
     close open-item-file-s
     go to main-exit
```

So status 35 on the input produces a zero-length `oisort.wrk` rather than
nothing. The two failure shapes are therefore distinct and the model keeps them
apart: status ≠ 0 → empty file; `s-flag-p` = 0 → no file.

## Part 4 — the key order, including the one descending key

```
on ascending key  s-b-nos
                  s-b-item
on descending key s-type
on ascending key  s-date
                  s-invoice
```

`s-type` descending inside a batch slot is the load-bearing one: the accepted
run puts a journal (6) ahead of the payment (5) and both ahead of the account
row (2) for the same slot. The golden records `6, 5, 2` for batch `2/1`, and
`5` before `2` for `0/2`.

Batch numbers compare **numerically**: `100/1` sorts after `7/2`, not before it.

COBOL promises no order beyond the declared keys. The port's `sort_by_key` is
stable, so ties keep input order; the fixture is built with no tie on all five
keys, which is why the comparison never depends on that choice.

## Part 5 — the two skip rules

```
if oi-type = 1 or 3                *> Ignore Receipts & Cr. Notes
if zero = oi-b-nos and oi-b-item   *> batch data zero so no payments
```

`1` is a **receipt** here; `sl055`'s `InvoiceType` calls the same byte an
invoice (F-B016 Part 2), so the numbering is per-program. Type 4 (proforma) and
types 5..9 are **kept** — only 1 and 3 go.

The batch rule needs *both* fields zero. `(0, 1)` and `(1, 0)` survive; only
`(0, 0)` is a non-payment. The `sort` case keeps a `(0, 0)` row in the stream
next to the `(0, n)` rows it must not take with it.

## Part 6 — the record is copied, not rebuilt

`release sort-record from open-item-record-3` moves all 114 bytes and
`sort-record` is 114 bytes, which is why `init01`'s `function length`
comparison (and its error screen) never fires in practice. The output record is
the input record, byte for byte; only membership and order change.
