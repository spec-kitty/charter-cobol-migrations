//! sl170 parity against the COBOL golden reports.
//!
//! Each case is one entry of `harness/scenarios/sl170_file_dump.py`: the same
//! selection, replayed against the same 300-byte rows the COBOL run was fed.
//! The report bytes are the whole artifact — headers, page ejects, the
//! truncated third column and the carried `l4-name-3` all have to match.
//!
//! The goldens were captured on 2026-11-03, so the run date (and with it the
//! `report_date` in the heading and the overdue deltas) is pinned here. Only
//! the `overdue-over-100` band depends on it, and by wide margins.

use acas_common::cobol_date::CobolDate;
use acas_sales::file_dump::{run, DumpContext, NumFilter, Selection};
use acas_sales::post::{SalesRow, SALES_RECORD_BYTES};
use std::path::{Path, PathBuf};

const RUN_DATE: i32 = 155_535; // 2026-11-03
const REPORT_DATE: &str = "03/11/2026";
const COMPANY: &str = "Harness Test Co";

fn golden_dir() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../fixtures/golden/sl170")
}

fn rows_from(bytes: &[u8]) -> Vec<SalesRow> {
    bytes
        .chunks(SALES_RECORD_BYTES)
        .map(|chunk| {
            let mut record = [b' '; SALES_RECORD_BYTES];
            record[..chunk.len()].copy_from_slice(chunk);
            SalesRow::from_bytes(record)
        })
        .collect()
}

fn context() -> DumpContext {
    DumpContext {
        user: COMPANY.to_string(),
        report_date: REPORT_DATE.to_string(),
        date_form: 1,
        run_date: CobolDate(RUN_DATE),
    }
}

fn keyed(customer: &str) -> Selection {
    let mut selection = Selection::default();
    let bytes = customer.as_bytes();
    selection.customer[..bytes.len()].copy_from_slice(bytes);
    selection
}

fn case(name: &str) -> Selection {
    match name {
        "all" => Selection::default(),
        "key" => keyed("CUSTD3"),
        "status-dormant" => Selection {
            status: b'D',
            ..Selection::default()
        },
        "credit-under-40" => Selection {
            credit: NumFilter {
                operator: b'L',
                value: 40,
            },
            ..Selection::default()
        },
        "credit-over-40" => Selection {
            credit: NumFilter {
                operator: b'G',
                value: 40,
            },
            ..Selection::default()
        },
        "activity-over-10" => Selection {
            invoice: NumFilter {
                operator: b'G',
                value: 10,
            },
            ..Selection::default()
        },
        "average-under-1000" => Selection {
            average: NumFilter {
                operator: b'L',
                value: 1000,
            },
            ..Selection::default()
        },
        "overdue-over-100" => Selection {
            overdue: NumFilter {
                operator: b'G',
                value: 100,
            },
            ..Selection::default()
        },
        "no-match" => keyed("ZZZZ"),
        other => panic!("no selection for {other}"),
    }
}

fn check(name: &str) {
    let dir = golden_dir().join(name);
    let input = std::fs::read(dir.join("input-sales.flat"))
        .unwrap_or_else(|error| panic!("{}: {error}", dir.display()));
    let expected = std::fs::read(dir.join("prt-1")).expect("golden report");

    let report = run(&rows_from(&input), &case(name), &context());
    let actual = report.into_bytes();

    let rendered = String::from_utf8_lossy(&actual);
    assert_eq!(
        actual.len(),
        expected.len(),
        "{name}: report length\n{rendered}"
    );
    for (index, (want, got)) in expected.iter().zip(actual.iter()).enumerate() {
        assert_eq!(
            want, got,
            "{name}: byte {index} differs\nwant {:?}\ngot  {:?}",
            &expected[index.saturating_sub(30)..(index + 30).min(expected.len())],
            &actual[index.saturating_sub(30)..(index + 30).min(actual.len())]
        );
    }
}

#[test]
fn every_case_matches_the_cobol_report() {
    for name in [
        "all",
        "key",
        "status-dormant",
        "credit-under-40",
        "credit-over-40",
        "activity-over-10",
        "average-under-1000",
        "overdue-over-100",
        "no-match",
    ] {
        check(name);
    }
}

#[test]
fn an_empty_selection_spools_the_whole_ledger() {
    let dir = golden_dir().join("all");
    let input = std::fs::read(dir.join("input-sales.flat")).unwrap();
    let report = run(&rows_from(&input), &Selection::default(), &context());
    assert_eq!(report.listed, 6);
    assert!(report.spool());
    assert!(!report.invalid_key);
}

#[test]
fn a_matching_key_lists_only_that_customer() {
    let dir = golden_dir().join("key");
    let input = std::fs::read(dir.join("input-sales.flat")).unwrap();
    let report = run(&rows_from(&input), &keyed("CUSTD3"), &context());
    assert_eq!(report.listed, 1);
}

#[test]
fn no_match_still_writes_headers_but_does_not_spool() {
    let dir = golden_dir().join("no-match");
    let input = std::fs::read(dir.join("input-sales.flat")).unwrap();
    let report = run(&rows_from(&input), &keyed("ZZZZ"), &context());
    assert_eq!(report.listed, 0);
    assert!(!report.spool());
    assert!(report.invalid_key);
}

#[test]
fn dump_all_outputs_for_inspection() {
    for name in ["all", "key", "status-dormant", "credit-under-40", "credit-over-40", "activity-over-10", "average-under-1000", "overdue-over-100", "no-match"] {
        let input = std::fs::read(golden_dir().join(name).join("input-sales.flat")).unwrap();
        let actual = run(&rows_from(&input), &case(name), &context()).into_bytes();
        std::fs::write(format!("/tmp/sl170-rust-{name}"), actual).unwrap();
    }
}
