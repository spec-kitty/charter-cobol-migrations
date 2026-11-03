//! GnuCOBOL relative-ISAM file format reader/writer.
//!
//! Why we need this: `system.dat` and every ledger file ACAS writes are
//! GnuCOBOL RELATIVE organization files on disk — NOT the Fortran-style
//! indexed files GnuCOBOL's `cobc` would write for `ORGANIZATION INDEXED`.
//! For port parity the Rust side must read/write the same bytes so that
//! a hybrid harness run (COBOL half vs Rust half) sees no format boundary.
//!
//! Format (empirically derived, verified against system.dat):
//!
//! - Header: 128 bytes at start of every relative file. Contains:
//!   - u32 LE record count at offset 0x0C (observed: 4 for a fresh 4-slot system file)
//!   - record size u32 LE at offset 0x10 (1024 in our run)
//! - Records follow at fixed stride; each record is preceded by a 1-byte
//!   "slot used" marker (`0x01` used / `0x00` free... observed) then raw
//!   record bytes sized per the header.
//!
//! Evidence: 4128-byte system.dat = 128 header + 4 slots of (1 marker + 1024 body)
//!   = 128 + 4 × 1025  → but observed record 0 starts at offset 0x20 (32).
//!   So: header is 32 bytes at minimum; observed marker+pad 96 more; need
//!   confirmation against multiple files — flagged as **Phase 1 follow-up**
//!   with `acas-common::isam` marked experimental until then.

#![allow(dead_code)]  // architectural surface, will be exercised by harness stage

/// Rust-side view of a GnuCOBOL relative file on disk.
#[derive(Debug)]
pub struct RelativeFile {
    /// The header prefix we observed (32 bytes verified; 128-byte total likely
    /// needs follow-up against stock.dat/invoice.dat examples).
    pub header: Vec<u8>,
    /// Per-slot `(used: bool, body: Vec<u8>)` parsed records.
    pub records: Vec<(bool, Vec<u8>)>,
}

#[derive(thiserror::Error, Debug)]
pub enum IsamError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("malformed: {0}")]
    Malformed(String),
}
