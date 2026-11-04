# Disposition — `gl072` batch transaction update

`gl072` is the tail of menu `H` of `general`: `gl070` pre-processes the open GL
batches into `pretrans.tmp`, `gl071` sorts it, and `gl072` walks the sorted
`postrans.tmp`, adds each leg to `ledger-balance`, rewrites the ledger record
and stamps the batch as posted.

Offsets are zero-based. Sizes and offsets are measured in
`docs/fd-evidence/F-B072-gl-post-apply.md`. Ported in
`crates/acas-gl/src/update.rs`; the legs are produced by `pre_process.rs` and
covered by `tests/gl072_parity.rs`.

## Fields of `post-trans-record` (70 B) the update reads

| off | len | field | disposition |
|---|---|---|---|
| 0 | 5 | `post-batch` | the batch grouping key; a change closes the previous batch and looks this one up |
| 5 | 5 | `post-post` | `l6-tran`, `bbbz9 blank when zero` |
| 10 | 2 | `post-code` | not printed by this program; carried |
| 12 | 8 | `post-date` | `l6-date` verbatim (the posting's own date, never the run date) |
| 20 | 6 | `post-ac` (leg) | `ledger-key` left half, `l6-account` via `/100` |
| 26 | 2 | `post-pc` (leg) | `ledger-key` right half, `l6-pc` |
| 28 | 10 | `post-amount` | the stored delta, and the `l6-debit` / `l6-credit` split on sign |
| 38 | 32 | `post-legend` | `l6-legend` verbatim |

`post-code` is the only field read from the leg and then not printed.

## Fields of `ledger-record` (126 B) the update touches

| off | len | field | disposition |
|---|---|---|---|
| 0 | 6 | `ledger-nos` | the key; `divide ledger-nos by 100` gives `l6-account`, so the last two digits print as decimals and always render `.00` |
| 6 | 2 | `ledger-pc` | the key's other half and `l6-pc` |
| 16 | 24 | `ledger-name` | `l6-legend` on the closing row only |
| 40 | 6 | `ledger-balance` | read, added to, packed back; `l6-balance` on opened rows and the closing row |
| 46 | 6 | `ledger-last` | carried, never touched |
| 52 | 24 | `ledger-q1..q4` | carried, never touched |

`ledger-type`, `ledger-place`, `ledger-level` and both fillers are carried.

A keyed read that misses leaves the record area untouched — the key was already
overwritten — so the brought-forward row repeats the previous account's name,
balance and (on the closing row) legend, and the `rewrite` finds no record to
update, so nothing is created.

## Fields of `batch-record` (96 B) the update touches

| off | len | field | disposition |
|---|---|---|---|
| 0 | 6 | `ledger` + `batch-nos` | the key; `ledger` is forced to `1` before the read |
| 9 | 1 | `cleared-status` | the `waiting` test; a batch that is not `waiting` sets `we-error` = 999 |
| 20 | 4 | `posted` | overwritten with `run-date` when the batch closes |
| 52 | 24 | `description` | `l3-desc`, copied only after the read |

`items`, `bcycle`, the other three dates and the posting defaults are carried.
`end-batch` runs on the batch-record area as it stands, with no guard.

## Report lines

| line | width | disposition |
|---|---|---|
| `line-1` | 132 | `l1-prog` + the literal `Transaction  Posting` + `Page ` + `z9` `l1-page`; written `before 1` on page 1 and `after page` otherwise |
| `line-3` | 132 | cycle, batch, the literal `General`, the batch description and the run date in the display form |
| `line-4` | 132 | a 120-byte literal padded with spaces to its own width |
| `line-5` | 132 | two rules: seven dashes at 1 and five at 35 (the first is a 34-byte field holding only seven dashes) |
| `line-6` | 118 of 132 | the detail and summary row, every money column `blank when zero` |
| `line-7` | 80 of 132 | two eleven-dash rules at 55 and 70 |

Two fossils on `line-6`: the balance column is **always blank on a detail
row** (`new-account` zeroes `l6-balance` and no detail path refills it), and the
date column is 12 bytes wide while the values put in it are 8 or 10.

## Fossil behaviours kept

- the page check runs after the row is written and counted, so the overflowing
  row prints on the page it overflowed and the eject lands on the *next* write
  — which is the closing block, so a 265-byte line can carry `0x0c` plus a
  heading;
- `tot-dr` / `tot-cr` are unsigned `9(8)v99`, so a negative leg stores its
  magnitude into `tot-cr`;
- a failed or not-`waiting` batch read sets `we-error` = 999 *after* the read
  leaves its content in the description, and every leg of that batch is
  skipped while `save-batch` is reset to zero;
- `l6-account` is blank-when-zero but comes from a `divide … giving`, so a
  zero or low-values key prints blanks;
- the run date, not the posting date, is used on the closing row.
