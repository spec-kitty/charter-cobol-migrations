//! acas-purchase: purchase-ledger (AP) port of ACAS purchase/.
//!
//! Purchase is a subset of the sales behaviour (upstream readme: "for
//! Purchase, users can use sales as it uses a subset of sales"), but the
//! records are *not* the sales records — `fdpinv2.cob` and `fdoi4.cob` are
//! shorter, re-ordered cuts with no truncation (F-B055). Reusing the sales
//! types would have been wrong in the offsets.

pub mod extract;
pub mod purchase_invoice;

pub use extract::{extract, AnalysisRow, ExtractRun, Money, SpecialsTotals, ValueCode, ValueRow};
pub use purchase_invoice::{
    HeaderStatus, InvoiceError, InvoiceNumber, InvoiceRow, InvoiceType, LineTail, OpenItem4,
    PackedMoney, PurchaseHeader, PurchaseLine, SupplierKey, ACAS_INVOICE_RECORD_BYTES,
    ANALYSIS_RECORD_BYTES, FIG_FIELDS, ITEM_BYTE_OFFSET, OPEN_ITEM4_RECORD_BYTES,
    VALUE_RECORD_BYTES,
};
