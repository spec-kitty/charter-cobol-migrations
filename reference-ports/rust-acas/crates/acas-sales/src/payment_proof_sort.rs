//! SL090 menu J — the payment proof sort.
//!
//! Ported from `sales/sl090.cbl`: `init01`, `sorting-1` and `input-to-sort`.
//! The program is a pure file transform — it reads `open-item-file-3`, drops
//! the rows that are not payments, and `sort ... giving open-item-file-s`. It
//! prints nothing: `sl095` (the proof report) reads the sorted file straight
//! afterwards and does the printing, and the caller owns both file handles.
//!
//! Layouts are measured in `docs/fd-evidence/F-B090-sl090-payment-proof-sort.md`
//! and every field is dispositioned in `docs/disposition-sl090.md`.
//!
//! ## The fossils, on purpose
//!
//! - `if s-flag-p = 0` is the whole gate: with no payment run in progress the
//!   program raises errors 30 and 15 through `maps99` and exits **without
//!   touching either file** — no empty output, no `oi-3-flag`. The `maps99`
//!   screen text itself belongs to WP12, so the refusal surfaces as
//!   [`SortOutcome::Refused`] rather than as lines.
//! - Types **1 and 3** are dropped outright. In this program `1` is a receipt;
//!   `sl055`'s `InvoiceType` calls the same byte an invoice (F-B016 Part 2), so
//!   the type numbering is per-program and must not be shared.
//! - Rows whose batch number *and* batch item are both zero are dropped too:
//!   batch-zero means "not a payment" to the author, not "the payment has no
//!   batch". `(0, 1)` and `(0, 999)` are kept.
//! - A failed **input open** is not an error either: the program closes and
//!   reopens the output as `output`, which leaves a zero-length sorted file
//!   behind. The caller passes the status it got; nothing else is read.
//! - The sort keys are the batch pair ascending, `s-type` **descending**, then
//!   date and invoice. `s-type` descending inside a batch slot is deliberate
//!   and is what puts the payment journal (6) ahead of the payment (5).
//! - `release sort-record from open-item-record-3` copies all 114 bytes, so
//!   the output is the input record unchanged; only the order and the
//!   membership are affected.

use crate::posting::OpenItem2;

/// `01 open-item-record-3 pic x(114)` — also the sort record's length, which
/// is why `init01`'s `function length` comparison never fires.
pub const OPEN_ITEM_BYTES: usize = 114;

/// `oi-b-nos` — `pic 9(5)` inside `oi-batch comp`, high byte first.
const B_NOS: std::ops::Range<usize> = 15..19;

/// `oi-b-item` — `pic 999` inside `oi-batch comp`, high byte first.
const B_ITEM: std::ops::Range<usize> = 19..21;

/// `oi-date` — `binary-long`, little endian (F-B008).
const DATE: std::ops::Range<usize> = 11..15;

/// `oi-invoice` — `binary-long`, little endian.
const INVOICE: std::ops::Range<usize> = 7..11;

/// `oi-type` — a digit character; 1 = receipt, 3 = credit note.
const TYPE: usize = 21;

/// What `sl090` did with the file it was handed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SortOutcome {
    /// The sorted file's records, in order. Empty when the input open failed.
    Written(Vec<[u8; OPEN_ITEM_BYTES]>),
    /// `s-flag-p = 0`: neither file is opened.
    Refused,
}

/// The four sort keys, read out of one record.
fn keys(record: &[u8; OPEN_ITEM_BYTES]) -> (u32, u16, u8, i32, u32) {
    let word = |range: std::ops::Range<usize>| -> [u8; 4] {
        let mut out = [0u8; 4];
        out.copy_from_slice(&record[range]);
        out
    };
    let b_nos = u32::from_be_bytes(word(B_NOS));
    let b_item = u16::from_be_bytes([record[B_ITEM.start], record[B_ITEM.start + 1]]);
    let date = i32::from_le_bytes(word(DATE));
    let invoice = u32::from_le_bytes(word(INVOICE));
    (b_nos, b_item, record[TYPE], date, invoice)
}

/// `input-to-sort` — keep the payment rows.
fn is_payment(record: &[u8; OPEN_ITEM_BYTES]) -> bool {
    let (b_nos, b_item, kind, _, _) = keys(record);
    if matches!(kind, b'1' | b'3') {
        return false;                       // receipts and credit notes
    }
    b_nos != 0 || b_item != 0               // batch-zero means "no payment"
}

/// `init01` + `sorting-1`, as pure data.
///
/// `input_status` is the `fs-reply` from opening `open-item-file-3` and
/// `s_flag_p` is the operator's payment flag (system byte 569, F-B011).
pub fn run(
    input_status: u8,
    s_flag_p: u8,
    rows: &[[u8; OPEN_ITEM_BYTES]],
) -> SortOutcome {
    if s_flag_p == 0 {
        return SortOutcome::Refused;
    }
    if input_status != 0 {
        return SortOutcome::Written(Vec::new());
    }
    let mut kept: Vec<[u8; OPEN_ITEM_BYTES]> = rows
        .iter()
        .copied()
        .filter(is_payment)
        .collect();
    // Ascending batch number, item and date/invoice; type descending, so the
    // comparison is on the inverted byte. `sort` is stable, which fixes the
    // order of rows that tie on all five keys — COBOL does not promise one.
    kept.sort_by_key(|record| {
        let (b_nos, b_item, kind, date, invoice) = keys(record);
        (b_nos, b_item, std::cmp::Reverse(kind), date, invoice)
    });
    SortOutcome::Written(kept)
}

/// Same as [`run`], from decoded rows.
///
/// Note that [`OpenItem2`] does not carry `oi-b-nos`/`oi-b-item` — sl055 always
/// writes them zero — so every row sorts as `(0, 0)` and the batch-zero rule
/// drops all of them. Use this only for records that came from sl055, and
/// [`run`] for anything that has real batch data.
pub fn run_items(
    input_status: u8,
    s_flag_p: u8,
    rows: &[OpenItem2],
) -> SortOutcome {
    let raw: Vec<[u8; OPEN_ITEM_BYTES]> = rows.iter().map(OpenItem2::to_bytes).collect();
    run(input_status, s_flag_p, &raw)
}

/// The sorted file as a byte stream, the way `parity` compares it.
///
/// `Refused` and `Written(vec![])` both yield an empty slice — the difference
/// is whether the caller should have created the file at all.
pub fn artifact(outcome: &SortOutcome) -> Vec<u8> {
    match outcome {
        SortOutcome::Written(rows) => rows.concat(),
        SortOutcome::Refused => Vec::new(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn record(customer: &str, invoice: u32, date: i32, batch: (u32, u16), kind: u8) -> [u8; OPEN_ITEM_BYTES] {
        let mut out = [b' '; OPEN_ITEM_BYTES];
        let key = format!("{customer:<7}");
        out[..7].copy_from_slice(key.as_bytes());
        out[INVOICE].copy_from_slice(&invoice.to_le_bytes());
        out[DATE].copy_from_slice(&date.to_le_bytes());
        out[B_NOS].copy_from_slice(&batch.0.to_be_bytes());
        out[B_ITEM].copy_from_slice(&batch.1.to_be_bytes());
        out[TYPE] = kind;
        out
    }

    fn written(outcome: SortOutcome) -> Vec<[u8; OPEN_ITEM_BYTES]> {
        match outcome {
            SortOutcome::Written(rows) => rows,
            SortOutcome::Refused => panic!("refused"),
        }
    }

    #[test]
    fn without_a_payment_run_nothing_is_written() {
        let rows = [record("CUST041", 1, 0, (1, 1), b'2')];
        assert_eq!(run(0, 0, &rows), SortOutcome::Refused);
        assert!(artifact(&SortOutcome::Refused).is_empty());
    }

    #[test]
    fn a_failed_input_open_still_leaves_an_empty_file() {
        assert_eq!(run(35, 1, &[]), SortOutcome::Written(Vec::new()));
    }

    #[test]
    fn receipts_and_credit_notes_are_dropped() {
        let rows = [
            record("CUST041", 1, 0, (1, 1), b'1'),
            record("CUST041", 2, 0, (1, 1), b'2'),
            record("CUST041", 3, 0, (1, 1), b'3'),
            record("CUST041", 4, 0, (1, 1), b'5'),
            record("CUST041", 5, 0, (1, 1), b'6'),
            record("CUST041", 6, 0, (1, 1), b'4'),
        ];
        let out = written(run(0, 1, &rows));
        let invoices: Vec<u32> = out
            .iter()
            .map(|r| u32::from_le_bytes([r[7], r[8], r[9], r[10]]))
            .collect();
        // Same batch slot, so the descending type puts 6, 5, 4, 2 in that order.
        // Same batch slot, so the descending type orders the survivors 6, 5, 4, 2
        // — invoices 5, 4, 6 and 2.
        assert_eq!(invoices, vec![5, 4, 6, 2]);
    }

    #[test]
    fn a_zero_batch_pair_is_dropped_even_though_zero_alone_is_not() {
        let rows = [
            record("CUST041", 1, 0, (0, 0), b'5'),
            record("CUST041", 2, 0, (0, 1), b'5'),
            record("CUST041", 3, 0, (1, 0), b'5'),
        ];
        let out = written(run(0, 1, &rows));
        assert_eq!(out.len(), 2);
    }

    #[test]
    fn batch_number_leads_the_order() {
        let rows = [
            record("CUST041", 1, 0, (9, 1), b'5'),
            record("CUST041", 2, 0, (2, 1), b'5'),
            record("CUST041", 3, 0, (100, 1), b'5'),
        ];
        let out = written(run(0, 1, &rows));
        let batches: Vec<u32> = out
            .iter()
            .map(|r| u32::from_be_bytes([r[15], r[16], r[17], r[18]]))
            .collect();
        assert_eq!(batches, vec![2, 9, 100]);
    }

    #[test]
    fn the_batch_item_breaks_a_shared_batch_number() {
        let rows = [
            record("CUST041", 1, 0, (4, 7), b'5'),
            record("CUST041", 2, 0, (4, 2), b'5'),
        ];
        let out = written(run(0, 1, &rows));
        assert_eq!(out[0][19..21], 2u16.to_be_bytes());
    }

    #[test]
    fn the_type_sorts_downwards_inside_a_batch_slot() {
        let rows = [
            record("CUST041", 1, 0, (4, 1), b'2'),
            record("CUST041", 2, 0, (4, 1), b'5'),
            record("CUST041", 3, 0, (4, 1), b'6'),
            record("CUST041", 4, 0, (4, 1), b'9'),
        ];
        let out = written(run(0, 1, &rows));
        let kinds: Vec<u8> = out.iter().map(|r| r[TYPE]).collect();
        assert_eq!(kinds, vec![b'9', b'6', b'5', b'2']);
    }

    #[test]
    fn date_then_invoice_break_the_rest() {
        let rows = [
            record("CUST042", 9, -5, (4, 1), b'5'),
            record("CUST041", 7, -20, (4, 1), b'5'),
            record("CUST041", 3, -20, (4, 1), b'5'),
        ];
        let out = written(run(0, 1, &rows));
        let order: Vec<(i32, u32)> = out
            .iter()
            .map(|r| {
                (
                    i32::from_le_bytes(r[11..15].try_into().unwrap()),
                    u32::from_le_bytes(r[7..11].try_into().unwrap()),
                )
            })
            .collect();
        assert_eq!(order, vec![(-20, 3), (-20, 7), (-5, 9)]);
    }

    #[test]
    fn the_whole_record_is_carried_not_just_the_keys() {
        let mut row = record("CUST041", 1, 0, (1, 1), b'5');
        row[22..26].copy_from_slice(b"KEEP");
        row[89] = 0x7f;
        let out = written(run(0, 1, &[row]));
        assert_eq!(&out[0][22..26], b"KEEP");
        assert_eq!(out[0][89], 0x7f);
    }

    #[test]
    fn an_empty_input_gives_an_empty_file() {
        assert!(artifact(&run(0, 1, &[])).is_empty());
    }
}
