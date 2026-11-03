# F-B013 — sl070 product-analysis: p-a-setup table, report layout, page mechanics

**Program:** `sales/sl070.cbl` (3.01.11), 768 lines. The `report1` path reads
`analysis-file` and writes `print-file`; `p-a-setup` writes both `analysis-file`
and `value-file`. **Measured** on 2026-11-03 against the vendored source
compiled by GnuCOBOL 3.1.2 and driven through the real `ACAS` menu
(`harness/runs/20261103-124517-sl070-system`, `…-124654-sl070-all`).

**Why this note exists:** `pa_report.rs` types the analysis record, the value
record and the whole of `report1`. Every claim is either read out of the
copybook with a byte count or was observed in one of the two runs above.

## Part 1 — `WRITE ... FROM` pads with spaces, it does not reuse the record

`print-record` is `pic x(132)` (`fdprint.cob`). A `write print-record from
line-N` with `line-N` shorter than 132 bytes emits `line-N`'s own bytes and
**spaces** for the rest — the tail of the previous record is not preserved.

Probe (`/tmp/wpprobe/wf.cbl`): write `line-2` (b`abcdefDATE`, 10 bytes) into a
space-filled `print-record`; then `move "XY" to print-record (1:2)` and write
`line-2 (1:6)` again. Output:

```
b'abcdefDATE\nabcdef\n'
```

The second line is `abcdef` + spaces, not `XYcdef`. So every write in this
report is "sending bytes + spaces", and the `move spaces to print-record`
before the group-row write exists only because *that* write has no `FROM`.

## Part 2 — `p-a-setup` mints sixteen fixed codes, and always runs from the menu

`init01` performs `p-a-setup` whenever `file-status (15) = zero` (sl070:219),
i.e. on every cold entry — the menu always enters cold. It opens
`analysis-file` **output** (truncating whatever was there), opens `value-file`
input and creates it when missing, then writes this table, in this order:

| # | system | group | desc | print |
|---|---|---|---|---|
| 1 | `S` | `v ` | `VAT Control` | spaces |
| 2 | `P` | `v ` | (carried) | (carried) |
| 3 | `P` | `vi` | `VAT Input Invoices/CN's` | (spaces) |
| 4 | `P` | `vj` | `VAT Input Receipts` | (spaces) |
| 5 | `S` | `z ` | `Computer Control` | (spaces) |
| 6 | `P` | `z ` | (carried) | (spaces) |
| 7 | `P` | `za` | `Purchase Carriage Charges` | `P&P` |
| 8 | `P` | `zb` | `Purchase Late Charges` | `LCG` |
| 9 | `S` | `zc` | `Sales Carriage Charges` | `P&P` |
| 10 | `S` | `zd` | `Sales Late Charges` | `LCG` |
| 11 | `S` | `vo` | `VAT Output Invoices/CN's` | spaces |
| 12 | `S` | `vp` | `VAT Output Receipts` | (spaces) |
| 13 | `P` | `a ` | `Default Group` | (spaces) |
| 14 | `P` | `a1` | `Default Purchases` | (spaces) |
| 15 | `S` | `a ` | `Default Group` | (spaces) |
| 16 | `S` | `a1` | `Default Sales` | (spaces) |

Every row carries `pa-gl = 000000`. Descriptions longer than 24 characters are
truncated by the move (`Purchase Carriage Charges` → `Purchase Carriage
Charge`); check it in the observed `analysis.flat`, all sixteen records.

`create-value` runs **before** the analysis write for each row: it copies
`analysis-record` over `value-record`, zeroes the three `va-v-*` comp-3 fields,
writes `value-record` only when the value key is absent, and then writes the
analysis record. The three `va-t-*` comp fields are *not* zeroed — they are
zero here only because the working-storage `value-record` was fresh. A second
`p-a-setup` inside one run unit would carry them.

`p-a-setup` finishes with `move 1 to file-status (15)`, so the second and later
entries in the same process do not re-run it.

## Part 3 — the report is `report1`; its heading and row layouts

`line-1` is 80 bytes, `line-2` 80, `line-4` 69, `line-6` 69 — all shorter than
the 132-byte record, so all four are space-padded (Part 1).

`line-1` (80): `l1-version x(33)` (the 15-character `prog-name`, space-padded) ·
`x(39)` literal `Product Analysis Codes` · `x(5)` literal `Page ` ·
`l1-page pic zz9` at 77..79.

`line-2` (80): `l2-user x(30)` · `x(40)` spaces · `l2-date x(10)` at 71..80.
`usera` is `x(32)`, so a long user name is clipped to 30 by the move.

`line-4` (69): `l5-led-lit x(4)` (value `Lgr`, blanked before menu 3) ·
`x(59)` literal `Code    Gl.Nos.      <-----Description------>   Print` ·
`x(6)` literal `-Type-` at 64..69.

`line-6` (69), 0-based offsets — this is the row:

| offset | len | field |
|---|---|---|
| 0 | 1 | filler, space |
| 1 | 1 | `l6-ledger` |
| 2 | 3 | filler, spaces |
| 5 | 7 | `l6-code` — `pa-group` only (2 bytes) + 5 spaces |
| 12 | 6 | `l6-gl pic 9(6) blank when zero` |
| 18 | 7 | filler, spaces |
| 25 | 24 | `l6-desc` |
| 49 | 4 | filler, spaces |
| 53 | 3 | `l6-print` |
| 56 | 7 | filler, spaces |
| 63 | 6 | `l6-type` |

**The heading is one column left of the data** for the code and print columns
(`Code` starts at 0-based 4, the code at 5; `Print` starts at 52, the print
field at 53); the `Gl.Nos.` header and the GL field both start at 12. The
blank-record write for a group row leaves a wholly blank line — this is the
only place `print-record` is blanked.

## Part 4 — row selection, group rows, and the error flag

`read ... next` walks the file in key order; the key is `pa-code`, so the order
is system letter, group, i.e. all `P` codes, then all `S` codes.

- A row whose `pa-system` is not `S` is skipped unless the "print all" mode
  (`menu 4`) is selected.
- A row is a **group** when `pa-second = space` *and* `pa-gl = zero`. Groups get
  a preceding blank line and `l6-type = "Group"`; with "print all" they also
  put `pa-system` in `l6-ledger`. Everything else is `Detail` with a blank
  ledger.
- `ws-err-flag` is set by any **detail** row with `pa-gl = zero`; the report
  then ends with `Warning: One or more P.A. codes contain a zero value for
  General Ledger numbers` written `after 2`. Every `p-a-setup` code is a
  detail-with-zero except the three groups, so both scenarios end with it.
- `l6-gl` is `pa-gl / 100` (integer, truncating) unless `Irs-Used` (`Y` at
  system-record byte 407), in which case `pa-gl` is moved whole; the picture is
  `blank when zero`, so a zero prints six spaces.

## Part 5 — page mechanics

`headings` counts pages in `a`, writes `line-1` `BEFORE 1` on page 1 and
`AFTER PAGE` on page 2 and later, then a blank record `AFTER 1`, `line-2`
`AFTER 1`, and `line-4` `AFTER 2`; `line-cnt` is reset to 5. `line-cnt` is
checked against 70 both before and after the `line-6` write, so a break lands
with the row still on the old page and the row then re-printed after the
heading.

`zz070-Convert-Date` copies `to-day` through `Date-Form` (system record byte
335): `1` UK passes it through, `2` swaps day and month, `3` rewrites it as
`ccyy/mm/dd`, and **`Date-Form = zero is rewritten to 1 in the system record**.
Any other value falls through to the international branch.

> The page-2 branch is read from source (sl070:427-448); no fixture has 71
> codes, so it is not oracle-verified. Everything else above is measured.
