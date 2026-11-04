# Disposition — `sl050` invoice proof

`sl050` reads the sales ledger (keyed, one read per header) and the invoice
file (sequential, headers and lines interleaved) and writes one print file.
The byte layouts are dispositioned elsewhere and not repeated: `sales-record`
(300 B) in `disposition-sl010.md`, `invoice-record`/`invoice-header`/`invoice-line`
(134 B, line overlay 80 B) in `disposition-fdinv2.md`.

This ledger accounts for every field **as `sl050` uses it**, and every byte of
the fourteen print lines. Offsets zero-based. Ported in
`crates/acas-sales/src/invoice_proof.rs`; the fossil evidence is
`docs/fd-evidence/F-B016-sl050-invoice-proof.md`.

## `invoice-header` as read

| off | len | field | disposition |
|---|---|---|---|
| 0 | 8 | `ih-invoice` | `move` to `l5-nos` (`z(7)9b`, Part 8) |
| 8 | 1 | `ih-letter` | not read by the proof |
| 9 | 1 | `sih-test` (`item-nos`) | `not = zero` skips the record — the header/line discriminator |
| 10 | 7 | `ih-customer` | `move` to `l5-cust` (`x(8)`) **and** to `sales-key` for the read |
| 17 | 4 | `ih-date` | `zz060-Convert-Date` → `l5-date` (`x(11)`) |
| 21 | 10 | `ih-order` | not read by the header path; its last two bytes appear as `sil-pa` when the header is consumed as a line (F-B016 Part 4) |
| 31 | 1 | `ih-type` | drives skip (4), sign flip (3), group (1/2/3) and `l5-type` |
| 32 | 10 | `ih-ref` | not read |
| 42 | 32 | `ih-description` | not read |
| 74 | 40 | `ih-fig` | `net` → `l5-goods` and the goods/net/balance totals; `extra`, `carriage`, `vat`, `discount`, `e-vat`, `c-vat` → the row, the b–e lines and the totals; `p-c` unread |
| 114 | 1 | `ih-status` | `sapplied` skips the record |
| 115 | 5 | `ih-status-P..I` | not read |
| 120 | 1 | `sih-lines` | `perform analysis-print` count |
| 121 | 1 | `ih-deduct-days` | not read |
| 122 | 4 | `ih-deduct-amt` | `ws-deduct-amt` → `lb`, `l5-net/gross`, totals |
| 126 | 4 | `ih-deduct-vat` | `ws-deduct-vat` → `l5-vat/gross`, totals |
| 130 | 1 | `ih-days` | not read |
| 131 | 3 | `ih-cr` | not read |

Sign flip on type 3 applies to `net`, `extra`, `carriage`, `vat`, `c-vat`,
`e-vat`, `discount`, `ws-deduct-amt`, `ws-deduct-vat` — before any total.

## `sales-record` (keyed lookup)

| off | len | field | disposition |
|---|---|---|---|
| 0 | 7 | `sales-key` | the key, exact seven bytes |
| 7 | 30 | `sales-name` | `move` to `l5-name` (`x(25)` — a 30-byte name is clipped) |
| everything else | — | — | not read |

A failed key answers `!! Customer Unknown` into `l5-name` and raises the sticky
`sales-missing` flag (F-B016 Part 5).

## `invoice-line` (analysis rows)

| off | len | field | disposition |
|---|---|---|---|
| 10 | 13 | `il-product` | first byte tested against `"/"` (`il-comment`) → abandons the rest of the invoice's analysis; otherwise unread |
| 23 | 2 | `il-pa` | `la-code` (`x(6)`) |
| 60 | 5 | `sil-net` | `la-amount` (`z(6)9.99cr`), negated on a type-3 header |
| 72 | 5 | `sil-vat` | negated on a type-3 header; `total-cvat (a, k)` |
| 77 | 1 | `sil-vat-code` | `la-vat` (`pic 9`, always printed) and the `k` axis; `> 0` gates the accumulation |
| everything else | — | — | not read |

## `print-record` (132 B) — the fourteen lines

| line | layout | disposition |
|---|---|---|
| `line-1` | `x(49)` version, `x(75)` title, `"Page "`, `zz9` | page number; page 1 is written `after 1`, a later page `after page` |
| `line-2` | `x(49)` user, `x(34)` `x(39)` spaces, `x(10)` date | `usera` and the converted `to-day` |
| `line-4` | `x(66)`, `x(9)`, `x(57)` | column banner, verbatim |
| `line-5` | see builder | the invoice row; **133 bytes, last clipped** (F-B016 Part 1) |
| `line-6` | `x(7)` `"Total"` `x(18)` + seven `z(6)9.99cr` | one per group; the literal comes from `ws-lit (a)` |
| `line-7` | `x(36)` + `x(78)` | totals banner, verbatim |
| `line-8` | `"Vat Code"` `9` `x(3)` `z9.99` `"%"` + three amounts | reconciliation rows: codes 1..3 always, 4/5 appended when their rate is non-zero (F-B016 Part 7) |
| `line-9` | `x(70)` | reconciliation banner, verbatim |
| `line-a` | `x(46)` `x(12)` `x(6)` `x(8)` `z(6)9.99cr` `x(2)` `x(9)` `9` | analysis row; `Analysis`/`Value`/`Vat Code` labels only on the first row of the report (`first-time`) |
| `line-b` | `x(46)` `x(12)` `x(6)` `x(8)` `z(6)9.99cr` | late charge, written only when `ws-deduct-amt` is non-zero |
| `line-c` | as `line-b` plus `x(2)` `x(9)` `9` | discount, only when non-zero; `lc-vat` always zero |
| `line-d` | as `line-c` | carriage, only when non-zero; `ld-vat` is 1 when `c-vat` is non-zero |
| `line-e` | as `line-c` | extra, only when non-zero; `le-a` is `extra-desc`, `le-vat` is 1 when `e-vat` is non-zero |

`lb`–`le` are cleared after writing, so the block prints at most once per
header. The row count for the page break is `line-cnt`, incremented 2 per
header row and 1 per analysis/extra row; `headings-1` resets it to 5.
