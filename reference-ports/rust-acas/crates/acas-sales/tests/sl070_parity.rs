//! sl070 parity against the COBOL golden setup tables and reports.
//!
//! Both cases replay one entry of `harness/scenarios/sl070_pa_report.py`: the
//! COBOL wrote the sixteen standard codes through `p-a-setup`, then printed
//! them with menu 3 (`S` ledger only) or menu 4 (everything). The analysis
//! table, the value table and the whole report are compared byte for byte —
//! nothing here is sampled (F-B013).
//!
//! The goldens were captured on 2026-11-03 with the user `Harness Test Co` and
//! `Date-Form = 1`, so both are pinned.

use acas_sales::pa_report::{
    report, setup, ReportInputs, ValueRecord, ANALYSIS_RECORD_BYTES, VALUE_RECORD_BYTES,
};
use std::path::Path;

const RUN_DATE: &str = "03/11/2026";
const USER: &str = "Harness Test Co";
const VERSION: &str = "SL070 (3.01.11)";

fn read(case: &str, name: &str) -> Vec<u8> {
    let path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../fixtures/golden/sl070")
        .join(case)
        .join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

/// Split a flat stream into fixed-width records and sort by record bytes.
fn sorted<const N: usize>(bytes: &[u8]) -> Vec<[u8; N]> {
    let mut rows: Vec<[u8; N]> = bytes
        .chunks(N)
        .map(|chunk| {
            let mut record = [0u8; N];
            record[..chunk.len()].copy_from_slice(chunk);
            record
        })
        .collect();
    rows.sort_unstable();
    rows
}

fn golden_values(case: &str) -> Vec<ValueRecord> {
    read(case, "value.flat")
        .chunks(VALUE_RECORD_BYTES)
        .map(|chunk| ValueRecord::from_raw(chunk.try_into().expect("whole 66-byte record")))
        .collect()
}

fn run_case(case: &str, print_all: bool) {
    let produced = setup(&[]);

    // p-a-setup writes the analysis file in table order, the file holds it in
    // key order; both sides are sorted before the bytes are compared.
    let produced_analysis: Vec<u8> = produced.analysis.iter().flat_map(|row| row.raw()).collect();
    assert_eq!(produced_analysis.len(), ANALYSIS_RECORD_BYTES * 16);
    assert_eq!(
        sorted::<ANALYSIS_RECORD_BYTES>(&produced_analysis),
        sorted::<ANALYSIS_RECORD_BYTES>(&read(case, "analysis.flat")),
        "{case}: analysis table"
    );

    // An empty value file on entry means every code is minted.
    let produced_values: Vec<u8> = produced.value.iter().flat_map(|row| row.raw()).collect();
    assert_eq!(
        sorted::<VALUE_RECORD_BYTES>(&produced_values),
        sorted::<VALUE_RECORD_BYTES>(&read(case, "value.flat")),
        "{case}: value table"
    );

    // Re-running against an existing value file rewrites nothing.
    assert!(setup(&golden_values(case)).value.is_empty());

    // The report: rows in key order, exactly as the sequential read sees them.
    let mut rows = produced.analysis.clone();
    rows.sort();
    let outcome = report(&ReportInputs {
        rows: &rows,
        user: USER.as_bytes(),
        today: RUN_DATE.as_bytes(),
        date_form: 1,
        print_all,
        irs_used: false,
        version: VERSION.as_bytes(),
    });

    assert_eq!(outcome.spool, read(case, "prt-1"), "{case}: report bytes");
    assert!(outcome.warning, "{case}: every detail has a zero GL number");
}

#[test]
fn sales_ledger_report_matches_the_cobol() {
    run_case("system", false);
}

#[test]
fn print_all_report_matches_the_cobol() {
    run_case("all", true);
}
