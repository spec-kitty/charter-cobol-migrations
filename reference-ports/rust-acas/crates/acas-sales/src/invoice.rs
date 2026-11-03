//! Invoice record types ported from `sales/fdinv2.cob`.
//!
//! Every field, offset and width here is measured off bytes GnuCOBOL itself
//! writes — see `docs/fd-evidence/F-B006-fdinv2-field-map.md`. Field
//! dispositions are in `docs/disposition-fdinv2.md`.
//!
//! ## Design notes (specific to L2R-005 & L2R-006)
//!
//! ACAS exploits the fact that `invoice-record` is polymorphic on disk:
//! one physical file holds both invoice *headers* and *lines*, keyed by the
//! same `(invoice-nos, invoice-let, item-nos)` triple. When `item_nos = 0`
//! the record is a header; otherwise it's a line. The union is dispatched
//! at `READ` time by the application, not by the ISAM layer — the ISAM
//! definition is 134 bytes of undifferentiated content.
//!
//! Porting choice: this `match` is the **feature**. The one physical file
//! with half-overlapping language is the **idiom**. Rust gets an enum
//! with two strong variants that share a 134-byte serde framing.
//!
//! ## The truncation fact (F-B006)
//!
//! The COBOL overlay `invoice-header` is 137 bytes; the FD record is 134.
//! ACAS writes `move sinvoice-header to invoice-record`, so the last three
//! header bytes are dropped by every write. That is carried, not repaired:
//! `cr` persists its low 3 bytes, and `day_book_flag`/`update` are
//! memory-only. The line overlay is 80 bytes in the same 134-byte frame;
//! bytes 80..134 are not its field area and ride along as `tail`.

use std::fmt;
use std::ops::Range;
use thiserror::Error;

/// `fdinv2.cob` — the FD record is always 134 bytes. The header overlay is
/// 137 bytes over it (F-B006); `InvoiceHeader::to_bytes` truncates to this.
pub const ACAS_INVOICE_RECORD_BYTES: usize = 134;

/// `ih-description`/`il-description` width.
const DESCRIPTION_BYTES: usize = 32;
/// `ih-sub-prime` figure group: eight 5-byte packed fields.
const FIG_FIELDS: usize = 8;
/// Packed field width for `s9(7)v99`.
const FIG_BYTES: usize = 5;

/// Invoice number space. 9(8) → up to 99_999_999. Bounded, so we keep the
/// bounded int, not a newtype over String.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
pub struct InvoiceNumber(pub u32);

/// Trailing letter tag on invoice ID — COBOL x field carrying A-Z
/// distinguishing duplicates (e.g. manual duplicates). Carried, not retired:
/// the *feature* is real (manual-duplicate invoices exist in production).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct InvoiceLetter(pub u8); // raw ASCII; A-Z expected but byte space is the truth

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum InvoiceLineNo {
    /// item-nos = 0 → this is the header for this invoice
    Header,
    /// item-nos = 1..=99 → nth line item under this invoice
    Line(u8),
}

impl InvoiceLineNo {
    pub fn from_cobol(v: u8) -> Self {
        if v == 0 { Self::Header } else { Self::Line(v) }
    }
    pub fn to_cobol(self) -> u8 {
        match self { Self::Header => 0, Self::Line(n) => n }
    }
}

/// `days-since-1900-01-01` for COBOL binary-long date fields.
///
/// ACAS stores dates as binary-long days-since-1900, *not* as packed-decimal
/// or string. Chrono-free wrapper; conversion to a calendar only when a
/// behavior actually requires it (reports do, files never).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
pub struct CobolDate(pub i32); // days since 1900-01-01; negative allowed

/// Invoice kind — `invoice-type`, PIC 9 (display numeric, so the on-disk byte
/// is the character `b'1'`, not `1`). Observed values in sl055: `1` = invoice,
/// `3` = credit note, `4` = proforma. Unknown bytes stay representable
/// (L2R-005 disposition) instead of killing the deserializer, and the raw byte
/// is what round-trips.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum InvoiceType {
    Invoice,
    CreditNote,
    Proforma,
    /// Preserved so files with unknown codes don't fail to decode.
    Other(u8),
}

impl InvoiceType {
    pub fn from_cobol(v: u8) -> Self {
        match v {
            b'1' => Self::Invoice,
            b'3' => Self::CreditNote,
            b'4' => Self::Proforma,
            x => Self::Other(x),
        }
    }
    pub fn to_cobol(self) -> u8 {
        match self {
            Self::Invoice => b'1',
            Self::CreditNote => b'3',
            Self::Proforma => b'4',
            Self::Other(x) => x,
        }
    }
}

/// Customer key, `x(7)` in the FD. Bytes 0..6 are the customer number
/// (`ih-nos`), byte 6 is the modulus check digit (`ih-check`, PIC 9).
/// Raw: ACAS compares customer codes positionally and never validates ASCII.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
pub struct CustomerKey(pub [u8; 7]);

impl CustomerKey {
    /// `ih-nos` — the six-byte customer number.
    pub fn nos(&self) -> [u8; 6] {
        self.0[..6].try_into().expect("6 of 7 bytes")
    }
    /// `ih-check` — modulus check digit, carried as its character.
    pub fn check_digit(&self) -> u8 {
        self.0[6]
    }
}

/// `s9(7)v99 comp-3` — packed decimal, 5 bytes, sign in the low nibble of the
/// last byte. Raw bytes are authoritative (nibble-exact round-trip); `cents`
/// is the arithmetic view. Unrecognised sign nibbles survive verbatim.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct PackedMoney([u8; FIG_BYTES]);

/// Magnitude cap of `s9(7)v99`, in hundredths.
pub const PACKED_MONEY_MAX_CENTS: i64 = 999_999_999;

impl PackedMoney {
    pub const ZERO: Self = Self([0, 0, 0, 0, 0x0C]);

    /// From raw wire bytes, preserving every nibble.
    pub const fn from_raw(raw: [u8; FIG_BYTES]) -> Self {
        Self(raw)
    }

    pub const fn raw(&self) -> [u8; FIG_BYTES] {
        self.0
    }

    /// Value in hundredths. The trailing nibble is the sign: `D`/`B`
    /// negative, everything else positive — as libcob reads it.
    pub fn cents(&self) -> i64 {
        let mut magnitude = 0i64;
        for byte in &self.0[..4] {
            magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
        }
        magnitude = magnitude * 10 + i64::from(self.0[4] >> 4);
        if matches!(self.0[4] & 0x0F, 0x0D | 0x0B) { -magnitude } else { magnitude }
    }

    /// Build from hundredths. Out of range is an error, never a silent wrap.
    pub fn from_cents(cents: i64) -> Result<Self, InvoiceError> {
        if cents.unsigned_abs() > PACKED_MONEY_MAX_CENTS as u64 {
            return Err(InvoiceError::PackedOverflow(cents));
        }
        let mut digits = [0u8; 9];
        let mut magnitude = cents.unsigned_abs();
        for slot in digits.iter_mut().rev() {
            *slot = (magnitude % 10) as u8;
            magnitude /= 10;
        }
        let mut raw = [0u8; FIG_BYTES];
        for i in 0..4 {
            raw[i] = (digits[i * 2] << 4) | digits[i * 2 + 1];
        }
        raw[4] = (digits[8] << 4) | if cents < 0 { 0x0D } else { 0x0C };
        Ok(Self(raw))
    }
}

/// `999v99 comp` — 4-byte big-endian binary (F-B006), unsigned, hundredths.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, serde::Serialize, serde::Deserialize)]
pub struct CompAmount([u8; 4]);

impl CompAmount {
    pub const ZERO: Self = Self([0, 0, 0, 0]);

    pub const fn from_raw(raw: [u8; 4]) -> Self {
        Self(raw)
    }
    pub const fn raw(&self) -> [u8; 4] {
        self.0
    }
    pub fn hundredths(&self) -> u32 {
        u32::from_be_bytes(self.0)
    }
    pub fn from_hundredths(v: u32) -> Self {
        Self(v.to_be_bytes())
    }
}

/// `99v99 comp` — 2-byte big-endian binary discount rate, hundredths.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Default, serde::Serialize, serde::Deserialize)]
pub struct CompRate([u8; 2]);

impl CompRate {
    pub const ZERO: Self = Self([0, 0]);

    pub const fn from_raw(raw: [u8; 2]) -> Self {
        Self(raw)
    }
    pub const fn raw(&self) -> [u8; 2] {
        self.0
    }
    pub fn hundredths(&self) -> u16 {
        u16::from_be_bytes(self.0)
    }
    pub fn from_hundredths(v: u16) -> Self {
        Self(v.to_be_bytes())
    }
}

/// `ih-status` — tri-state display flag. `Applied` keeps the exact byte
/// because the 88-level accepts both `z` and `Z` and programs write both.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum HeaderStatus {
    Pending,
    Invoiced,
    Applied(u8),
    Other(u8),
}

impl HeaderStatus {
    pub fn from_cobol(v: u8) -> Self {
        match v {
            b'P' => Self::Pending,
            b'I' => Self::Invoiced,
            b'z' | b'Z' => Self::Applied(v),
            x => Self::Other(x),
        }
    }
    pub fn to_cobol(self) -> u8 {
        match self {
            Self::Pending => b'P',
            Self::Invoiced => b'I',
            Self::Applied(x) | Self::Other(x) => x,
        }
    }
}

/// One of `ih-status-{P,L,C,A,I}` — single-letter columns, space when unset.
/// Byte space is the truth: the 88-levels only name the set state, and ACAS
/// preserves the case of the letter, so it is preserved here.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
pub struct StatusFlag(pub u8);

impl StatusFlag {
    /// Blank column.
    pub const UNSET: Self = Self(b' ');

    /// Set to `letter`, as ACAS writes it; case preserved.
    pub const fn set(letter: u8) -> Self {
        Self(letter)
    }
    /// Any non-space byte reads as set.
    pub const fn is_set(&self) -> bool {
        self.0 != b' '
    }
}

/// Invoice record as observed on disk. Dispatch on `item_nos`.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum InvoiceRow {
    Header(InvoiceHeader),
    Line(InvoiceLine),
}

/// 01 invoice-record, header variant (item_nos=0), overlay `invoice-header`.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct InvoiceHeader {
    pub invoice_nos: InvoiceNumber,
    pub invoice_let: InvoiceLetter,
    pub customer: CustomerKey,
    pub date: CobolDate,
    pub order: [u8; 10],
    pub invoice_type: InvoiceType,
    pub reference: [u8; 10],
    pub description: [u8; DESCRIPTION_BYTES],
    /// `ih-fig`, in copybook order: p-c, net, extra, carriage, vat, discount,
    /// e-vat, c-vat.
    pub figures: [PackedMoney; FIG_FIELDS],
    pub status: HeaderStatus,
    /// `ih-status-P`, `-L`, `-C`, `-A`, `-I`, in that order.
    pub status_flags: [StatusFlag; 5],
    pub lines: u8,
    pub deduct_days: u8,
    pub deduct_amt: CompAmount,
    pub deduct_vat: CompAmount,
    pub days: u8,
    /// `ih-cr` credit-by date. Only the low 3 bytes reach disk (F-B006);
    /// decode yields the 24-bit value and the high byte is lost on write.
    pub cr: CobolDate,
    /// `ih-day-book-flag` — **memory only**: byte 135 is past the 134-byte
    /// record, so a value set here never persists. Decodes as space.
    pub day_book_flag: u8,
    /// `ih-update` (`88 ih-analyised` = z/Z) — **memory only**, byte 136.
    pub update: u8,
}

impl InvoiceHeader {
    /// `88 day-booked`.
    pub fn day_booked(&self) -> bool {
        self.day_book_flag == b'B'
    }
    /// `88 ih-analyised` — both cases, as the 88-level declares them.
    pub fn analysed(&self) -> bool {
        matches!(self.update, b'z' | b'Z')
    }
}

/// Bytes 80..134 of the record: outside the line overlay but inside the
/// frame. `[u8; 54]`, with serde served by hand because serde's array impls
/// stop at 32.
#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(transparent)]
pub struct RecordTail(serde_bytes_compat::Bytes54);

/// Serialise as bytes; accept a byte string or a sequence on the way back.
mod serde_bytes_compat {
    use serde::{Deserialize, Deserializer, Serialize, Serializer};

    #[derive(Debug, Clone, Copy, PartialEq, Eq)]
    pub struct Bytes54(pub [u8; 54]);

    impl Serialize for Bytes54 {
        fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
            s.serialize_bytes(&self.0)
        }
    }

    impl<'de> Deserialize<'de> for Bytes54 {
        fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
            struct V;
            impl<'de> serde::de::Visitor<'de> for V {
                type Value = Bytes54;
                fn expecting(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                    f.write_str("54 bytes")
                }
                fn visit_bytes<E: serde::de::Error>(self, v: &[u8]) -> Result<Bytes54, E> {
                    v.try_into().map(Bytes54).map_err(|_| E::invalid_length(v.len(), &self))
                }
                fn visit_seq<A: serde::de::SeqAccess<'de>>(self, mut seq: A) -> Result<Bytes54, A::Error> {
                    let mut out = [0u8; 54];
                    for (i, slot) in out.iter_mut().enumerate() {
                        *slot = seq.next_element()?.ok_or_else(|| {
                            serde::de::Error::invalid_length(i, &self)
                        })?;
                    }
                    Ok(Bytes54(out))
                }
            }
            d.deserialize_bytes(V)
        }
    }
}

impl RecordTail {
    pub const fn new(raw: [u8; 54]) -> Self {
        Self(serde_bytes_compat::Bytes54(raw))
    }
    pub const fn raw(&self) -> [u8; 54] {
        (self.0).0
    }
}

impl Default for RecordTail {
    fn default() -> Self {
        Self::new([b' '; 54])
    }
}

impl From<[u8; 54]> for RecordTail {
    fn from(raw: [u8; 54]) -> Self {
        Self::new(raw)
    }
}

/// Line-item variant (item_nos != 0), overlay `invoice-line`.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct InvoiceLine {
    pub invoice_nos: InvoiceNumber,
    pub invoice_let: InvoiceLetter,
    pub line_no: u8,
    pub product: [u8; 13],
    pub pa: [u8; 2],
    pub qty: i16,
    /// `il-type` — a digit *character* (`b'3'` = credit), not a number.
    pub line_type: u8,
    pub description: [u8; DESCRIPTION_BYTES],
    pub net: PackedMoney,
    pub unit: PackedMoney,
    pub discount: CompRate,
    pub vat: PackedMoney,
    pub vat_code: u8,
    pub update: u8,
    /// Trailing pad byte inside the overlay.
    pub filler: u8,
    /// Bytes 80..134 of the frame — outside the overlay, carried verbatim.
    pub tail: RecordTail,
}

impl InvoiceLine {
    /// `88 il-analyised`.
    pub fn analysed(&self) -> bool {
        matches!(self.update, b'z' | b'Z')
    }
    /// `il-type` credit-note test, as sl055 performs it.
    pub fn is_credit(&self) -> bool {
        self.line_type == b'3'
    }
}

#[derive(Debug, Error, PartialEq, Eq)]
pub enum InvoiceError {
    #[error("record not 134 bytes (got {0})")]
    WrongLength(usize),
    #[error("item-nos {0} does not match the requested variant")]
    ItemNosMarker(u8),
    #[error("invoice number out of 9(8) range ({0})")]
    NumberOutOfRange(u32),
    #[error("invoice number is not 9(8) display digits")]
    UnparsableNumber,
    #[error("packed amount out of s9(7)v99 range ({0} hundredths)")]
    PackedOverflow(i64),
}

// Field offsets (F-B006). Named so encode and decode cannot drift apart.
const O_INVOICE: Range<usize> = 0..8;
const O_LETTER: usize = 8;
const O_ITEM: usize = 9;
const O_CUSTOMER: Range<usize> = 10..17;
const O_DATE: Range<usize> = 17..21;
const O_ORDER: Range<usize> = 21..31;
const O_TYPE: usize = 31;
const O_REF: Range<usize> = 32..42;
const O_DESCRIPTION: Range<usize> = 42..74;
const O_FIG: usize = 74;
const O_STATUS: usize = 114;
const O_FLAGS: Range<usize> = 115..120;
const O_LINES: usize = 120;
const O_DEDUCT_DAYS: usize = 121;
const O_DEDUCT_AMT: Range<usize> = 122..126;
const O_DEDUCT_VAT: Range<usize> = 126..130;
const O_DAYS: usize = 130;
/// Four-byte `ih-cr`, of which only 131..134 exists inside the record.
const O_CR: usize = 131;
const CR_PERSISTED: usize = 3;
// Line overlay.
const O_LINE_NO: usize = 9;
const O_PRODUCT: Range<usize> = 10..23;
const O_PA: Range<usize> = 23..25;
const O_QTY: Range<usize> = 25..27;
const O_LINE_TYPE: usize = 27;
const O_DESCRIPTION_L: Range<usize> = 28..60;
const O_NET: usize = 60;
const O_UNIT: usize = 65;
const O_DISCOUNT: Range<usize> = 70..72;
const O_VAT: usize = 72;
const O_VAT_CODE: usize = 77;
const O_UPDATE_L: usize = 78;
const O_FILLER: usize = 79;
const O_TAIL: Range<usize> = 80..ACAS_INVOICE_RECORD_BYTES;

fn read_fixed<const N: usize>(b: &[u8], at: usize) -> [u8; N] {
    b[at..at + N].try_into().expect("fixed-width slice")
}

fn packed_at(b: &[u8], at: usize) -> [u8; FIG_BYTES] {
    b[at..at + FIG_BYTES].try_into().expect("packed field")
}

fn parse_number(b: &[u8], at: Range<usize>) -> Result<u32, InvoiceError> {
    let text = std::str::from_utf8(&b[at]).map_err(|_| InvoiceError::UnparsableNumber)?;
    text.trim()
        .parse::<u32>()
        .map_err(|_| InvoiceError::UnparsableNumber)
}

fn write_number(out: &mut [u8], at: Range<usize>, n: u32) -> Result<(), InvoiceError> {
    if n > 99_999_999 {
        return Err(InvoiceError::NumberOutOfRange(n));
    }
    let width = at.len();
    out[at].copy_from_slice(format!("{n:0width$}").as_bytes());
    Ok(())
}

/// `ih-cr` decode: three persisted bytes, high byte absent (F-B006).
fn read_cr(b: &[u8]) -> i32 {
    let mut raw = [0u8; 4];
    raw[..CR_PERSISTED].copy_from_slice(&b[O_CR..O_CR + CR_PERSISTED]);
    i32::from_le_bytes(raw)
}

impl InvoiceHeader {
    pub fn from_bytes(b: &[u8]) -> Result<Self, InvoiceError> {
        if b.len() != ACAS_INVOICE_RECORD_BYTES {
            return Err(InvoiceError::WrongLength(b.len()));
        }
        if InvoiceLineNo::from_cobol(b[O_ITEM]) != InvoiceLineNo::Header {
            return Err(InvoiceError::ItemNosMarker(b[O_ITEM]));
        }
        let figures = std::array::from_fn(|i| PackedMoney::from_raw(packed_at(b, O_FIG + i * FIG_BYTES)));
        Ok(Self {
            invoice_nos: InvoiceNumber(parse_number(b, O_INVOICE)?),
            invoice_let: InvoiceLetter(b[O_LETTER]),
            customer: CustomerKey(read_fixed(b, O_CUSTOMER.start)),
            date: CobolDate(i32::from_le_bytes(read_fixed(b, O_DATE.start))),
            order: read_fixed(b, O_ORDER.start),
            invoice_type: InvoiceType::from_cobol(b[O_TYPE]),
            reference: read_fixed(b, O_REF.start),
            description: read_fixed(b, O_DESCRIPTION.start),
            figures,
            status: HeaderStatus::from_cobol(b[O_STATUS]),
            status_flags: std::array::from_fn(|i| StatusFlag(b[O_FLAGS.start + i])),
            lines: b[O_LINES],
            deduct_days: b[O_DEDUCT_DAYS],
            deduct_amt: CompAmount::from_raw(read_fixed(b, O_DEDUCT_AMT.start)),
            deduct_vat: CompAmount::from_raw(read_fixed(b, O_DEDUCT_VAT.start)),
            days: b[O_DAYS],
            cr: CobolDate(read_cr(b)),
            // Bytes 135/136 are outside the record: COBOL's MOVE pads with
            // spaces, so a fresh read always yields space here (F-B006).
            day_book_flag: b' ',
            update: b' ',
        })
    }

    pub fn to_bytes(self) -> Result<[u8; ACAS_INVOICE_RECORD_BYTES], InvoiceError> {
        let mut out = [b' '; ACAS_INVOICE_RECORD_BYTES];
        write_number(&mut out, O_INVOICE, self.invoice_nos.0)?;
        out[O_LETTER] = self.invoice_let.0;
        out[O_ITEM] = InvoiceLineNo::Header.to_cobol();
        out[O_CUSTOMER].copy_from_slice(&self.customer.0);
        out[O_DATE].copy_from_slice(&self.date.0.to_le_bytes());
        out[O_ORDER].copy_from_slice(&self.order);
        out[O_TYPE] = self.invoice_type.to_cobol();
        out[O_REF].copy_from_slice(&self.reference);
        out[O_DESCRIPTION].copy_from_slice(&self.description);
        for (i, value) in self.figures.iter().enumerate() {
            let at = O_FIG + i * FIG_BYTES;
            out[at..at + FIG_BYTES].copy_from_slice(&value.raw());
        }
        out[O_STATUS] = self.status.to_cobol();
        for (i, flag) in self.status_flags.iter().enumerate() {
            out[O_FLAGS.start + i] = flag.0;
        }
        out[O_LINES] = self.lines;
        out[O_DEDUCT_DAYS] = self.deduct_days;
        out[O_DEDUCT_AMT].copy_from_slice(&self.deduct_amt.raw());
        out[O_DEDUCT_VAT].copy_from_slice(&self.deduct_vat.raw());
        out[O_DAYS] = self.days;
        // The MOVE truncates at the record edge; only three bytes survive.
        out[O_CR..O_CR + CR_PERSISTED].copy_from_slice(&self.cr.0.to_le_bytes()[..CR_PERSISTED]);
        Ok(out)
    }
}

impl InvoiceLine {
    pub fn from_bytes(b: &[u8]) -> Result<Self, InvoiceError> {
        if b.len() != ACAS_INVOICE_RECORD_BYTES {
            return Err(InvoiceError::WrongLength(b.len()));
        }
        let item = b[O_ITEM];
        if item == 0 {
            return Err(InvoiceError::ItemNosMarker(item));
        }
        Ok(Self {
            invoice_nos: InvoiceNumber(parse_number(b, O_INVOICE)?),
            invoice_let: InvoiceLetter(b[O_LETTER]),
            line_no: b[O_LINE_NO],
            product: read_fixed(b, O_PRODUCT.start),
            pa: read_fixed(b, O_PA.start),
            qty: i16::from_le_bytes(read_fixed(b, O_QTY.start)),
            line_type: b[O_LINE_TYPE],
            description: read_fixed(b, O_DESCRIPTION_L.start),
            net: PackedMoney::from_raw(packed_at(b, O_NET)),
            unit: PackedMoney::from_raw(packed_at(b, O_UNIT)),
            discount: CompRate::from_raw(read_fixed(b, O_DISCOUNT.start)),
            vat: PackedMoney::from_raw(packed_at(b, O_VAT)),
            vat_code: b[O_VAT_CODE],
            update: b[O_UPDATE_L],
            filler: b[O_FILLER],
            tail: RecordTail::new(read_fixed(b, O_TAIL.start)),
        })
    }

    pub fn to_bytes(self) -> Result<[u8; ACAS_INVOICE_RECORD_BYTES], InvoiceError> {
        if self.line_no == 0 {
            return Err(InvoiceError::ItemNosMarker(0));
        }
        let mut out = [b' '; ACAS_INVOICE_RECORD_BYTES];
        write_number(&mut out, O_INVOICE, self.invoice_nos.0)?;
        out[O_LETTER] = self.invoice_let.0;
        out[O_LINE_NO] = self.line_no;
        out[O_ITEM] = self.line_no;
        out[O_PRODUCT].copy_from_slice(&self.product);
        out[O_PA].copy_from_slice(&self.pa);
        out[O_QTY].copy_from_slice(&self.qty.to_le_bytes());
        out[O_LINE_TYPE] = self.line_type;
        out[O_DESCRIPTION_L].copy_from_slice(&self.description);
        out[O_NET..O_NET + FIG_BYTES].copy_from_slice(&self.net.raw());
        out[O_UNIT..O_UNIT + FIG_BYTES].copy_from_slice(&self.unit.raw());
        out[O_DISCOUNT].copy_from_slice(&self.discount.raw());
        out[O_VAT..O_VAT + FIG_BYTES].copy_from_slice(&self.vat.raw());
        out[O_VAT_CODE] = self.vat_code;
        out[O_UPDATE_L] = self.update;
        out[O_FILLER] = self.filler;
        out[O_TAIL].copy_from_slice(&self.tail.raw());
        Ok(out)
    }
}

impl InvoiceRow {
    /// Decode a 134-byte record, dispatching on `item-nos`.
    pub fn from_bytes(b: &[u8]) -> Result<Self, InvoiceError> {
        if b.len() != ACAS_INVOICE_RECORD_BYTES {
            return Err(InvoiceError::WrongLength(b.len()));
        }
        match InvoiceLineNo::from_cobol(b[O_ITEM]) {
            InvoiceLineNo::Header => Ok(InvoiceRow::Header(InvoiceHeader::from_bytes(b)?)),
            InvoiceLineNo::Line(_) => Ok(InvoiceRow::Line(InvoiceLine::from_bytes(b)?)),
        }
    }

    /// Encode for parity against COBOL-written fixtures.
    pub fn to_bytes(&self) -> Result<[u8; ACAS_INVOICE_RECORD_BYTES], InvoiceError> {
        match self {
            InvoiceRow::Header(h) => h.clone().to_bytes(),
            InvoiceRow::Line(l) => l.clone().to_bytes(),
        }
    }
}

impl fmt::Display for InvoiceNumber {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:08}", self.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Both records were WRITTEN BY GnuCOBOL through ACAS's own overlays
    /// (`fixtures/isam_probe/capture.sh`, F-B006), so these are captured
    /// bytes, not bytes we constructed and then congratulated ourselves on.
    fn capture() -> Vec<u8> {
        std::fs::read(format!(
            "{}/../../fixtures/generated/capture/invoice-capture.dat",
            env!("CARGO_MANIFEST_DIR")
        ))
        .expect("run fixtures/isam_probe/capture.sh")
    }

    fn record_at(captured: &[u8], index: usize) -> &[u8] {
        &captured[index * ACAS_INVOICE_RECORD_BYTES..(index + 1) * ACAS_INVOICE_RECORD_BYTES]
    }

    #[test]
    fn capture_file_is_two_records() {
        assert_eq!(capture().len(), 2 * ACAS_INVOICE_RECORD_BYTES);
    }

    #[test]
    fn full_header_record_round_trips_byte_identically() {
        let captured = capture();
        let raw = record_at(&captured, 0);
        let row = InvoiceRow::from_bytes(raw).expect("header decodes");
        assert_eq!(row.to_bytes().unwrap().as_slice(), raw);
    }

    #[test]
    fn full_line_record_round_trips_byte_identically() {
        let captured = capture();
        let raw = record_at(&captured, 1);
        let row = InvoiceRow::from_bytes(raw).expect("line decodes");
        assert_eq!(row.to_bytes().unwrap().as_slice(), raw);
    }

    #[test]
    fn captured_header_fields_land_at_the_measured_offsets() {
        let captured = capture();
        let header = InvoiceHeader::from_bytes(record_at(&captured, 0)).unwrap();
        assert_eq!(header.invoice_nos, InvoiceNumber(42));
        assert_eq!(header.invoice_let, InvoiceLetter(b'L'));
        assert_eq!(header.customer.nos(), *b"CUST01");
        assert_eq!(header.customer.check_digit(), b'7');
        assert_eq!(header.date, CobolDate(155_534));
        assert_eq!(&header.order, b"ORDER-0001");
        assert_eq!(header.invoice_type, InvoiceType::Invoice);
        assert_eq!(&header.reference, b"REF-000001");
        assert_eq!(&header.description, b"abcdefghijklmnopqrstuvwxyz012345");
        assert_eq!(header.lines, 7);
        assert_eq!(header.deduct_days, 9);
        assert_eq!(header.deduct_amt.hundredths(), 12_345);
        assert_eq!(header.deduct_vat.hundredths(), 6_789);
        assert_eq!(header.days, 3);
    }

    #[test]
    fn captured_line_fields_land_at_the_measured_offsets() {
        let captured = capture();
        let line = InvoiceLine::from_bytes(record_at(&captured, 1)).unwrap();
        assert_eq!(line.line_no, 3);
        assert_eq!(&line.product, b"PRODUCT-00001");
        assert_eq!(&line.pa, b"PA");
        assert_eq!(line.qty, 17);
        assert!(line.is_credit());
        assert_eq!(line.discount.hundredths(), 1_234);
        assert_eq!(line.vat_code, b'8');
        assert_eq!(line.update, b'z');
        assert!(line.analysed());
        assert_eq!(line.tail.raw(), [b' '; 54]);
    }

    #[test]
    fn money_is_nibble_exact_across_the_whole_range() {
        for cents in [0, 1, -1, 99, 100, 123_456_789, -123_456_789, PACKED_MONEY_MAX_CENTS, -PACKED_MONEY_MAX_CENTS] {
            let money = PackedMoney::from_cents(cents).unwrap();
            assert_eq!(money.cents(), cents, "round trip at {cents}");
            assert_eq!(PackedMoney::from_raw(money.raw()), money);
        }
    }

    #[test]
    fn money_matches_the_bytes_gnucobol_writes() {
        // Sentinels from the capture (F-B006): +1234.56, -7654.32, +9999.99.
        assert_eq!(PackedMoney::from_cents(123_456).unwrap().raw(), [0x00, 0x01, 0x23, 0x45, 0x6C]);
        assert_eq!(PackedMoney::from_cents(-765_432).unwrap().raw(), [0x00, 0x07, 0x65, 0x43, 0x2D]);
        assert_eq!(PackedMoney::from_cents(999_999).unwrap().raw(), [0x00, 0x09, 0x99, 0x99, 0x9C]);
        assert_eq!(PackedMoney::from_raw([0x00, 0x01, 0x23, 0x45, 0x6D]).cents(), -123_456);
    }

    #[test]
    fn money_rejects_packed_overflow() {
        assert!(PackedMoney::from_cents(PACKED_MONEY_MAX_CENTS + 1).is_err());
        assert!(PackedMoney::from_cents(-PACKED_MONEY_MAX_CENTS - 1).is_err());
    }

    #[test]
    fn unknown_status_bytes_survive_round_trip() {
        let captured = capture();
        let raw = record_at(&captured, 0);
        for byte in [b'P', b'I', b'z', b'Z', b' ', b'Q', 0x00, 0xFF] {
            let mut mutated = raw.to_vec();
            mutated[O_STATUS] = byte;
            mutated[O_FLAGS.start] = byte;
            let row = InvoiceRow::from_bytes(&mutated).unwrap();
            assert_eq!(row.to_bytes().unwrap().as_slice(), mutated.as_slice(), "status {byte:#04x}");
        }
    }

    #[test]
    fn applied_status_keeps_its_case() {
        assert_eq!(HeaderStatus::from_cobol(b'z'), HeaderStatus::Applied(b'z'));
        assert_eq!(HeaderStatus::from_cobol(b'Z'), HeaderStatus::Applied(b'Z'));
        assert_eq!(HeaderStatus::from_cobol(b'Z').to_cobol(), b'Z');
        assert_eq!(HeaderStatus::from_cobol(0x00), HeaderStatus::Other(0x00));
    }

    #[test]
    fn status_flags_read_as_set_on_any_letter() {
        assert!(!StatusFlag(b' ').is_set());
        assert!(StatusFlag::set(b'l').is_set());
    }

    #[test]
    fn cr_keeps_three_bytes_and_the_day_book_update_flags_are_memory_only() {
        let captured = capture();
        let mut header = InvoiceHeader::from_bytes(record_at(&captured, 0)).unwrap();
        assert_eq!(header.cr, CobolDate(155_564), "24-bit value survives");

        header.cr = CobolDate(0x00AB_CDEF);
        header.day_book_flag = b'B';
        header.update = b'Z';
        assert!(header.day_booked() && header.analysed());

        let row = InvoiceRow::Header(header).to_bytes().unwrap();
        assert_eq!(&row[O_CR..O_CR + CR_PERSISTED], &[0xEF, 0xCD, 0xAB], "low 3 bytes only");

        // Re-decoded: cr is truncated, and the two flags come back blank
        // because bytes 135/136 do not exist in the frame (F-B006).
        let reread = InvoiceHeader::from_bytes(&row).unwrap();
        assert_eq!(reread.cr, CobolDate(0x00AB_CDEF));
        assert_eq!(reread.day_book_flag, b' ');
        assert_eq!(reread.update, b' ');
        assert!(!reread.day_booked() && !reread.analysed());
    }

    #[test]
    fn wrong_length_and_mismatched_marker_are_errors() {
        assert_eq!(InvoiceRow::from_bytes(&[0u8; 100]).unwrap_err(), InvoiceError::WrongLength(100));

        let captured = capture();
        let header_bytes = record_at(&captured, 0);
        assert_eq!(InvoiceHeader::from_bytes(record_at(&captured, 1)).unwrap_err(), InvoiceError::ItemNosMarker(3));
        assert_eq!(InvoiceLine::from_bytes(header_bytes).unwrap_err(), InvoiceError::ItemNosMarker(0));
    }

    #[test]
    fn out_of_range_invoice_number_is_rejected() {
        let mut header = InvoiceHeader::from_bytes(record_at(&capture(), 0)).unwrap();
        header.invoice_nos = InvoiceNumber(100_000_000);
        assert_eq!(header.to_bytes().unwrap_err(), InvoiceError::NumberOutOfRange(100_000_000));
    }

/// The harness corpus itself must survive a Rust round trip unchanged,
    /// record for record — the same claim the COBOL rewrite makes (run
    /// `harness/runs/*-sl055-wp03`): COBOL re-wrote these exact 836 bytes
    /// with zero diffs.
    #[test]
    fn every_harness_fixture_record_round_trips() {
        let corpus = std::fs::read(format!(
            "{}/../../fixtures/generated/clean/invoice.dat",
            env!("CARGO_MANIFEST_DIR")
        ))
        .expect("run fixtures/fdinv2_builder.py fixtures/generated clean");
        let records = corpus.len() / ACAS_INVOICE_RECORD_BYTES;
        assert_eq!(records, 6, "2 invoices x (header + 2 lines)");
        for index in 0..records {
            let raw = record_at(&corpus, index);
            let row = InvoiceRow::from_bytes(raw).unwrap_or_else(|e| panic!("record {index}: {e}"));
            assert_eq!(row.to_bytes().unwrap().as_slice(), raw, "record {index}");
        }
    }

    #[test]
    fn invoice_number_pads_to_eight_digits() {
        assert_eq!(InvoiceNumber(42).to_string(), "00000042");
    }
}
