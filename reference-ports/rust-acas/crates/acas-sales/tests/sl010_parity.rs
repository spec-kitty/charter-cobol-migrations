//! sl010 customer-report parity against the COBOL goldens.
//!
//! Each case replays one entry of `harness/scenarios/sl010_report.py`: the
//! COBOL was driven through its real menu and selection screen, and the whole
//! `prt-1` spool file — column banner, addresses, delivery blocks, notes lines
//! and both page ejects — is compared byte for byte.
//!
//! The goldens were captured on 2026-11-03 against a seeded `system.dat` with
//! `page-lines = 48`, `sl-delim = '\'` and the user `Harness Test Co`.

use acas_sales::customer_report::{run, DeliveryRow, NumFilter, ReportContext, Selection};
use acas_sales::SalesRow;
use std::path::{Path, PathBuf};

const FIXTURE_ROW: usize = 300;
const DELIVERY_ROW: usize = 134;
const RUN_DATE: &str = "03/11/2026";

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn sales_rows() -> Vec<SalesRow> {
    let bytes = std::fs::read(fixtures().join("generated/sl010-report/sales.flat")).unwrap();
    bytes
        .chunks(FIXTURE_ROW)
        .map(|chunk| SalesRow::from_bytes(chunk.try_into().expect("whole 300-byte record")))
        .collect()
}

fn delivery_rows() -> Vec<DeliveryRow> {
    let bytes = std::fs::read(fixtures().join("generated/sl010-report/delivery.flat")).unwrap();
    bytes
        .chunks(DELIVERY_ROW)
        .map(|chunk| DeliveryRow::from_raw(chunk.try_into().expect("whole 134-byte record")))
        .collect()
}

fn golden(case: &str) -> Vec<u8> {
    let path = fixtures().join("golden/sl010").join(case).join("prt-1");
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn context() -> ReportContext {
    ReportContext {
        user: "Harness Test Co".into(),
        report_date: RUN_DATE.into(),
        date_form: 1,
        run_date: 0,
        page_lines: 48,
        sl_delim: b'\\',
    }
}

/// `zz050-Validate-Date` for 01/11/2026, as a `binary-long` day number.
fn entry_day() -> i32 {
    acas_common::cobol_date::CobolDate::new(2026, 11, 1).unwrap().0
}

fn band(operator: u8, value: u32) -> NumFilter {
    NumFilter { operator, value }
}

fn case(name: &str) -> (Selection, &'static str) {
    let base = Selection::default();
    match name {
        "all" => (
            Selection {
                enter_date: *b"01/11/2026",
                enter_date_day: Some(entry_day()),
                ..base
            },
            "all",
        ),
        "key" => (
            Selection {
                customer: *b"CUSTS2",
                ..base
            },
            "key",
        ),
        "status-live" => (
            Selection {
                status: b'L',
                ..base
            },
            "status-live",
        ),
        "credit-over-20" => (
            Selection {
                credit: band(b'G', 20),
                ..base
            },
            "credit-over-20",
        ),
        "no-match" => (
            Selection {
                customer: *b"ZZZZZZ",
                ..base
            },
            "no-match",
        ),
        other => panic!("unknown case {other}"),
    }
}

fn replay(name: &str) {
    let (selection, label) = case(name);
    let report = run(&sales_rows(), &delivery_rows(), &selection, &context());
    let produced = report.into_bytes();
    let expected = golden(label);
    assert_eq!(produced.len(), expected.len(), "{name}: spool length");
    assert_eq!(produced, expected, "{name}: spool bytes");
}

#[test]
fn every_selection_reproduces_the_cobol_spool_file() {
    for name in ["all", "key", "status-live", "credit-over-20", "no-match"] {
        replay(name);
    }
}

#[test]
fn a_blank_entry_date_still_produces_the_report() {
    // `if enter-date-in = spaces go to main-end` is an `exit section`, so the
    // report runs on: only the date validation is skipped.
    let selection = Selection::default();
    let report = run(&sales_rows(), &delivery_rows(), &selection, &context());
    assert!(report.listed > 0);
    assert!(report.print_out);
}

#[test]
fn a_delivery_block_without_a_record_repeats_the_previous_address() {
    // CUSTS40 carries a delivery tag but no delivery record; the invalid read
    // leaves `deliv-address` holding CUSTS10's notes text.
    let (selection, _) = case("all");
    let report = run(&sales_rows(), &delivery_rows(), &selection, &context());
    let text = String::from_utf8_lossy(&report.into_bytes()).into_owned();
    assert!(text.contains("   Delivery Address Record Not Found"));
    assert!(text.contains("Deliver after 9am\\Ring the bell twice"));
}

#[test]
fn a_run_that_matches_nothing_writes_the_report_but_never_spools_it() {
    // `print-out` is set by `listing` alone; page 1 is still written.
    let (selection, _) = case("no-match");
    let report = run(&sales_rows(), &delivery_rows(), &selection, &context());
    assert_eq!(report.listed, 0);
    assert!(!report.print_out);
    assert!(!report.into_bytes().is_empty());
}

#[test]
fn dump_for_debugging() {
    for name in ["all", "credit-over-20"] {
        let (selection, _) = case(name);
        let report = run(&sales_rows(), &delivery_rows(), &selection, &context());
        std::fs::write(format!("/tmp/sl010_{name}.bin"), report.into_bytes()).unwrap();
    }
}
