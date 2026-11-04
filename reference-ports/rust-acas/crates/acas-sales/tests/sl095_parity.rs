//! sl095 payment-proof-report parity against the COBOL golden.
//!
//! Each case replays `harness/scenarios/sl095_proof.py`. The COBOL was driven
//! through the real sales menu with `J`, after `sl090` had sorted the open
//! items; the sorted file is committed alongside the report so the kernel can
//! be fed the *exact* records COBOL read. Every spool byte is compared,
//! including the 265-byte page-break line of the `busy` case.
//!
//! `proof` was captured on 2026-11-03 and re-run twice with identical bytes
//! (`4dc5bb4c…`/`5d224fa3…`); `busy` likewise (`5de7231b…`/`fc65b75c…`). Both
//! are live captures.
//!
//! `no-flag` is the refusal: with `s-flag-p` clear neither program opens
//! anything, so no `prt-1` exists at all — not even an empty one.

use acas_sales::payment_proof_report::{
    run, Proof, ProofContext, ProofOutcome, OPEN_ITEM_BYTES,
};
use acas_sales::SalesRow;
use std::path::{Path, PathBuf};

/// The context the harness seed produces: a UK-dated 48-line report.
fn context() -> ProofContext {
    ProofContext {
        user: "Harness Test Co".into(),
        report_date: "03/11/2026".into(),
        date_form: 1,
        page_lines: 48,
    }
}

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures().join("generated").join(format!("sl095-{case}")).join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn golden(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures().join("golden").join("sl095").join(case).join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn records(case: &str) -> Vec<[u8; OPEN_ITEM_BYTES]> {
    golden(case, "oisort.wrk")
        .chunks(OPEN_ITEM_BYTES)
        .map(|chunk| chunk.try_into().expect("whole 114-byte open item"))
        .collect()
}

fn sales(case: &str) -> Vec<SalesRow> {
    generated(case, "sales.flat")
        .chunks(acas_sales::SALES_RECORD_BYTES)
        .map(|chunk| SalesRow::from_bytes(chunk.try_into().expect("whole 300-byte sales row")))
        .collect()
}

fn printed(outcome: ProofOutcome) -> Vec<u8> {
    match outcome {
        ProofOutcome::Printed(_, report) => report.into_bytes(),
        other => panic!("expected a report, got {other:?}"),
    }
}

#[test]
fn the_proof_report_reproduces_the_cobol_spool() {
    let rows = records("proof");
    let ledger = sales("proof");
    let produced = printed(run(1, 0, &Proof { records: &rows, sales: &ledger }, &context()));
    let expected = golden("proof", "prt-1");
    std::fs::write("/tmp/rust095.txt", &produced).ok();
    assert_eq!(produced.len(), expected.len(), "spool length");
    assert_eq!(produced, expected, "spool bytes");
}

#[test]
fn the_page_break_reproduces_the_cobol_overflow_line() {
    let rows = records("busy");
    let ledger = sales("busy");
    let produced = printed(run(1, 0, &Proof { records: &rows, sales: &ledger }, &context()));
    let expected = golden("busy", "prt-1");
    assert_eq!(produced, expected, "spool bytes");
    // The break is one row late, so the eject sits at the end of a row's line.
    assert_eq!(produced.iter().filter(|byte| **byte == 0x0C).count(), 1);
    assert!(
        produced.split(|byte| *byte == b'\n').any(|line| line.len() == 265),
        "the overflow line is row + form feed + the next page's title"
    );
}

#[test]
fn a_cleared_payment_flag_refuses_and_writes_no_report() {
    let rows = records("proof");
    let ledger = sales("proof");
    assert!(matches!(
        run(0, 0, &Proof { records: &rows, sales: &ledger }, &context()),
        ProofOutcome::Refused
    ));
    // The golden directory holds no prt-1 for `no-flag` by design.
    assert!(!fixtures().join("golden/sl095/no-flag/prt-1").exists());
}

#[test]
fn a_failed_open_leaves_the_flags_raised_but_no_report() {
    let rows = records("proof");
    let ledger = sales("proof");
    match run(1, 35, &Proof { records: &rows, sales: &ledger }, &context()) {
        ProofOutcome::NoInput(flags) => {
            assert_eq!(flags.oi_3_flag, b'Y');
            assert_eq!(flags.s_flag_p, 2);
        }
        other => panic!("expected NoInput, got {other:?}"),
    }
}
