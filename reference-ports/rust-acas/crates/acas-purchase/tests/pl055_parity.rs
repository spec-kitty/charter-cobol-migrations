//! pl055 extract parity against the COBOL goldens.
//!
//! Each case replays `harness/scenarios/pl055_extract.py`: the COBOL was driven
//! through the real purchase menu with `H`, and the four artifacts it leaves —
//! the rewritten invoice file, `openitm4.dat`, the value table and the analysis
//! table — are compared byte for byte, in key order.
//!
//! The goldens were captured on 2026-11-04 against the setup `system.dat` with
//! `p-flag-i` (byte 499) and both the invoice-file and value-file status bytes
//! seeded, and every case was re-run afterwards with identical bytes, so they
//! are live captures rather than hand-edited files.
//!
//! `empty` is the no-work case: pl055 still closes by writing the four bucket
//! rows, and the invoice file stays as it was.

use acas_purchase::extract::{extract, AnalysisRow, ExtractRun, ValueRow};
use acas_purchase::purchase_invoice::{
    InvoiceRow, ACAS_INVOICE_RECORD_BYTES, ANALYSIS_RECORD_BYTES, OPEN_ITEM4_RECORD_BYTES,
    VALUE_RECORD_BYTES,
};
use std::path::{Path, PathBuf};

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn input(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures()
        .join("generated")
        .join(format!("pl055-{case}"))
        .join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn golden(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures()
        .join("golden")
        .join("pl055")
        .join(case)
        .join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn rows(case: &str) -> Vec<InvoiceRow> {
    input(case, "pinvoice.flat")
        .chunks(ACAS_INVOICE_RECORD_BYTES)
        .map(|chunk| {
            let frame: [u8; ACAS_INVOICE_RECORD_BYTES] =
                chunk.try_into().expect("whole 129-byte invoice frame");
            InvoiceRow::from_bytes(&frame)
        })
        .collect()
}

/// One full run: the tables come off disk, `extract` walks the rows, `finish`
/// closes with the bucket rows.
fn run(case: &str) -> ExtractRun {
    let analysis = input(case, "analysis.flat")
        .chunks(ANALYSIS_RECORD_BYTES)
        .filter_map(AnalysisRow::from_bytes)
        .collect::<Vec<_>>();
    let values = input(case, "value.flat")
        .chunks(VALUE_RECORD_BYTES)
        .filter_map(ValueRow::from_bytes)
        .collect::<Vec<_>>();
    let mut run = ExtractRun::with_tables(analysis, values);
    extract(&mut run, &rows(case));
    run.finish();
    run
}

#[test]
fn the_invoice_file_is_rewritten_exactly_as_cobol_rewrites_it() {
    for case in ["clean", "credit-note", "mixed"] {
        assert_eq!(
            run(case).invoice_artifact(),
            golden(case, "pinvoice.flat"),
            "pinvoice {case}"
        );
    }
}

#[test]
fn the_staged_open_items_match_including_the_credit_note_negation() {
    for case in ["clean", "credit-note", "mixed", "empty"] {
        let produced = run(case).item4_artifact();
        let expected = golden(case, "openitm4.dat");
        assert_eq!(produced.len() % OPEN_ITEM4_RECORD_BYTES, 0, "whole records");
        assert_eq!(produced, expected, "openitm4 {case}");
    }
}

#[test]
fn the_analysis_and_value_tables_match_the_bucket_close_included() {
    for case in ["clean", "credit-note", "mixed", "empty"] {
        let produced = run(case);
        assert_eq!(
            produced.value_artifact(),
            golden(case, "value.flat"),
            "value {case}"
        );
        assert_eq!(
            produced.analysis_artifact(),
            golden(case, "analysis.flat"),
            "analysis {case}"
        );
    }
}

/// `pl-*` system counters are `s9(8)v99 comp-3` — eleven digit nibbles plus a
/// sign, six bytes (F-B072 Part 9), not the nine nibbles the invoice figures
/// carry. `counters.flat` is the raw system-record-4 pair the COBOL left.
fn counter_bytes(cents: i64) -> [u8; 6] {
    let mut digits = [0u8; 11];
    let mut magnitude = cents.unsigned_abs();
    for slot in digits.iter_mut().rev() {
        *slot = (magnitude % 10) as u8;
        magnitude /= 10;
    }
    let mut out = [0u8; 6];
    for (index, byte) in out.iter_mut().take(5).enumerate() {
        *byte = (digits[index * 2] << 4) | digits[index * 2 + 1];
    }
    out[5] = (digits[10] << 4) | if cents < 0 { 0x0D } else { 0x0C };
    out
}

#[test]
fn the_month_counters_hash_match_the_cobol_system_record() {
    for case in ["clean", "credit-note", "mixed", "empty"] {
        let produced = run(case);
        let mut expected = Vec::new();
        expected.extend_from_slice(&counter_bytes(produced.invoices_this_month));
        expected.extend_from_slice(&counter_bytes(produced.credit_notes_this_month));
        assert_eq!(expected, golden(case, "counters.flat"), "counters {case}");
    }
}

#[test]
fn the_month_counters_are_positive_for_credit_notes_and_zero_for_receipts() {
    let credit = run("credit-note");
    // Invoice 2001: net 20.00 + vat 3.00 + c-vat 2.00.
    // Credit note 2002: net 15.00 + carriage 4.00 + vat 3.00 + c-vat 1.50.
    assert_eq!(credit.invoices_this_month, 2500);
    assert_eq!(credit.credit_notes_this_month, 2350);

    // `mixed` holds one receipt (3002) and it contributes nothing at all.
    // 3003 is type 4: `ws-inv-amt` is built for it but neither `if ih-type = 2`
    // nor `= 3` takes it. 3004 is analysed but not applied, so its *specials*
    // are skipped — the month counter is not, because it moves inside
    // `extract` before `if ih-analyised` leaves (F-B055 Part 4). 3001 is
    // analysed and applied, so it never reaches `extract` at all.
    let mixed = run("mixed");
    assert_eq!(mixed.invoices_this_month, 960 + 480 + 870 + 600);
    assert_eq!(mixed.credit_notes_this_month, 0);
}

#[test]
fn an_applied_and_analysed_header_is_skipped_entirely() {
    let produced = run("mixed");
    // Seven headers in the fixture, one of them already applied: six staged.
    assert_eq!(produced.staged.len(), 6);
    assert!(produced.staged.iter().all(|item| item.invoice != 3001));
}

#[test]
fn an_analysed_header_is_still_staged_but_moves_no_specials() {
    let produced = run("mixed");
    let staged = produced
        .staged
        .iter()
        .find(|item| item.invoice == 3004)
        .expect("3004 staged");
    assert!(staged.is_open());
    // 3004's VAT leg is 1.60 and it reaches neither VAT bucket: `if ih-analyised`
    // leaves before the specials block. `Pvi` therefore holds only 3003 + 3005
    // + 3006 + 3007, and the receipt 3002's 9.00 sits in the separate `Pvj`
    // (vat-return) bucket the COBOL keeps for type 1.
    let bucket = produced.values.get(b"Pvi").expect("vat bucket row");
    assert_eq!(bucket.v_this, 140 + 80 + 120 + 100);
    let receipt = produced.values.get(b"Pvj").expect("vat-return bucket row");
    assert_eq!(receipt.v_this, 900);
}

#[test]
fn a_credit_notes_deduction_bucket_is_not_sign_flipped() {
    let produced = run("credit-note");
    // 2001 deducts nothing, 2002 deducts 5.00 and is a credit note: still +5.00.
    let bucket = produced.values.get(b"Pzb").expect("discount bucket row");
    assert_eq!(bucket.v_this, 500);
    assert_eq!(bucket.t_this, 1);
}

#[test]
fn an_unknown_analysis_code_mints_the_emergency_row_and_raises_the_warning() {
    let produced = run("mixed");
    assert!(produced.analysis_created);
    let minted = produced
        .analysis
        .get(b"PQZ")
        .expect("emergency analysis row");
    assert_eq!(&minted.desc[..14], b"Emergency Name");
    assert_eq!(minted.gl, *b"000000");
}

#[test]
fn the_empty_case_still_closes_with_the_four_bucket_rows() {
    let produced = run("empty");
    assert!(produced.staged.is_empty());
    assert!(produced.invoice_after.is_empty());
    for code in [b"Pvi", b"Pvj", b"Pza", b"Pzb"] {
        assert!(
            produced.values.contains_key(code),
            "bucket {:?} written",
            code
        );
    }
}
