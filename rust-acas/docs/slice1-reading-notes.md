# ACAS Sales→GL Posting — Slice 1 Reading Notes

**PBC (primary behavioral contract) sources:**
- `sales/sl055.cbl` — 587 lines, "INVOICE POST - EXTRACT ANALYSIS"
- `sales/sl060.cbl` — 1158 lines, downstream posting
- Copybooks read: `fdinv2.cob` (invoice header/lines), `fdsl.cob` (sales ledger cust), `fdanal.cob` (analysis codes), `fdval.cob` (GL analysis values), `fdoi2.cob` (open-item staging file)

**Copyright:** Vincent B. Coen FBCS, 1976–2013. CIS→Open COBOL conversion date 1983 in file header. This is a genuinely old program, carefully maintained.

## What sl055 does (the extract half)

Runs in batch. For each invoice physically authored but not yet "analysied":

1. Opens `invoice-file`, `value-file` (analysis values), `analysis-file`, and `open-item-file-2` (the `itm2` staging table handed to sl060).
2. Two-line flavor:
   - **Line records** (`ih-test ≠ 0`): posts **per-line analysis updates** into `value-file` — appetizes ACAS's per-product sales counts and VAT splits.
   - **Header records** (`ih-test = 0`): extracts the whole invoice header to `oi-header` and writes open-item-file-2 record (the actual handed-off payload).
3. Marks each invoice record `il-update = "Z"` (analysied); future runs skip it.
4. Maintains four running totals (gross VAT, VAT-return, carriage, discount) and stores them as **"specials"** in the analysis value file with codes `Svo/vp/zc/zd` (Sales voucher / VAT payable / carriage / discount).

## sl060 (the posting half — to be read next session)

Reads `open-item-file-2`, posts to:
- sales ledger customer balances (open-items + envelope balance)
- actual General Ledger via analysis codes from `fdval`

That's the deferred half of slice 1: port just sl055 first, feed its staging file to *live COBOL sl060* under the harness — strangler-fig parity at the ledger boundary. Then port sl060 against the same fixtures and drop the COBOL side entirely.

## Load-bearing copybook: `fdinv2.cob` (invoice file)

```cobol
fd  invoice-file.
01  invoice-record.
    03  invoice-key.
        05  invoice-nos    pic 9(8).
        05  invoice-let    pic x.
        05  item-nos       binary-char.            *> 0 = header rec, 1..n = lines
    03  invoice-customer   pic x(7).
    03  invoice-date       binary-long.            *> epoch-days; NOT a Y2K string
    03  filler             pic x(10).              *> dead bytes
    03  invoice-type       pic 9.                  *> 1=Inv 2=? 3=CrNote 4=Proforma
    ...                                            *> 129/134-byte record
```

Charter-relevant observations in this one FD:

- **Record-versioned 129→134-byte change 17/05/13** — fields accreted raw onto
  to the end, marked `filler` in the 2009 comment. Classic fossil.
- **`item-nos` does double duty.** `0` = this record IS the invoice header;
  `1..n` = line-items hanging under the same `invoice-nos` key. Rust shape:
  `enum InvoiceRow { Header(InvoiceHeader), Line(InvoiceLine) }`. Carried, NOT
  ported as a scalar with an 88-level swallow (88-level idiom = conditional
  name on same field — replaced with explicit type).
- **`invoice-date` is `binary-long` (=i32)** holding *days since 1900-01-01*,
  not a packed date string. Rust: `time::Date` via a `days-since-1900` newtype.
  Carried with a wrapper, behavior-preserving.
- **line-vs-header dispatch happens on file, not in memory** — never optimize
  to "records are well-formed"; ACAS means to exploit file-I/O as its own
  conditional dispatch.

## The four VAT/discount/carriage counters (da040-Close-Files):

| Displayed | Key used | Counter |
|---|---|---|
| `Svo` | "Sales voucher" net VAT total for run | ws-vat-totalv |
| `vp`  | VAT payable VAT-return subtotal | ws-vatr-totalv |
| `zc`  | carriage | ws-carr-totalv |
| `zd`  | discount | ws-disc-totalv |

These are written into `analysis-file`/`value-file` keyed by va-code.
**Charter-class:** open-coded classification codes — idiom. Will become a
`SpecialCounterKind` enum in Rust (absorbed).

## Two idiom-fossils already noted for the pack:

1. **`ws-p-flag` set only if any invoice has `pending`/`ih-status-L ≠ "L"`, then
  SL122 ("Unprinted Invoices Exist") reported at end.** Idiom: late-fail-after-
  work-done. In Rust: pre-flight validation that returns `Err(UnprintedInvoices
  {count})`. Behavior preserved; the WORK (half-finished file state) is
  deliberately not preserved. L2R-003 in action.
2. **`File-Status (15)` array indexing.** Calls check specific array slots by
  bare number. Rust: enum `FileStatusSlot::InvoiceUpdated = 14` (0-indexed).
  Carried with explicit typing. 88-level idioms on same slot → enum.
