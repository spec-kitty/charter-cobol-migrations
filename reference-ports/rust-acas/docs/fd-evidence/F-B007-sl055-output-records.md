# F-B007 — sl055 output records, and why the flat fixtures never ran

Verified 2026-11-03 against bytes GnuCOBOL 3.1.2 itself writes through ACAS's
own overlays: `fixtures/isam_probe/../oiprobe`-style sentinel programs
(`/tmp/oiprobe/{w,v}.cbl`, sources copied below) MOVE a distinctive value into
every field of `wsoi.cob`'s `oi-header` and `fdval.cob`'s `value-record`, WRITE
the overlay onto the FD record, and dump the file. Offsets are where each
sentinel landed.

## Part 1 — the blocker: flat fixtures are not openable by ACAS

`selinv.cob` / `selval.cob` / `selanal.cob` declare `organization indexed` with
`access dynamic`. `fdinv2_builder.py` writes a *flat* frame (N fixed records +
32-byte space trailer, the F-B002 **relative**-file framing). Opening a flat
file through an indexed FD fails:

```
open i-o invoice-file  → fs-reply = 35   ("file attributes mismatch")
```

`35` is not a warning; the read pointer is never positioned and the whole read
loop is skipped. Every `sl055` run before this note therefore did **no work at
all** while still exiting 0 — including the run quoted as WP03 parity evidence
(run `20261103-015937-sl055-wp03`: `invoice.dat` identical because unchanged,
`value.dat`/`openitm2.dat` empty). The F-B002 framing applies to the
*sequential* side (`open-item-file-2`) only.

Consequence for the harness: the indexed tables must be **BDB-born**. Three
helper programs under `fixtures/cobol_loader/` (build: `build.sh`) do that
without inventing bytes:

| helper | role |
|---|---|
| `mkidx.cbl` | OPEN OUTPUT + CLOSE on each indexed FD — GnuCOBOL mints empty BDB tables |
| `loadinv.cbl`, `loadana.cbl`, `loadval.cbl` | stream the flat fixture rows into the indexed files |
| `dumpval.cbl`, `dumpsanal.cbl` | read an indexed file in key order and emit raw records to a flat stream, so *logical* contents can be hashed and diffed |

The flat `.dat` fixtures stay the Rust-side input contract; they are loaded,
never opened directly by ACAS.

## Part 2 — `value-record` (fdval.cob), 66 bytes

`va-v-*` fields are `s9(8)v99 comp-3` = **six** bytes (10 digits → 11 nibbles
including the sign → padded to 12). `va-t-*` are `9(5) comp` = 4 bytes
big-endian. Sentinels: `S`/`ABC`, gl `123456`, desc, print `PRT`,
t = 11111/22222/33333, v = +34567890.12 / -34567890.12 / 99999999.99.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0 | va-system | x | `53` (`S`) |
| 1..2 | va-first/va-second (`va-group`) | xx | `4142` (`AB`) |
| 3..8 | va-gl | 9(6) display | `313233343536` (`123456`) |
| 9..32 | va-desc | x(24) | `DESC-SENTINEL-...` space-padded |
| 33..35 | va-print | xxx | `505254` (`PRT`) |
| 36..39 | va-t-this | 9(5) comp | `00002b67` (BE 11111) |
| 40..43 | va-t-last | 9(5) comp | `000056ce` |
| 44..47 | va-t-year | 9(5) comp | `00008235` |
| 48..53 | va-v-this | s9(8)v99 comp-3 | `0345678901 2c` |
| 54..59 | va-v-last | s9(8)v99 comp-3 | `0345678901 2d` (D = negative) |
| 60..65 | va-v-year | s9(8)v99 comp-3 | `0999999999 9c` |

Overflow is silent truncation, not an error: `1234567890.12` lands as
`34567890.12` because only 8 integer digits exist.

`value-record` exactly fills its own 66-byte FD — nothing is dropped here.
(`fdanal.cob`'s `analysis-record` is the first 36 bytes of the same shape:
code 3, gl 6, desc 24, print 3.)

## Part 3 — `oi-header` (wsoi.cob), written through a 114-byte FD

`fdoi2.cob` is `pic x(114)`. `wsoi.cob`'s `oi-header` is **119 bytes**: the WD
overlay is 5 bytes longer than its record, so `move oi-header to
open-item-record-2` truncates — the same fossil as F-B006, in the opposite
direction (a *write* MOVE that silently drops the tail).

Fields past the record edge, therefore never on disk:

| bytes | field | on disk? |
|---|---|---|
| 114 | `oi-applied` | **no** |
| 115..118 | `oi-date-cleared` | **no** |

sl055 always sets both to spaces/zero before writing, so nothing observable is
lost — but a reader must not expect them.

| Offset | Field | PIC/usage | Observed |
|---|---|---|---|
| 0..5 | oi-nos | x(6) | `CUST01` |
| 6 | oi-check | 9 | `37` |
| 7..10 | oi-invoice | binary-long | `e9 030000` (LE 1001) |
| 11..14 | oi-date | binary-long | `8e 5f 0200` (LE 155534) |
| 15..18 | oi-b-nos | 9(5) comp | `00002b67` (BE 11111) |
| 19..20 | oi-b-item | 999 comp | `00de` (BE 222) |
| 21 | oi-type | 9 | `33` (`3`) |
| 22..46 | oi-description | x(25) | sentinel, space-padded |
| 47 | oi-hold-flag | x | `48` (`H`) |
| 48 | oi-unapl | x | `55` (`U`) |
| 49..53 | oi-p-c | s9(7)v99 comp-3 | `000000100c` |
| 54..58 | oi-net | s9(7)v99 comp-3 | `000000200c` |
| 59..63 | (unreferenced slot under the same comp-3 filler) | — | `000000300c` |
| 64..68 | oi-extra | s9(7)v99 comp-3 | `000000400c` |
| 69..73 | oi-carriage | s9(7)v99 comp-3 | `000000500c` |
| 74..78 | oi-vat | s9(7)v99 comp-3 | `000000600c` |
| 79..83 | oi-discount | s9(7)v99 comp-3 | `000000700c` |
| 84..88 | oi-e-vat | s9(7)v99 comp-3 | `000000800c` |
| 89..93 | oi-c-vat | s9(7)v99 comp-3 | `000000900c` |
| 94..98 | oi-paid | s9(7)v99 comp-3 | `000001000c` |
| 99 | oi-status | 9 | `31` (`1`) |
| 100 | oi-deduct-days | binary-char | `09` |
| 101..104 | oi-deduct-amt | s999v99 comp | `000004d2` (BE 1234) |
| 105..108 | oi-deduct-vat | s999v99 comp | `0000162e` (BE 5678) |
| 109 | oi-days | binary-char | `07` |
| 110..113 | oi-cr | binary-long | `ac 5f 0200` (LE 155564) |

`oi-type` and `oi-status` are PIC 9 display: the byte is the character, not the
value. `oi-b-nos`/`oi-b-item` are always zero from sl055.

## Correction (2026-11-03, WP04)

Offsets from `oi-extra` (64) onward are **five bytes too high**: the probe
carried a separate sentinel for `oi-approp`, which is a REDEFINES of `oi-net`
and takes no storage. Consequently `oi-header` is exactly 114 bytes, nothing is
truncated, and `oi-applied` / `oi-date-cleared` do reach disk. True table and
the measurement: F-B008. The `value-record` table above is unaffected.

Probe sources: `/tmp/oiprobe/w.cbl`, `/tmp/oiprobe/v.cbl` (committed copies
under `fixtures/isam_probe/` as `oiprobe_oi2.cbl`, `oiprobe_value.cbl`).
