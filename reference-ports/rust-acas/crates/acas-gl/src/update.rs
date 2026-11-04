//! `gl072` — Batch Transaction Update: the only writer of ledger balances.
//!
//! The program walks the sorted `postrans.tmp` stream, one batch at a time,
//! re-reads each account it touches with a keyed `READ`, adds the leg amount to
//! `ledger-balance`, rewrites the record and prints a posting report.
//!
//! Everything the COBOL does on the way is kept, fossils included:
//!
//! - the page check runs *after* the row is written and after `line-cnt` is
//!   incremented, so the row that overflows a page still prints on it
//!   (F-B072 Part 7);
//! - a failed keyed read leaves the record area untouched, so the
//!   brought-forward row of a missing account repeats the previous account's
//!   name and balance (Part 6);
//! - a failed or not-`waiting` batch read sets `we-error = 999` *after* the
//!   heading block for that batch has printed (Part 8);
//! - `l6-account` is fed `ledger-nos / 100`, so the account's last two digits
//!   print as its decimals (Part 6);
//! - `tot-dr` / `tot-cr` are unsigned `9(8)v99`, so a negative leg into them
//!   stores its magnitude.
//!
//! Only `ledger-balance` is written; `ledger-last` and the four quarters are
//! carried through untouched (Part 3).
//!
//! One deliberate divergence: a leg whose record does not decode (a non-digit
//! in a numeric slice) is dropped whole. COBOL only guards `post-batch` for
//! numeric and would move the remaining bytes through regardless; in a
//! well-formed `postrans.tmp` the two agree, and dropping is the safer read of
//! a malformed one.

use std::collections::BTreeMap;

use acas_common::cobol_date::CobolDate;
use acas_sales::report::{edit_masked_blank_when_zero, edit_suppressed, PrintFile, Record};

use crate::records::{
    Money, BATCH_RECORD_BYTES, LEDGER_RECORD_BYTES, TRANS_RECORD_BYTES, VALUE_MAX_CENTS,
};

/// `n` bytes of blank report record.
fn blank(n: usize) -> String {
    " ".repeat(n)
}

/// `pic 9999.99 blank when zero` from `ledger-nos / 100`.
fn edit_account(nos: &[u8]) -> String {
    let Some(value) = decimal(nos) else {
        return blank(7);
    };
    if value == 0 {
        return blank(7);
    }
    let whole = value / 100;
    let cents = value % 100;
    format!("{whole:04}.{cents:02}")
        .chars()
        .rev()
        .take(7)
        .collect::<String>()
        .chars()
        .rev()
        .collect()
}

/// `pic 99 blank when zero`. A low-values source is copied through rather than
/// blanked — the MOVE is display to display, so NULs reach the spool.
fn edit_pc(pc: &[u8]) -> String {
    match decimal(pc) {
        Some(0) => blank(2),
        None => String::from_utf8_lossy(pc).into_owned(),
        Some(value) => format!("{value:02}")
            .chars()
            .rev()
            .take(2)
            .collect::<String>()
            .chars()
            .rev()
            .collect(),
    }
}

/// `pic z(7)9.99cr blank when zero`.
fn edit_balance(cents: Money) -> String {
    if cents == 0 {
        return blank(13);
    }
    let mut rendered = edit_masked_blank_when_zero(cents, "zzzzzzz9.99");
    rendered.push_str(if cents < 0 { "CR" } else { "  " });
    rendered
}

/// `pic z(7)9.99 blank when zero`.
fn edit_unsigned_money(cents: Money) -> String {
    edit_masked_blank_when_zero(cents, "zzzzzzz9.99")
}

/// `pic bbbz9 blank when zero` — three spaces, then the number's last two
/// digits zero-suppressed.
fn edit_tran(post: &[u8]) -> String {
    match decimal(post) {
        Some(0) | None => blank(5),
        Some(value) => {
            let mut field = String::from("   ");
            field.push_str(&edit_suppressed(value % 100, 2));
            field
        }
    }
}

fn decimal(bytes: &[u8]) -> Option<u32> {
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

/// `s9(8)v99 comp-3`, six bytes. Ten digits pack two per byte; the sixth byte
/// carries an eleventh leading digit in its high nibble and the sign in its
/// low one (`0x0c` plus, `0x0d` minus) — GnuCOBOL emits that pad nibble in
/// front of the value, so the digit run is eleven wide with the implied
/// decimal after the tenth.
fn unpack_packed(field: &[u8]) -> Option<Money> {
    if field.len() != 6 {
        return None;
    }
    let mut magnitude: u64 = 0;
    for (index, byte) in field.iter().enumerate() {
        let (high, low) = (*byte >> 4, *byte & 0x0f);
        if index == 5 {
            if high > 9 {
                return None;
            }
            magnitude = magnitude * 10 + u64::from(high);
        } else {
            if high > 9 || low > 9 {
                return None;
            }
            magnitude = magnitude * 100 + u64::from(high) * 10 + u64::from(low);
        }
    }
    let negative = field[5] & 0x0f == 0x0d;
    Some(if negative { -(magnitude as i64) } else { magnitude as i64 })
}

/// The same. The digit run is eleven wide (a leading pad plus ten digits), so
/// the sixth byte takes the last one and the sign; the magnitude is clamped to
/// the ten digits the field can carry.
fn pack_packed(cents: Money) -> [u8; 6] {
    let magnitude = cents.unsigned_abs().min(VALUE_MAX_CENTS - 1);
    let text = format!("0{magnitude:010}");
    let digits: Vec<u8> = text.bytes().map(|byte| byte - b'0').collect();
    let mut out = [0u8; 6];
    for index in 0..5 {
        out[index] = digits[index * 2] << 4 | digits[index * 2 + 1];
    }
    out[5] = digits[10] << 4 | if cents < 0 { 0x0d } else { 0x0c };
    out
}

/// Offsets inside `ledger-record` (F-B072 Part 3).
const LEDGER_NOS: std::ops::Range<usize> = 0..6;
const LEDGER_PC: std::ops::Range<usize> = 6..8;
const LEDGER_NAME: std::ops::Range<usize> = 16..40;
const LEDGER_BALANCE: std::ops::Range<usize> = 40..46;

/// Offsets inside `batch-record` (F-B072 Part 4).
const BATCH_CLEARED: usize = 9;
const BATCH_POSTED: std::ops::Range<usize> = 20..24;
const BATCH_DESCRIPTION: std::ops::Range<usize> = 52..76;

/// The `ledger-record` area at its start value. GnuCOBOL leaves file record
/// areas at low-values, and the empty-stream report prints those bytes through
/// (`l6-legend` comes out as NULs), so the port starts from NULs rather than
/// from a synthetic blank record.
fn unread_ledger() -> [u8; LEDGER_RECORD_BYTES] {
    [0u8; LEDGER_RECORD_BYTES]
}

/// What the update needs from the caller.
#[derive(Debug, Clone)]
pub struct UpdateContext {
    /// `page-lines` from the system record.
    pub page_lines: usize,
    /// `scycle`, printed in the batch heading.
    pub cycle: u8,
    /// `run-date`, stamped on the batch when it closes.
    pub run_date: i32,
    /// `to-day` (`dd/mm/ccyy`), the account-summary date.
    pub to_day: [u8; 10],
    /// `date-form`: 1 UK, 2 USA, 3 International. Anything else reads as UK.
    pub date_form: u8,
    /// `prog-name` — the report's left heading.
    pub prog_name: String,
}

/// The sorted legs and the two tables the update touches.
pub struct UpdateInput<'a> {
    pub legs: &'a [[u8; TRANS_RECORD_BYTES]],
    pub ledger: &'a BTreeMap<[u8; 8], [u8; LEDGER_RECORD_BYTES]>,
    pub batches: &'a BTreeMap<[u8; 6], [u8; BATCH_RECORD_BYTES]>,
}

/// The rewritten tables and the report.
#[derive(Debug, Clone)]
pub struct UpdateReport {
    pub print: PrintFile,
    pub ledger: BTreeMap<[u8; 8], [u8; LEDGER_RECORD_BYTES]>,
    pub batches: BTreeMap<[u8; 6], [u8; BATCH_RECORD_BYTES]>,
    /// Detail rows printed.
    pub rows: usize,
    /// Every record written to the spool, summary rows included.
    pub lines: usize,
}

impl UpdateReport {
    /// `close print-file` — the spool bytes.
    pub fn into_bytes(self) -> Vec<u8> {
        self.print.finish()
    }
}

/// `headings` — page mechanics and the batch lookup.
fn heading_line_1(context: &UpdateContext, page: usize) -> Record {
    let mut line = Record::spaces();
    line.put(1, context.prog_name.as_bytes());
    line.put(51, b"Transaction  Posting");
    line.put(114, b"Page ");
    line.put(119, edit_suppressed(page as u32, 2).as_bytes());
    line
}

fn heading_line_3(context: &UpdateContext, batch: u16, description: &[u8], date: &[u8]) -> Record {
    let mut line = Record::spaces();
    line.put(1, b"Cycle - ");
    line.put(9, edit_suppressed(u32::from(context.cycle), 2).as_bytes());
    line.put(11, b"          Batch - ");
    line.put(29, edit_suppressed(u32::from(batch), 5).as_bytes());
    line.put(44, b"General");
    line.put(56, description);
    line.put(111, date);
    line
}

fn heading_line_4() -> Record {
    let mut line = Record::spaces();
    line.put(
        1,
        b"Account   Br/P C    --Balance--   Trans  --Date--    ---Debit---    \
          ---Credit--       -------------Legend------------",
    );
    line
}

/// `line-5` — the column rules. The copybook's first filler is a 34-byte field
/// whose value is only seven dashes, so the second group starts at 35.
fn heading_line_5() -> Record {
    let mut line = Record::spaces();
    line.put(1, b"-------");
    line.put(35, b"-----");
    line
}

/// `line-7` — the eleven-byte rule under each money column.
fn rule_line() -> Record {
    let mut line = Record::spaces();
    line.put(55, b"===========");
    line.put(70, b"===========");
    line
}

/// The detail/summary row, positioned exactly as the copybook lays it out
/// (F-B072 Part 6). `account` is `(ledger-nos, ledger-pc)`.
struct Row<'a> {
    nos: &'a [u8],
    pc: &'a [u8],
    balance: Money,
    tran: &'a [u8],
    date: &'a [u8],
    debit: Money,
    credit: Money,
    legend: &'a [u8],
}

impl Row<'_> {
    fn render(&self) -> Record {
        let mut line = Record::spaces();
        line.put(1, edit_account(self.nos).as_bytes());
        line.put(14, edit_pc(self.pc).as_bytes());
        line.put(21, edit_balance(self.balance).as_bytes());
        line.put(34, edit_tran(self.tran).as_bytes());
        line.put(43, self.date);
        line.put(55, edit_unsigned_money(self.debit).as_bytes());
        line.put(70, edit_unsigned_money(self.credit).as_bytes());
        line.put(87, self.legend);
        line
    }
}

/// `zz070-Convert-Date` — `to-day` into the configured display form.
fn convert_date(day: &[u8; 10], date_form: u8) -> [u8; 10] {
    if date_form != 2 && date_form != 3 {
        return *day;
    }
    // The USA branch swaps days and month in place; the international branch
    // first moves the whole `"ccyy/mm/dd"` shape over the field. Either way the
    // separators end up at 3-based 4 and 7.
    let (days, month, year) = (&day[0..2], &day[3..5], &day[6..10]);
    let mut out = [b'/'; 10];
    out[2] = b'/';
    out[5] = b'/';
    match date_form {
        2 => {
            out[0..2].copy_from_slice(month);
            out[3..5].copy_from_slice(days);
            out[6..10].copy_from_slice(year);
        }
        _ => {
            out[0..4].copy_from_slice(year);
            out[5..7].copy_from_slice(month);
            out[8..10].copy_from_slice(days);
            out[4] = b'/';
            out[7] = b'/';
        }
    }
    out
}

/// Run `gl072` over `legs`.
pub fn update(context: &UpdateContext, input: UpdateInput<'_>) -> UpdateReport {
    let mut run = Run {
        context,
        print: PrintFile::new(),
        ledger: input.ledger.clone(),
        batches: input.batches.clone(),
        record: unread_ledger(),
        save_batch: 0,
        save_ledger: [0u8; 8],
        read_ledger: false,
        line_cnt: 0,
        page: 0,
        tot_dr: 0,
        tot_cr: 0,
        we_error: 0,
        rows: 0,
        lines: 0,
    };

    for record in input.legs {
        let Some(leg_key) = TransKey::parse(record) else {
            continue;
        };
        if leg_key.batch != run.save_batch && run.save_batch != 0 && run.we_error != 999 {
            run.end_account();
            run.end_batch();
            run.save_ledger = [0; 8];
            run.headings(leg_key.batch);
        }
        if run.save_batch == 0 {
            run.save_batch = leg_key.batch;
            run.headings(leg_key.batch);
        }
        if run.we_error == 999 {
            continue;
        }
        if leg_key.key != run.save_ledger && run.save_ledger != [0; 8] {
            run.end_account();
            run.new_account(&leg_key);
        }
        if run.save_ledger == [0; 8] {
            run.new_account(&leg_key);
        }
        run.save_ledger = leg_key.key;

        let date = &leg_key.date;
        let row = Row {
            nos: &leg_key.ac,
            pc: &leg_key.pc,
            // `new-account` leaves `l6-balance` at zero, so a detail row never
            // carries a balance — the column is blank on every posting line.
            balance: 0,
            tran: &leg_key.post,
            date,
            debit: if leg_key.amount > 0 { leg_key.amount } else { 0 },
            credit: if leg_key.amount > 0 { 0 } else { leg_key.amount },
            legend: &leg_key.legend,
        };
        let line = row.render();
        run.print.write_after(line.as_bytes(), 1);
        run.lines += 1;
        run.rows += 1;
        let value = unpack_packed(&run.record[LEDGER_BALANCE]).unwrap_or(0) + leg_key.amount;
        run.record[LEDGER_BALANCE].copy_from_slice(&pack_packed(value));
        if leg_key.amount > 0 {
            run.tot_dr = unsigned_add(run.tot_dr, leg_key.amount);
        } else {
            run.tot_cr = unsigned_add(run.tot_cr, leg_key.amount);
        }
        run.line_cnt += 1;
        if run.line_cnt > context.page_lines {
            run.end_account();
            run.headings(run.save_batch);
            run.read_ledger = true;
            run.new_account(&leg_key);
        }
    }

    run.end_account();
    run.end_batch();
    UpdateReport {
        print: run.print,
        ledger: run.ledger,
        batches: run.batches,
        rows: run.rows,
        lines: run.lines,
    }
}

/// An added value into an unsigned `9(8)v99`: the magnitude, capped at eight
/// integer digits.
fn unsigned_add(total: u64, delta: Money) -> u64 {
    (total + delta.unsigned_abs()).min(VALUE_MAX_CENTS - 1)
}

/// The parts of a leg the update uses, kept by reference into the raw record.
struct TransKey {
    batch: u16,
    post: [u8; 5],
    ac: [u8; 6],
    pc: [u8; 2],
    date: [u8; 8],
    amount: Money,
    legend: [u8; 32],
    key: [u8; 8],
}

impl TransKey {
    fn parse(record: &[u8; TRANS_RECORD_BYTES]) -> Option<Self> {
        let batch = decimal(&record[0..5])?;
        let mut ac = [0u8; 6];
        ac.copy_from_slice(&record[20..26]);
        let mut pc = [0u8; 2];
        pc.copy_from_slice(&record[26..28]);
        let mut key = [0u8; 8];
        key[..6].copy_from_slice(&ac);
        key[6..].copy_from_slice(&pc);
        let mut post = [0u8; 5];
        post.copy_from_slice(&record[5..10]);
        let mut date = [0u8; 8];
        date.copy_from_slice(&record[12..20]);
        let mut legend = [0u8; 32];
        legend.copy_from_slice(&record[38..70]);
        Some(Self {
            batch: batch as u16,
            post,
            ac,
            pc,
            date,
            amount: crate::records::unpack_overpunch(&record[28..38])?,
            legend,
            key,
        })
    }
}

/// The mutable walk state, one field per COBOL working-storage item.
struct Run<'a> {
    context: &'a UpdateContext,
    print: PrintFile,
    ledger: BTreeMap<[u8; 8], [u8; LEDGER_RECORD_BYTES]>,
    batches: BTreeMap<[u8; 6], [u8; BATCH_RECORD_BYTES]>,
    /// The current `ledger-record` area. Survives a failed read on purpose.
    record: [u8; LEDGER_RECORD_BYTES],
    save_batch: u16,
    save_ledger: [u8; 8],
    read_ledger: bool,
    line_cnt: usize,
    page: usize,
    tot_dr: u64,
    tot_cr: u64,
    we_error: u16,
    rows: usize,
    lines: usize,
}

impl Run<'_> {
    /// `get-batch` + the rest of `headings`.
    fn headings(&mut self, batch: u16) {
        let mut key = [b'0'; 6];
        key[0] = b'1';
        key[1..].copy_from_slice(&five_digits(batch));
        self.save_batch = batch;
        let record = self.batches.get(&key).copied();
        let mut description = [b' '; 24];
        if let Some(batch_record) = &record {
            description.copy_from_slice(&batch_record[BATCH_DESCRIPTION]);
        }
        let waiting = record.as_ref().is_some_and(|batch_record| {
            batch_record[BATCH_CLEARED] == b'0'
        });
        if waiting {
            self.we_error = 0;
        } else {
            self.we_error = 999;
            self.save_batch = 0;
        }
        if self.we_error == 999 {
            return;
        }

        let date = convert_date(&self.context.to_day, self.context.date_form);
        self.page += 1;
        let line_1 = heading_line_1(self.context, self.page);
        let line_3 = heading_line_3(self.context, batch, &description, &date);
        let line_4 = heading_line_4();
        let line_5 = heading_line_5();
        if self.page != 1 {
            self.print.write_page(line_1.as_bytes());
            self.print.write_after(line_3.as_bytes(), 1);
            let blank = Record::spaces();
            self.print.write_after(blank.as_bytes(), 1);
            self.lines += 3;
        } else {
            self.print.write_before(line_1.as_bytes(), 1);
            self.print.write_before(line_3.as_bytes(), 1);
            self.lines += 2;
        }
        self.print.write_after(line_4.as_bytes(), 1);
        self.print.write_after(line_5.as_bytes(), 1);
        self.lines += 2;
        self.line_cnt = 5;
    }

    /// `end-batch` — the batch is marked cleared and stamped with the run
    /// date.
    fn end_batch(&mut self) {
        if self.save_batch == 0 {
            return;
        }
        let mut key = [b'0'; 6];
        key[0] = b'1';
        key[1..].copy_from_slice(&five_digits(self.save_batch));
        if let Some(record) = self.batches.get_mut(&key) {
            record[BATCH_CLEARED] = b'1';
            record[BATCH_POSTED].copy_from_slice(&self.context.run_date.to_le_bytes());
        }
    }

    /// `end-account` — rewrite the record and print the account summary.
    fn end_account(&mut self) {
        let mut key = [0u8; 8];
        key.copy_from_slice(&self.record[..8]);
        if let Some(slot) = self.ledger.get_mut(&key) {
            *slot = self.record;
        }

        let rule = rule_line();
        self.print.write_after(rule.as_bytes(), 1);
        self.lines += 1;
        self.line_cnt += 1;

        let date = self.context.to_day;
        let tran = [b'0'; 5];
        let nos = self.record[LEDGER_NOS].to_vec();
        let pc = self.record[LEDGER_PC].to_vec();
        let name = self.record[LEDGER_NAME].to_vec();
        let row = Row {
            nos: &nos,
            pc: &pc,
            balance: unpack_packed(&self.record[LEDGER_BALANCE]).unwrap_or(0),
            tran: &tran,
            date: &date,
            debit: self.tot_dr as Money,
            credit: self.tot_cr as Money,
            legend: &name,
        };
        let line = row.render();
        self.print.write_after(line.as_bytes(), 1);
        self.lines += 1;
        self.print.write_after(rule.as_bytes(), 1);
        self.lines += 1;
        let blank_line = Record::spaces();
        self.print.write_after(blank_line.as_bytes(), 1);
        self.lines += 1;
        self.line_cnt += 3;
    }

    /// `new-account` — key the record, read it unless the page break asked for
    /// it, and print the brought-forward row.
    fn new_account(&mut self, leg: &TransKey) {
        self.record[..8].copy_from_slice(&leg.key);
        if !self.read_ledger {
            if let Some(record) = self.ledger.get(&leg.key).copied() {
                self.record = record;
            }
        }
        if !self.read_ledger {
            self.tot_dr = 0;
            self.tot_cr = 0;
        }

        let date = convert_date(&self.context.to_day, self.context.date_form);
        let tran = [b'0'; 5];
        let nos = self.record[LEDGER_NOS].to_vec();
        let pc = self.record[LEDGER_PC].to_vec();
        let mut row = Row {
            nos: &nos,
            pc: &pc,
            balance: unpack_packed(&self.record[LEDGER_BALANCE]).unwrap_or(0),
            tran: &tran,
            date: &date,
            debit: 0,
            credit: 0,
            legend: b"brought forward",
        };
        if !self.read_ledger {
            let balance = row.balance;
            if balance > 0 {
                row.debit = balance;
                self.tot_dr = unsigned_add(self.tot_dr, balance);
            } else {
                row.credit = balance;
                self.tot_cr = unsigned_add(self.tot_cr, balance);
            }
        }
        let line = row.render();
        self.print.write_after(line.as_bytes(), 2);
        self.lines += 1;
        self.line_cnt += 2;
        self.read_ledger = false;
    }
}

/// `run-date` as the `binary-long` day number the batch stamp takes: a
/// `dd/mm/ccyy` text date turned into ACAS's day integer (F-B001).
pub fn run_date_from(day: &[u8; 10]) -> i32 {
    if *day == [b' '; 10] {
        return 0;
    }
    let number = |bytes: &[u8]| -> i32 {
        bytes
            .iter()
            .fold(0i32, |acc, byte| acc * 10 + i32::from(byte.wrapping_sub(b'0')))
    };
    let (days, month, year) = (number(&day[0..2]), number(&day[3..5]), number(&day[6..10]));
    CobolDate::new(year, month as u32, days as u32).map(|date| date.0).unwrap_or(0)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::records::Trans;

    fn ledger_record(nos: &str, pc: &str, name: &str, balance: Money) -> [u8; LEDGER_RECORD_BYTES] {
        let mut record = [b' '; LEDGER_RECORD_BYTES];
        record[LEDGER_NOS].copy_from_slice(nos.as_bytes());
        record[LEDGER_PC].copy_from_slice(pc.as_bytes());
        record[8] = b'1';
        record[LEDGER_NAME].copy_from_slice(&[b' '; 24]);
        record[LEDGER_NAME][..name.len()].copy_from_slice(name.as_bytes());
        record[LEDGER_BALANCE].copy_from_slice(&pack_packed(balance));
        record
    }

    fn batch_record(number: u16, cleared: u8, description: &str) -> [u8; BATCH_RECORD_BYTES] {
        let mut record = [b' '; BATCH_RECORD_BYTES];
        record[0] = b'1';
        record[1..6].copy_from_slice(&five_digits(number));
        record[8] = b'1';
        record[9] = b'0' + cleared;
        record[10..12].copy_from_slice(b"12");
        record[BATCH_DESCRIPTION].copy_from_slice(&[b' '; 24]);
        record[BATCH_DESCRIPTION][..description.len()].copy_from_slice(description.as_bytes());
        record
    }

    fn leg(ac: &str, amount: Money, post: u16) -> [u8; TRANS_RECORD_BYTES] {
        Trans {
            batch: 1,
            post,
            code: *b"JD",
            date: *b"01/04/26",
            ac: ac.as_bytes().try_into().unwrap(),
            pc: *b"00",
            amount,
            legend: [b'L'; 32],
        }
        .to_bytes()
    }

    fn context(page_lines: usize) -> UpdateContext {
        UpdateContext {
            page_lines,
            cycle: 12,
            run_date: 155_535,
            to_day: *b"03/11/2026",
            date_form: 1,
            prog_name: "gl072 (3.00.04)".into(),
        }
    }

    type FixtureTables = (
        BTreeMap<[u8; 8], [u8; LEDGER_RECORD_BYTES]>,
        BTreeMap<[u8; 6], [u8; BATCH_RECORD_BYTES]>,
    );

    fn tables(ledger: &[(&str, &str, &str, Money)], batches: &[(u16, u8, &str)]) -> FixtureTables {
        let ledger = ledger
            .iter()
            .map(|(nos, pc, name, balance)| {
                let record = ledger_record(nos, pc, name, *balance);
                (record[..8].try_into().unwrap(), record)
            })
            .collect();
        let batches = batches
            .iter()
            .map(|(number, cleared, description)| {
                let record = batch_record(*number, *cleared, description);
                (record[..6].try_into().unwrap(), record)
            })
            .collect();
        (ledger, batches)
    }

    fn lines(report: &UpdateReport) -> Vec<String> {
        String::from_utf8_lossy(&report.print.clone().finish())
            .split('\n')
            .map(str::to_owned)
            .collect()
    }

    #[test]
    fn packed_round_trips_and_clamps() {
        for value in [0, 1, -1, 5_000, -5_000, 9_999_999_999] {
            assert_eq!(unpack_packed(&pack_packed(value)), Some(value));
        }
        assert_eq!(unpack_packed(&pack_packed(50_000_000_000)), Some(9_999_999_999));
        assert_eq!(unpack_packed(&pack_packed(-50_000_000_000)), Some(-9_999_999_999));
    }

    #[test]
    fn packed_rejects_a_bad_digit_or_sign() {
        assert_eq!(unpack_packed(&[0xff, 0, 0, 0, 0, 0x0c]), None);
        // GnuCOBOL reads any other low nibble as an unsigned sign.
        assert_eq!(unpack_packed(&[0, 0, 0, 0, 0, 0x0f]), Some(0));
        assert_eq!(unpack_packed(&[0, 0, 0]), None);
    }

    #[test]
    fn account_edit_is_the_number_over_one_hundred() {
        assert_eq!(edit_account(b"001234"), "0012.34");
        assert_eq!(edit_account(b"000001"), "0000.01");
        assert_eq!(edit_account(b"000000"), blank(7));
        assert_eq!(edit_account(&[0, 0, 0, 0, 0, 0]), blank(7));
    }

    #[test]
    fn pc_and_trans_edits_blank_on_zero_and_copy_low_values() {
        assert_eq!(edit_pc(b"00"), blank(2));
        assert_eq!(edit_pc(b"07"), "07");
        assert_eq!(edit_pc(&[0, 0]), "\0\0");
        assert_eq!(edit_tran(b"00000"), blank(5));
        assert_eq!(edit_tran(b"01234"), "   34");
    }

    #[test]
    fn balance_edits_right_align_and_mark_credit() {
        assert_eq!(edit_balance(0), blank(13));
        assert_eq!(edit_balance(1_500_000), "   15000.00  ");
        assert_eq!(edit_balance(-1_500_000), "   15000.00CR");
        assert_eq!(edit_unsigned_money(-1_500_000), "   15000.00");
    }

    #[test]
    fn dates_convert_by_form() {
        assert_eq!(convert_date(b"03/11/2026", 1), *b"03/11/2026");
        assert_eq!(convert_date(b"03/11/2026", 2), *b"11/03/2026");
        assert_eq!(convert_date(b"03/11/2026", 3), *b"2026/11/03");
        assert_eq!(convert_date(b"03/11/2026", 0), *b"03/11/2026");
    }

    #[test]
    fn unsigned_totals_keep_the_magnitude() {
        assert_eq!(unsigned_add(0, -2500), 2500);
        assert_eq!(unsigned_add(2500, 500), 3000);
    }

    #[test]
    fn a_missing_account_repeats_the_previous_record_area() {
        let (ledger, batches) = tables(
            &[("000010", "00", "PRESENT", 5_000)],
            &[(1, 0, "BATCH")],
        );
        // The second leg's account does not exist: `new-account` keeps the last
        // record's name and balance and the rewrite finds no key.
        let legs = [leg("000010", 1_000, 1), leg("000099", 1_000, 2)];
        let report = update(
            &context(48),
            UpdateInput { legs: &legs, ledger: &ledger, batches: &batches },
        );
        let text = lines(&report);
        let brought: Vec<&String> = text.iter().filter(|line| line.contains("brought forward")).collect();
        assert_eq!(brought.len(), 2);
        // The second one is keyed to the account that does not exist but still
        // carries the previous account's balance.
        assert!(brought[1].contains("0000.99"), "{}", brought[1]);
        assert!(brought[1].contains("60.00"), "{}", brought[1]);
        // The name survives only on the closing row, which rewrites nothing.
        assert!(text.iter().any(|line| line.contains("PRESENT")));
        assert!(!report.ledger.contains_key(b"00009900"));
    }

    #[test]
    fn a_processed_batch_prints_no_heading_and_skips_every_leg() {
        let (ledger, batches) = tables(
            &[("000010", "00", "PRESENT", 5_000)],
            &[(1, 1, "PROCESSED")],
        );
        let legs = [leg("000010", 1_000, 1)];
        let report = update(
            &context(48),
            UpdateInput { legs: &legs, ledger: &ledger, batches: &batches },
        );
        assert_eq!(report.rows, 0);
        let text = lines(&report);
        assert!(!text.iter().any(|line| line.contains("Transaction  Posting")));
        // Only the closing block survives; nothing was added to the balance.
        assert_eq!(report.ledger[b"00001000"][LEDGER_BALANCE], pack_packed(5_000));
    }

    #[test]
    fn the_page_check_runs_one_row_late() {
        // Two lines of page: the heading block takes five, so every detail row
        // overflows and the eject lands on the row that overflowed.
        let (ledger, batches) = tables(
            &[("000010", "00", "PRESENT", 0)],
            &[(1, 0, "BATCH")],
        );
        let legs = [leg("000010", 1_000, 1), leg("000010", 1_000, 2)];
        let report = update(
            &context(1),
            UpdateInput { legs: &legs, ledger: &ledger, batches: &batches },
        );
        let bytes = report.print.clone().finish();
        // Each eject appends 0x0c and a 132-byte line-1 to the previous record.
        assert_eq!(bytes.iter().filter(|byte| **byte == 0x0c).count(), 2);
        assert!(bytes.windows(15).any(|window| window.ends_with(b"Page  1")));
        assert!(bytes.windows(15).any(|window| window.ends_with(b"Page  2")));
    }

    #[test]
    fn closing_a_batch_stamps_it_cleared_and_posted() {
        let (ledger, batches) = tables(
            &[("000010", "00", "PRESENT", 0)],
            &[(1, 0, "BATCH")],
        );
        let legs = [leg("000010", 1_000, 1)];
        let report = update(
            &context(48),
            UpdateInput { legs: &legs, ledger: &ledger, batches: &batches },
        );
        let batch = &report.batches[b"100001"];
        assert_eq!(batch[9], b'1');
        assert_eq!(&batch[20..24], &155_535i32.to_le_bytes());
    }
}
