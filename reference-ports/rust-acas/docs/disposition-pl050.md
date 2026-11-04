# Disposition — `pl050` invoice proof

`pl050` reads the purchase ledger (keyed, one read per header) and the invoice
file (sequential) and writes one print file. The record layouts are
dispositioned elsewhere and not repeated: `purch-record` (300 B) in
`disposition-wssystem.md`'s companion readers, `invoice-record` and its two
overlays in `disposition-pl055.md`.

This ledger accounts for every field **as `pl050` uses it**, and every byte of
the ten print lines. Offsets zero-based. Ported in
`crates/acas-purchase/src/invoice_proof.rs`; the fossil evidence is
`docs/fd-evidence/F-B050-pl050-invoice-proof.md`.

## `invoice-header` as read

| off | len | field | disposition |
|---|---|---|---|
| 0 | 8 | `ih-invoice` | `move` to `l5-nos` (`z(7)9b`) |
| 8 | 1 | `ih-test` | `not = zero` skips the record — the header/line discriminator |
| 9 | 7 | `ih-supplier` | `move` to `l5-cust` (`x(9)`) **and** to `purch-key` for the keyed read |
| 16 | 4 | `ih-date` | `zz060-Convert-Date` → `l5-date` (`x(11)`) |
| 20 | 10 | `ih-order` | not read by the header path; its last two bytes appear as `il-pa` when a header is consumed as a line |
| 30 | 1 | `ih-type` | drives the sign flip (3), the group subscript (the byte itself, so `4` falls off the table), and `l5-type` |
| 31 | 10 | `ih-ref` | not read |
| 41 | 40 | `ih-fig` | `net` → `l5-goods`, the net totals; `carriage` → `ld`, the carriage totals; `vat` → `l5-vat`, the vat totals; `c-vat` → `l5-vat`, `ld-vat`, `total-cvat (a, 1)`, the vat totals; `p-c`, `extra`, `discount`, `e-vat` are read into the figures but never printed (purchase has no extra/discount columns) and are **not** in any total |
| 81 | 1 | `ih-status` | `applied` (`z`/`Z`) skips the record |
| 82 | 1 | `ih-lines` | `perform analysis-print` count |
| 83 | 1 | `ih-deduct-days` | not read |
| 84 | 4 | `ih-deduct-amt` | `ws-deduct-amt` → `lb`, `l5-net`, `l5-gross`, `total-ded`; negated for type 2 |
| 88 | 4 | `ih-deduct-vat` | moved to the working storage field, but `pl050` never adds it to anything |
| 92 | 1 | `ih-days` | not read |
| 93 | 4 | `ih-cr` | not read |
| 97 | 1 | `ih-day-book-flag` | not read |
| 98 | 1 | `ih-update` | not read (the proof ignores the analysed flag) |

Sign flip on type 3 applies to `net`, `carriage`, `vat`, `c-vat` — before any
total. Type 2 flips only `ws-deduct-amt`.

## `purch-record` (keyed lookup)

| off | len | field | disposition |
|---|---|---|---|
| 0 | 7 | `purch-key` | the key, exact seven bytes, high padded with spaces |
| 9 | 30 | `purch-name` | `move` to `l5-name` (`x(25)` — a 30-byte name is clipped) |
| everything else | — | — | not read |

A failed key answers `Supplier Unknown` into `l5-name` and raises the sticky
`purchase-missing` flag (F-B050 Part 5).

## `invoice-line` (analysis rows, read through the 75-byte working-storage overlay)

| off | len | field | disposition |
|---|---|---|---|
| 9 | 1 | `il-product` first byte | tested against `"/"` (`il-comment`) → abandons the rest of the invoice's analysis; otherwise unread |
| 21 | 2 | `il-pa` (WS) | `la-code` (`x(6)`); the first byte is disk `product[12]` (F-B050 Part 2) |
| 55 | 5 | `il-net` | `la-amount` (`z(6)9.99cr`), negated on a type-3 header |
| 67 | 5 | `il-vat` | negated on a type-3 header; `total-cvat (a, k)` |
| 72 | 1 | `il-vat-code` | `la-vat` (`pic 9`, always printed) and the `k` axis; `> 0` gates the accumulation |

## Print lines

| line | width | disposition |
|---|---|---|
| `line-1` | 132 | version `PL050 (3.01.04)` (49), title (75) at 50, `Page ` at 125, `l3-page` (`zz9`) at 130 |
| `line-2` | 132 | `usera` (49) then the converted `to-day` at 123, after two 37/36-byte blanks |
| `line-4` | 132 | banner: 66 bytes, four spaces, then `     Goods                 <---Net-->  <---Vat-->  <--Gross->` at 71 (`Goods` at 76, `<---Net-->` at 98) |
| `line-5` | 132 | the header row: `l5-nos` (`z(7)9b`), date (`x(11)`), supplier (`x(9)`), name (`x(25)`, a 30-byte name clipped), the never-moved 4-byte marker at 55, type (`x(14)`) at 59, then goods / net / vat / gross as `z(6)9.99cr` at 73 / 97 / 109 / 121 — the row fills the record exactly, so nothing is truncated |
| `line-6` | 132 | a group total: `    Total` at 4, `l6-lit` (`x(18)`) at 14, goods 32, carriage 44, net 56, vat 68, gross 80, prompt pay 92 — the deduction column is **last** here, unlike the sales program (F-B050 Part 1) |
| `line-7` | 102 | `Goods    Carriage         Net         Vat       Gross  Prompt Pay` at 37 |
| `line-8` | 132 | a VAT-code row: code at 10, rate (`z9.99`) at 14, `%` at 19, receipts (`z(7)9.99cr`) 24, invoices (`z(9)9.99cr`) 37, credit notes 52 |
| `line-9` | 132 | the reconciliation banner, written `after 5` (not the sales program's 2) |
| `line-a` | 132 | an analysis row: labels on the first row of the report only (`la-a` at 47, `la-b` at 65, `la-c` at 87), code at 59 (`x(6)`, two bytes moved), amount at 73, `la-vat` at 96 |
| `line-b` | 132 | the prompt-pay row: `Prompt Pay  ` at 47, amount at 73 |
| `line-d` | 132 | the carriage row: `Carriage    ` at 47, amount at 73, `ld-vat` at 96 (0 or 1) |

`line-b` and `line-d` are cleared after they are written, so each occurs at
most once per header; `lb-a` is filled only when the deduction is non-zero and
`ld-a` only when carriage is non-zero.
