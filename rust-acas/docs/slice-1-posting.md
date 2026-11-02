# Slice 1: Sales Invoice Posting (sl055 extract half)

**Goal:** port `sales/sl055.cbl` to `acas-sales::posting::extract` (Rust) such that the
harness can feed the *same* invoice-file data to COBOL sl055 and Rust sl055 and observe
byte-identical `open-item-file-2` staging and `value-file` aftermath.

## Scope boundary (deliberate)

| In scope | Out of scope |
|---|---|
| sl055's header-extract into open-item-file-2 | sl060 GL posting half (phase 2 of slice 1) |
| per-line analysis updates (`va-t-this/va-v-this` etc.) | UI menus (sl000/sales.cbl caller) |
| the four "specials" Svo/vp/zc/zd counters | sl910 invoice *creation* |
| `il-update = "Z"` analysied flag semantics | multi-currency (ACAS is single-currency GBP) |

## Behavior inventory (L2R-001: characterization before porting)

Surface area sl055 exposes that we must preserve:

1. **Input contract**: sales invoice data in `invoice-file` (records keyed by `invoice-nos`,
   `invoice-let`; both headers (`item-nos=0`) and lines (`item-nos=N`) interleaved).
   Ledger-level system file must exist. `value-file`/`analysis-file` may be empty
   (created on fault).
2. **Sequential iteration** by `invoice-key`; **lines cached against their parent header**
   by key prefix match.
3. **Header skip rules**:
   - `ih-type = 4` (proforma) → skip silently
   - `pending or ih-status-L ≠ "L"` → skip + mark `ws-p-flag`
   - `ih-analyised and applied` → skip (rerun safety)
4. **Line skip rules**:
   - `il-analyised` → skip
   - `il-product(1:1) = "/"` → skip (comment-only lines)
5. **Analysis code resolution**: `va-code = "S" + il-pa` on VAT lines; special codes
   fixed strings `Svo`,`vp`,`zc`,`zd`. Falls back to `Emergency Name` pattern in
   `analysis-file` if code missing (that fallback IS observable behavior to keep —
   do not "fix" it).
6. **VAT line rule**: `il-type=3` (credit note) multiplies net by −1.
7. **Specials totals**: accumulated in COMP-3 (packed decimal) 9(7)v99 — i64 cents
   in Rust domain type.
8. **End-of-run marker**: `il-update = "Z"` written to every processed line/header,
   `ws-p-flag ≠ 0` + SL122 + user-prompt = "dirty exit"; otherwise clean exit.
9. **Idiom-fossil NOT preserved**: if unprinted invoices exist, sl055 still performs
   all the extract work and *then* bails with SL122. Rust version preflights and
   returns `Err(UnprintedInvoices { count })` *before* any writes — behavior at
   ledger level preserved; at temp-file level carefully not.
10. **Random access disk I/O** via `READ invoice-file NEXT RECORD` + `REWRITE` —
    in Rust this becomes staged `Vec<InvoiceRow>` mutation then one transactional
    write (see Architecture).

## Architecture

```
acas_sales::posting::extract
   invoice_rows: &[InvoiceRow]     <- loader reads invoice-file (fdinv2 format)
   analysis: &mut AnalysisTable    <- reads/updated value-file
   counters_out: SpecialsTotals
   oi2_out: &mut Vec<OpenItem2Rec> <- replace or append to openitm2
   returns Result<(), ExtractError>
                                  ExtractError = UnprintedInvoices | EmergAnalysisCreated | ...
```

Pure functional shape on in-memory data. **Storage is external** — ISAM decoder
(cobol file layout → `InvoiceRow`) lives in `acas-common` and is exercised
independently.

## Parity-harness shape

Harness stage for this slice:
```
/tmp/acas-harness-env/ACAS/invoice.dat      # hand-crafted fixture (header + lines)
/tmp/acas-harness-env/ACAS/analysis.dat     # fixture
/tmp/acas-harness-env/ACAS/value.dat        # fixture
run A: cobol-side sl055 (harness spawns via COB)
run B: rust-side acas-sales::posting::extract with binary-identical fixtures
assert: openitm2 + value-file + analysis-file hashes match
assert: screen message streams differ ONLY in the known-not-to-match "Y" trailing byte
```

## Estimated contract size

~300 LoC domain code, ~450 LoC test scaffolding. Roughly twice the complexity
per byte as the direct one-to-one port because we're implementing *both sides*
(COBOL adaptation + Rust domain) of the same observable contract.
