//! The byte records of the GL posting chain.
//!
//! Offsets and sizes are measured in
//! `docs/fd-evidence/F-B072-gl-post-apply.md`; the posting overlay's money
//! encoding is F-B009 Part 3. Input `posting-record`s arrive from sl060, are
//! expanded to two or three `pre-trans-record` legs by `gl070`, sorted by
//! `gl071` and consumed by `gl072`.

/// `fdpost.cob` — the posting record is 98 bytes.
pub const POSTING_RECORD_BYTES: usize = 98;
/// One `pre-trans-record` / `post-trans-record` leg: 70 bytes.
pub const TRANS_RECORD_BYTES: usize = 70;
/// `fdledger.cob` — the ledger record is 126 bytes.
pub const LEDGER_RECORD_BYTES: usize = 126;
/// `fdbatch.cob` — the batch record is 96 bytes.
pub const BATCH_RECORD_BYTES: usize = 96;

/// Hundredths, the unit every ACAS money field is held in here.
pub type Money = i64;

/// Magnitude cap of `s9(8)v99` in hundredths.
pub const VALUE_MAX_CENTS: u64 = 10_000_000_000;

/// GnuCOBOL's ASCII overpunch table for the final digit of a signed
/// `s9(8)v99` display field (F-B009 Part 3, measured).
const OVERPUNCH: [u8; 10] = [b'p', b'q', b'r', b's', b't', b'u', b'v', b'w', b'x', b'y'];

/// Decode ten display bytes carrying a sign overpunch, or `None` when any
/// digit byte is not numeric.
pub fn unpack_overpunch(field: &[u8]) -> Option<Money> {
    if field.len() != 10 {
        return None;
    }
    let (last, digits) = field.split_last()?;
    let mut magnitude: u64 = 0;
    for byte in digits {
        let digit = byte.checked_sub(b'0')?;
        if digit > 9 {
            return None;
        }
        magnitude = magnitude * 10 + u64::from(digit);
    }
    let (digit, negative) = match *last {
        b'0'..=b'9' => (*last - b'0', false),
        byte => {
            let index = OVERPUNCH.iter().position(|candidate| *candidate == byte)?;
            (index as u8, true)
        }
    };
    magnitude = magnitude * 10 + u64::from(digit);
    let value = magnitude as i64;
    Some(if negative { -value } else { value })
}

/// Encode a value back the same way. Magnitude is clamped to ten digits.
pub fn pack_overpunch(cents: Money) -> [u8; 10] {
    let magnitude = (cents.unsigned_abs()).min(VALUE_MAX_CENTS - 1);
    let text = format!("{magnitude:010}");
    let mut out = [0u8; 10];
    for (slot, byte) in out.iter_mut().zip(text.bytes()) {
        *slot = byte;
    }
    if cents < 0 {
        let final_digit = (out[9] - b'0') as usize;
        out[9] = OVERPUNCH[final_digit];
    }
    out
}

fn digits(bytes: &[u8]) -> Option<u32> {
    let mut value = 0u32;
    for byte in bytes {
        let digit = byte.checked_sub(b'0')?;
        if digit > 9 {
            return None;
        }
        value = value * 10 + u32::from(digit);
    }
    Some(value)
}

fn five_digits(value: u16) -> [u8; 5] {
    let text = format!("{value:05}");
    let bytes = text.as_bytes();
    bytes[bytes.len() - 5..].try_into().unwrap_or(*b"00000")
}

/// A view over one `posting-record`.
#[derive(Debug, Clone, Copy)]
pub struct Posting {
    pub batch: u16,
    pub post: u16,
    pub code: [u8; 2],
    pub date: [u8; 8],
    pub dr: [u8; 6],
    pub dr_pc: [u8; 2],
    pub cr: [u8; 6],
    pub cr_pc: [u8; 2],
    pub amount: Money,
    pub legend: [u8; 32],
    pub vat_ac: [u8; 6],
    pub vat_pc: [u8; 2],
    pub vat_side: [u8; 2],
    pub vat_amount: Money,
}

impl Posting {
    /// Decode a record, or `None` when a numeric field does not parse.
    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() != POSTING_RECORD_BYTES {
            return None;
        }
        Some(Self {
            batch: digits(&bytes[0..5])? as u16,
            post: digits(&bytes[5..10])? as u16,
            code: bytes[10..12].try_into().ok()?,
            date: bytes[12..20].try_into().ok()?,
            dr: bytes[20..26].try_into().ok()?,
            dr_pc: bytes[26..28].try_into().ok()?,
            cr: bytes[28..34].try_into().ok()?,
            cr_pc: bytes[34..36].try_into().ok()?,
            amount: unpack_overpunch(&bytes[36..46])?,
            legend: bytes[46..78].try_into().ok()?,
            vat_ac: bytes[78..84].try_into().ok()?,
            vat_pc: bytes[84..86].try_into().ok()?,
            vat_side: bytes[86..88].try_into().ok()?,
            vat_amount: unpack_overpunch(&bytes[88..98])?,
        })
    }

    /// `if post-key = zero` — both key halves are all zero digits.
    pub fn zero_key(&self) -> bool {
        self.batch == 0 && self.post == 0
    }
}

/// One `pre-trans-record`, i.e. one ledger leg.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Trans {
    pub batch: u16,
    pub post: u16,
    pub code: [u8; 2],
    pub date: [u8; 8],
    pub ac: [u8; 6],
    pub pc: [u8; 2],
    pub amount: Money,
    pub legend: [u8; 32],
}

impl Trans {
    pub fn to_bytes(&self) -> [u8; TRANS_RECORD_BYTES] {
        let mut out = [b' '; TRANS_RECORD_BYTES];
        out[0..5].copy_from_slice(&five_digits(self.batch));
        out[5..10].copy_from_slice(&five_digits(self.post));
        out[10..12].copy_from_slice(&self.code);
        out[12..20].copy_from_slice(&self.date);
        out[20..26].copy_from_slice(&self.ac);
        out[26..28].copy_from_slice(&self.pc);
        out[28..38].copy_from_slice(&pack_overpunch(self.amount));
        out[38..70].copy_from_slice(&self.legend);
        out
    }

    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() != TRANS_RECORD_BYTES {
            return None;
        }
        Some(Self {
            batch: digits(&bytes[0..5])? as u16,
            post: digits(&bytes[5..10])? as u16,
            code: bytes[10..12].try_into().ok()?,
            date: bytes[12..20].try_into().ok()?,
            ac: bytes[20..26].try_into().ok()?,
            pc: bytes[26..28].try_into().ok()?,
            amount: unpack_overpunch(&bytes[28..38])?,
            legend: bytes[38..70].try_into().ok()?,
        })
    }

    /// The 8-byte `ledger-key` this leg posts to.
    pub fn key(&self) -> [u8; 8] {
        let mut key = [0u8; 8];
        key[..6].copy_from_slice(&self.ac);
        key[6..].copy_from_slice(&self.pc);
        key
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn posting_bytes(batch: u16, post: u16) -> [u8; POSTING_RECORD_BYTES] {
        let mut record = [b' '; POSTING_RECORD_BYTES];
        record[0..5].copy_from_slice(&format!("{batch:05}").as_bytes()[..5]);
        record[5..10].copy_from_slice(&format!("{post:05}").as_bytes()[..5]);
        record[10..12].copy_from_slice(b"JD");
        record[12..20].copy_from_slice(b"01/04/26");
        record[20..26].copy_from_slice(b"000010");
        record[26..28].copy_from_slice(b"00");
        record[28..34].copy_from_slice(b"000020");
        record[34..36].copy_from_slice(b"00");
        record[36..46].copy_from_slice(&pack_overpunch(50_000));
        record[46..52].copy_from_slice(b"LEGEND");
        record[78..84].copy_from_slice(b"000000");
        record[84..86].copy_from_slice(b"00");
        record[86..88].copy_from_slice(b"  ");
        record[88..98].copy_from_slice(&pack_overpunch(0));
        record
    }

    #[test]
    fn overpunch_round_trips_both_signs() {
        for value in [0, 1, -1, 12_345, -12_345, 9_999_999_999] {
            assert_eq!(unpack_overpunch(&pack_overpunch(value)), Some(value));
        }
    }

    #[test]
    fn overpunch_negative_uses_the_letter_row() {
        assert_eq!(pack_overpunch(-1)[9], b'q');
        assert_eq!(unpack_overpunch(b"000000000q"), Some(-1));
    }

    #[test]
    fn overpunch_rejects_a_non_digit() {
        assert_eq!(unpack_overpunch(b"0000A00000"), None);
        assert_eq!(unpack_overpunch(b"000"), None);
    }

    #[test]
    fn posting_decodes_every_field_at_its_measured_offset() {
        let record = posting_bytes(6, 2);
        let posting = Posting::from_bytes(&record).expect("decodes");
        assert_eq!(posting.batch, 6);
        assert_eq!(posting.post, 2);
        assert_eq!(&posting.code, b"JD");
        assert_eq!(&posting.dr, b"000010");
        assert_eq!(&posting.cr, b"000020");
        assert_eq!(posting.amount, 50_000);
    }

    #[test]
    fn only_both_key_halves_zero_is_a_zero_key() {
        assert!(Posting::from_bytes(&posting_bytes(0, 0)).unwrap().zero_key());
        assert!(!Posting::from_bytes(&posting_bytes(0, 1)).unwrap().zero_key());
    }

    #[test]
    fn posting_needs_a_whole_record_and_parses_the_amount() {
        let record = posting_bytes(1, 1);
        assert!(Posting::from_bytes(&record[..97]).is_none());
        let mut broken = record;
        broken[36] = b'x';
        assert!(Posting::from_bytes(&broken).is_none());
    }

    #[test]
    fn trans_round_trips_and_keys_on_account_and_pc() {
        let trans = Trans {
            batch: 6,
            post: 2,
            code: *b"JD",
            date: *b"01/04/26",
            ac: *b"000080",
            pc: *b"00",
            amount: -50_000,
            legend: [b'X'; 32],
        };
        let bytes = trans.to_bytes();
        assert_eq!(Trans::from_bytes(&bytes), Some(trans));
        assert_eq!(trans.key(), *b"00008000");
    }
}
