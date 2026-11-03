//! SL060 — Invoice Posting: open items to sales ledger, and the GL posting run.
//!
//! Ported from `sales/sl060.cbl`. Pure domain kernel: the caller hands in the
//! staged `open-item-file-2` records, the sales table and the value table; the
//! kernel returns the `open-item-file-3` ledger rows, the rewritten sales rows,
//! the GL posting/batch records and the report text. Storage stays outside.
//!
//! Byte layouts for all three writer records are measured in
//! `docs/fd-evidence/F-B009-sl060-ledger-and-posting-records.md`;
//! field-level dispositions (and the fossils this module deliberately keeps)
//! are in `docs/disposition-fdoi2.md`.
//!
//! ## The run, in COBOL order
//!
//! 1. `aa020-Read-Loop` — one record per staged open item, in key order:
//!    look up the customer (missing -> "*** Customer Unknown ***" and a fresh
//!    row that is *written* at the end), compute `work-vat` /`work-goods` /
//!    `work-net`, bucket the totals by `oi-type`, write the GL posting when
//!    `g-l`, apply the average, the turnover and the `sales-current` legs,
//!    write the OTM3 row, print the line.
//! 2. `aa030-Main-End` — the three `Total Posted` lines in bucket order and
//!    the late-deduction line, the `Szd` value-file adjustment, the batch
//!    record.
//! 3. `aa040-End-Loop` phase 2 — every **credit note** in OTM3 is apportioned
//!    against the customer's later open invoices (`ba000-Cr-Swop`).
//! 4. OTM2 is truncated.
//!
//! ## The fossils, on purpose
//!
//! - `total-net (a)` is subscripted by the *digit* of `oi-type` and only
//!   buckets 1..3 exist. Types 4/5/6/9 never reach OTM2 from sl055; the port
//!   keeps three slots and indexes blindly (`oi-type - 1`).
//! - One posting record per *open item*, not per line, despite the banner over
//!   `ca000-BL-Write` claiming otherwise.
//! - `post-legend` is STRING-ed without `ON OVERFLOW` into 32 bytes.
//! - `sales-average` is integer division into a `binary-long` — it floors.
//! - `work-b` (the "Un-Applied Credits C/F" figure) is the last record's
//!   deduction, not a total.
//! - `si-paid` raised by apportionment lands in the credit note's own record:
//!   `ba030` moves `si-header` back over `oi-header` and the write at 499
//!   follows it (F-B010 Part 4).
//! - `current-quarter` is never set by the chained path, so turnover adds land
//!   in `sales-last` (F-B010 Part 1) via raw offset arithmetic.
//! - a blank money field reads as `20202020202`, not zero (F-B010 Part 2).
//! - `file-status (18)` arrives already 1 from sl055, so phase 2 never prints a
//!   page heading (F-B010 Part 3).
//! - `ba000-Cr-Swop` does no apportionment, only print-and-carry (F-B010
//!   Part 5).
//!
//! ## Type mapping
//!
//! - `sales-current` / `turnover-q*` / `sales-unapplied` — `s9(8)v99 comp-3`,
//!   six bytes, no truncation (`Money` is i64 hundredths)
//! - `sales-limit` .. `sales-create-date` — `binary-long`, LE
//! - `s-debtors` / `sl-sales-ac` / `vat-ac` — `binary-long` in the system
//!   record, re-typed to the six display digits `post-dr` / `post-cr` /
//!   `vat-ac` actually take
//! - `post-amount` / `vat-amount` — `s9(8)v99` display with a sign overpunch on
//!   the final byte (`p`..`y` for -0..-9)
//! - batch amounts — unsigned `9(9)v99 comp-3` with an `F` sign nibble

use std::collections::BTreeMap;

use acas_common::cobol_date::CobolDate;

use crate::invoice::CustomerKey;
use crate::posting::{Money, OpenItem2, ValueRow};

/// `fdsl.cob` — the sales record is 300 bytes.
pub const SALES_RECORD_BYTES: usize = 300;
/// `fdpost.cob` — the posting record is 98 bytes.
pub const POSTING_RECORD_BYTES: usize = 98;
/// `fdbatch.cob` — the batch record is 96 bytes.
pub const BATCH_RECORD_BYTES: usize = 96;
/// `print-record` is 132 bytes (`fdprint.cob`).
pub const PRINT_RECORD_BYTES: usize = 132;
/// `if items = 99` — a batch closes and a new one opens.
pub const BATCH_ITEM_LIMIT: u32 = 99;
/// The name written for a customer key with no sales row.
pub const CUSTOMER_UNKNOWN: [u8; 24] = *b"*** Customer Unknown ***";

/// `oi-type` digits as buckets: receipt, account, credit note.
pub const BUCKETS: usize = 3;

/// Nominal codes the posting run stamps on each record, from the system
/// record (F-B009 Part 6). Six display digits, as `post-dr` / `post-cr` /
/// `vat-ac` take them.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GlAccounts {
    pub debtors: [u8; 6],
    pub sales: [u8; 6],
    pub vat: [u8; 6],
}

impl GlAccounts {
    /// All-zero codes, which is what a stock `mapserup` install leaves behind.
    pub const ZERO: Self = Self { debtors: *b"000000", sales: *b"000000", vat: *b"000000" };

    /// `move s-debtors to post-dr` — a `binary-long` into `pic 9(6)` keeps the
    /// low six digits and drops the rest.
    pub fn display(v: u32) -> [u8; 6] {
        let text = format!("{v:06}");
        let tail = text.as_bytes();
        tail[tail.len() - 6..].try_into().unwrap_or(*b"000000")
    }
}

/// Everything the run needs from the caller's environment.
#[derive(Debug, Clone)]
pub struct PostContext {
    /// `g-l` — report only, or report *and* GL. `None` skips `ca000-BL-*`.
    pub gl: Option<GlAccounts>,
    /// `scycle`, copied into `bcycle`.
    pub cycle: u8,
    /// `current-quarter`, 1-based as the copybook is, but the setup screens
    /// leave it `0` and `sl060` indexes with it unguarded (F-B010).
    pub quarter: usize,
    /// `u-date` — `dd/mm/ccyy`; the posting date is `dd/mm/` + `yy`.
    pub run_date: [u8; 10],
    /// `run-date` as days, for the batch `entered` stamp.
    pub run_date_days: i32,
    /// `next-batch`, incremented once per batch opened.
    pub next_batch: u16,
    /// `postings`, the latest record number in the posting file.
    pub postings: u16,
    /// `Page-Lines` from the system record.
    pub page_lines: u16,
    /// `usera`, printed in the page heading.
    pub user: [u8; 32],
}

/// One bucket's `Total Posted` line.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct BucketTotal {
    pub net: Money,
    pub vat: Money,
}

impl BucketTotal {
    pub fn gross(&self) -> Money {
        self.net + self.vat
    }
}

/// What the run produced.
#[derive(Debug, Default)]
pub struct PostOutcome {
    /// `open-item-file-3`, in key order.
    pub otm3: Vec<[u8; OPEN_ITEM3_RECORD_BYTES]>,
    /// `posting-file` records, in write order.
    pub postings: Vec<[u8; POSTING_RECORD_BYTES]>,
    /// `batch-file` records, one per batch.
    pub batches: Vec<[u8; BATCH_RECORD_BYTES]>,
    /// `prt-1`, as 132-byte records.
    pub report: Vec<u8>,
    /// `total-net` / `total-vat` by bucket.
    pub totals: [BucketTotal; BUCKETS],
    /// `total-deduct`, and `total-mov-ded`.
    pub total_deduct: Money,
    pub total_mov_ded: u32,
    /// `sales-missing` — at least one open item named a customer with no row.
    pub sales_missing: bool,
    /// `work-b` at the end: the last apportionment's deduction, not a sum.
    pub unapplied_c_notes: Money,
    pub next_batch: u16,
    pub postings_written: u16,
}

/// `open-item-record-3` is the same 114 bytes as `-2` (F-B009 Part 5).
pub const OPEN_ITEM3_RECORD_BYTES: usize = 114;

/// A row of the sales ledger (`fdsl.cob`), 300 bytes (F-B009 Part 2).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SalesRow {
    pub key: CustomerKey,
    pub name: [u8; 30],
    pub addr1: [u8; 48],
    pub addr2: [u8; 48],
    pub phone: [u8; 13],
    pub ext: [u8; 4],
    pub email: [u8; 30],
    pub fax: [u8; 13],
    /// `sales-status`: `1` is live, `0` is dead.
    pub status: u8,
    pub late: u8,
    pub dunning: u8,
    pub email_invoice: u8,
    pub email_statement: u8,
    pub email_letters: u8,
    pub delivery_tag: u8,
    pub notes_tag: u8,
    pub credit: [u8; 2],
    pub discount: i16,
    pub late_min: i16,
    pub late_max: i16,
    pub limit: i32,
    pub activety: i32,
    pub last_inv: i32,
    pub last_pay: i32,
    pub average: i32,
    pub pay_activety: i32,
    pub pay_average: i32,
    pub pay_worst: i32,
    pub create_date: i32,
    pub current: Wide,
    pub last: Wide,
    pub turnover: [Wide; 4],
    pub unapplied: Wide,
    pub tail: [u8; 10],
}

impl SalesRow {
    /// An `initialize sales-record` row — the customer-unknown path.
    pub fn blank(key: CustomerKey) -> Self {
        Self {
            key,
            name: [b' '; 30],
            addr1: [b' '; 48],
            addr2: [b' '; 48],
            phone: [b' '; 13],
            ext: [b' '; 4],
            email: [b' '; 30],
            fax: [b' '; 13],
            status: 0,
            late: 0,
            dunning: 0,
            email_invoice: 0,
            email_statement: 0,
            email_letters: 0,
            delivery_tag: 0,
            notes_tag: 0,
            credit: *b" 0",
            discount: 0,
            late_min: 0,
            late_max: 0,
            limit: 0,
            activety: 0,
            last_inv: 0,
            last_pay: 0,
            average: 0,
            pay_activety: 0,
            pay_average: 0,
            pay_worst: 0,
            create_date: 0,
            current: Wide::ZEROED,
            last: Wide::ZEROED,
            turnover: [Wide::ZEROED; 4],
            unapplied: Wide::ZEROED,
            tail: [b' '; 10],
        }
    }

    pub fn to_bytes(self) -> [u8; SALES_RECORD_BYTES] {
        let mut out = [0u8; SALES_RECORD_BYTES];
        out[0..7].copy_from_slice(&self.key.0);
        out[7..37].copy_from_slice(&self.name);
        out[37..85].copy_from_slice(&self.addr1);
        out[85..133].copy_from_slice(&self.addr2);
        out[133..146].copy_from_slice(&self.phone);
        out[146..150].copy_from_slice(&self.ext);
        out[150..180].copy_from_slice(&self.email);
        out[180..193].copy_from_slice(&self.fax);
        out[193] = b'0'.wrapping_add(self.status);
        out[194] = b'0'.wrapping_add(self.late);
        out[195] = b'0'.wrapping_add(self.dunning);
        out[196] = b'0'.wrapping_add(self.email_invoice);
        out[197] = b'0'.wrapping_add(self.email_statement);
        out[198] = b'0'.wrapping_add(self.email_letters);
        out[199] = b'0'.wrapping_add(self.delivery_tag);
        out[200] = b'0'.wrapping_add(self.notes_tag);
        out[201..204].copy_from_slice(b"   ");
        out[204..206].copy_from_slice(&self.credit);
        out[206..208].copy_from_slice(&self.discount.to_be_bytes());
        out[208..210].copy_from_slice(&self.late_min.to_be_bytes());
        out[210..212].copy_from_slice(&self.late_max.to_be_bytes());
        out[212..216].copy_from_slice(&self.limit.to_le_bytes());
        out[216..220].copy_from_slice(&self.activety.to_le_bytes());
        out[220..224].copy_from_slice(&self.last_inv.to_le_bytes());
        out[224..228].copy_from_slice(&self.last_pay.to_le_bytes());
        out[228..232].copy_from_slice(&self.average.to_le_bytes());
        out[232..236].copy_from_slice(&self.pay_activety.to_le_bytes());
        out[236..240].copy_from_slice(&self.pay_average.to_le_bytes());
        out[240..244].copy_from_slice(&self.pay_worst.to_le_bytes());
        out[244..248].copy_from_slice(&self.create_date.to_le_bytes());
        out[248..254].copy_from_slice(&self.current.0);
        out[254..260].copy_from_slice(&self.last.0);
        for (slot, value) in self.turnover.iter().enumerate() {
            let at = 260 + slot * 6;
            out[at..at + 6].copy_from_slice(&value.0);
        }
        out[284..290].copy_from_slice(&self.unapplied.0);
        out[290..300].copy_from_slice(&self.tail);
        out
    }

    pub fn from_bytes(b: [u8; SALES_RECORD_BYTES]) -> Self {
        let digit = |at: usize| b[at].wrapping_sub(b'0');
        let mut turnover = [Wide::ZEROED; 4];
        for (slot, value) in turnover.iter_mut().enumerate() {
            let at = 260 + slot * 6;
            value.0 = b[at..at + 6].try_into().unwrap_or([0; 6]);
        }
        Self {
            key: CustomerKey(b[0..7].try_into().unwrap_or(*b"       ")),
            name: b[7..37].try_into().unwrap_or([b' '; 30]),
            addr1: b[37..85].try_into().unwrap_or([b' '; 48]),
            addr2: b[85..133].try_into().unwrap_or([b' '; 48]),
            phone: b[133..146].try_into().unwrap_or([b' '; 13]),
            ext: b[146..150].try_into().unwrap_or([b' '; 4]),
            email: b[150..180].try_into().unwrap_or([b' '; 30]),
            fax: b[180..193].try_into().unwrap_or([b' '; 13]),
            status: digit(193),
            late: digit(194),
            dunning: digit(195),
            email_invoice: digit(196),
            email_statement: digit(197),
            email_letters: digit(198),
            delivery_tag: digit(199),
            notes_tag: digit(200),
            credit: b[204..206].try_into().unwrap_or(*b" 0"),
            discount: i16::from_be_bytes(b[206..208].try_into().unwrap_or([0; 2])),
            late_min: i16::from_be_bytes(b[208..210].try_into().unwrap_or([0; 2])),
            late_max: i16::from_be_bytes(b[210..212].try_into().unwrap_or([0; 2])),
            limit: i32::from_le_bytes(b[212..216].try_into().unwrap_or([0; 4])),
            activety: i32::from_le_bytes(b[216..220].try_into().unwrap_or([0; 4])),
            last_inv: i32::from_le_bytes(b[220..224].try_into().unwrap_or([0; 4])),
            last_pay: i32::from_le_bytes(b[224..228].try_into().unwrap_or([0; 4])),
            average: i32::from_le_bytes(b[228..232].try_into().unwrap_or([0; 4])),
            pay_activety: i32::from_le_bytes(b[232..236].try_into().unwrap_or([0; 4])),
            pay_average: i32::from_le_bytes(b[236..240].try_into().unwrap_or([0; 4])),
            pay_worst: i32::from_le_bytes(b[240..244].try_into().unwrap_or([0; 4])),
            create_date: i32::from_le_bytes(b[244..248].try_into().unwrap_or([0; 4])),
            current: Wide(b[248..254].try_into().unwrap_or([0; 6])),
            last: Wide(b[254..260].try_into().unwrap_or([0; 6])),
            turnover,
            unapplied: Wide(b[284..290].try_into().unwrap_or([0; 6])),
            tail: b[290..300].try_into().unwrap_or([b' '; 10]),
        }
    }
}

/// `s9(8)v99 comp-3` — ten digits plus a sign nibble, padded into twelve
/// nibbles. Digits past ten are dropped, as COBOL does.
fn pack_wide(cents: Money) -> [u8; 6] {
    let magnitude = cents.unsigned_abs() % 10_000_000_000;
    let formatted = format!("{magnitude:010}");
    let bytes = formatted.as_bytes();
    let mut out = [0u8; 6];
    out[0] = bytes[0] - b'0';
    for pair in 0..4 {
        out[1 + pair] = ((bytes[1 + pair * 2] - b'0') << 4) | (bytes[2 + pair * 2] - b'0');
    }
    out[5] = ((bytes[9] - b'0') << 4) | if cents < 0 { 0x0D } else { 0x0C };
    out
}

/// Read a six-byte `s9(8)v99`. Twelve nibbles against eleven usable ones, so
/// the spare high nibble is padding the field never owns; digits past the
/// tenth are dropped exactly as COBOL does when it moves other bytes in.
fn unpack_wide(raw: [u8; 6]) -> Money {
    let mut magnitude: i128 = 0;
    for byte in raw {
        magnitude = magnitude * 100 + i128::from(byte >> 4) * 10 + i128::from(byte & 0x0F);
    }
    let sign = i128::from(raw[5] & 0x0F);
    let magnitude = (magnitude - sign) / 10 % 10_000_000_000;
    let magnitude = magnitude as Money;
    if matches!(raw[5] & 0x0F, 0x0B | 0x0D) { -magnitude } else { magnitude }
}

/// `add <amount> to <packed field>` as the compiler actually performs it.
///
/// The field is read as the eleven digits that follow its padding nibble — a
/// space-filled field (`0x20` everywhere) therefore reads as `20202020202`,
/// nine digits of junk that dwarf any real amount. The sum is then squeezed
/// back into a ten digit field: digits past the tenth are dropped and the
/// padding nibble is re-emitted as a zero. That is why a first post into an
/// untouched row lands on `0020…` and the junk stays put across records
/// instead of drifting (F-B010).
fn packed_add(raw: [u8; 6], delta: Money) -> [u8; 6] {
    let mut digits: i128 = 0;
    for (at, byte) in raw.iter().enumerate() {
        digits = digits * 10 + i128::from(byte >> 4);
        if at < 5 {
            digits = digits * 10 + i128::from(byte & 0x0F);
        }
    }
    let sum = (digits + i128::from(delta)) % 10_000_000_000;
    let body = format!("{:010}", sum.unsigned_abs());
    let rendered = format!("0{body}");
    let bytes = rendered.as_bytes();
    let mut out = [0u8; 6];
    for at in 0..5 {
        out[at] = ((bytes[at * 2] - b'0') << 4) | (bytes[at * 2 + 1] - b'0');
    }
    out[5] = ((bytes[10] - b'0') << 4) | if sum < 0 { 0x0D } else { 0x0C };
    out
}

/// `add <amount> to STurnover-Q (current-quarter)`.
///
/// `current-quarter` is a caller global and the stubborn part of this fossil:
/// the harness never sets it, so it arrives as `0` and the subscript runs off
/// the front of `Quarters` into the field before it — `sales-last`. Values
/// past four walk on into `sales-unapplied` and the ten-byte filler, and a
/// field past the record end is truncated by the FD. The subscript is applied
/// to raw byte positions (`260 + 6 * (quarter - 1)`), not to a bounded array.
fn quarter_add(row: &mut SalesRow, quarter: usize, delta: Money) {
    let offset = 260i64 + 6 * (quarter as i64 - 1);
    match offset {
        254 => {
            eprintln!("q0 last before={:02x?} delta={delta}", row.last.0);
            row.last = Wide(packed_add(row.last.0, delta));
            eprintln!("q0 last after={:02x?}", row.last.0);
        }
        260..=278 if offset % 6 == 2 || offset <= 278 => {
            let slot = ((offset - 260) / 6) as usize;
            if let Some(field) = row.turnover.get_mut(slot) {
                *field = Wide(packed_add(field.0, delta));
            }
        }
        284 => row.unapplied = Wide(packed_add(row.unapplied.0, delta)),
        290..=299 => {
            let at = (offset - 290) as usize;
            let mut raw = [b' '; 6];
            for (index, slot) in raw.iter_mut().enumerate() {
                if let Some(byte) = row.tail.get(at + index) {
                    *slot = *byte;
                }
            }
            let updated = packed_add(raw, delta);
            for (index, byte) in updated.iter().enumerate() {
                if let Some(slot) = row.tail.get_mut(at + index) {
                    *slot = *byte;
                }
            }
        }
        _ => {}
    }
}

/// A packed `s9(8)v99` as it sits on disk.
///
/// The raw six bytes are authoritative: ACAS leaves a comp-3 field completely
/// inert unless something assigns to it, so a row that merely passes through
/// keeps whatever nibbles it arrived with (the fixtures' untouched fields are
/// spaces, not zeros). Arithmetic goes through [`Wide::cents`] /
/// [`Wide::set_cents`], which is where the packing happens.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Wide([u8; 6]);

impl Wide {
    /// `initialize` — a cleared field, all nibbles zero.
    pub const ZEROED: Self = Self([0; 6]);
    /// `move zero` — a proper packed zero.
    pub const ZERO: Self = Self([0, 0, 0, 0, 0, 0x0C]);

    pub fn cents(self) -> Money {
        unpack_wide(self.0)
    }

    pub fn add(&mut self, delta: Money) {
        self.0 = pack_wide(self.cents() + delta);
    }

    pub fn set(self, cents: Money) -> Self {
        Self(pack_wide(cents))
    }
}

/// `9(9)v99 comp-3`, unsigned — eleven digits and an `F` sign nibble.
fn pack_batch_amount(cents: u64) -> [u8; 6] {
    let magnitude = cents % 100_000_000_000;
    let formatted = format!("{magnitude:011}");
    let bytes = formatted.as_bytes();
    let mut out = [0u8; 6];
    for pair in 0..5 {
        out[pair] = ((bytes[pair * 2] - b'0') << 4) | (bytes[pair * 2 + 1] - b'0');
    }
    out[5] = ((bytes[10] - b'0') << 4) | 0x0F;
    out
}

/// `s9(8)v99` **display** — ten digit bytes with the sign overpunched into the
/// last one (`p`..`y` are -0..-9).
fn pack_overpunch(cents: Money) -> [u8; 10] {
    let magnitude = cents.unsigned_abs() % 10_000_000_000;
    let mut out = [0u8; 10];
    out.copy_from_slice(format!("{magnitude:010}").as_bytes());
    if cents < 0 {
        out[9] = b'p' + (out[9] - b'0');
    }
    out
}

/// The batch opened by `ca000-BL-Open` (F-B009 Part 4).
#[derive(Debug, Clone)]
pub struct BatchRecord {
    pub ledger: u8,
    pub nos: u16,
    pub items: u32,
    pub status: u8,
    pub cleared: u8,
    pub cycle: u8,
    pub dates: [i32; 4],
    pub input_gross: Money,
    pub input_vat: Money,
    pub actual_gross: Money,
    pub actual_vat: Money,
    pub description: [u8; 24],
    pub bdefault: u8,
    pub convention: [u8; 2],
    pub def_ac: [u8; 6],
    pub def_pc: u8,
    pub def_code: [u8; 2],
    pub def_vat: u8,
    pub start: u16,
}

impl BatchRecord {
    /// `ca000-BL-Open`'s field set for a sales batch.
    fn open(ctx: &PostContext, nos: u16) -> Self {
        let mut description = [b' '; 24];
        description[..21].copy_from_slice(b"Sales Ledger Invoices");
        Self {
            ledger: 3,
            nos,
            items: 0,
            status: 0,
            cleared: 0,
            cycle: ctx.cycle,
            dates: [ctx.run_date_days, 0, 0, 0],
            input_gross: 0,
            input_vat: 0,
            actual_gross: 0,
            actual_vat: 0,
            description,
            bdefault: 0,
            convention: *b"CR",
            def_ac: *b"000000",
            def_pc: 0,
            def_code: *b"SL",
            def_vat: b'O',
            start: ctx.postings.wrapping_add(1),
        }
    }

    pub fn to_bytes(&self) -> [u8; BATCH_RECORD_BYTES] {
        let mut out = [0u8; BATCH_RECORD_BYTES];
        out[0] = b'0'.wrapping_add(self.ledger);
        out[1..6].copy_from_slice(&five_digits(self.nos));
        out[6..8].copy_from_slice(format!("{:02}", self.items % 100).as_bytes());
        out[8] = b'0'.wrapping_add(self.status);
        out[9] = b'0'.wrapping_add(self.cleared);
        out[10..12].copy_from_slice(format!("{:02}", self.cycle).as_bytes());
        for (slot, days) in self.dates.iter().enumerate() {
            let at = 12 + slot * 4;
            out[at..at + 4].copy_from_slice(&days.to_le_bytes());
        }
        out[28..34].copy_from_slice(&pack_batch_amount(self.input_gross.unsigned_abs()));
        out[34..40].copy_from_slice(&pack_batch_amount(self.input_vat.unsigned_abs()));
        out[40..46].copy_from_slice(&pack_batch_amount(self.actual_gross.unsigned_abs()));
        out[46..52].copy_from_slice(&pack_batch_amount(self.actual_vat.unsigned_abs()));
        out[52..76].copy_from_slice(&self.description);
        out[76..78].copy_from_slice(format!("{:02}", self.bdefault).as_bytes());
        out[78..80].copy_from_slice(&self.convention);
        out[80..86].copy_from_slice(&self.def_ac);
        out[86..88].copy_from_slice(format!("{:02}", self.def_pc).as_bytes());
        out[88..90].copy_from_slice(&self.def_code);
        out[90] = self.def_vat;
        out[91..96].copy_from_slice(&five_digits(self.start));
        out
    }
}

/// One `posting-record` (fdpost.cob, F-B009 Part 3).
#[derive(Debug, Clone)]
pub struct PostingRecord {
    pub batch: u16,
    pub number: u16,
    pub code: [u8; 2],
    pub date: [u8; 8],
    pub dr: [u8; 6],
    pub cr: [u8; 6],
    pub amount: Money,
    pub legend: [u8; 32],
    pub vat_ac: [u8; 6],
    pub vat_side: [u8; 2],
    pub vat_amount: Money,
}

impl PostingRecord {
    pub fn to_bytes(&self) -> [u8; POSTING_RECORD_BYTES] {
        let mut out = [0u8; POSTING_RECORD_BYTES];
        out[0..5].copy_from_slice(&five_digits(self.batch));
        out[5..10].copy_from_slice(&five_digits(self.number));
        out[10..12].copy_from_slice(&self.code);
        out[12..20].copy_from_slice(&self.date);
        out[20..26].copy_from_slice(&self.dr);
        out[26..28].copy_from_slice(b"00");
        out[28..34].copy_from_slice(&self.cr);
        out[34..36].copy_from_slice(b"00");
        out[36..46].copy_from_slice(&pack_overpunch(self.amount));
        out[46..78].copy_from_slice(&self.legend);
        out[78..84].copy_from_slice(&self.vat_ac);
        out[84..86].copy_from_slice(b"00");
        out[86..88].copy_from_slice(&self.vat_side);
        out[88..98].copy_from_slice(&pack_overpunch(self.vat_amount));
        out
    }
}

/// Zero-suppressed integer field: leading zeros become spaces, the last digit
/// always prints. `zzz9` over `width` digits (F-B009-report edit rules).
fn edit_suppressed(width: usize, value: i64) -> Vec<u8> {
    let magnitude = value.unsigned_abs();
    let text = format!("{magnitude:0width$}");
    let bytes = text.as_bytes();
    let first = bytes.len().saturating_sub(width);
    let mut out = Vec::with_capacity(width);
    let mut live = false;
    for (offset, byte) in bytes[first..].iter().enumerate() {
        let last = offset + 1 == width;
        if *byte == b'0' && !live && !last {
            out.push(b' ');
        } else {
            live = true;
            out.push(*byte);
        }
    }
    out
}

/// `z(6)9.99cr` — suppressed integral part, two decimals, `CR` for negatives
/// (two spaces otherwise).
fn edit_money_cr(width: usize, cents: Money) -> Vec<u8> {
    let mut out = edit_suppressed(width, cents / 100);
    out.push(b'.');
    out.extend_from_slice(format!("{:02}", (cents % 100).unsigned_abs()).as_bytes());
    out.extend_from_slice(if cents < 0 { b"CR" } else { b"  " });
    out
}

/// `zzz9.99 blank when zero`.
fn edit_money_blank_zero(width: usize, cents: Money) -> Vec<u8> {
    if cents == 0 {
        return vec![b' '; width + 3];
    }
    let mut out = edit_suppressed(width, cents / 100);
    out.push(b'.');
    out.extend_from_slice(format!("{:02}", (cents % 100).unsigned_abs()).as_bytes());
    out
}


/// `pic 9(5)` from a two-byte value: five digits, high digits dropped.
fn five_digits(v: u16) -> [u8; 5] {
    let text = format!("{v:05}");
    let bytes = text.as_bytes();
    bytes[bytes.len() - 5..].try_into().unwrap_or(*b"00000")
}

fn padded(text: &[u8], width: usize) -> Vec<u8> {
    let mut out = vec![b' '; width];
    let take = text.len().min(width);
    out[..take].copy_from_slice(&text[..take]);
    out
}

/// `zzz9.99`-style local date text (`dd/mm/ccyy`), spaces when out of range.
fn date_text(days: i32) -> [u8; 10] {
    if days <= 0 {
        return [b' '; 10];
    }
    let (year, month, day) = CobolDate(days).to_ymd();
    format!("{day:02}/{month:02}/{year:04}").into_bytes().try_into().unwrap_or([b' '; 10])
}

/// `post-date` — `dd/mm/yy` from the item date.
fn posting_date(days: i32) -> [u8; 8] {
    let full = date_text(days);
    let mut out = [b'0'; 8];
    out[..6].copy_from_slice(&full[..6]);
    out[6..].copy_from_slice(&full[8..10]);
    out
}

/// The report, one 132-byte record per line.
#[derive(Debug, Default)]
struct Report {
    bytes: Vec<u8>,
    page: u32,
    line_count: u32,
    /// `file-status (18)` — once a heading has been written the C/F line may
    /// print (`if file-status (18) = 1`).
    headed: bool,
}

impl Report {
    fn emit(&mut self, line: &[u8]) {
        let mut record = padded(line, PRINT_RECORD_BYTES);
        record.truncate(PRINT_RECORD_BYTES);
        // One `write print-record`, one spooled line.
        record.push(b'\n');
        self.bytes.extend_from_slice(&record);
    }

    /// `ba000-Headings`
    fn headings(&mut self, ctx: &PostContext) {
        self.page += 1;
        self.emit(&heading_line_1(self.page));
        self.emit(&heading_line_2(ctx));
        self.emit(LINE_4);
        self.emit(b"");
        self.line_count = 5;
    }

    /// `ba000-New-Heading` (page 2 of the C/F listing)
    fn new_heading(&mut self, ctx: &PostContext) {
        if !self.headed {
            self.headed = true;
        }
        self.page += 1;
        self.emit(&heading_line_1(self.page));
        self.emit(&heading_line_2(ctx));
        const LINE_1A: &[u8] = b"                                                        Un-Applied Credits";
        self.emit(LINE_1A);
        self.emit(b"");
        const LINE_4A: &[u8] =
            b"--Customer--   Invoice      Bal C/F        Applied      Cr. Note          Type    ";
        self.emit(LINE_4A);
        self.emit(b"");
        self.line_count = 6;
    }
}

fn heading_line_1(page: u32) -> Vec<u8> {
    let mut out = padded(b"SL060 (3.01.14)", 54);
    out.extend_from_slice(b"Invoice Posting Report");
    out.extend_from_slice(&padded(b"", 70 - 22));
    out.extend_from_slice(b"Page ");
    out.extend_from_slice(format!("{page:3}").as_bytes());
    out
}

fn heading_line_2(ctx: &PostContext) -> Vec<u8> {
    let mut out = vec![b' '; PRINT_RECORD_BYTES];
    let user = &ctx.user[..ctx.user.len().min(54)];
    out[..user.len()].copy_from_slice(user);
    let at = PRINT_RECORD_BYTES - 10;
    out[at..].copy_from_slice(&ctx.run_date);
    out
}

const LINE_4: &[u8] = b" Number     Date    <------------Customer------------>   Type    Old Balance  New Balance   Dedn     Net         Vat       Gross    ";


/// Run the posting pass over `staged` (OTM2, key order).
///
/// `sales` and `value` are the tables the run rewrites in place. The OTM2
/// stage is cleared by the caller — `outcome.otm3` replaces it.
pub fn post(
    staged: &[OpenItem2],
    sales: &mut BTreeMap<CustomerKey, SalesRow>,
    value: &mut [ValueRow],
    ctx: &PostContext,
) -> PostOutcome {
    let mut out = PostOutcome::default();
    // `file-status (18)` — sl055 sets it when it opens OTM2 (sl055:398) and
    // `sales.cbl` chains the two programs in one run unit, so working storage
    // carries the 1 in. `ba000-New-Heading` therefore never fires from
    // `ba000-Cr-Swop`'s guard, and the C/F line is always allowed to print.
    let mut report = Report { headed: true, ..Report::default() };
    let mut batch = ctx.gl.map(|_| BatchRecord::open(ctx, ctx.next_batch));
    let mut next_batch = ctx.next_batch.wrapping_add(1);
    let mut rrn = ctx.postings;
    let mut posted: Vec<OpenItem2> = Vec::with_capacity(staged.len());
    let mut ws_deduction: Money;

    report.headings(ctx);

    for header in staged {
        let key = header.customer;
        let known = sales.contains_key(&key);
        if !known {
            out.sales_missing = true;
            let mut row = SalesRow::blank(key);
            row.name = padded(&CUSTOMER_UNKNOWN, 30).try_into().unwrap_or([b' '; 30]);
            sales.insert(key, row);
        }
        let lines: Vec<u8> = {
            let row = sales.get(&key).expect("row just ensured");
            row.name.to_vec()
        };
        let name_field = padded(&lines, 25);

        let kind = header.invoice_type;
        // `move oi-header to si-header` … `move si-header to oi-header` at
        // `ba030-end`: the record sl060 writes for a credit note is the si
        // copy, paid/status included.
        let mut record = header.clone();
        let deduct_vat = Money::from(header.deduct_vat);
        let deduct_amt = Money::from(header.deduct_amt);
        let work_vat = header.vat + header.c_vat + header.e_vat + deduct_vat;
        let work_goods = header.net + header.extra;
        let work_net = header.net
            + header.extra
            + header.carriage
            + header.discount
            + deduct_amt;

        let bucket = usize::from(kind.saturating_sub(b'1'));
        out.totals[bucket].vat += work_vat;
        out.totals[bucket].net += work_net;

        let gross = work_net + work_vat;
        ws_deduction = 0;

        if let Some(gl) = ctx.gl {
            let mut legend = build_legend(header.invoice.0, &name_field);
            // `u-date` holds the *item's* date (`zz060` redirected it a few
            // lines earlier), so the posting stamp is dd/mm/ + 2-digit year.
            let date = posting_date(header.date);
            rrn = rrn.wrapping_add(1);
            let b = batch.as_mut().expect("batch open when gl is on");
            b.items += 1;
            out.postings.push(
                PostingRecord {
                    batch: b.nos,
                    number: b.items as u16,
                    code: *b"SL",
                    date,
                    dr: gl.debtors,
                    cr: gl.sales,
                    amount: work_net,
                    legend: std::mem::take(&mut legend),
                    vat_ac: gl.vat,
                    vat_side: *b"CR",
                    vat_amount: header.vat + header.e_vat + header.c_vat,
                }
                .to_bytes(),
            );
            b.input_gross += work_net;
            b.input_vat += header.vat + header.e_vat + header.c_vat;
            b.actual_gross = b.input_gross;
            b.actual_vat = b.input_vat;
            out.postings_written = b.items as u16;
            if b.items >= BATCH_ITEM_LIMIT {
                out.batches.push(b.to_bytes());
                let fresh = BatchRecord::open(ctx, next_batch);
                next_batch = next_batch.wrapping_add(1);
                batch = Some(fresh);
                // A closed batch restarts the item counter and the record
                // number sequence; `batch-start` carries the new watermark.
                if let Some(current) = batch.as_mut() {
                    current.start = rrn.wrapping_add(1);
                }
            }
        }

        let date = header.date;
        let _old_bal: Money;
        {
            let row = sales.get_mut(&key).expect("row exists");
            _old_bal = row.current.cents() - row.unapplied.cents();
            if kind == b'2' || kind == b'1' {
                sales_average(row, work_goods);
            }
            match kind {
                b'1' => {
                    quarter_add(row, ctx.quarter, work_goods);
                    row.last_inv = date;
                    row.last_pay = date;
                }
                b'2' => {
                    quarter_add(row, ctx.quarter, work_goods);
                    row.current.add(work_vat + work_net);
                    row.last_inv = date;
                }
                b'3' => {
                    quarter_add(row, ctx.quarter, work_goods);
                    row.current.add(work_vat + work_net);
                    row.last_pay = date;
                }
                _ => {}
            }
        }
        if kind == b'3' {
            ws_deduction = cr_notes(&mut posted, sales, &mut record, ctx, &mut out);
            let row = sales.get_mut(&key).expect("row exists");
            credit_average(row, work_goods);
        }
        out.total_deduct += ws_deduction;

        let row = sales.get_mut(&key).expect("row exists");
        if row.status == 0 {
            row.status = 1;
        }
        if row.current.cents() < 0 {
            let deficit = -row.current.cents();
            row.unapplied.add(deficit);
            row.current = Wide::ZERO;
        }
        let new_bal = row.current.cents() - row.unapplied.cents();

        report.emit(&line_5(header, &name_field, work_net, work_vat, gross, ws_deduction, _old_bal, new_bal));
        report.line_count += 1;
        if u32::from(ctx.page_lines) > 0 && report.line_count > u32::from(ctx.page_lines) {
            report.headings(ctx);
        }

        posted.push(record);
    }

    let posted_count = posted.len();
    totals_and_deductions(&mut report, &mut out, sales, value, ctx, posted_count);

    if let Some(b) = batch.as_mut() {
        out.batches.push(b.to_bytes());
    }
    out.next_batch = next_batch;

    // Phase 2: close un-applied credit notes against the customer's later
    // open invoices. The listing runs over OTM3 in key order.
    posted.sort_by_key(|row| (row.customer.0, row.invoice.0));
    let mut carry = 0;
    for index in 0..posted.len() {
        if posted[index].invoice_type != b'3' || posted[index].closed() {
            continue;
        }
        carry += cr_swop(&mut posted, index, ctx, &mut report);
    }
    out.unapplied_c_notes = carry;

    // `file-status (18) = 1`: the OTM3 read loop reached at least one record.
    if posted_count > 0 {
        report.emit(&line_8(b"Un-Applied Credits C/F ", carry));
    }
    if out.sales_missing {
        report.emit(b"SL134 Warning Record/s missing in Sales File");
    }
    out.report = report.bytes;
    out.otm3 = posted.iter().map(|row| row.to_bytes()).collect();
    out.next_batch = next_batch;
    out
}

impl OpenItem2 {
    /// `s-closed` — `oi-status = 1`.
    fn closed(&self) -> bool {
        self.status == b'1'
    }

    /// Every leg `ba000-Cr-Swop` sums before apportioning. Deliberately
    /// excludes `p-c`.
    fn legs(&self) -> Money {
        self.net
            + self.extra
            + self.carriage
            + self.vat
            + self.discount
            + self.e_vat
            + self.c_vat
            + Money::from(self.deduct_amt)
            + Money::from(self.deduct_vat)
    }

    /// `ba000-Clear-Invoice-Deduct`
    fn clear_deduct(&mut self, work_b: Money, sales_row: &mut SalesRow) {
        if work_b > 0 {
            sales_row.current.add(-work_b);
            self.deduct_amt = 0;
            self.deduct_vat = 0;
        }
    }
}

/// `work-2` is `s9(14) comp-3`: the product is truncated to fourteen digits
/// before the goods are added, and the division result is truncated again by
/// the `binary-long` receiver.
const WORK_2_DIGITS: i128 = 100_000_000_000_000;

fn scaled_average(activety: i32, average: i32, goods: Money) -> Option<i32> {
    let mut work_2: i128 = i128::from(activety) * i128::from(average) % WORK_2_DIGITS;
    if work_2 == 0 {
        return None;
    }
    work_2 = (work_2 + i128::from(goods)) % WORK_2_DIGITS;
    Some((work_2 / i128::from(activety)) as i32)
}

/// `ba000-Sales-Comp` — the running spend average, floored.
fn sales_average(row: &mut SalesRow, goods: Money) {
    let mut work_2: i128 = if row.activety != 0 && row.average != 0 {
        i128::from(row.activety) * i128::from(row.average) % WORK_2_DIGITS
    } else {
        0
    };
    row.activety += 1;
    work_2 = (work_2 + i128::from(goods)) % WORK_2_DIGITS;
    row.average = (work_2 / i128::from(row.activety)) as i32;
}

/// `ba000-Credit-Comp` — the same average, but only once there is a history.
fn credit_average(row: &mut SalesRow, goods: Money) {
    if let Some(value) = scaled_average(row.activety, row.average, goods) {
        row.average = value;
    }
}

/// `post-legend` — the invoice digits, `" : "`, then the customer name,
/// STRING-ed into 32 bytes without an overflow handler.
fn build_legend(invoice: u32, name: &[u8]) -> [u8; 32] {
    let digits = format!("{invoice:08}");
    let trimmed = digits.trim_start_matches('0');
    let digits = if trimmed.is_empty() { "0" } else { trimmed };
    let mut out = Vec::new();
    out.extend_from_slice(digits.as_bytes());
    out.extend_from_slice(b" : ");
    out.extend_from_slice(name);
    padded(&out, 32).try_into().unwrap_or([b' '; 32])
}

/// `ba000-Apportion` — hand part of a credit note to one open invoice.
///
/// Returns `true` when the invoice's own status flipped to closed.
fn apportion(
    invoice: &mut OpenItem2,
    work_1: &mut Money,
    work_b: Money,
    customer: &mut SalesRow,
    deducted: &mut u32,
    si: &mut OpenItem2,
) -> bool {
    let mut work_a = invoice.legs() - invoice.paid;
    if work_a == 0 {
        invoice.status = b'1';
        return true;
    }
    if work_a <= 0 {
        return false;
    }
    work_a -= work_b;
    let mut closed = false;
    if work_a == *work_1 {
        invoice.paid += *work_1;
        si.paid += *work_1;
        invoice.p_c += *work_1;
        *work_1 = 0;
        invoice.clear_deduct(work_b, customer);
        if work_b > 0 {
            *deducted += 1;
        }
        invoice.status = b'1';
        si.status = b'1';
        closed = true;
    } else if work_a > *work_1 {
        invoice.paid += *work_1;
        si.paid += *work_1;
        invoice.p_c += *work_1;
        *work_1 = 0;
        si.status = b'1';
    } else {
        invoice.paid += work_a;
        si.paid += work_a;
        invoice.p_c += work_a;
        *work_1 -= work_a;
        invoice.clear_deduct(work_b, customer);
        if work_b > 0 {
            *deducted += 1;
        }
        invoice.status = b'1';
        closed = true;
    }
    if *work_1 == 0 {
        si.status = b'1';
    }
    closed
}

/// `ba000-CR-Notes` — spread a credit note over the customer's open invoices
/// from its own invoice number upward, then from the start of the customer.
///
/// Returns `ws-deduction` for the print line and `total-deduct`.
fn cr_notes(
    rows: &mut [OpenItem2],
    sales: &mut BTreeMap<CustomerKey, SalesRow>,
    si: &mut OpenItem2,
    _ctx: &PostContext,
    out: &mut PostOutcome,
) -> Money {
    let mut work_1 = si.legs() + si.paid;
    if work_1 < 0 {
        work_1 = -work_1;
    }
    work_1 -= si.paid;
    let mut deducted = 0;
    let mut carried: Money = 0;

    for pass in 0..2 {
        let first_pass = pass == 0;
        let start = if first_pass {
            rows
                .iter()
                .position(|row| (row.customer.0, row.invoice.0) >= (si.customer.0, si.cr as u32))
                .unwrap_or(rows.len())
        } else {
            0
        };
        let mut index = start;
        while index < rows.len() {
            let row = &mut rows[index];
            index += 1;
            if row.invoice_type != b'2' {
                continue;
            }
            if row.customer != si.customer {
                break;
            }
            if row.closed() {
                continue;
            }
            let mut work_b = Money::from(row.deduct_amt) + Money::from(row.deduct_vat);
            if row.date + 1 + i32::from(row.deduct_days) <= si.date {
                work_b = 0;
            }
            carried = work_b;
            if i64::from(si.cr) == i64::from(row.invoice.0) || !first_pass {
                let customer = sales.entry(row.customer).or_insert_with(|| SalesRow::blank(row.customer));
                let _ = apportion(row, &mut work_1, work_b, customer, &mut deducted, si);
            }
        }
        if work_1 == 0 || !first_pass {
            break;
        }
    }
    out.total_mov_ded += deducted;
    carried
}

/// `ba000-Cr-Swop` — phase 2's close-out of one un-applied credit note.
///
/// There is no invoice loop here: phase 1 already apportioned what it could
/// (`ba000-CR-Notes`), and any balance still on the note is carried forward as
/// un-applied. The note's `oi-paid` takes the negated balance, which is what
/// makes `legs + paid` zero for a closed note.
fn cr_swop(
    rows: &mut [OpenItem2],
    index: usize,
    ctx: &PostContext,
    report: &mut Report,
) -> Money {
    let work_1 = rows[index].legs() + rows[index].paid;
    // `if work-1 = zero` — SL131 display and an `accept`; UI only, no artifact.
    if !report.headed {
        report.new_heading(ctx);
    }
    rows[index].status = b'1';
    let note = rows[index].clone();
    report.emit(&line_7(&note, work_1));
    report.line_count += 1;
    if u32::from(ctx.page_lines) > 0 && report.line_count > u32::from(ctx.page_lines) {
        report.new_heading(ctx);
    }

    let carried = -work_1;
    rows[index].paid += carried;
    // `work-b` takes the *unnnegated* balance (negative for a note); the print
    // edit shows the magnitude either way.
    work_1
}

#[allow(clippy::too_many_arguments)]
fn line_5(
    header: &OpenItem2,
    name: &[u8],
    net: Money,
    vat: Money,
    gross: Money,
    deduction: Money,
    old_bal: Money,
    new_bal: Money,
) -> Vec<u8> {
    let kind: &[u8] = match header.invoice_type {
        b'2' => b"Invoice",
        b'3' => b"CR. Note",
        b'1' => b"Receipt",
        _ => b"",
    };
    let mut out = edit_suppressed(8, i64::from(header.invoice.0));
    out.push(b' ');
    out.extend_from_slice(&date_text(header.date));
    out.push(b' ');
    out.extend_from_slice(&padded(&header.customer.0, 9));
    out.extend_from_slice(&padded(name, 25));
    out.extend_from_slice(b"  ");
    out.extend_from_slice(&padded(kind, 9));
    out.extend_from_slice(&edit_money_cr(7, old_bal));
    out.extend_from_slice(&edit_money_cr(7, new_bal));
    out.extend_from_slice(&edit_money_blank_zero(4, deduction));
    out.extend_from_slice(&edit_money_cr(7, net));
    out.extend_from_slice(&edit_money_cr(7, vat));
    out.extend_from_slice(&edit_money_cr(7, gross));
    out
}

fn line_6(total: &str, bucket: &BucketTotal) -> Vec<u8> {
    let mut out = vec![b' '; 11];
    out.extend_from_slice(b"Total  Posted ");
    out.extend_from_slice(&padded(total.as_bytes(), 18));
    out.extend_from_slice(&money_13(bucket.net));
    out.extend_from_slice(&money_13(bucket.vat));
    out.extend_from_slice(&money_13(bucket.gross()));
    out
}

/// `z(7)9.99cr` — zero suppressed, `CR` trailing a negative, thirteen wide.
fn money_13(cents: Money) -> Vec<u8> {
    let mut out = edit_suppressed(8, cents / 100);
    out.push(b'.');
    out.extend_from_slice(format!("{:02}", (cents % 100).unsigned_abs()).as_bytes());
    out.extend_from_slice(if cents < 0 { b"CR" } else { b"  " });
    out
}

fn line_7(note: &OpenItem2, balance: Money) -> Vec<u8> {
    let mut out = padded(&note.customer.0, 12);
    out.extend_from_slice(&edit_suppressed(8, i64::from(note.invoice.0)));
    out.extend_from_slice(b"  ");
    out.extend_from_slice(b"    ");
    out.extend_from_slice(&edit_money_blank_zero(8, balance));
    out.extend_from_slice(b"    ");
    out.extend_from_slice(&edit_money_blank_zero(8, note.paid));
    out.extend_from_slice(b"    ");
    out.extend_from_slice(&edit_suppressed(8, i64::from(note.cr)));
    out.extend_from_slice(b"  ");
    out.extend_from_slice(b"    ");
    out.extend_from_slice(&padded(b"Cr. Note", 12));
    out
}

fn line_8(description: &[u8], total: Money) -> Vec<u8> {
    let mut out = vec![b' '; 24];
    out.extend_from_slice(&padded(description, 32));
    out.extend_from_slice(&edit_money_blank_zero(8, total));
    out
}

/// `aa030-Main-End` — the posted totals, the late-deduction line and the
/// `Szd` value-file adjustment.
fn totals_and_deductions(
    report: &mut Report,
    out: &mut PostOutcome,
    sales: &mut BTreeMap<CustomerKey, SalesRow>,
    value: &mut [ValueRow],
    ctx: &PostContext,
    _posted: usize,
) {
    let _ = sales;
    let page_lines = u32::from(ctx.page_lines.max(1));
    if report.line_count > page_lines.saturating_sub(7) {
        report.headings(ctx);
    }
    const LITERALS: [&str; 3] = ["Receipts", "Invoices", "Credit Notes"];
    for (index, total) in LITERALS.iter().enumerate() {
        report.emit(&line_6(total, &out.totals[index]));
        report.emit(b"");
        if report.line_count > page_lines {
            report.headings(ctx);
        }
    }
    let mut late = vec![b' '; 11];
    late.extend_from_slice(b"Total  Amount Late Deductions");
    late.extend_from_slice(b"   ");
    late.extend_from_slice(&money_13(out.total_deduct));
    report.emit(&late);
    report.emit(b"");

    if out.total_deduct != 0 {
        analyse_deductions(value, out);
    }
}

/// `ba000-Analise-Deductions` — the `Szd` row and its successor take the
/// deduction out of the value-file counters and sums.
fn analyse_deductions(value: &mut [ValueRow], out: &mut PostOutcome) {
    let Some(start) = value.iter().position(|row| &row.code == b"Szd") else {
        return;
    };
    for index in start..value.len().min(start + 2) {
        let row = &mut value[index];
        row.t_this = row.t_this.saturating_sub(out.total_mov_ded);
        row.t_year = row.t_year.saturating_sub(out.total_mov_ded);
        row.v_this -= out.total_deduct;
        row.v_year -= out.total_deduct;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::posting;
    use crate::posting::OpenItem2;

    fn root() -> std::path::PathBuf {
        std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
    }

    fn golden(rel: &str) -> Vec<u8> {
        std::fs::read(root().join(rel)).unwrap_or_else(|e| panic!("{rel}: {e}"))
    }

    fn ctx() -> PostContext {
        PostContext {
            gl: Some(GlAccounts::ZERO),
            // The seeded system record carries `cyclea`/`scycle` = 1.
            cycle: 1,
            // SYS002 is driven with a blank Current Quarter, so the global
            // arrives as zero and the turnover subscript runs off the front.
            quarter: 0,
            run_date: *b"03/11/2026",
            run_date_days: 155_535,
            next_batch: 1,
            postings: 0,
            page_lines: 48,
            user: {
                let mut user = [b' '; 32];
                user[..16].copy_from_slice(b"Harness Test Co ");
                user
            },
        }
    }

    /// A staged header with every money leg spelled out.
    #[allow(clippy::too_many_arguments)]
    fn item(customer: &[u8; 7], invoice: u32, kind: u8, net: Money, vat: Money) -> OpenItem2 {
        OpenItem2 {
            customer: crate::invoice::CustomerKey(*customer),
            invoice: crate::invoice::InvoiceNumber(invoice),
            date: 155_534,
            invoice_type: b'0' + kind,
            description: [b' '; 25],
            hold_flag: b' ',
            unapl: b' ',
            p_c: net + vat,
            net,
            extra: 0,
            carriage: 0,
            vat,
            discount: 0,
            e_vat: 0,
            c_vat: 0,
            paid: 0,
            status: b'0',
            deduct_days: 0,
            deduct_amt: 0,
            deduct_vat: 0,
            days: 30,
            cr: 0,
            applied: b' ',
            date_cleared: 0,
        }
    }

    fn sales_of(rows: &[SalesRow]) -> BTreeMap<CustomerKey, SalesRow> {
        rows.iter().map(|row| (row.key, row.clone())).collect()
    }

    fn customer(name: &[u8]) -> CustomerKey {
        let mut key = [b' '; 7];
        key.copy_from_slice(&name[..7]);
        CustomerKey(key)
    }

    #[test]
    fn dbg_packed_add() {
        let out = packed_add([0x20; 6], 100_000);
        eprintln!("result {:02x?}", out);
        let mut row = SalesRow::blank(customer(b"CUST010"));
        quarter_add(&mut row, 0, 100_000);
        eprintln!("row.last {:02x?}", row.last.0);
    }

    #[test]
    fn sales_row_round_trips_its_300_bytes() {
        let raw = golden("fixtures/golden/sl060/clean/salesled.flat");
        let bytes: [u8; SALES_RECORD_BYTES] = raw[..SALES_RECORD_BYTES].try_into().expect("one row");
        let row = SalesRow::from_bytes(bytes);
        assert_eq!(row.name[..13], *b"CUST010 Tradi");
        let again = row.to_bytes();
        let first = (0..SALES_RECORD_BYTES).find(|at| again[*at] != bytes[*at]);
        assert_eq!(first, None, "round-trip differs at {:?}", first.map(|at| (at, bytes[at], again[at])));
    }

    #[test]
    fn posting_amounts_overpunch_the_sign() {
        let record = PostingRecord {
            batch: 1,
            number: 2,
            code: *b"SL",
            date: *b"02/11/26",
            dr: *b"000000",
            cr: *b"000000",
            amount: -3_456_789_012,
            legend: [b' '; 32],
            vat_ac: *b"000000",
            vat_side: *b"CR",
            vat_amount: -12,
        };
        let bytes = record.to_bytes();
        assert_eq!(&bytes[36..46], b"345678901r");
        assert_eq!(bytes[45], b'r', "-2 overpunches its final digit");
        assert_eq!(&bytes[88..98], b"000000001r");
        assert_eq!(bytes[97], b'r');
    }

    #[test]
    fn batch_amounts_are_unsigned_packed_with_an_f_sign() {
        let batch = BatchRecord::open(&ctx(), 7);
        let mut batch = batch;
        batch.input_gross = 12_345_678_901;
        batch.items = 99;
        let bytes = batch.to_bytes();
        assert_eq!(&bytes[28..34], &[0x12, 0x34, 0x56, 0x78, 0x90, 0x1f]);
        assert_eq!(&bytes[6..8], b"99");
        assert_eq!(bytes[0], b'3', "`ledger` is a display digit");
        assert_eq!(&bytes[1..6], b"00007");
    }

    #[test]
    fn a_receipt_raises_turnover_and_leaves_current_alone() {
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let mut value = Vec::new();
        let staged = [item(b"CUST010", 1001, 1, 100_000, 20_000)];
        let out = post(&staged, &mut sales, &mut value, &ctx());
        let row = sales.get(&customer(b"CUST010")).expect("row");
        // `current-quarter` is a caller global the harness never sets, so the
        // subscript runs off the front of `Quarters` into `sales-last` (F-B010).
        assert_eq!(row.last.cents(), 100_000);
        assert_eq!(row.turnover[0].cents(), 0);
        assert_eq!(row.current.cents(), 0);
        assert_eq!(row.last_inv, 155_534);
        assert_eq!(row.last_pay, 155_534);
        assert_eq!(row.status, 1);
        assert_eq!(out.postings.len(), 1);
        assert_eq!(out.totals[0].net, 100_000);
        assert_eq!(out.otm3.len(), 1);
    }

    #[test]
    fn an_invoice_raises_current_and_the_totals() {
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let staged = [item(b"CUST010", 1001, 2, 100_000, 20_000)];
        let out = post(&staged, &mut sales, &mut Vec::new(), &ctx());
        let row = sales.get(&customer(b"CUST010")).expect("row");
        assert_eq!(row.current.cents(), 120_000);
        assert_eq!(out.totals[1].net, 100_000);
        assert_eq!(out.totals[1].vat, 20_000);
        assert_eq!(out.totals[1].gross(), 120_000);
    }

    #[test]
    fn an_unknown_customer_gets_a_row_and_the_134_warning() {
        let mut sales = sales_of(&[]);
        let staged = [item(b"CUST999", 1001, 2, 50_000, 10_000)];
        let out = post(&staged, &mut sales, &mut Vec::new(), &ctx());
        let row = sales.get(&customer(b"CUST999")).expect("row written");
        assert_eq!(&row.name, &padded(&CUSTOMER_UNKNOWN, 30)[..]);
        assert_eq!(row.status, 1);
        assert!(out.sales_missing);
        assert!(String::from_utf8_lossy(&out.report).contains("SL134"));
    }

    #[test]
    fn a_negative_balance_moves_to_unapplied() {
        let mut row = SalesRow::blank(customer(b"CUST010"));
        row.current = Wide::ZERO.set(100);
        let mut sales = sales_of(&[row]);
        let staged = [item(b"CUST010", 1001, 3, -50_000, -10_000)];
        let out = post(&staged, &mut sales, &mut Vec::new(), &ctx());
        let row = sales.get(&customer(b"CUST010")).expect("row");
        assert_eq!(row.current.cents(), 0);
        assert_eq!(row.unapplied.cents(), 59_900);
        assert_eq!(out.totals[2].net, -50_000);
    }

    #[test]
    fn a_credit_note_apportions_onto_its_invoice() {
        let invoice = item(b"CUST010", 1001, 2, 100_000, 20_000);
        let mut note = item(b"CUST010", 1002, 3, -40_000, -8_000);
        note.cr = 1001;
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let out = post(&[invoice.clone(), note.clone()], &mut sales, &mut Vec::new(), &ctx());
        invoice.closed();

        let applied = OpenItem2::from_bytes(&out.otm3[0]).expect("row");
        assert_eq!(applied.paid, 48_000, "whole note applied to the invoice");
        assert_eq!(applied.p_c, 120_000 + 48_000);
        assert_eq!(applied.status, b'0', "a part payment leaves the invoice open");
        let closed_note = OpenItem2::from_bytes(&out.otm3[1]).expect("row");
        assert_eq!(closed_note.status, b'1', "the note closes itself");
        assert_eq!(out.unapplied_c_notes, 0);
    }

    #[test]
    fn a_credit_note_larger_than_the_invoice_leaves_a_balance() {
        let invoice = item(b"CUST010", 1001, 2, 10_000, 2_000);
        let mut note = item(b"CUST010", 1002, 3, -40_000, -8_000);
        note.cr = 1001;
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let out = post(&[invoice, note], &mut sales, &mut Vec::new(), &ctx());
        let leftover = OpenItem2::from_bytes(&out.otm3[0]).expect("row");
        assert_eq!(leftover.paid, 12_000);
        assert_eq!(leftover.status, b'1');
        assert_eq!(out.unapplied_c_notes, -36_000, "C/F carries the remainder");
        assert!(String::from_utf8_lossy(&out.report).contains("Un-Applied Credits C/F"));
    }

    #[test]
    fn a_late_deduction_is_cleared_when_the_note_covers_it() {
        let mut invoice = item(b"CUST010", 1001, 2, 100_000, 20_000);
        invoice.deduct_amt = 12_500;
        invoice.deduct_vat = 2_500;
        invoice.deduct_days = 4;
        let mut note = item(b"CUST010", 1002, 3, -200_000, -40_000);
        note.cr = 1001;
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let mut value = Vec::new();
        let out = post(&[invoice, note], &mut sales, &mut value, &ctx());
        let applied = OpenItem2::from_bytes(&out.otm3[0]).expect("row");
        assert_eq!(applied.deduct_amt, 0);
        assert_eq!(applied.deduct_vat, 0);
        assert_eq!(out.total_mov_ded, 1);
        assert_eq!(out.total_deduct, 15_000);
        // The invoice's own 135000 legs less the 15000 deduction.
        assert_eq!(applied.paid, 120_000);
        assert_eq!(applied.deduct_days, 4, "`oi-deduct-days` survives the clear");
    }

    #[test]
    fn a_stale_deduction_survives_an_old_invoice() {
        let mut invoice = item(b"CUST010", 1001, 2, 100_000, 20_000);
        invoice.deduct_amt = 12_500;
        invoice.deduct_vat = 2_500;
        invoice.deduct_days = 0;
        invoice.date = 155_400; // the note is dated 155534: 1 + 0 days is past
        let mut note = item(b"CUST010", 1002, 3, -200_000, -40_000);
        note.cr = 1001;
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let out = post(&[invoice, note], &mut sales, &mut Vec::new(), &ctx());
        let applied = OpenItem2::from_bytes(&out.otm3[0]).expect("row");
        assert_eq!(applied.deduct_amt, 12_500, "left on the invoice");
        // A stale deduction is not subtracted from `work-a`, so the whole leg
        // set is paid: 100000 + 20000 + 12500 + 2500.
        assert_eq!(applied.paid, 135_000);
        assert_eq!(out.total_mov_ded, 0);
    }

    #[test]
    fn batches_roll_over_at_99_items() {
        let customer = customer(b"CUST010");
        let mut sales = sales_of(&[SalesRow::blank(customer)]);
        let staged: Vec<OpenItem2> =
            (0..100).map(|i| item(b"CUST010", 1000 + i, 2, 1_000, 200)).collect();
        let out = post(&staged, &mut sales, &mut Vec::new(), &ctx());
        assert_eq!(out.batches.len(), 2);
        assert_eq!(out.postings.len(), 100);
        let first = &out.postings[98];
        assert_eq!(&first[0..5], b"00001");
        assert_eq!(&first[5..10], b"00099");
        let second = &out.postings[99];
        assert_eq!(&second[0..5], b"00002");
        assert_eq!(&second[5..10], b"00001");
        let rolled = &out.batches[1];
        assert_eq!(&rolled[6..8], b"01", "the 100th item opens the new batch");
        assert_eq!(&rolled[91..96], b"00100");
    }

    #[test]
    fn posting_dates_come_from_the_item_not_the_run() {
        let mut staged = item(b"CUST010", 1001, 2, 1_000, 0);
        staged.date = 155_400; // 2026-08-20
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let out = post(&[staged], &mut sales, &mut Vec::new(), &ctx());
        assert_eq!(&out.postings[0][12..20], b"21/06/26");
    }

    #[test]
    fn the_no_gl_run_skips_postings_and_batches() {
        let mut sales = sales_of(&[SalesRow::blank(customer(b"CUST010"))]);
        let mut context = ctx();
        context.gl = None;
        let out = post(&[item(b"CUST010", 1001, 2, 1_000, 0)], &mut sales, &mut Vec::new(), &context);
        assert!(out.postings.is_empty());
        assert!(out.batches.is_empty());
        assert_eq!(out.otm3.len(), 1);
    }

    /// The report string is 132-byte records; compare the text, not the pads.
    fn report_lines(bytes: &[u8]) -> Vec<String> {
        String::from_utf8_lossy(bytes)
            .split('\n')
            .map(|line| line.trim_end().to_string())
            .filter(|line| !line.is_empty())
            .collect()
    }

    fn first_diff(left: &[u8], right: &[u8]) -> String {
        let at = left.iter().zip(right.iter()).position(|(a, b)| a != b);
        match at {
            None if left.len() != right.len() => format!(" (length {} vs {})", left.len(), right.len()),
            None => " (identical)".to_string(),
            Some(at) => {
                let lo = at.saturating_sub(8);
                let hi = (at + 8).min(left.len());
                format!(
                    " at {} (record {}, col {}): {:02x?} vs {:02x?}",
                    at,
                    at / SALES_RECORD_BYTES,
                    at % SALES_RECORD_BYTES,
                    &left[lo..hi],
                    &right[lo..hi.min(right.len())]
                )
            }
        }
    }

    /// Replay a COBOL chained run and compare every artifact byte for byte.
    fn replay(case: &str) {
        let src = case.replace('-', "_");
        let staged_bytes = golden(&format!("fixtures/golden/sl055/{src}/openitm2.dat"));
        let staged: Vec<OpenItem2> = staged_bytes
            .chunks(114)
            .map(|chunk| {
                OpenItem2::from_bytes(chunk).unwrap_or_else(|| panic!("{case}: bad OTM2 row"))
            })
            .collect();

        let mut sales: BTreeMap<CustomerKey, SalesRow> = {
            let raw = golden(&format!("fixtures/golden/sl060/{case}/input-sales.flat"));
            let mut map = BTreeMap::new();
            for chunk in raw.chunks(SALES_RECORD_BYTES) {
                let row = SalesRow::from_bytes(chunk.try_into().expect("300 bytes"));
                map.insert(row.key, row);
            }
            map
        };
        let mut value: Vec<ValueRow> = golden(&format!("fixtures/golden/sl055/{src}/value.flat"))
            .chunks(posting::VALUE_RECORD_BYTES)
            .map(|chunk| ValueRow::from_bytes(chunk).expect("value row"))
            .collect();

        let out = post(&staged, &mut sales, &mut value, &ctx());

        let expected_sales = golden(&format!("fixtures/golden/sl060/{case}/salesled.flat"));
        let built: Vec<u8> = sales.values().flat_map(|row| row.clone().to_bytes()).collect();
        eprintln!("{case} last251..261={:02x?} exp={:02x?}",
            &built[251..261], &expected_sales[251..261]);
        let built: Vec<u8> = sales.values().flat_map(|row| row.clone().to_bytes()).collect();
        assert_eq!(built, expected_sales, "{case}: sales ledger differs{}", first_diff(&built, &expected_sales));

        let expected_otm3 = golden(&format!("fixtures/golden/sl060/{case}/openitm3.flat"));
        if out.otm3.concat() != expected_otm3 {
            let l = out.otm3.concat();
            let at = l.iter().zip(expected_otm3.iter()).position(|(a, b)| a != b);
            eprintln!("{case} otm3 diff at {:?}", at);
            std::fs::write("/tmp/otm3.built", &l).unwrap();
        }
        assert_eq!(out.otm3.concat(), expected_otm3, "{case}: open-item ledger differs");

        let expected_postings = golden(&format!("fixtures/golden/sl060/{case}/posting.flat"));
        assert_eq!(out.postings.concat(), expected_postings, "{case}: postings differ");

        let expected_batches = golden(&format!("fixtures/golden/sl060/{case}/batch.flat"));
        if out.batches.concat() != expected_batches {
            let l = &out.batches.concat();
            let at = l.iter().zip(expected_batches.iter()).position(|(a, b)| a != b);
            eprintln!("{case} batch diff at {:?}: {:02x?} vs {:02x?}", at,
                &l[..40], &expected_batches[..40]);
        }
        assert_eq!(out.batches.concat(), expected_batches, "{case}: batches differ");

        let expected_report = golden(&format!("fixtures/golden/sl060/{case}/prt-1"));
        assert_eq!(report_lines(&out.report), report_lines(&expected_report), "{case}: report");
    }

    #[test]
    fn cobol_chain_matches_on_clean() {
        replay("clean");
    }

    #[test]
    fn cobol_chain_matches_on_credit_note() {
        replay("credit-note");
    }

    #[test]
    fn cobol_chain_matches_on_mixed() {
        replay("mixed");
    }

    #[test]
    fn cobol_chain_matches_on_pending() {
        replay("pending");
    }

    #[test]
    fn cobol_chain_matches_on_comment_lines() {
        replay("comment-lines");
    }
}
