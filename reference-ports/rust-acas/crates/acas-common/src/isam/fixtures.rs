//! Byte-exact fixture builders for the parity harness (charter L2R-002: both
//! halves of a run must start from identical bytes).
//!
//! Every offset below cites the FD that owns it. Builders write the *flat*
//! shape (F-B005 shape B) because that is what the existing `sl055-*`
//! fixtures use and what ACAS opens `i-o` without complaint — except
//! `invoice`, whose richer builder already lives in
//! `fixtures/fdinv2_builder.py`.
//!
//! Sizes are FD facts, not guesses: `fdval.cob` = 66 B, `fdanal.cob` = 36 B,
//! `fdoi2.cob` = 114 B. Each was re-measured off a GnuCOBOL write before
//! being pinned (F-B005).

use super::{FileKind, TRAILER_LEN};

/// Pad right with spaces, the COBOL ALPHANUMERIC send, truncated to `size`.
fn put_alpha(rec: &mut [u8], pos: usize, data: &[u8], size: usize) {
    let n = data.len().min(size);
    rec[pos..pos + n].copy_from_slice(&data[..n]);
    rec[pos + n..pos + size].fill(b' ');
}

/// Right-justified `PIC 9(n)` digits.
fn put_digits(rec: &mut [u8], pos: usize, value: u64, digits: usize) {
    let text = format!("{value:0digits$}");
    let text = &text[text.len() - digits..];
    rec[pos..pos + digits].copy_from_slice(text.as_bytes());
}

/// `va-code` at 0..3 (fdval.cob) + `va-gl` 3..9 + `va-desc` 9..33.
///
/// The comp/comp-3 money columns (33..66) stay zero: a fixture that leaves
/// them zero is a valid "no movement yet" row and keeps the builder honest
/// about only the fields it claims to set.
pub fn value_record(system: u8, first: u8, second: u8, gl: u64, desc: &[u8]) -> Vec<u8> {
    let size = FileKind::Value.record_size();
    let mut rec = vec![0u8; size];
    put_alpha(&mut rec, 0, &[system], 1);
    put_alpha(&mut rec, 1, &[first], 1);
    put_alpha(&mut rec, 2, &[second], 1);
    put_digits(&mut rec, 3, gl, 6);
    put_alpha(&mut rec, 9, desc, 24);
    put_alpha(&mut rec, 33, b"yyy", 3);
    rec
}

/// `pa-code` at 0..3 (fdanal.cob) + `pa-gl` 3..9 + `pa-desc` 9..33.
pub fn analysis_record(system: u8, first: u8, second: u8, gl: u64, desc: &[u8]) -> Vec<u8> {
    let size = FileKind::Analysis.record_size();
    let mut rec = vec![0u8; size];
    put_alpha(&mut rec, 0, &[system], 1);
    put_alpha(&mut rec, 1, &[first], 1);
    put_alpha(&mut rec, 2, &[second], 1);
    put_digits(&mut rec, 3, gl, 6);
    put_alpha(&mut rec, 9, desc, 24);
    put_alpha(&mut rec, 33, b"yyy", 3);
    rec
}

/// `open-item-record-2` is an opaque `pic x(114)` (`fdoi2.cob`), so the
/// builder takes the payload and pads it.
pub fn open_item2_record(payload: &[u8]) -> Vec<u8> {
    let size = FileKind::OpenItem2.record_size();
    let mut rec = vec![b' '; size];
    put_alpha(&mut rec, 0, payload, payload.len().min(size));
    rec
}

/// Assemble flat-shape file bytes: contiguous records + 32-space trailer.
pub fn flat_file(records: &[Vec<u8>]) -> Vec<u8> {
    let mut out = Vec::new();
    for r in records {
        out.extend_from_slice(r);
    }
    out.extend(std::iter::repeat_n(b' ', TRAILER_LEN));
    out
}
