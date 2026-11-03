# Disposition — sl070 analysis + value records (`fdanal.cob`, `fdval.cob`)

`sl070` writes all of `analysis-record` (36 bytes) and all of `value-record`
(66 bytes) via `p-a-setup`, and reads back 36 bytes' worth through `report1`.
Both ledgers account for **every byte**, so nothing is written or printed by
accident.

Offsets are zero-based; a field's bytes are `offset .. offset + length`.
Accessors name the typed field in `crates/acas-sales/src/pa_report.rs`.

## `analysis-record` — 36 bytes, key `pa-code` (3)

| offset | len | COBOL field | disposition |
|---|---|---|---|
| 0 | 1 | `pa-system` | written by `p-a-setup` (`S`/`P`); printed as `l6-ledger` on group rows in print-all mode only |
| 1 | 2 | `pa-group` | written by `p-a-setup`; printed as `l6-code`; `pa-second` (offset 2) drives the group test |
| 3 | 6 | `pa-gl pic 9(6)` | written as `000000`; divided by 100 into `l6-gl` (printed) unless `Irs-Used`, where it is printed whole |
| 9 | 24 | `pa-desc` | written by `p-a-setup`; printed as `l6-desc` |
| 33 | 3 | `pa-print` | written by `p-a-setup`; printed as `l6-print` |

`pa-code` is the record key: `pa-system ++ pa-group`, no filler, no check
digit.

## `value-record` — 66 bytes, key `va-code` (3)

`create-value` is the only writer. The first 36 bytes are a copy of the
analysis record; the three counter fields are carried from the working-storage
record (zero in practice, never explicitly cleared); the three money fields are
zeroed.

| offset | len | COBOL field | disposition |
|---|---|---|---|
| 0 | 3 | `va-code` | copied from `pa-code`, the record key |
| 3 | 6 | `va-gl` | copied from `pa-gl` |
| 9 | 24 | `va-desc` | copied from `pa-desc` |
| 33 | 3 | `va-print` | copied from `pa-print` |
| 36 | 4 | `va-t-this` `pic 9(5) comp` | not cleared here; zero in practice. Binary-long, big-endian |
| 40 | 4 | `va-t-last` (same) | as above |
| 44 | 4 | `va-t-year` (same) | as above |
| 48 | 6 | `va-v-this` `pic s9(8)v99 comp-3` | **zeroed** (`PackedValue::ZERO`) |
| 54 | 6 | `va-v-last` (same) | **zeroed** |
| 60 | 6 | `va-v-year` (same) | **zeroed** |

The record has no filler; 0 + 3 + 6 + 24 + 3 + 12 + 18 = 66.
