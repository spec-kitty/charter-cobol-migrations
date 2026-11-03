# Disposition — sl010 menu 4 (`customer_report.rs`)

Two records reach this port: the 300-byte `sales-file` record it reads, and the
134-byte `delivery-file` record it reads for a customer's delivery address and
notes. Both are accounted for byte by byte below.

The create / amend / delete sections of the same program are **not** ported here
— they are screen accept loops and belong to WP12's screen layer.

Offsets are zero-based; a field's bytes are `offset .. offset + length`.

## `sales-file` (`fdsl.cob`, 300 bytes)

The full record is dispositioned for `sl170` in `disposition-sl170.md`, and that
ledger stays authoritative for the *type*. The table below records what *this*
report does with each field, which differs in several rows.

| offset | len | COBOL field | disposition in `customer_report.rs` | accessor |
|---|---|---|---|---|
| 0 | 7 | `sales-key` | printed (`l6-key`); the `start` probe and the `customer-in` stop test compare it byte-wise — the probe against `Z`, so only the six typed positions ever match | `key.0` |
| 7 | 30 | `sales-name` | printed (`l6-name`) | `name` |
| 37 | 96 | `sales-address.` (`addr1` + `addr2`) | printed as `l7-address`, `sl-delim` rewritten to `,` | `addr1` + `addr2` |
| 133 | 13 | `sales-phone` | printed into `l6-phone`, cut at the first double space | `phone` |
| 146 | 4 | `sales-ext` | when non-blank, appended after an `x` — and the appended string starts one byte *back*, overwriting the last telephone digit (F-B014 Part 7) | `ext` |
| 150 | 30 | `sales-email` | **not printed** — the listing has no email column | `email` |
| 180 | 13 | `sales-fax` | printed (`l6-fax`) | `fax` |
| 193 | 1 | `sales-status` | `= 1` prints `Active`, else `Dormant`; the `L`/`D` filter reads it | `status` |
| 194 | 1 | `sales-late` | `= 1` puts `Y` in `l6-charges`, else a blank | `late` |
| 195 | 1 | `sales-dunning` | `= 1` puts `Y` in `l6-letter`, else a blank | `dunning` |
| 196 | 1 | `email-invoice` | **not printed** | `email_invoice` |
| 197 | 1 | `email-statement` | **not printed** | `email_statement` |
| 198 | 1 | `email-letters` | **not printed** | `email_letters` |
| 199 | 1 | `delivery-tag` | `> zero` (blank counts as zero) triggers the delivery block | `delivery_tag` |
| 200 | 1 | `notes-tag` | `> zero` triggers the notes line | `notes_tag` |
| 201 | 3 | *filler* | never touched | — |
| 204 | 2 | `sales-credit` | **compared** (`credit-op`) and printed through a `zzz9bbb` edit that blanks a zero and a blank field | `credit` |
| 206 | 2 | `sales-discount` (`comp`) | printed as `z9.99`, blank when zero | `discount` |
| 208 | 2 | `sales-late-min` (`binary-short`) | **not printed** | `late_min` |
| 210 | 2 | `sales-late-max` (`binary-short`) | **not printed** | `late_max` |
| 212 | 4 | `sales-limit` (`binary-long`) | printed as `z(6)9`, blank when zero | `limit` |
| 216 | 4 | `sales-activety` (`binary-long`) | **compared** (`invoice-op`) | `activety` |
| 220 | 4 | `sales-last-inv` (`binary-long`) | operand of the overdue band (`run-date - sales-last-inv`); not printed | `last_inv` |
| 224 | 4 | `sales-last-pay` | **not printed** | `last_pay` |
| 228 | 4 | `sales-average` | **compared** (`average-op`) | `average` |
| 232 | 4 | `sales-pay-activety` | **not printed** | `pay_activety` |
| 236 | 4 | `sales-pay-average` | **not printed** | `pay_average` |
| 240 | 4 | `sales-pay-worst` | **not printed** | `pay_worst` |
| 244 | 4 | `sales-create-date` | **compared** by the entry-date band; not printed | `create_date` |
| 248 | 6 | `sales-current` (`comp-3`) | read only for the overdue gate (`> 0.00`); **not printed** | `current.cents()` |
| 254 | 6 | `sales-last` (`comp-3`) | **not printed** | `last` |
| 260 | 24 | `turnover-q1..q4` | **not printed** ×4 | `turnover` |
| 284 | 6 | `sales-unapplied` | **not printed** (and not subtracted — the balance never reaches the page) | `unapplied` |
| 290 | 10 | *filler* | never touched | `tail` |

## `delivery-file` (`fddel.cob`, 134 bytes)

| offset | len | COBOL field | disposition | accessor |
|---|---|---|---|---|
| 0 | 1 | `deliv-key-type` | `D` selects the delivery block, `N` the notes line; any other byte matches neither | `kind` |
| 1 | 7 | `deliv-sales-key` | the lookup key, compared whole against `sales-key` | `key` |
| 8 | 30 | `deliv-name` | printed as the block's name — or `Record Not Found`, which also suppresses the address `inspect` | `name` |
| 38 | 96 | `deliv-address` | delivery blocks print it as `l7-address`; notes lines print it after `Notes: `, cut at the first double space. Both are read through the shared FD buffer, so a failed read repeats the previous bytes (F-B014 Part 3) | `address` |

The delivery record is never written by this report.

## Notes

- A blank `pic 9` tag arrives as `0xF0` (`digit()` stores `byte - b'0'`), so the
  tag test is `!= 0 && != 0xF0 && != b'0'`, not a numeric `> 0`.
- `Record::put` clips at the record end, which is how `l6-discount` loses its
  last three bytes against the 135-byte `line-6`.
- The buffer shared by the two reads is a local of `run`, initialised to NULs:
  GnuCOBOL zeroes an untouched FD record and `move "Record Not Found"` only ever
  overwrites the notes path.
