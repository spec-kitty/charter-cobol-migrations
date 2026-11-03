//! SL170 — Customer File Dump.
//!
//! Ported from `sales/sl170.cbl`. A selection screen (the ten fields of
//! `display-03`) filters the sales ledger and dumps every surviving customer as
//! a fixed two-column block; a page break lands every fourth customer.
//!
//! Layout, print mechanics and the carried fossils are measured in
//! `docs/fd-evidence/F-B012-sl170-file-dump.md`; the field-by-field
//! dispositions are in `docs/disposition-sl170.md`.
//!
//! ## The run, in COBOL order
//!
//! 1. `report-selection` — `open input sales-file` *before* the screen, so a
//!    missing file fails before the operator ever sees the selection.
//! 2. `report-heading-setup` — build the `Report On :` text from the
//!    selection, one operand at a time.
//! 3. `produce-report` — page 1 heading, an optional keyed `read`, then the
//!    sequential loop over the rest of the file: status filter, key filter,
//!    numeric filters, `listing`, page break every fourth customer.
//! 4. `end-report` — the report is spooled only when at least one customer was
//!    listed.
//!
//! ## The fossils, on purpose
//!
//! - A keyed `read` *prints nothing*: control falls straight into
//!   `read-loop`, so the record the failed read lands on is the one the next
//!   `read next` yields. `cust-in` is six characters and the key is seven, so
//!   the space-padded key can never hit exactly — every keyed run is an
//!   invalid-key run that still prints.
//! - `inspect customer-in replacing all space by "Z"` turns the padded key into
//!   a comparison probe that sorts after every real key with the same prefix.
//!   Only the six typed positions are compared (`until y > 6`), so the check
//!   digit is never part of the match.
//! - The overdue test sits *inside* its gate (`sales-current > 0.00`), so a
//!   customer with a zero or negative balance is listed however few days it is
//!   overdue, while a positive balance must clear the band to appear.
//! - `listing` subtracts `sales-unapplied` from `sales-current` in place, so
//!   the dump shows a balance the file itself does not hold.
//! - `sales-last-inv` / `sales-last-pay` are `binary-long`; an untouched field
//!   holds spaces (`0x20202020`), which is not zero, so the `= zero` guard
//!   misses and `maps04` renders `00/00/0000`.
//! - An untouched `pic 9` field (the delivery tag) prints as the space it
//!   holds, and an untouched `pic 99` credit prints `     .00` — GnuCOBOL does
//!   not turn either blank into a zero.
//! - The address legend is built by stringing one entry at a time and stepping
//!   the pointer back two (`subtract 2 from p`) before the next, so the comma
//!   replaces each `". "` instead of following it.
//! - `a` is the page counter and doubles as an error flag on an invalid keyed
//!   read.
//!
//! ## Type mapping
//!
//! - `sales-key` — `[u8; 7]`, compared and printed as bytes
//! - `sales-credit` — `[u8; 2]` display digits, edited through a 2-decimal
//!   picture (so `30` prints as `30.00`)
//! - `sales-discount` (`99v99`), `sales-late-min/max` (`binary-short`),
//!   `sales-limit` … `sales-create-date` (`binary-long`) — native integers,
//!   edited as above
//! - `sales-current`, `sales-last`, `turnover-q*`, `sales-unapplied` —
//!   `comp-3` money, reached through [`Wide::cents`]

use acas_common::cobol_date::CobolDate;

use crate::post::SalesRow;
use crate::report::{
    edit_blankable_money, edit_money_cr, edit_number, edit_suppressed, PrintFile, Record,
    PRINT_RECORD,
};

/// `display-03`'s ten fields, as values.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Selection {
    /// `cust-in` — six characters (the check digit is not entered here).
    pub customer: [u8; 6],
    /// `status-in` — `b'L'`, `b'D'` or a space for all.
    pub status: u8,
    pub credit: NumFilter,
    pub invoice: NumFilter,
    pub average: NumFilter,
    pub overdue: NumFilter,
}

impl Default for Selection {
    fn default() -> Self {
        Self {
            customer: [b' '; 6],
            status: b' ',
            credit: NumFilter::default(),
            invoice: NumFilter::default(),
            average: NumFilter::default(),
            overdue: NumFilter::default(),
        }
    }
}

/// One `[value] [operator]` pair. `operator` is `b'L'`, `b'G'`, `b'E'` or a
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

    /// `test-num` — sets `truth` from one comparison.
    fn accepts(self, field: i64) -> bool {
        let operand = i64::from(self.value);
        match self.operator {
            b'L' => field < operand,
            b'G' => field > operand,
            b'E' => field == operand,
            _ => true,
        }
    }
}

/// What the report needs from the environment. `user` is the `usera` the
/// heading prints, `date_form` comes from the system record, and `run_date` is
/// the start-of-day date the overdue band subtracts from.
#[derive(Debug, Clone)]
pub struct DumpContext {
    pub user: String,
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International. Anything else reads as UK.
    pub date_form: u8,
    pub run_date: CobolDate,
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct DumpReport {
    pub print: PrintFile,
    /// `rec-cnt` — the number of customers listed.
    pub listed: usize,
    /// `a > 0` from an invalid keyed read; the page counter carries it.
    pub invalid_key: bool,
}

impl DumpReport {
    /// `if rec-cnt not = 0 call "SYSTEM" using print-report`.
    pub fn spool(&self) -> bool {
        self.listed != 0
    }

    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

/// `l3-report` accumulates one operand per filter, separated by the blank the
/// COBOL leaves behind: every `add 1 to y` steps the `string` pointer over one
/// position, so the gap survives even when the segment between two of them is
/// empty.
fn heading(selection: &Selection) -> String {
    // The "All"/"Matched" test is over the raw selection, before any operand.
    let all = selection.status == b' '
        && !selection.credit.is_set()
        && !selection.invoice.is_set()
        && !selection.average.is_set()
        && !selection.overdue.is_set()
        && selection.customer == [b' '; 6];
    let mut text = String::from(if all { "All" } else { "Matched" });

    text.push(' ');
    if selection.status == b'L' {
        text.push_str("Live");
    }
    if selection.status == b'D' {
        text.push_str("Dormant");
    }

    text.push(' ');
    let credit = selection.credit;
    if credit.is_set() {
        text.push_str(operand(credit));
        text.push_str(&edit_suppressed(credit.value, 2));
        text.push_str(" Days Credit");
    }

    text.push(' ');
    let invoice = selection.invoice;
    if invoice.is_set() {
        text.push_str(operand(invoice));
        text.push_str(&edit_suppressed(invoice.value, 5));
        text.push_str(" Invoices");
    }

    text.push(' ');
    let average = selection.average;
    if average.is_set() {
        text.push_str(operand(average));
        text.push_str(&edit_suppressed(average.value, 5));
        text.push_str(" Av. Value");
    }

    text.push(' ');
    let overdue = selection.overdue;
    if overdue.is_set() {
        text.push_str(operand(overdue));
        text.push_str(&edit_suppressed(overdue.value, 5));
        text.push_str(" Days Overdue");
    }

    text.push(' ');
    if selection.customer != [b' '; 6] {
        text.push_str(" Keys Matching - ");
        text.push_str(&String::from_utf8_lossy(&selection.customer));
    }
    text
}

/// The two-character operand column of a heading (`cr-operand` and friends).
fn operand(filter: NumFilter) -> &'static str {
    match filter.operator {
        b'L' => "< ",
        b'G' => "> ",
        b'E' => "= ",
        _ => "",
    }
}

/// The comparison probe: the six typed characters, a pad, and every space
/// replaced by `Z`.
fn probe(selection: &Selection) -> [u8; 7] {
    let mut key = [b' '; 7];
    key[..6].copy_from_slice(&selection.customer);
    for byte in &mut key {
        if *byte == b' ' {
            *byte = b'Z';
        }
    }
    key
}

/// `zz060-Convert-Date` — `binary-long` day number to the screen date form.
///
/// A zero value prints spaces; a value `maps04` rejects prints `00/00/0000`.
fn convert_date(day: i32, date_form: u8) -> String {
    if day == 0 {
        return String::new();
    }
    // `maps04`'s `ws-unpack` starts from this literal and only overwrites the
    // parts `date-of-integer` can fill; an unrepresentable value leaves it.
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

fn page_heading(page: usize) -> Record {
    let mut record = Record::spaces();
    record.put(1, b"SL170 (3.01.07)");
    record.put(58, b"Sales Ledger Dump");
    record.put(125, b"Page ");
    record.put(130, edit_suppressed(page as u32, 3).as_bytes());
    record
}

fn report_heading(text: &str, context: &DumpContext) -> Record {
    let mut record = Record::spaces();
    record.put(1, context.user.as_bytes());
    record.put(41, b"Report On : ");
    record.put(53, text.as_bytes());
    record.put(123, context.report_date.as_bytes());
    record
}

/// `line-5`: 40 spaces, `<`, fifty dashes, `>` — the rule between customers,
/// which starts at record column 41 and ends on column 92 of the 132-byte line.
const SEPARATOR: &str = "<-------------------------------------------------->";
/// One `line-4` block for a customer.
///
/// The block is a `line-4` *reused* between writes: `l4-name-3` and the
/// space-filled pieces therefore carry over from the line before, exactly as
/// the COBOL does. Only the pieces a `move` touches are rewritten.
struct Line4 {
    bytes: [u8; PRINT_RECORD],
}

impl Line4 {
    fn new() -> Self {
        Self {
            bytes: [b' '; PRINT_RECORD],
        }
    }

    /// `move value to <field>` — the field is space-filled to `width` first,
    /// exactly as COBOL does with a shorter sending item.
    fn put(&mut self, at: usize, width: usize, value: &[u8]) {
        for offset in 0..width {
            let byte = value.get(offset).copied().unwrap_or(b' ');
            if let Some(slot) = self.bytes.get_mut(at - 1 + offset) {
                *slot = byte;
            }
        }
    }

    fn as_bytes(&self) -> &[u8; PRINT_RECORD] {
        &self.bytes
    }
}

fn write_block(print: &mut PrintFile, line4: &mut Line4, row: &SalesRow, context: &DumpContext) {
    // Field map from the copybook: name-1 1..14, value-1 15..70, name-2
    // 71..86, value-2 87..100 (`z(7)9.99bbb` — three literal blanks), of which
    // d-filler 87..89 and date 90..100 are the redefine, name-3 101..118,
    // value-3 119..131.
    line4.put(1, 14, b"Sales-Key");
    line4.put(15, 56, &row.key.0);
    line4.put(71, 16, b"Sales-Credit");
    line4.put(87, 14, edit_blankable_money(&row.credit).as_bytes());
    line4.put(101, 18, b"Sales-Current");
    let current = row.current.cents() - row.unapplied.cents();
    line4.put(119, 13, edit_money_cr(current).as_bytes());
    print.write_after(line4.as_bytes(), 2);

    line4.put(1, 14, b"Sales-Name");
    line4.put(15, 56, &row.name);
    line4.put(71, 16, b"Sales-Discount");
    line4.put(87, 14, edit_number(i64::from(row.discount), 2).as_bytes());
    line4.put(101, 18, b"Sales-Last");
    line4.put(119, 13, edit_money_cr(row.last.cents()).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Addr1");
    line4.put(15, 56, &row.addr1);
    line4.put(71, 16, b"Sales-Late-Min");
    line4.put(87, 14, edit_number(i64::from(row.late_min), 0).as_bytes());
    line4.put(101, 18, b"Turnover-Q1");
    line4.put(119, 13, edit_money_cr(row.turnover[0].cents()).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Addr2");
    line4.put(15, 56, &row.addr2);
    line4.put(71, 16, b"Sales-Late-Max");
    line4.put(87, 14, edit_number(i64::from(row.late_max), 0).as_bytes());
    line4.put(101, 18, b"Turnover-Q2");
    line4.put(119, 13, edit_money_cr(row.turnover[1].cents()).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Phone");
    line4.put(15, 56, &row.phone);
    line4.put(71, 16, b"Sales-Limit");
    line4.put(87, 14, edit_number(i64::from(row.limit), 0).as_bytes());
    line4.put(101, 18, b"Turnover-Q3");
    line4.put(119, 13, edit_money_cr(row.turnover[2].cents()).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Delivery-Tag");
    // A `pic 9` holding a space displays as that space, not as a digit.
    line4.put(15, 56, &[tag_char(row.delivery_tag)]);
    line4.put(71, 16, b"Sales-Activety");
    line4.put(87, 14, edit_number(i64::from(row.activety), 0).as_bytes());
    line4.put(101, 18, b"Turnover-Q4");
    line4.put(119, 13, edit_money_cr(row.turnover[3].cents()).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Notes Tag");
    line4.put(15, 56, &[tag_char(row.notes_tag)]);
    line4.put(71, 16, b"");
    line4.put(87, 14, b"");
    // Name-3 keeps whatever the previous line put there.
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Status");
    line4.put(15, 56, if row.status == 1 { b"Live" } else { b"Dead" });
    line4.put(71, 16, b"Sales-Last-Inv");
    line4.put(87, 14, b"");
    line4.put(90, 11, convert_date(row.last_inv, context.date_form).as_bytes());
    // `move spaces to l4-name-3 l4-filler` — the third column is *cleared*
    // here (`l4-filler` is the whole 13-byte redefine), so this line and every
    // one after it print a blank right-hand column.
    line4.put(101, 18, b"");
    line4.put(119, 13, b"");
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Late");
    line4.put(15, 56, if row.late == 1 { b"Yes" } else { b"No" });
    line4.put(71, 16, b"Sales-Last-Pay");
    line4.put(90, 11, convert_date(row.last_pay, context.date_form).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    line4.put(1, 14, b"Sales-Dunning");
    line4.put(15, 56, if row.dunning == 1 { b"Yes" } else { b"No" });
    line4.put(71, 16, b"Sales-Average");
    line4.put(87, 14, edit_number(i64::from(row.average), 0).as_bytes());
    print.write_after(line4.as_bytes(), 1);

    if row.email != [b' '; 30] {
        // `string "Sales-Email   " delimited by size ... into line-4` — the
        // address stops at its first space.
        let mut emailed = String::from("Sales-Email   ");
        let address = String::from_utf8_lossy(&row.email);
        emailed.push_str(address.split(' ').next().unwrap_or(""));
        // The `Used by` legend only appears when an email switch is on, and the
        // `subtract 2 from p` trims the separator back before the comma.
        if row.email_invoice == 1 || row.email_statement == 1 || row.email_letters == 1 {
            emailed.push_str("  Used by ");
            if row.email_invoice == 1 {
                emailed.push_str("Invoicing. ");
            }
            if row.email_statement == 1 {
                if row.email_invoice == 1 {
                    // `subtract 2 from p` — the pointer steps back over the
                    // ". " left by the previous legend entry, so the comma
                    // replaces it instead of following it.
                    emailed.truncate(emailed.len().saturating_sub(2));
                    emailed.push_str(", Statements. ");
                } else {
                    emailed.push_str("Statements. ");
                }
            }
            if row.email_letters == 1 {
                if row.email_invoice == 1 || row.email_statement == 1 {
                    emailed.truncate(emailed.len().saturating_sub(2));
                    emailed.push_str(", Dunning. ");
                } else {
                    emailed.push_str("Dunning. ");
                }
            }
        }
        let mut record = Record::spaces();
        record.put(1, emailed.as_bytes());
        print.write_after(record.as_bytes(), 1);
    }
}

/// Produce the dump.
///
/// `rows` is the sales ledger in key order — the caller owns the read; this
/// kernel never touches storage.
pub fn run(rows: &[SalesRow], selection: &Selection, context: &DumpContext) -> DumpReport {
    let key = probe(selection);
    let keyed = selection.customer != [b' '; 6];

    let mut print = PrintFile::new();
    let mut line4 = Line4::new();
    let mut listed = 0usize;
    // `a` (the page counter) and `z` (customers on this page).
    let mut page = 0usize;
    let mut on_page = 0usize;

    // `move cust-in to sales-key` pads the six typed characters with the
    // space of the seven-byte key, and no key carries a space in position 7 —
    // so the exact keyed `read` below can never hit. It fails, moves 1 to `a`,
    // and leaves the file positioned at the first key greater than the padded
    // probe: the `read next` at the top of `read-loop` yields *that* record.
    let mut padded = [b' '; 7];
    padded[..6].copy_from_slice(&selection.customer);
    let exact = rows.iter().position(|row| row.key.0 == padded);
    let start = if keyed {
        match exact {
            // A hit is not listed either: control falls straight into
            // `read-loop`, whose `read next` steps past it.
            Some(at) => at + 1,
            None => rows.partition_point(|row| row.key.0 < padded),
        }
    } else {
        0
    };
    // Only a keyed run can hold an invalid key, and it always does when the
    // exact key is missing.
    let invalid_key = keyed && exact.is_none();

    page += 1;
    write_heading(&mut print, page, &heading(selection), context);

    for row in rows.iter().skip(start) {
        if selection.status == b'L' && row.status == 0 {
            continue;
        }
        if selection.status == b'D' && row.status == 1 {
            continue;
        }
        if keyed && row.key.0 > key {
            break;
        }
        // `perform test-array varying y from 1 by 1 until y > 6` — six
        // positions, so the seventh key byte (the check character, where the
        // `Z` pad sits) is never compared.
        if keyed && !(0..6).all(|at| key[at] == b'Z' || key[at] == row.key.0[at]) {
            continue;
        }
        let overdue = context.run_date.0 - row.last_inv;
        // The overdue test sits *inside* its gate:
        //   if overdue-op not = space and sales-current > 0.00
        //      ... perform test-num
        //      if a-false go to read-loop
        // so a record whose balance is zero or behind is listed whatever the
        // day count, and only a positive balance can exclude a customer. A
        // blank `comp-3` balance reads as the junk 2020202.02 and so counts as
        // positive (F-B010).
        let overdue_keeps = !selection.overdue.is_set()
            || row.current.cents() <= 0
            || selection.overdue.accepts(i64::from(overdue));
        let keep = selection.credit.accepts(i64::from(credit_value(row)))
            && selection.invoice.accepts(i64::from(row.activety))
            && selection.average.accepts(i64::from(row.average))
            && overdue_keeps;
        if !keep {
            continue;
        }

        write_block(&mut print, &mut line4, row, context);
        listed += 1;
        on_page += 1;
        if on_page > 3 {
            on_page = 0;
            page += 1;
            write_heading(&mut print, page, &heading(selection), context);
        } else {
            let mut separator = Record::spaces();
            separator.put(41, SEPARATOR.as_bytes());
            print.write_after(separator.as_bytes(), 1);
        }
    }

    DumpReport {
        print,
        listed,
        invalid_key,
    }
}

/// `headings-1` — page `page`, then `Report On :`.
///
/// Page 1 is written `before 1`; every later page ejects first, blank-fills a
/// record and advances it, then writes the heading `after 2`.
fn write_heading(print: &mut PrintFile, page: usize, text: &str, context: &DumpContext) {
    let line1 = page_heading(page);
    if page == 1 {
        print.write_before(line1.as_bytes(), 1);
    } else {
        print.write_page(line1.as_bytes());
        print.write_after(Record::spaces().as_bytes(), 1);
    }
    print.write_after(report_heading(text, context).as_bytes(), 2);
}

/// A `pic 9` read as a digit value, rendered back the way COBOL prints it.
///
/// A valid digit is its character; anything else (a space in an untouched
/// record) travels through the `wrapping_sub` in `SalesRow::from_bytes` as
/// `byte - b'0'` and prints as the original byte, which is what the COBOL
/// `move <pic 9> to <pic x>` hands the spool file.
fn tag_char(value: u8) -> u8 {
    if value <= 9 {
        b'0'.wrapping_add(value)
    } else {
        value.wrapping_add(b'0')
    }
}

/// `sales-credit` is `pic 99` display: blank digits read as zero.
fn credit_value(row: &SalesRow) -> u32 {
    String::from_utf8_lossy(&row.credit)
        .trim()
        .parse()
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::post::SALES_RECORD_BYTES;

    const RUN_DAY: i32 = 155_535;

    /// A row with just the fields the filters look at.
    fn row(key: &str, live: bool, balance_cents: Option<i64>, last_inv: i32) -> SalesRow {
        let mut record = [b' '; SALES_RECORD_BYTES];
        record[..key.len()].copy_from_slice(key.as_bytes());
        record[193] = if live { b'1' } else { b'0' };
        record[220..224].copy_from_slice(&last_inv.to_le_bytes());
        if let Some(cents) = balance_cents {
            // `s9(9)v99 comp-3`: eleven digits, then the `C` sign nibble.
            let digits = format!("{:011}", cents.unsigned_abs());
            for pair in 0..5 {
                let high = digits.as_bytes()[pair * 2] - b'0';
                let low = digits.as_bytes()[pair * 2 + 1] - b'0';
                record[248 + pair] = (high << 4) | low;
            }
            record[253] = ((digits.as_bytes()[10] - b'0') << 4)
                | if cents < 0 { 0x0D } else { 0x0C };
        }
        SalesRow::from_bytes(record)
    }

    fn context() -> DumpContext {
        DumpContext {
            user: "Harness Test Co".into(),
            report_date: "03/11/2026".into(),
            date_form: 1,
            run_date: CobolDate(RUN_DAY),
        }
    }

    fn keys_in(report: &DumpReport) -> Vec<String> {
        String::from_utf8_lossy(&report.print.clone().finish())
            .lines()
            .filter_map(|line| line.strip_prefix("Sales-Key     "))
            .map(|rest| rest.split(' ').next().unwrap_or("").to_string())
            .collect()
    }

    #[test]
    fn a_blank_tag_prints_as_the_blank_byte_it_is() {
        // `digit()` stores `byte - b'0'`, so a space comes back as 0xF0.
        assert_eq!(tag_char(0xF0), b' ');
        assert_eq!(tag_char(3), b'3');
    }

    #[test]
    fn a_keyed_run_starts_at_the_first_key_greater_than_the_probe() {
        let rows = vec![
            row("CUSTD10", true, Some(100), 0),
            row("CUSTD30", true, Some(100), 0),
            row("CUSTD40", true, Some(100), 0),
        ];
        let selection = Selection {
            customer: *b"CUSTD3",
            ..Selection::default()
        };
        let report = run(&rows, &selection, &context());
        // The six typed characters are compared; the seventh (check digit) is
        // not, so `CUSTD30` matches and `CUSTD40` ends the run.
        assert_eq!(keys_in(&report), ["CUSTD30"]);
        assert!(report.invalid_key, "the padded key never hits exactly");
    }

    #[test]
    fn a_keyed_run_still_lists_the_record_the_failed_read_points_at() {
        let rows = vec![row("CUSTD10", true, Some(100), 0), row("CUSTD20", true, Some(100), 0)];
        let selection = Selection {
            customer: *b"CUSTD2",
            ..Selection::default()
        };
        // `CUSTD20` is the first key greater than the padded probe, and the
        // `read next` at the top of the loop yields it.
        assert_eq!(keys_in(&run(&rows, &selection, &context())), ["CUSTD20"]);
    }

    #[test]
    fn the_overdue_gate_admits_zero_and_negative_balances() {
        // The `a-false` check lives inside the gate, so a record whose balance
        // is not positive is listed no matter how few days it is overdue.
        let rows = vec![
            row("CUSTD10", true, Some(0), RUN_DAY - 2),
            row("CUSTD20", true, Some(-123_456), RUN_DAY - 2),
            row("CUSTD30", true, Some(123_456), RUN_DAY - 2),
        ];
        let selection = Selection {
            overdue: NumFilter {
                operator: b'G',
                value: 100,
            },
            ..Selection::default()
        };
        assert_eq!(keys_in(&run(&rows, &selection, &context())), ["CUSTD10", "CUSTD20"]);
    }

    #[test]
    fn a_positive_balance_within_the_band_is_excluded() {
        let rows = vec![
            row("CUSTD10", true, Some(123_456), RUN_DAY - 2),
            row("CUSTD20", true, Some(123_456), RUN_DAY - 200),
        ];
        let selection = Selection {
            overdue: NumFilter {
                operator: b'G',
                value: 100,
            },
            ..Selection::default()
        };
        assert_eq!(keys_in(&run(&rows, &selection, &context())), ["CUSTD20"]);
    }
}
