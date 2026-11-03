//! SL055 — Invoice Post Extract (analysis pass), ported from COBOL.
//!
//! Pure domain kernel: takes in-memory invoice rows plus the analysis and
//! value tables, returns the updated tables and the open-item-2 staging
//! records sl060 would consume. Storage lives outside this module.
//!
//! Byte layouts for both output records are documented in
//! `docs/fd-evidence/F-B007-sl055-output-records.md` (measured off GnuCOBOL
//! writes through ACAS's own `value-record` / `oi-header` overlays).
//!
//! ## The rules, in the order sl055 applies them
//!
//! Key order is `(invoice-nos, invoice-let, item-nos)`, so a header (item 0)
//! is read before its own lines.
//!
//! Line records (`item-nos != 0`):
//! 1. `il-analyised` -> skip.
//! 2. `il-product(1:1) = "/"` -> comment line, skip.
//! 3. key = `"S" + il-pa`; ensure the analysis row, then the value row
//!    (`db000-Create` / `db010-Create-Anal`, "Emergency Name" fallback).
//! 4. `t-this += 1`, `t-year += 1`.
//! 5. `il-type = 3` -> subtract `il-net`, otherwise add it, to both `v-this`
//!    and `v-year`.
//! 6. when the code has a non-space second character, the *group* row
//!    `"S" + first + space` gets the same update.
//!
//! Header records (`item-nos = 0`):
//! 7. `ih-analyised AND applied` -> skip the invoice.
//! 8. `ih-type = 4` (proforma) -> skip the invoice.
//! 9. pending, or `ih-status-L` not `L` -> flag the run, skip the invoice.
//! 10. `dd000-Extract`: stage the open-item-2 header (skipped when already
//!     applied), mark applied, then accumulate the four specials with the
//!     credit-note sign flip.
//!
//! Skipping an invoice skips the rest of it: COBOL does this with a `START`
//! on `(invoice-nos + 1, space, 0)`, modelled here as "ignore the remaining
//! rows of this invoice".
//!
//! ## The deliberate departure (L2R-003)
//!
//! COBOL does the whole run and *then* warns SL122 if any invoice was
//! unprinted. The Rust caller wants the condition before it commits file
//! state, so [`preflight`] reports it up front. The computed work is
//! nevertheless identical — COBOL has already written it by the time it
//! warns — so the artifacts still match; [`extract`] returns the unprinted
//! count alongside the work it did.
//!
//! ## The read-buffer fossil (observed, F-B008)
//!
//! `ih-update` sits at byte 136 of a 137-byte overlay on a 134-byte record
//! (F-B006), so it is never written back. GnuCOBOL still reads each record
//! into the *same* 137-byte buffer, which means bytes 134-136 keep the
//! previous record's content: once one header has posted, the buffer's
//! `ih-update` is `"Z"` and every later header in the batch looks already
//! analysed. COBOL takes its `if ih-analyised` early exit after `dd000`, so
//! later invoices still stage their open-item record but never reach the
//! totals. [`ExtractRun::buffer_update`] carries that byte.
//!
//! ## Type mapping
//!
//! - counters (`va-t-*`, `9(5) comp`) -> `u32`, big-endian 4 bytes on the wire
//! - value sums (`va-v-*`, `s9(8)v99 comp-3`) -> `i64` hundredths, 6-byte
//!   packed on the wire with ACAS's silent high-digit truncation
//! - `va-code` -> `[u8; 3]`; `va-system` is always `b'S'`
//! - `oi-*` -> [`OpenItem2`], one field per F-B007 offset

use std::collections::BTreeMap;

use crate::invoice::{
    CustomerKey, HeaderStatus, InvoiceHeader, InvoiceLine, InvoiceNumber, InvoiceRow, InvoiceType,

};

/// `fdval.cob` — the value record is 66 bytes.
pub const VALUE_RECORD_BYTES: usize = 66;
/// `fdanal.cob` — the analysis record is 36 bytes.
pub const ANALYSIS_RECORD_BYTES: usize = 36;
/// `fdoi2.cob` — the open-item-2 record is 114 bytes.
pub const OPEN_ITEM2_RECORD_BYTES: usize = 114;

/// Hundredths. Same unit as [`PackedMoney::cents`].
pub type Money = i64;

/// Magnitude cap of `s9(8)v99`, in hundredths (ten integer digits).
const VALUE_MAX_CENTS: u64 = 10_000_000_000;
/// `9(5) comp` counter cap.
const COUNTER_MAX: u32 = 100_000;

/// Value-file key: `va-system` (`b'S'`) plus the two `il-pa` characters.
pub type ValueCode = [u8; 3];

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
    /// `db010-Create-Anal` fallback description.
    fn emergency(code: ValueCode) -> Self {
        let mut desc = [b' '; 24];
        desc[..14].copy_from_slice(b"Emergency Name");
        Self { code, gl: *b"000000", desc, print: [b' '; 3] }
    }

    pub fn to_bytes(&self) -> [u8; ANALYSIS_RECORD_BYTES] {
        let mut out = [b' '; ANALYSIS_RECORD_BYTES];
        out[0..3].copy_from_slice(&self.code);
        out[3..9].copy_from_slice(&self.gl);
        out[9..33].copy_from_slice(&self.desc);
        out[33..36].copy_from_slice(&self.print);
        out
    }

    pub fn from_bytes(b: &[u8]) -> Option<Self> {
        if b.len() != ANALYSIS_RECORD_BYTES {
            return None;
        }
        Some(Self {
            code: b[0..3].try_into().ok()?,
            gl: b[3..9].try_into().ok()?,
            desc: b[9..33].try_into().ok()?,
            print: b[33..36].try_into().ok()?,
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
    /// `va-t-last` — zeroed by every create, never maintained by sl055.
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

    pub fn from_bytes(b: &[u8]) -> Option<Self> {
        if b.len() != VALUE_RECORD_BYTES {
            return None;
        }
        Some(Self {
            code: b[0..3].try_into().ok()?,
            gl: b[3..9].try_into().ok()?,
            desc: b[9..33].try_into().ok()?,
            print: b[33..36].try_into().ok()?,
            t_this: u32::from_be_bytes(b[36..40].try_into().ok()?),
            t_last: u32::from_be_bytes(b[40..44].try_into().ok()?),
            t_year: u32::from_be_bytes(b[44..48].try_into().ok()?),
            v_this: unpack_long(b[48..54].try_into().ok()?),
            v_last: unpack_long(b[54..60].try_into().ok()?),
            v_year: unpack_long(b[60..66].try_into().ok()?),
        })
    }
}

/// `s9(8)v99 comp-3`: ten digits plus a sign nibble, padded into twelve
/// nibbles. Values past ten digits lose their high digits — ACAS does not
/// check, so neither do we.
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
    if matches!(raw[5] & 0x0F, 0x0D | 0x0B) { -magnitude } else { magnitude }
}

/// The open-item-2 header handed to sl060 (F-B007).
///
/// The overlay is exactly 114 bytes, so every field reaches disk — including
/// `oi-applied` and `oi-date-cleared`, which sl055 always writes as space/zero.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenItem2 {
    pub customer: CustomerKey,
    pub invoice: InvoiceNumber,
    pub date: i32,
    /// `oi-type` — digit character.
    pub invoice_type: u8,
    /// `oi-description`, `ih-order` space-padded to 25.
    pub description: [u8; 25],
    pub hold_flag: u8,
    pub unapl: u8,
    pub p_c: Money,
    pub net: Money,
    pub extra: Money,
    pub carriage: Money,
    pub vat: Money,
    pub discount: Money,
    pub e_vat: Money,
    pub c_vat: Money,
    pub paid: Money,
    /// `oi-status` — digit character, `0` = open.
    pub status: u8,
    pub deduct_days: u8,
    pub deduct_amt: i32,
    pub deduct_vat: i32,
    pub days: u8,
    pub cr: i32,
    /// `oi-applied` — always space from sl055.
    pub applied: u8,
    /// `oi-date-cleared` — always zero from sl055.
    pub date_cleared: i32,
}

/// `oi-*` money slots in wire order, offset of each from the record start.
const OI_MONEY_SLOTS: [usize; 9] = [49, 54, 59, 64, 69, 74, 79, 84, 89];

impl OpenItem2 {
    /// `multiply -1 by oi-*` for a credit note (dd000). `oi-p-c` and `oi-paid`
    /// are deliberately absent — ACAS leaves them positive.
    fn negate(&mut self) {
        self.net = -self.net;
        self.extra = -self.extra;
        self.carriage = -self.carriage;
        self.vat = -self.vat;
        self.discount = -self.discount;
        self.e_vat = -self.e_vat;
        self.c_vat = -self.c_vat;
        self.deduct_amt = -self.deduct_amt;
        self.deduct_vat = -self.deduct_vat;
    }

    fn money(&self) -> [Money; 9] {
        [
            self.p_c, self.net, self.extra, self.carriage, self.vat, self.discount,
            self.e_vat, self.c_vat, self.paid,
        ]
    }

    pub fn to_bytes(&self) -> [u8; OPEN_ITEM2_RECORD_BYTES] {
        let mut out = [0u8; OPEN_ITEM2_RECORD_BYTES];
        out[0..7].copy_from_slice(&self.customer.0);
        out[7..11].copy_from_slice(&self.invoice.0.to_le_bytes());
        out[11..15].copy_from_slice(&self.date.to_le_bytes());
        // oi-b-nos / oi-b-item (15..21): sl055 zeroes both, so they stay 0.
        out[21] = self.invoice_type;
        out[22..47].copy_from_slice(&self.description);
        out[47] = self.hold_flag;
        out[48] = self.unapl;
        for (at, value) in OI_MONEY_SLOTS.iter().zip(self.money()) {
            out[*at..*at + 5].copy_from_slice(&pack_money(value));
        }
        out[94] = self.status;
        out[95] = self.deduct_days;
        out[96..100].copy_from_slice(&self.deduct_amt.to_be_bytes());
        out[100..104].copy_from_slice(&self.deduct_vat.to_be_bytes());
        out[104] = self.days;
        out[105..109].copy_from_slice(&self.cr.to_le_bytes());
        out[109] = self.applied;
        out[110..114].copy_from_slice(&self.date_cleared.to_le_bytes());
        out
    }

    pub fn from_bytes(b: &[u8]) -> Option<Self> {
        if b.len() != OPEN_ITEM2_RECORD_BYTES {
            return None;
        }
        let money = |at: usize| unpack_money(b[at..at + 5].try_into().unwrap_or([0; 5]));
        Some(Self {
            customer: CustomerKey(b[0..7].try_into().ok()?),
            invoice: InvoiceNumber(u32::from_le_bytes(b[7..11].try_into().ok()?)),
            date: i32::from_le_bytes(b[11..15].try_into().ok()?),
            invoice_type: b[21],
            description: b[22..47].try_into().ok()?,
            hold_flag: b[47],
            unapl: b[48],
            p_c: money(49),
            net: money(54),
            extra: money(59),
            carriage: money(64),
            vat: money(69),
            discount: money(74),
            e_vat: money(79),
            c_vat: money(84),
            paid: money(89),
            status: b[94],
            deduct_days: b[95],
            deduct_amt: i32::from_be_bytes(b[96..100].try_into().ok()?),
            deduct_vat: i32::from_be_bytes(b[100..104].try_into().ok()?),
            days: b[104],
            cr: i32::from_le_bytes(b[105..109].try_into().ok()?),
            applied: b[109],
            date_cleared: i32::from_le_bytes(b[110..114].try_into().ok()?),
        })
    }
}

/// `s9(7)v99 comp-3` over nine digits — the oi-header money slots.
fn pack_money(cents: Money) -> [u8; 5] {
    let magnitude = cents.unsigned_abs() % 1_000_000_000;
    let formatted = format!("{magnitude:09}");
    let mut nibbles = [0u8; 9];
    for (slot, byte) in nibbles.iter_mut().zip(formatted.bytes()) {
        *slot = byte - b'0';
    }
    let mut out = [0u8; 5];
    for pair in 0..4 {
        out[pair] = (nibbles[pair * 2] << 4) | nibbles[pair * 2 + 1];
    }
    out[4] = (nibbles[8] << 4) | if cents < 0 { 0x0D } else { 0x0C };
    out
}

fn unpack_money(raw: [u8; 5]) -> Money {
    let mut magnitude: i64 = 0;
    for byte in raw {
        magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
    }
    magnitude = (magnitude - i64::from(raw[4] & 0x0F)) / 10;
    if matches!(raw[4] & 0x0F, 0x0D | 0x0B) { -magnitude } else { magnitude }
}

/// The four bucket totals sl055 carries across the run and writes as the rows
/// `Svo` (sales VAT), `Svp` (VAT-return leg), `Szc` (carriage), `Szd`
/// (discount) — each with the group row `Sv `/`Sz ` alongside.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct SpecialsTotals {
    pub sales_vat: Money,
    pub vat_return: Money,
    pub carriage: Money,
    pub discount: Money,
    /// hit counts (`work-3`): bumped only when the amount is non-zero
    pub n_sales_vat: u32,
    pub n_vat_return: u32,
    pub n_carriage: u32,
    pub n_discount: u32,
}

/// Why a caller may want to refuse the run.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ExtractError {
    /// SL122 analog: at least one invoice is still pending/unprinted.
    #[error("unprinted invoices present: {count}")]
    UnprintedPresent { count: u32 },
}

/// A whole run: the two tables it mutates and the output it builds.
pub struct ExtractRun {
    /// What the last read left at record byte 136 (`ih-update`, past the end
    /// of the 134-byte record). Beside disk state it is the one piece of
    /// ACAS's buffer that survives a record boundary — see the module docs.
    pub buffer_update: u8,
    pub analysis: BTreeMap<ValueCode, AnalysisRow>,
    pub values: BTreeMap<ValueCode, ValueRow>,
    pub out_items2: Vec<OpenItem2>,
    pub specials: SpecialsTotals,
}

impl Default for ExtractRun {
    fn default() -> Self {
        Self::new()
    }
}

impl ExtractRun {
    pub fn new() -> Self {
        Self {
            buffer_update: b' ',
            analysis: BTreeMap::new(),
            values: BTreeMap::new(),
            out_items2: vec![],
            specials: SpecialsTotals::default(),
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

    /// `88 ih-analyised` as the read buffer sees it — stale, not fresh.
    fn buffer_analysed(&self) -> bool {
        matches!(self.buffer_update, b'z' | b'Z')
    }

    /// `db000-Create` + `db010-Create-Anal`: make a value row exist for `code`,
    /// minting the analysis row first when the code is unknown ("Emergency
    /// Name" fallback) and, when the second character is set, its group row.
    fn ensure_value(&mut self, code: ValueCode) {
        if self.values.contains_key(&code) {
            return;
        }
        let analysis = match self.analysis.get(&code) {
            Some(row) => row.clone(),
            None => {
                let primary = AnalysisRow::emergency(code);
                self.analysis.insert(code, primary.clone());
                if code[2] != b' ' {
                    let group = [code[0], code[1], b' '];
                    self.analysis.insert(group, AnalysisRow::emergency(group));
                }
                primary
            }
        };
        // db000 writes the group row first when `va-second` is set, then the
        // caller writes the primary row.
        if code[2] != b' ' {
            let group = [code[0], code[1], b' '];
            if let Some(row) = self.analysis.get(&group) {
                self.values.insert(group, ValueRow::from_analysis(row));
            }
        }
        self.values.insert(code, ValueRow::from_analysis(&analysis));
    }

    /// `dc000-Store-Specials`: bump one bucket and its group row.
    fn store_special(&mut self, code: ValueCode, count: u32, amount: Money) {
        let targets: Vec<ValueCode> = if code[2] == b' ' {
            vec![code]
        } else {
            vec![code, [code[0], code[1], b' ']]
        };
        for target in targets {
            self.ensure_value(target);
            if let Some(row) = self.values.get_mut(&target) {
                row.t_this = (row.t_this + count) % COUNTER_MAX;
                row.t_year = (row.t_year + count) % COUNTER_MAX;
                row.add_amount(amount);
            }
        }
    }

    /// Line analysis (da010 steps 1-6).
    fn analyse_line(&mut self, line: &InvoiceLine) {
        if line.analysed() || line.product[0] == b'/' {
            return;
        }
        let code = [b'S', line.pa[0], line.pa[1]];
        self.ensure_value(code);

        let delta = if line.is_credit() { -line.net.cents() } else { line.net.cents() };
        let mut targets = vec![code];
        if code[2] != b' ' {
            targets.push([b'S', line.pa[0], b' ']);
        }
        for target in targets {
            if let Some(row) = self.values.get_mut(&target) {
                row.add_counter();
                row.add_amount(delta);
            }
        }
    }

    /// `dd000-Extract`: stage the open-item-2 header (no-op when already
    /// applied — ACAS then still runs the totals below).
    fn stage_header(&mut self, header: &InvoiceHeader) {
        if applied(header) {
            return;
        }
        let mut description = [b' '; 25];
        description[..header.order.len()].copy_from_slice(&header.order);

        let mut item = OpenItem2 {
            customer: header.customer,
            invoice: header.invoice_nos,
            date: header.date.0,
            invoice_type: header.invoice_type.to_cobol(),
            description,
            hold_flag: b' ',
            unapl: b' ',
            p_c: header.figures[0].cents(),
            net: header.figures[1].cents(),
            extra: header.figures[2].cents(),
            carriage: header.figures[3].cents(),
            vat: header.figures[4].cents(),
            discount: header.figures[5].cents(),
            e_vat: header.figures[6].cents(),
            c_vat: header.figures[7].cents(),
            paid: 0,
            status: b'0',
            deduct_days: header.deduct_days,
            deduct_amt: header.deduct_amt.hundredths() as i32,
            deduct_vat: header.deduct_vat.hundredths() as i32,
            days: 0,
            cr: header.cr.0,
            applied: b' ',
            date_cleared: 0,
        };
        if header.invoice_type == InvoiceType::CreditNote {
            item.negate();
        }
        self.out_items2.push(item);
    }

    /// `da020` totals. `work-2` is the VAT leg (`ih-c-vat + ih-vat + ih-e-vat`),
    /// sign-flipped for credit notes; type 1 sends it to the VAT-return bucket
    /// and everything else to the sales-VAT bucket. Zero amounts do not count.
    fn accumulate_specials(&mut self, header: &InvoiceHeader) {
        let credit = header.invoice_type == InvoiceType::CreditNote;
        let flip = |amount: Money| if credit { -amount } else { amount };

        let vat = flip(
            header.figures[7].cents() + header.figures[4].cents() + header.figures[6].cents(),
        );
        if vat != 0 {
            if header.invoice_type == InvoiceType::Invoice {
                self.specials.n_vat_return = (self.specials.n_vat_return + 1) % COUNTER_MAX;
                self.specials.vat_return += vat;
            } else {
                self.specials.n_sales_vat = (self.specials.n_sales_vat + 1) % COUNTER_MAX;
                self.specials.sales_vat += vat;
            }
        }

        let carriage = flip(header.figures[3].cents());
        if carriage != 0 {
            self.specials.n_carriage = (self.specials.n_carriage + 1) % COUNTER_MAX;
            self.specials.carriage += carriage;
        }

        let deduct = flip(header.deduct_amt.hundredths() as i32 as Money);
        if deduct != 0 {
            self.specials.n_discount = (self.specials.n_discount + 1) % COUNTER_MAX;
            self.specials.discount += deduct;
        }
    }

    /// `da040-Close-Files`: write the four bucket rows — zero-valued or not,
    /// exactly as ACAS does.
    pub fn finish(&mut self) {
        let buckets: [([u8; 3], u32, Money); 4] = [
            (*b"Svo", self.specials.n_sales_vat, self.specials.sales_vat),
            (*b"Svp", self.specials.n_vat_return, self.specials.vat_return),
            (*b"Szc", self.specials.n_carriage, self.specials.carriage),
            (*b"Szd", self.specials.n_discount, self.specials.discount),
        ];
        for (code, count, amount) in buckets {
            self.store_special(code, count, amount);
        }
    }

    /// Value rows in key order, as wire bytes.
    pub fn value_artifact(&self) -> Vec<u8> {
        self.values.values().flat_map(|row| row.to_bytes()).collect()
    }

    /// Analysis rows in key order, as wire bytes.
    pub fn analysis_artifact(&self) -> Vec<u8> {
        self.analysis.values().flat_map(|row| row.to_bytes()).collect()
    }

    /// Staged open-item-2 records, as wire bytes.
    pub fn item2_artifact(&self) -> Vec<u8> {
        self.out_items2.iter().flat_map(|row| row.to_bytes()).collect()
    }
}

/// `88 applied` on `ih-status`.
fn applied(header: &InvoiceHeader) -> bool {
    matches!(header.status, HeaderStatus::Applied(_))
}

/// `88 pending` on `ih-status`.
fn pending(header: &InvoiceHeader) -> bool {
    matches!(header.status, HeaderStatus::Pending)
}

/// `ih-status-L` — invoice printed. Column 1 of the five flag bytes.
fn printed(header: &InvoiceHeader) -> bool {
    header.status_flags[1].is_set()
}

/// SL122 pre-flight: how many invoices in this batch are unprinted/pending.
pub fn preflight(rows: &[InvoiceRow]) -> Option<u32> {
    let count = rows
        .iter()
        .filter(|row| matches!(row, InvoiceRow::Header(h) if pending(h) || !printed(h)))
        .count();
    (count > 0).then_some(count as u32)
}

/// Run the extract over `rows` in key order; returns the unprinted count.
///
/// A caller that already refused the run on [`preflight`] still gets the whole
/// computed work here — COBOL has finished writing by the time it warns, so
/// the artifacts have to match regardless.
pub fn extract(run: &mut ExtractRun, rows: &[InvoiceRow]) -> u32 {
    let mut unprinted = 0u32;
    let mut skipping: Option<u32> = None;

    for row in rows {
        let nos = match row {
            InvoiceRow::Header(header) => header.invoice_nos.0,
            InvoiceRow::Line(line) => line.invoice_nos.0,
        };
        // `da030` re-STARTs at the next invoice; the rest of this one is skipped.
        if skipping.is_some_and(|skipped| nos <= skipped) {
            continue;
        }
        skipping = None;

        match row {
            InvoiceRow::Line(line) => run.analyse_line(line),
            InvoiceRow::Header(header) => {
                if run.buffer_analysed() && applied(header) {
                    continue;
                }
                if header.invoice_type == InvoiceType::Proforma {
                    skipping = Some(nos);
                    continue;
                }
                if pending(header) || !printed(header) {
                    unprinted += 1;
                    skipping = Some(nos);
                    continue;
                }
                run.stage_header(header);
                if run.buffer_analysed() {
                    // dd000 ran, but `if ih-analyised` sends us to the next
                    // record before the totals (the rewrite keeps the buffer
                    // byte, the disk record loses it).
                    continue;
                }
                run.accumulate_specials(header);
                run.buffer_update = b'Z';
            }
        }
    }
    unprinted
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::invoice::{InvoiceLetter, PackedMoney, StatusFlag};

    fn path(rel: &str) -> std::path::PathBuf {
        std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../..").join(rel)
    }

    fn header(nos: u32, kind: InvoiceType, net: i64, vat: i64) -> InvoiceHeader {
        InvoiceHeader {
            invoice_nos: InvoiceNumber(nos),
            invoice_let: InvoiceLetter(b' '),
            customer: CustomerKey(*b"CUST010"),
            date: crate::invoice::CobolDate(155_534),
            order: *b"ORDER0010 ",
            invoice_type: kind,
            reference: *b"REF-000001",
            description: [b' '; 32],
            figures: std::array::from_fn(|i| match i {
                0 => PackedMoney::from_cents(net + vat).unwrap(),
                1 => PackedMoney::from_cents(net).unwrap(),
                4 => PackedMoney::from_cents(vat).unwrap(),
                _ => PackedMoney::ZERO,
            }),
            status: HeaderStatus::Other(b' '),
            status_flags: [StatusFlag::UNSET, StatusFlag::set(b'L'), StatusFlag::UNSET,
                           StatusFlag::UNSET, StatusFlag::UNSET],
            lines: 2,
            deduct_days: 0,
            deduct_amt: crate::invoice::CompAmount::ZERO,
            deduct_vat: crate::invoice::CompAmount::ZERO,
            days: 30,
            cr: crate::invoice::CobolDate(155_564),
            day_book_flag: b' ',
            update: b' ',
        }
    }

    fn line(nos: u32, item: u8, pa: [u8; 2], net: i64, credit: bool) -> InvoiceLine {
        InvoiceLine {
            invoice_nos: InvoiceNumber(nos),
            invoice_let: InvoiceLetter(b' '),
            line_no: item,
            product: *b"WIDGET-A     ",
            pa,
            qty: 1,
            line_type: if credit { b'3' } else { b'1' },
            description: [b' '; 32],
            net: PackedMoney::from_cents(net).unwrap(),
            unit: PackedMoney::from_cents(net).unwrap(),
            discount: crate::invoice::CompRate::ZERO,
            vat: PackedMoney::from_cents(net / 5).unwrap(),
            vat_code: b'1',
            update: b' ',
            filler: b' ',
            tail: crate::invoice::RecordTail::default(),
        }
    }

    fn rows(nos: u32, header: InvoiceHeader, lines: Vec<InvoiceLine>) -> Vec<InvoiceRow> {
        let _ = nos;
        let mut out = vec![InvoiceRow::Header(header)];
        out.extend(lines.into_iter().map(InvoiceRow::Line));
        out
    }

    fn value(run: &ExtractRun, code: &[u8; 3]) -> (u32, Money) {
        let row = run.values.get(code).expect("value row");
        (row.t_this, row.v_this)
    }

    #[test]
    fn packed_long_round_trips_and_keeps_its_sign() {
        for cents in [0i64, 1, -1, 123_456_789, -123_456_789, 9_999_999_999] {
            let raw = pack_long(cents);
            assert_eq!(unpack_long(raw), cents, "round trip at {cents}");
        }
        assert_eq!(pack_long(-1)[5] & 0x0F, 0x0D, "negative sign nibble");
        assert_eq!(pack_long(1)[5] & 0x0F, 0x0C, "positive sign nibble");
    }

    #[test]
    fn packed_long_truncates_high_digits_like_acas() {
        // Eleventh digit onwards is lost; ACAS never checks the overflow.
        assert_eq!(unpack_long(pack_long(12_345_678_901)), 2_345_678_901);
    }

    #[test]
    fn packed_money_matches_the_oi_golden_bytes() {
        assert_eq!(pack_money(120_000), [0x00, 0x01, 0x20, 0x00, 0x0C]);
        assert_eq!(pack_money(-12_500), [0x00, 0x00, 0x12, 0x50, 0x0D]);
        for cents in [0i64, 1, -1, 999_999_999, -999_999_999] {
            assert_eq!(unpack_money(pack_money(cents)), cents);
        }
    }

    #[test]
    fn a_line_bumps_its_own_row_and_its_group_row() {
        let mut run = ExtractRun::new();
        let rows = rows(1001, header(1001, InvoiceType::Invoice, 50_000, 10_000),
                        vec![line(1001, 1, *b"01", 50_000, false)]);
        extract(&mut run, &rows);
        assert_eq!(value(&run, b"S01"), (1, 50_000));
        assert_eq!(value(&run, b"S0 "), (1, 50_000));
        assert_eq!(run.analysis.get(b"S01").unwrap().desc, *b"Emergency Name          ");
    }

    #[test]
    fn a_credit_line_subtracts() {
        let mut run = ExtractRun::new();
        let rows = rows(1001, header(1001, InvoiceType::CreditNote, 50_000, 10_000),
                        vec![line(1001, 1, *b"01", 50_000, true)]);
        extract(&mut run, &rows);
        assert_eq!(value(&run, b"S01"), (1, -50_000));
    }

    #[test]
    fn comment_lines_do_not_count() {
        // The comment test comes before `db000-Create`, so no row is minted.
        let mut run = ExtractRun::new();
        let mut comment = line(1001, 1, *b"01", 50_000, false);
        comment.product[0] = b'/';
        let rows = rows(1001, header(1001, InvoiceType::Invoice, 50_000, 10_000), vec![comment]);
        extract(&mut run, &rows);
        assert!(run.values.is_empty());
    }

    #[test]
    fn only_the_first_posted_invoice_reaches_the_totals() {
        // F-B008: `ih-update` never lands on disk, but the read buffer keeps
        // it — after one posted header the next one looks analysed.
        let mut run = ExtractRun::new();
        let rows = [
            rows(1001, header(1001, InvoiceType::Invoice, 50_000, 10_000),
                 vec![line(1001, 1, *b"01", 50_000, false)]),
            rows(1002, header(1002, InvoiceType::Invoice, 20_000, 4_000),
                 vec![line(1002, 1, *b"01", 20_000, false)]),
        ]
        .concat();
        extract(&mut run, &rows);
        assert_eq!(run.out_items2.len(), 2, "both headers still stage");
        assert_eq!(run.specials.n_vat_return, 1);
        assert_eq!(run.specials.vat_return, 10_000);
        assert_eq!(value(&run, b"S01"), (2, 70_000), "line analysis is unaffected");
    }

    #[test]
    fn analysied_lines_are_skipped() {
        let mut run = ExtractRun::new();
        let mut done = line(1001, 1, *b"01", 50_000, false);
        done.update = b'z';
        let rows = rows(1001, header(1001, InvoiceType::Invoice, 50_000, 10_000), vec![done]);
        extract(&mut run, &rows);
        assert!(run.values.is_empty());
    }

    #[test]
    fn a_proforma_skips_itself_and_its_lines() {
        let mut run = ExtractRun::new();
        let rows = rows(1001, header(1001, InvoiceType::Proforma, 50_000, 10_000),
                        vec![line(1001, 1, *b"01", 50_000, false)]);
        assert_eq!(extract(&mut run, &rows), 0, "proformas do not flag SL122");
        assert!(run.out_items2.is_empty());
        assert!(run.values.is_empty(), "the proforma's lines are skipped too");
        assert_eq!(run.specials, SpecialsTotals::default());
    }

    #[test]
    fn pending_or_unprinted_headers_flag_the_run_and_skip_the_invoice() {
        let mut run = ExtractRun::new();
        let mut unp = header(1001, InvoiceType::Invoice, 50_000, 10_000);
        unp.status = HeaderStatus::Pending;
        let rows = vec![InvoiceRow::Header(unp.clone())];
        assert_eq!(preflight(&rows), Some(1));
        assert_eq!(extract(&mut run, &rows), 1);
        assert!(run.out_items2.is_empty());

        let mut unprinted = unp;
        unprinted.status = HeaderStatus::Other(b' ');
        unprinted.status_flags[1] = StatusFlag::UNSET;
        assert_eq!(preflight(&[InvoiceRow::Header(unprinted)]), Some(1));
        assert_eq!(preflight(&[InvoiceRow::Header(header(1, InvoiceType::Invoice, 1, 0))]),
                   None);
    }

    #[test]
    fn an_applied_header_counts_totals_but_stages_no_record() {
        let mut run = ExtractRun::new();
        let mut applied_header = header(1001, InvoiceType::Invoice, 50_000, 10_000);
        applied_header.status = HeaderStatus::Applied(b'z');
        extract(&mut run, &[InvoiceRow::Header(applied_header)]);
        assert!(run.out_items2.is_empty(), "dd000 leaves applied invoices alone");
        assert_eq!(run.specials.vat_return, 10_000, "the totals still count");
    }

    #[test]
    fn an_analysed_buffer_skips_applied_and_unapplied_headers_alike() {
        // With the buffer holding "Z", the `ih-analyised and applied` gate
        // fires for an applied header...
        let mut run = ExtractRun::new();
        run.buffer_update = b'Z';
        let mut gone = header(1001, InvoiceType::Invoice, 50_000, 10_000);
        gone.status = HeaderStatus::Applied(b'Z');
        extract(&mut run, &[InvoiceRow::Header(gone)]);
        assert_eq!(run.specials, SpecialsTotals::default());

        // ...and an unapplied one still stages its record, just no totals.
        let mut run = ExtractRun::new();
        run.buffer_update = b'Z';
        let fresh = header(1001, InvoiceType::Invoice, 50_000, 10_000);
        extract(&mut run, &[InvoiceRow::Header(fresh)]);
        assert_eq!(run.out_items2.len(), 1);
        assert_eq!(run.specials, SpecialsTotals::default());
    }

    #[test]
    fn credit_notes_flip_the_record_and_the_totals_but_not_p_c() {
        let mut run = ExtractRun::new();
        let mut cn = header(1002, InvoiceType::CreditNote, 30_000, 6_000);
        cn.figures[3] = PackedMoney::from_cents(200).unwrap();
        cn.deduct_amt = crate::invoice::CompAmount::from_hundredths(12_500);
        extract(&mut run, &[InvoiceRow::Header(cn.clone())]);
        let item = &run.out_items2[0];
        assert_eq!(item.net, -30_000);
        assert_eq!(item.carriage, -200);
        assert_eq!(item.p_c, 36_000, "oi-p-c is not in the negation list");
        assert_eq!(item.deduct_amt, -12_500);
        assert_eq!(item.cr, 155_564, "cr is moved after the negation");
        assert_eq!(run.specials.sales_vat, -6_000);
        assert_eq!(run.specials.carriage, -200);
        assert_eq!(run.specials.discount, -12_500);
    }

    #[test]
    fn oi_record_round_trips_through_its_bytes() {
        let mut run = ExtractRun::new();
        extract(&mut run, &[InvoiceRow::Header(header(1001, InvoiceType::Invoice, 50_000, 10_000))]);
        let raw = run.item2_artifact();
        assert_eq!(raw.len(), OPEN_ITEM2_RECORD_BYTES);
        let decoded = OpenItem2::from_bytes(&raw).unwrap();
        assert_eq!(decoded.to_bytes().as_slice(), raw.as_slice());
        assert_eq!(decoded.status, b'0');
        assert_eq!(decoded.applied, b' ');
        assert_eq!(&decoded.description[..9], b"ORDER0010");
        assert_eq!(&decoded.description[9..], [b' '; 16]);
    }

    // ---- golden parity -------------------------------------------------
    //
    // Goldens are COBOL's own output (see `harness/scenarios/sl055_extract.py`
    // and F-B007). The input flats are the table state the run started from,
    // so these tests replay the same conditions byte for byte.

    fn golden(case: &str, name: &str) -> Vec<u8> {
        std::fs::read(path(&format!("fixtures/golden/sl055/{case}/{name}")))
            .unwrap_or_else(|e| panic!("{case}/{name}: {e}"))
    }

    fn replay(case: &str) -> ExtractRun {
        let invoice = golden(case, "input-invoice.flat");
        let analysis = golden(case, "input-analysis.flat");
        let values = golden(case, "input-value.flat");

        let rows: Vec<InvoiceRow> = invoice
            .chunks_exact(crate::invoice::ACAS_INVOICE_RECORD_BYTES)
            .map(|rec| InvoiceRow::from_bytes(rec).expect("fixture row"))
            .collect();
        let analysis_rows: Vec<AnalysisRow> = analysis
            .chunks_exact(ANALYSIS_RECORD_BYTES)
            .map(|rec| AnalysisRow::from_bytes(rec).expect("analysis row"))
            .collect();
        let value_rows: Vec<ValueRow> = values
            .chunks_exact(VALUE_RECORD_BYTES)
            .map(|rec| ValueRow::from_bytes(rec).expect("value row"))
            .collect();

        let mut run = ExtractRun::with_tables(analysis_rows, value_rows);
        let _ = extract(&mut run, &rows);
        run.finish();
        run
    }

    /// `(code, counters, values)` per row — a readable diff than raw bytes.
    fn readable(artifact: &[u8]) -> Vec<(String, [u32; 3], [Money; 3])> {
        artifact
            .chunks_exact(VALUE_RECORD_BYTES)
            .map(|rec| ValueRow::from_bytes(rec).expect("value row"))
            .map(|row| {
                (
                    String::from_utf8_lossy(&row.code).into_owned(),
                    [row.t_this, row.t_last, row.t_year],
                    [row.v_this, row.v_last, row.v_year],
                )
            })
            .collect()
    }

    fn assert_matches_golden(case: &str) {
        let run = replay(case);
        assert_eq!(
            readable(&run.value_artifact()),
            readable(&golden(case, "value.flat")),
            "{case}: value rows"
        );
        assert_eq!(run.value_artifact(), golden(case, "value.flat"), "{case}: value file");
        assert_eq!(run.analysis_artifact(), golden(case, "analysis.flat"), "{case}: analysis file");
        assert_eq!(run.item2_artifact(), golden(case, "openitm2.dat"), "{case}: open-item-2");
    }

    #[test]
    fn clean_fixture_matches_the_cobol_golden() {
        assert_matches_golden("clean");
    }

    #[test]
    fn credit_note_fixture_matches_the_cobol_golden() {
        assert_matches_golden("credit_note");
    }

    #[test]
    fn pending_fixture_matches_the_cobol_golden() {
        assert_matches_golden("pending");
    }

    #[test]
    fn mixed_skip_rule_fixture_matches_the_cobol_golden() {
        assert_matches_golden("mixed");
    }

    #[test]
    fn comment_line_fixture_matches_the_cobol_golden() {
        assert_matches_golden("comment_lines");
    }

    #[test]
    fn pending_golden_keeps_the_posted_invoice_and_warns() {
        let run = replay("pending");
        assert_eq!(run.out_items2.len(), 1, "only the printed invoice is staged");
        assert_eq!(run.out_items2[0].invoice, InvoiceNumber(1001));
    }
}
