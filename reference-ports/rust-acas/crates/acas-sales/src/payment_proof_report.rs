//! SL095 menu J — the payment and journal proof report.
//!
//! Ported from `sales/sl095.cbl`: `init01`, `report1`, `read-loop`,
//! `process-invoice`, `loop-end` and `headings`. Pure kernel over three inputs —
//! the open-item rows `sl090` has just sorted, the sales rows to key into, and
//! the run context; the caller owns every file handle and the whole screen
//! layer (WP12).
//!
//! Layout and the fossils are measured in
//! `docs/fd-evidence/F-B095-sl095-payment-proof-report.md`; every field of the
//! open-item and sales records and all seven print lines are dispositioned in
//! `docs/disposition-sl095.md`.
//!
//! ## The fossils, on purpose
//!
//! - `s-flag-p` gates the whole program. A zero exits from `init01` before any
//!   open, so a refusal leaves **no spool at all** and touches no flag.
//! - `work-1` and `l9-value` are unsigned. The balance therefore flattens any
//!   negative leg sum on the way in (Part 2) and unapplied cash cannot print a
//!   minus: a negative figure is stored as its absolute value (Part 3).
//! - The page check runs one row late, so the row that overflows the page is
//!   still printed on it and the form feed is appended to the end of that
//!   row's line (Part 4). Every page is one payment row too long.
//! - Sub-lines are gated on the *carried* customer (`save-customer`) and on a
//!   non-zero payment, never on the invoice's own customer or status (Part 5):
//!   a closed invoice can print, an invoice whose customer has not just paid
//!   cannot.
//! - Only the payment path tests `s-open`; an invoice's status is not read.
//! - A failed keyed sales read prints `!! Customer Unknown` and is otherwise
//!   silent — no flag, no warning line, and the row still counts (Part 7).
//! - `init01` writes `oi-3-flag` `Y` (system byte 562) and `s-flag-p` `2`
//!   (byte 569) before any file is opened (Part 8).

use crate::post::SalesRow;
use crate::posting::Money;
use crate::report::{edit_masked, edit_suppressed, PrintFile};

/// `01 print-record pic x(132)`.
pub const PRINT_RECORD_BYTES: usize = 132;

/// `01 open-item-record-s pic x(114)`.
pub const OPEN_ITEM_BYTES: usize = 114;

/// 1-based columns of `line-6`, straight out of the copybook.
const B_NOS: usize = 1;
const SLASH: usize = 6;
const B_ITEM: usize = 7;
const TRANS: usize = 11;
const DATE: usize = 13;
const AC: usize = 24;
const NAME: usize = 32;
const VALUE: usize = 61;
const APPROP: usize = 72;
const DEDN: usize = 83;
const INVOICE: usize = 92;
const I_DATE: usize = 101;
const I_APPROP: usize = 111;
const I_BALANCE: usize = 120;

/// Zero-based offsets of the open-item fields this program reads (F-B008).
const OI_CUSTOMER: std::ops::Range<usize> = 0..7;
const OI_INVOICE: std::ops::Range<usize> = 7..11;
const OI_DATE: std::ops::Range<usize> = 11..15;
const OI_B_NOS: std::ops::Range<usize> = 15..19;
const OI_B_ITEM: std::ops::Range<usize> = 19..21;
const OI_TYPE: usize = 21;
const OI_STATUS: usize = 94;

/// `oi-paid` — `s9(7)v99 comp-3`, five bytes.
const OI_PAID: usize = 89;

/// `oi-approp` — a redefines of `oi-net` at 54.
const OI_APPROP: usize = 54;

/// The legs `work-1` sums, in the copybook's own order (Part 2). `oi-paid` and
/// `oi-p-c` are absent. Offsets 96 and 100 are four-byte `comp`, the rest are
/// five-byte `comp-3`.
const OI_WORK_SLOTS: [usize; 9] = [54, 59, 64, 69, 74, 79, 84, 96, 100];

/// `!! Customer Unknown`.
const UNKNOWN: &str = "!! Customer Unknown";

/// The two system bytes `init01` writes before anything is opened.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Flags {
    /// `oi-3-flag`, system byte 562.
    pub oi_3_flag: u8,
    /// `s-flag-p`, system byte 569.
    pub s_flag_p: u8,
}

impl Flags {
    /// `move "Y" to oi-3-flag` and `move 2 to s-flag-p`.
    fn raised() -> Self {
        Self {
            oi_3_flag: b'Y',
            s_flag_p: 2,
        }
    }
}

/// What the report needs from the environment.
#[derive(Debug, Clone)]
pub struct ProofContext {
    /// `usera` — the second heading line's left column.
    pub user: String,
    /// `to-day`, already in the system date form.
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International. Zero is rewritten to UK.
    pub date_form: u8,
    /// `page-lines` from the system record.
    pub page_lines: usize,
}

/// The sorted open-item rows and the sales rows to key into.
#[derive(Debug, Clone, Copy)]
pub struct Proof<'a> {
    pub records: &'a [[u8; OPEN_ITEM_BYTES]],
    pub sales: &'a [SalesRow],
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct ProofReport {
    pub print: PrintFile,
    pub payment_rows: usize,
    pub journal_rows: usize,
    pub invoice_rows: usize,
    /// Payments whose key missed the sales file.
    pub unknown_customers: usize,
}

impl ProofReport {
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }

    /// Rows written, payment and invoice alike.
    pub fn rows(&self) -> usize {
        self.payment_rows + self.journal_rows + self.invoice_rows
    }
}

/// What `sl095` did.
#[derive(Debug, Clone)]
pub enum ProofOutcome {
    /// `s-flag-p` was zero: neither file is opened and the flags stay as they
    /// were.
    Refused,
    /// The open-item open failed: `close`, `main-exit` — no spool at all, but
    /// the flags were already raised (they precede the open).
    NoInput(Flags),
    /// A report was printed.
    Printed(Flags, ProofReport),
}

impl ProofOutcome {
    /// The spool bytes; empty for both no-report paths.
    pub fn bytes(&self) -> Vec<u8> {
        match self {
            Self::Printed(_, report) => report.clone().into_bytes(),
            _ => Vec::new(),
        }
    }
}

/// A 132-byte record under construction, positioned by 1-based column.
#[derive(Debug, Clone)]
struct Line([u8; PRINT_RECORD_BYTES]);

impl Line {
    fn spaces() -> Self {
        Self([b' '; PRINT_RECORD_BYTES])
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

    /// `move spaces` / `move zero` over a run of the line: either way the bytes
    /// become spaces, because every numeric field it is used on is
    /// blank-when-zero.
    fn clear(&mut self, position: usize, width: usize) {
        self.put(position, " ".repeat(width));
    }

    fn bytes(&self) -> &[u8] {
        &self.0
    }
}

/// `pic z(7)9.99cr` — a signed mask with the two-byte `CR` suffix, or all
/// spaces when the value is zero and the picture is blank-when-zero.
fn edit_cr(cents: Money, int_positions: usize, blank_when_zero: bool) -> String {
    if blank_when_zero && cents == 0 {
        return " ".repeat(int_positions + 6);
    }
    let mask = format!("{}9.99", "z".repeat(int_positions));
    let mut rendered = edit_masked(cents, &mask);
    rendered.push_str(if cents < 0 { "CR" } else { "  " });
    rendered
}

/// `pic zzzzz9.99bb` — two trailing blank insertions, blank when zero.
///
/// The `b` is not part of the picture's digit count, so the mask handed to
/// [`edit_masked`] stops at `.99` and the two spaces are appended here.
fn edit_bb(cents: Money, int_positions: usize) -> String {
    if cents == 0 {
        return " ".repeat(int_positions + 6);
    }
    let mut rendered = edit_masked(cents, &format!("{}9.99", "z".repeat(int_positions)));
    rendered.push_str("  ");
    rendered
}

/// `pic z(4)9 blank when zero` — zero prints as five spaces.
fn edit_suppressed_blank_when_zero(value: u32, width: usize) -> String {
    if value == 0 {
        " ".repeat(width)
    } else {
        edit_suppressed(value, width)
    }
}

/// `pic zzzzzzz9b` — one trailing blank insertion, blank when zero.
fn edit_trailing_blank(value: i64) -> String {
    if value == 0 {
        return " ".repeat(9);
    }
    let mut rendered = edit_masked(value, "zzzzzzz9");
    rendered.push(' ');
    rendered
}

/// `zz060-Convert-Date` — a `binary-long` day number into the print form.
///
/// A zero or negative day prints spaces; a value `maps04` rejects prints
/// `00/00/0000` (F-B015 lapsing into this program unchanged).
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
        // `if Date-Form = zero move 1 to Date-Form` — zero reads as UK.
        _ => format!("{dom:02}/{month:02}/{year:04}"),
    }
}

/// Signed `comp-3` hundredths from five bytes: nine digits, two per byte, with
/// the sign in the low nibble of the last.
fn packed(bytes: &[u8]) -> Money {
    let mut value: i64 = 0;
    for byte in &bytes[..bytes.len() - 1] {
        value = value * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0f);
    }
    let last = bytes[bytes.len() - 1];
    value = value * 10 + i64::from(last >> 4);
    if matches!(last & 0x0f, 0x0d | 0x0f) {
        -value
    } else {
        value
    }
}

/// A `binary-long` / `comp` four-byte field, little endian.
fn le_word(bytes: &[u8]) -> u32 {
    u32::from_le_bytes(bytes.try_into().expect("four bytes"))
}

/// `oi-deduct-amt`/`oi-deduct-vat` — `pic s999v99 comp`, four big-endian bytes
/// of hundredths.
fn comp_four(bytes: &[u8]) -> Money {
    Money::from(i32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
}

/// The four money legs of one invoice record, summed the way the unsigned
/// `work-1` receiver stores them (Part 2): each `add ... giving` keeps the
/// absolute value and drops anything above eight digits.
fn work_sum(record: &[u8; OPEN_ITEM_BYTES]) -> Money {
    let mut work: Money = 0;
    for slot in OI_WORK_SLOTS {
        let leg = if matches!(slot, 96 | 100) {
            comp_four(&record[slot..slot + 4])
        } else {
            packed(&record[slot..slot + 5])
        };
        work = (work + leg).abs() % 100_000_000;
    }
    work
}

/// Everything the report accumulates.
struct Sheet<'a> {
    print: PrintFile,
    context: &'a ProofContext,
    sales: &'a [SalesRow],
    /// `line-6`, kept across rows exactly as the COBOL keeps it.
    line6: Line,
    page: usize,
    line_cnt: usize,
    /// `save-customer` — set by a payment row, never cleared.
    save_customer: [u8; 7],
    /// `sav-approp` — the last payment's appropriation.
    sav_approp: Money,
    t_pay: Money,
    t_approp: Money,
    t_deducts: Money,
    j_pay: Money,
    j_approp: Money,
    j_deducts: Money,
    payment_rows: usize,
    journal_rows: usize,
    invoice_rows: usize,
    unknown_customers: usize,
}

impl<'a> Sheet<'a> {
    fn new(context: &'a ProofContext, sales: &'a [SalesRow]) -> Self {
        Self {
            print: PrintFile::new(),
            context,
            sales,
            line6: Line::spaces(),
            page: 0,
            line_cnt: 0,
            save_customer: [b' '; 7],
            sav_approp: 0,
            t_pay: 0,
            t_approp: 0,
            t_deducts: 0,
            j_pay: 0,
            j_approp: 0,
            j_deducts: 0,
            payment_rows: 0,
            journal_rows: 0,
            invoice_rows: 0,
            unknown_customers: 0,
        }
    }

    fn page_limit(&self) -> usize {
        self.context.page_lines
    }

    /// `headings` — page 1 advances one line; every later page ejects onto the
    /// end of the line the break fell on (Part 4).
    fn headings(&mut self) {
        self.page += 1;
        let mut line1 = Line::spaces();
        line1.put(1, "SL095 (3.01.07)");
        line1.put(49, "Payment And Journal Proof Report");
        line1.put(125, "Page ");
        line1.put(130, edit_suppressed(self.page as u32, 3));

        let mut line2 = Line::spaces();
        line2.put(1, self.context.user.as_str());
        line2.put(123, self.context.report_date.as_str());

        let mut line4 = Line::spaces();
        line4.put(
            1,
            "  Batch  Tp  Pay Date  <-------------Customer------------->",
        );
        line4.put(
            62,
            "  Value    Approp.    Ded'n    <--------Payment Appropriation--------->",
        );

        let mut line5 = Line::spaces();
        line5.put(23, " A/C               Name");
        line5.put(93, "Invoice   Date      Approp.     Balance ");

        if self.page != 1 {
            self.print.write_page(line1.bytes());
            self.print.write_after(line2.bytes(), 1);
            self.print.write_after(Line::spaces().bytes(), 1);
        } else {
            self.print.write_before(line1.bytes(), 1);
            self.print.write_before(line2.bytes(), 1);
        }
        self.print.write_after(line4.bytes(), 2);
        self.print.write_after(line5.bytes(), 1);
        self.line_cnt = 6;
    }

    /// `read sales-file ... invalid key` — the name for a key, or the literal.
    fn name_for(&mut self, customer: &[u8]) -> Vec<u8> {
        match self.sales.iter().find(|row| row.key.0 == customer) {
            Some(row) => row.name.to_vec(),
            None => {
                self.unknown_customers += 1;
                UNKNOWN.as_bytes().to_vec()
            }
        }
    }

    /// One payment (type 5) or journal (type 6) row.
    fn payment(&mut self, record: &[u8; OPEN_ITEM_BYTES]) {
        let kind = record[OI_TYPE];
        self.save_customer.copy_from_slice(&record[OI_CUSTOMER]);

        let b_nos = u32::from_be_bytes(record[OI_B_NOS].try_into().expect("four bytes"));
        let b_item = u16::from_be_bytes(record[OI_B_ITEM].try_into().expect("two bytes"));
        self.line6.put(B_NOS, edit_suppressed_blank_when_zero(b_nos, 5));
        self.line6.put(SLASH, "/");
        // `pic 999b` keeps its three digit positions and its trailing blank.
        self.line6.put(B_ITEM, format!("{b_item:03} "));
        self.line6
            .put(TRANS, if kind == b'6' { "J" } else { "P" });

        let day = le_word(&record[OI_DATE]) as i32;
        self.line6
            .put(DATE, convert_date(day, self.context.date_form));

        let customer = &record[OI_CUSTOMER];
        self.line6.put(AC, customer);
        let name = self.name_for(customer);
        self.line6.put(NAME, &name);

        let paid = packed(&record[OI_PAID..OI_PAID + 5]);
        let approp = packed(&record[OI_APPROP..OI_APPROP + 5]);
        let dedn = comp_four(&record[96..100]);
        if kind == b'6' {
            self.j_pay += paid;
            self.j_approp += approp;
            self.j_deducts += dedn;
        } else {
            self.t_pay += paid;
            self.t_approp += approp;
            self.t_deducts += dedn;
        }

        self.line6.put(VALUE, edit_bb(paid, 5));
        self.line6.put(APPROP, edit_bb(approp, 5));
        self.sav_approp = approp;
        self.line6.put(DEDN, edit_bb(dedn, 3));
        // `move zero to l6-invoice l6-i-approp l6-i-balance` and
        // `move spaces to l6-i-date` — no sub-line on a payment.
        self.line6.clear(INVOICE, 9);
        self.line6.clear(I_APPROP, 9);
        self.line6.clear(I_BALANCE, 13);
        self.line6.clear(I_DATE, 10);

        if self.line_cnt > self.page_limit() {
            self.headings();
        }
        self.print.write_after(self.line6.bytes(), 2);
        self.line_cnt += 2;
        if kind == b'6' {
            self.journal_rows += 1;
        } else {
            self.payment_rows += 1;
        }

        // The fields the next row must not inherit.
        self.line6.clear(B_NOS, 5);
        self.line6.clear(B_ITEM, 4);
        self.line6.clear(DEDN, 9);
        self.line6.clear(VALUE, 11);
        self.line6.clear(APPROP, 11);
        self.line6.clear(DATE, 11);
        self.line6.clear(AC, 8);
        self.line6.clear(NAME, 29);
        self.line6.clear(TRANS, 2);
    }

    /// `process-invoice` — the appropriation sub-line (Part 5).
    fn invoice(&mut self, record: &[u8; OPEN_ITEM_BYTES]) {
        let paid = packed(&record[OI_PAID..OI_PAID + 5]);
        if paid == 0 {
            return;
        }
        if record[OI_CUSTOMER] != self.save_customer {
            return;
        }

        let invoice = le_word(&record[OI_INVOICE]);
        self.line6.put(INVOICE, edit_trailing_blank(i64::from(invoice)));

        let day = le_word(&record[OI_DATE]) as i32;
        self.line6
            .put(I_DATE, convert_date(day, self.context.date_form));
        self.line6.clear(SLASH, 1);

        let approp = if paid > self.sav_approp {
            self.sav_approp
        } else {
            paid
        };
        self.line6.put(I_APPROP, &edit_bb(approp, 5)[..9]);
        self.line6.put(I_BALANCE, edit_cr(work_sum(record) - paid, 7, true));

        self.print.write_after(self.line6.bytes(), 1);
        self.line_cnt += 1;
        self.invoice_rows += 1;
        if self.line_cnt > self.page_limit() {
            self.headings();
        }
    }

    /// One `line-9` totals row.
    fn total_line(&mut self, literal: &str, value: Money, advance: usize) {
        let mut line = Line::spaces();
        line.put(24, literal);
        line.put(41, edit_masked(value, "zzzzzz9.99"));
        self.print.write_after(line.bytes(), advance);
    }

    /// `loop-end` — the four-slot payment block, then the identical journal
    /// block under the `Journal` title.
    fn finish(&mut self) {
        if self.line_cnt > self.page_limit().saturating_sub(8) {
            self.headings();
        }

        let mut line8 = Line::spaces();
        line8.put(31, "**************");

        let mut line7 = Line::spaces();
        line7.put(31, "Payment");
        line7.put(38, " Totals");
        self.print.write_after(line7.bytes(), 4);
        self.print.write_after(line8.bytes(), 1);

        self.total_line("Payments", self.t_pay, 3);
        self.total_line("Appropriations", self.t_approp, 1);
        // `l9-value` is unsigned, so a negative unapplied figure prints as its
        // absolute value (Part 3).
        self.total_line("Unapplied Cash", self.t_pay - self.t_approp, 1);
        self.total_line("Deductions Taken", self.t_deducts, 2);

        // `move "Journal" to l7-tit`
        let mut line7 = Line::spaces();
        line7.put(31, "Journal");
        line7.put(38, " Totals");
        self.print.write_after(line7.bytes(), 2);
        self.print.write_after(line8.bytes(), 1);

        self.total_line("Payments", self.j_pay, 3);
        self.total_line("Appropriations", self.j_approp, 1);
        self.total_line("Unapplied Cash", self.j_pay - self.j_approp, 1);
        self.total_line("Deductions Taken", self.j_deducts, 2);
    }
}

/// Run one proof, exactly as `init01` → `report1` → `loop-end` would.
///
/// `open_status` is the `fs-reply` from opening the sorted open-item file;
/// `s_flag_p` is the operator's payment flag (system byte 569).
pub fn run(
    s_flag_p: u8,
    open_status: u8,
    proof: &Proof<'_>,
    context: &ProofContext,
) -> ProofOutcome {
    // `if s-flag-p = zero go to menu-exit`
    if s_flag_p == 0 {
        return ProofOutcome::Refused;
    }
    let flags = Flags::raised();
    // `open input open-item-file-s` then
    // `if fs-reply not = zero close ... go to main-exit`
    if open_status != 0 {
        return ProofOutcome::NoInput(flags);
    }
    let mut sheet = Sheet::new(context, proof.sales);
    sheet.headings();
    for record in proof.records {
        let kind = record[OI_TYPE];
        if kind == b'2' {
            sheet.invoice(record);
            continue;
        }
        // `if oi-type < 5 or > 6 or not s-open go to read-loop`
        if !matches!(kind, b'5' | b'6') || record[OI_STATUS] != b'0' {
            continue;
        }
        sheet.payment(record);
    }
    sheet.finish();

    ProofOutcome::Printed(
        flags,
        ProofReport {
            print: sheet.print,
            payment_rows: sheet.payment_rows,
            journal_rows: sheet.journal_rows,
            invoice_rows: sheet.invoice_rows,
            unknown_customers: sheet.unknown_customers,
        },
    )
}


#[cfg(test)]
mod tests {
    use super::*;

    const RUN_DAY: i32 = 155_535;

    /// One row of `line-6` under a test.
    const SUB_LINE_INDENT: usize = 60;

    /// `s9(7)v99 comp-3` — nine digits, sign in the last nibble.
    fn pack(cents: i64) -> [u8; 5] {
        let digits: Vec<u8> = format!("{:09}", cents.unsigned_abs())
            .bytes()
            .map(|byte| byte - b'0')
            .collect();
        let mut out = [0u8; 5];
        for (index, pair) in digits.chunks(2).enumerate() {
            out[index] = pair[0] << 4
                | pair
                    .get(1)
                    .copied()
                    .unwrap_or(if cents < 0 { 0x0d } else { 0x0c });
        }
        out
    }

    struct Row {
        bytes: [u8; OPEN_ITEM_BYTES],
    }

    impl Row {
        fn new(customer: &str, invoice: u32, day: i32, batch: (u32, u16), kind: u8) -> Self {
            let mut bytes = [b' '; OPEN_ITEM_BYTES];
            bytes[..customer.len()].copy_from_slice(customer.as_bytes());
            bytes[OI_INVOICE].copy_from_slice(&invoice.to_le_bytes());
            bytes[OI_DATE].copy_from_slice(&day.to_le_bytes());
            bytes[OI_B_NOS].copy_from_slice(&batch.0.to_be_bytes());
            bytes[OI_B_ITEM].copy_from_slice(&batch.1.to_be_bytes());
            bytes[OI_TYPE] = kind;
            bytes[OI_STATUS] = b'0';
            for slot in [49usize, 54, 59, 64, 69, 74, 79, 84, 89] {
                bytes[slot..slot + 5].copy_from_slice(&pack(0));
            }
            bytes[96..100].copy_from_slice(&0i32.to_be_bytes());
            bytes[100..104].copy_from_slice(&0i32.to_be_bytes());
            bytes[104] = 0;
            bytes[105..109].copy_from_slice(&0i32.to_le_bytes());
            bytes[109] = b' ';
            bytes[110..114].copy_from_slice(&0i32.to_le_bytes());
            Self { bytes }
        }

        /// `net` is also `oi-approp`; `paid` is `oi-paid`.
        fn money(mut self, net: i64, paid: i64) -> Self {
            self.bytes[54..59].copy_from_slice(&pack(net));
            self.bytes[89..94].copy_from_slice(&pack(paid));
            self
        }

        fn closed(mut self) -> Self {
            self.bytes[OI_STATUS] = b'1';
            self
        }
    }

    fn ledger(customer: &str, name: &str) -> SalesRow {
        let mut record = [b' '; crate::post::SALES_RECORD_BYTES];
        record[..customer.len()].copy_from_slice(customer.as_bytes());
        record[7..7 + name.len()].copy_from_slice(name.as_bytes());
        SalesRow::from_bytes(record)
    }

    fn context(page_lines: usize) -> ProofContext {
        ProofContext {
            user: "Harness Test Co".into(),
            report_date: "03/11/2026".into(),
            date_form: 1,
            page_lines,
        }
    }

    fn outcome(rows: &[Row], sales: &[SalesRow], page_lines: usize) -> ProofOutcome {
        let records: Vec<[u8; OPEN_ITEM_BYTES]> = rows.iter().map(|row| row.bytes).collect();
        run(
            1,
            0,
            &Proof {
                records: &records,
                sales,
            },
            &context(page_lines),
        )
    }

    fn text(rows: &[Row], sales: &[SalesRow], page_lines: usize) -> String {
        String::from_utf8_lossy(&outcome(rows, sales, page_lines).bytes()).into_owned()
    }

    /// The appropriation sub-lines: `line-6` with its payment half cleared.
    fn sub_lines(text: &str) -> Vec<String> {
        text.lines()
            .filter(|line| line.starts_with(&" ".repeat(SUB_LINE_INDENT)))
            .map(str::to_string)
            .collect()
    }

    /// The four `line-9` values of a block, in order.
    fn totals(lines: &[String], title: &str) -> Vec<String> {
        let start = lines
            .iter()
            .position(|line| line.contains(title))
            .unwrap_or_else(|| panic!("no {title} block"));
        // The block is: title, banner, then the four rows, with the blank
        // separators falling between them.
        lines[start + 2..]
            .iter()
            .filter(|line| !line.trim().is_empty())
            .take(4)
            .map(|line| line.split_whitespace().last().unwrap_or("").to_string())
            .collect()
    }

    #[test]
    fn without_a_payment_run_nothing_is_opened_and_no_flag_moves() {
        assert!(matches!(
            run(1, 0, &Proof { records: &[], sales: &[] }, &context(48)),
            ProofOutcome::Refused | ProofOutcome::Printed(..)
        ));
        assert!(matches!(
            run(0, 0, &Proof { records: &[], sales: &[] }, &context(48)),
            ProofOutcome::Refused
        ));
        // The refusal exits from `init01`, so the rows never matter.
        let rows = [Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5')];
        assert!(run(0, 0, &Proof { records: &[], sales: &[] }, &context(48))
            .bytes()
            .is_empty());
        assert!(!outcome(&rows, &[], 48).bytes().is_empty());
    }

    #[test]
    fn a_failed_open_still_raises_the_flags_but_prints_nothing() {
        match run(1, 35, &Proof { records: &[], sales: &[] }, &context(48)) {
            ProofOutcome::NoInput(flags) => {
                assert_eq!(flags.oi_3_flag, b'Y');
                assert_eq!(flags.s_flag_p, 2);
            }
            other => panic!("{other:?}"),
        }
    }

    #[test]
    fn a_reported_run_raises_both_flags() {
        let rows = [Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5')];
        match outcome(&rows, &[], 48) {
            ProofOutcome::Printed(flags, _) => {
                assert_eq!(flags.oi_3_flag, b'Y');
                assert_eq!(flags.s_flag_p, 2);
            }
            other => panic!("{other:?}"),
        }
    }

    #[test]
    fn the_batch_number_blanks_at_zero_and_the_item_keeps_its_zeroes() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (0, 7), b'5'),
            Row::new("CUST041", 2, RUN_DAY, (9, 7), b'5'),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        assert!(produced.contains("     /007 P"), "{produced}");
        assert!(produced.contains("    9/007 P"), "{produced}");
    }

    #[test]
    fn the_journal_marker_is_j_and_the_payment_marker_p() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'6'),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'5'),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        assert!(produced.contains("1/001 J "));
        assert!(produced.contains("1/002 P "));
    }

    #[test]
    fn an_unknown_customer_prints_the_literal_and_still_counts() {
        let rows = [Row::new("ZZZZZZ", 1, RUN_DAY, (1, 1), b'5').money(0, 1_000)];
        let produced = text(&rows, &[], 48);
        assert!(produced.contains("!! Customer Unknown"));
        assert_eq!(totals(&produced.lines().map(str::to_string).collect::<Vec<_>>(), "Payment Totals")[0], "10.00");
        // No warning line: the miss is not an error in this program (Part 7).
        assert!(!produced.contains("Warning"));
    }

    #[test]
    fn a_closed_payment_is_skipped_but_a_closed_invoice_is_not() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').closed(),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'5').money(0, 1_000),
            Row::new("CUST041", 3, RUN_DAY, (1, 3), b'2').money(100, 500).closed(),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        // 1 is closed and gone; 2 is the only payment counted.
        assert!(!produced.contains("1/001"));
        assert_eq!(
            totals(&produced.lines().map(str::to_string).collect::<Vec<_>>(), "Payment Totals")[0],
            "10.00"
        );
        // 3 is a closed *invoice*: the invoice path never reads `s-open`.
        assert_eq!(sub_lines(&produced).len(), 1, "{produced}");
    }

    #[test]
    fn an_invoice_only_prints_under_the_carried_customer() {
        let rows = vec![
            // Before any payment: `save-customer` is still blank.
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'2').money(100, 500),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'5').money(0, 100),
            // After a payment for someone else.
            Row::new("CUST042", 3, RUN_DAY, (1, 3), b'6').money(0, 100),
            Row::new("CUST041", 4, RUN_DAY, (1, 4), b'2').money(100, 500),
            // Zero paid, and the right customer again.
            Row::new("CUST042", 5, RUN_DAY, (1, 5), b'2').money(100, 500),
            Row::new("CUST042", 6, RUN_DAY, (1, 6), b'2').money(100, 0),
        ];
        let sales = [ledger("CUST041", "Alpha"), ledger("CUST042", "Beta")];
        let produced = text(&rows, &sales, 48);
        let sub = sub_lines(&produced);
        assert_eq!(sub.len(), 1, "only invoice 5 can print:\n{produced}");
        assert!(sub[0].contains("      5 "));
    }

    #[test]
    fn the_appropriation_is_the_payments_own_and_is_clamped() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').money(4_000, 10_000),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'2').money(1_000, 5_000),
            Row::new("CUST041", 3, RUN_DAY, (1, 3), b'2').money(1_000, 2_500),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        let sub = sub_lines(&produced);
        // Paid 50.00 against a 40.00 appropriation, then 25.00 against it.
        assert!(sub[0].contains("    40.00"), "{:?}", sub);
        assert!(sub[1].contains("    25.00"), "{:?}", sub);
    }

    #[test]
    fn a_zero_appropriation_blanks_the_column() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').money(0, 100),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'2').money(100, 500),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        let sub = sub_lines(&produced);
        // Columns 111..119 blank: `l6-i-approp` is blank when zero.
        assert_eq!(&sub[0][110..119], "         ");
    }

    #[test]
    fn the_invoice_row_leaves_the_payment_columns_blank() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').money(0, 100),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'2').money(100, 500),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        let sub = sub_lines(&produced);
        // batch, item, marker, date, account, name, value, appropriation, ded'n
        assert_eq!(&sub[0][0..60], " ".repeat(60), "the cleared half: {}", sub[0]);
        // `l6-slash` is blanked for a sub-line, unlike a payment row.
        assert_eq!(&sub[0][5..6], " ");
    }

    #[test]
    fn a_negative_balance_carries_cr_and_a_zero_one_blanks() {
        assert_eq!(edit_cr(-13_25, 7, true), "      13.25CR");
        assert_eq!(edit_cr(20_400, 7, true), "     204.00  ");
        assert_eq!(edit_cr(0, 7, true), " ".repeat(13));
    }

    /// `work-1` is unsigned: negative legs come back absolute (Part 2).
    #[test]
    fn the_leg_sum_flattens_sign_and_wraps_at_six_integer_digits() {
        let mut record = Row::new("CUST041", 1, RUN_DAY, (1, 1), b'2').bytes;
        record[54..59].copy_from_slice(&pack(1_000));
        record[69..74].copy_from_slice(&pack(-1_400));
        assert_eq!(work_sum(&record), 400);
        record[54..59].copy_from_slice(&pack(90_000_000));
        record[69..74].copy_from_slice(&pack(90_000_000));
        assert_eq!(work_sum(&record), 80_000_000);
    }

    /// `l9-value` is unsigned, so unapplied cash cannot print a minus.
    #[test]
    fn unapplied_cash_absorbs_a_negative() {
        let rows = [Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').money(9_000, 5_000)];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        let lines: Vec<String> = produced.lines().map(str::to_string).collect();
        assert_eq!(totals(&lines, "Payment Totals"), ["50.00", "90.00", "40.00", "0.00"]);
    }

    /// Part 4 — the check runs one row late: the row that overflows is still
    /// printed and the eject lands on the *next* one.
    #[test]
    fn the_page_break_fires_after_the_row_that_overflows() {
        let rows: Vec<Row> = (1..=6)
            .map(|n| Row::new("CUST041", n, RUN_DAY, (1, n as u16), b'5').money(0, 100))
            .collect();
        let produced = outcome(&rows, &[ledger("CUST041", "Alpha")], 14).bytes();
        // Two breaks: one before row 6, one before the totals block, because
        // page 2 is already past `page-lines - 8` after a single row.
        assert_eq!(produced.iter().filter(|byte| **byte == 0x0C).count(), 2);
        let text = String::from_utf8_lossy(&produced);
        assert!(text.contains("Page   2"));
        // Row 5 overflows page 1 and the feed is appended to its own line.
        assert!(
            text.lines()
                .any(|line| line.contains("1/005 P") && line.contains('\u{c}')),
            "the eject shares the overflowed row's line:\n{text}"
        );
    }

    /// The last row can overflow with no row left to trigger the eject: the
    /// break then falls on the totals block instead.
    #[test]
    fn a_page_overflow_on_the_last_row_breaks_at_the_totals() {
        let rows: Vec<Row> = (1..=5)
            .map(|n| Row::new("CUST041", n, RUN_DAY, (1, n as u16), b'5').money(0, 100))
            .collect();
        let produced = outcome(&rows, &[ledger("CUST041", "Alpha")], 14).bytes();
        // The eject carries the next page's title on its own line.
        let text = String::from_utf8_lossy(&produced);
        assert!(text
            .lines()
            .any(|line| line.contains("Page   2") && line.contains('\u{c}')));
        assert!(text.contains("Payment Totals"));
    }

    #[test]
    fn the_totals_block_breaks_a_full_page() {
        let rows: Vec<Row> = (1..=5)
            .map(|n| Row::new("CUST041", n, RUN_DAY, (1, n as u16), b'5').money(0, 100))
            .collect();
        // `line-cnt` is 16 > 12 - 8, so the totals block opens a new page.
        let produced = outcome(&rows, &[ledger("CUST041", "Alpha")], 12).bytes();
        assert!(String::from_utf8_lossy(&produced)
            .lines()
            .any(|line| line.contains("Page   2") && line.contains('\u{c}')));
    }

    #[test]
    fn the_two_blocks_copy_each_other_and_their_totals_do_not_mix() {
        let rows = [
            Row::new("CUST041", 1, RUN_DAY, (1, 1), b'5').money(0, 1_000),
            Row::new("CUST041", 2, RUN_DAY, (1, 2), b'6').money(0, 7_000),
        ];
        let produced = text(&rows, &[ledger("CUST041", "Alpha")], 48);
        let lines: Vec<String> = produced.lines().map(str::to_string).collect();
        let payments = lines.iter().position(|line| line.contains("Payment Totals")).unwrap();
        let journal = lines.iter().position(|line| line.contains("Journal Totals")).unwrap();
        assert!(payments < journal);
        assert_eq!(totals(&lines, "Payment Totals")[0], "10.00");
        assert_eq!(totals(&lines, "Journal Totals")[0], "70.00");
    }

    #[test]
    fn dates_follow_the_system_form_and_reject_nonsense() {
        assert_eq!(convert_date(0, 1), "");
        assert_eq!(convert_date(-1, 1), "");
        assert_eq!(convert_date(RUN_DAY, 1), "03/11/2026");
        assert_eq!(convert_date(RUN_DAY, 2), "11/03/2026");
        assert_eq!(convert_date(RUN_DAY, 3), "2026/11/03");
        assert_eq!(convert_date(RUN_DAY, 0), "03/11/2026");
        assert_eq!(convert_date(3_000_000, 1), "21/09/9814");
    }

    #[test]
    fn the_edits_follow_the_pictures() {
        assert_eq!(edit_bb(1_000, 5), "    10.00  ");
        assert_eq!(edit_bb(0, 5), " ".repeat(11));
        assert_eq!(edit_trailing_blank(0), " ".repeat(9));
        assert_eq!(edit_trailing_blank(918), "     918 ");
        assert_eq!(edit_suppressed_blank_when_zero(0, 5), "     ");
        assert_eq!(edit_suppressed_blank_when_zero(2, 5), "    2");
    }
}
