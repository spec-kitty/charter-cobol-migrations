# Disposition — sl170 reads of `sales-file` (`fdsl.cob`)

`sl170` is read-only over the 300-byte sales record: it filters on four numeric
fields, one status byte and the key, and prints forty of the record's bytes as
text. This ledger accounts for **every byte of the record** as `sl170` uses it,
so nothing is printed, compared or dropped by accident.

Offsets are zero-based; a field's bytes are `offset .. offset + length`. The
`SalesRow` accessor column names the typed field in
`crates/acas-sales/src/post.rs` (WP05's ledger typed the whole record; `sl170`
consumes it and adds nothing).

| offset | len | COBOL field | disposition in `file_dump.rs` | accessor |
|---|---|---|---|---|
| 0 | 7 | `sales-key` | printed (`l4-value-1`) and compared byte-wise against the `Z`-padded probe, six positions only | `key.0` |
| 7 | 30 | `sales-name` | printed | `name` |
| 37 | 48 | `sales-addr1` | printed | `addr1` |
| 85 | 48 | `sales-addr2` | printed | `addr2` |
| 133 | 13 | `sales-phone` | printed | `phone` |
| 146 | 4 | `sales-ext` | **not printed** by any `listing` line | `ext` |
| 150 | 30 | `sales-email` | printed up to the first space, only when non-blank, in the email line | `email` |
| 180 | 13 | `sales-fax` | **not printed** | `fax` |
| 193 | 1 | `sales-status` | `= 1` prints `Live`, else `Dead`; `status-in` `L`/`D` filters on it | `status` |
| 194 | 1 | `sales-late` | `= 1` prints `Yes`, else `No` | `late` |
| 195 | 1 | `sales-dunning` | `= 1` prints `Yes`, else `No` | `dunning` |
| 196 | 1 | `email-invoice` | drives the `Used by` legend | `email_invoice` |
| 197 | 1 | `email-statement` | drives the `Used by` legend | `email_statement` |
| 198 | 1 | `email-letters` | drives the `Used by` legend (printed as `Dunning`) | `email_letters` |
| 199 | 1 | `delivery-tag` | printed as one character; a blank record prints a space | `delivery_tag` |
| 200 | 1 | `notes-tag` | printed as one character | `notes_tag` |
| 201 | 3 | *filler* | cleared (`l4-name-2` + the value-2 redefine are moved spaces) | — |
| 204 | 2 | `sales-credit` | **compared** (`credit-op` band) and printed through the blank-preserving money edit | `credit` |
| 206 | 2 | `sales-discount` (`comp`) | printed (two decimals, `binary-short`) | `discount` |
| 208 | 2 | `sales-late-min` (`binary-short`) | printed | `late_min` |
| 210 | 2 | `sales-late-max` (`binary-short`) | printed | `late_max` |
| 212 | 4 | `sales-limit` (`binary-long`) | printed | `limit` |
| 216 | 4 | `sales-activety` (`binary-long`) | **compared** (`invoice-op` band) and printed | `activety` |
| 220 | 4 | `sales-last-inv` (`binary-long`) | converted through `maps04` and printed as a date; also the overdue operand | `last_inv` |
| 224 | 4 | `sales-last-pay` (`binary-long`) | converted and printed | `last_pay` |
| 228 | 4 | `sales-average` (`binary-long`) | **compared** (`average-op` band) and printed | `average` |
| 232 | 4 | `sales-pay-activety` | **not printed** | `pay_activety` |
| 236 | 4 | `sales-pay-average` | **not printed** | `pay_average` |
| 240 | 4 | `sales-pay-worst` | **not printed** | `pay_worst` |
| 244 | 4 | `sales-create-date` | **not printed** | `create_date` |
| 248 | 6 | `sales-current` (`comp-3`) | gate for the overdue band (`> 0.00`) and printed after `sales-unapplied` is subtracted from it in place | `current` |
| 254 | 6 | `sales-last` (`comp-3`) | printed | `last` |
| 260 | 24 | `turnover-q1..q4` (`comp-3` ×4) | each printed against the Turnover-Q column | `turnover[0..4]` |
| 284 | 6 | `sales-unapplied` (`comp-3`) | subtracted from `sales-current` before that field is printed | `unapplied` |
| 290 | 10 | *filler* | never touched | `tail` |

## Notes

- `sales-current` is modified in the record buffer by `listing`
  (`subtract sales-unapplied from sales-current`), so the printed balance is not
  the stored one. Nothing writes the record back, so the change dies with the
  run.
- The four blank-tracked fields (`delivery-tag`, `notes-tag`, `sales-credit`,
  `sales-current`) all use the "GnuCOBOL does not turn a blank into a zero"
  rules measured in F-B012 Parts 3 and 5.
- Fields marked *not printed* are still typed by `post.rs` for the other sales
  programs; this ledger records that `sl170` itself ignores them, which is the
  reason a grep for them in `file_dump.rs` comes back empty.
