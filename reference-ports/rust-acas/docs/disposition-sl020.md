# Disposition — `sl020` sales-ledger enquiry

`sl020` reads three files and writes one print file. The byte-level layout of
each record is already dispositioned elsewhere and is not repeated here:

- `sales-record` (300 B) — `docs/disposition-sl010.md`, decoded by
  `post::SalesRow`;
- `open-item-record-2/3` (114 B) — `docs/disposition-fdoi2.md`, decoded by
  `posting::OpenItem2`;
- `invoice-record` / `invoice-header` (134 B) — `docs/disposition-fdinv2.md`,
  decoded by `invoice::InvoiceHeader`.

This ledger accounts for every one of those fields **as `sl020` uses it**, plus
every byte of the 80-byte print record. Offsets are zero-based. Accessors name
the typed field in `crates/acas-sales/src/ledger_enquiry.rs`.

## `sales-record` — the customer block

| offset | len | COBOL field | disposition |
|---|---|---|---|
| 0 | 7 | `sales-key` | compared against `customer-in` (F-B015 Part 8: on a failed keyed start the bytes are the ones the caller `move`d in); printed as `l2-account` |
| 7 | 30 | `sales-name` | printed as `l1-name` |
| 37 | 48 | `sales-addr1` | first half of `sales-address`; unstrung on `sl-delim` (Part 5) |
| 85 | 48 | `sales-addr2` | second half of `sales-address`; same |
| 133 | 60 | phone, ext, email, fax, status, late, dunning, email switches, tags, `sales-credit` | **not** read by `sl020` |
| 193 | 1 | `sales-status` | not read — the enquiry takes whatever the key lands on |
| 204 | 2 | `sales-credit` (days) | not read |
| 206 | 2 | `sales-discount` | not read |
| 208 | 4 | `sales-late-min` / `sales-late-max` | not read |
| 212 | 4 | `sales-limit` | `move` to `l4-credit-limit` (`z(7)9`, whole units) |
| 216 | 32 | activety, last-inv, last-pay, average, pay-* , create-date | not read |
| 248 | 6 | `sales-current` | `move` to `l2-balance` (`z(6)9.99`) |
| 254 | 6 | `sales-last` | not read |
| 260 | 24 | `turnover-q1..q4` | added together into `l3-ytd` (`z(7)9` — the `move` truncates the hundredths, Part 4) |
| 284 | 6 | `sales-unapplied` | `move` to `l3-unapplied` (`z(6)9.99`) |
| 290 | 10 | `tail` | not read |

## `open-item-record-3` — the item rows

Read through `oi-header` (`wsoi.cob`). Fields `sl020` uses:

| offset | len | COBOL field | disposition |
|---|---|---|---|
| 0 | 7 | `oi-customer` | compared against `sales-key`; a mismatch ends the loop |
| 7 | 4 | `oi-invoice` | `move` to `l7-invoice` (`z(7)9 blank when zero`); zeroed for types 5/6 (Part 4) |
| 11 | 4 | `oi-date` | `zz060-Convert-Date` → `l7-date`; also the ageing subtraction operand |
| 21 | 1 | `oi-type` | selects description text, ageing path and the paid sign |
| 22 | 25 | `oi-description` | copied into the `Goods - ` line, stopping at the first two spaces |
| 47 | 1 | `oi-hold-flag` | not space → `Q` in `l7-hold` |
| 54 | 5 | `oi-net` | `inv-amount` sum |
| 59 | 5 | `oi-extra` | `inv-amount` sum |
| 64 | 5 | `oi-carriage` | `inv-amount` sum |
| 69 | 5 | `oi-vat` | `inv-amount` sum |
| 74 | 5 | `oi-discount` | `inv-amount` sum (already negative on disk) |
| 79 | 5 | `oi-e-vat` | `inv-amount` sum |
| 84 | 5 | `oi-c-vat` | `inv-amount` sum |
| 89 | 5 | `oi-paid` | printed as `l7-paid`; negated for a credit note, subtracted from `inv-amount` (types 2/3 only) |
| 105 | 4 | `oi-cr` | `move` to `ws-inv8` (`z(7)9`) for the `CN.Re Inv -` text |
| 49 | 5 | `oi-p-c` | not read |
| 94 | 1 | `oi-status` | not read |
| 95 | 1 | `oi-deduct-days` | not read |
| 96 | 4 | `oi-deduct-amt` | `inv-amount` sum |
| 100 | 4 | `oi-deduct-vat` | `inv-amount` sum |
| 104 | 1 | `oi-days` | not read |
| 109 | 1 | `oi-applied` | not read |
| 110 | 4 | `oi-date-cleared` | not read |

## `invoice-header` — the work file

Only `set-up-work-file` reads this file, and only headers.

| offset | len | COBOL field | disposition |
|---|---|---|---|
| 9 | 1 | `ih-test` | non-zero (a line) is skipped |
| 114 | 1 | `ih-status` | `"z"` (applied, lower case only — the 88-level is not used) is skipped |
| 31 | 1 | `ih-type` | `1` and `4` are skipped; `3` negates the total |
| 7 | 1 + 8 | `ih-customer` | key of the `work-record` |
| 0 | 8 | `ih-invoice` | number of the `work-record` |
| 79..114 | 35 | `ih-net`, `ih-extra`, `ih-carriage`, `ih-vat`, `ih-discount`, `ih-e-vat`, `ih-c-vat`, plus `ih-deduct-amt` / `ih-deduct-vat` | added into `work-amount`; `ih-discount` is **added**, not subtracted (Part 2) |

Everything else in the header is not read.

## `print-record` — the 80-byte spool line

`print-record` is `pic x(80)`. Every line is a `01` filled from literals and
`move`s; unset positions stay spaces.

| line | width | content |
|---|---|---|
| `line-0` | 80 | `prog-name` at 1 (15), `l0-title` at 31 (20), `l0-date` at 71 (10) |
| `line-1` | 80 | `Customer:` at 1, name at 11 (30), forty `*` at 41 |
| `line-2` | 80 | `Address :` at 1, address line 1 at 11 (30), `* A/C Nos` at 41, account at 51 (8), `*Balance` at 59, balance at 70 (`z(6)9.99`, 10), `*` at 80 |
| `line-3` | 80 | address line 2 at 11, `* YTD` at 41, ytd at 51 (`z(7)9`, 8), `*Unapplied` at 59, unapplied at 70, `*` at 80 |
| `line-4` | 80 | address line 3 at 11, `* Credit` at 41, limit at 51, `*Unposted` at 59, unposted at 70, `*` at 80 |
| `line-5` | 80 | address line 4 at 11, forty `*` at 41 |
| `line-6` | 80 | `Number` at 2, `Date` at 14, `Description` at 24, `Invoiced` at 47, `Paid` at 64, `Balance` at 74 |
| `l7-group` | 80 | invoice at 1 (`z(7)9 blank when zero`), hold at 10, date at 12 (11), description at 23 (19), invoiced at 42 (13), paid at 55 (13), balance at 68 (13) |
| `line-20` | 80 | `Inv #` at 1, `Total O/S` at 8, `Current` at 28, `30` at 46, `60` at 61, `90+` at 75 |
| `line-21` | 80 | row count at 1 (`zz9`), total at 6 (`zz,zzz,zz9.99`), `bal-0` at 19 (`z(6),zzz,zz9.99`), `bal-30` at 36, `bal-60` at 51, `bal-90` at 66 (all `zzzz,zzz,zz9.99`) |

`l7-group` is exactly 80 bytes, so nothing is clipped. The 100 occurrences live
in `line-7-19`, which is 8,000 bytes long — only one occurrence is ever copied
into `print-record` per row.
