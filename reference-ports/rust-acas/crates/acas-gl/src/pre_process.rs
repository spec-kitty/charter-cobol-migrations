//! `gl070`'s `gl071b-pre-process` and `gl071`'s sort.
//!
//! One posting record becomes up to three ledger legs (F-B072 Part 5): the
//! debit leg, the credit leg (always negated), and a VAT leg when the record
//! carries a VAT account and a non-zero VAT amount. The VAT amount rides on the
//! side opposite its `post-vat-side`: `"CR"` adds it to the debit leg, `"DR"`
//! to the credit leg, and negates the VAT leg only for `"CR"`.
//!
//! Everything else about the posting — code, date, legend — is copied onto
//! every leg unchanged. `gl071` then sorts the legs by
//! `(batch, account, p.c., posting number)` ascending, which is what puts each
//! account's legs together and in posting order.

use crate::records::{Posting, Trans, TRANS_RECORD_BYTES, POSTING_RECORD_BYTES};

/// `gl071b` — expand every posting of `batch` into its legs, in file order.
///
/// Postings with an all-zero key, or belonging to another batch, are skipped
/// before any leg is built.
pub fn pre_process(postings: &[[u8; POSTING_RECORD_BYTES]], batch: u16) -> Vec<Trans> {
    let mut legs = Vec::new();
    for record in postings {
        let Some(posting) = Posting::from_bytes(record) else {
            continue;
        };
        if posting.zero_key() || posting.batch != batch {
            continue;
        }
        let base = Trans {
            batch: posting.batch,
            post: posting.post,
            code: posting.code,
            date: posting.date,
            ac: posting.dr,
            pc: posting.dr_pc,
            amount: posting.amount,
            legend: posting.legend,
        };

        let debit = if posting.vat_side == *b"CR" {
            base.amount + posting.vat_amount
        } else {
            base.amount
        };
        legs.push(Trans {
            amount: debit,
            ..base
        });

        let credit = if posting.vat_side == *b"DR" {
            base.amount + posting.vat_amount
        } else {
            base.amount
        };
        legs.push(Trans {
            ac: posting.cr,
            pc: posting.cr_pc,
            amount: -credit,
            ..base
        });

        if posting.vat_ac == *b"000000" || posting.vat_amount == 0 {
            continue;
        }
        let vat = if posting.vat_side == *b"CR" {
            -posting.vat_amount
        } else {
            posting.vat_amount
        };
        legs.push(Trans {
            ac: posting.vat_ac,
            pc: posting.vat_pc,
            amount: vat,
            ..base
        });
    }
    legs
}

/// `gl071` — `sort ... on ascending key sort-batch sort-ac sort-pc sort-post`.
///
/// The sort is stable so equal keys hold file order; COBOL promises nothing
/// beyond the declared keys.
pub fn sort_legs(legs: &mut [Trans]) {
    legs.sort_by(|left, right| {
        (
            left.batch,
            left.ac,
            left.pc,
            left.post,
        )
            .cmp(&(right.batch, right.ac, right.pc, right.post))
    });
}

/// The byte stream `gl071` gives out.
pub fn sorted_bytes(legs: &[Trans]) -> Vec<u8> {
    let mut out = Vec::with_capacity(legs.len() * TRANS_RECORD_BYTES);
    for leg in legs {
        out.extend_from_slice(&leg.to_bytes());
    }
    out
}
