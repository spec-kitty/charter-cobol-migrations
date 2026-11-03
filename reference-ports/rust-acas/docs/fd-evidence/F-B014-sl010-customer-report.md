# F-B014 — sl010 menu 4, the customer listing

Measured 2026-11-03 against `sales/sl010.cbl` (3.01.20) on the harness build,
by driving the real menu and reading the bytes it wrote to `prt-1`. Every claim
below is either a golden byte range (`fixtures/golden/sl010/*`) or a probe
source named inline.

The program is entered at the sales menu with `B` (Customer File Maintenance),
then `4` (Print Customer records) at sl010's own menu. `init01` runs `slcreate`
unless `s-l-exists`, which is why the scenario seeds `sales-ledger = 'Y'`
(byte 560 of the system record, F-B011) — answering `Y` there would recreate and
so truncate the prepared tables.

## Part 1 — the layout of `line-6`

`line-6` is 135 bytes and the 132-byte spool record truncates the discount.

| field | 0-based bytes | width |
|---|---|---|
| `l6-key` | 0..10 | 10 |
| `l6-status` | 10..20 | 10 |
| `l6-name` | 20..70 | 50 |
| `l6-phone` | 70..88 | 18 |
| `l6-fax` | 88..101 | 13 |
| `filler` | 101..105 | 4 |
| `l6-charges` | 105..110 | 5 |
| `l6-letter` | 110..113 | 3 |
| `l6-limit` | 113..120 | 7 |
| `l6-credit` | 120..127 | 7 |
| `l6-discount` | 127..132 | 5 (of 5, cut at 132 of 135) |

## Part 2 — `B` insertion adds a blank *after* the character

`pic xb(4)` is 5 bytes, not 4 and not 8; `pic xbb` is 3. A value longer than one
character is lost entirely beyond its first byte.

Probe `/tmp/wpprobe/d.cbl`:

```
move "ABCD" to chg   →  "[A    ]"
move "Q"    to ltr   →  "[Q  ]"
```

`length of chg` = 5, `length of ltr` = 3 (`/tmp/wpprobe/c.cbl`). Golden line 6 of
`golden/sl010/all/prt-1` shows the same: `Y` at 105, blanks to 109, `Y` at 110,
blanks to 112 — so the `xb(4)` blank is *after* its character, and the letter
field starts at 110.

## Part 3 — the delivery-file record area is not cleared

The delivery record is zero-filled at program start, and an invalid `read` leaves
`deliv-address` exactly as it was.

* A first failed delivery read prints 96 NUL bytes as `l7-address`
  (`golden/sl010/credit-over-20/prt-1` line 12 — CUSTS40 carries a delivery tag
  but no record, and no earlier read ever succeeded).
* With an earlier successful read the block prints *that* record's text
  (`golden/sl010/all/prt-1` line 21 repeats CUSTS10's notes).
* The `inspect l7-address replacing all sl-delim by ","` is gated on
  `Deliv-Name not = "Record Not Found"`, so a stale line keeps its `\`.
* `notes-print`'s invalid branch *does* `move "Record Not Found" to
  deliv-Address`, and a COBOL `MOVE` space-fills the rest of the 96 bytes. The
  `string` therefore stops on the fill and prints `Notes: Record Not Found`
  only (line 25). This is the one place the buffer is overwritten.

## Part 4 — page mechanics

`page-lines` is 48 in the seeded system record (byte 22).

`headings` writes page 1 `before 1` on both heading lines and later pages
`after page` / `after 1` / a blank record / `after 1`; the blank record between
the heading and the column banner exists **only on an ejected page** because the
`write print-record after 1` sits inside the `if`. Consequence: a page-1 heading
block is eight lines (2 heading + blank + banner + units + blank = 6 written,
`line-cnt` reset to 6), and the continuation line after the form feed is
133..265 bytes long (`golden/sl010/all/prt-1` line 44).

`listing` calls `headings` twice — at its top when `line-cnt > page-lines`, and
again after the record is *built* when `line-cnt > page-lines - 5`. The second
break lands between the build and the write, so the customer row that triggered
it is not on the page its heading belongs to.

## Part 5 — the keyed start

`customer-in` is seven bytes; only six are typed, so `move customer-in to
sales-key` pads it with a space and `start ... key not < sales-key` can never hit
a real key exactly. The failed start still positions the file, so the following
`read next` yields the first key above the probe, and control falls straight into
`read-loop` — the record the start landed on is read *and* listed.

Then `inspect customer-in replacing all space by "Z"` turns the padded probe into
a stop condition that sorts after its own prefix: the run ends at the first key
greater than the `Z`-filled probe. Only the six typed positions are compared, so
a start past the end lists nothing but still prints page 1
(`golden/sl010/no-match/prt-1`).

## Part 6 — the heading

`report-heading-setup` starts its `string` pointer at `l3-report(1)` (`y` is zero
and the code adds 1 first), so the text is flush against `Report On : `.

`if status-in = spaces and credit-op and invoice-op and average-op and overdue-op
and customer-in` — a bare `pic x(7)` condition is true for an all-blank value in
GnuCOBOL, so a wholly empty selection reads `All`, not `Matched`
(`golden/sl010/all/prt-1` line 2). `customer-in` has content, which is the only
thing that segment prints anyway.

## Part 7 — the telephone

`string sales-phone delimited by "  " into l6-phone` then `subtract 1 from y`
then `string "x" sales-ext`. `sales-ext` is `pic x(4)`, so a 13-character
telephone loses its final digit to the `x` and the extension arrives with its
trailing blank: `0123456789012` + `417 ` prints `012345678901x417 `.

## Part 8 — the filters

Every band is `test-1` = the typed number, `test-2` = the record field, and the
operator is one of `L`/`G`/`E`. The overdue band compares `run-date -
sales-last-inv` and is gated on `sales-current > 0.00`: a balance that is zero or
credit is listed however few days it is overdue. `sales-current` and
`sales-last` are read but never printed — the listing has no balance column.

The entry-date band compares the validated day number against
`sales-create-date`, and `enter-date-in` is the only required field: blank sends
control to `main-end`, which is an `exit section` — the report still runs, only
the date validation is skipped.

## Part 9 — `l1-page`

`l1-page` is `pic zz9`, so pages print right-aligned with leading-zero
suppression. Page bytes of the golden: page 2 renders `  2` at 129..132.
