# F-B008 — `oi-header` field offsets (F-B007 corrected) and the read-buffer fossil

Verified 2026-11-03 against bytes GnuCOBOL 3.1.2 writes through ACAS itself
(`harness/scenarios/sl055_extract.py` clean run), cross-read with
`cobol-original/sales/wsoi.cob`.

## Part 1 — F-B007's offset table is shifted by five bytes from `oi-extra` on

`wsoi.cob` declares

```
03 filler comp-3.
   05 oi-p-c     pic s9(7)v99.
   05 oi-net     pic s9(7)v99.
   05 oi-approp redefines oi-net pic s9(7)v99.
   05 oi-extra   pic s9(7)v99.
   ...
```

`oi-approp` is a **REDEFINES of `oi-net`** and takes no storage. The probe that
produced F-B007 moved a distinct sentinel into every field it listed, including
`oi-approp`, so every offset from `oi-extra` onward in that table is five bytes
too high — and the "119-byte overlay" conclusion follows from the same
double-count. `oi-header` is exactly **114 bytes**, exactly its FD; nothing is
truncated, so `oi-applied` and `oi-date-cleared` *are* on disk.

Observed layout, from record 1 of `harness/runs/20261103-035813-sl055-clean`
(fixture invoice: p-c 1200.00, net 1000.00, vat 200.00; all other legs zero):

| Offset | Field | Bytes | Reading |
|---|---|---|---|
| 49 | oi-p-c | `00 01 20 00 0c` | 120000 |
| 54 | oi-net (= oi-approp) | `00 01 00 00 0c` | 100000 |
| 59 | oi-extra | `00 00 00 00 0c` | 0 |
| 64 | oi-carriage | `00 00 00 00 0c` | 0 |
| 69 | oi-vat | `00 00 20 00 0c` | **20000** |
| 74 | oi-discount | `00 00 00 00 0c` | 0 |
| 79 | oi-e-vat | `00 00 00 00 0c` | 0 |
| 84 | oi-c-vat | `00 00 00 00 0c` | 0 |
| 89 | oi-paid | `00 00 00 00 0c` | 0 |
| 94 | oi-status | `30` | `"0"` (display digit) |
| 95 | oi-deduct-days | `00` | 0 |
| 96..99 | oi-deduct-amt | `00 00 00 00` | 0 (BE comp) |
| 100..103 | oi-deduct-vat | `00 00 00 00` | 0 (BE comp) |
| 104 | oi-days | `00` | 0 |
| 105..108 | oi-cr | `ac 5f 02 00` | 155564 (LE) |
| 109 | oi-applied | `20` | space |
| 110..113 | oi-date-cleared | `00 00 00 00` | 0 |

The decisive check is offset 69: the fixture's only non-zero VAT leg is
`ih-vat`, and `dd000-Extract` `move ih-vat to oi-vat` puts it there. F-B007
placed `oi-vat` at 74, where this record reads zero.

## Part 2 — `ih-update` survives the record boundary in the read buffer

`ih-update` is the last field of the 137-byte `invoice-header` overlay on the
134-byte `invoice-record` (F-B006), so it never reaches disk. But `sl055` reads
each record into the same 137-byte working-storage area, and a `read` only
overwrites the first 134 bytes: byte 136 keeps whatever the *previous* record
left there.

Therefore, once one header has been posted, its `move "Z" to ih-update` makes
every later header in the batch look `ih-analyised`. From `da020-Header-Analysis`:

```
perform  dd000-Extract.
if       ih-analyised
         rewrite invoice-record
         go to da010-Read-Loop.
```

The later invoice still gets its open-item record (dd000 has already run) but
never reaches the four `ws-*-total` accumulations.

Observed on the clean fixture — two structurally identical, printed, unpaid
invoices (1001 vat 200.00, 1002 vat 100.00):

- both `openitm2` records exist and both carry their VAT (`…00 00 20 00 0c`
  and `…00 00 10 00 0c` at offset 69);
- the `value.flat` dump shows the VAT-return bucket `Svp`/`Sv ` at
  **1 hit / 20000**, not 2 / 30000 — only invoice 1001 counted.

Reproduce:

```
python3 harness/parity_harness.py run --scenario sl055-clean
```

and compare `artifacts/openitm2.dat` against `dump/value.flat`.

Consequence for the port: `ExtractRun::buffer_update` models the byte. It holds
`b' '` at run start and `b'Z'` once a header has been processed through the
totals; the `ih-analyised` test reads the *buffer*, never the (always blank)
disk field. Skipped headers — proforma, pending, unprinted — leave it untouched,
exactly as COBOL does.

This is bug-compatible behaviour, not a design choice: a "fixed" ACAS would
count every invoice's VAT. Parity wins.
