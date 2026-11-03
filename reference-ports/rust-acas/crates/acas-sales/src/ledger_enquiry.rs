//! SL020 menu 3 — the sales-ledger enquiry.
//!
//! Ported from `sales/sl020.cbl`: `set-up-work-file`, `get-unposted`, the
//! `enquiry` body and `print-screen`. Pure kernel over the invoice file, the
//! open-item file, the sales row and the enquiry's own work-file rows; the
//! caller owns every read and the whole screen layer (WP12).
//!
//! Layout, the edit pictures and the fossils are measured in
//! `docs/fd-evidence/F-B015-sl020-ledger-enquiry.md`; every field of the four
//! records is dispositioned in `docs/disposition-sl020.md`.
//!
//! ## The fossils, on purpose
//!
//! - `set-up-work-file` only runs when the caller's `s-flag-i` is 1. Without
//!   it `work-file-data` stays `"N"`: no work file, no "Unposted" figure, no
//!   `start` on it.
//! - The work file keeps `s-flag-i`-gated rows of invoice headers only, and
//!   `ih-discount` is **added** to the total (it is already negative on disk).
//! - `amount-out` is only assigned for types 2 and 3, so every other type
//!   ages whatever the previous item left behind.
//! - `oi-paid` is negated for a credit note, so its balance is `legs + |paid|`.
//! - A payment (type 5/6) has its invoice set to zero before the row is
//!   written; `blank when zero` then prints eight spaces.
//! - Past 100 items the row counter sticks at 100, the description becomes
//!   `">> screen overflow <<"` and every further item overwrites row 100 while
//!   still ageing.
//! - `unstring ... count a pointer a` shares one field; the segments come out
//!   in order (Part 5) but a run of two delimiters yields an empty line, and a
//!   source with no delimiter left hands over the whole clipped remainder.
//! - A failed keyed start is status 23, and the sales read that follows is
//!   status 46 — not `at end`. The block prints from the record area as it
//!   stands, which on a fresh program is the key just `move`d in surrounded by
//!   NULs (Part 8). The caller supplies that phantom row; the item loop is
//!   empty because it does test its own status.
//! - `selprint.cob` leaves `organization line sequential` commented out, so the
//!   spool is a fixed-record file and every record is written at its full 80
//!   bytes — `line-20` and `line-21` carry their trailing spaces (Part 7).

use crate::invoice::{InvoiceHeader, InvoiceType};
use crate::posting::Money;
use crate::post::SalesRow;
use crate::posting::OpenItem2;
use crate::report::{edit_masked, edit_masked_blank_when_zero, edit_suppressed, PrintFile};

/// `01 print-record pic x(80)`.
pub const PRINT_RECORD_BYTES: usize = 80;

/// `l7-group occurs 100`.
const ROW_LIMIT: usize = 100;

/// `if l = 59 write print-record from line-0 after page`.
const PAGE_BREAK_ROW: usize = 59;

/// What the report needs from the environment.
#[derive(Debug, Clone)]
pub struct ReportContext {
    /// `to-day`, already converted to the system date form for `l0-date`.
    pub report_date: String,
    /// `date-form`: 1 UK, 2 USA, 3 International. Anything else reads as UK.
    pub date_form: u8,
    /// `run-date` — the day number the ageing subtracts. Not a wall clock: the
    /// run can be replayed against a captured one.
    pub run_date: i32,
    /// `page-lines` from the system record, for the caller's screen arithmetic.
    pub page_lines: usize,
    /// `sl-delim` — the address separator.
    pub sl_delim: u8,
}

/// One `work-file` row: `work-key` + `work-amount`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WorkRow {
    pub customer: [u8; 7],
    pub invoice: u32,
    pub amount: Money,
}

/// `set-up-work-file` — the rows the "Unposted" figure is summed from.
///
/// The caller has already dispatched headers from lines, so `ih-test = 0` is
/// satisfied by construction. The two real filters are preserved: an applied
/// header (`ih-status = "z"`, lower case only — the program does not use the
/// `ih-analyised` 88-level) and receipts/proformas (`ih-type = 1 or 4`) are
/// both skipped.
pub fn build_work_file(headers: &[InvoiceHeader]) -> Vec<WorkRow> {
    let mut rows = Vec::new();
    for header in headers {
        if header.status.to_cobol() == b'z' {
            continue;
        }
        match header.invoice_type {
            InvoiceType::Invoice | InvoiceType::Proforma => continue,
            _ => {}
        }
        let legs = header.figures[1].cents()
            + header.figures[2].cents()
            + header.figures[3].cents()
            + header.figures[5].cents()
            + header.figures[4].cents()
            + header.figures[7].cents()
            + header.figures[6].cents()
            + i64::from(header.deduct_amt.hundredths())
            + i64::from(header.deduct_vat.hundredths());
        let amount = if header.invoice_type == InvoiceType::CreditNote {
            -legs
        } else {
            legs
        };
        rows.push(WorkRow {
            customer: header.customer.0,
            invoice: header.invoice_nos.0,
            amount,
        });
    }
    rows
}

/// `get-unposted` — sum the work rows for one customer.
pub fn unposted(work: &[WorkRow], customer: &[u8; 7]) -> Money {
    work.iter()
        .filter(|row| row.customer == *customer)
        .map(|row| row.amount)
        .sum()
}

/// One completed enquiry: the customer row, its open items and the work rows.
#[derive(Debug, Clone)]
pub struct Enquiry {
    pub customer: [u8; 7],
    pub sales: SalesRow,
    pub items: Vec<OpenItem2>,
    pub work: Vec<WorkRow>,
}

/// One finished report.
#[derive(Debug, Clone)]
pub struct EnquiryReport {
    pub print: PrintFile,
    /// `a` — the number of open items shown (capped at 100).
    pub rows: usize,
    /// `bal-t` — total outstanding, the "Total O/S" column.
    pub total: Money,
    /// `bal-0`, `bal-30`, `bal-60`, `bal-90` in that order.
    pub buckets: [Money; 4],
}

impl EnquiryReport {
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

/// One 80-byte line under construction. `put` takes the 1-based position the
/// copybook uses.
#[derive(Debug, Clone)]
struct Line([u8; PRINT_RECORD_BYTES]);

impl Line {
    fn spaces() -> Self {
        Self([b' '; PRINT_RECORD_BYTES])
    }

    fn put(&mut self, position: usize, value: impl AsRef<[u8]>) {
        let start = position - 1;
        for (offset, byte) in value.as_ref().iter().enumerate() {
            match self.0.get_mut(start + offset) {
                Some(slot) => *slot = *byte,
                None => break,
            }
        }
    }

    /// `selprint.cob` leaves the organization clause commented out, so the
    /// spool is a fixed-record file and every record is written at its full
    /// 80 bytes — trailing spaces included (F-B015 Part 7).
    fn record(&self) -> &[u8] {
        &self.0
    }
}

/// `line-0` — version, title, run date.
fn heading_0(context: &ReportContext) -> Line {
    let mut line = Line::spaces();
    line.put(1, "SL020 (3.01.08)");
    line.put(31, "Sales Ledger Enquiry");
    line.put(71, context.report_date.as_str());
    line
}

/// `sales-address` (the full 96 bytes) unstrung four times on `sl-delim`.
///
/// The program shares one field between `count` and `pointer` (F-B015 Part 5),
/// so the four unstrings walk the address segment by segment instead of each
/// starting at 1. Two edges of that walk are measured in F-B015 Part 5 and
/// reproduced here: a delimiter sitting on the pointer yields an empty line and
/// moves the pointer by one; with no delimiter left the whole remainder is
/// moved (clipped at `address-line`'s 36 bytes) and the pointer lands one past
/// the end, where every later unstring moves spaces.
fn address_lines(row: &SalesRow, delim: u8) -> [[u8; 30]; 4] {
    let mut address = Vec::with_capacity(96);
    address.extend_from_slice(&row.addr1);
    address.extend_from_slice(&row.addr2);
    let mut pointer = 0usize;
    let mut lines = [[b' '; 30]; 4];
    for line in lines.iter_mut() {
        // `address-line` is `pic x(36)` and is space-filled before each
        // unstring; only its first 30 bytes reach `lN-address`.
        let mut segment = [b' '; 36];
        if pointer >= address.len() {
            // Past the end: spaces, pointer unchanged.
        } else if let Some(offset) = address[pointer..].iter().position(|byte| *byte == delim) {
            let end = pointer + offset;
            let take = (end - pointer).min(segment.len());
            segment[..take].copy_from_slice(&address[pointer..pointer + take]);
            pointer = end + 1;
        } else {
            let take = (address.len() - pointer).min(segment.len());
            segment[..take].copy_from_slice(&address[pointer..pointer + take]);
            pointer = address.len() + 1;
        }
        line.copy_from_slice(&segment[..30]);
    }
    lines
}

/// `zz060-Convert-Date` — `binary-long` day number into the screen date form.
///
/// A zero value prints spaces; a value `maps04` rejects prints `00/00/0000`.
fn convert_date(day: i32, date_form: u8) -> String {
    // `maps04` answers spaces for zero and for negative day numbers, so both
    // print as an empty date (measured, `/tmp/wpprobe/u/m4.cbl`).
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

/// `ws-desc` for one item — the description column's text.
fn description(item: &OpenItem2) -> Vec<u8> {
    let mut text = Vec::with_capacity(20);
    match item.invoice_type {
        b'1' => text.extend_from_slice(b"Receipt "),
        b'2' => {
            text.extend_from_slice(b"Goods - ");
            let stop = item
                .description
                .windows(2)
                .position(|pair| pair == b"  ")
                .unwrap_or(item.description.len());
            text.extend_from_slice(&item.description[..stop]);
        }
        b'3' => {
            text.extend_from_slice(b"CN.Re Inv -");
            text.extend_from_slice(edit_suppressed(item.cr.max(0) as u32, 8).as_bytes());
        }
        b'5' => text.extend_from_slice(b"Payment"),
        b'6' => text.extend_from_slice(b"Journal Payment"),
        _ => {}
    }
    text.truncate(20);
    text
}

/// `line-6` — the column banner.
fn headings_6() -> Line {
    let mut line = Line::spaces();
    line.put(2, "Number");
    line.put(14, "Date");
    line.put(24, "Description");
    line.put(47, "Invoiced");
    line.put(64, "Paid");
    line.put(74, "Balance");
    line
}

/// `line-20` / `line-21` — the totals block.
fn totals_20() -> Line {
    let mut line = Line::spaces();
    line.put(1, "Inv #");
    line.put(8, "Total O/S");
    line.put(28, "Current");
    line.put(46, "30");
    line.put(61, "60");
    line.put(75, "90+");
    line
}

fn totals_21(report: &EnquiryReport) -> Line {
    let mut line = Line::spaces();
    line.put(1, edit_suppressed(report.rows as u32, 3));
    line.put(6, edit_masked(report.total, "zz,zzz,zz9.99"));
    line.put(19, edit_masked(report.buckets[0], "zzzzzz,zzz,zz9.99"));
    line.put(36, edit_masked(report.buckets[1], "zzzz,zzz,zz9.99"));
    line.put(51, edit_masked(report.buckets[2], "zzzz,zzz,zz9.99"));
    line.put(66, edit_masked(report.buckets[3], "zzzz,zzz,zz9.99"));
    line
}

/// Run one enquiry through to its printed report.
pub fn run(enquiry: &Enquiry, context: &ReportContext) -> EnquiryReport {
    let sales = &enquiry.sales;
    let mut print = PrintFile::new();
    let mut buckets = [0 as Money; 4];
    let mut total = 0 as Money;

    let balance = sales.current.cents();
    let unapplied = sales.unapplied.cents();
    // `l3-ytd` is `z(7)9` — no decimals — so the `move` truncates the
    // hundredths the sum carries (F-B015 Part 4).
    let ytd: Money = sales.turnover.iter().map(|quarter| quarter.cents()).sum::<Money>() / 100;
    let limit = Money::from(sales.limit);
    let owed = unposted(&enquiry.work, &enquiry.customer);

    let mut head = Vec::with_capacity(6);
    let mut line = Line::spaces();
    line.put(1, "Customer:");
    line.put(11, sales.name);
    line.put(41, "*".repeat(40).as_str());
    head.push(line);

    let addresses = address_lines(sales, context.sl_delim);
    let mut line = Line::spaces();
    line.put(1, "Address :");
    line.put(11, addresses[0]);
    line.put(41, "* A/C Nos");
    line.put(51, enquiry.customer);
    line.put(59, "*Balance");
    line.put(70, edit_masked(balance, "zzzzzz9.99"));
    line.put(80, "*");
    head.push(line);

    let mut line = Line::spaces();
    line.put(11, addresses[1]);
    line.put(41, "* YTD");
    line.put(51, edit_masked(ytd, "zzzzzzz9"));
    line.put(59, "*Unapplied");
    line.put(70, edit_masked(unapplied, "zzzzzz9.99"));
    line.put(80, "*");
    head.push(line);

    let mut line = Line::spaces();
    line.put(11, addresses[2]);
    line.put(41, "* Credit");
    line.put(51, edit_masked(limit, "zzzzzzz9"));
    line.put(59, "*Unposted");
    line.put(70, edit_masked(owed, "zzzzzz9.99"));
    line.put(80, "*");
    head.push(line);

    let mut line = Line::spaces();
    line.put(11, addresses[3]);
    line.put(41, "*".repeat(40).as_str());
    head.push(line);

    head.push(headings_6());

    print.write_after(heading_0(context).record(), 1);
    for line in &head {
        print.write_after(line.record(), 1);
    }

    // `move spaces to line-7-19` — the rows are rebuilt per customer.
    let mut rows = vec![Line::spaces(); ROW_LIMIT];
    let mut count = 0usize;
    let mut amount_out: Money = 0;

    for item in &enquiry.items {
        count += 1;
        // `go to item-comp-1` after the overflow literal skips the number,
        // date, hold and description moves, so row 100 keeps whatever those
        // columns held (F-B015 Part 6). Everything below it still runs.
        let overflow = count > ROW_LIMIT;
        let row_number;
        if overflow {
            rows[ROW_LIMIT - 1].put(23, ">> screen overflow <<");
            count = ROW_LIMIT;
            row_number = ROW_LIMIT;
        } else {
            row_number = count;
        }

        let row = &mut rows[row_number - 1];
        if !overflow {
            let mut invoice = item.invoice.0;
            if item.invoice_type == b'5' || item.invoice_type == b'6' {
                invoice = 0;
            }
            row.put(1, edit_masked_blank_when_zero(i64::from(invoice), "zzzzzzz9"));
            let date = convert_date(item.date, context.date_form);
            row.put(12, &date);
            if item.hold_flag != b' ' {
                row.put(10, "Q");
            }
            let text = description(item);
            row.put(23, &text);
        }

        let inv_amount = item.net
            + item.extra
            + item.carriage
            + item.vat
            + item.discount
            + item.e_vat
            + Money::from(item.deduct_amt)
            + Money::from(item.deduct_vat)
            + item.c_vat;
        let paid = if item.invoice_type == b'3' {
            -item.paid
        } else {
            item.paid
        };
        let on_terms = item.invoice_type == b'2' || item.invoice_type == b'3';
        if on_terms {
            amount_out = inv_amount - paid;
        }

        if on_terms {
            row.put(68, edit_masked(amount_out, "zz,zzz,zz9.99"));
        }
        row.put(42, edit_masked(inv_amount, "zz,zzz,zz9.99"));
        row.put(55, edit_masked(paid, "zz,zzz,zz9.99"));

        if item.invoice_type == b'1' {
            row.put(55, edit_masked(inv_amount, "zz,zzz,zz9.99"));
            row.put(68, edit_masked(0, "zz,zzz,zz9.99"));
            continue;
        }
        if item.invoice_type == b'5' || item.invoice_type == b'6' {
            row.put(42, edit_masked(0, "zz,zzz,zz9.99"));
            row.put(68, edit_masked(0, "zz,zzz,zz9.99"));
            continue;
        }

        // `calc-age`
        let age = i64::from(context.run_date) - i64::from(item.date);
        let bucket = if age < 30 {
            0
        } else if age < 60 {
            1
        } else if age < 90 {
            2
        } else {
            3
        };
        buckets[bucket] += amount_out;
        total += amount_out;

    }

    for (index, row) in rows.iter().enumerate().take(count) {
        print.write_after(row.record(), 1);
        if index + 1 == PAGE_BREAK_ROW {
            print.write_page(heading_0(context).record());
            for line in &head {
                print.write_after(line.record(), 1);
            }
        }
    }

    let mut report = EnquiryReport {
        print,
        rows: count,
        total,
        buckets,
    };
    report.print.write_after(totals_20().record(), 2);
    let totals = totals_21(&report);
    report.print.write_after(totals.record(), 2);
    report
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::post::{SALES_RECORD_BYTES, Wide};

    const RUN_DAY: i32 = 155_535;

    fn row(key: &str) -> SalesRow {
        let mut record = [b' '; SALES_RECORD_BYTES];
        let bytes = key.as_bytes();
        record[..bytes.len()].copy_from_slice(bytes);
        record[7..37].copy_from_slice(&[b'N'; 30]);
        record[37..85].copy_from_slice(&[b'A'; 48]);
        record[85..133].copy_from_slice(&[b'B'; 48]);
        SalesRow::from_bytes(record)
    }

    fn key7(customer: &str) -> [u8; 7] {
        let mut key = [b' '; 7];
        let bytes = customer.as_bytes();
        key[..bytes.len()].copy_from_slice(bytes);
        key
    }

    fn item(kind: u8, invoice: u32, day: i32, net: i64, paid: i64) -> OpenItem2 {
        OpenItem2 {
            customer: crate::invoice::CustomerKey(key7("CUST011")),
            invoice: crate::invoice::InvoiceNumber(invoice),
            date: day,
            invoice_type: kind,
            description: *b"Widget                   ",
            hold_flag: b' ',
            unapl: b' ',
            p_c: 0,
            net,
            extra: 0,
            carriage: 0,
            vat: 0,
            discount: 0,
            e_vat: 0,
            c_vat: 0,
            paid,
            status: b'0',
            deduct_days: 0,
            deduct_amt: 0,
            deduct_vat: 0,
            days: 0,
            cr: 0,
            applied: b' ',
            date_cleared: 0,
        }
    }

    fn wide(cents: i64) -> Wide {
        Wide::ZERO.set(cents)
    }

    fn context() -> ReportContext {
        ReportContext {
            report_date: "03/11/2026".into(),
            date_form: 1,
            run_date: RUN_DAY,
            page_lines: 48,
            sl_delim: b'\\',
        }
    }

    fn enquiry(items: Vec<OpenItem2>) -> Enquiry {
        Enquiry {
            customer: key7("CUST011"),
            sales: row("CUST011"),
            items,
            work: Vec::new(),
        }
    }

    fn text(items: Vec<OpenItem2>) -> String {
        String::from_utf8_lossy(&run(&enquiry(items), &context()).into_bytes()).into_owned()
    }

    /// `set-up-work-file` keeps goods and credit notes, drops everything else.
    #[test]
    fn the_work_file_keeps_only_goods_and_credit_notes() {
        let fixture = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures");
        let raw = std::fs::read(fixture.join("generated/sl020-enquiry/invoice.flat")).unwrap();
        let headers: Vec<_> = raw
            .chunks(134)
            .map(|chunk| InvoiceHeader::from_bytes(chunk).expect("header"))
            .collect();
        let rows = build_work_file(&headers);
        // Four headers: 41, 42, 45 (credit note) and 51.
        assert_eq!(rows.len(), 4);
        assert_eq!(rows[2].invoice, 45);
        assert_eq!(rows[2].amount, 9900, "a credit note's total is negated");
        // `ih-discount` is added, not subtracted; on these rows it is zero.
        assert_eq!(rows[0].amount, 23500);
    }

    #[test]
    fn an_applied_header_never_reaches_the_work_file() {
        let fixture = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures");
        let raw = std::fs::read(fixture.join("generated/sl020-enquiry/invoice.flat")).unwrap();
        let mut chunk = raw[..134].to_vec();
        chunk[114] = b'z'; // ih-status already applied
        let header = InvoiceHeader::from_bytes(&chunk).unwrap();
        assert!(build_work_file(&[header]).is_empty());
    }

    #[test]
    fn the_unposted_sum_is_one_customer_only() {
        let work = vec![
            WorkRow { customer: key7("CUST011"), invoice: 1, amount: 100 },
            WorkRow { customer: key7("CUST011"), invoice: 2, amount: 250 },
            WorkRow { customer: key7("CUST022"), invoice: 3, amount: 400 },
        ];
        assert_eq!(unposted(&work, &key7("CUST011")), 350);
        assert_eq!(unposted(&work, &key7("CUST022")), 400);
    }

    /// Part 5 — the shared count/pointer field walks the address.
    #[test]
    fn the_address_unstring_walks_the_segments_and_stops_at_the_end() {
        let mut record = [b' '; SALES_RECORD_BYTES];
        record[37..56].copy_from_slice(b"12 Old Wharf\\Hull\\\\");
        record[85..95].copy_from_slice(b"Humberside");
        let row = SalesRow::from_bytes(record);
        let lines = address_lines(&row, b'\\');
        assert_eq!(&lines[0][..12], b"12 Old Wharf");
        assert_eq!(&lines[1][..4], b"Hull");
        assert_eq!(lines[2], [b' '; 30], "a delimiter on the pointer is empty");
        // The 4th unstring starts past the end: spaces, then the tail of the
        // 96-byte address at 30-char width (the `H` of Humberside at column 30).
        assert_eq!(lines[3][29], b'H');
    }

    #[test]
    fn an_address_without_a_delimiter_fills_one_line_and_stops() {
        let mut record = [b' '; SALES_RECORD_BYTES];
        record[37..85].copy_from_slice(&[b'X'; 48]);
        let row = SalesRow::from_bytes(record);
        let lines = address_lines(&row, b'\\');
        assert_eq!(lines[0], [b'X'; 30]);
        assert_eq!(lines[1], [b' '; 30]);
    }

    /// Part 4 — only types 2 and 3 assign `amount-out`; anything else that
    /// reaches `calc-age` ages whatever the previous item left behind.
    /// Payments and receipts exit through `bypass-ageing`; a proforma does not.
    #[test]
    fn a_proforma_row_ages_the_previous_amount() {
        let report = run(
            &enquiry(vec![
                item(b'2', 41, RUN_DAY - 5, 10000, 0),
                item(b'4', 44, RUN_DAY - 5, 3000, 0),
            ]),
            &context(),
        );
        assert_eq!(report.total, 20000, "the proforma re-adds the 100.00");
        assert_eq!(report.buckets[0], 20000);
    }

    #[test]
    fn a_payment_row_bypasses_the_ageing_it_would_have_carried() {
        let report = run(
            &enquiry(vec![
                item(b'2', 41, RUN_DAY - 5, 10000, 0),
                item(b'5', 0, RUN_DAY - 5, 0, 50000),
            ]),
            &context(),
        );
        assert_eq!(report.total, 10000);
    }

    #[test]
    fn a_credit_note_balance_is_legs_plus_its_paid_amount() {
        let report = run(&enquiry(vec![item(b'3', 45, RUN_DAY - 10, 12000, 2000)]), &context());
        assert_eq!(report.total, 14000);
        assert!(String::from_utf8_lossy(&report.into_bytes()).contains("CN.Re Inv -"));
    }

    #[test]
    fn a_payment_row_leaves_the_number_column_blank() {
        let produced = text(vec![item(b'5', 99, RUN_DAY - 1, 0, 50000)]);
        let row = produced.lines().find(|line| line.contains("Payment")).unwrap();
        assert_eq!(&row[..8], "        ", "eight spaces: `blank when zero`");
    }

    /// Part 6 — past 100 items the row counter sticks at 100, the number and
    /// description columns freeze, and every further item still ages.
    #[test]
    fn the_hundredth_row_absorbs_every_overflow_item() {
        let mut items: Vec<_> = (1..=100)
            .map(|n| item(b'2', n, RUN_DAY - 5, 1000, 0))
            .collect();
        items.push(item(b'2', 999, RUN_DAY - 5, 1000, 0));
        let report = run(&enquiry(items), &context());
        assert_eq!(report.rows, 100);
        assert_eq!(report.total, 101 * 1000);
        let produced = String::from_utf8_lossy(&report.into_bytes()).into_owned();
        // The literal is 21 bytes into a 19-byte field, so it clips its tail.
        assert!(produced.contains(">> screen overflow "));
        assert!(!produced.contains("999"), "the number column is frozen");
    }

    #[test]
    fn the_year_to_date_picture_has_no_decimals() {
        let mut sale = row("CUST011");
        sale.turnover = [wide(10000), wide(20000), wide(30000), wide(40000)];
        let report = run(
            &Enquiry { customer: key7("CUST011"), sales: sale, items: Vec::new(), work: Vec::new() },
            &context(),
        );
        assert!(String::from_utf8_lossy(&report.into_bytes()).contains("* YTD         1000*"));
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
}
