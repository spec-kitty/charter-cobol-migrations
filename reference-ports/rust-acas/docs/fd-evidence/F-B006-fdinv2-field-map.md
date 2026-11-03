# F-B006 — fdinv2 header/line field map (GnuCOBOL-observed)

Verified 2026-11-03 against bytes GnuCOBOL 3.1.2 itself writes through ACAS's
own `invoice-header` and `invoice-line` overlays
(`fixtures/isam_probe/capture_header.cbl` → `fixtures/generated/capture/invoice-capture.dat`).

method: every field of the overlay is MOVE'd a distinctive value, the overlay
is MOVE'd onto the 134-byte `invoice-record`, the record is WRITTEN, and the
file is dumped. Offsets below are where each sentinel landed, not where the
copybook comment says it should land.

## The headline fact

`invoice-header` is **137 bytes** in GnuCOBOL, but the FD it overlays
(`invoice-record`) is **134 bytes**. `cobc` warns:

```
warning: size of record 'invoice-header' (137) larger than maximum of file 'invoice-file' (134)
```

ACAS writes with `move sinvoice-header to invoice-record`
(sl910:1240, sl920:1415, sl930:788, sl950:654), so the MOVE truncates and the
last three bytes of the header never reach disk:

| bytes | field | on disk? |
|---|---|---|
| 131..134 | `ih-cr` binary-long | partially — low 3 bytes only |
| 135 | `ih-day-book-flag` | **no** |
| 136 | `ih-update` | **no** |

Consequences, both observed:

- `ih-cr` reads back as `0x20025fac`-shaped garbage: COBOL's MOVE pads the
  134-byte record with **spaces**, so the 4th byte of cr reads `0x20`.
  A fresh `README`-era file therefore yields `cr = 0x20000000 | days`.
- `ih-day-book-flag` and `ih-update` are memory-only. In one process they
  survive between records because the record area is never re-initialised on
  READ (probe `rw.cbl`: record 2 reads record 1's flags). Across processes
  they come from the MOVE-pad (= space) and are always blank.

This is a live ACAS bug: `sl055` does `if ih-analyised ... rewrite` and
`move "Z" to ih-update; rewrite invoice-record` — the analysed flag cannot
persist, so a second extract re-processes everything.

## invoice-header offsets (as written into the 134-byte record)

| Offset | Field | PIC/usage | Observed bytes for sentinel |
|---|---|---|---|
| 0..8 | ih-invoice | 9(8) | `3030303030303432` = `00000042` |
| 8 | ih-letter | x | `4c` (`L`) |
| 9 | ih-test | binary-char | `00` (0 = header dispatch) |
| 10..16 | ih-nos | x(6) | `CUST01` |
| 16 | ih-check | 9 | `37` (`7`) |
| 17..21 | ih-date | binary-long LE | `8e 5f 02 00` = 155534 |
| 21..31 | ih-order | x(10) | `ORDER-0001` |
| 31 | ih-type | 9 | `31` (`1`) |
| 32..42 | ih-ref | x(10) | `REF-000001` |
| 42..74 | ih-description | x(32) | `abc…345` |
| 74..114 | ih-fig (8 × s9(7)v99 comp-3) | **5 B each** | see below |
| 114 | ih-status | x (+88 P/I/z/Z) | `50` (`P`) |
| 115..120 | ih-status-P,L,C,A,I | x ×5 | `61 62 63 64 65` |
| 120 | ih-lines | binary-char | `07` |
| 121 | ih-deduct-days | binary-char | `09` |
| 122..126 | ih-deduct-amt | 999v99 **comp = 4 B BE** | `00 00 30 39` = 12345 |
| 126..130 | ih-deduct-vat | 999v99 comp = 4 B BE | `00 00 1a 85` = 6789 |
| 130 | ih-days | binary-char | `03` |
| 131..134 | ih-cr | binary-long LE, **truncated to 131..133** | `ac 5f 02` (of `ac 5f 02 00`) |
| 135 | ih-day-book-flag | x | not written |
| 136 | ih-update | x (+88 z/Z) | not written |

### ih-fig (74..114), 5 bytes per field, packed, sign nibble in the last byte

| Offset | Field | Sentinel |
|---|---|---|
| 74 | ih-p-c | `00 01 23 45 6c` = +1234.56 |
| 79 | ih-net | `00 07 65 43 2d` = −7654.32 |
| 84 | ih-extra | +1.00 |
| 89 | ih-carriage | +2.00 |
| 94 | ih-vat | +3.00 |
| 99 | ih-discount | +4.00 |
| 104 | ih-e-vat | +5.00 |
| 109 | ih-c-vat | +6.00 |

Sign nibbles seen: `C` positive, `D` negative (COBOL default, F = unsigned
accepted on read — carried verbatim either way).

## invoice-line offsets (80-byte overlay; bytes 80..134 unwritten)

| Offset | Field | PIC/usage | Sentinel |
|---|---|---|---|
| 0..8 | il-invoice | 9(8) | `00000042` |
| 8 | il-letter | x | `L` |
| 9 | il-line | binary-char | `03` |
| 10..23 | il-product | x(13) | `PRODUCT-00001` |
| 23..25 | il-pa | xx | `PA` |
| 25..27 | il-qty | binary-short LE | `11 00` = 17 |
| 27 | il-type | x | `33` (`3` = credit) |
| 28..60 | il-description | x(32) | `abc…345` |
| 60..65 | il-net | s9(7)v99 comp-3 | `00 01 23 45 6d` = −1234.56 |
| 65..70 | il-unit | s9(7)v99 comp-3 | `00 09 99 99 9c` = +9999.99 |
| 70..72 | il-discount | 99v99 comp = **2 B BE** | `04 d2` = 1234 (12.34) |
| 72..77 | il-vat | s9(7)v99 comp-3 | `00 00 05 67 8c` = +56.78 |
| 77 | il-vat-code | 9 | `38` (`8`) |
| 78 | il-update | x (+88 z/Z) | `7a` (`z`) |
| 79 | filler | x | space |
| 80..134 | (outside the line overlay) | — | spaces |

Line records are 80 meaningful bytes in a 134-byte frame; the remaining 54 are
whatever the writer's record buffer held — spaces for a fresh MOVE. The Rust
type carries them so a round-trip stays byte-identical instead of silently
rewriting them to zero.

## Corrections this note forces

- **`comp` here is 4 bytes, big-endian** for `999v99` and 2 bytes for the
  line's `99v99`. The header's `ih-sub-prime` "92 bytes" comment undercounts:
  with two 4-byte comps the group is 95. Header = 137.
- `fixtures/fdinv2_builder.py` placed `ih-deduct-amt` at 122 as a 2-byte LE
  short and pushed `ih-days`/`ih-cr`/`ih-day-book-flag`/`ih-update` to
  126/127/131/132 — everything from byte 122 on was mis-framed, and the
  builder wrote the dead `day-book`/`update` bytes positionally where COBOL
  reads `ih-days`/`ih-cr`. Fixed under WP03 (DP-003).
- The current `invoice.rs` `filler_2013: [u8; 5]` at `129..134` is not a
  filler: 129..130 are the tail of `ih-deduct-vat`, 131..134 are `ih-cr`.

## Reproduce

```bash
fixtures/isam_probe/capture.sh   # rewrites fixtures/generated/capture/invoice-capture.dat
python3 - <<'PY'
d = open('fixtures/generated/capture/invoice-capture.dat','rb').read()
print(len(d), d[118:137].hex())   # 268; 1a 85 03 ac 5f 02 + record pad
PY
```
