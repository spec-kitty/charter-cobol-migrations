//! PL055 — Invoice Post Extract (analysis pass), ported from COBOL.
//!
//! Pure domain kernel: takes in-memory invoice rows plus the analysis and
//! value tables, returns the updated tables, the rewritten invoice records and
//! the open-item-4 staging pl060 would consume. Storage lives outside.
//!
//! Byte layouts: `docs/fd-evidence/F-B055-pl055-invoice-and-oi4-records.md`.
//! Field dispositions: `docs/disposition-pl055.md`.
//!
//! ## The rules, in the order pl055 applies them
//!
//! Key order is `(invoice-nos, item-nos)`, so a header (item 0) precedes its
//! own lines.
//!
//! Line records (item != 0):
//! 1. `il-analyised` -> skip.
//! 2. key `"P" + il-pa`; ensure the value row (`create` / `create-anal`,
//!    "Emergency Name" fallback).
//! 3. `t-this += 1`, `t-year += 1`; `il-type = 3` subtracts `il-net`,
//!    otherwise it is added, to both `v-this` and `v-year`.
//! 4. when `va-second` is not space, the *group* row `"P" + first + space`
//!    gets the same update.
//! 5. `il-update = "z"`, rewrite.
//!
//! Header records (item = 0):
//! 6. `ih-analyised AND applied` -> skip the invoice.
//! 7. `extract`: stage the open-item-4 header and move the month counter
//!    (both skipped when already applied).
//! 8. `ih-analyised` -> rewrite and skip the *specials* totals. The month
//!    counter has already moved in step 7 — it lives inside `extract`.
//! 9. accumulate the three specials with the credit-note sign flip, then
//!    `ih-update = "z"`, `ih-status = "z"`, rewrite.
//!
//! There is no proforma check and no pending/printed check here — those are
//! sales-only. pl055 posts whatever it is handed.
//!
//! ## Departures and fossils
//!
//! - **The month counters are returned, not persisted.** They move inside
//!   `extract`, so an already-analysed invoice still counts even though its
//!   VAT/carriage/deduction legs are skipped (F-B055 Part 4). `ws-inv-amt` is an
//!   `add ... giving`, recomputed per header, and is built from the *unnegated*
//!   `ih-*` fields: a credit note adds a positive amount to
//!   `pl-credit-notes-this-month`, and a receipt contributes nothing at all
//!   because the whole `if ih-type not = 1` is skipped. Both carried.
//! - **The discount bucket is never sign-flipped.** `ih-deduct-amt` is unsigned
//!   `999v99`, so `multiply -1 by` is emitted for vat and carriage only. A
//!   credit note's deduction therefore counts positive in `Pzb`.
//! - **[`ExtractRun::finish`] writes all three buckets even when zero**, as
//!   ACAS does.
//! - The staged `oi-date-cleared` is zero and `oi-applied` is space; both stay
//!   on disk here (unlike sales, F-B055 Part 1), so a later reader sees them.
//!
//! ## Type mapping
//!
//! - counters (`va-t-*`, `9(5) comp`) -> `u32`, 4 big-endian bytes, mod 100000
//! - value sums (`va-v-*`, `s9(8)v99 comp-3`) -> `i64` hundredths, 6-byte
//!   packed with ACAS's silent high-digit truncation
//! - `va-code` -> `[u8; 3]`; `va-system` is always `b'P'`
//! - `oi-*` -> [`OpenItem4`], one field per F-B055 Part 3 offset

use std::collections::BTreeMap;

use crate::purchase_invoice::{
    HeaderStatus, InvoiceRow, OpenItem4, PackedMoney, PurchaseHeader, PurchaseLine,
    ANALYSIS_RECORD_BYTES, VALUE_RECORD_BYTES,
};

pub use crate::purchase_invoice::OPEN_ITEM4_RECORD_BYTES;

/// Hundredths. Same unit as [`PackedMoney::cents`].
pub type Money = i64;

/// Magnitude cap of `s9(8)v99`, in hundredths (ten integer digits).
const VALUE_MAX_CENTS: u64 = 10_000_000_000;
/// `9(5) comp` counter cap.
const COUNTER_MAX: u32 = 100_000;

/// Value-file key: `va-system` (`b'P'`) plus the two `il-pa` characters.
pub type ValueCode = [u8; 3];

impl ExtractRun {
    /// `ws-vat-*` / `ws-carr-*` / `ws-disc-*` bucket codes.
    const BUCKET_VAT: ValueCode = *b"Pvi";
    const BUCKET_VAT_RETURN: ValueCode = *b"Pvj";
    const BUCKET_CARRIAGE: ValueCode = *b"Pza";
    const BUCKET_DISCOUNT: ValueCode = *b"Pzb";
}

/// One row of the analysis file (`fdanal.cob`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AnalysisRow {
    pub code: ValueCode,
    /// `pa-gl` — `9(6)`, displayed digits on the wire.
    pub gl: [u8; 6],
    /// `pa-desc` — `x(24)`.
    pub desc: [u8; 24],
    /// `pa-print` — `xxx`.
    pub print: [u8; 3],
}

impl AnalysisRow {
    /// `create-anal` fallback description, spaces elsewhere.
    fn emergency(code: ValueCode) -> Self {
        let mut desc = [b' '; 24];
        desc[..14].copy_from_slice(b"Emergency Name");
        Self {
            code,
            gl: *b"000000",
            desc,
            print: [b' '; 3],
        }
    }

    pub fn to_bytes(&self) -> [u8; ANALYSIS_RECORD_BYTES] {
        let mut out = [b' '; ANALYSIS_RECORD_BYTES];
        out[0..3].copy_from_slice(&self.code);
        out[3..9].copy_from_slice(&self.gl);
        out[9..33].copy_from_slice(&self.desc);
        out[33..36].copy_from_slice(&self.print);
        out
    }

    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() != ANALYSIS_RECORD_BYTES {
            return None;
        }
        Some(Self {
            code: bytes[0..3].try_into().ok()?,
            gl: bytes[3..9].try_into().ok()?,
            desc: bytes[9..33].try_into().ok()?,
            print: bytes[33..36].try_into().ok()?,
        })
    }
}

/// One row of the value file (`fdval.cob`), 66 bytes on the wire.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValueRow {
    pub code: ValueCode,
    pub gl: [u8; 6],
    pub desc: [u8; 24],
    pub print: [u8; 3],
    /// `va-t-this`
    pub t_this: u32,
    /// `va-t-last` — zeroed by every create, never maintained by pl055.
    pub t_last: u32,
    /// `va-t-year`
    pub t_year: u32,
    /// `va-v-this`
    pub v_this: Money,
    /// `va-v-last` — zeroed by every create.
    pub v_last: Money,
    /// `va-v-year`
    pub v_year: Money,
}

impl ValueRow {
    fn from_analysis(analysis: &AnalysisRow) -> Self {
        Self {
            code: analysis.code,
            gl: analysis.gl,
            desc: analysis.desc,
            print: analysis.print,
            t_this: 0,
            t_last: 0,
            t_year: 0,
            v_this: 0,
            v_last: 0,
            v_year: 0,
        }
    }

    fn add_counter(&mut self) {
        self.t_this = (self.t_this + 1) % COUNTER_MAX;
        self.t_year = (self.t_year + 1) % COUNTER_MAX;
    }

    fn add_amount(&mut self, delta: Money) {
        self.v_this += delta;
        self.v_year += delta;
    }

    pub fn to_bytes(&self) -> [u8; VALUE_RECORD_BYTES] {
        let mut out = [0u8; VALUE_RECORD_BYTES];
        out[0..3].copy_from_slice(&self.code);
        out[3..9].copy_from_slice(&self.gl);
        out[9..33].copy_from_slice(&self.desc);
        out[33..36].copy_from_slice(&self.print);
        out[36..40].copy_from_slice(&self.t_this.to_be_bytes());
        out[40..44].copy_from_slice(&self.t_last.to_be_bytes());
        out[44..48].copy_from_slice(&self.t_year.to_be_bytes());
        out[48..54].copy_from_slice(&pack_long(self.v_this));
        out[54..60].copy_from_slice(&pack_long(self.v_last));
        out[60..66].copy_from_slice(&pack_long(self.v_year));
        out
    }

    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() != VALUE_RECORD_BYTES {
            return None;
        }
        Some(Self {
            code: bytes[0..3].try_into().ok()?,
            gl: bytes[3..9].try_into().ok()?,
            desc: bytes[9..33].try_into().ok()?,
            print: bytes[33..36].try_into().ok()?,
            t_this: u32::from_be_bytes(bytes[36..40].try_into().ok()?),
            t_last: u32::from_be_bytes(bytes[40..44].try_into().ok()?),
            t_year: u32::from_be_bytes(bytes[44..48].try_into().ok()?),
            v_this: unpack_long(bytes[48..54].try_into().ok()?),
            v_last: unpack_long(bytes[54..60].try_into().ok()?),
            v_year: unpack_long(bytes[60..66].try_into().ok()?),
        })
    }
}

fn pack_long(cents: Money) -> [u8; 6] {
    let magnitude = cents.unsigned_abs() % VALUE_MAX_CENTS;
    let formatted = format!("{magnitude:010}");
    let mut nibbles = [0u8; 10];
    for (slot, byte) in nibbles.iter_mut().zip(formatted.bytes()) {
        *slot = byte - b'0';
    }
    // Twelve nibbles: a clear pad, ten digits, the sign. The pad keeps the
    // field right-aligned to the byte boundary.
    let mut out = [0u8; 6];
    out[0] = nibbles[0];
    for pair in 0..4 {
        out[1 + pair] = (nibbles[1 + pair * 2] << 4) | nibbles[2 + pair * 2];
    }
    out[5] = (nibbles[9] << 4) | if cents < 0 { 0x0D } else { 0x0C };
    out
}

fn unpack_long(raw: [u8; 6]) -> Money {
    let mut magnitude: i64 = 0;
    for byte in raw {
        magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
    }
    // The low nibble of the last byte is the sign, not a digit.
    magnitude = (magnitude - i64::from(raw[5] & 0x0F)) / 10;
    if matches!(raw[5] & 0x0F, 0x0D | 0x0B) {
        -magnitude
    } else {
        magnitude
    }
}

/// The three specials pl055 accumulates (`ws-vat*`, `ws-carr*`, `ws-disc*`).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SpecialsTotals {
    pub n_vat: u32,
    pub vat: Money,
    pub n_vat_return: u32,
    pub vat_return: Money,
    pub n_carriage: u32,
    pub carriage: Money,
    pub n_discount: u32,
    pub discount: Money,
}

/// Carried state of one pl055 run.
#[derive(Debug, Clone)]
pub struct ExtractRun {
    pub analysis: BTreeMap<ValueCode, AnalysisRow>,
    pub values: BTreeMap<ValueCode, ValueRow>,
    pub specials: SpecialsTotals,
    /// Invoices that took the `extract` path.
    pub staged: Vec<OpenItem4>,
    /// Records pl055 rewrote, in read order.
    pub invoice_after: Vec<[u8; crate::purchase_invoice::ACAS_INVOICE_RECORD_BYTES]>,
    /// Set when a `create-anal` fallback fired (`Anal-Created`), which makes
    /// pl055 display PL201/PL202 and wait for a keypress.
    pub analysis_created: bool,
    /// `pl-invoices-this-month` delta.
    pub invoices_this_month: Money,
    /// `pl-credit-notes-this-month` delta.
    pub credit_notes_this_month: Money,
}

impl Default for ExtractRun {
    fn default() -> Self {
        Self::new()
    }
}

impl ExtractRun {
    pub fn new() -> Self {
        Self {
            analysis: BTreeMap::new(),
            values: BTreeMap::new(),
            specials: SpecialsTotals::default(),
            staged: vec![],
            invoice_after: vec![],
            analysis_created: false,
            invoices_this_month: 0,
            credit_notes_this_month: 0,
        }
    }

    /// Start from tables read off disk, so a run continues an existing file.
    pub fn with_tables(
        analysis: impl IntoIterator<Item = AnalysisRow>,
        values: impl IntoIterator<Item = ValueRow>,
    ) -> Self {
        let mut run = Self::new();
        for row in analysis {
            run.analysis.insert(row.code, row);
        }
        for row in values {
            run.values.insert(row.code, row);
        }
        run
    }

    /// `create` + `create-anal`: make a value row exist for `code`, minting
    /// the analysis row first when the code is unknown ("Emergency Name"
    /// fallback) and, when the second character is set, its group row.
    fn ensure_value(&mut self, code: ValueCode) {
        if self.values.contains_key(&code) {
            return;
        }
        let analysis = match self.analysis.get(&code) {
            Some(row) => row.clone(),
            None => {
                let primary = AnalysisRow::emergency(code);
                self.analysis.insert(code, primary.clone());
                self.analysis_created = true;
                if code[2] != b' ' {
                    let group = [b'P', code[1], b' '];
                    self.analysis
                        .entry(group)
                        .or_insert_with(|| AnalysisRow::emergency(group));
                }
                primary
            }
        };
        // `create` then writes the group row too — but with `write`, so a key
        // that already exists answers status 22 and keeps its counters. The
        // group row must therefore never be reset here.
        if code[2] != b' ' {
            let group = [b'P', code[1], b' '];
            let row = self.analysis.get(&group).cloned();
            if let Some(row) = row {
                self.values
                    .entry(group)
                    .or_insert_with(|| ValueRow::from_analysis(&row));
            }
        }
        self.values.insert(code, ValueRow::from_analysis(&analysis));
    }

    /// `store-specials`: bump one bucket and its group row.
    fn store_special(&mut self, code: ValueCode, count: u32, amount: Money) {
        for target in [code, [b'P', code[1], b' ']] {
            self.ensure_value(target);
            if let Some(row) = self.values.get_mut(&target) {
                row.t_this = (row.t_this + count) % COUNTER_MAX;
                row.t_year = (row.t_year + count) % COUNTER_MAX;
                row.add_amount(amount);
            }
        }
    }

    /// Line analysis, steps 1-5.
    fn analyse_line(&mut self, line: &mut PurchaseLine) {
        if line.analysed() {
            return;
        }
        let code = [b'P', line.pa[0], line.pa[1]];
        self.ensure_value(code);

        let delta = if line.is_credit() {
            -line.net.cents()
        } else {
            line.net.cents()
        };
        let mut targets = vec![code];
        if code[2] != b' ' {
            targets.push([b'P', line.pa[0], b' ']);
        }
        for target in targets {
            if let Some(row) = self.values.get_mut(&target) {
                row.add_counter();
                row.add_amount(delta);
            }
        }
        line.update = b'z';
    }

    /// `extract`: stage the open-item-4 header (no-op when already applied).
    fn stage_header(&mut self, header: &mut PurchaseHeader) {
        if header.status.is_applied() {
            return;
        }
        let mut item = OpenItem4 {
            supplier: header.supplier,
            invoice: header.invoice_nos.0,
            date: header.date.0,
            b_nos: 0,
            b_item: 0,
            invoice_type: header.invoice_type.0,
            reference: header.reference,
            order: header.order,
            hold_flag: b' ',
            unapl: 0,
            p_c: PackedMoney::ZERO,
            net: header.figures[1],
            extra: header.figures[2],
            carriage: header.figures[3],
            vat: header.figures[4],
            discount: header.figures[5],
            e_vat: header.figures[6],
            c_vat: header.figures[7],
            paid: PackedMoney::ZERO,
            status: b'0',
            deduct_days: header.deduct_days,
            deduct_amt: header.deduct_amt.hundredths() as i32,
            deduct_vat: header.deduct_vat.hundredths() as i32,
            days: header.days,
            cr: header.cr.0,
            applied: b' ',
            date_cleared: 0,
        };
        if header.invoice_type.is_credit() {
            item.negate();
        }
        self.staged.push(item);
        // The month counters live *inside* `extract`, before the open-item
        // write, so an `ih-analyised` header still moves them: header-analysis
        // only skips the *specials* block, and `extract` has already been
        // performed by then. An applied header never gets here at all.
        if !header.invoice_type.is_receipt() {
            let amount = ExtractRun::month_amount(header);
            if header.invoice_type.is_credit() {
                self.credit_notes_this_month += amount;
            } else if header.invoice_type.is_invoice() {
                self.invoices_this_month += amount;
            }
        }
        // `move "z" to ih-status` sits at the end of `extract`, before the
        // open-item write — so it is set even when the totals are skipped.
        header.status = HeaderStatus::Applied(b'z');
    }

    /// The header totals: VAT leg (c-vat + vat), carriage, deduction. Credit
    /// notes flip the first two only — `ih-deduct-amt` is unsigned.
    fn accumulate_specials(&mut self, header: &PurchaseHeader) {
        let credit = header.invoice_type.is_credit();
        let flip = |amount: Money| if credit { -amount } else { amount };

        let vat = flip(header.figures[7].cents() + header.figures[4].cents());
        if vat != 0 {
            if header.invoice_type.is_receipt() {
                self.specials.n_vat_return = (self.specials.n_vat_return + 1) % COUNTER_MAX;
                self.specials.vat_return += vat;
            } else {
                self.specials.n_vat = (self.specials.n_vat + 1) % COUNTER_MAX;
                self.specials.vat += vat;
            }
        }

        let carriage = flip(header.figures[3].cents());
        if carriage != 0 {
            self.specials.n_carriage = (self.specials.n_carriage + 1) % COUNTER_MAX;
            self.specials.carriage += carriage;
        }

        let deduct = header.deduct_amt.hundredths() as Money;
        if deduct != 0 {
            self.specials.n_discount = (self.specials.n_discount + 1) % COUNTER_MAX;
            self.specials.discount += deduct;
        }
    }

    /// `ws-inv-amt`: net + carriage + vat + c-vat from the *raw* invoice
    /// figures (never negated), only for non-receipts. Recomputed per header.
    fn month_amount(header: &PurchaseHeader) -> Money {
        header.figures[1].cents()
            + header.figures[3].cents()
            + header.figures[4].cents()
            + header.figures[7].cents()
    }

    /// `close-files`: write the four bucket rows — zero-valued or not.
    pub fn finish(&mut self) {
        let buckets: [([u8; 3], u32, Money); 4] = [
            (Self::BUCKET_VAT, self.specials.n_vat, self.specials.vat),
            (
                Self::BUCKET_VAT_RETURN,
                self.specials.n_vat_return,
                self.specials.vat_return,
            ),
            (
                Self::BUCKET_CARRIAGE,
                self.specials.n_carriage,
                self.specials.carriage,
            ),
            (
                Self::BUCKET_DISCOUNT,
                self.specials.n_discount,
                self.specials.discount,
            ),
        ];
        for (code, count, amount) in buckets {
            self.store_special(code, count, amount);
        }
    }

    /// Value rows in key order, as wire bytes.
    pub fn value_artifact(&self) -> Vec<u8> {
        self.values
            .values()
            .flat_map(|row| row.to_bytes())
            .collect()
    }

    /// Analysis rows in key order, as wire bytes.
    pub fn analysis_artifact(&self) -> Vec<u8> {
        self.analysis
            .values()
            .flat_map(|row| row.to_bytes())
            .collect()
    }

    /// Staged open-item-4 records, as wire bytes.
    pub fn item4_artifact(&self) -> Vec<u8> {
        self.staged.iter().flat_map(|row| row.to_bytes()).collect()
    }

    /// Rewritten invoice records, as wire bytes, in read order.
    pub fn invoice_artifact(&self) -> Vec<u8> {
        self.invoice_after.iter().flatten().copied().collect()
    }
}

/// Run the extract over `rows` in key order.
pub fn extract(run: &mut ExtractRun, rows: &[InvoiceRow]) {
    for row in rows {
        match row {
            InvoiceRow::Line(line) => {
                let mut line = line.clone();
                run.analyse_line(&mut line);
                // Skipped lines are still in the file; the artifact is the
                // whole stream in read order.
                run.invoice_after.push(line.to_bytes());
            }
            InvoiceRow::Header(header) => {
                let mut header = header.clone();
                if header.analysed() && header.status.is_applied() {
                    run.invoice_after.push(header.to_bytes());
                    continue;
                }
                run.stage_header(&mut header);
                if header.analysed() {
                    // `extract` ran, but `if ih-analyised` goes to the next
                    // record before the totals — the rewrite just re-emits it.
                    run.invoice_after.push(header.to_bytes());
                    continue;
                }
                run.accumulate_specials(&header);
                header.update = b'z';
                run.invoice_after.push(header.to_bytes());
            }
        }
    }
}
