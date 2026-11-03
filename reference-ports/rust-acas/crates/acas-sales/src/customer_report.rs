//! SL010 menu 4 — the customer listing.
//!
//! Ported from `sales/sl010.cbl` (`customer-input` … `main-end` of
//! `report-customer`, `report-selection`, `report-heading-setup`,
//! `produce-report`, `test-num`, `headings`, `listing`, `delivery-print`,
//! `notes-print`). Pure kernel over the sales ledger and the delivery file: the
//! caller owns both reads, this module owns the layout.
//!
//! The create/amend/delete/display functions of the same program are *not*
//! here — they are screen accept loops over `maps09` and belong to the screen
//! layer (WP12).
//!
//! Layout, print mechanics and the fossils are measured in
//! `docs/fd-evidence/F-B014-sl010-customer-report.md`; the field-by-field
//! dispositions are in `docs/disposition-sl010.md`.
//!
//! ## The run, in COBOL order
//!
//! 1. `report-selection` — the twelve selection fields; a blank entry date only
//!    skips its date validation (the section exits, the report does not).
//! 2. `report-heading-setup` — `Report On :` text, one operand at a time.
//! 3. `produce-report` — page 1, an optional keyed `start`, then the sequential
//!    loop: status filter, key filter, the four numeric bands, `listing`.
//! 4. `end-report` — the report is spooled only when a customer was listed.
//!
//! ## The fossils, on purpose
//!
//! - `headings` runs *before* any customer is read, so page 1 always exists,
//!   even for a selection that matches nothing.
//! - `listing` builds the customer row, then calls `headings` again mid-build
//!   when `line-cnt > Page-Lines - 5`. The row itself is not rebuilt: the page
//!   break lands between the build and the write, which is why a break can
//!   separate a customer's name row from nothing at all.
//! - `l6-charges` is `pic xb(4)` and `l6-letter` is `pic xbb`: the `B` inserts
//!   a blank *after* each character, the field is one byte wider than its base
//!   picture, and a value longer than one character is lost — `"ABCD"` prints
//!   `"A    "` (measured, probe `/tmp/wpprobe/d.cbl`).
//! - The delivery and notes reads reuse `deliv-address` in the file buffer. An
//!   invalid read leaves the previous record's text in it, so the delivery
//!   block of a customer whose delivery record is missing prints the *notes*
//!   text of the customer listed before it.
//! - `l6-phone` is built with `string sales-phone delimited by "  "` and then
//!   `subtract 1 from y`, which overwrites the last comment byte. The extension
//!   is appended with the same pointer, so a 13-character telephone loses its
//!   final digit to the `x`.
//! - The `All` / `Matched` heading test reads `customer-in`, an all-blank
//!   `pic x(7)` counts as present, so a wholly empty selection still reads
//!   `All` (measured; the golden says so).
//! - `sales-current` / `sales-last` are read but never printed: the listing has
//!   no balance column.


use crate::post::SalesRow;
use crate::report::{edit_suppressed, PrintFile, Record};

/// One customer's delivery-file record, keyed by `type + sales-key`.
#[derive(Debug, Clone)]
pub struct DeliveryRow {
    /// `D` — delivery address, `N` — notes.
    pub kind: u8,
    pub key: [u8; 7],
    pub name: [u8; 30],
    pub address: [u8; 96],
}

impl DeliveryRow {
    pub fn from_raw(record: &[u8; 134]) -> Self {
        let mut name = [b' '; 30];
        name.copy_from_slice(&record[8..38]);
        let mut address = [b' '; 96];
        address.copy_from_slice(&record[38..134]);
        let mut key = [b' '; 7];
        key.copy_from_slice(&record[1..8]);
        Self {
            kind: record[0],
            key,
            name,
            address,
        }
    }
}

/// One `[value] [operator]` band. `operator` is `b'L'`, `b'G'`, `b'E'` or a
/// space for "do not test".
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NumFilter {
    pub operator: u8,
    pub value: u32,
}

impl Default for NumFilter {
    fn default() -> Self {
        Self {
            operator: b' ',
            value: 0,
        }
    }
}

impl NumFilter {
    fn is_set(self) -> bool {
        self.operator != b' '
    }

    /// `test-num` — a blank operator accepts everything.
    fn accepts(self, field: i64) -> bool {
        compare(self.operator, field, i64::from(self.value))
    }
}

/// `display-03`'s twelve fields, as values.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Selection {
    /// `cust-in` — six characters; `sl010` accepts a seventh into
    /// `customer-in`, which stays blank here (the screen pads it).
    pub customer: [u8; 6],
    /// `status-in` — `b'L'`, `b'D'` or a space for all.
    pub status: u8,
    pub credit: NumFilter,
    pub invoice: NumFilter,
    pub average: NumFilter,
    pub overdue: NumFilter,
    /// `enter-date-in` — the raw ten characters, as typed.
    pub enter_date: [u8; 10],
    /// `enter-date-op`.
    pub enter_date_op: u8,
    /// `ws-enter-date` — the validated day number. `None` when the date screen
    /// was left blank, which skips the validation and leaves the field at zero.
    pub enter_date_day: Option<i32>,
}

impl Default for Selection {
    /// Every field blank — the state `report-selection` moves in before the
    /// screen is displayed.
    fn default() -> Self {
        Self {
            customer: [b' '; 6],
            status: b' ',
            credit: NumFilter::default(),
            invoice: NumFilter::default(),
            average: NumFilter::default(),
            overdue: NumFilter::default(),
            enter_date: [b' '; 10],
            enter_date_op: b' ',
            enter_date_day: None,
        }
    }
}

impl Selection {
    /// `if enter-date-in = spaces go to main-end`.
    ///
    /// `main-end` is an `exit section`, not an exit from the report: a blank
    /// entry date only skips `zz050-Validate-Date`, and `report-customer` goes
    /// on to build the heading and produce the report regardless.
    pub fn enter_date_is_blank(&self) -> bool {
        self.enter_date == [b' '; 10]
    }
}

/// What the report needs from the environment.
#[derive(Debug, Clone)]
pub struct ReportContext {
    /// `usera` — the first heading line's left column.
    pub user: String,
    /// The start-of-day date, already rendered in the ledger's date form.
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International.
    pub date_form: u8,
    /// `run-date` as a `binary-long` day number.
    pub run_date: i32,
    /// `page-lines` from the system record.
    pub page_lines: usize,
    /// `sl-delim` — the address separator the listing rewrites to a comma.
    pub sl_delim: u8,
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct CustomerReport {
    pub print: PrintFile,
    /// Customers listed.
    pub listed: usize,
    /// `print-out` — set only by `listing`, so a selection that matches nothing
    /// closes the spool file without ever handing it to the printer.
    pub print_out: bool,
}

impl CustomerReport {
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

fn operand(filter: NumFilter) -> &'static str {
    match filter.operator {
        b'L' => "< ",
        b'G' => "> ",
        b'E' => "= ",
        _ => "",
    }
}

/// `l3-report`, built one segment at a time.
///
/// Every `add 1 to y` steps the `string` pointer over one position, so the
/// blank it leaves survives even where the segment between two of them is
/// empty; the pointer starts at 2, hence the leading blank.
fn heading(selection: &Selection) -> String {
    let all = selection.status == b' '
        && !selection.credit.is_set()
        && !selection.invoice.is_set()
        && !selection.average.is_set()
        && !selection.overdue.is_set()
        && selection.customer == [b' '; 6];
    // The `string` pointer starts at 1 (`y` is zero here and the segment is
    // preceded by an `add 1 to y`), so the text starts flush at `l3-report`.
    let mut text = String::from(if all { "All" } else { "Matched" });

    text.push(' ');
    if selection.status == b'L' {
        text.push_str("Live");
    }
    if selection.status == b'D' {
        text.push_str("Dormant");
    }

    text.push(' ');
    if selection.credit.is_set() {
        text.push_str(operand(selection.credit));
        text.push_str(&edit_suppressed(selection.credit.value, 2));
        text.push_str(" Days Credit");
    }

    text.push(' ');
    if selection.invoice.is_set() {
        text.push_str(operand(selection.invoice));
        text.push_str(&edit_suppressed(selection.invoice.value, 5));
        text.push_str(" Invoices");
    }

    text.push(' ');
    if selection.average.is_set() {
        text.push_str(operand(selection.average));
        text.push_str(&edit_suppressed(selection.average.value, 5));
        text.push_str(" Av. Value");
    }

    text.push(' ');
    if selection.overdue.is_set() {
        text.push_str(operand(selection.overdue));
        text.push_str(&edit_suppressed(selection.overdue.value, 5));
        text.push_str(" Days Overdue");
    }

    text.push(' ');
    if selection.enter_date_op != b' ' {
        text.push_str(operand(NumFilter {
            operator: selection.enter_date_op,
            value: 0,
        }));
        text.push_str(&String::from_utf8_lossy(&selection.enter_date));
        text.push_str(" Entry Date");
    }

    text.push(' ');
    if selection.customer != [b' '; 6] {
        text.push_str(" Keys Matching - ");
        text.push_str(&String::from_utf8_lossy(&selection.customer));
    }
    text
}

fn page_heading(page: usize) -> Record {
    let mut record = Record::spaces();
    record.put(1, b"SL010 (3.01.20)");
    record.put(58, b"Customer Listing");
    record.put(125, b"Page ");
    record.put(130, edit_suppressed(page as u32, 3).as_bytes());
    record
}

fn report_heading(text: &str, context: &ReportContext) -> Record {
    let mut record = Record::spaces();
    record.put(1, context.user.as_bytes());
    record.put(41, b"Report On : ");
    // `l3-report` is `pic x(70)`: a longer STRING is cut at 70 and does not
    // reach into the date that follows.
    let clipped = &text.as_bytes()[..text.len().min(REPORT_TEXT)];
    record.put(53, clipped);
    record.put(123, context.report_date.as_bytes());
    record
}

/// Width of `l3-report`.
const REPORT_TEXT: usize = 70;

/// `line-4` — the column banner, byte for byte.
const COLUMN_BANNER: &str = concat!(
    "Customer  Status    <---------------Name & Address-------------->     ",
    "----Telephone---- -----Fax-----     Late       Credit",
);
/// `l6-key` for a delivery block.
const DELIVERY_LEGEND: &str = "   Deliver";
/// `l6-status` for a delivery block.
const DELIVERY_STATUS: &str = "y Address";

/// `pic z(6)9` — blank when zero.
fn edit_limit(value: i32) -> String {
    if value == 0 {
        return " ".repeat(7);
    }
    edit_suppressed(value.unsigned_abs(), 7)
}

/// `pic zzz9bbb` — blank when zero.
fn edit_credit(digits: &[u8; 2]) -> String {
    let value = String::from_utf8_lossy(digits).trim().parse::<u32>().unwrap_or(0);
    if value == 0 {
        return " ".repeat(7);
    }
    format!("{}   ", edit_suppressed(value, 4))
}

/// `pic z9.99` — blank when zero, value in hundredths.
fn edit_discount(hundredths: i16) -> String {
    if hundredths == 0 {
        return " ".repeat(5);
    }
    let cents = hundredths.unsigned_abs() as u32;
    format!(
        "{}.{:02}",
        edit_suppressed(cents / 100, 2),
        cents % 100
    )
}

/// The 132-byte customer row (`line-6`), with every field placed the way the
/// `move`s place it.
///
/// `charges` / `letter` are one character each; the `B` blanks are appended
/// after them.
fn line_6(row: &SalesRow, charges: u8, letter: u8) -> Record {
    let mut record = Record::spaces();
    record.put(1, &row.key.0);
    record.put(11, if row.status == 1 { b"Active" } else { b"Dormant" });
    record.put(21, &row.name);
    // `move sales-phone to l6-phone` is skipped when an extension exists.
    if row.ext == [b' '; 4] {
        record.put(71, &row.phone);
    } else {
        record.put(71, &phone_with_extension(row));
    }
    record.put(89, &row.fax);
    // `l6-charges pic xb(4)` / `l6-letter pic xbb`.
    record.put(106, &[charges]);
    record.put(111, &[letter]);
    record.put(114, edit_limit(row.limit).as_bytes());
    record.put(121, edit_credit(&row.credit).as_bytes());
    record.put(128, edit_discount(row.discount).as_bytes());
    record
}

/// `string sales-phone delimited by "  " into l6-phone with pointer y`,
/// `subtract 1 from y`, then `string "x" ... sales-ext ... with pointer y`.
fn phone_with_extension(row: &SalesRow) -> Vec<u8> {
    let phone = &row.phone;
    let stop = phone
        .windows(2)
        .position(|pair| pair == b"  ")
        .unwrap_or(phone.len());
    let mut out: Vec<u8> = phone[..stop].to_vec();
    // `subtract 1 from y` steps the pointer back over the byte the terminated
    // STRING left in place; with a full-width phone that is its last digit.
    out.pop();
    out.push(b'x');
    out.extend_from_slice(&row.ext);
    out
}

/// `line-7` — the address, with the delimiter rewritten to a comma.
fn line_7(address: &[u8], context: &ReportContext, replace: bool) -> Record {
    let mut record = Record::spaces();
    record.put(21, address);
    if replace {
        for byte in field_mut(&mut record, 21, address.len()) {
            if *byte == context.sl_delim {
                *byte = b',';
            }
        }
    }
    record
}

/// Read back `len` bytes of the record starting at 1-based `position`.
fn field_mut(record: &mut Record, position: usize, len: usize) -> &mut [u8] {
    let start = position - 1;
    &mut record.as_bytes_mut()[start..start + len]
}

/// The report under construction: the spool, the page/line counters and the
/// delivery-file record area the reads share.
struct Sheet<'a> {
    print: PrintFile,
    context: &'a ReportContext,
    heading: &'a str,
    /// `a` — the page counter.
    page: usize,
    /// `line-cnt`.
    line_cnt: usize,
    listed: usize,
    /// `deliv-address` as the reads leave it: GnuCOBOL zeroes an untouched FD
    /// record and an invalid key does not clear it, so later blocks can print an
    /// earlier record's bytes.
    deliv_address: [u8; 96],
}

impl<'a> Sheet<'a> {
    fn new(context: &'a ReportContext, heading: &'a str) -> Self {
        Self {
            print: PrintFile::new(),
            context,
            heading,
            page: 0,
            line_cnt: 0,
            listed: 0,
            deliv_address: [0u8; 96],
        }
    }

    /// `headings` — page `a`, the `Report On :` line and the two banners.
    fn headings(&mut self) {
        self.page += 1;
        let line1 = page_heading(self.page);
        // Page 1 advances `before 1` on both heading lines; a later page ejects
        // and advances `after 1`, which leaves the blank line the golden shows.
        if self.page != 1 {
            self.print.write_page(line1.as_bytes());
            self.print
                .write_after(report_heading(self.heading, self.context).as_bytes(), 1);
            // The blank record between the heading and the banner exists only
            // on an ejected page: the write is inside the `if`, not after it.
            self.print.write_after(Record::spaces().as_bytes(), 1);
        } else {
            self.print.write_before(line1.as_bytes(), 1);
            self.print
                .write_before(report_heading(self.heading, self.context).as_bytes(), 1);
        }
        let mut banner = Record::spaces();
        banner.put(1, COLUMN_BANNER.as_bytes());
        banner.put(128, b" Disc");
        self.print.write_after(banner.as_bytes(), 1);
        let mut units = Record::spaces();
        units.put(2, b"Number   ------");
        units.put(105, b"Chg  Let   Limit/Days    %");
        self.print.write_after(units.as_bytes(), 1);
        self.print.write_after(Record::spaces().as_bytes(), 1);
        self.line_cnt = 6;
    }

    /// `listing` — one customer block.
    fn listing(&mut self, row: &SalesRow, delivery: &[DeliveryRow]) {
        if self.line_cnt > self.context.page_lines {
            self.headings();
        }

        let charges = if row.late == 1 { b'Y' } else { b' ' };
        let letter = if row.dunning == 1 { b'Y' } else { b' ' };
        let row_record = line_6(row, charges, letter);
        let address = [row.addr1.as_slice(), row.addr2.as_slice()].concat();
        let address_record = line_7(&address, self.context, true);

        // The second break lands between the build and the write, so the record
        // that triggers it is not on the page its heading belongs to.
        if self.line_cnt > self.context.page_lines - 5 {
            self.headings();
        }

        self.print.write_after(row_record.as_bytes(), 1);
        self.print.write_after(address_record.as_bytes(), 1);
        self.listed += 1;

        if tag_set(row.delivery_tag) {
            self.delivery_print(row, delivery);
        }
        if tag_set(row.notes_tag) {
            self.notes_print(row, delivery);
        }

        self.print.write_after(Record::spaces().as_bytes(), 1);
        self.line_cnt += 3;
    }

    /// `delivery-print`.
    fn delivery_print(&mut self, row: &SalesRow, delivery: &[DeliveryRow]) {
        let found = delivery.iter().find(|d| d.kind == b'D' && d.key == row.key.0);
        let mut record = Record::spaces();
        record.put(1, DELIVERY_LEGEND.as_bytes());
        record.put(11, DELIVERY_STATUS.as_bytes());
        match found {
            Some(entry) => {
                record.put(21, &entry.name);
                self.deliv_address = entry.address;
                self.print.write_after(record.as_bytes(), 1);
                let address = line_7(&self.deliv_address, self.context, true);
                self.print.write_after(address.as_bytes(), 1);
            }
            None => {
                record.put(21, b"Record Not Found");
                self.print.write_after(record.as_bytes(), 1);
                // The invalid read leaves `deliv-address` untouched and the
                // `inspect` is gated on the name, so the stale bytes print raw.
                let address = line_7(&self.deliv_address, self.context, false);
                self.print.write_after(address.as_bytes(), 1);
            }
        }
        self.line_cnt += 2;
    }

    /// `notes-print`.
    fn notes_print(&mut self, row: &SalesRow, delivery: &[DeliveryRow]) {
        match delivery.iter().find(|d| d.kind == b'N' && d.key == row.key.0) {
            Some(entry) => self.deliv_address = entry.address,
            // `move "Record Not Found" to deliv-Address` — a COBOL MOVE also
            // space-fills the rest of the 96-byte field, which is what stops the
            // STRING at its terminating blank pair.
            None => {
                let mut text = [b' '; 96];
                text[..17].copy_from_slice(b"Record Not Found ");
                self.deliv_address = text;
            }
        }
        // `string "Notes: " delimited by size, deliv-address delimited by "  "`.
        let stop = self
            .deliv_address
            .windows(2)
            .position(|pair| pair == b"  ")
            .unwrap_or(self.deliv_address.len());
        let mut record = Record::spaces();
        record.put(21, b"Notes: ");
        record.put(28, &self.deliv_address[..stop]);
        self.print.write_after(record.as_bytes(), 1);
        self.line_cnt += 1;
    }
}

/// A `pic 9` tag: a blank (stored as `0xF0` by `digit()`) is not a zero flag
/// and not a set one either — GnuCOBOL reads it as zero.
fn tag_set(tag: u8) -> bool {
    tag != 0 && tag != 0xF0 && tag != b'0'
}

/// Produce the listing.
pub fn run(
    rows: &[SalesRow],
    delivery: &[DeliveryRow],
    selection: &Selection,
    context: &ReportContext,
) -> CustomerReport {
    let heading_text = heading(selection);
    let mut sheet = Sheet::new(context, &heading_text);
    sheet.headings();

    // A keyed run `start`s the file at the space-padded key (`key not <`), so
    // the first record read is the first key not below it. `customer-in` is
    // seven bytes and only six are typed, so the pad can never hit exactly —
    // every keyed run is an invalid-key start, and a start past the end is the
    // end of the report.
    let keyed = selection.customer != [b' '; 6];
    let mut padded = [b' '; 7];
    padded[..6].copy_from_slice(&selection.customer);
    // Then every space of the probe becomes `Z`: the stop test compares the six
    // typed positions against a probe that sorts after its own prefix.
    let mut stop = padded;
    for byte in &mut stop {
        if *byte == b' ' {
            *byte = b'Z';
        }
    }
    let start = if keyed {
        rows.partition_point(|row| row.key.0 < padded)
    } else {
        0
    };

    for row in rows.iter().skip(start) {
        if keyed && row.key.0 > stop {
            break;
        }
        if selection.status == b'L' && row.status != 1 {
            continue;
        }
        if selection.status == b'D' && row.status == 1 {
            continue;
        }
        if selection.credit.is_set() && !selection.credit.accepts(i64::from(credit_value(row))) {
            continue;
        }
        if selection.invoice.is_set() && !selection.invoice.accepts(i64::from(row.activety)) {
            continue;
        }
        if selection.average.is_set() && !selection.average.accepts(i64::from(row.average)) {
            continue;
        }
        // The overdue test sits inside its own gate: a balance that is not
        // positive is listed whatever the day count.
        if selection.overdue.is_set() && row.current.cents() > 0 {
            let overdue = context.run_date - row.last_inv;
            if !selection.overdue.accepts(i64::from(overdue)) {
                continue;
            }
        }
        if !entry_accepts(selection, row) {
            continue;
        }
        sheet.listing(row, delivery);
    }

    CustomerReport {
        print: sheet.print,
        print_out: sheet.listed != 0,
        listed: sheet.listed,
    }
}

/// `sales-credit` is `pic 99` display; blank digits read as zero.
fn credit_value(row: &SalesRow) -> u32 {
    String::from_utf8_lossy(&row.credit)
        .trim()
        .parse()
        .unwrap_or_default()
}

/// The entry-date band compares `ws-enter-date` (a `binary-long`, so the day
/// number) against `sales-create-date`.
fn entry_accepts(selection: &Selection, row: &SalesRow) -> bool {
    if selection.enter_date_op == b' ' {
        return true;
    }
    // A blank entry date never reaches `zz050-Validate-Date`, so
    // `ws-enter-date` keeps the zero it was moved at `report-selection`.
    let day = selection.enter_date_day.unwrap_or(0);
    compare(
        selection.enter_date_op,
        i64::from(row.create_date),
        i64::from(day),
    )
}

/// `test-num`'s one comparison, with the operands in COBOL's order
/// (`test-2` against `test-1`).
fn compare(operator: u8, field: i64, operand: i64) -> bool {
    match operator {
        b'L' => field < operand,
        b'G' => field > operand,
        b'E' => field == operand,
        _ => true,
    }
}


#[cfg(test)]
mod tests {
    use super::*;
    use crate::post::SALES_RECORD_BYTES;

    fn row(key: &str) -> SalesRow {
        let mut record = [b' '; SALES_RECORD_BYTES];
        record[..key.len()].copy_from_slice(key.as_bytes());
        record[193] = b'1';
        SalesRow::from_bytes(record)
    }

    fn context() -> ReportContext {
        ReportContext {
            user: "Harness Test Co".into(),
            report_date: "03/11/2026".into(),
            date_form: 1,
            run_date: 0,
            page_lines: 48,
            sl_delim: b'\\',
        }
    }

    #[test]
    fn the_blank_inserted_fields_are_one_character_wide() {
        // `pic xb(4)` is 5 bytes and `pic xbb` is 3: the `B` adds a blank after
        // the character, and a longer value is lost (probe d.cbl).
        let record = line_6(&row("CUSTS10"), b'Y', b'Y');
        // charges at 105 (then four blanks), letter at 110 (then two).
        assert_eq!(record.as_bytes()[105], b'Y');
        assert_eq!(&record.as_bytes()[106..110], b"    ");
        assert_eq!(record.as_bytes()[110], b'Y');
        assert_eq!(&record.as_bytes()[111..113], b"  ");
    }

    #[test]
    fn an_extension_loses_the_last_telephone_digit() {
        let mut record = [b' '; SALES_RECORD_BYTES];
        record[..7].copy_from_slice(b"CUSTS10");
        record[133..146].copy_from_slice(b"0123456789012");
        record[146..150].copy_from_slice(b"417 ");
        let phone = phone_with_extension(&SalesRow::from_bytes(record));
        // The phone is a full 13 characters, so `subtract 1 from y` overwrites
        // its final digit with the `x`.
        // `sales-ext` is `pic x(4)`, so its trailing blank is STRING-ed too.
        assert_eq!(phone, b"012345678901x417 ");
    }

    #[test]
    fn a_blank_tag_prints_no_block() {
        // `digit()` stores `byte - b'0'`, so an untouched `pic 9` comes back as
        // 0xF0 and GnuCOBOL compares it as a zero.
        assert_eq!(row("CUSTS10").delivery_tag, 0xF0);
        assert!(!tag_set(0xF0));
        assert!(tag_set(1));
        assert!(!tag_set(b'0'));
    }

    #[test]
    fn a_keyed_start_partitions_at_the_padded_probe() {
        let rows: Vec<SalesRow> = ["CUSTS10", "CUSTS20", "CUSTS30"]
            .iter()
            .map(|key| row(key))
            .collect();
        let selection = Selection {
            customer: *b"CUSTS2",
            ..Selection::default()
        };
        let report = run(&rows, &[], &selection, &context());
        let text = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        assert!(text.contains("CUSTS20"));
        assert!(!text.contains("CUSTS10"));
        assert!(!text.contains("CUSTS30"));
    }

    #[test]
    fn a_long_heading_is_cut_at_the_report_column() {
        let long: String = std::iter::repeat_n('x', 120).collect();
        let record = report_heading(&long, &context());
        assert_eq!(record.as_bytes()[52], b'x');
        assert_eq!(record.as_bytes()[121], b'x');
        // The date starts at 122 and is not overwritten by the overflow.
        assert_eq!(&record.as_bytes()[122..132], b"03/11/2026");
    }

    #[test]
    fn the_heading_reads_all_even_for_an_empty_selection() {
        // `and customer-in` on an all-blank `pic x(7)` tests true, so the
        // golden says `All` for a wholly empty selection.
        assert!(heading(&Selection::default()).starts_with("All"));
        let matched = Selection {
            status: b'L',
            ..Selection::default()
        };
        assert!(heading(&matched).starts_with("Matched"));
    }
}
