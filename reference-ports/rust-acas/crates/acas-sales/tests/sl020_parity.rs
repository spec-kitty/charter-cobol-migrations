//! sl020 sales-ledger-enquiry parity against the COBOL goldens.
//!
//! Each case replays one entry of `harness/scenarios/sl020_enquiry.py`: the
//! COBOL was driven through the real sales menu, keyed with a customer, printed
//! and the whole 80-byte-record `prt-1` spool — header block, item rows, page
//! mechanics and ageing totals — is compared byte for byte.
//!
//! The goldens were captured on 2026-11-03 against the seeded `system.dat`
//! (user `Harness Test Co`, `sl-delim = '\'`, `date-form 1`) with
//! `s-flag-i` set for every case but `no-work-file`.
//!
//! `no-match` is the enquiry's oddest case and is reproduced literally: a
//! failed keyed `start` returns status 23, and the following `read` answers 46
//! without transferring a record. `sl020` never tests that status on the sales
//! file, so the body runs against the record area, whose key bytes the caller
//! has just overwritten with the customer. Name and address are the initial
//! NULs (F-B015 Part 8); the item loop does test its own status, so it stops
//! after zero rows.

use acas_sales::invoice::InvoiceHeader;
use acas_sales::ledger_enquiry::{build_work_file, run, Enquiry, ReportContext};
use acas_sales::post::{SalesRow, SALES_RECORD_BYTES};
use acas_sales::posting::OpenItem2;
use std::path::{Path, PathBuf};

const OPEN_ITEM_ROW: usize = 114;
const INVOICE_ROW: usize = 134;
const RUN_DATE: &str = "03/11/2026";

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(name: &str) -> Vec<u8> {
    std::fs::read(fixtures().join("generated/sl020-enquiry").join(name)).unwrap()
}

fn sales_rows() -> Vec<SalesRow> {
    generated("sales.flat")
        .chunks(SALES_RECORD_BYTES)
        .map(|chunk| SalesRow::from_bytes(chunk.try_into().expect("whole 300-byte record")))
        .collect()
}

fn items() -> Vec<OpenItem2> {
    generated("openitm3.flat")
        .chunks(OPEN_ITEM_ROW)
        .map(|chunk| OpenItem2::from_bytes(chunk).expect("whole 114-byte open item"))
        .collect()
}

fn invoices() -> Vec<InvoiceHeader> {
    generated("invoice.flat")
        .chunks(INVOICE_ROW)
        .map(|chunk| InvoiceHeader::from_bytes(chunk).expect("whole 134-byte header"))
        .collect()
}

fn row(customer: &str) -> SalesRow {
    sales_rows()
        .into_iter()
        .find(|row| row.key.0 == key7(customer))
        .unwrap_or_else(|| panic!("no sales row for {customer}"))
}

fn customer_items(customer: &str) -> Vec<OpenItem2> {
    items()
        .into_iter()
        .filter(|item| item.customer.0 == key7(customer))
        .collect()
}

/// The record area after a failed keyed read: NULs but for the key the caller
/// has just `move`d in (F-B015 Part 8).
fn phantom_row(customer: &str) -> SalesRow {
    let mut record = [0u8; SALES_RECORD_BYTES];
    let key = customer.as_bytes();
    record[..key.len()].copy_from_slice(key);
    record[key.len()] = b' ';
    SalesRow::from_bytes(record)
}

fn context() -> ReportContext {
    ReportContext {
        report_date: RUN_DATE.into(),
        date_form: 1,
        run_date: acas_common::cobol_date::CobolDate::new(2026, 11, 3).unwrap().0,
        page_lines: 48,
        sl_delim: b'\\',
    }
}

fn golden(case: &str) -> Vec<u8> {
    let path = fixtures().join("golden/sl020").join(case).join("prt-1");
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn replay(customer: &str, work_file: bool) {
    let phantom = customer == "ZZZZZZ";
    let enquiry = Enquiry {
        customer: key7(customer),
        sales: if phantom { phantom_row(customer) } else { row(customer) },
        items: if phantom { Vec::new() } else { customer_items(customer) },
        work: if work_file { build_work_file(&invoices()) } else { Vec::new() },
    };
    let produced = run(&enquiry, &context()).into_bytes();
    let label = if !work_file {
        "no-work-file"
    } else if phantom {
        "no-match"
    } else {
        customer
    };
    let expected = golden(label);
    assert_eq!(produced.len(), expected.len(), "{customer}: spool length");
    assert_eq!(produced, expected, "{customer}: spool bytes");
}

#[test]
fn every_enquiry_reproduces_the_cobol_spool_file() {
    replay("CUST011", true);
    replay("CUST022", true);
    replay("CUST033", true);
    replay("ZZZZZZ", true);
    replay("CUST011", false);
}

#[test]
fn the_unposted_column_only_carries_a_work_file() {
    let with = |work_file: bool| {
        let enquiry = Enquiry {
            customer: *b"CUST011",
            sales: row("CUST011"),
            items: customer_items("CUST011"),
            work: if work_file { build_work_file(&invoices()) } else { Vec::new() },
        };
        String::from_utf8_lossy(&run(&enquiry, &context()).into_bytes()).into_owned()
    };
    assert!(with(true).contains("*Unposted      698.25*"));
    assert!(with(false).contains("*Unposted        0.00*"));
}

#[test]
fn a_payment_row_prints_a_blank_number_and_ages_nothing() {
    let text = String::from_utf8_lossy(&golden("CUST011")).into_owned();
    assert!(text.contains(" Payment "));
    // The payment's own balance and invoiced figures are both zeroed.
    assert!(text.contains("Payment                     0.00       500.00         0.00"));
}

#[test]
fn dump_for_debugging() {
    for customer in ["CUST011", "CUST022", "CUST033"] {
        let enquiry = Enquiry {
            customer: key7(customer),
            sales: row(customer),
            items: customer_items(customer),
            work: build_work_file(&invoices()),
        };
        std::fs::write(format!("/tmp/sl020_{customer}.bin"), run(&enquiry, &context()).into_bytes())
            .unwrap();
    }
}

/// A 7-byte customer key.
fn key7(customer: &str) -> [u8; 7] {
    let mut key = [b' '; 7];
    let bytes = customer.as_bytes();
    key[..bytes.len()].copy_from_slice(bytes);
    key
}
