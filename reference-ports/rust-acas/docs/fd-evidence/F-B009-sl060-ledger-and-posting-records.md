# F-B009 — sl060's three writer records, measured

Verified 2026-11-03 against bytes GnuCOBOL 3.1.2 writes through ACAS's own
`fdsl.cob` / `fdpost.cob` / `fdbatch.cob` overlays (probe `/tmp/wpprobe/p.cbl`:
MOVE a distinct sentinel into every field, WRITE the overlay onto the FD, read
the record back, dump). Offsets are where each sentinel landed. `function
length` supplied the record sizes; nothing here is inferred from the group
names.

`sl060` is the only writer of these three files, and it is the phase after
`sl055`: `sales.cbl` `load07` runs `sl055` and then `sl060` automatically when
`sl055` returns `ws-term-code` zero.

## Part 1 — record sizes

```
LEN sales=300 posting=98 batch=96
```

| file | copybook | select (sel*.cob) | bytes |
|---|---|---|---|
| `salesled.dat` (file-12) | `fdsl.cob` | indexed, key `sales-key` | 300 |
| `posting.dat` (file-6) | `fdpost.cob` | **relative**, key `rrn` | 98 |
| `batch.dat` (file-7) | `fdbatch.cob` | indexed, key `batch-key` | 96 |

`fdpost.cob`'s header comment claims 96 bytes "leading sign removed"; the
overlay is 98 and the sign was moved into an overpunch, not removed (Part 3).

## Part 2 — `sales-record` (fdsl.cob), 300 bytes

`Sales-Key` is 7 bytes: the 6-digit customer number plus its check digit —
the same 7-byte `customer-key` shape the invoice and open-item records carry.
`sales-status` is `PIC 9` where `0` is `customer-dead`.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0..6 | sales-key | x(7) | `AAA1111` |
| 7..36 | sales-name | x(30) | `B` + spaces |
| 37..84 | sales-addr1 | x(48) | `C` + spaces |
| 85..132 | sales-addr2 | x(48) | `D` + spaces |
| 133..145 | sales-phone | x(13) | `E` + spaces |
| 146..149 | sales-ext | x(4) | `F` + spaces |
| 150..179 | sales-email | x(30) | `G` + spaces |
| 180..192 | sales-fax | x(13) | `H` + spaces |
| 193 | sales-status | 9 | `31` (`1`) |
| 194 | sales-late | 9 | `32` (`2`) |
| 195 | sales-dunning | 9 | `33` |
| 196 | email-invoice | 9 | `34` |
| 197 | email-statement | 9 | `35` |
| 198 | email-letters | 9 | `36` |
| 199 | delivery-tag | 9 | `37` |
| 200 | notes-tag | 9 | `38` |
| 201..203 | filler | xxx | (spaces) |
| 204..205 | sales-credit | 99 | `3039` (`09`) |
| 206..207 | sales-discount | 99v99 comp | `03f3` (BE 1011 = 10.11) |
| 208..209 | sales-late-min | binary-short | `0457` (BE 1111) |
| 210..211 | sales-late-max | binary-short | `08ae` (BE 2222) |
| 212..215 | sales-limit | binary-long | `0815 1605` (LE 333333) |
| 216..219 | sales-activety | binary-long | `001c c806` (LE 444444) |
| 220..223 | sales-last-inv | binary-long | `0023 7a08` (LE 555555) |
| 224..227 | sales-last-pay | binary-long | `002a 2c0a` (LE 666666) |
| 228..231 | sales-average | binary-long | `0031 de0b` (LE 777777) |
| 232..235 | sales-pay-activety | binary-long | `0038 900d` (LE 888888) |
| 236..239 | sales-pay-average | binary-long | `003f 420f` (LE 999999) |
| 240..243 | sales-pay-worst | binary-long | `0092 8a01` (LE 101010) |
| 244..247 | sales-create-date | binary-long | `0007 b201` (LE 111111) |
| 248..253 | sales-current | s9(8)v99 comp-3 | `0123456789 0c` (12345678.90) |
| 254..259 | sales-last | s9(8)v99 comp-3 | `0234567890 1c` |
| 260..265 | turnover-q1 | s9(8)v99 comp-3 | `0000000011 1c` (1.11) |
| 266..271 | turnover-q2 | s9(8)v99 comp-3 | `0000000022 2c` (2.22) |
| 272..277 | turnover-q3 | s9(8)v99 comp-3 | `0000000033 3c` (3.33) |
| 278..283 | turnover-q4 | s9(8)v99 comp-3 | `0000000044 4c` (4.44) |
| 284..289 | sales-unapplied | s9(8)v99 comp-3 | `0345678901 2c` (34567890.12) |
| 290..299 | filler | x(10) | spaces |

`Quarters` is a group of four `s9(8)v99 comp-3` fields (24 bytes) and is
`REDEFINES`d by `STurnover-Q ... OCCURS 4` — the quarter index is a
1-based subscript, so `STurnover-Q (current-quarter)` writes at
`260 + (q-1) * 6`. `current-quarter` is a program global supplied by the
caller; `xl150` bumps it at year end, `sl060` only reads it.

## Part 3 — `posting-record` (fdpost.cob), 98 bytes

`post-amount` and `vat-amount` are `PIC s9(8)v99` **display**: ten digit bytes,
sign carried as an overpunch on the final digit. GnuCOBOL 3.1.2's ASCII table
(measured, `/tmp/wpprobe/op4.cbl`):

| value digit | positive | negative |
|---|---|---|
| 0 | `0` (30) | `p` (70) |
| 1 | `1` (31) | `q` (71) |
| … | … | … |
| 9 | `9` (39) | `y` (79) |

So `-34567890.12` lands as `33343536373839303172` — the final `2` stalks a
`72` (`r` = −2). Zero is `p`/`0` per sign.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0..4 | batch | 9(5) | `00001` |
| 5..9 | post-number | 9(5) | `00002` |
| 10..11 | post-code | xx | `PC` |
| 12..19 | post-date | x(8) | `DATE1234` |
| 20..25 | post-dr | 9(6) | `000003` |
| 26..27 | dr-pc | 99 | `04` |
| 28..33 | post-cr | 9(6) | `000005` |
| 34..35 | cr-pc | 99 | `06` |
| 36..45 | post-amount | s9(8)v99 display | `1234567890` |
| 46..77 | post-legend | x(32) | `LEGEND-SENTINEL` + spaces |
| 78..83 | vat-ac | 9(6) | `000007` |
| 84..85 | vat-pc | 99 | `08` |
| 86..87 | post-vat-side | xx | `VS` |
| 88..97 | vat-amount | s9(8)v99 display | `3456789012` + `72` (−…12) |

The select is `organization relative`, `relative key rrn`; the record number
is written before each `WRITE` and incremented after (`add 1 to rrn`).

## Part 4 — `batch-record` (fdbatch.cob), 96 bytes

`amounts` is a group of four **unsigned** `9(9)v99 comp-3` fields — 11 digits
plus an `F` sign nibble, six bytes each.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0 | ledger | 9 | `33` (3 = sales) |
| 1..5 | batch-nos | 9(5) | `00044` |
| 6..7 | items | 99 | `55` |
| 8 | batch-status | 9 | `31` |
| 9 | cleared-status | 9 | `32` |
| 10..11 | bcycle | 99 | `3037` |
| 12..15 | entered | binary-long | `07b2 0100` (LE 111111) |
| 16..19 | proofed | binary-long | `0e64 0300` |
| 20..23 | posted | binary-long | `1516 0500` |
| 24..27 | stored | binary-long | `1cc8 0600` |
| 28..33 | input-gross | 9(9)v99 comp-3 | `12345678901f` |
| 34..39 | input-vat | 9(9)v99 comp-3 | `23456789012f` |
| 40..45 | actual-gross | 9(9)v99 comp-3 | `34567890123f` |
| 46..51 | actual-vat | 9(9)v99 comp-3 | `45678901234f` |
| 52..75 | description | x(24) | `DESCRIPTION-SENTINEL` |
| 76..77 | bdefault | 99 | `66` |
| 78..79 | convention | xx | `CN` |
| 80..85 | batch-def-ac | 9(6) | `000099` |
| 86..87 | batch-def-pc | 99 | `10` |
| 88..89 | batch-def-code | xx | `CD` |
| 90 | batch-def-vat | x | `V` |
| 91..95 | batch-start | 9(5) | `00077` |

`batch-key` is `ledger` + `batch-nos` (6 bytes) — the only indexed key here.
`ledger` is `3` for every sl060 batch (`88 sl-batch`).

## Part 5 — `open-item-record-3` is `open-item-record-2`, verbatim

`fdoi3.cob` redefines only the key (`oi3-customer`, `oi3-invoice` — the first
11 bytes) over a 114-byte record. `sl060` writes `open-item-record-3 FROM
oi-header`, and `oi-header` is exactly the 114-byte F-B008 shape, so **OTM3
carries OTM2's bytes unchanged**. Nothing new to measure; `OpenItem2`'s
existing codec covers it.

`oi3-key` also gives the phase-2 read order: the file is read `NEXT RECORD`
sequentially in `(customer, invoice)` order, so a credit note is followed by
any open items of the same customer with a higher invoice number.

## Part 6 — system accounts

`post-dr` is `s-debtors` (offset 231 of `wssystem.cob`'s 1024-byte system
record), `post-cr` is `sl-sales-ac` (235) and `posting-record.vat-ac` is
`vat-ac` (160). `mapserup`'s `sl-setup` zeroes all three, so on a stock
install they post as `000000` unless a human has set the nominal codes.
