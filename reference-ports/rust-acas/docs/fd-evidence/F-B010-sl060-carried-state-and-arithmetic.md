# F-B010 — the state sl060 inherits, and the arithmetic it does on raw bytes

Verified 2026-11-03 while porting `sl060`. This note collects the fossils that
are not fields: state carried in from the previous program, subscripts that
leave their table, and what an `add` into a `comp-3` field genuinely does to
the bytes underneath it. `post.rs` reproduces each one and names this note at
the point of reproduction.

## Part 1 — `current-quarter` is a global the chained path never sets

`add work-goods to STurnover-Q (current-quarter)` (sl060:459, 465, 472) reads a
`pic 99` declared outside the program (`sys002.cbl:465`, `using current-quarter`,
a screen field). It is valid only while a caller sets it; `sl060` never does
and neither does the `sales.cbl` menu path, so it arrives as **0**.

`STurnover-Q` is a 4-slot `OCCURS` redefining `Quarters` (24 bytes at 260), and
a COBOL subscript is 1-based, so slot 0 addresses the six bytes *before* the
group: `sales-last` (254..260, F-B009 Part 2). The subscript is not bounds
checked — it is byte arithmetic on the record:

| quarter | lands on | offset |
|---|---|---|
| 0 | `sales-last` | 254..259 |
| 1..4 | `turnover-q-1`..`q-4` | 260..283 |
| 5 | `sales-unapplied` | 284..289 |
| 6, 7 | `filler` (10 bytes) | 290..295, 296..299 |
| 8 | past the record end | truncated by the FD |

Probe `/tmp/wpprobe/s10.cbl` (free format, ACAS's own `fdsl.cob`):

```
space-filled seed, q=0: last=+02021202.02 q1=+02020202.02
zeroed seed,       q=0: last=+03031303.03
```

`turnover-q (1)` is untouched while `sales-last` moves, and `sales-last` also
changes for receipts and credit notes — every phase-1 record touches it.
The port applies the same offset arithmetic (`quarter_add`) rather than
indexing a bounded array.

## Part 2 — `add` into a space-filled `comp-3` field reads the space nibbles

An untouched sales row is spaces, not zeros: every money field is `0x20 0x20
…`. `comp-3` arithmetic does not care that the field was "blank" — it reads
eleven digits, and each `0x20` contributes the digits `2` and `0`, so the field
reads as `20202020202` (2020202.0202, a number no posting could plausibly be).
That junk dwarfs the first real amount, and GnuCOBOL then re-emits the padding
nibble as an actual digit.

Measured on the probe above: a `1000.00` add turns six `0x20` bytes into
`00 20 21 20 20 2C` = `02021202.02` — the junk survives, minus the digit that
the rounding of the addition happened to land on. Against a zeroed field the
same add gives `1000.00`. It is not a bug that clears up: the junk persists and
compounds across records, so the port's `packed_add` reads and re-emits the
actual bytes instead of `Wide::cents`/`set_cents`.

## Part 3 — `file-status (18)` is set by `sl055` and inherits into `sl060`

`file-status` is a `pic 9 occurs 32` flag array in the shared environment
division; the indexes are "has this file been touched" markers, not statuses.
`sl055:398` sets entry **18** (OTM2) the moment it opens the staging file.
`sl060` clears it only at `aa999-Exit-Prog` (line 601).

`sales.cbl` `load07` calls `sl055` then `sl060` in one run unit and COBOL's
working storage is only initialised on the first call, so **sl060 starts with
18 = 1**. Consequences, both visible in every golden under
`fixtures/golden/sl060/*/prt-1`:

- `ba000-Cr-Swop`'s `if file-status (18) = zero → ba000-New-Heading` (626)
  never fires: there is no page-2 heading, no `Un-Applied Credits` banner and
  no `line-4a` in the C/F listing; the C/F rows simply follow the totals.
- `aa050-End-Loop-End`'s `if … file-status (18) = 1` (585, 588) is therefore
  always satisfied, so the C/F line prints on an otherwise empty pass too.

The port models this as `Report { headed: true, .. }` at `post()` entry, **not**
as `false`, and keeps the flag as the C/F gate.

## Part 4 — `si-header` is written back into the note's own record

`ba000-CR-Notes` opens with `move oi-header to si-header` (739) and closes with
`move si-header to oi-header` (796). `si-header` (`sales/wssoi.cob`) is a
114-byte mirror of `oi-header`, same offsets, so the restore is a whole-record
copy: `si-paid`, `si-status` and every apportioned leg land back in the header
that `aa020-Read-Loop` writes at 499 (and prints at 513) *after* `ba000-CR-Notes` returns.

So the credit note's own OTM3 row **does** carry the amount apportioned off it
and can be written already closed. Phase 2 only sees notes still open. The port
models this by apportioning into a `si` copy of the note and pushing that copy
as the OTM3 row.

## Part 5 — `ba000-Cr-Swop` has no invoice loop

Despite the section name, 613..649 does no apportionment at all: it sums the
note's legs (`work-1`), sets `oi-status` to 1, prints `line-7` with `work-1` as
the balance and `oi-paid` as the applied figure, adds `work-1` (still negative)
to `work-b`, negates `work-1`, adds it to `oi-paid` and rewrites. Everything a
note could reach was already apportioned by phase 1.

A port that gives `Cr-Swop` an invoice loop double-applies every note phase 1
had already covered. `post.rs::cr_swop` is the print-and-carry-only version.

## Part 6 — `total-net (a)` is subscripted by the *digit* of `oi-type`

`move oi-type to a` (423) then `add work-vat to total-vat (a)` / `add work-net
to total-net (a)` (440, 441). `total-group` holds exactly three entries, so
only types 1..3 are addressable. Types 4, 5, 6 and 9 (proforma, payment,
journal) never reach OTM2 from `sl055`, so the hole is unexercised — and a
type outside 1..3 would silently corrupt an adjacent working-storage field
instead of trapping. The port keeps a three-slot array and derives the index as
`oi-type - '1'`.
