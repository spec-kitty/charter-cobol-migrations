# Disposition — `sl095` payment and journal proof report

`sl095` is the second half of menu `J`. It reads the file `sl090` has just
sorted (`open-item-file-s`), keys each payment back into the sales ledger, and
prints a *Payment* block and a *Journal* block, each with four totals, plus an
appropriation sub-line under every invoice that follows a payment for the same
customer.

The `oi-header` layout (114 B) is dispositioned in `disposition-sl055.md`; the
sales record (300 B) in `disposition-fdinv2.md`-adjacent notes and in the
`post` module. Offsets are zero-based. Ported in
`crates/acas-sales/src/payment_proof_report.rs`; evidence is
`docs/fd-evidence/F-B095-sl095-payment-proof-report.md`.

## Fields the program reads

| off | len | field | disposition |
|---|---|---|---|
| 0 | 7 | `oi-customer` | carried into `save-customer` and `l6-ac`; the sales read key. Sub-lines are gated on equality with it (Part 5) |
| 7 | 4 | `oi-invoice` | printed at `l6-invoice` on a sub-line only |
| 11 | 4 | `oi-date` | `zz060-Convert-Date` into `l6-date` / `l6-i-date` |
| 15 | 4 | `oi-b-nos` | `l6-b-nos`, `z(4)9 blank when zero` |
| 19 | 2 | `oi-b-item` | `l6-b-item`, `999b blank when zero` |
| 21 | 1 | `oi-type` | `2` = invoice branch, `5` payment, `6` journal, everything else skipped |
| 54 | 5 | `oi-approp` (= `oi-net`) | `l6-approp`, and the clamped source of `l6-i-approp` |
| 59 | 5 | `oi-extra` | `work-1` leg |
| 64 | 5 | `oi-carriage` | `work-1` leg |
| 69 | 5 | `oi-vat` | `work-1` leg |
| 74 | 5 | `oi-discount` | `work-1` leg |
| 79 | 5 | `oi-e-vat` | `work-1` leg |
| 84 | 5 | `oi-c-vat` | `work-1` leg |
| 89 | 5 | `oi-paid` | `l6-value`; the sub-line gate, the clamp source and the `work-1` subtraction |
| 94 | 1 | `oi-status` | `s-open` (`0`) tested on the payment path **only** |
| 96 | 4 | `oi-deduct-amt` | `l6-dedn` and a totals leg |
| 100 | 4 | `oi-deduct-vat` | `work-1` leg |

Not read anywhere in this program: `oi-description`, `oi-hold-flag`,
`oi-unapl`, `oi-p-c`, `oi-deduct-days`, `oi-days`, `oi-cr`, `oi-applied`,
`oi-date-cleared` — carried, never examined.

## Fields read from the sales record

| off | len | field | disposition |
|---|---|---|---|
| 0 | 7 | `sales-key` | the keyed read; a miss prints the literal (Part 7) |
| 7 | 30 | `sales-name` | `l6-name` (29 bytes — the last character of a 30-byte name never prints) |

Everything else in the 300-byte sales record is untouched.

## Print lines

| line | layout | disposition |
|---|---|---|
| `line-1` | version 1..48, title 49, `Page ` 125, `zz9` 130 | `l1-version` is `prog-name`; page 1 advances one line, later pages eject |
| `line-2` | `usera` 1..48, date 123..132 | date from `zz070-Convert-Date` of `to-day` |
| `line-4` | two 61/71 literals | verbatim, byte for byte |
| `line-5` | 22 blank, ` A/C               Name` at 23, the appropriation heading at 93 | verbatim |
| `line-6` | 132 bytes, columns per F-B095 Part 1 | the only row line; payment and sub-line share it and it is **not** cleared by `write` |
| `line-7` | 30 blank, `Payment`/`Journal` 31..37, ` Totals` 38..44 | reused for the journal block by a `move` |
| `line-8` | 30 blank, `**************` at 31 | verbatim, both blocks |
| `line-9` | 23 blank, `l9-desc` 24..40, `z(6)9.99` 41..50 | `cws-*` literals space-padded into 17 bytes; the value is unsigned (Part 3) |

## Controls

| element | disposition |
|---|---|
| `s-flag-p = 0` | `go to menu-exit` from `init01` — no open, no spool, no flag change |
| open-item open status ≠ 0 | `close`, `main-exit` — no spool; both flags were already raised |
| sales open | unchecked; a failure turns every row into `!! Customer Unknown` (unreachable through menu `J`) |
| `oi-type` 1/3/4/7/9 | fall through to `read-loop` |
| `not s-open` | payments only |
| keyed sales read, `invalid key` | literal printed, no flag, row still counts |
| `oi-paid = 0` or customer ≠ `save-customer` | sub-line skipped |
| `Oi-paid > sav-approp` | appropriation clamped to `sav-approp` |
| `line-cnt > page-lines` | `headings`, one row late (Part 4) |
| `line-cnt > page-lines - 8` | `headings` at `loop-end` |
| `oi-3-flag`, `s-flag-p` | set to `Y` / `2` by `init01` before any open |
