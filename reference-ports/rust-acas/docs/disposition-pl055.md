# Disposition — `pl055` invoice post extract

`pl055` scans the invoice file in key order and rewrites it: header records are
staged as open-item-4 rows, line records drive analysis totals, and the run
closes by writing four bucket rows into the value table. The byte layouts are
evidence, not disposition — `invoice-record` (129 B, line overlay 74 B) and
`open-item-record-4` (109 B) are measured field by field in
`docs/fd-evidence/F-B055-pl055-invoice-and-oi4-records.md`, and the
`value-record` / `analysis-record` layouts are F-B007's (identical files).

This ledger accounts for every field **as `pl055` uses it**. Offsets zero-based.
Ported in `crates/acas-purchase/src/{purchase_invoice,extract}.rs`.

## `invoice-record`, header overlay

| off | len | field | disposition |
|---|---|---|---|
| 0..7 | 8 | invoice-nos | `9(8)` display; key order; not copied to `oi-*` under its own name — `oi-invoice` is `binary-long` and takes the *value* |
| 8 | 1 | `ih-test` / item-nos | `= 0` is the only header discriminator; non-zero goes to the line path |
| 9..15 | 7 | ih-supplier (nos + check) | `move` to `oi-supplier`, both halves verbatim |
| 16..19 | 4 | ih-date | `move` to `oi-date` (both `binary-long`, LE) |
| 20..29 | 10 | ih-order | `move` to `oi-order` (`x(10)` in both records) |
| 30 | 1 | ih-type | drives the credit-negation of four money fields, the two month counters (2 and 3 only), the receipt split of the VAT bucket and the skip of the month amount (1) |
| 31..40 | 10 | ih-ref | `move` to `oi-ref` |
| 41..45 | 5 | ih-p-c | **never read**; `oi-p-c` is `move zero` |
| 46..50 | 5 | ih-net | `move` to `oi-net`, and into `ws-inv-amt` for every type but 1 |
| 51..55 | 5 | ih-extra | **never read** as `ih-extra`; `oi-extra` is `move zero` |
| 56..60 | 5 | ih-carriage | `move` to `oi-carriage`, and into `ws-inv-amt` |
| 61..65 | 5 | ih-vat | `move` to `oi-vat`, and into `ws-inv-amt` |
| 66..70 | 5 | ih-discount | not read (the header deduction is `ih-deduct-amt`, different field) |
| 71..75 | 5 | ih-e-vat | **never read**; `oi-e-vat` is `move zero` |
| 76..80 | 5 | ih-c-vat | `move` to `oi-c-vat`, and into `ws-inv-amt` |
| 81 | 1 | ih-status | `applied` (`z`/`Z`) skips staging and the counters, and `applied AND ih-analyised` skips the record outright. The program itself writes `z` here at the end of `extract` |
| 82 | 1 | ih-lines | not read (sales-only) |
| 83 | 1 | ih-deduct-days | `move` to `oi-deduct-days` |
| 84..87 | 4 | ih-deduct-amt | `999v99 comp`, unsigned → `oi-deduct-amt` (`s999v99`, signed); the sign therefore never shows, and the value is the discount bucket's own amount |
| 88..91 | 4 | ih-deduct-vat | `move` to `oi-deduct-vat`; not totalled anywhere by `pl055` |
| 92 | 1 | ih-days | `move` to `oi-days` |
| 93..96 | 4 | ih-cr | `move` to `oi-cr` |
| 97 | 1 | ih-day-book-flag | not read |
| 98 | 1 | ih-update | `ih-analyised` (`z`/`Z`) stages but skips the **specials** block; the month counter still moves (F-B055 Part 5). The program writes `z` here |
| 99..128 | 30 | filler | carried verbatim on the rewrite (`to_bytes`/`from_bytes` round-trip) |

Ordering is load-bearing, not stylistic: `extract` negates the four money
fields on a type-3 header **before** `ws-inv-amt` is built, so a credit note's
`ws-inv-amt` is the unnegated sum and the credit-note counter stays positive.
`ih-deduct-amt` is added to the deduction bucket *without* a type test, so a
credit note's deduction is positive too.

## `invoice-record`, line overlay (items != 0)

| off | len | field | disposition |
|---|---|---|---|
| 0..7 | 8 | il-invoice | key only |
| 8 | 1 | il-line | key only |
| 9..21 | 13 | il-product | not read |
| 22..23 | 2 | il-pa | analysis code, `"P" + il-pa`; a second byte that is not space also updates the `"P" + first + space` group row |
| 24..25 | 2 | filler | not read |
| 26..27 | 2 | il-qty | not read |
| 28 | 1 | il-type | `3` subtracts `il-net` from both sums instead of adding |
| 29..52 | 24 | il-description | not read |
| 53..54 | 2 | filler | not read |
| 55..59 | 5 | il-net | the one amount the line path moves |
| 60..64 | 5 | il-unit | not read |
| 65..66 | 2 | il-discount | not read (the header carries the deduction) |
| 67..71 | 5 | il-vat | not read |
| 72 | 1 | il-vat-code | not read |
| 73 | 1 | il-update | `il-analyised` skips the line; the program writes `z` |

## `open-item-record-4` as written

Every field is either a `move` from the header (above) or a constant: `oi-p-c`,
`oi-extra`, `oi-e-vat`, `oi-discount`, `oi-paid`, `oi-b-nos`, `oi-b-item`,
`oi-status`, `oi-date-cleared` are all `move zero`; `oi-hold-flag` and
`oi-applied` are `move space`. The four negated fields (`oi-net`,
`oi-carriage`, `oi-vat`, `oi-c-vat`) are the only conditional ones. `oi-status`
in particular is the *zero* byte and not the `space` the sales twin uses.

## `value-record` / `analysis-record`

`va-code` = `"P" + il-pa` (system byte is a literal `P`); `va-group` second
byte blank means the group row is not touched. `va-t-this`/`va-t-year` count
and `va-v-this`/`va-v-year` sum; `va-t-last`/`va-v-last` are zeroed by `create`
and never maintained. On a missing key `create` copies the matching
`analysis-record` (all seven `va-*` counters zeroed); `create-anal` mints an
`analysis-record` of `gl` = zero, `print` = spaces, `desc` = `"Emergency Name"`,
plus a blank-second group row, and raises `Anal-Created`. `va-print`,
`va-gl`, `va-desc` are carried through from the analysis row and never read
back by `pl055`.

`pa-code` is written on every read so the next `read` continues from the key;
that is modelled by the lookup itself, not by mutating a row.

## Fossils carried

1. `ws-inv-amt` is an `add ... giving`, so it is rebuilt per header and cannot
   accumulate, but it is *not* zeroed: a type-1 receipt leaves the previous
   header's amount in it, which is why the whole `if ih-type not = 1` block
   exists rather than a zero test.
2. `if applied` in `extract` sits after nothing useful — the caller has already
   tested `applied AND ih-analyised`, so this covers only applied-but-unanalysed
   headers: they move no item and no counter, yet still get their specials
   totalled and get `ih-status`/`ih-update` rewritten.
3. The rewrite happens for **every** record, staged or not, so a skip is still
   an output byte.
4. `store-specials` writes all four buckets unconditionally, zeros included.
5. A missing analysis row for a line is repaired in place: the emergency row is
   minted, `Anal-Created` raises PL201/PL202 and the program waits for a key.
