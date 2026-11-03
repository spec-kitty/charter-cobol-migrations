//! SL050 menu F — the invoice proof report.
//!
//! Ported from `sales/sl050.cbl`: the sequential invoice walk, the header row,
//! `analysis-print`, `extra-analysis`, `headings-1` and `main-end`. Pure kernel
//! over the invoice records and the sales rows; the caller owns both reads and
//! the whole screen layer (WP12).
//!
//! Layout, the edit pictures and the fossils are measured in
//! `docs/fd-evidence/F-B016-sl050-invoice-proof.md`; every field of the three
//! records and all fourteen print lines are dispositioned in
//! `docs/disposition-sl050.md`.
//!
//! ## The fossils, on purpose
//!
//! - `line-5` is **133 bytes** in a 132-byte record, so the write clips the
//!   last byte — the `R` of a negative gross's `CR` (Part 1).
//! - The type numbering is local: `1` is a *receipt* (printed `Receipt`, group
//!   1), `2` an invoice (group 2), `3` a credit note (group 3, every signed
//!   figure negated), `4` a proforma (skipped). An applied header
//!   (`ih-status` `z`/`Z`) is skipped too (Part 2).
//! - `at end` is status 10; every read after the first EOF answers 46, which
//!   the program does not test. A header whose declared line count runs off
//!   the end therefore spins on the stale record area and the report never
//!   reaches its totals (Part 3) — the caller reproduces this by handing the
//!   records it would read.
//! - An over-declared line count consumes the *next* record as an analysis
//!   line, header or not (Part 4).
//! - A failed keyed sales read prints `!! Customer Unknown` and raises
//!   `ws-error`, which nothing clears: one miss prints the closing warning
//!   line (Part 5).
//! - `l5-marker` is never moved and stays blank (Part 6).
//! - `total-cvat (a, k)` takes its group from the header and its VAT code from
//!   the line; a code of zero adds nothing (Part 7).
//! - A `move` into an edited field carries the value, not the source digits
//!   (Part 8), so every money edit here is fed in hundredths.

use crate::invoice::{InvoiceHeader, InvoiceLine, InvoiceRow, InvoiceType};
use crate::post::SalesRow;
use crate::posting::Money;
use crate::report::{edit_masked, edit_suppressed, PrintFile};

/// `01 print-record pic x(132)`.
pub const PRINT_RECORD_BYTES: usize = 132;

/// `line-5` in full — one byte wider than the record (F-B016 Part 1).
pub const LINE_5_BYTES: usize = 133;

/// `total-group occurs 3`, one per group.
const GROUPS: usize = 3;

/// `total-cvat occurs 5`.
const VAT_CODES: usize = 5;

/// `perform 3 times` — codes 1..3 always get a reconciliation row.
const BASE_VAT_ROWS: u8 = 3;

/// `ws-lit` — the group literals, in group order.
const GROUP_LITERALS: [&str; GROUPS] = ["Receipts", "Invoices", "Credit Notes"];

/// What the report needs from the environment.
#[derive(Debug, Clone)]
pub struct ProofContext {
    /// `usera` — the second heading line's left column.
    pub user: String,
    /// `to-day`, already converted to the system date form.
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International. Anything else reads as UK.
    pub date_form: u8,
    /// `page-lines` from the system record.
    pub page_lines: usize,
    /// `vat-rate (1..5)`, in hundredths.
    pub vat_rates: [i16; VAT_CODES],
    /// `extra-desc` — the literal for the `line-e` block. Blank in the harness
    /// seed, and a blank literal suppresses the row entirely.
    pub extra_desc: [u8; 12],
}

/// The records to proof, in file order, and the sales rows to key into.
#[derive(Debug, Clone, Copy)]
pub struct Proof<'a> {
    pub records: &'a [InvoiceRow],
    pub sales: &'a [SalesRow],
}

/// One `total-group` entry.
#[derive(Debug, Clone, Copy, Default)]
struct GroupTotals {
    deduct: Money,
    goods: Money,
    carriage: Money,
    net: Money,
    vat: Money,
    gross: Money,
    discount: Money,
    cvat: [Money; VAT_CODES],
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct ProofReport {
    pub print: PrintFile,
    /// Header rows written.
    pub rows: usize,
    /// `88 sales-missing` — a customer key that missed the ledger.
    pub sales_missing: bool,
    /// The report never reached `main-end`: an analysis ran off the end of the
    /// records, after which the COBOL loop reads status 46 forever and never
    /// writes the totals (F-B016 Part 3). The spool stops where the analysis
    /// stopped.
    pub hung: bool,
}

impl ProofReport {
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

/// A line under construction. `N` is the line's own width; `put` takes the
/// 1-based position the copybook uses and clips at that width.
#[derive(Debug, Clone)]
struct Line<const N: usize>([u8; N]);

impl<const N: usize> Line<N> {
    fn spaces() -> Self {
        Self([b' '; N])
    }

    fn put(&mut self, position: usize, value: impl AsRef<[u8]>) {
        let start = position.saturating_sub(1);
        for (offset, byte) in value.as_ref().iter().enumerate() {
            match self.0.get_mut(start + offset) {
                Some(slot) => *slot = *byte,
                None => break,
            }
        }
    }

    fn bytes(&self) -> &[u8] {
        &self.0
    }
}

impl Line<LINE_5_BYTES> {
    /// `write print-record from line-5` — the record is one byte narrower.
    fn clipped(&self) -> &[u8] {
        &self.0[..PRINT_RECORD_BYTES]
    }
}

/// `cr` edit at one of the program's three widths: the integer positions run
/// from six to nine, and the `CR`/spaces suffix is always two bytes.
fn edit_cr(cents: Money, integer_positions: usize) -> String {
    // `integer_positions` is the count of `z` positions; the picture's own
    // mandatory `9` follows them, so a zero still renders `0.00`.
    let mask = format!("{}9.99", "z".repeat(integer_positions));
    let mut rendered = edit_masked(cents, &mask);
    rendered.push_str(if cents < 0 { "CR" } else { "  " });
    rendered
}

/// `pic z9.99` — five bytes, blank-suppressed tens.
fn edit_rate(hundredths: i16) -> String {
    let cents = hundredths.unsigned_abs() as u32;
    format!("{}.{:02}", edit_suppressed(cents / 100, 2), cents % 100)
}

/// `zz060-Convert-Date` — a `binary-long` day number into the print form.
///
/// A zero or negative day prints spaces; a value `maps04` rejects prints
/// `00/00/0000` (F-B015 lapsing into sl050 unchanged).
fn convert_date(day: i32, date_form: u8) -> String {
    if day <= 0 {
        return String::new();
    }
    let (year, month, dom) = acas_common::cobol_date::CobolDate(day).to_ymd();
    if !(1..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&dom) {
        return String::from("00/00/0000");
    }
    match date_form {
        2 => format!("{month:02}/{dom:02}/{year:04}"),
        3 => format!("{year:04}/{month:02}/{dom:02}"),
        _ => format!("{dom:02}/{month:02}/{year:04}"),
    }
}

/// `line-1` — version, title, page number.
fn heading_1(page: usize) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(1, "SL050 (3.01.10)");
    line.put(50, "Unapplied Sales Transaction Report");
    line.put(125, "Page ");
    line.put(130, edit_suppressed(page as u32, 3));
    line
}

/// `line-2` — user and report date.
fn heading_2(context: &ProofContext) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(1, context.user.as_str());
    line.put(123, context.report_date.as_str());
    line
}

/// `line-4` — the column banner, byte for byte.
fn heading_4() -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(1, concat!(
        "  Number ---Date--- <------------Customer------------>  --Type--",
        "           "
    ));
    line.put(
        76,
        "Goods                 <---Net-->  <---Vat-->  <--Gross->",
    );
    line
}

/// `line-7` — the totals banner.
fn heading_7() -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(
        37,
        "Goods    Discount  Prompt Pay    Carriage         Net         Vat       Gross",
    );
    line
}

/// `line-9` — the reconciliation banner.
fn heading_9() -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(1, "V.A.T. Reconciliation       Receipts       Invoices   Credit Notes");
    line
}

/// `line-5` — one invoice header.
#[allow(clippy::too_many_arguments)]
fn row_5(
    header: &InvoiceHeader,
    name: &[u8],
    date: &str,
    kind: &str,
    goods: Money,
    net: Money,
    vat: Money,
    gross: Money,
) -> Line<LINE_5_BYTES> {
    let mut line = Line::spaces();
    line.put(1, format!("{} ", edit_suppressed(header.invoice_nos.0, 8)));
    line.put(10, date);
    line.put(21, header.customer.0);
    line.put(29, name);
    line.put(59, kind);
    line.put(73, edit_cr(goods, 6));
    line.put(98, edit_cr(net, 6));
    line.put(110, edit_cr(vat, 6));
    line.put(122, edit_cr(gross, 6));
    line
}

/// `line-a` — one analysis line, with or without its column labels.
fn line_a(labels: bool, code: &[u8], amount: Money, vat_code: u8) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    if labels {
        line.put(47, "Analysis");
        line.put(65, "Value");
        line.put(87, "Vat Code");
    }
    line.put(59, code);
    line.put(73, edit_cr(amount, 6));
    line.put(96, format!("{vat_code}"));
    line
}

/// `line-b` … `line-e` — the deduction block rows.
fn deduction_5(text: &str, amount: Money, vat_flag: Option<bool>) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(47, text);
    line.put(73, edit_cr(amount, 6));
    if let Some(set) = vat_flag {
        line.put(96, if set { "1" } else { "0" });
    }
    line
}

/// `line-6` — one group's totals.
fn line_6(literal: &str, totals: &GroupTotals) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(8, "Total");
    line.put(14, literal);
    line.put(32, edit_cr(totals.goods, 6));
    line.put(44, edit_cr(totals.discount, 6));
    line.put(56, edit_cr(totals.deduct, 6));
    line.put(68, edit_cr(totals.carriage, 6));
    line.put(80, edit_cr(totals.net, 6));
    line.put(92, edit_cr(totals.vat, 6));
    line.put(104, edit_cr(totals.gross, 6));
    line
}

/// `line-8` — one VAT-code reconciliation row.
fn line_8(code: u8, rate: i16, groups: [Money; GROUPS]) -> Line<PRINT_RECORD_BYTES> {
    let mut line = Line::spaces();
    line.put(1, "Vat Code");
    line.put(10, format!("{code}"));
    line.put(14, edit_rate(rate));
    line.put(19, "%");
    line.put(24, edit_cr(groups[0], 7));
    line.put(37, edit_cr(groups[1], 9));
    line.put(52, edit_cr(groups[2], 9));
    line
}

/// The report under construction: the spool, the counters and the totals.
struct Sheet<'a> {
    print: PrintFile,
    context: &'a ProofContext,
    /// `j` — the page counter.
    page: usize,
    /// `line-cnt`.
    line_cnt: usize,
    rows: usize,
    sales_missing: bool,
    /// `first-time` — labels the analysis columns once per report.
    first_time: bool,
    /// Set when an analysis asks for a record that is not there.
    hung: bool,
    totals: [GroupTotals; GROUPS],
    /// `a` — the group of the header being printed.
    group: usize,
}

impl<'a> Sheet<'a> {
    fn new(context: &'a ProofContext) -> Self {
        Self {
            print: PrintFile::new(),
            context,
            page: 0,
            line_cnt: 0,
            rows: 0,
            sales_missing: false,
            first_time: true,
            hung: false,
            totals: [GroupTotals::default(); GROUPS],
            group: 2,
        }
    }

    fn page_limit(&self) -> usize {
        self.context.page_lines
    }

    /// `headings-1` — `main12` and `cont-hds`. Page 1 advances one line; every
    /// later page ejects first.
    fn headings(&mut self) {
        self.page += 1;
        let line1 = heading_1(self.page);
        if self.page != 1 {
            self.print.write_page(line1.bytes());
        } else {
            self.print.write_after(line1.bytes(), 1);
        }
        self.print.write_after(heading_2(self.context).bytes(), 1);
        self.print.write_after(heading_4().bytes(), 2);
        self.print
            .write_after(Line::<PRINT_RECORD_BYTES>::spaces().bytes(), 1);
        self.line_cnt = 5;
    }

    /// One header's row plus its analysis and deduction blocks.
    fn header_row(
        &mut self,
        header: &InvoiceHeader,
        records: &[InvoiceRow],
        cursor: &mut usize,
        sales: &[SalesRow],
    ) {
        // `move sih-customer to sales-key l5-cust`, then the keyed read. A miss
        // prints the literal and raises the flag nothing clears (Part 5).
        let name: &[u8] = match sales
            .iter()
            .find(|row| row.key.0 == header.customer.0)
        {
            Some(row) => &row.name,
            None => {
                self.sales_missing = true;
                b"!! Customer Unknown"
            }
        };

        let mut deduct_amt = Money::from(header.deduct_amt.hundredths());
        let mut deduct_vat = Money::from(header.deduct_vat.hundredths());
        let mut figures: [Money; 8] = header.figures.map(|figure| figure.cents());
        if header.invoice_type == InvoiceType::CreditNote {
            figures = figures.map(|value| -value);
            deduct_amt = -deduct_amt;
            deduct_vat = -deduct_vat;
        }
        let [_, net, extra, carriage, vat, discount, e_vat, c_vat] = figures;

        self.group = match header.invoice_type {
            // `1` is a *receipt* in this program, whatever `InvoiceType` calls
            // it (F-B016 Part 2).
            InvoiceType::Invoice => 1,
            InvoiceType::Other(b'2') | InvoiceType::Proforma => 2,
            InvoiceType::CreditNote => 3,
            _ => 2,
        };
        let kind = match self.group {
            1 => "Receipt",
            3 => "Cr. Note",
            _ => "Invoice",
        };

        let vat_sum = vat + c_vat + e_vat + deduct_vat;
        let net_sum = net + extra + carriage + discount + deduct_amt;
        let gross = vat_sum + net_sum;

        // `add sih-c-vat sih-e-vat to total-cvat (a, 1)`
        self.totals[self.group - 1].cvat[0] += c_vat + e_vat;

        let group = &mut self.totals[self.group - 1];
        group.goods += net;
        group.discount += discount + extra;
        group.deduct += deduct_amt;
        group.carriage += carriage;
        group.vat += vat_sum;
        group.net += net_sum;
        group.gross += gross;

        if self.line_cnt > self.page_limit().saturating_sub(2) {
            self.headings();
        }
        let date = convert_date(header.date.0, self.context.date_form);
        let row = row_5(header, name, &date, kind, net, net_sum, vat_sum, gross);
        self.print.write_after(row.clipped(), 2);
        self.line_cnt += 2;
        self.rows += 1;

        self.first_time = true;
        // `perform analysis-print` and `perform extra-analysis`
        self.analysis(header, records, cursor);
        self.extra(header, extra, carriage, discount, deduct_amt, c_vat, e_vat);
    }

    /// `analysis-print` — up to `ih-lines` rows, stopping early at a comment
    /// line or at the end of the records.
    fn analysis(&mut self, header: &InvoiceHeader, records: &[InvoiceRow], cursor: &mut usize) {
        for _ in 0..header.lines {
            let Some(record) = records.get(*cursor) else {
                // `at end` — `move 99 to fs-Reply` and abandon the rest of
                // this invoice's analysis. Every later read answers 46, which
                // nothing tests, so `main-end` is never reached (Part 3).
                self.hung = true;
                return;
            };
            *cursor += 1;
            let raw = match record {
                InvoiceRow::Header(inner) => inner.clone().to_bytes().ok(),
                InvoiceRow::Line(inner) => inner.clone().to_bytes().ok(),
            };
            let Some(raw) = raw else { return };
            let Ok(line) = InvoiceLine::from_overlay(&raw) else {
                return;
            };
            // `move sil-product (1) to test-product` / `if il-comment`
            if line.product[0] == b'/' {
                return;
            }
            let credit = header.invoice_type == InvoiceType::CreditNote;
            let net = if credit { -line.net.cents() } else { line.net.cents() };
            let vat = if credit { -line.vat.cents() } else { line.vat.cents() };
            // `sil-vat-code` is `pic 9`, so a line carries an ASCII digit; a
            // header read as a line carries whatever byte the figure area
            // holds there, which `move` reduces to a digit (F-B016 Part 4).
            let raw_code = line.vat_code;
            let code = if raw_code.is_ascii_digit() {
                raw_code - b'0'
            } else {
                raw_code % 10
            };
            if code > 0 && usize::from(code) <= VAT_CODES {
                self.totals[self.group - 1].cvat[usize::from(code) - 1] += vat;
            }
            let labels = self.first_time;
            self.first_time = false;
            let row = line_a(labels, &line.pa, net, code);
            self.print.write_after(row.bytes(), 1);
            self.line_cnt += 1;
            if self.line_cnt > self.page_limit() {
                self.headings();
            }
        }
    }

    /// `extra-analysis` — the deduction block, at most once per header because
    /// each field is cleared as it is written.
    #[allow(clippy::too_many_arguments)]
    fn extra(
        &mut self,
        _header: &InvoiceHeader,
        extra: Money,
        carriage: Money,
        discount: Money,
        deduct_amt: Money,
        c_vat: Money,
        e_vat: Money,
    ) {
        if self.line_cnt > self.page_limit().saturating_sub(4) {
            self.headings();
        }
        let write = |sheet: &mut Self, line: Line<PRINT_RECORD_BYTES>| {
            sheet.print.write_after(line.bytes(), 1);
            sheet.line_cnt += 1;
        };
        if deduct_amt != 0 {
            write(self, deduction_5("Late Charge ", deduct_amt, None));
        }
        if discount != 0 {
            write(self, deduction_5("Discount    ", discount, Some(false)));
        }
        if carriage != 0 {
            write(self, deduction_5("Carriage    ", carriage, Some(c_vat != 0)));
        }
        if extra != 0 {
            // `move extra-desc to le-a` — a blank system description blanks the
            // literal, and a blank `le-a` skips the row even though the amount
            // is already in the totals (measured: the golden has no extra row).
            let text = String::from_utf8_lossy(&self.context.extra_desc).into_owned();
            if text.trim_end().is_empty() {
                return;
            }
            write(self, deduction_5(&text, extra, Some(e_vat != 0)));
        }
    }

    /// `main-end` — the totals block, the warning and the reconciliation.
    fn finish(&mut self) {
        if self.line_cnt < self.page_limit().saturating_sub(16) {
            self.print
                .write_after(Line::<PRINT_RECORD_BYTES>::spaces().bytes(), 3);
        } else {
            self.headings();
        }
        self.print.write_after(heading_7().bytes(), 2);
        self.print
            .write_after(Line::<PRINT_RECORD_BYTES>::spaces().bytes(), 1);
        for (index, literal) in GROUP_LITERALS.iter().enumerate() {
            let totals = self.totals[index];
            self.print.write_after(line_6(literal, &totals).bytes(), 1);
        }
        if self.sales_missing {
            let mut line = Line::<PRINT_RECORD_BYTES>::spaces();
            line.put(1, "Warning Record/s Missing In Sales File");
            self.print.write_after(line.bytes(), 2);
        }
        self.print.write_after(heading_9().bytes(), 2);
        self.print
            .write_after(Line::<PRINT_RECORD_BYTES>::spaces().bytes(), 1);
        for code in 1..=BASE_VAT_ROWS {
            let rate = self.context.vat_rates[usize::from(code) - 1];
            let groups = std::array::from_fn(|group| self.totals[group].cvat[usize::from(code) - 1]);
            self.print.write_after(line_8(code, rate, groups).bytes(), 1);
        }
        // `if vat-rate (4) not = zero or vat-rate (5) not = zero`
        // Codes 1..3 always print; 4 and 5 are the local-tax pair and print
        // only when their rate is set.
        if self.context.vat_rates[3] != 0 || self.context.vat_rates[4] != 0 {
            for code in (BASE_VAT_ROWS + 1)..=VAT_CODES as u8 {
                let rate = self.context.vat_rates[usize::from(code) - 1];
                let groups = std::array::from_fn(|group| self.totals[group].cvat[usize::from(code) - 1]);
                self.print.write_after(line_8(code, rate, groups).bytes(), 1);
            }
        }
    }
}

/// Run one proof through to its printed report.
pub fn run(proof: &Proof<'_>, context: &ProofContext) -> ProofReport {
    let mut sheet = Sheet::new(context);
    sheet.headings();
    let mut cursor = 0usize;
    while cursor < proof.records.len() {
        let record = &proof.records[cursor];
        cursor += 1;
        let InvoiceRow::Header(header) = record else {
            // `if sih-test not = zero go to loop`
            continue;
        };
        // `if sapplied go to loop`
        if matches!(header.status.to_cobol(), b'z' | b'Z') {
            continue;
        }
        // `if sih-type = 4` — proformas
        if header.invoice_type == InvoiceType::Proforma {
            continue;
        }
        sheet.header_row(header, proof.records, &mut cursor, proof.sales);
    }
    if !sheet.hung {
        sheet.finish();
    }
    ProofReport {
        print: sheet.print,
        rows: sheet.rows,
        sales_missing: sheet.sales_missing,
        hung: sheet.hung,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::invoice::{CompAmount, CustomerKey, HeaderStatus, InvoiceNumber};
    use crate::invoice::{InvoiceLetter, PackedMoney};
    use crate::invoice::CobolDate;

    const RUN_DAY: i32 = 155_535;

    fn key7(customer: &str) -> [u8; 7] {
        let mut key = [b' '; 7];
        let bytes = customer.as_bytes();
        key[..bytes.len()].copy_from_slice(bytes);
        key
    }

    fn sale(customer: &str, name: &str) -> SalesRow {
        let mut record = [b' '; crate::post::SALES_RECORD_BYTES];
        record[..7].copy_from_slice(&key7(customer));
        let bytes = name.as_bytes();
        record[7..7 + bytes.len()].copy_from_slice(bytes);
        SalesRow::from_bytes(record)
    }

    #[allow(clippy::too_many_arguments)]
    fn header(
        number: u32,
        customer: &str,
        kind: u8,
        lines: u8,
        net: i64,
        vat: i64,
        extra: i64,
        carriage: i64,
        discount: i64,
        e_vat: i64,
        c_vat: i64,
        deduct: u32,
        status: u8,
    ) -> InvoiceHeader {
        let mut figures = [PackedMoney::ZERO; 8];
        figures[1] = PackedMoney::from_cents(net).unwrap();
        figures[2] = PackedMoney::from_cents(extra).unwrap();
        figures[3] = PackedMoney::from_cents(carriage).unwrap();
        figures[4] = PackedMoney::from_cents(vat).unwrap();
        figures[5] = PackedMoney::from_cents(discount).unwrap();
        figures[6] = PackedMoney::from_cents(e_vat).unwrap();
        figures[7] = PackedMoney::from_cents(c_vat).unwrap();
        InvoiceHeader {
            invoice_nos: InvoiceNumber(number),
            invoice_let: InvoiceLetter(b'L'),
            customer: CustomerKey(key7(customer)),
            date: CobolDate(RUN_DAY),
            order: *b"ORDER-0001",
            invoice_type: InvoiceType::from_cobol(b'0' + kind),
            reference: *b"REF-000001",
            description: [b' '; 32],
            figures,
            status: HeaderStatus::from_cobol(status),
            status_flags: [crate::invoice::StatusFlag::UNSET; 5],
            lines,
            deduct_days: 0,
            deduct_amt: CompAmount::from_hundredths(deduct),
            deduct_vat: CompAmount::ZERO,
            days: 0,
            cr: CobolDate(0),
            day_book_flag: b' ',
            update: b' ',
        }
    }

    fn line(product: &str, pa: &str, net: i64, vat: i64, code: u8) -> InvoiceLine {
        InvoiceLine {
            invoice_nos: InvoiceNumber(1),
            invoice_let: InvoiceLetter(b'L'),
            line_no: 1,
            product: {
                let mut out = [b' '; 13];
                let bytes = product.as_bytes();
                out[..bytes.len().min(13)].copy_from_slice(&bytes[..bytes.len().min(13)]);
                out
            },
            pa: {
                let mut out = [b' '; 2];
                let bytes = pa.as_bytes();
                out[..bytes.len().min(2)].copy_from_slice(&bytes[..bytes.len().min(2)]);
                out
            },
            qty: 1,
            line_type: b'2',
            description: [b' '; 32],
            net: PackedMoney::from_cents(net).unwrap(),
            unit: PackedMoney::ZERO,
            discount: crate::invoice::CompRate::ZERO,
            vat: PackedMoney::from_cents(vat).unwrap(),
            vat_code: b'0' + code,
            update: b' ',
            filler: b' ',
            tail: crate::invoice::RecordTail::new([b' '; 54]),
        }
    }

    fn context() -> ProofContext {
        ProofContext {
            user: "Harness Test Co".into(),
            report_date: "03/11/2026".into(),
            date_form: 1,
            page_lines: 48,
            vat_rates: [0; 5],
            extra_desc: [b' '; 12],
        }
    }

    fn text(records: Vec<InvoiceRow>, sales: Vec<SalesRow>) -> String {
        let proof = Proof {
            records: &records,
            sales: &sales,
        };
        String::from_utf8_lossy(&run(&proof, &context()).into_bytes()).into_owned()
    }

    fn plain(kind: u8, net: i64) -> Vec<InvoiceRow> {
        vec![
            InvoiceRow::Header(header(1, "CUST011", kind, 0, net, 0, 0, 0, 0, 0, 0, 0, b'I')),
            // Last record is a header with no lines: the only shape that ends
            // (F-B016 Part 3).
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ]
    }

    fn ledger() -> Vec<SalesRow> {
        vec![sale("CUST011", "Alpha Analytical Ltd")]
    }

    /// Part 1 — the row is 133 bytes in a 132-byte record.
    #[test]
    fn the_gross_column_loses_its_last_sign_byte() {
        let produced = text(plain(3, 40_00), ledger());
        let row = produced
            .lines()
            .find(|line| line.contains("Cr. Note"))
            .unwrap_or_else(|| panic!("no credit-note row in:\n{produced}"));
        assert_eq!(row.len(), 132);
        assert!(row.ends_with("40.00C"), "the `R` of `CR` is clipped: {row:?}");
    }

    /// Part 2 — `1` is a receipt here, and it lands in the receipts group.
    #[test]
    fn type_one_is_a_receipt_on_this_program() {
        let produced = text(plain(1, 50_000), ledger());
        assert!(produced.contains("Receipt"));
        assert!(produced.contains("Total Receipts"));
        assert!(produced.contains("500.00"));
    }

    #[test]
    fn proformas_and_applied_headers_never_reach_the_report() {
        let records = vec![
            InvoiceRow::Header(header(1, "CUST011", 4, 0, 77_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 66_00, 0, 0, 0, 0, 0, 0, 0, b'z')),
            InvoiceRow::Header(header(3, "CUST011", 2, 0, 11_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ];
        let produced = text(records, ledger());
        assert!(!produced.contains("77.00"));
        assert!(!produced.contains("66.00"));
        assert!(produced.contains("11.00"));
    }

    /// Part 3 — a declared line count that runs off the end stops the analysis
    /// without reaching the totals. The caller sees a report that simply ends.
    #[test]
    fn an_over_declared_line_at_end_file_stops_the_report() {
        let records = vec![InvoiceRow::Header(header(
            1, "CUST011", 2, 3, 10_00, 0, 0, 0, 0, 0, 0, 0, b'I',
        ))];
        let report = run(
            &Proof {
                records: &records,
                sales: &ledger(),
            },
            &context(),
        );
        assert!(report.hung);
        let produced = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        assert!(!produced.contains("Total Receipts"), "no totals block");
        assert!(!produced.contains("V.A.T."));
    }

    /// Part 4 — the missing lines are taken from the following header, which is
    /// then consumed and never printed as a row of its own.
    #[test]
    fn an_over_declared_line_consumes_the_next_header() {
        let records = vec![
            InvoiceRow::Header(header(1, "CUST011", 2, 2, 10_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 33_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ];
        let report = run(
            &Proof {
                records: &records,
                sales: &ledger(),
            },
            &context(),
        );
        // The consumed header's figures appear in the analysis row, but it
        // never gets a row of its own. The analysis then asks for the second
        // declared line, overruns the records and the report stops there — the
        // loop's next read answers 46 and nothing tests it (Part 3).
        assert_eq!(report.rows, 1);
        assert!(report.hung);
        let produced = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        assert!(produced.contains("Analysis"));
        assert!(!produced.contains("Total Receipts"));
    }

    /// Part 5 — the missing-customer flag is sticky.
    #[test]
    fn one_unknown_customer_warns_and_the_warning_never_clears() {
        let records = vec![
            InvoiceRow::Header(header(1, "ZZZZZZ", 2, 0, 99_99, 0, 0, 0, 0, 0, 0, 0, b'I')),
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 12_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ];
        let produced = text(records, ledger());
        assert!(produced.contains("!! Customer Unknown"));
        assert!(produced.contains("Warning Record/s Missing In Sales File"));
    }

    /// Part 6 — the marker column is never moved.
    #[test]
    fn the_marker_column_stays_blank() {
        let record = plain(2, 10_00);
        let InvoiceRow::Header(header) = &record[0] else { unreachable!() };
        let name = b"Alpha";
        let row = row_5(header, name, "03/11/2026", "Invoice", 10_00, 10_00, 0, 10_00);
        assert_eq!(&row.bytes()[53..58], b"     ");
        assert_eq!(&row.bytes()[58..72], b"Invoice       ");
    }

    /// Part 7 — the code axis comes from the line, and only 1..5 accumulate.
    #[test]
    fn the_reconciliation_indexes_the_line_vat_code() {
        let records = vec![
            InvoiceRow::Header(header(1, "CUST011", 2, 2, 10_00, 0, 0, 0, 0, 0, 0, 0, b'I')),
            InvoiceRow::Line(line("P1", "V2", 10_00, 7_00, 2)),
            InvoiceRow::Line(line("P2", "V2", 10_00, 1_00, 9)),
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ];
        let produced = text(records, ledger());
        assert!(produced.contains("Vat Code 2"));
        // Code 9 is past the table and adds nothing.
        assert!(produced.contains("Vat Code 3"));
        assert!(produced.contains("7.00"));
    }

    /// Part 8 — a negative value carries `CR`, a zero keeps its mandatory digit.
    #[test]
    fn the_edits_follow_the_pictures() {
        assert_eq!(edit_cr(50_000, 6), "    500.00  ");
        assert_eq!(edit_cr(-12_345, 6), "    123.45CR");
        assert_eq!(edit_cr(0, 6), "      0.00  ");
        assert_eq!(edit_rate(0), " 0.00");
        assert_eq!(edit_rate(1_750), "17.50");
    }

    #[test]
    fn dates_follow_the_system_form_and_reject_nonsense() {
        assert_eq!(convert_date(0, 1), "");
        assert_eq!(convert_date(-1, 1), "");
        assert_eq!(convert_date(RUN_DAY, 1), "03/11/2026");
        assert_eq!(convert_date(RUN_DAY, 2), "11/03/2026");
        assert_eq!(convert_date(RUN_DAY, 3), "2026/11/03");
        assert_eq!(convert_date(3_000_000, 1), "21/09/9814");
    }

    /// The `line-e` literal comes from the system record; blank, the row is
    /// skipped even though its amount is already in the totals.
    #[test]
    fn a_blank_extra_description_suppresses_the_extra_row() {
        let records = vec![
            InvoiceRow::Header(header(1, "CUST011", 2, 0, 10_00, 0, 2_00, 0, 0, 0, 0, 0, b'I')),
            InvoiceRow::Header(header(2, "CUST011", 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, b'I')),
        ];
        let produced = text(records.clone(), ledger());
        assert!(produced.contains("Total Invoices"));
        assert!(!produced.contains("Extra "), "the literal is blank");
        let mut described = context();
        described.extra_desc = *b"Extra Charge";
        let proof = Proof {
            records: &records,
            sales: &ledger(),
        };
        let with = String::from_utf8_lossy(&run(&proof, &described).into_bytes()).into_owned();
        assert!(with.contains("Extra Charge  "));
    }

    /// The page break is `line-cnt > page-lines - 2`, and the heading is written
    /// with a form feed on the previous line.
    #[test]
    fn the_page_break_ejects_before_the_row_it_cannot_fit() {
        let records: Vec<_> = (1..=6)
            .map(|n| {
                InvoiceRow::Header(header(n, "CUST011", 1, 0, 10_00, 0, 0, 0, 0, 0, 0, 0, b'I'))
            })
            .collect();
        let mut short = context();
        short.page_lines = 8;
        let proof = Proof {
            records: &records,
            sales: &ledger(),
        };
        let produced = run(&proof, &short).into_bytes();
        let text = String::from_utf8_lossy(&produced);
        // One eject per row that no longer fits, each carrying the next page's
        // heading on the previous line.
        assert_eq!(produced.iter().filter(|byte| **byte == 0x0C).count(), 7);
        assert!(text.contains("Page   2"));
        assert!(text.contains("Page   7"));
    }
}
