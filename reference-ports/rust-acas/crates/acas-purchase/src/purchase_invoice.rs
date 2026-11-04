//! Purchase invoice record types ported from `purchase/fdpinv2.cob`.
//!
//! Every field, offset and width here is measured off bytes GnuCOBOL itself
//! writes — see `docs/fd-evidence/F-B055-pl055-invoice-and-oi4-records.md`.
//! Field dispositions are in `docs/disposition-pl055.md`.
//!
//! ## Design notes (L2R-005, L2R-006)
//!
//! `invoice-record` is polymorphic on disk exactly like the sales record: one
//! 129-byte frame holds a *header* (item byte = 0) or a *line* (anything else),
//! and the application dispatches at READ time. The `match` is the feature;
//! the shared undifferentiated frame is the idiom. Rust gets an enum.
//!
//! ## What differs from the sales cut
//!
//! - No `invoice-let`: purchase keys invoices by number alone, and the second
//!   key character is the item number.
//! - No description on the header and no `ih-status-{P,L,C,A,I}` flag bytes:
//!   purchase never prints invoices, so the print/held columns are gone.
//! - **Nothing is truncated.** The header overlay is exactly 129 bytes on a
//!   129-byte FD, so `ih-update`/`ih-day-book-flag`/`ih-lines` do reach disk
//!   and a re-run really does see the analysed flag (F-B055 Part 1). The
//!   line overlay is 74 bytes in the same frame; bytes 74..129 are not its
//!   field area and ride along as `tail`.

use acas_common::cobol_date::CobolDate;

/// `fdpinv2.cob` — the FD record is always 129 bytes, and so is the header
/// overlay. There is no truncation to carry.
pub const ACAS_INVOICE_RECORD_BYTES: usize = 129;
/// Byte offset of the field that tells a header from a line.
pub const ITEM_BYTE_OFFSET: usize = 8;
/// `ih-fig` — the packed money group: p-c, net, extra, carriage, vat,
/// discount, e-vat, c-vat.
pub const FIG_FIELDS: usize = 8;
/// Packed field width for `s9(7)v99`.
const FIG_BYTES: usize = 5;
/// `fdanal.cob` record.
pub const ANALYSIS_RECORD_BYTES: usize = 36;
/// `fdval.cob` record.
pub const VALUE_RECORD_BYTES: usize = 66;
/// `fdoi4.cob` record.
pub const OPEN_ITEM4_RECORD_BYTES: usize = 109;

/// Invoice number. `9(8)` **display**: eight ASCII digits on the wire.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize,
)]
pub struct InvoiceNumber(pub u32);

impl InvoiceNumber {
    fn to_digits(self) -> [u8; 8] {
        let mut out = [b'0'; 8];
        let mut value = self.0;
        for slot in out.iter_mut().rev() {
            *slot = b'0' + (value % 10) as u8;
            value /= 10;
        }
        out
    }

    /// Eight display digits, high digits dropped by the `9(8)` size.
    pub fn from_digits(bytes: &[u8]) -> Self {
        let mut value = 0u32;
        for byte in &bytes[..8] {
            value = value * 10 + u32::from(byte.wrapping_sub(b'0') % 10);
        }
        Self(value)
    }
}

/// `ih-supplier` / `oi-supplier` — six digits plus the modulus check digit.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize,
)]
pub struct SupplierKey(pub [u8; 7]);

impl SupplierKey {
    pub fn nos(&self) -> [u8; 6] {
        self.0[..6].try_into().expect("6 of 7 bytes")
    }
    pub fn check_digit(&self) -> u8 {
        self.0[6]
    }
}

/// `ih-type` / `oi-type` — the digit is the truth, and out-of-range types are
/// carried rather than rejected (pl055 never validates it).
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize,
)]
pub struct InvoiceType(pub u8);

impl InvoiceType {
    // The stored byte is the *character*, so the constants are characters too.
    pub const RECEIPT: Self = Self(b'1');
    pub const INVOICE: Self = Self(b'2');
    pub const CREDIT_NOTE: Self = Self(b'3');
    pub const PROFORMA: Self = Self(b'4');

    pub fn is_credit(self) -> bool {
        self.0 == b'3'
    }
    pub fn is_receipt(self) -> bool {
        self.0 == b'1'
    }
    pub fn is_invoice(self) -> bool {
        self.0 == b'2'
    }
}

/// `s9(7)v99 comp-3` — five bytes, sign in the low nibble of the last. Raw
/// bytes are authoritative; `cents` is the arithmetic view.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct PackedMoney([u8; FIG_BYTES]);

/// Magnitude cap of `s9(7)v99`, in hundredths.
pub const PACKED_MONEY_MAX_CENTS: i64 = 999_999_999;

impl PackedMoney {
    pub const ZERO: Self = Self([0, 0, 0, 0, 0x0C]);

    pub const fn from_raw(raw: [u8; FIG_BYTES]) -> Self {
        Self(raw)
    }
    pub const fn raw(&self) -> [u8; FIG_BYTES] {
        self.0
    }

    /// Hundredths. The trailing nibble is the sign: `D`/`B` negative,
    /// everything else positive — as libcob reads it.
    pub fn cents(&self) -> i64 {
        let mut magnitude = 0i64;
        for byte in &self.0[..4] {
            magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
        }
        magnitude = magnitude * 10 + i64::from(self.0[4] >> 4);
        if matches!(self.0[4] & 0x0F, 0x0D | 0x0B) {
            -magnitude
        } else {
            magnitude
        }
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
        let mut out = [0u8; FIG_BYTES];
        for (index, byte) in out.iter_mut().take(4).enumerate() {
            *byte = (digits[index * 2] << 4) | digits[index * 2 + 1];
        }
        out[4] = (digits[8] << 4) | if cents < 0 { 0x0D } else { 0x0C };
        Ok(Self(out))
    }

    /// `multiply -1 by` — negate in place, sign nibble only.
    pub fn negate(&mut self) {
        self.0[4] = (self.0[4] & 0xF0) | if self.cents() < 0 { 0x0C } else { 0x0D };
    }
}

/// `999v99 comp` / `s999v99 comp` — four bytes big-endian binary.
#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    PartialOrd,
    Ord,
    Hash,
    Default,
    serde::Serialize,
    serde::Deserialize,
)]
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
    pub fn from_hundredths(value: u32) -> Self {
        Self(value.to_be_bytes())
    }
}

/// `ih-status` — `88 pending`/`invoiced`/`applied`, case preserved because the
/// 88-levels accept both cases and ACAS writes both.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum HeaderStatus {
    Pending,
    Invoiced,
    Applied(u8),
    Other(u8),
}

impl HeaderStatus {
    pub fn from_cobol(value: u8) -> Self {
        match value {
            b'p' | b'P' => Self::Pending,
            b'i' | b'I' => Self::Invoiced,
            b'z' | b'Z' => Self::Applied(value),
            other => Self::Other(other),
        }
    }
    pub fn to_cobol(self) -> u8 {
        match self {
            Self::Pending => b'p',
            Self::Invoiced => b'i',
            Self::Applied(value) | Self::Other(value) => value,
        }
    }
    pub fn is_applied(self) -> bool {
        matches!(self, Self::Applied(_))
    }
}

/// Decoder failure for a value that will not fit its field.
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum InvoiceError {
    #[error("packed amount {0} does not fit s9(7)v99")]
    PackedOverflow(i64),
}

/// Bytes 74..129 of the record: outside the line overlay but inside the frame.
/// serde's array impls stop at 32, so this one serialises as bytes by hand.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LineTail(pub [u8; ACAS_INVOICE_RECORD_BYTES - 74]);

impl Default for LineTail {
    fn default() -> Self {
        Self([b' '; ACAS_INVOICE_RECORD_BYTES - 74])
    }
}

impl serde::Serialize for LineTail {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_bytes(&self.0)
    }
}

impl<'de> serde::Deserialize<'de> for LineTail {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        struct Visitor;
        impl<'de> serde::de::Visitor<'de> for Visitor {
            type Value = LineTail;
            fn expecting(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                f.write_str("55 tail bytes")
            }
            fn visit_bytes<E: serde::de::Error>(self, v: &[u8]) -> Result<LineTail, E> {
                let tail: [u8; ACAS_INVOICE_RECORD_BYTES - 74] = v
                    .try_into()
                    .map_err(|_| E::invalid_length(v.len(), &self))?;
                Ok(LineTail(tail))
            }
            fn visit_seq<A: serde::de::SeqAccess<'de>>(
                self,
                mut seq: A,
            ) -> Result<LineTail, A::Error> {
                let mut tail = [b' '; ACAS_INVOICE_RECORD_BYTES - 74];
                for slot in tail.iter_mut() {
                    *slot = seq.next_element()?.ok_or_else(|| {
                        serde::de::Error::invalid_length(ACAS_INVOICE_RECORD_BYTES - 74, &self)
                    })?;
                }
                Ok(LineTail(tail))
            }
        }
        deserializer.deserialize_bytes(Visitor)
    }
}

/// A record as observed on disk. Dispatch on the item byte.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum InvoiceRow {
    Header(PurchaseHeader),
    Line(PurchaseLine),
}

impl InvoiceRow {
    /// Dispatch a whole 129-byte frame. Item byte 0 is a header.
    pub fn from_bytes(bytes: &[u8; ACAS_INVOICE_RECORD_BYTES]) -> Self {
        if bytes[ITEM_BYTE_OFFSET] == 0 {
            Self::Header(PurchaseHeader::from_bytes(bytes))
        } else {
            Self::Line(PurchaseLine::from_bytes(bytes))
        }
    }

    pub fn to_bytes(&self) -> [u8; ACAS_INVOICE_RECORD_BYTES] {
        match self {
            Self::Header(header) => header.to_bytes(),
            Self::Line(line) => line.to_bytes(),
        }
    }

    pub fn invoice_nos(&self) -> InvoiceNumber {
        match self {
            Self::Header(header) => header.invoice_nos,
            Self::Line(line) => line.invoice_nos,
        }
    }

    /// Key order `(invoice-nos, item-nos)`.
    pub fn key(&self) -> (u32, u8) {
        match self {
            Self::Header(header) => (header.invoice_nos.0, 0),
            Self::Line(line) => (line.invoice_nos.0, line.line_no),
        }
    }
}

/// `invoice-header` — item byte 0.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct PurchaseHeader {
    pub invoice_nos: InvoiceNumber,
    pub supplier: SupplierKey,
    pub date: CobolDate,
    pub order: [u8; 10],
    pub invoice_type: InvoiceType,
    pub reference: [u8; 10],
    /// `ih-fig` in copybook order: p-c, net, extra, carriage, vat, discount,
    /// e-vat, c-vat.
    pub figures: [PackedMoney; FIG_FIELDS],
    pub status: HeaderStatus,
    pub lines: u8,
    pub deduct_days: u8,
    /// `999v99 comp` — **unsigned** on the invoice.
    pub deduct_amt: CompAmount,
    pub deduct_vat: CompAmount,
    pub days: u8,
    pub cr: CobolDate,
    pub day_book_flag: u8,
    pub update: u8,
    pub filler: [u8; 30],
}

impl PurchaseHeader {
    /// `88 day-booked`.
    pub fn day_booked(&self) -> bool {
        matches!(self.day_book_flag, b'b' | b'B')
    }
    /// `88 ih-analyised` — both cases.
    pub fn analysed(&self) -> bool {
        matches!(self.update, b'z' | b'Z')
    }

    pub fn from_bytes(bytes: &[u8; ACAS_INVOICE_RECORD_BYTES]) -> Self {
        let mut figures = [PackedMoney::ZERO; FIG_FIELDS];
        for (index, slot) in figures.iter_mut().enumerate() {
            *slot = PackedMoney::from_raw(
                bytes[41 + index * FIG_BYTES..41 + (index + 1) * FIG_BYTES]
                    .try_into()
                    .expect("5 packed bytes"),
            );
        }
        let mut filler = [b' '; 30];
        filler.copy_from_slice(&bytes[99..129]);
        Self {
            invoice_nos: InvoiceNumber::from_digits(&bytes[0..8]),
            supplier: SupplierKey(bytes[9..16].try_into().expect("7 supplier bytes")),
            date: CobolDate(i32::from_le_bytes(
                bytes[16..20].try_into().expect("4 date bytes"),
            )),
            order: bytes[20..30].try_into().expect("10 order bytes"),
            invoice_type: InvoiceType(bytes[30]),
            reference: bytes[31..41].try_into().expect("10 ref bytes"),
            figures,
            status: HeaderStatus::from_cobol(bytes[81]),
            lines: bytes[82],
            deduct_days: bytes[83],
            deduct_amt: CompAmount::from_raw(bytes[84..88].try_into().expect("4 bytes")),
            deduct_vat: CompAmount::from_raw(bytes[88..92].try_into().expect("4 bytes")),
            days: bytes[92],
            cr: CobolDate(i32::from_le_bytes(
                bytes[93..97].try_into().expect("4 cr bytes"),
            )),
            day_book_flag: bytes[97],
            update: bytes[98],
            filler,
        }
    }

    pub fn to_bytes(&self) -> [u8; ACAS_INVOICE_RECORD_BYTES] {
        let mut out = [b' '; ACAS_INVOICE_RECORD_BYTES];
        out[0..8].copy_from_slice(&self.invoice_nos.to_digits());
        out[8] = 0;
        out[9..16].copy_from_slice(&self.supplier.0);
        out[16..20].copy_from_slice(&self.date.0.to_le_bytes());
        out[20..30].copy_from_slice(&self.order);
        out[30] = self.invoice_type.0;
        out[31..41].copy_from_slice(&self.reference);
        for (index, figure) in self.figures.iter().enumerate() {
            out[41 + index * FIG_BYTES..41 + (index + 1) * FIG_BYTES]
                .copy_from_slice(&figure.raw());
        }
        out[81] = self.status.to_cobol();
        out[82] = self.lines;
        out[83] = self.deduct_days;
        out[84..88].copy_from_slice(&self.deduct_amt.raw());
        out[88..92].copy_from_slice(&self.deduct_vat.raw());
        out[92] = self.days;
        out[93..97].copy_from_slice(&self.cr.0.to_le_bytes());
        out[97] = self.day_book_flag;
        out[98] = self.update;
        out[99..129].copy_from_slice(&self.filler);
        out
    }
}

/// `invoice-line` — item byte non-zero. 74 bytes over the 129-byte frame.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct PurchaseLine {
    pub invoice_nos: InvoiceNumber,
    pub line_no: u8,
    pub product: [u8; 13],
    /// `il-pa` — the analysis code; its first character is the group.
    pub pa: [u8; 2],
    pub filler: [u8; 2],
    pub qty: i16,
    pub line_type: u8,
    pub description: [u8; 24],
    pub dup_filler: [u8; 2],
    pub net: PackedMoney,
    pub unit: PackedMoney,
    pub discount: u16,
    pub vat: PackedMoney,
    pub vat_code: u8,
    pub update: u8,
    pub tail: LineTail,
}

impl PurchaseLine {
    pub fn analysed(&self) -> bool {
        matches!(self.update, b'z' | b'Z')
    }
    pub fn is_credit(&self) -> bool {
        self.line_type == b'3'
    }

    pub fn from_bytes(bytes: &[u8; ACAS_INVOICE_RECORD_BYTES]) -> Self {
        let mut tail = [b' '; ACAS_INVOICE_RECORD_BYTES - 74];
        tail.copy_from_slice(&bytes[74..129]);
        Self {
            invoice_nos: InvoiceNumber::from_digits(&bytes[0..8]),
            line_no: bytes[8],
            product: bytes[9..22].try_into().expect("13 product bytes"),
            pa: bytes[22..24].try_into().expect("2 pa bytes"),
            filler: bytes[24..26].try_into().expect("2 filler bytes"),
            qty: i16::from_be_bytes(bytes[26..28].try_into().expect("2 qty bytes")),
            line_type: bytes[28],
            description: bytes[29..53].try_into().expect("24 description bytes"),
            dup_filler: bytes[53..55].try_into().expect("2 filler bytes"),
            net: PackedMoney::from_raw(bytes[55..60].try_into().expect("5 packed bytes")),
            unit: PackedMoney::from_raw(bytes[60..65].try_into().expect("5 packed bytes")),
            discount: u16::from_be_bytes(bytes[65..67].try_into().expect("2 rate bytes")),
            vat: PackedMoney::from_raw(bytes[67..72].try_into().expect("5 packed bytes")),
            vat_code: bytes[72],
            update: bytes[73],
            tail: LineTail(tail),
        }
    }

    pub fn to_bytes(&self) -> [u8; ACAS_INVOICE_RECORD_BYTES] {
        let mut out = [b' '; ACAS_INVOICE_RECORD_BYTES];
        out[0..8].copy_from_slice(&self.invoice_nos.to_digits());
        out[8] = self.line_no;
        out[9..22].copy_from_slice(&self.product);
        out[22..24].copy_from_slice(&self.pa);
        out[24..26].copy_from_slice(&self.filler);
        out[26..28].copy_from_slice(&self.qty.to_be_bytes());
        out[28] = self.line_type;
        out[29..53].copy_from_slice(&self.description);
        out[53..55].copy_from_slice(&self.dup_filler);
        out[55..60].copy_from_slice(&self.net.raw());
        out[60..65].copy_from_slice(&self.unit.raw());
        out[65..67].copy_from_slice(&self.discount.to_be_bytes());
        out[67..72].copy_from_slice(&self.vat.raw());
        out[72] = self.vat_code;
        out[73] = self.update;
        out[74..129].copy_from_slice(&self.tail.0);
        out
    }
}

/// `oi-header` (purchase `wsoi.cob`) — the open-item-4 staging record pl055
/// writes and pl060/pl070 consume. Exactly 109 bytes: every field reaches
/// disk, including `oi-applied` and `oi-date-cleared` (F-B055 Part 3).
///
/// `oi-net` and `oi-approp` are one storage; the field is named `net` here and
/// `approp` at the call sites that read it as money owed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenItem4 {
    pub supplier: SupplierKey,
    pub invoice: u32,
    pub date: i32,
    /// `9(5) comp` — cleared batch number; pl055 always writes zero.
    pub b_nos: u32,
    /// `999 comp` — cleared batch item; always zero from pl055.
    pub b_item: u16,
    pub invoice_type: u8,
    pub reference: [u8; 10],
    pub order: [u8; 10],
    pub hold_flag: u8,
    pub unapl: u8,
    /// `oi-p-c`
    pub p_c: PackedMoney,
    /// `oi-net` (`oi-approp` redefines this same storage).
    pub net: PackedMoney,
    pub extra: PackedMoney,
    pub carriage: PackedMoney,
    pub vat: PackedMoney,
    pub discount: PackedMoney,
    pub e_vat: PackedMoney,
    pub c_vat: PackedMoney,
    pub paid: PackedMoney,
    /// `oi-status` — PIC 9, the character.
    pub status: u8,
    pub deduct_days: u8,
    pub deduct_amt: i32,
    pub deduct_vat: i32,
    pub days: u8,
    pub cr: i32,
    pub applied: u8,
    pub date_cleared: i32,
}

impl OpenItem4 {
    /// `88 s-open`.
    pub fn is_open(&self) -> bool {
        self.status == b'0'
    }

    /// `multiply -1 by` over the four money legs the credit-note path negates.
    pub fn negate(&mut self) {
        self.net.negate();
        self.carriage.negate();
        self.vat.negate();
        self.c_vat.negate();
    }

    pub fn to_bytes(&self) -> [u8; OPEN_ITEM4_RECORD_BYTES] {
        let mut out = [b' '; OPEN_ITEM4_RECORD_BYTES];
        out[0..7].copy_from_slice(&self.supplier.0);
        out[7..11].copy_from_slice(&self.invoice.to_le_bytes());
        out[11..15].copy_from_slice(&self.date.to_le_bytes());
        out[15..19].copy_from_slice(&self.b_nos.to_be_bytes());
        out[19..21].copy_from_slice(&self.b_item.to_be_bytes());
        out[21] = self.invoice_type;
        out[22..32].copy_from_slice(&self.reference);
        out[32..42].copy_from_slice(&self.order);
        out[42] = self.hold_flag;
        out[43] = self.unapl;
        let figures = [
            self.p_c,
            self.net,
            self.extra,
            self.carriage,
            self.vat,
            self.discount,
            self.e_vat,
            self.c_vat,
            self.paid,
        ];
        for (index, figure) in figures.iter().enumerate() {
            let at = 44 + index * FIG_BYTES;
            out[at..at + FIG_BYTES].copy_from_slice(&figure.raw());
        }
        out[89] = self.status;
        out[90] = self.deduct_days;
        out[91..95].copy_from_slice(&self.deduct_amt.to_be_bytes());
        out[95..99].copy_from_slice(&self.deduct_vat.to_be_bytes());
        out[99] = self.days;
        out[100..104].copy_from_slice(&self.cr.to_le_bytes());
        out[104] = self.applied;
        out[105..109].copy_from_slice(&self.date_cleared.to_le_bytes());
        out
    }

    pub fn from_bytes(bytes: &[u8; OPEN_ITEM4_RECORD_BYTES]) -> Self {
        let mut figures = [PackedMoney::ZERO; 9];
        for (index, slot) in figures.iter_mut().enumerate() {
            let at = 44 + index * FIG_BYTES;
            *slot = PackedMoney::from_raw(bytes[at..at + FIG_BYTES].try_into().expect("5 bytes"));
        }
        Self {
            supplier: SupplierKey(bytes[0..7].try_into().expect("7 supplier bytes")),
            invoice: u32::from_le_bytes(bytes[7..11].try_into().expect("4 bytes")),
            date: i32::from_le_bytes(bytes[11..15].try_into().expect("4 bytes")),
            b_nos: u32::from_be_bytes(bytes[15..19].try_into().expect("4 bytes")),
            b_item: u16::from_be_bytes(bytes[19..21].try_into().expect("2 bytes")),
            invoice_type: bytes[21],
            reference: bytes[22..32].try_into().expect("10 bytes"),
            order: bytes[32..42].try_into().expect("10 bytes"),
            hold_flag: bytes[42],
            unapl: bytes[43],
            p_c: figures[0],
            net: figures[1],
            extra: figures[2],
            carriage: figures[3],
            vat: figures[4],
            discount: figures[5],
            e_vat: figures[6],
            c_vat: figures[7],
            paid: figures[8],
            status: bytes[89],
            deduct_days: bytes[90],
            deduct_amt: i32::from_be_bytes(bytes[91..95].try_into().expect("4 bytes")),
            deduct_vat: i32::from_be_bytes(bytes[95..99].try_into().expect("4 bytes")),
            days: bytes[99],
            cr: i32::from_le_bytes(bytes[100..104].try_into().expect("4 bytes")),
            applied: bytes[104],
            date_cleared: i32::from_le_bytes(bytes[105..109].try_into().expect("4 bytes")),
        }
    }
}
