//! `sl070` — product analysis file: the records, `p-a-setup`, and `report1`.
//!
//! `sl070` is two different programs wearing one name. `p-a-setup` mints the
//! fixed table of analysis codes the rest of the ledger depends on, mirrors
//! each one into the value file, and is the only writer either file has on
//! this path. `report1` reads the analysis file back and prints it.
//!
//! Everything here is measured — see `docs/fd-evidence/F-B013-sl070-pa-report.md`
//! for the runs, the probe and the byte offsets, and `docs/disposition-pa.md`
//! for the field-by-field disposition of both records.
//!
//! Fossils reproduced on purpose:
//!
//! - the report heading sits one column to the left of the code and print
//!   columns it labels;
//! - a group row is followed by a wholly blank line;
//! - the warning that every `p-a-setup` code trips (`pa-gl = zero` on a
//!   detail) is printed for both report modes;
//! - `Date-Form = zero` is rewritten to `1` in the caller's system record.
//!
//! The caller owns storage: this module never opens a file.

use crate::report::{edit_suppressed, PrintFile, Record};

/// `01 analysis-record` — 36 bytes, key `pa-code` (3).
pub const ANALYSIS_RECORD_BYTES: usize = 36;
/// `01 value-record` — 66 bytes, key `va-code` (3).
pub const VALUE_RECORD_BYTES: usize = 66;
/// Width of `print-record`.
const RECORD: usize = crate::report::PRINT_RECORD;

/// `s9(8)v99 comp-3` — ten digits and a sign nibble in six bytes.
///
/// Raw bytes are authoritative; `cents` is the arithmetic view. As with
/// `PackedMoney`, an unrecognised sign nibble survives verbatim.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct PackedValue([u8; 6]);

/// Magnitude cap of `s9(8)v99`, in hundredths.
pub const PACKED_VALUE_MAX_CENTS: i64 = 9_999_999_999;

impl PackedValue {
    /// `move zero to va-v-*` — packed zero is `0x00*5 0x0C`.
    pub const ZERO: Self = Self([0, 0, 0, 0, 0, 0x0C]);

    pub const fn from_raw(raw: [u8; 6]) -> Self {
        Self(raw)
    }

    pub const fn raw(&self) -> [u8; 6] {
        self.0
    }

    /// Value in hundredths; `D`/`B` in the sign nibble is negative.
    pub fn cents(&self) -> i64 {
        let mut magnitude = 0i64;
        for byte in &self.0[..5] {
            magnitude = magnitude * 100 + i64::from(byte >> 4) * 10 + i64::from(byte & 0x0F);
        }
        if matches!(self.0[5] & 0x0F, 0x0D | 0x0B) {
            -magnitude
        } else {
            magnitude
        }
    }

    pub fn from_cents(cents: i64) -> Option<Self> {
        if cents.unsigned_abs() > PACKED_VALUE_MAX_CENTS as u64 {
            return None;
        }
        let negative = cents < 0;
        let mut magnitude = cents.unsigned_abs();
        let mut digits = [0u8; 10];
        for slot in digits.iter_mut().rev() {
            *slot = (magnitude % 10) as u8;
            magnitude /= 10;
        }
        let mut raw = [0u8; 6];
        for index in 0..5 {
            raw[index] = (digits[index * 2] << 4) | digits[index * 2 + 1];
        }
        raw[5] = if negative { 0x0D } else { 0x0C };
        Some(Self(raw))
    }
}

/// `01 analysis-record` (`fdanal.cob`) — the function is keyed by `pa-code`,
/// `pa-system` followed by `pa-group`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct AnalysisCode {
    bytes: [u8; ANALYSIS_RECORD_BYTES],
}

impl AnalysisCode {
    /// Build a record; `desc` is clipped or padded to its 24 bytes the way a
    /// `move` would, and `gl` must be six display digits.
    pub fn new(system: u8, group: [u8; 2], gl: [u8; 6], desc: &[u8], print_ref: [u8; 3]) -> Self {
        let mut record = Self {
            bytes: [b' '; ANALYSIS_RECORD_BYTES],
        };
        record.bytes[0] = system;
        record.bytes[1..3].copy_from_slice(&group);
        record.bytes[3..9].copy_from_slice(&gl);
        for (slot, byte) in record.bytes[9..33].iter_mut().zip(desc) {
            *slot = *byte;
        }
        record.bytes[33..36].copy_from_slice(&print_ref);
        record
    }

    pub const fn from_raw(bytes: [u8; ANALYSIS_RECORD_BYTES]) -> Self {
        Self { bytes }
    }

    pub const fn raw(&self) -> [u8; ANALYSIS_RECORD_BYTES] {
        self.bytes
    }

    /// `pa-code` — the record key.
    pub fn code(&self) -> [u8; 3] {
        [self.bytes[0], self.bytes[1], self.bytes[2]]
    }

    /// `pa-system`.
    pub fn system(&self) -> u8 {
        self.bytes[0]
    }

    /// `pa-group`.
    pub fn group(&self) -> [u8; 2] {
        [self.bytes[1], self.bytes[2]]
    }

    /// `pa-gl` as a number. Blank digits read as `0`.
    pub fn gl(&self) -> u32 {
        self.bytes[3..9].iter().fold(0u32, |value, byte| {
            value * 10 + u32::from(byte.wrapping_sub(b'0').min(9))
        })
    }

    /// `pa-desc`.
    pub fn desc(&self) -> &[u8] {
        &self.bytes[9..33]
    }

    /// `pa-print`.
    pub fn print_ref(&self) -> &[u8] {
        &self.bytes[33..36]
    }

    /// `pa-second = space and pa-gl = zero` — the group-row test.
    pub fn is_group(&self) -> bool {
        self.bytes[2] == b' ' && self.gl() == 0
    }
}

/// `01 value-record` (`fdval.cob`) — the counters and money the sales and
/// purchase postings accumulate against an analysis code.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct ValueRecord {
    bytes: [u8; VALUE_RECORD_BYTES],
}

impl ValueRecord {
    /// `create-value`: copy the analysis record over the value record, keep
    /// whatever the three `va-t-*` counters already held (`carried`), and zero
    /// the three packed money fields.
    ///
    /// The counters are *not* cleared by the COBOL — they are zero in practice
    /// only because the working-storage record is fresh (F-B013 Part 2).
    pub fn mint(code: &AnalysisCode, carried: Option<&Self>) -> Self {
        let mut record = Self {
            bytes: [0; VALUE_RECORD_BYTES],
        };
        record.bytes[..ANALYSIS_RECORD_BYTES].copy_from_slice(&code.raw());
        if let Some(previous) = carried {
            record.bytes[36..48].copy_from_slice(&previous.bytes[36..48]);
        }
        for index in 0..3 {
            record.bytes[48 + index * 6..54 + index * 6]
                .copy_from_slice(&PackedValue::ZERO.raw());
        }
        record
    }

    pub const fn from_raw(bytes: [u8; VALUE_RECORD_BYTES]) -> Self {
        Self { bytes }
    }

    pub const fn raw(&self) -> [u8; VALUE_RECORD_BYTES] {
        self.bytes
    }

    pub fn code(&self) -> [u8; 3] {
        [self.bytes[0], self.bytes[1], self.bytes[2]]
    }

    pub fn gl(&self) -> &[u8] {
        &self.bytes[3..9]
    }

    pub fn desc(&self) -> &[u8] {
        &self.bytes[9..33]
    }

    pub fn print_ref(&self) -> &[u8] {
        &self.bytes[33..36]
    }

    /// One of `va-t-this` / `va-t-last` / `va-t-year` (`pic 9(5) comp`,
    /// binary-long, big-endian).
    pub fn counter(&self, which: Counter) -> u32 {
        let offset = 36 + which as usize * 4;
        u32::from_be_bytes(self.bytes[offset..offset + 4].try_into().expect("4 bytes"))
    }

    /// One of `va-v-this` / `va-v-last` / `va-v-year`.
    pub fn money(&self, which: Counter) -> PackedValue {
        let offset = 48 + which as usize * 6;
        PackedValue::from_raw(self.bytes[offset..offset + 6].try_into().expect("6 bytes"))
    }
}

/// Which of the three period slots a counter or money field refers to.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Counter {
    This,
    Last,
    Year,
}

/// The two tables `p-a-setup` pulls out of `init01`.
#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct Setup {
    /// Rows to write to `analysis-file`, in p-a-setup order.
    pub analysis: Vec<AnalysisCode>,
    /// Rows to write to `value-file`. A code already present keeps its record.
    pub value: Vec<ValueRecord>,
}

/// The sixteen codes `p-a-setup` writes, in order (F-B013 Part 2).
///
/// Descriptions are written long and clipped by [`AnalysisCode::new`].
const STANDARD_CODES: [(u8, [u8; 2], &str, [u8; 3]); 16] = [
    (b'S', *b"v ", "VAT Control", *b"   "),
    (b'P', *b"v ", "VAT Control", *b"   "),
    (b'P', *b"vi", "VAT Input Invoices/CN's", *b"   "),
    (b'P', *b"vj", "VAT Input Receipts", *b"   "),
    (b'S', *b"z ", "Computer Control", *b"   "),
    (b'P', *b"z ", "Computer Control", *b"   "),
    (b'P', *b"za", "Purchase Carriage Charges", *b"P&P"),
    (b'P', *b"zb", "Purchase Late Charges", *b"LCG"),
    (b'S', *b"zc", "Sales Carriage Charges", *b"P&P"),
    (b'S', *b"zd", "Sales Late Charges", *b"LCG"),
    (b'S', *b"vo", "VAT Output Invoices/CN's", *b"   "),
    (b'S', *b"vp", "VAT Output Receipts", *b"   "),
    (b'P', *b"a ", "Default Group", *b"   "),
    (b'P', *b"a1", "Default Purchases", *b"   "),
    (b'S', *b"a ", "Default Group", *b"   "),
    (b'S', *b"a1", "Default Sales", *b"   "),
];

/// `p-a-setup`.
///
/// `existing_values` is the value file as the caller holds it: a code whose
/// value record already exists is not rewritten (`create-value`'s
/// `invalid key` guard). The analysis file is truncated by the COBOL and the
/// caller is expected to replace it with [`Setup::analysis`].
pub fn setup(existing_values: &[ValueRecord]) -> Setup {
    let mut setup = Setup::default();
    for (system, group, desc, print_ref) in STANDARD_CODES {
        let code = AnalysisCode::new(system, group, *b"000000", desc.as_bytes(), print_ref);
        let carried = existing_values
            .iter()
            .find(|row| row.code() == code.code() && row.gl() == *b"000000");
        if carried.is_none() {
            setup.value.push(ValueRecord::mint(&code, None));
        }
        setup.analysis.push(code);
    }
    setup
}

/// Everything `report1` reads that is not the analysis file itself.
#[derive(Debug, Clone)]
pub struct ReportInputs<'a> {
    /// Analysis rows in **key order** — the caller owns the sequential read.
    pub rows: &'a [AnalysisCode],
    /// `usera` (32 bytes in the system record, clipped to 30 by the move).
    pub user: &'a [u8],
    /// `to-day`, `dd/mm/yyyy`.
    pub today: &'a [u8],
    /// `Date-Form` — `1` UK, `2` USA, `3` international; `0` is rewritten.
    pub date_form: u8,
    /// Menu 4 (`print all`) rather than menu 3 (`S` ledger only).
    pub print_all: bool,
    /// `Irs-Used` — print `pa-gl` whole instead of dividing it by 100.
    pub irs_used: bool,
    /// `prog-name`, for `l1-version`.
    pub version: &'a [u8],
}

/// What `report1` produced.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReportOutcome {
    /// The `prt-1` spool stream, exactly as the COBOL writes it.
    pub spool: Vec<u8>,
    /// `Date-Form` after the report — `0` comes back as `1`.
    pub date_form: u8,
    /// `ws-err-flag`: a detail row was found with no GL number.
    pub warning: bool,
}

const HEADING_TEXT: &[u8] = b"Code    Gl.Nos.      <-----Description------>   Print";
const TYPE_HEADING: &[u8] = b"-Type-";
const WARNING_TEXT: &[u8] =
    b"Warning: One or more P.A. codes contain a zero value for General Ledger numbers";
const PAGE_BREAK_AFTER: usize = 70;

/// `zz070-Convert-Date`. Returns the date in the configured form and the
/// `Date-Form` to write back (a zero becomes one).
pub fn convert_date(today: &[u8], date_form: u8) -> (Vec<u8>, u8) {
    let date_form = if date_form == 0 { 1 } else { date_form };
    let mut date = today.to_vec();
    match date_form {
        1 => {}
        2 => {
            if date.len() >= 5 {
                date.swap(0, 3);
                date.swap(1, 4);
            }
        }
        _ => {
            // International: `move "ccyy/mm/dd"` then fill year, month, days.
            let year = today.get(6..10).unwrap_or(b"    ");
            let month = today.get(3..5).unwrap_or(b"  ");
            let days = today.get(..2).unwrap_or(b"  ");
            date.clear();
            date.extend_from_slice(year);
            date.push(b'/');
            date.extend_from_slice(month);
            date.push(b'/');
            date.extend_from_slice(days);
        }
    }
    (date, date_form)
}

struct Lines {
    one: Record,
    two: Record,
    four: Record,
    six: Record,
}

impl Lines {
    fn new() -> Self {
        Self {
            one: Record::spaces(),
            two: Record::spaces(),
            four: Record::spaces(),
            six: Record::spaces(),
        }
    }
}

/// `report1`.
///
/// The caller is the menu: pass `print_all` for menu 4 and leave it false for
/// menu 3. Nothing here opens a file — [`ReportOutcome::spool`] is the bytes
/// `prt-1` would have received.
pub fn report(inputs: &ReportInputs<'_>) -> ReportOutcome {
    let mut spool = PrintFile::new();
    let mut lines = Lines::new();
    lines.four.put(1, if inputs.print_all { b"Lgr" } else { b"    " });
    lines.four.put(5, HEADING_TEXT);
    lines.four.put(64, TYPE_HEADING);
    lines.one.put(1, inputs.version);
    lines.one.put(34, b"Product Analysis Codes");
    lines.one.put(73, b"Page ");

    let (date, date_form) = convert_date(inputs.today, inputs.date_form);
    lines.two.put(1, &inputs.user[..inputs.user.len().min(30)]);
    lines.two.put(71, &date);

    let mut page: u32 = 0;
    let mut line_cnt: usize = 0;
    let mut warning = false;

    let headings = |spool: &mut PrintFile, lines: &mut Lines, page: &mut u32, line_cnt: &mut usize| {
        *page += 1;
        lines.one.put(78, edit_suppressed(*page, 3).as_bytes());
        if *page == 1 {
            spool.write_before(lines.one.as_bytes(), 1);
        } else {
            spool.write_page(lines.one.as_bytes());
            spool.write_after(&[b' '; RECORD], 1);
        }
        spool.write_after(lines.two.as_bytes(), 1);
        spool.write_after(lines.four.as_bytes(), 2);
        *line_cnt = 5;
    };

    headings(&mut spool, &mut lines, &mut page, &mut line_cnt);

    for row in inputs.rows {
        if row.system() != b'S' && !inputs.print_all {
            continue;
        }
        if row.is_group() {
            spool.write_after(&[b' '; RECORD], 1);
            line_cnt += 1;
            lines.six.put(64, b"Group ");
            let ledger = [row.system()];
            lines.six.put(2, if inputs.print_all { &ledger } else { b" " });
        } else {
            lines.six.put(64, b"Detail");
            lines.six.put(2, b" ");
        }
        if line_cnt > PAGE_BREAK_AFTER {
            headings(&mut spool, &mut lines, &mut page, &mut line_cnt);
        }
        if !row.is_group() && row.gl() == 0 {
            warning = true;
        }
        let group = row.group();
        lines.six.put(6, &[group[0], group[1], b' ', b' ', b' ', b' ', b' ']);
        let gl = if inputs.irs_used { row.gl() } else { row.gl() / 100 };
        let gl = if gl == 0 { b"      ".to_vec() } else { format!("{gl:06}").into_bytes() };
        lines.six.put(13, &gl);
        lines.six.put(26, row.desc());
        lines.six.put(54, row.print_ref());
        spool.write_after(lines.six.as_bytes(), 1);
        line_cnt += 1;
        if line_cnt > PAGE_BREAK_AFTER {
            headings(&mut spool, &mut lines, &mut page, &mut line_cnt);
        }
    }

    if warning {
        let mut record = Record::spaces();
        record.put(1, WARNING_TEXT);
        spool.write_after(record.as_bytes(), 2);
    }

    ReportOutcome {
        spool: spool.finish(),
        date_form,
        warning,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn code(system: u8, group: [u8; 2], gl: [u8; 6], desc: &str) -> AnalysisCode {
        AnalysisCode::new(system, group, gl, desc.as_bytes(), *b"   ")
    }

    fn report_of(rows: &[AnalysisCode], print_all: bool, irs_used: bool) -> ReportOutcome {
        report(&ReportInputs {
            rows,
            user: b"Harness Test Co",
            today: b"03/11/2026",
            date_form: 1,
            print_all,
            irs_used,
            version: b"SL070 (3.01.11)",
        })
    }

    fn lines(spool: &[u8]) -> Vec<String> {
        String::from_utf8_lossy(spool)
            .split('\n')
            .map(str::to_string)
            .collect()
    }

    #[test]
    fn setup_writes_the_sixteen_standard_codes_in_order() {
        let setup = setup(&[]);
        assert_eq!(setup.analysis.len(), 16);
        assert_eq!(setup.value.len(), 16);
        let codes: Vec<[u8; 3]> = setup.analysis.iter().map(AnalysisCode::code).collect();
        assert_eq!(&codes[..3], &[*b"Sv ", *b"Pv ", *b"Pvi"]);
        assert_eq!(codes[15], *b"Sa1");
    }

    #[test]
    fn descriptions_are_clipped_to_the_field_and_print_codes_survive() {
        let setup = setup(&[]);
        let carriage = setup
            .analysis
            .iter()
            .find(|row| row.code() == *b"Pza")
            .expect("Pza is a standard code");
        assert_eq!(carriage.desc(), b"Purchase Carriage Charge");
        assert_eq!(carriage.print_ref(), b"P&P");
    }

    #[test]
    fn a_code_that_already_has_a_value_record_is_not_rewritten() {
        let first = setup(&[]);
        let again = setup(&first.value);
        assert!(again.value.is_empty());
        assert_eq!(again.analysis.len(), 16, "the analysis file is rebuilt");
    }

    #[test]
    fn minting_keeps_carried_counters_and_zeroes_the_money() {
        let code = code(b'S', *b"v ", *b"000000", "VAT Control");
        let mut carried = ValueRecord::mint(&code, None);
        let mut raw = carried.raw();
        raw[36..40].copy_from_slice(&7u32.to_be_bytes());
        raw[48] = 0x12;
        carried = ValueRecord::from_raw(raw);

        let minted = ValueRecord::mint(&code, Some(&carried));
        assert_eq!(minted.counter(Counter::This), 7);
        assert_eq!(minted.money(Counter::This), PackedValue::ZERO);
        assert_eq!(minted.code(), *b"Sv ");
    }

    #[test]
    fn packed_value_round_trips_and_keeps_unknown_sign_nibbles() {
        let value = PackedValue::from_cents(-123_456).expect("in range");
        assert_eq!(value.cents(), -123_456);
        assert_eq!(PackedValue::from_raw([0, 0, 0, 0, 0, 0x0F]).cents(), 0);
        assert!(PackedValue::from_cents(PACKED_VALUE_MAX_CENTS + 1).is_none());
    }

    #[test]
    fn the_group_test_needs_a_blank_second_byte_and_a_zero_gl() {
        assert!(code(b'S', *b"v ", *b"000000", "").is_group());
        assert!(!code(b'S', *b"vi", *b"000000", "").is_group());
        assert!(!code(b'S', *b"v ", *b"000001", "").is_group());
    }

    #[test]
    fn the_sales_report_skips_the_purchase_ledger() {
        let rows = [
            code(b'P', *b"a1", *b"000000", "Default Purchases"),
            code(b'S', *b"a1", *b"000000", "Default Sales"),
        ];
        let spool = report_of(&rows, false, false).spool;
        let text = String::from_utf8_lossy(&spool);
        assert!(text.contains("Default Sales"));
        assert!(!text.contains("Default Purchases"));

        let spool = report_of(&rows, true, false).spool;
        assert!(String::from_utf8_lossy(&spool).contains("Default Purchases"));
    }

    #[test]
    fn a_group_row_in_print_all_mode_carries_its_ledger_letter() {
        let rows = [code(b'P', *b"z ", *b"000000", "Computer Control")];
        let spool = report_of(&rows, true, false).spool;
        let row = lines(&spool)
            .into_iter()
            .find(|line| line.contains("Computer Control"))
            .expect("the group row is printed");
        assert_eq!(row.as_bytes()[1], b'P');
        assert!(row.starts_with(" P   z "));
    }

    #[test]
    fn gl_numbers_are_divided_by_a_hundred_unless_irs_is_used() {
        let rows = [code(b'S', *b"x1", *b"012345", "Divided")];
        let spool = String::from_utf8_lossy(&report_of(&rows, false, false).spool).to_string();
        let row = spool
            .lines()
            .find(|line| line.contains("Divided"))
            .expect("row printed");
        assert_eq!(&row[12..18], "000123");

        let spool = String::from_utf8_lossy(&report_of(&rows, false, true).spool).to_string();
        let row = spool.lines().find(|line| line.contains("Divided")).unwrap();
        assert_eq!(&row[12..18], "012345");
    }

    #[test]
    fn a_zero_gl_number_prints_blank_and_raises_the_warning() {
        let rows = [code(b'S', *b"x1", *b"000000", "No GL")];
        let outcome = report_of(&rows, false, false);
        assert!(outcome.warning);
        let spool = String::from_utf8_lossy(&outcome.spool).to_string();
        let row = spool.lines().find(|line| line.contains("No GL")).unwrap();
        assert_eq!(&row[12..18], "      ");
        assert!(spool.contains("Warning: One or more P.A. codes contain a zero value"));
        assert!(spool.ends_with('\n'), "the file is closed with a newline");
    }

    #[test]
    fn a_group_row_with_no_gl_number_does_not_raise_the_warning() {
        let rows = [code(b'S', *b"z ", *b"000000", "Computer Control")];
        assert!(!report_of(&rows, false, false).warning);
    }

    #[test]
    fn dates_follow_the_system_date_form_and_a_zero_is_rewritten() {
        assert_eq!(convert_date(b"03/11/2026", 1).0, b"03/11/2026");
        assert_eq!(convert_date(b"03/11/2026", 2).0, b"11/03/2026");
        assert_eq!(convert_date(b"03/11/2026", 3).0, b"2026/11/03");
        let (date, form) = convert_date(b"03/11/2026", 0);
        assert_eq!(form, 1);
        assert_eq!(date, b"03/11/2026");
    }

    #[test]
    fn the_page_number_is_zero_suppressed_and_starts_at_one() {
        let spool = String::from_utf8_lossy(&report_of(&[], false, false).spool).to_string();
        let heading = spool.lines().next().expect("heading");
        assert_eq!(&heading[72..80], "Page   1");
    }

    #[test]
    fn seventy_one_rows_eject_the_page_and_repeat_the_heading() {
        let rows: Vec<AnalysisCode> = (0..80u8)
            .map(|index| code(b'S', [b'x', b'0' + index % 10], *b"000000", "Row"))
            .collect();
        let spool = report_of(&rows, false, false).spool;
        assert_eq!(spool.iter().filter(|byte| **byte == 0x0C).count(), 1);
        let text = String::from_utf8_lossy(&spool);
        assert!(text.contains("Page   2"));
        // The eject is appended to the previous line, so page 2 continues it.
        assert!(text.lines().any(|line| line.len() == 265), "eject joins the heading");
    }

    #[test]
    fn an_empty_file_still_prints_the_heading() {
        let outcome = report_of(&[], false, false);
        assert!(!outcome.warning);
        let spool = String::from_utf8_lossy(&outcome.spool);
        assert!(spool.starts_with("SL070 (3.01.11)"));
        assert!(!spool.contains("Warning"));
    }
}
