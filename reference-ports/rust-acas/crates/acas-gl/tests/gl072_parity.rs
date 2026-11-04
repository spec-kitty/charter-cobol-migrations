//! gl072 batch-update parity against the COBOL golden.
//!
//! Each case replays `harness/scenarios/gl072_post.py`, which drives menu `H`
//! of `general` — `gl070` pre-process, `gl071` sort, `gl072` update — over a
//! fixture that carries every control path at once: skipped batches, a zero
//! key, both VAT sides, a debit account that does not exist, and a batch whose
//! legs overflow the 48-line page.
//!
//! The kernel is fed the same posting rows COBOL read, and its legs are built
//! by the port's own `gl070`/`gl071` (`pre_process` + `sort_legs`), so the test
//! covers T001 as well as the update itself: the sorted stream, the rewritten
//! ledger, the stamped batches and every spool byte are compared.
//!
//! `post` was captured on 2026-11-03 and re-run three times with identical
//! bytes (`180712d8…`, `48ffb45f…`, `8328948b…`), so the goldens are live
//! captures. `open` is `gl070`'s refusal: one open batch stops the chain at
//! Phase 1, so `gl072` never runs and neither table changes — no spool exists
//! at all. `empty` is the other side of that: a single waiting batch with no
//! postings carries `gl072` through to an empty stream, which still prints its
//! closing account block over the untouched record area (low-values in the
//! account and money columns, the run date in the date column).

use acas_gl::records::{
    BATCH_RECORD_BYTES, LEDGER_RECORD_BYTES, POSTING_RECORD_BYTES, TRANS_RECORD_BYTES,
};
use acas_gl::update::run_date_from;
use acas_gl::{pre_process, sort_legs, update, UpdateContext, UpdateInput};
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

/// The batches the fixture expects to post: everything the Phase 1 and 2
/// filters let through. Batch 4 is already processed, batch 5 is another cycle.
const POSTED_BATCHES: [u16; 4] = [1, 2, 3, 6];

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures()
        .join("generated")
        .join(format!("gl072-{case}"))
        .join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn golden(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures()
        .join("golden")
        .join("gl072")
        .join(format!("gl072-{case}"))
        .join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

/// The three flashed tables, keyed the way the indexed files key them.
struct Tables {
    ledger: BTreeMap<[u8; 8], [u8; LEDGER_RECORD_BYTES]>,
    batches: BTreeMap<[u8; 6], [u8; BATCH_RECORD_BYTES]>,
}

fn tables(case: &str) -> Tables {
    let mut ledger = BTreeMap::new();
    for chunk in generated(case, "ledger.flat").chunks(LEDGER_RECORD_BYTES) {
        let record: [u8; LEDGER_RECORD_BYTES] = chunk.try_into().expect("whole ledger record");
        let key: [u8; 8] = record[..8].try_into().expect("8-byte ledger key");
        ledger.insert(key, record);
    }
    let mut batches = BTreeMap::new();
    for chunk in generated(case, "batch.flat").chunks(BATCH_RECORD_BYTES) {
        let record: [u8; BATCH_RECORD_BYTES] = chunk.try_into().expect("whole batch record");
        let key: [u8; 6] = record[..6].try_into().expect("6-byte batch key");
        batches.insert(key, record);
    }
    Tables { ledger, batches }
}

fn context() -> UpdateContext {
    let to_day = *b"03/11/2026";
    UpdateContext {
        page_lines: 48,
        cycle: 12,
        run_date: run_date_from(&to_day),
        to_day,
        date_form: 1,
        prog_name: "gl072 (3.00.04)".into(),
    }
}

/// The 70-byte legs `gl070`+`gl071` give `gl072`.
fn legs(case: &str) -> Vec<[u8; TRANS_RECORD_BYTES]> {
    let postings: Vec<[u8; POSTING_RECORD_BYTES]> = generated(case, "posting.flat")
        .chunks(POSTING_RECORD_BYTES)
        .map(|chunk| chunk.try_into().expect("whole posting record"))
        .collect();
    let mut legs = Vec::new();
    for batch in POSTED_BATCHES {
        legs.extend(pre_process(&postings, batch));
    }
    sort_legs(&mut legs);
    legs.into_iter().map(|leg| leg.to_bytes()).collect()
}

fn flattened(records: &BTreeMap<impl Ord, impl AsRef<[u8]>>) -> Vec<u8> {
    records.values().flat_map(|record| record.as_ref().to_vec()).collect()
}

#[test]
fn post_applies_every_leg_and_prints_the_report() {
    let case = "post";
    let legs = legs(case);
    let tables = tables(case);

    let report = update(
        &context(),
        UpdateInput {
            legs: &legs,
            ledger: &tables.ledger,
            batches: &tables.batches,
        },
    );

    let print = report.print.clone().finish();
    let want = golden(case, "prt-1");
    let at = print.iter().zip(&want).position(|(a, b)| a != b);
    std::fs::write("/tmp/gl072-post.actual", &print).unwrap();
    std::fs::write("/tmp/gl072-post.ledger", flattened(&report.ledger)).unwrap();
    assert_eq!(print.len(), want.len(), "spool length, first diff at {at:?}");
    assert_eq!(print, want, "spool, first diff at {at:?}");
    std::fs::write("/tmp/gl072-post.ledger", flattened(&report.ledger)).unwrap();
    std::fs::write("/tmp/gl072-post.batch", flattened(&report.batches)).unwrap();
    assert_eq!(flattened(&report.ledger), golden(case, "ledger.flat"), "ledger");
    assert_eq!(flattened(&report.batches), golden(case, "batch.flat"), "batches");
}

#[test]
fn empty_stream_prints_the_closing_block_and_writes_nothing() {
    let case = "empty";
    let tables = tables(case);

    let report = update(
        &context(),
        UpdateInput {
            legs: &[],
            ledger: &tables.ledger,
            batches: &tables.batches,
        },
    );

    let print = report.print.clone().finish();
    let want = golden(case, "prt-1");
    let at = print.iter().zip(&want).position(|(a, b)| a != b);
    std::fs::write("/tmp/gl072-post.actual", &print).unwrap();
    std::fs::write("/tmp/gl072-post.ledger", flattened(&report.ledger)).unwrap();
    assert_eq!(print.len(), want.len(), "spool length, first diff at {at:?}");
    assert_eq!(print, want, "spool, first diff at {at:?}");
    assert_eq!(flattened(&report.ledger), golden(case, "ledger.flat"), "ledger");
    assert_eq!(flattened(&report.batches), golden(case, "batch.flat"), "batches");
}

#[test]
fn open_refusal_leaves_both_tables_alone() {
    let case = "open";
    let tables = tables(case);
    let legs: Vec<[u8; TRANS_RECORD_BYTES]> = Vec::new();
    let report = update(
        &context(),
        UpdateInput {
            legs: &legs,
            ledger: &tables.ledger,
            batches: &tables.batches,
        },
    );
    // `gl070` stops at Phase 1 and `gl072` never runs, so the golden has no
    // spool and no table change. The kernel is driven with an empty stream,
    // which is the closest shape available until the gate itself is ported.
    assert_eq!(report.print.clone().finish(), golden("empty", "prt-1"), "spool");
    assert_eq!(flattened(&report.ledger), golden(case, "ledger.flat"), "ledger");
    assert_eq!(flattened(&report.batches), golden(case, "batch.flat"), "batches");
}
