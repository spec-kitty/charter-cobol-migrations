# F-B055 — the purchase invoice and open-item-4 records, and where pl055 differs from sl055

Verified 2026-11-04 against bytes GnuCOBOL 3.1.2 itself writes through ACAS's
own overlays: `/tmp/pprobe/p.cbl` (source below) MOVEs a sentinel into every
`invoice-header`, `invoice-line` and `oi-header` field, MOVEs the overlay onto
the FD record and WRITEs it. Offsets are where each sentinel landed.

## Part 1 — no truncation, on either record

The sales side carries two write-MOVE fossils (F-B006): `invoice-header` is
137 bytes over a 134-byte FD, and `wsoi.cob`'s `oi-header` is 119 over 114.
Purchase renamed and re-cut both records, and the gaps are gone:

| overlay | length | FD | dropped |
|---|---|---|---|
| `invoice-header` (fdpinv2.cob) | **129** | 129 | none |
| `invoice-line` (fdpinv2.cob) | 74 | 129 | bytes 74..129 ride as tail |
| `oi-header` (wsoi.cob) | **109** | 109 | none |

Two consequences the port must carry rather than repair:

1. **`ih-update` and `il-update` do persist here.** At 98 and 73 respectively,
   both are inside the record, so the F-B008 read-buffer fossil (sl055's
   `ih-update` sitting at byte 136 of a 134-byte frame, always stale) does not
   exist for pl055. A re-run of pl055 sees genuinely-set `ih-analyised` /
   `il-analyised` flags. Idempotence is real here, not buffered.
2. `ih-day-book-flag` (97) and `ih-lines` (82) are inside the record too, so
   unlike sales they survive a rewrite.

`fdpinv2.cob`'s header comment says "129 bytes"; the line comment says
"74 bytes 22/12/11". Both match the measurement.

## Part 2 — `invoice-record` (fdpinv2.cob), 129 bytes

`invoice-nos` is `9(8)` **display** (eight ASCII digits, not binary) and
`item-nos` is `binary-char` (one raw byte, zero for a header). `ih-date` and
`ih-cr` are `binary-long` = four bytes **Little Endian** — GnuCOBOL's native
representation on x86-64, so `155534` lands `8e 5f 02 00`.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0..7 | invoice-nos | 9(8) display | `3030303031303032` (`00001002`) |
| 8 | invoice-key item-nos / `ih-test` / `il-line` | binary-char | `00` (header) |
| 9..15 | ih-supplier (ih-nos + ih-check) | x(6) + 9 | `SUPP015` |
| 16..19 | ih-date | binary-long | `8e 5f 02 00` (LE 155534) |
| 20..29 | ih-order | x(10) | `ORD2` + spaces |
| 30 | ih-type | 9 | `32` (`2`) |
| 31..40 | ih-ref | x(10) | `REF2` + spaces |
| 41..45 | ih-fig[0] ih-p-c | s9(7)v99 comp-3 | `000001100c` |
| 46..50 | ih-fig[1] ih-net | s9(7)v99 comp-3 | `000001200c` |
| 51..55 | ih-fig[2] ih-extra | s9(7)v99 comp-3 | `000001300c` |
| 56..60 | ih-fig[3] ih-carriage | s9(7)v99 comp-3 | `000001400c` |
| 61..65 | ih-fig[4] ih-vat | s9(7)v99 comp-3 | `000001500c` |
| 66..70 | ih-fig[5] ih-discount | s9(7)v99 comp-3 | `000001600c` |
| 71..75 | ih-fig[6] ih-e-vat | s9(7)v99 comp-3 | `000001700c` |
| 76..80 | ih-fig[7] ih-c-vat | s9(7)v99 comp-3 | `00000180 0c` |
| 81 | ih-status | x (+88 pending/invoiced/applied) | `70` (`p`) |
| 82 | ih-lines | binary-char | `03` |
| 83 | ih-deduct-days | binary-char | `04` |
| 84..87 | ih-deduct-amt | 999v99 comp, **unsigned** | `0001869f` (BE 99999 = 999.99) |
| 88..91 | ih-deduct-vat | 999v99 comp, unsigned | `00015b38` (BE 88888 = 888.88) |
| 92 | ih-days | binary-char | `05` |
| 93..96 | ih-cr | binary-long | `d0 5f 02 00` |
| 97 | ih-day-book-flag | x (+88 day-booked) | `62` (`b`) |
| 98 | ih-update | x (+88 ih-analyised) | `5a` (`Z`) |
| 99..128 | filler | x(30) | spaces |

`ih-deduct-amt`/`ih-deduct-vat` are **unsigned** `999v99` on the invoice but
**signed** `s999v99` on the open item; `move` between them is a widening with
no sign to lose.

`invoice-line` (74 bytes) lies over the same record area:

| Offset | Field | PIC/usage |
|---|---|---|
| 0..7 | il-invoice | 9(8) display |
| 8 | il-line | binary-char |
| 9..21 | il-product | x(13) |
| 22..23 | il-pa | xx |
| 24..25 | filler | xx |
| 26..27 | il-qty | binary-short |
| 28 | il-type | x |
| 29..52 | il-description | x(24) |
| 53..54 | filler | xx |
| 55..59 | il-net | s9(7)v99 comp-3 |
| 60..64 | il-unit | s9(7)v99 comp-3 |
| 65..66 | il-discount | 99v99 comp |
| 67..71 | il-vat | s9(7)v99 comp-3 |
| 72 | il-vat-code | 9 |
| 73 | il-update | x (+88 il-analyised) |

## Part 3 — `open-item-record-4` (fdoi4.cob), 109 bytes, overlay `oi-header`

`fdoi4.cob` is `01 open-item-record-4 pic x(109)`. The `wsoi.cob` overlay is
**also 109** — this is the purchase cut of the sales record, 5 bytes shorter
than `wsoi.cob` under sales/ because `oi-description` (x(25)) is **absent** and
`oi-ref`/`oi-order` swapped position. `oi-approp` is a REDEFINES of `oi-net`
and takes no storage.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0..5 | oi-nos | x(6) | `CUST01` |
| 6 | oi-check | 9 | `37` |
| 7..10 | oi-invoice | binary-long | `e9 03 00 00` (LE 1001) |
| 11..14 | oi-date | binary-long | `8e 5f 02 00` (LE 155534) |
| 15..18 | oi-b-nos | 9(5) comp | `00002b67` (BE 11111) |
| 19..20 | oi-b-item | 999 comp | `00de` (BE 222) |
| 21 | oi-type | 9 | `33` (`3`) |
| 22..31 | oi-ref | x(10) | `REF-SENT-1` |
| 32..41 | oi-order | x(10) | `ORDER-SENT` |
| 42 | oi-hold-flag | x | `48` (`H`) |
| 43 | oi-unapl | x | `55` (`U`) |
| 44..48 | oi-p-c | s9(7)v99 comp-3 | `000000100c` |
| 49..53 | oi-net (= oi-approp) | s9(7)v99 comp-3 | `000000200c` |
| 54..58 | oi-extra | s9(7)v99 comp-3 | `000000400c` |
| 59..63 | oi-carriage | s9(7)v99 comp-3 | `000000500c` |
| 64..68 | oi-vat | s9(7)v99 comp-3 | `000000600c` |
| 69..73 | oi-discount | s9(7)v99 comp-3 | `000000700c` |
| 74..78 | oi-e-vat | s9(7)v99 comp-3 | `000000800c` |
| 79..83 | oi-c-vat | s9(7)v99 comp-3 | `000000900c` |
| 84..88 | oi-paid | s9(7)v99 comp-3 | `000001000c` |
| 89 | oi-status | 9 (+88 s-open/s-closed) | `31` (`1`) |
| 90 | oi-deduct-days | binary-char | `09` |
| 91..94 | oi-deduct-amt | s999v99 comp | `000004d2` (BE 1234) |
| 95..98 | oi-deduct-vat | s999v99 comp | `0000162e` (BE 5678) |
| 99 | oi-days | binary-char | `07` |
| 100..103 | oi-cr | binary-long | `ac 5f 02 00` (LE 155564) |
| 104 | oi-applied | x | `59` (`Y`) |
| 105..108 | oi-date-cleared | binary-long | `d0 5f 02 00` (LE 155600) |

`oi-type` and `oi-status` are PIC 9: the byte is the character, not the value.
`oi-b-nos`/`oi-b-item` are the *cleared* batch numbers — pl055 always zeroes
them, and pl070/pl072 are what fill them.

## Part 4 — `value-record` / `analysis-record`

Identical to the sales copies (`fdval.cob` 66 bytes, `fdanal.cob` 36 bytes).
Offsets are F-B007 Part 2 and the correction note there; nothing differs, and
`pl055` addresses the same `va-*` / `pa-*` names in the same positions.

Probe source `/tmp/pprobe/p.cbl`, compiled `cobc -free -x`. Committed copies of
the two FD records used by the probe are the stock `fixtures/isam_probe/`
`fdval.cob` / `fdanal.cob`.

## Part 5 — the month counters move inside `extract`, not after the analysed test

Measured 2026-11-04 on the `pl055-mixed` scenario (run
`20261104-013403-pl055-mixed`, reproduced `013546`). `mixed` carries one header
per shape: 3001 `ih-update = Z` **and** `ih-status = z` (analysed + applied),
3002 type 1 (receipt), 3003 type 4, 3004 `ih-update = Z` only (analysed, not
applied), 3005..3007 type 2.

`pl-invoices-this-month` (system-record-4 bytes **3176..3181**, `s9(8)v99
comp-3`) came back **2910** — exactly 3004 + 3005 + 3006 + 3007
(`960 + 480 + 870 + 600`). So:

1. **An analysed-but-not-applied header still moves the month counter.** The
   two `add` statements sit inside the `extract` section, *before* the
   `move "z" to ih-status` and the open-item write. `header-analysis` performs
   `extract` and only afterwards tests `if ih-analyised` — which skips the
   *specials* block, not the counter.
2. **An applied header never reaches `extract`** (`if applied go to main-exit`
   is its first statement), so analysed + applied moves nothing.
3. **Type 4 builds `ws-inv-amt` and is counted by neither counter.** Only
   `ih-type = 2` and `= 3` follow the `add`.

The consequence is a split: 3004 is present in `Pv`-style counters and absent
from `Pvi`/`Pza`/`Pzb`. Reading the section as "totals" and skipping all of it
for an analysed header is 960 out of 2910 on this fixture.

Also measured there: `s9(8)v99` is 11 digit nibbles plus a sign, six bytes —
`2910` stores `00 00 00 02 91 0c` and `2500` stores `00 00 00 02 50 0c`
(part 9 of F-B072's reading). The counter pair is now gated as
`golden/<case>/counters.flat`.

Build restored: `/tmp/acas-build/purchase/pl055.cbl` was instrumented for this
measurement and put back byte-identical to the vendored copy before the
goldens were re-captured.
