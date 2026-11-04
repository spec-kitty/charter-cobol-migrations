# F-B050 — `pl050` invoice proof: the group-4 overrun, the two overlays, and the record order

Verified 2026-11-04 against GnuCOBOL 3.1.2 and `cobol-original/purchase/pl050.cbl`.
Goldens: `fixtures/golden/pl050/{proof,busy,empty}`, captured by
`harness/scenarios/pl050_proof.py` from `fixtures/pl050_proof_builder.py`.
Every case was captured twice with identical bytes before the goldens were
promoted.

`pl050` is menu `G` of `purchase` (*Invoice Proof Report*): the purchase mirror
of `sl050`. It walks the invoice file sequentially, prints one row per
unapplied header plus one analysis row per line the header declares, then
totals three groups into a VAT reconciliation.

Two differences from `sl050` are large enough that the sales port
(`invoice_proof.rs`) could not simply be re-pointed at the purchase records:

## Part 1 — the group index is the type byte, and type `4` falls off the table

`sl050` maps `1/2/3` to groups `1/2/3` and skips `4`. `pl050` does

```
move ih-type to a
```

so the type **is** the subscript, and there is no proforma skip. `total-group`
is `occurs 3`, and GnuCOBOL's default is no bounds checking, so a type-`4`
header indexes entry **four** — one past the table. The proof golden carries
two proformas and shows both consequences:

- they print, as `Cr. Note` (the `l5-type` branch is `1` → `Receipt`,
  `2` → `Invoice`, *else* → `Cr. Note`), with no sign flip (only `3` negates);
- their amounts never appear in the totals block, which is
  `perform total-report 3 times` over entries 1..3. Measured: goods totals
  `515.00 / 231.99 / 40.00CR`, while the two proformas' `77.00` and `5.00` are
  simply absent.

The out-of-range entry also writes over the working storage that follows the
table (`ws-deduct-amt`, `line-cnt`).

Measured with a `show-ded` trace compiled into the program (hex dump of the six
bytes at `ws-deduct-amt`, then `line-cnt`, then `a`), the proforma stores are:

| case | field before | `line-cnt` before | field after | `line-cnt` after |
|---|---|---|---|---|
| proforma 4, no deduction | `00 00 0C 13 30 30` | 19 | `00 00 12 13 30 3C` | 19 |
| proforma 41, 2.50 deduction | `00 25 0C 1E 30 30` | 30 | `00 25 12 24 55 3C` | 36 |

`total-ded (4)` is the first field of entry four, so it lands exactly on
`ws-deduct-amt`; the store is a six-byte packed amount, so it covers that field,
`line-cnt`, and the two bytes after it — which `tail-fill` mirrors from
`ih-invoice (1:2)`. The three-byte `ws-deduct-amt` keeps its sign nibble in the
middle of the wider field, where it is read as a digit of twelve and re-encoded
canonically: `00 00 0C` before a zero add comes back as `00 00 12`, and the
byte at `line-cnt` is the sixth digit pair of the sum. The rest of the row's
stores (`total-gds (4)` onward, and `total-cvat (4, 1..3)`) land inside the
`invoice-header` working storage, which is re-read from disk every record, so
they never reach a printed byte. A type past `4` is invisible for the same
reason.

In the proof fixture the resulting counters stay under `page-lines`, so no page
eject results; the trace read `19, 22, 25, 28, 30` at the row checks and `40`
after the loop, and the report matches the golden byte for byte.

## Part 2 — the line analysis reads a 12-byte product

`wspinv.cob`'s `invoice-line` declares `il-product pic x(12)`, but
`fdpinv2.cob`'s disk record is `x(13)`. `move invoice-record to invoice-line (1)`
copies by position, so the working-storage field that lands on disk bytes 21..23
is `il-pa` — the **13th product byte plus the first `pa` byte**. The fixture is
written to match (12-character product, then the 2-byte code), and the golden
shows the code column carrying `V1`, `V3`, `V2`.

Read against the disk offsets instead, the analysis code is
`record[21..23]` = `product[12]` and `pa[0]`. The `il-comment` test reads
`il-product (1)` = disk byte 9, which is the same byte both ways.

`go to main-exit` is a **section exit**, so it ends the current
`perform analysis-print` iteration and no more: the next declared line is still
read and printed. The proof fixture's invoice 7 declares two lines and its first
is `/COMMENT`, so the comment costs that invoice one row and its second line
still prints with the column labels untouched.

## Part 3 — `line-5` fits; there is no write-MOVE truncation

`line-5` composes to 128 bytes in the 132-byte `print-record`, so the sales
fossil (a 133-byte row losing the `R` of `CR`) does not exist here. Measured
row widths: 130 and 132 against a 132-byte record.

## Part 4 — the page check precedes the row, and the totals block always ejects

```
if       line-cnt > Page-Lines
         perform headings.
write    print-record  from  line-5 after 2  lines.
```

The check precedes the write, so the row whose counter already exceeded the
limit prints on the *new* page; because `main12` writes the heading with
`after page`, the form feed is appended to the last line of the page just
finished. `main-end` always calls `perform main12 in headings`, and
`main12` writes page 1 with `before 1` and every later page with `after page`.
`line-9` advances **5** lines, not the sales program's 2.

`main-end` calls `perform main12 in headings`. A paragraph `perform` stops at the
next paragraph header, so the closing page gets `main12` alone: no `cont-hds`
column banner, and `line-cnt` keeps the value the last row left, because only
`cont-hds` resets it to 5.

## Part 5 — the missing supplier is sticky and its literals are purchase-specific

A failed keyed read on `purchase-file` sets `ws-error` to 1
(`88 purchase-missing`); nothing clears it. The name column takes
`Supplier Unknown` (the sales program's literal is `!! Customer Unknown`) and
the closing warning reads `Warning: Record/s missing in Purchase File`. Both
appear in the proof golden, and `Print-Out` is set by the warning even when no
row was written.

## Part 6 — `at end`, status 46 and a file that ends in a header

Identical to F-B016 Part 3: the only tested exit is status 10 on the main
loop's read, and every read after that answers 46. An analysis that runs off
the end leaves the loop spinning, so the fixture ends with a header that
declares no lines.

## Part 7 — `l5-marker` is never moved, and the name is clipped by its field

Four blank columns between the name and the type on every row. `l5-name` is
`x(25)` while `purch-name` is thirty bytes, so the move stops at the field
boundary: a name longer than twenty-five characters loses its tail and the
four marker columns stay blank beneath it. (Writing all thirty would run into
the marker and then the type column; nothing in the fixture is over seventeen
characters, so the goldens cannot see the difference — pinned by
`a_thirty_byte_supplier_name_is_clipped_by_l5_name`.)

## Part 8 — `total-cvat` is indexed by the line's code and only 1..3 print

`add il-vat (1) to total-cvat (a, k)` takes the group from the header and the
code from the line; the reconciliation is `perform compute-vatcodes 3 times`,
so codes 4 and 5 never print even though `vat-rate (1..5)` exists.

## Part 9 — fixture facts the scenario depends on

- `ih-date` is a little-endian `binary-long` (F-B001). The first capture of
  these goldens was taken with a big-endian builder and printed garbage: blank
  dates, then `00/00/0000` once the byte-swapped value exceeded what
  `maps04` accepts. Both builders that share this record already wrote it
  little-endian; only this one did not.
- `pinvoice.dat` is INDEXED and `loadpinv` appends. A frame out of key order
  answers status 21 and is dropped **silently**, so the builder must sort by
  `(invoice, item)`. The first fixture left `41` in builder order and seven of
  its eighteen frames never reached the table (DP-028).
