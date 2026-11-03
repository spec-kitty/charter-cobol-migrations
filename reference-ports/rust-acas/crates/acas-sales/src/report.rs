//! The print-file half of a COBOL report program.
//!
//! Every ACAS report writes 132-byte lines to `print-file`, which is
//! `selprint.cob`'s `assign "prt-1"` — a line-sequential spool file the shell
//! then hands to `lpr`. The report text *is* the artifact: the parity
//! scenarios hash `prt-1` and nothing else, so the line mechanics have to be
//! reproduced exactly, not approximated as a `Vec<String>`.
//!
//! Measured behaviour (probe source and bytes in
//! `docs/fd-evidence/F-B012-sl170-file-dump.md`, Part 1):
//!
//! - `WRITE ... AFTER ADVANCING n` emits `n - 1` empty lines, then the record.
//! - `WRITE ... BEFORE ADVANCING 1` writes the record first, then the newline.
//! - `WRITE ... AFTER ADVANCING PAGE` appends a form feed (0x0C) to the *end of
//!   the previous line* and puts the record on that same line. The resulting
//!   line is therefore 133..265 bytes long, which is why the spool file has
//!   variable-length lines even though every record is 132 wide.
//! - Every record is exactly 132 bytes; a longer sending item is truncated
//!   (that is how `sl170`'s third column loses all but its first byte).
//!
//! None of this is a COBOL requirement — it is what GnuCOBOL 3.1.2 does with a
//! line-sequential file, and the COBOL side is the oracle.

/// Width of one spool record: `01 print-record pic x(132)`.
pub const PRINT_RECORD: usize = 132;

/// A line-sequential spool file being built up in memory.
///
/// The stream is written exactly as the measured runtime writes it:
///
/// - `write_after(record, n)` emits `n` newlines, then the record;
/// - `write_before(record, n)` emits the record, then `n` newlines;
/// - `write_page(record)` emits a form feed and the record with no newline in
///   between, so the record continues the previous line;
/// - the file is closed with a newline if it does not already end in one.
#[derive(Debug, Default, Clone)]
pub struct PrintFile {
    bytes: Vec<u8>,
}

impl PrintFile {
    pub fn new() -> Self {
        Self::default()
    }

    /// `write print-record ... after advancing n lines`.
    pub fn write_after(&mut self, record: &[u8], advance: usize) {
        self.bytes.resize(self.bytes.len() + advance, b'\n');
        self.bytes.extend_from_slice(record);
    }

    /// `write print-record ... before advancing n lines`.
    pub fn write_before(&mut self, record: &[u8], advance: usize) {
        self.bytes.extend_from_slice(record);
        self.bytes.resize(self.bytes.len() + advance, b'\n');
    }

    /// `write print-record ... after advancing page`.
    pub fn write_page(&mut self, record: &[u8]) {
        self.bytes.push(0x0C);
        self.bytes.extend_from_slice(record);
    }

    pub fn len(&self) -> usize {
        self.bytes.len()
    }

    pub fn is_empty(&self) -> bool {
        self.bytes.is_empty()
    }

    /// `close print-file`.
    pub fn finish(mut self) -> Vec<u8> {
        if self.bytes.last().is_some_and(|byte| *byte != b'\n') {
            self.bytes.push(b'\n');
        }
        self.bytes
    }
}

/// A 132-byte record under construction.
///
/// `put` takes the 1-based character position COBOL uses in `line-4 (1:14)`
/// style references, so the layout constants below read like the copybook.
#[derive(Debug, Clone)]
pub struct Record {
    bytes: [u8; PRINT_RECORD],
}

impl Default for Record {
    fn default() -> Self {
        Self::spaces()
    }
}

impl Record {
    pub fn spaces() -> Self {
        Self {
            bytes: [b' '; PRINT_RECORD],
        }
    }

    /// Place `value` at 1-based `position`, clipping at the record end.
    pub fn put(&mut self, position: usize, value: &[u8]) {
        let start = position.saturating_sub(1);
        for (offset, byte) in value.iter().enumerate() {
            match self.bytes.get_mut(start + offset) {
                Some(slot) => *slot = *byte,
                None => break,
            }
        }
    }

    pub fn as_bytes(&self) -> &[u8; PRINT_RECORD] {
        &self.bytes
    }

    pub fn as_bytes_mut(&mut self) -> &mut [u8; PRINT_RECORD] {
        &mut self.bytes
    }
}

/// `pic z(7)9.99cr` — the twelve-digit edited money field ACAS prints.
///
/// Zero suppression turns leading zeros into spaces, but the digit position
/// immediately left of the decimal point is not suppressed and always prints
/// (`0.00`, not `.00`). A negative value gets a `CR` suffix.
const EDIT_INT_POSITIONS: usize = 8;

/// Edit a non-negative digit string with an explicit source scale.
///
/// `digits` carries no sign and no point; `scale` is the number of its
/// trailing digits that are already decimals (`0` for `pic 99`, `2` for
/// `pic 99v99`). The result is always [`EDIT_INT_POSITIONS`] + `.` + 2 + 2
/// bytes: 13, the width of `l4-value-2`.
pub fn edit_money(digits: &str, scale: usize) -> String {
    let digits: Vec<char> = digits.chars().filter(char::is_ascii_digit).collect();
    let (whole, fraction): (String, String) = if scale == 0 {
        (digits.iter().collect(), String::new())
    } else if digits.len() <= scale {
        (String::new(), format!("{:0>width$}", digits.iter().collect::<String>(), width = scale))
    } else {
        let split = digits.len() - scale;
        (digits[..split].iter().collect(), digits[split..].iter().collect())
    };

    let whole = if whole.is_empty() { "0".to_string() } else { whole };
    let whole: String = whole
        .chars()
        .rev()
        .take(EDIT_INT_POSITIONS)
        .collect::<Vec<_>>()
        .into_iter()
        .rev()
        .collect();

    let mut rendered = String::with_capacity(EDIT_INT_POSITIONS + 5);
    let padding = EDIT_INT_POSITIONS - whole.chars().count();
    let mandatory_at = EDIT_INT_POSITIONS - 1;
    let mut seen_non_zero = false;
    for index in 0..EDIT_INT_POSITIONS {
        if index < padding {
            rendered.push(' ');
            continue;
        }
        let ch = whole.chars().nth(index - padding).unwrap_or('0');
        let suppress = ch == '0' && !seen_non_zero && index < mandatory_at;
        if !suppress {
            seen_non_zero = true;
        }
        rendered.push(if suppress { ' ' } else { ch });
    }
    rendered.push('.');
    rendered.push_str(&format!("{:0>2}", &fraction[..fraction.len().min(2)]));
    rendered
}

/// `pic z(7)9.99cr` fed by a display field that may hold spaces.
///
/// `move sales-credit to l4-value-2` sends a `pic 99` that an old record can
/// leave blank. GnuCOBOL does not turn those spaces into zeros: each blank
/// source digit prints blank, while zero suppression still blanks leading
/// zeros and the decimal part keeps its two zeros (`"  .00"`, not `"0.00"`).
pub fn edit_blankable_money(digits: &[u8]) -> String {
    let source: Vec<char> = digits.iter().map(|byte| char::from(*byte)).collect();
    let padding = EDIT_INT_POSITIONS.saturating_sub(source.len());
    let mandatory_at = EDIT_INT_POSITIONS - 1;
    let mut seen_non_zero = false;
    let mut rendered = String::with_capacity(EDIT_INT_POSITIONS + 3);
    for index in 0..EDIT_INT_POSITIONS {
        if index < padding {
            rendered.push(' ');
            continue;
        }
        match *source.get(index - padding).unwrap_or(&' ') {
            ' ' => rendered.push(' '),
            '0' => {
                let suppress = !seen_non_zero && index < mandatory_at;
                if suppress {
                    rendered.push(' ');
                } else {
                    seen_non_zero = true;
                    rendered.push('0');
                }
            }
            other => {
                seen_non_zero = true;
                rendered.push(other);
            }
        }
    }
    rendered.push_str(".00");
    rendered
}

/// `pic z(7)9.99cr` from a signed value with a source scale.
///
/// `scale` is the number of source digits that are already decimals, exactly
/// as for [`edit_money`]; the printed field always carries two.
pub fn edit_number(value: i64, scale: usize) -> String {
    let mut rendered = edit_money(&value.unsigned_abs().to_string(), scale);
    if value < 0 {
        rendered.push_str("CR");
    } else {
        rendered.push_str("  ");
    }
    rendered
}

/// `pic z(7)9.99cr` from signed hundredths.
pub fn edit_money_cr(cents: i64) -> String {
    edit_number(cents, 2)
}

/// `pic z9` / `pic zzzz9` — zero-suppressed unsigned, width from the caller.
///
/// The final position is a plain `9`: it prints even when everything before it
/// is suppressed, so a zero heading operand renders as `" 0"`, not `"  "`.
pub fn edit_suppressed(value: u32, width: usize) -> String {
    let digits = value.to_string();
    let digits: String = digits
        .chars()
        .rev()
        .take(width)
        .collect::<Vec<_>>()
        .into_iter()
        .rev()
        .collect();
    let padding = width - digits.chars().count();
    let mandatory_at = width - 1;
    let mut rendered = String::with_capacity(width);
    let mut seen_non_zero = false;
    for index in 0..width {
        if index < padding {
            rendered.push(' ');
            continue;
        }
        let ch = digits.chars().nth(index - padding).unwrap_or('0');
        let suppress = ch == '0' && !seen_non_zero && index < mandatory_at;
        if !suppress {
            seen_non_zero = true;
        }
        rendered.push(if suppress { ' ' } else { ch });
    }
    rendered
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn after_n_advances_n_lines_then_writes() {
        let mut file = PrintFile::new();
        file.write_before(b"first", 1);
        file.write_after(b"second", 2);
        assert_eq!(
            String::from_utf8(file.finish()).unwrap(),
            "first\n\n\nsecond\n"
        );
    }

    #[test]
    fn page_eject_joins_the_previous_line() {
        let mut file = PrintFile::new();
        file.write_after(b"before", 1);
        file.write_page(b"after");
        assert_eq!(
            String::from_utf8(file.finish()).unwrap(),
            "\nbefore\u{c}after\n"
        );
    }

    #[test]
    fn close_appends_exactly_one_newline() {
        let mut file = PrintFile::new();
        file.write_before(b"record", 0);
        assert_eq!(String::from_utf8(file.finish()).unwrap(), "record\n");
    }

    #[test]
    fn a_blank_digit_prints_blank_from_the_blankable_editor() {
        // `  ` — an untouched `pic 99`: blank integer part, zeros after the
        // point, exactly what the COBOL run prints.
        assert_eq!(edit_blankable_money(b"  "), "        .00");
        assert_eq!(edit_blankable_money(b"07"), "       7.00");
        assert_eq!(edit_blankable_money(b"30"), "      30.00");
    }

    #[test]
    fn blankable_money_zero_suppresses_like_the_picture_does() {
        assert_eq!(edit_blankable_money(b"00"), "       0.00");
        assert_eq!(edit_blankable_money(b" 5"), "       5.00");
    }

    #[test]
    fn records_pad_to_the_full_width_and_clip() {
        let mut record = Record::spaces();
        record.put(131, b"abcdef");
        assert_eq!(record.as_bytes().len(), PRINT_RECORD);
        assert_eq!(&record.as_bytes()[130..], b"ab");
    }

    #[test]
    fn money_zero_suppresses_but_keeps_the_units_digit() {
        assert_eq!(edit_money_cr(0), "       0.00  ");
        assert_eq!(edit_money_cr(3000), "      30.00  ");
        assert_eq!(edit_money_cr(-500), "       5.00CR");
    }

    #[test]
    fn money_keeps_eight_integer_digits() {
        assert_eq!(edit_money_cr(3_897_628_800), "38976288.00  ");
        // A ninth integer digit falls off the left, as `pic z(7)9` does.
        assert_eq!(edit_money_cr(100_000_000_000), "       0.00  ");
    }

    #[test]
    fn discount_scale_two_lands_where_cobol_puts_it() {
        assert_eq!(edit_money("8224", 2), "      82.24");
        assert_eq!(edit_money("5", 2), "       0.05");
    }

    #[test]
    fn suppressed_widths_follow_the_picture() {
        assert_eq!(edit_suppressed(40, 2), "40");
        assert_eq!(edit_suppressed(7, 2), " 7");
        assert_eq!(edit_suppressed(0, 5), "    0");
        assert_eq!(edit_suppressed(38976288, 5), "76288");
    }
}
