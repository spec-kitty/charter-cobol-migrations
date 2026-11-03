//! Invoice record types ported from `copybooks/fdinv2.cob`.
//!
//! Field dispositions are tracked in `docs/disposition.yaml` against
//! `fdinv2.cob` — this type's shape follows those decisions.
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
//! with two strong variants that share a 134-byte serde framing. The
//! on-disk positional overlap (both variants start at byte 0) is retained
//! because the parity harness demands byte-identical staging output.

use std::fmt;
use thiserror::Error;

/// `fdinv2.cob` — Physical disk record always 134 bytes (post P-B001 era;
/// earlier 129-byte files treated as legacy migration target, not exercised
/// in the golden-master corpus).
pub const ACAS_INVOICE_RECORD_BYTES: usize = 134;

/// Invoice number space. 9(8) → up to 99_999_999. Bounded, so we keep the
/// bounded int, not a newtype over String.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, serde::Serialize, serde::Deserialize)]
pub struct InvoiceNumber(pub u32);

/// Trailing letter tag on invoice ID — COBOL x field carrying A-Z
/// distinguishing duplicates (e.g. manual duplicates). Carried, not retired:
/// the *feature* is real (manual-duplicate invoices exist in production).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct InvoiceLetter(pub u8);  // raw ASCII; A-Z expected but byte space is the truth

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
pub struct CobolDate(pub i32);  // days since 1900-01-01; negative allowed

/// Invoice kind — `invoice-type` field as PIC 9 (one digit), observed values
/// in sl055: 1 = invoice?, 3 = credit note, 4 = proforma. Treat unknown
/// values as `Other(u8)` (not an error) — L2R-005 disposition.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub enum InvoiceType {
    Invoice,
    CreditNote,
    Proforma,
    /// Preserved so files with unknown codes don't kill the deserializer.
    /// Reads as acategory we'd rather see than silently miss.
    Other(u8),
}

impl InvoiceType {
    pub fn from_cobol(v: u8) -> Self {
        match v { 1 => Self::Invoice, 3 => Self::CreditNote,
                  4 => Self::Proforma, x => Self::Other(x) }
    }
    pub fn to_cobol(self) -> u8 {
        match self { Self::Invoice => 1, Self::CreditNote => 3,
                     Self::Proforma => 4, Self::Other(x) => x }
    }
}

/// Customer key is PIC X(7) in ACAS. Keep it as raw bytes: ACAS compares
/// customer codes positionally, and the possibility of non-ASCII codes is
/// part of the file format.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct CustomerKey(pub [u8; 7]);

/// Invoice record asobserved on disk. Dispatch on `line_no`.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub enum InvoiceRow {
    Header(InvoiceHeader),
    Line(InvoiceLine),
}

/// 01 invoice-record (header variant; item_nos=0). Fields as in fdinv2.cob.
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct InvoiceHeader {
    pub invoice_nos: InvoiceNumber,
    pub invoice_let: InvoiceLetter,
    pub customer: CustomerKey,
    pub date: CobolDate,
    pub invoice_type: InvoiceType,
    /* — remaining fields (order, extra, vat splits) skipped pending full
       dispositions of every FD field; the *shape* contract is what matters
       here. Adding fields is L2R-005-registered as dispositions accrete. — */
    /// The 5 unknown bytes appended 17/05/13 between the 2009 baseline (129B)
    /// and the current layout (134B). Kept as is — fossil, behavior preserved.
    pub filler_2013: [u8; 5],
}

/// Line-item variant (item_nos != 0).
#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
pub struct InvoiceLine {
    pub invoice_nos: InvoiceNumber,
    pub invoice_let: InvoiceLetter,
    pub line_no: u8,       // 1..=99
    pub customer: CustomerKey,
    pub date: CobolDate,
    pub filler_2013: [u8; 5],
    /* remaining line-fields (product, net, vat, etc.) accrete alongside the
       copybook-inventory work — see sl055's il-* references */
}

#[derive(Debug, Error)]
pub enum InvoiceError {
    #[error("record not 134 bytes (got {0})")]
    WrongLength(usize),
    #[error("item-nos out of range ({0})")]
    ItemNosOutOfRange(u8),
}

impl InvoiceRow {
    /// Decode from the fixed 134-byte on-disk record. Length check totals
    /// enforce the positional-interleaving contract.
    pub fn from_bytes(b: &[u8]) -> Result<Self, InvoiceError> {
        if b.len() != ACAS_INVOICE_RECORD_BYTES {
            return Err(InvoiceError::WrongLength(b.len()));
        }
        let invoice_nos = u32::from_str_radix(
            std::str::from_utf8(&b[0..8]).map_err(|_| InvoiceError::WrongLength(0))?, 10
        ).map_err(|_| InvoiceError::WrongLength(0))?;
        let invoice_let = InvoiceLetter(b[8]);
        let item_nos = b[9];
        let customer = {
            let mut c = [0u8; 7];
            c.copy_from_slice(&b[10..17]);
            CustomerKey(c)
        };
        let date_days = i32::from_le_bytes([b[17], b[18], b[19], b[20]]);
        let invoice_type = InvoiceType::from_cobol(b[31]);

        match InvoiceLineNo::from_cobol(item_nos) {
            InvoiceLineNo::Header => Ok(InvoiceRow::Header(InvoiceHeader {
                invoice_nos: InvoiceNumber(invoice_nos),
                invoice_let,
                customer,
                date: CobolDate(date_days),
                invoice_type,
                filler_2013: b[129..134].try_into().unwrap(),
            })),
            InvoiceLineNo::Line(n) => Ok(InvoiceRow::Line(InvoiceLine {
                invoice_nos: InvoiceNumber(invoice_nos),
                invoice_let,
                line_no: n,
                customer,
                date: CobolDate(date_days),
                filler_2013: b[129..134].try_into().unwrap(),
            })),
        }
    }

    /// Re-encode to wire bytes for parity against COBOL-written fixtures.
    pub fn to_bytes(&self) -> [u8; ACAS_INVOICE_RECORD_BYTES] {
        let mut out = [0u8; ACAS_INVOICE_RECORD_BYTES];
        let (invoice_nos, letter, item, cust, date, f13) = match self {
            InvoiceRow::Header(h) =>
                (h.invoice_nos, h.invoice_let, InvoiceLineNo::Header, h.customer, h.date, h.filler_2013),
            InvoiceRow::Line(l) =>
                (l.invoice_nos, l.invoice_let, InvoiceLineNo::Line(l.line_no), l.customer, l.date, l.filler_2013),
        };
        // COBOL PIC 9(8) = 8-char right-justified zero-padded numeric
        let s = format!("{:08}", invoice_nos.0);
        out[0..8].copy_from_slice(s.as_bytes());
        out[8] = letter.0;
        out[9] = item.to_cobol();
        out[10..17].copy_from_slice(&cust.0);
        out[17..21].copy_from_slice(&date.0.to_le_bytes());
        out[31] = match match self {
            InvoiceRow::Header(h) => h.invoice_type,
            InvoiceRow::Line(_) => InvoiceType::Other(0),
        } { t => t.to_cobol() };
        // bytes 21..30 = filler (kept as zeroes = "spaces" in binary world;
        // exact value comes from fixture capture)
        out[129..134].copy_from_slice(&f13);
        out
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

    #[test]
    fn roundtrip_preserves_bytes() {
        let mut b = [0u8; ACAS_INVOICE_RECORD_BYTES];
        b[0..8].copy_from_slice(b"00000042");
        b[8] = b'A';
        b[9] = 0;                    // header
        b[10..17].copy_from_slice(b"CUST001");
        b[17..21].copy_from_slice(&24000i32.to_le_bytes());
        b[31] = 1;
        b[129..134].copy_from_slice(&[1,2,3,4,5]);
        let row = InvoiceRow::from_bytes(&b).unwrap();
        assert_eq!(row.to_bytes(), b);
    }

    #[test]
    fn rejects_wrong_length() {
        assert!(InvoiceRow::from_bytes(&[0u8; 100]).is_err());
    }

    #[test]
    fn line_variant_routes() {
        let mut b = [0u8; ACAS_INVOICE_RECORD_BYTES];
        b[0..8].copy_from_slice(b"00000042");
        b[8] = b'A';
        b[9] = 3;                    // line 3
        let row = InvoiceRow::from_bytes(&b).unwrap();
        match row {
            InvoiceRow::Line(l) => assert_eq!(l.line_no, 3),
            _ => panic!("expected line variant"),
        }
    }
}
