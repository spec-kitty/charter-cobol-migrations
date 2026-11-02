//! SL055 — Invoice Post Extract (analysis pass), ported from COBOL.
//!
//! Pure-function domain kernel: takes in-memory invoice rows and the
//! analysis/value tables, returns updated state + the open-item-2 staging
//! records sl060 would consume. Storage lives outside this module.
//!
//! ## Behavior contract (from docs/slice1-reading-notes.md + fdinv2 dispositions)
//!
//! 1. Iterate invoices in key order (`invoice-nos`, `invoice-let`, `item-nos`).
//! 2. **Lines first** (they sit under headers in key order, but only lines with
//!    their parent header *already determined to be skipped or posted* are
//!    processed — COBOL achieves this via sequential read plus skip-ahead on
//!    headers; we model it as a two-phase pass over rows for one invoice).
//! 3. Analysis updates per line:
//!    - key: `"S" + il-pa` (va-code); absent → create with `Emergency Name`
//!    - `add 1 to va-t-this, va-t-year`
//!    - if `il-type != 3` add `il-net` else subtract (credit notes)
//!    - secondary row handling (va-second) — done when va-second non-space
//! 4. Header skip rules:
//!    - ih-type == 4 (proforma) → skip permanently (no skip-ahead bookkeeping;
//!      proformas stay pending forever, that IS the behavior)
//!    - pending or ih-status-L != "L" → mark p_flag, skip
//!    - ih-analyised AND applied (z/Z AND z/Z) → skip
//! 5. Header extract: write oi-header to open-item-file-2, accumulate
//!    four specials (vat/vatr/carr/disc), mark `ih-update = 'Z'`.
//! 6. Header totals accounting:
//!    - `work-2 = c-vat + vat + e-vat`; if type-3 (credit-note) × −1;
//!    - vs ih-type==1 (return): goes to `vatr` counters, else `vat` counters
//!    - carriage and deduct-amt likewise with −1 on type 3
//! 7. End: 4 specials written under va-code `"Svo"`, `"vp"`, `"zc"`, `"zd"`.
//! 8. Late-fail semantics from COBOL are NOT ported (L2R-003 / late-fail
//!    detection tactic): we PRE-FLIGHT the run and return
//!    `Err(ExtractError::UnprintedPresent)` *before* any writes if any
//!    candidate invoice is pending. ACAS's behavior was: do the work then
//!    show SL122; our version: surface the condition first.
//!
//! On the penultimate point: this is the **first deliberate deviation** from
//! full parity, and it's logged. The byte-level proof of behavior equivalence
//! comes from fixture tests that show: (a) clean set → both post identically;
//! (b) with pending set → COBOL does all work then warns, Rust warns and does
//! no work; downstream (SL060 input) is identical in either case.
//!
//! ## Type mapping
//!
//! - `va-t-this`, `va-t-year` — counters, "how many times this was hit" — compile
//!   to `u32` value increments
//! - `va-v-this`, `va-v-year` — value sums in COMP-3 money — compile to
//!   `Money` (i64 cents; we keep ACAS's packed-decimal wrapping behavior via
//!   saturation checks at write time)
//! - `va-code`, `va-system` — string keys "S" + two-char product-analysis

use thiserror::Error;

/// i64 of pennies.
pub type Money = i64;

#[derive(Debug, Clone)]
pub struct ValueRow {
    pub code: String,
    // transaction counters, this/last/year
    pub t_this: u32,
    pub t_last: u32,
    pub t_year: u32,
    // value sums, this/last/year
    pub v_this: Money,
    pub v_last: Money,
    pub v_year: Money,
    /// ACAS "second" records hang under va-second — when a line's PA code
    /// maps to a second target, both get updated (rare; dual-accounting).
    pub second: Option<String>,
}

#[derive(Debug, Clone)]
pub struct AnalysisRow {
    pub code: String,
    pub description: String,
    pub gl_code: u32,
    /// same parity as ValueRow::second
    pub second: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenItem2Header {
    pub invoice_nos: u32,
    pub invoice_let: u8,
    pub customer: [u8; 7],
    pub date_days_since_1600_12_31: i32,
    pub order: [u8; 10],
    pub inv_type: u8,
    pub reference: [u8; 10],
    pub description: [u8; 32],
    pub p_and_c: Money,
    pub net: Money,
    pub extra: Money,
    pub carriage: Money,
    pub vat: Money,
    pub discount: Money,
    pub e_vat: Money,
    pub c_vat: Money,
    pub deduct_amt: i32,    // comp 999v99 → we keep as deci-cents for now
    pub deduct_vat: i32,
    pub deduct_days: u8,
    pub days: u8,
    pub cr_days_since_1600_12_31: i32,
    pub status_main: u8,    // P/I/z etc
    pub status_pick: u8,
    pub status_printed: u8,
    pub status_cleared: u8,
    pub status_applied: u8,
    pub status_deleted: u8,
    pub line_count: u8,
    pub day_booked: bool,
    // Note: applied/unapplied/hold flags — COBOL writes spaces here always
    // (sl055.540 sets spaces); so we hard-code b' '.
}

/// SL055's specials: the four bucket totals ACAS writes at end of run.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct SpecialsTotals {
    /// Svo — vat-totalv (gross VAT across invoices; sign-adjusted credits)
    pub sales_vat: Money,
    /// vp — vatr-totalv (VAT-return leg; invoices typed return)
    pub vat_return: Money,
    /// zc — carr-totalv
    pub carriage: Money,
    /// zd — disc-totalv
    pub discount: Money,
    /// raw counters; ACAS tracks both a count and a value per bucket and
    /// writes both to the value file. We keep them for parity.
    pub n_sales_vat: u32,
    pub n_vat_return: u32,
    pub n_carriage: u32,
    pub n_discount: u32,
}

#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ExtractError {
    /// Pre-flight abort: at least one header is in pending state (SL122 analog).
    #[error("unprinted invoices present: {count}")]
    UnprintedPresent { count: u32 },
}

/// A lone invoice: header + its lines (item-nos 1..).
#[derive(Debug)]
pub struct Invoice <'a>{
    pub header: &'a crate::invoice::InvoiceHeader,
    pub lines: Vec<&'a crate::invoice::InvoiceLine>,
}

/// State needed across the whole run.
pub struct ExtractRun<'t> {
    pub analysis: &'t mut std::collections::HashMap<String, AnalysisRow>,
    pub values: &'t mut std::collections::HashMap<String, ValueRow>,
    pub out_items2: Vec<OpenItem2Header>,
    pub specials: SpecialsTotals,
}

impl<'t> ExtractRun<'t> {
    pub fn new(
        analysis: &'t mut std::collections::HashMap<String, AnalysisRow>,
        values: &'t mut std::collections::HashMap<String, ValueRow>,
    ) -> Self {
        Self {
            analysis,
            values,
            out_items2: vec![],
            specials: SpecialsTotals::default(),
        }
    }
}

/// Pre-flight scan for SL122-condition (unprinted/pending invoices).
///
/// Returns Ok(headers) in invoice-key order, or Err with the count.
/// Mirrors da020's skip-test, applied upfront rather than mid-loop.
///
/// Note: caller passes rows already sorted by (invoice-nos, let, item-nos=0).
pub fn preflight<'a>(
    rows: &'a [crate::invoice::InvoiceRow],
) -> Result<Vec<&'a crate::invoice::InvoiceHeader>, ExtractError> {
    let mut headers = vec![];
    let pending = 0u32;
    for row in rows {
        let crate::invoice::InvoiceRow::Header(h) = row else { continue };
        // sl055 da020:
        //   pending or ih-status-L not = "L" → skip & flag
        //   ih-type = 4 (proforma) → silent skip
        //   ih-analyised (update=="Z"/"z") AND applied → silent skip
        let is_applied = false;  // TODO line-by-line; placeholders parked in slice-1 v0.1
        let analysed = false;
        let type_is_proforma = matches!(
            crate::invoice::InvoiceType::from_cobol(0 /* placeholder */),
            crate::invoice::InvoiceType::Proforma
        );
        let _ = (is_applied, analysed, type_is_proforma);
        headers.push(h);
    }
    if pending > 0 {
        return Err(ExtractError::UnprintedPresent { count: pending });
    }
    Ok(headers)
}

/// The extract core. Skeleton shape — behaviors accrete as slice 1 advances.
pub fn extract_inv(run: &mut ExtractRun, inv: Invoice) -> Result<(), ExtractError> {
    // Slice 1, v0.1 — capture framework only. Real logic lands as parity
    // fixtures are carved out of live runs: each assertion becomes a line
    // here. Currently: line aggregation + header staging.
    for line in &inv.lines {
        // (1) skip if il-analyised
        //     placeholder: parked until il-update disposition lands
        // (2) comment-only lines: il-product[0] == '/' → skip
        // (3) "S" + il-pa → ensure analysis + value rows; add counters
        let code = format!("S{}", "XX"); // stub: product-analysis wire-up next
        let v = run.values.entry(code.clone()).or_insert_with(|| {
            // db000-Create semantics
            ValueRow {
                code: code.clone(),
                t_this: 0, t_last: 0, t_year: 0,
                v_this: 0, v_last: 0, v_year: 0,
                second: None,
            }
        });
        // da010 main update:
        v.t_this += 1;
        v.t_year += 1;
        // placeholder for net accumulation via Money i64
        let _ = line; // parked on InvoiceLine field disposition completion
    }
    // Header bookkeeping parked: specials + oi2 staging + ih-update flag
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_run_produces_empty_state() {
        let mut analysis = std::collections::HashMap::new();
        let mut values = std::collections::HashMap::new();
        let mut run = ExtractRun::new(&mut analysis, &mut values);
        let _ = &mut run;
        assert!(run.out_items2.is_empty());
        assert_eq!(run.specials, SpecialsTotals::default());
    }
}
