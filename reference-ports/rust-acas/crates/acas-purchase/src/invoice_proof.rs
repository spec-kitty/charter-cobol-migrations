//! PL050 menu G — the purchase invoice proof report.
//!
//! Ported from `purchase/pl050.cbl`: the sequential invoice walk, `analysis-print`,
//! `extra-analysis`, `main12`/`cont-hds` and `main-end`. Pure kernel over the
//! invoice frames and the supplier rows; the caller owns the reads and the whole
//! screen layer (WP12).
//!
//! Layout, the edit pictures and every fossil are measured in
//! `docs/fd-evidence/F-B050-pl050-invoice-proof.md`; every field of the three
//! records and all ten print lines are dispositioned in
//! `docs/disposition-pl050.md`.
//!
//! ## The fossils, on purpose
//!
//! - The group subscript is the type **byte** (`move ih-type to a`), and there
//!   is no proforma skip. Type `4` therefore indexes entry four of a
//!   three-entry table: the row prints (`Cr. Note`, no sign flip) and its
//!   amounts land past the end of the table, where they are never printed by
//!   the `perform 3 times` totals (Part 1).
//! - That out-of-range entry writes over `ws-deduct-amt` and `line-cnt`, the
//!   two fields that follow the table. The `total-ded (4)` add is a packed
//!   six-byte store at exactly `ws-deduct-amt`, so `line-cnt` takes the sixth
//!   digit pair of the accumulation — see [`overrun`] (Part 1).
//! - The analysis reads `il-pa (1)` through a **12-byte** product where the disk
//!   field is thirteen, so the two-byte code is disk bytes 21..23: the thirteenth
//!   product byte and the first `pa` byte (Part 2).
//! - `line-5` fits the record exactly, so unlike the sales program nothing is
//!   clipped (Part 3).
//! - The page check precedes the row write and the totals block always starts a
//!   new page; `line-9` advances five lines, not the sales program's two
//!   (Part 4).
//! - A missed supplier key prints `Supplier Unknown` and raises a flag nothing
//!   clears, so one miss prints the closing warning (Part 5).
//! - An analysis that runs off the end of the file spins: after the first end of
//!   file every read answers status 46, which `at end` does not catch, so
//!   `main-end` is never reached (Part 6).
//! - `l5-marker` is never moved and stays blank (Part 7).
//! - `total-cvat (a, k)` takes its group from the header and its VAT code from
//!   the line; the reconciliation only prints codes 1..3 (Part 8).
//! - A comment line is a `go to main-exit`, which ends that `perform` iteration
//!   and no more: the next declared line is still read and printed (Part 2).
//! - `main-end` opens with `perform main12 in headings`. A paragraph `perform`
//!   stops at the next paragraph header, so the closing page gets `main12` and
//!   not `cont-hds`: no column banner, and `line-cnt` keeps its value because
//!   only `cont-hds` resets it (Part 4).

use acas_common::cobol_date::CobolDate;
use acas_sales::report::{edit_masked, edit_suppressed, PrintFile};

use crate::extract::Money;
use crate::purchase_invoice::{InvoiceRow, PurchaseHeader, ACAS_INVOICE_RECORD_BYTES};

/// `01 print-record pic x(132)`. `line-5` fills it exactly (Part 3).
pub const PRINT_RECORD_BYTES: usize = 132;

/// `purch-record` (`fdpl.cob`) — only the key and the name are read here.
pub const PURCHASE_RECORD_BYTES: usize = 300;

/// `total-group occurs 3`.
const GROUPS: usize = 3;

/// `perform compute-vatcodes 3 times`, and `vat-rate (1..3)`.
const VAT_ROWS: usize = 3;

/// `ws-lit` — the group literals, in group order.
const GROUP_LITERALS: [&str; GROUPS] = ["Receipts", "Invoices", "Credit Notes"];

/// `ws-data`'s offset of `total-group`. The table is 54 bytes an entry (six
/// `s9(8)v99` followed by `total-cvat occurs 3`) and it is the last thing before
/// `ws-deduct-amt` and `line-cnt` — which is what entry four lands on (Part 1).
const WS_GROUP_OFFSET: usize = 26;
const GROUP_ENTRY_BYTES: usize = 54;
/// `ws-deduct-amt`, the field directly after the table: where `total-ded (4)`
/// lands, and the only overrun store that changes a printed byte.
const WS_DEDUCT: usize = WS_GROUP_OFFSET + GROUPS * GROUP_ENTRY_BYTES;

/// One supplier row, as much of `purch-record` as the proof reads.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SupplierRow {
    pub key: [u8; 7],
    pub name: [u8; 30],
}

impl SupplierRow {
    /// Offsets: `purch-key` 0, `purch-name` 9.
    pub fn from_bytes(bytes: &[u8; PURCHASE_RECORD_BYTES]) -> Self {
        Self {
            key: bytes[0..7].try_into().expect("7 key bytes"),
            name: bytes[9..39].try_into().expect("30 name bytes"),
        }
    }
}

/// What the report needs from the environment.
#[derive(Debug, Clone)]
pub struct ProofContext {
    /// `usera` — the second heading line's left column.
    pub user: String,
    /// `to-day`, already converted to the print form by `zz070`.
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International. Anything else reads as UK.
    pub date_form: u8,
    /// `page-lines` from the system record.
    pub page_lines: usize,
    /// `vat-rate (1..3)`, in hundredths.
    pub vat_rates: [i16; VAT_ROWS],
}

/// The records to proof, in file order, and the supplier rows to key into.
#[derive(Debug, Clone, Copy)]
pub struct Proof<'a> {
    pub records: &'a [InvoiceRow],
    pub suppliers: &'a [SupplierRow],
}

/// One `total-group` entry, for the three entries the report prints.
#[derive(Debug, Clone, Copy, Default)]
struct GroupTotals {
    deduct: Money,
    goods: Money,
    carriage: Money,
    net: Money,
    vat: Money,
    gross: Money,
    cvat: [Money; VAT_ROWS],
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct ProofReport {
    pub print: PrintFile,
    /// Header rows written.
    pub rows: usize,
    /// `88 purchase-missing` — a supplier key that missed the file.
    pub supplier_missing: bool,
    /// The walk never reached `main-end`: an analysis ran off the end of the
    /// records, after which the COBOL reads status 46 forever (Part 6). The
    /// spool stops where the analysis stopped.
    pub hung: bool,
}

impl ProofReport {
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

/// A print line, always a whole `print-record`: each line is built fresh, so
/// the bytes a shorter line does not reach stay blank.
#[derive(Debug, Clone)]
struct Line([u8; PRINT_RECORD_BYTES]);

impl Line {
    fn spaces() -> Self {
        Self([b' '; PRINT_RECORD_BYTES])
    }

    /// `put` takes the 1-based position the copybook uses and clips at the end.
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

/// `cr` edit at one of the program's widths: `integer_positions` counts the
/// `z` positions, the picture's own mandatory `9` follows them, and the
/// `CR`/spaces suffix is always two bytes.
fn edit_cr(cents: Money, integer_positions: usize) -> String {
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

/// A day number into the print form, `maps04` included: a zero or negative day
/// prints spaces, a rejected date prints `00/00/0000` (F-B015 unchanged).
fn convert_date(day: i32, date_form: u8) -> String {
    if day <= 0 {
        return String::new();
    }
    let (year, month, dom) = CobolDate(day).to_ymd();
    if !(1..=9999).contains(&year) || !(1..=12).contains(&month) || !(1..=31).contains(&dom) {
        return String::from("00/00/0000");
    }
    match date_form {
        2 => format!("{month:02}/{dom:02}/{year:04}"),
        3 => format!("{year:04}/{month:02}/{dom:02}"),
        _ => format!("{dom:02}/{month:02}/{year:04}"),
    }
}

/// `zz070-Convert-Date` — the same round trip on `to-day`, already UK form.
pub fn convert_today(to_day: &str, date_form: u8) -> String {
    let bytes = to_day.as_bytes();
    if bytes.len() != 10 {
        return to_day.to_string();
    }
    let (days, month, year) = (&to_day[0..2], &to_day[3..5], &to_day[6..10]);
    match date_form {
        2 => format!("{month}/{days}/{year}"),
        3 => format!("{year}/{month}/{days}"),
        _ => to_day.to_string(),
    }
}

/// `line-1` — version, title, page number.
fn heading_1(page: usize) -> Line {
    let mut line = Line::spaces();
    line.put(1, "PL050 (3.01.04)");
    line.put(50, "Unapplied Purchase Transaction Report");
    line.put(125, "Page ");
    line.put(130, edit_suppressed(page as u32, 3));
    line
}

/// `line-2` — user and report date.
fn heading_2(context: &ProofContext) -> Line {
    let mut line = Line::spaces();
    line.put(1, context.user.as_str());
    line.put(123, context.report_date.as_str());
    line
}

/// `line-4` — the column banner, byte for byte.
fn heading_4() -> Line {
    let mut line = Line::spaces();
    line.put(
        1,
        " Number  ---Date--- <------------Supplier------------>    --Type--",
    );
    line.put(
        71,
        "     Goods                 <---Net-->  <---Vat-->  <--Gross-> ",
    );
    line
}

/// `line-7` — the totals banner.
fn heading_7() -> Line {
    let mut line = Line::spaces();
    line.put(
        37,
        "Goods    Carriage         Net         Vat       Gross  Prompt Pay ",
    );
    line
}

/// `line-9` — the reconciliation banner.
fn heading_9() -> Line {
    let mut line = Line::spaces();
    line.put(
        1,
        "V.A.T. Reconciliation       Receipts       Invoices   Credit Notes",
    );
    line
}

/// `line-5` — one invoice header. Fills the record exactly.
#[allow(clippy::too_many_arguments)]
fn row_5(
    header: &PurchaseHeader,
    name: &[u8],
    date: &[u8],
    kind: &str,
    goods: Money,
    net: Money,
    vat: Money,
    gross: Money,
) -> Line {
    let mut line = Line::spaces();
    line.put(1, format!("{} ", edit_suppressed(header.invoice_nos.0, 8)));
    line.put(10, date);
    line.put(21, header.supplier.0);
    // `l5-name` is `x(25)` and the supplier name is thirty bytes, so a long
    // name is clipped by the field and the marker columns stay blank beneath
    // it. Writing all thirty would bleed into `l5-marker` and `l5-type`.
    line.put(30, &name[..name.len().min(25)]);
    // `l5-marker` at 55 is never moved (Part 7).
    line.put(59, kind);
    line.put(73, edit_cr(goods, 6));
    line.put(97, edit_cr(net, 6));
    line.put(109, edit_cr(vat, 6));
    line.put(121, edit_cr(gross, 6));
    line
}

/// `line-a` — one analysis line, with or without its column labels.
fn line_a(labels: bool, code: &[u8], amount: Money, vat_code: u8) -> Line {
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

/// `line-b` — the prompt-pay row.
fn line_b(amount: Money) -> Line {
    let mut line = Line::spaces();
    line.put(47, "Prompt Pay  ");
    line.put(73, edit_cr(amount, 6));
    line
}

/// `line-d` — the carriage row, with its VAT flag at 96.
fn line_d(amount: Money, vat_flag: bool) -> Line {
    let mut line = Line::spaces();
    line.put(47, "Carriage    ");
    line.put(73, edit_cr(amount, 6));
    line.put(96, if vat_flag { "1" } else { "0" });
    line
}

/// `line-6` — one group's totals, the deduction column **last** (Part 1).
fn line_6(literal: &str, totals: &GroupTotals) -> Line {
    let mut line = Line::spaces();
    line.put(4, "    Total");
    // `move ws-lit (a) to l6-lit` is seventeen bytes into an eighteen-byte
    // field, so position 31 stays blank.
    line.put(14, format!("{literal:<17}"));
    line.put(32, edit_cr(totals.goods, 6));
    line.put(44, edit_cr(totals.carriage, 6));
    line.put(56, edit_cr(totals.net, 6));
    line.put(68, edit_cr(totals.vat, 6));
    line.put(80, edit_cr(totals.gross, 6));
    line.put(92, edit_cr(totals.deduct, 6));
    line
}

/// `line-8` — one VAT-code reconciliation row.
fn line_8(code: u8, rate: i16, groups: [Money; GROUPS]) -> Line {
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

/// The nibble at `index`, high nibble first.
fn nibble(bytes: &[u8], index: usize) -> u8 {
    let byte = bytes[index / 2];
    if index.is_multiple_of(2) {
        byte >> 4
    } else {
        byte & 0x0F
    }
}

/// The number a packed field holds, its sign nibble included.
fn packed(raw: &[u8]) -> Money {
    let mut magnitude: i64 = 0;
    for byte in raw.iter().take(raw.len() - 1) {
        magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
    }
    let last = raw[raw.len() - 1];
    magnitude = magnitude * 10 + i64::from(last >> 4);
    if matches!(last & 0x0F, 0x0D | 0x0B) {
        -magnitude
    } else {
        magnitude
    }
}

/// `pic s999v99 comp-3` — five digits, sign in the low nibble of the third byte.
fn pack_deduct(cents: Money) -> [u8; 3] {
    let mut digits = [0u8; 5];
    let mut magnitude = cents.unsigned_abs();
    for slot in digits.iter_mut().rev() {
        *slot = (magnitude % 10) as u8;
        magnitude /= 10;
    }
    let sign = if cents < 0 { 0x0D } else { 0x0C };
    [
        (digits[0] << 4) | digits[1],
        (digits[2] << 4) | digits[3],
        (digits[4] << 4) | sign,
    ]
}

/// The `total-ded (4)` store, which runs off the end of the table (Part 1).
///
/// The store is a six-byte packed field at `ws-deduct-amt`, so it overwrites
/// that field, `line-cnt`, and the first two bytes of `invoice-header`, where
/// `ih-invoice (1:2)` had just been copied. `ws-deduct-amt` keeps its sign
/// nibble in the middle of the wider field, where it reads as a digit of
/// twelve — measured: deduct `2.50` at `line-cnt` 30 stores
/// `00 25 12 24 55 3C`, so `line-cnt` becomes 36.
fn overrun(deduct: [u8; 3], line_cnt: u8, invoice_prefix: [u8; 2]) -> ([u8; 3], u8) {
    let mut field = [0u8; 6];
    field[..3].copy_from_slice(&deduct);
    field[3] = line_cnt;
    field[4..].copy_from_slice(&invoice_prefix);

    let mut magnitude: i64 = 0;
    for index in 0..11 {
        magnitude = magnitude * 10 + i64::from(nibble(&field, index));
    }
    let total = if matches!(nibble(&field, 11), 0x0D | 0x0B) {
        -magnitude
    } else {
        magnitude
    };
    let cents = total + packed(&deduct);

    let mut digits = [0u8; 11];
    let mut magnitude = cents.unsigned_abs();
    for slot in digits.iter_mut().rev() {
        *slot = (magnitude % 10) as u8;
        magnitude /= 10; // high overflow digits fall off the left
    }
    let sign = if cents < 0 { 0x0D } else { 0x0C };
    let mut out = [0u8; 6];
    for (index, byte) in out.iter_mut().enumerate() {
        let low = if index == 5 {
            sign
        } else {
            digits[index * 2 + 1]
        };
        *byte = (digits[index * 2] << 4) | low;
    }
    (out[..3].try_into().expect("3 bytes"), out[3])
}

/// The report under construction: the spool, the counters and the totals.
struct Sheet<'a> {
    print: PrintFile,
    context: &'a ProofContext,
    suppliers: &'a [SupplierRow],
    /// `j` — the page counter.
    page: usize,
    /// `line-cnt`, a signed byte.
    line_cnt: i16,
    rows: usize,
    supplier_missing: bool,
    /// `first-time` — labels the analysis columns once per header.
    first_time: bool,
    hung: bool,
    totals: [GroupTotals; GROUPS],
    /// `a` — the header's type byte, which is also its group.
    group: u8,
}

impl<'a> Sheet<'a> {
    fn new(context: &'a ProofContext, suppliers: &'a [SupplierRow]) -> Self {
        Self {
            print: PrintFile::new(),
            context,
            suppliers,
            page: 0,
            line_cnt: 0,
            rows: 0,
            supplier_missing: false,
            first_time: true,
            hung: false,
            totals: [GroupTotals::default(); GROUPS],
            group: 2,
        }
    }

    fn page_limit(&self) -> i16 {
        self.context.page_lines as i16
    }

    /// `main12` — the heading block's first half. A `perform` of a paragraph
    /// ends at the next paragraph header, so `perform main12 in headings` (what
    /// `main-end` does) gets these lines and *not* `cont-hds`. It leaves
    /// `line-cnt` alone; `cont-hds` is what resets it.
    fn main12(&mut self) {
        self.page += 1;
        let line1 = heading_1(self.page);
        if self.page != 1 {
            self.print.write_page(line1.bytes());
            self.print.write_after(heading_2(self.context).bytes(), 1);
            self.print.write_after(Line::spaces().bytes(), 1);
        } else {
            // Page one advances *before*, so the first record has no leading
            // blank and the two heading lines sit together.
            self.print.write_before(line1.bytes(), 1);
            self.print.write_before(heading_2(self.context).bytes(), 1);
        }
    }

    /// `headings` — `main12` and, because the section runs on from it,
    /// `cont-hds` too.
    fn headings(&mut self) {
        self.main12();
        self.print.write_after(heading_4().bytes(), 1);
        self.print.write_after(Line::spaces().bytes(), 1);
        self.line_cnt = 5;
    }

    fn write_row(&mut self, line: &Line) {
        self.print.write_after(line.bytes(), 1);
        self.line_cnt += 1;
    }

    /// One header's row plus its analysis and deduction blocks.
    fn header_row(
        &mut self,
        header: &PurchaseHeader,
        raw: &[u8; ACAS_INVOICE_RECORD_BYTES],
        records: &[InvoiceRow],
        cursor: &mut usize,
    ) {
        // `move ih-supplier to purch-key`, then the keyed read. A miss prints
        // the literal and raises the flag nothing clears (Part 5).
        let name: &[u8] = match self
            .suppliers
            .iter()
            .find(|row| row.key == header.supplier.0)
        {
            Some(row) => &row.name,
            None => {
                self.supplier_missing = true;
                b"Supplier Unknown"
            }
        };

        let figures = header.figures.map(|figure| figure.cents());
        let [_, mut net, _, mut carriage, mut vat, _, _, mut c_vat] = figures;
        let mut deduct = Money::from(header.deduct_amt.hundredths());
        if header.invoice_type.is_credit() {
            net = -net;
            carriage = -carriage;
            vat = -vat;
            c_vat = -c_vat;
        }
        if header.invoice_type.is_invoice() {
            deduct = -deduct;
        }
        let goods = net;
        let vat_sum = vat + c_vat;
        let net_sum = net + carriage;
        let gross = vat_sum + net_sum;

        // `if ws-deduct-amt = zero` blanks the row, so only a non-zero amount
        // builds one; the same for carriage.
        let prompt_pay = (deduct != 0).then_some(deduct);
        let carriage_row = (carriage != 0).then_some((carriage, c_vat != 0));

        // `move ih-type to a` — the stored byte is a character, the subscript
        // is the digit it carries.
        self.group = header.invoice_type.0.wrapping_sub(b'0');
        let kind = match self.group {
            1 => "Receipt",
            2 => "Invoice",
            _ => "Cr. Note",
        };

        // `add ih-c-vat to total-cvat (a, 1)` and the rest of the totals.
        // Beyond entry three these stores walk into the working storage that
        // follows the table; of all of them only `total-ded (4)` is observable,
        // and only through `line-cnt`.
        let entry = usize::from(self.group).saturating_sub(1);
        if entry < GROUPS {
            let group = &mut self.totals[entry];
            group.cvat[0] += c_vat;
            group.goods += goods;
            group.deduct += deduct;
            group.carriage += carriage;
            group.vat += vat_sum;
            group.net += net_sum;
            group.gross += gross;
        } else if WS_GROUP_OFFSET + entry * GROUP_ENTRY_BYTES == WS_DEDUCT {
            // A type past four stores further into the header overlay, which
            // is re-read before anything looks at it, so it is invisible.
            let (_, line_cnt) = overrun(pack_deduct(deduct), self.line_cnt as u8, [raw[0], raw[1]]);
            self.line_cnt = i16::from(line_cnt as i8);
        }

        if self.line_cnt > self.page_limit() {
            self.headings();
        }
        let mut date = convert_date(header.date.0, self.context.date_form);
        if date.len() < 11 {
            date.push_str(&" ".repeat(11 - date.len()));
        }
        let row = row_5(
            header,
            name,
            date.as_bytes(),
            kind,
            goods,
            net_sum,
            vat_sum,
            gross,
        );
        self.print.write_after(row.bytes(), 2);
        self.line_cnt += 2;
        self.rows += 1;

        self.first_time = true;
        // `perform analysis-print ih-lines times` and `perform extra-analysis`.
        self.analysis(header, records, cursor);
        self.extra(prompt_pay, carriage_row);
    }

    /// `analysis-print` — up to `ih-lines` rows, abandoned at a comment line.
    fn analysis(&mut self, header: &PurchaseHeader, records: &[InvoiceRow], cursor: &mut usize) {
        for _ in 0..header.lines {
            let Some(record) = records.get(*cursor) else {
                // After the first end of file every read answers status 46,
                // which nothing tests, so the walk never reaches `main-end`
                // (Part 6).
                self.hung = true;
                return;
            };
            *cursor += 1;
            let raw = record.to_bytes();
            // `move il-product (1) to test-product` / `if il-comment` — a
            // `go to main-exit`, so only this line is dropped: the next
            // `perform` iteration reads on. The column labels are still unset
            // for the header, because the skip never reaches them.
            if raw[9] == b'/' {
                continue;
            }
            // Through the twelve-byte overlay the two-byte code is disk 21..23
            // — the thirteenth product byte and the first `pa` byte (Part 2).
            let code = [raw[21], raw[22]];
            let credit = header.invoice_type.is_credit();
            let net = if credit {
                -packed(&raw[55..60])
            } else {
                packed(&raw[55..60])
            };
            let vat = if credit {
                -packed(&raw[67..72])
            } else {
                packed(&raw[67..72])
            };
            // `il-vat-code` is `pic 9`: a byte that is not a digit still moves
            // as a digit, one place (F-B016 Part 4).
            let raw_code = raw[72];
            let vat_code = if raw_code.is_ascii_digit() {
                raw_code - b'0'
            } else {
                raw_code % 10
            };
            let entry = usize::from(self.group).saturating_sub(1);
            if vat_code > 0 && usize::from(vat_code) <= VAT_ROWS && entry < GROUPS {
                self.totals[entry].cvat[usize::from(vat_code) - 1] += vat;
            }
            let labels = self.first_time;
            self.first_time = false;
            let row = line_a(labels, &code, net, vat_code);
            self.write_row(&row);
            if self.line_cnt > self.page_limit() {
                self.headings();
            }
        }
    }

    /// `extra-analysis` — the prompt-pay and carriage rows, each at most once
    /// per header because the field is cleared as the row is written.
    fn extra(&mut self, prompt_pay: Option<Money>, carriage: Option<(Money, bool)>) {
        if self.line_cnt > self.page_limit() - 2 {
            self.headings();
        }
        if let Some(amount) = prompt_pay {
            self.write_row(&line_b(amount));
        }
        if let Some((amount, flag)) = carriage {
            self.write_row(&line_d(amount, flag));
        }
    }

    /// `main-end` — the totals block, the warning and the reconciliation. It
    /// opens with `perform main12 in headings`, so it always starts a page —
    /// but only with `main12`, which is why the closing page has no column
    /// banner and `line_cnt` is left where the last row put it.
    fn finish(&mut self) {
        self.main12();
        self.print.write_after(heading_7().bytes(), 2);
        self.print.write_after(Line::spaces().bytes(), 1);
        for (index, literal) in GROUP_LITERALS.iter().enumerate() {
            let totals = self.totals[index];
            let line = line_6(literal, &totals);
            self.print.write_after(line.bytes(), 1);
            self.line_cnt += 1;
        }
        if self.supplier_missing {
            let mut line = Line::spaces();
            line.put(1, "Warning: Record/s missing in Purchase File");
            self.print.write_after(line.bytes(), 2);
        }
        self.print.write_after(heading_9().bytes(), 5);
        self.print.write_after(Line::spaces().bytes(), 1);
        for code in 1..=VAT_ROWS as u8 {
            let rate = self.context.vat_rates[usize::from(code) - 1];
            let groups =
                std::array::from_fn(|group| self.totals[group].cvat[usize::from(code) - 1]);
            let line = line_8(code, rate, groups);
            self.print.write_after(line.bytes(), 1);
            self.line_cnt += 1;
        }
    }
}

/// Run one proof through to its printed report.
pub fn run(proof: &Proof<'_>, context: &ProofContext) -> ProofReport {
    let mut sheet = Sheet::new(context, proof.suppliers);
    sheet.headings();
    let mut cursor = 0usize;
    while cursor < proof.records.len() {
        let record = &proof.records[cursor];
        cursor += 1;
        let raw = record.to_bytes();
        let InvoiceRow::Header(header) = record else {
            // `if ih-test not = zero go to loop`
            continue;
        };
        // `if applied go to loop`
        if header.status.is_applied() {
            continue;
        }
        // There is no proforma skip: type 4 prints and falls off the table.
        sheet.header_row(header, &raw, proof.records, &mut cursor);
    }
    if !sheet.hung {
        sheet.finish();
    }
    ProofReport {
        print: sheet.print,
        rows: sheet.rows,
        supplier_missing: sheet.supplier_missing,
        hung: sheet.hung,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::purchase_invoice::{CompAmount, InvoiceNumber, InvoiceType, SupplierKey};

    fn context() -> ProofContext {
        ProofContext {
            user: "Harness Test Co".into(),
            report_date: "04/11/2026".into(),
            date_form: 1,
            page_lines: 48,
            vat_rates: [0; 3],
        }
    }

    fn header(number: u32, kind: u8, lines: u8, deduct: u32) -> PurchaseHeader {
        PurchaseHeader {
            invoice_nos: InvoiceNumber(number),
            supplier: SupplierKey(*b"SUP001 "),
            date: CobolDate(155_535),
            order: *b"ORDER-0001",
            invoice_type: InvoiceType(kind),
            reference: *b"REF-000001",
            figures: [crate::purchase_invoice::PackedMoney::ZERO; 8],
            status: crate::purchase_invoice::HeaderStatus::Invoiced,
            lines,
            deduct_days: 0,
            deduct_amt: CompAmount::from_hundredths(deduct),
            deduct_vat: CompAmount::ZERO,
            days: 0,
            cr: CobolDate(0),
            day_book_flag: b' ',
            update: b' ',
            filler: [b' '; 30],
        }
    }

    fn supplier(name: &str) -> SupplierRow {
        let mut row = SupplierRow {
            key: *b"SUP001 ",
            name: [b' '; 30],
        };
        row.name[..name.len()].copy_from_slice(name.as_bytes());
        row
    }

    fn run_rows(records: &[InvoiceRow], suppliers: &[SupplierRow]) -> ProofReport {
        run(&Proof { records, suppliers }, &context())
    }

    #[test]
    fn the_out_of_range_store_carries_the_line_counter_measured() {
        // Measured under the probe: deduct 2.50 with `line-cnt` already 30
        // leaves `00 25 12 24 55 3C`, i.e. a counter of 36.
        let (field, line_cnt) = overrun(pack_deduct(250), 30, *b"00");
        assert_eq!(field, [0x00, 0x25, 0x12]);
        assert_eq!(line_cnt, 0x24);
    }

    #[test]
    fn a_zero_deduction_leaves_the_counter_on_its_own_nibbles() {
        // Adding nothing round-trips the field, so the counter's nibble pair is
        // preserved and the value is unchanged (measured: 19 stays 19).
        let (field, line_cnt) = overrun(pack_deduct(0), 19, *b"00");
        assert_eq!(field, [0x00, 0x00, 0x12]);
        assert_eq!(line_cnt, 19);
    }

    #[test]
    fn packed_money_reads_and_writes_its_sign() {
        assert_eq!(packed(&pack_deduct(250)), 250);
        assert_eq!(packed(&pack_deduct(-4_050)), -4_050);
    }

    #[test]
    fn the_report_date_follows_the_configured_form() {
        assert_eq!(convert_today("04/11/2026", 0), "04/11/2026");
        assert_eq!(convert_today("04/11/2026", 2), "11/04/2026");
        assert_eq!(convert_today("04/11/2026", 3), "2026/11/04");
    }

    #[test]
    fn an_applied_header_is_skipped_without_a_row() {
        let mut applied = header(1, b'2', 0, 0);
        applied.status = crate::purchase_invoice::HeaderStatus::Applied(b'z');
        let records = vec![
            InvoiceRow::Header(applied),
            InvoiceRow::Header(header(2, b'1', 0, 0)),
        ];
        let report = run_rows(&records, &[supplier("Alpha")]);
        assert_eq!(report.rows, 1);
    }

    #[test]
    fn a_thirty_byte_supplier_name_is_clipped_by_l5_name() {
        // `purch-name` is thirty bytes, `l5-name` is twenty-five, so the move
        // clips: the four marker columns stay blank and the type column keeps
        // its text. (A 30-byte write would run from 30 to 59 and eat both.)
        let mut long = SupplierRow {
            key: *b"SUP001 ",
            name: [b'x'; 30],
        };
        long.name[..5].copy_from_slice(b"Alpha");
        let records = vec![InvoiceRow::Header(header(1, b'1', 0, 0))];
        let report = run_rows(&records, &[long]);
        let text = report.into_bytes();
        // A record is not newline-terminated here: the `after 2` advance sits on
        // the *next* write, and a page break starts with the form feed, so the
        // row runs on into them. Take one record from the row's own start.
        let start = text
            .windows(9)
            .position(|window| window == b"       1 ")
            .expect("the header row");
        let row = &text[start..start + PRINT_RECORD_BYTES];
        let clipped: Vec<u8> = b"Alphaxxxxxxxxxxxxxxxxxxxx".to_vec();
        assert_eq!(&row[29..54], clipped.as_slice(), "clipped at twenty-five bytes");
        assert_eq!(&row[54..58], b"    ", "the marker columns stay blank");
        assert_eq!(&row[58..62], b"Rece", "the type column is intact");
    }

    #[test]
    fn a_comment_line_drops_only_its_own_analysis_row() {
        let mut comment = [b' '; ACAS_INVOICE_RECORD_BYTES];
        comment[0..8].copy_from_slice(b"00000001");
        comment[8] = 1;
        comment[9] = b'/';
        let records = vec![
            InvoiceRow::Header(header(1, b'1', 2, 0)),
            InvoiceRow::Line(crate::purchase_invoice::PurchaseLine::from_bytes(&comment)),
        ];
        // Two declared lines, one record: the first is the comment and is
        // dropped, the second read runs off the end and the walk hangs.
        let report = run_rows(&records, &[supplier("Alpha")]);
        assert!(report.hung, "the over-declared line count runs off the end");
        let text = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        assert!(!text.contains("V.A.T. Reconciliation"), "no totals block");
    }

    #[test]
    fn a_header_read_as_a_line_takes_its_code_from_the_order_tail() {
        // `move invoice-record to invoice-line (1)` copies by position, so the
        // two-byte code of a header is `ih-order (2:2)` (F-B050 Part 2).
        let mut stray = header(9, b'1', 0, 0);
        stray.order = *b"ORDER-XY00";
        let records = vec![
            InvoiceRow::Header(header(1, b'1', 1, 0)),
            InvoiceRow::Header(stray.clone()),
        ];
        // The analysis consumes the second header as a line; the main loop then
        // reads end of file and reaches the totals, so nothing hangs.
        let report = run_rows(&records, &[supplier("Alpha")]);
        assert!(!report.hung);
        let text = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        let row = text
            .lines()
            .find(|line| line.contains("Analysis"))
            .expect("an analysis row");
        assert_eq!(&row[58..60], "RD", "the code is the order tail");
    }
}
