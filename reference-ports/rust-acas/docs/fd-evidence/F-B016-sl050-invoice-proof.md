# F-B016 — `sl050` invoice proof: the 133-byte row, the type numbering, and the EOF-status fossil

Verified 2026-11-03 against GnuCOBOL 3.1.2 (`/tmp/wpprobe/w16/w.cbl`) and
`cobol-original/sales/sl050.cbl`. Goldens: `fixtures/golden/sl050/{proof,busy}`,
captured by `harness/scenarios/sl050_proof.py` from `fixtures/sl050_proof_builder.py`.

`sl050` is menu `F` of `sales` (*Sales Transactions Proof*). It walks the
invoice file sequentially, prints a row for every unapplied, non-proforma
header plus one analysis row per line the header declares, and totals three
groups (receipts, invoices, credit notes) into a VAT reconciliation. It is
ported as `invoice_proof.rs`; the caller owns the reads.

## Part 1 — `line-5` is 133 bytes and the record clips its last byte

```
len4=132  len5=133  len8=66
```

`01 print-record pic x(132)`; `line-5` composes to one byte more (the trailing
sign byte of `l5-gross`). `write print-record from line-5` truncates, so a
**negative gross loses the `R` of its `CR`** and a positive one loses one of
its two sign spaces. The proof golden shows it on every credit-note row:

```
     3 28/10/2026 CUST011 Alpha Analytical Ltd          Cr. Note           40.00CR                  51.00CR      8.15CR     59.15C|
```

`line-4`, `line-8` and every analysis line fit and are unaffected.

## Part 2 — the type numbering is per-program

`sih-type` is read as `1` = **receipt**, `2` = invoice, `3` = credit note,
`4` = proforma. `sl055`'s `InvoiceType` calls `1` an *invoice* — the same byte
means different things to the two programs, and only `3` (credit note) and
`4` (proforma) agree. The proof prints `Receipt` for `1` and files it in
group 1; `4` is skipped outright, as is an applied header (`sapplied` = `z`/`Z`
in `sih-status` — the 88-level, so both cases).

## Part 3 — `at end` is status 10, and the program clobbers its own file status

`fs-reply` is the `FILE STATUS` field of both `sales-file` and `invoice-file`,
and the program also moves into it (`move zero to fs-Reply` before every
analysis, `move 99 to fs-Reply` at end of file). Measured on an instrumented
build: the first read past EOF answers `10` and takes the `at end` branch; every
read after that answers **`46`**, which is *not* `at end`. There is no
terminating condition on 46.

Consequence: a header that declares more lines than the file still holds ends
the analysis at EOF, and the outer loop then reads 46 forever. The loop body
still executes, but `sih-test` is taken from the stale record area, so if the
last record was a line the program spins with no output at all. `sl050`
therefore only terminates when the last record of the file is a header that
declares zero lines — which is why the proof fixture ends that way, and why the
`proof` golden is a finished report. An instrumented run of the fixture with a
trailing line spun for 50 s of CPU without writing another byte.

## Part 4 — an over-declared line count eats the next header

`perform analysis-print sih-lines times` reads straight through record
boundaries. When the count overruns, the next header is copied to
`invoice-line (1)` and interpreted at the *line* overlay's offsets: product
(bytes 10..22) becomes the customer number plus three date bytes, `sil-pa`
(bytes 23..24) becomes the last two bytes of `sih-order` (`DER` → `DE`),
`sil-net` reads the figure area, and the header is consumed — it never appears
as its own row and never reaches the totals. Golden:

```
     7 22/10/2026 ZZZZZZ  !! Customer Unknown           Invoice            99.99                    99.99        0.00       99.99 |
                                              Analysis    V3    Value        10.00    Vat Code 3                                    |
                                                          DE            2020202.02             0                                    |
```

## Part 5 — the missing-customer flag is sticky and never cleared

A failed keyed sales read sets `ws-error` to 1 (`88 sales-missing`). Nothing
resets it, so one unknown customer prints the closing
`Warning Record/s Missing In Sales File` line for the whole report. The name
column takes the literal `!! Customer Unknown`; the record area keeps the
*previous* customer's bytes, which the program never reads again.

## Part 6 — `l5-marker` is never moved

Five columns of `line-5` between the name and the type, blank on every row.

## Part 7 — `total-cvat` is indexed by the line's VAT code, not the header's

`add sil-vat (1) to total-cvat (a, k)` with `k` from `sil-vat-code`, so the
group axis comes from the header and the code axis from the line. A code of
zero adds nothing (the row still prints `Vat Code 0`); codes 1..5 accumulate.

The reconciliation row loop is `perform 3 times`, so only **codes 1..3 always
print** — not five. `4` and `5` are the local-tax pair: they are appended by a
second `perform 2 times` that runs only when `vat-rate (4)` or `vat-rate (5)`
is non-zero. The golden has every rate at zero, so it carries three rows; a
zero-rate `4`/`5` row is never written.

## Part 8 — the edits, measured

| field | picture | measured rendering |
|---|---|---|
| `l5-nos` | `z(7)9b` | nine bytes: eight digits, then the `b` blank |
| `l5-goods` … `l5-gross` | `z(6)9.99cr` | value in hundredths; `50000` → `50000.00`, `-12345` → `12345.00CR` |
| `l5-date` | `x(11)` | a ten-character date into eleven bytes |
| `l8-vat-rate` | `z9.99` | zero renders ` 0.00` |
| `l8-amount1..3` | `z(7)9.99cr` / `z(9)9.99cr` | integer digits aligned to the value, not to the source digits |

A `MOVE` into an edited field carries the *numeric value* with its implied
scale; it does not copy a digit string. That is why the port edits from
hundredths (`edit_masked`) rather than from field bytes.
