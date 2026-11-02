//! `CobolDate` — ACAS/COBOL day-integer convention, days-since-1600-12-31.
//!
//! F-B001 (pinned via harness fixtures, 2026-11-02):
//!   `days_since_epoch(2026-11-02)` = 155534 (LE bytes `8e 5f 02 00`)
//!   observed at offset 27 of record 1 in `system.dat`.
//!
//! ACAS uses GnuCOBOL's `function integer-of-date`. This module is the only
//! place that knows the epoch is 1600-12-31, NOT 1900-01-01.

use thiserror::Error;

/// Julian-day-style day number where 0 = 1600-12-31.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash,
    serde::Serialize, serde::Deserialize,
)]
pub struct CobolDate(pub i32);

#[derive(Debug, Error, PartialEq, Eq)]
pub enum CobolDateError {
    #[error("days {0} outside representable window")]
    OutOfRange(i32),
}

const EPOCH_JDN_OFFSET: i64 = 2_305_813; // Julian Day Number of 1600-12-31

fn gregorian_to_jdn(y: i32, m: u32, d: u32) -> i64 {
    // Richards' algorithm
    let y = y as i64;
    let m = m as i64;
    let d = d as i64;
    (1461 * (y + 4800 + (m - 14) / 12)) / 4
        + (367 * (m - 2 - 12 * ((m - 14) / 12))) / 12
        - (3 * ((y + 4900 + (m - 14) / 12) / 100)) / 4
        + d
        - 32075
}

fn jdn_to_gregorian(mut jdn: i64) -> (i32, u32, u32) {
    // Fliegel-Van Flandern
    let mut l = jdn + 68569;
    let n = (4 * l) / 146097;
    l -= (146097 * n + 3) / 4;
    let i = (4000 * (l + 1)) / 1461001;
    l = l - (1461 * i) / 4 + 31;
    let j = (80 * l) / 2447;
    let day = l - (2447 * j) / 80;
    l = j / 11;
    let month = j + 2 - (12 * l);
    let year = 100 * (n - 49) + i + l;
    (year as i32, month as u32, day as u32)
}

impl CobolDate {
    /// Create from calendar date. Valid range approx [1600-12-31, 9999-12-31].
    pub fn new(year: i32, month: u32, day: u32) -> Result<Self, CobolDateError> {
        let jdn = gregorian_to_jdn(year, month, day);
        let days = jdn - EPOCH_JDN_OFFSET;
        if days < i32::MIN as i64 || days > i32::MAX as i64 {
            return Err(CobolDateError::OutOfRange(days as i32));
        }
        Ok(Self(days as i32))
    }

    pub fn to_ymd(self) -> (i32, u32, u32) {
        jdn_to_gregorian(self.0 as i64 + EPOCH_JDN_OFFSET)
    }

    /// Raw wire representation as GnuCOBOL writes BINARY-LONG (LE by default).
    pub fn to_le_bytes(self) -> [u8; 4] {
        self.0.to_le_bytes()
    }

    pub fn from_le_bytes(b: [u8; 4]) -> Self {
        Self(i32::from_le_bytes(b))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn observed_fixture() {
        // Pinned by F-B001: harness run wrote this to system.dat
        let d = CobolDate::new(2026, 11, 2).unwrap();
        assert_eq!(d.0, 155534);
        assert_eq!(d.to_le_bytes(), [0x8e, 0x5f, 0x02, 0x00]);
        assert_eq!(d.to_ymd(), (2026, 11, 2));
    }

    #[test]
    fn roundtrip_edges() {
        assert_eq!(CobolDate::new(1600, 12, 31).unwrap().0, 0);
        assert_eq!(CobolDate::new(1900, 1, 1).unwrap().to_ymd(), (1900, 1, 1));
        assert_eq!(CobolDate::new(2000, 2, 29).unwrap().to_ymd(), (2000, 2, 29));
    }
}
