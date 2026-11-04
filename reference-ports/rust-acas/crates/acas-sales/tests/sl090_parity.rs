//! sl090 payment-proof-sort parity against the COBOL golden.
//!
//! The case replays `harness/scenarios/sl090_sort.py`: the COBOL was driven
//! through the real sales menu with `J`, and the sorted `oisort.wrk` it gave
//! out — every surviving record, all 114 bytes, in the order the four sort
//! keys produce — is compared byte for byte.
//!
//! The golden was captured on 2026-11-03 against the seeded `system.dat` with
//! `s-flag-p` (byte 569) set, and was re-run twice afterwards with identical
//! bytes (`7604d63d…`), so it is a live capture, not a hand-edited file.
//!
//! `no-flag` is the refusal: with `s-flag-p` clear the program raises errors
//! 30/15 through `maps99` and exits before opening anything, so no `oisort.wrk`
//! exists at all — not even an empty one.

use acas_sales::payment_proof_sort::{artifact, run, SortOutcome, OPEN_ITEM_BYTES};
use std::path::{Path, PathBuf};

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(name: &str) -> Vec<u8> {
    let path = fixtures().join("generated/sl090-sort").join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn rows() -> Vec<[u8; OPEN_ITEM_BYTES]> {
    generated("openitm3.flat")
        .chunks(OPEN_ITEM_BYTES)
        .map(|chunk| chunk.try_into().expect("whole 114-byte open item"))
        .collect()
}

fn golden() -> Vec<u8> {
    let path = fixtures().join("golden/sl090/sort/oisort.wrk");
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

#[test]
fn the_sort_reproduces_the_cobol_sorted_file() {
    let produced = artifact(&run(0, 1, &rows()));
    let expected = golden();
    assert_eq!(produced.len(), expected.len(), "sorted length");
    assert_eq!(produced, expected, "sorted bytes");
}

#[test]
fn the_receipt_the_credit_note_and_the_batch_zero_row_are_gone() {
    // Three of the fourteen fixture rows must not reach the output — the
    // receipt (117), the credit note (118) and the batch-zero row (0).
    let produced = artifact(&run(0, 1, &rows()));
    assert_eq!(produced.len() / OPEN_ITEM_BYTES, 11);
    for invoice in [117u32, 118, 0] {
        let present = produced
            .chunks(OPEN_ITEM_BYTES)
            .any(|row| u32::from_le_bytes([row[7], row[8], row[9], row[10]]) == invoice);
        assert!(!present, "invoice {invoice} should have been dropped");
    }
}

#[test]
fn a_cleared_payment_flag_refuses_and_writes_nothing() {
    assert_eq!(run(0, 0, &rows()), SortOutcome::Refused);
    // The golden directory holds no oisort.wrk for `no-flag` by design.
    let expected = fixtures().join("golden/sl090/no-flag/oisort.wrk");
    assert!(!expected.exists(), "a refusal leaves no file to compare");
}

#[test]
fn the_sorted_file_is_the_input_records_unchanged() {
    // Every emitted record is byte-identical to one input record: the sort
    // moves records, it does not rebuild them.
    let source = rows();
    for row in artifact(&run(0, 1, &source)).chunks(OPEN_ITEM_BYTES) {
        assert!(source.iter().any(|candidate| candidate.as_slice() == row));
    }
}
