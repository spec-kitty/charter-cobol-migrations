//! acas-gl: general/nominal ledger port of ACAS `general/`.
//!
//! The ledger is the posting target for every other ledger: sales (sl060),
//! purchase and the incomplete-records system all write `posting.dat` and the
//! posting chain applies it here. Behaviours are ported per charter-pack
//! directives; evidence is in `docs/fd-evidence/F-B072-gl-post-apply.md` and
//! the dispositions in `docs/disposition-gl072.md`.

pub mod pre_process;
pub mod records;
pub mod update;

pub use pre_process::{pre_process, sort_legs, sorted_bytes};
pub use records::{Money, Posting, Trans, BATCH_RECORD_BYTES, LEDGER_RECORD_BYTES, POSTING_RECORD_BYTES, TRANS_RECORD_BYTES};
pub use update::{run_date_from, update, UpdateContext, UpdateInput, UpdateReport};
