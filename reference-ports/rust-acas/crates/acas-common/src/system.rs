//! `wssystem.cob` — the system file record (F-B011).
//!
//! The record is 1024 bytes, record 1 of `system.dat`; 2-4 are the one-time
//! default / final / version-4 records `ACAS.cbl` writes at first-run setup.
//!
//! **Offsets are runtime offsets**, i.e. copybook offset + 8. The shipped
//! binary carries an 8-byte prefix ahead of the version fields that the
//! vendored copybook does not describe; `docs/disposition-wssystem.md` has the
//! whole ledger and `fixtures/sys_probe/` regenerates it from source.
//!
//! Encoding rules that matter here, both measured on GnuCOBOL output:
//!
//! * `comp` (the VAT rates, `sl-late-per`, `sl-disc`, `extra-rate`) is
//!   big-endian, and `pic 99v99` is scaled by 100 — 2.56 is the integer 256.
//! * `binary-short` / `binary-long` are native-endian (little-endian here).
//! * `pic 9` and `pic x` are the literal byte: a digit is `b'0'`-`b'9'`, not
//!   a value, and unknown bytes are preserved rather than normalised.
//!
//! Underneath is a raw `[u8; 1024]`, so filler and any byte we have not typed
//! round-trip verbatim.

use std::borrow::Cow;
use std::path::Path;

use thiserror::Error;

use crate::cobol_date::CobolDate;
use crate::isam::{IsamError, RelativeFile};

/// Record length; F-B002 and F-B011 both pin this at 1024.
pub const RECORD_LEN: usize = 1024;
/// Records in a fresh `system.dat` (live, default, final, version-4).
pub const RECORD_COUNT: usize = 4;
/// The only record main programs read.
pub const RRN_LIVE: usize = 1;
/// Opaque 8-byte prefix ahead of the version fields (F-B011).
pub const PREFIX_RANGE: std::ops::Range<usize> = 0..8;

#[derive(Debug, Error)]
pub enum SystemError {
    #[error("system record must be {RECORD_LEN} bytes, got {0}")]
    BadLength(usize),
    #[error(transparent)]
    Isam(#[from] IsamError),
}

type Result<T> = std::result::Result<T, SystemError>;

/// One `system-record`. Byte-exact by construction.
#[derive(Clone, PartialEq, Eq)]
pub struct SystemRecord([u8; RECORD_LEN]);

impl Default for SystemRecord {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Debug for SystemRecord {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SystemRecord")
            .field("usera", &self.usera())
            .field("cyclea", &self.cyclea())
            .field("period", &self.period())
            .finish_non_exhaustive()
    }
}

impl SystemRecord {
    /// A space-filled record, the state `initialize system-record` produces
    /// for the character areas and the state a `create` starts from.
    pub fn new() -> Self {
        Self([b' '; RECORD_LEN])
    }

    /// A zero-filled record — what `INITIALIZE` gives the numeric areas.
    pub fn zeroed() -> Self {
        Self([0; RECORD_LEN])
    }

    pub fn from_slice(bytes: &[u8]) -> Result<Self> {
        let arr: [u8; RECORD_LEN] =
            bytes.try_into().map_err(|_| SystemError::BadLength(bytes.len()))?;
        Ok(Self(arr))
    }

    pub fn as_bytes(&self) -> &[u8; RECORD_LEN] {
        &self.0
    }

    pub fn as_bytes_mut(&mut self) -> &mut [u8; RECORD_LEN] {
        &mut self.0
    }

    /// The prefix `+0..8`, opaque (F-B011): `00 04` then six zero bytes.
    pub fn prefix(&self) -> &[u8] {
        &self.0[PREFIX_RANGE]
    }

    fn bytes(&self, off: usize, len: usize) -> &[u8] {
        &self.0[off..off + len]
    }

    fn read_u8(&self, off: usize) -> u8 {
        self.0[off]
    }

    fn write_u8(&mut self, off: usize, v: u8) {
        self.0[off] = v;
    }

    fn read_be16(&self, off: usize) -> i16 {
        i16::from_be_bytes([self.0[off], self.0[off + 1]])
    }

    fn write_be16(&mut self, off: usize, v: i16) {
        self.0[off..off + 2].copy_from_slice(&v.to_be_bytes());
    }

    fn read_le16(&self, off: usize) -> i16 {
        i16::from_le_bytes([self.0[off], self.0[off + 1]])
    }

    fn write_le16(&mut self, off: usize, v: i16) {
        self.0[off..off + 2].copy_from_slice(&v.to_le_bytes());
    }

    fn read_le32(&self, off: usize) -> i32 {
        i32::from_le_bytes([
            self.0[off],
            self.0[off + 1],
            self.0[off + 2],
            self.0[off + 3],
        ])
    }

    fn write_le32(&mut self, off: usize, v: i32) {
        self.0[off..off + 4].copy_from_slice(&v.to_le_bytes());
    }
}

/// `pic x` field: reads trailing-space-trimmed, writes with COBOL MOVE
/// padding (space fill, truncate on overflow).
macro_rules! text_field {
    ($($get:ident / $set:ident @ $off:expr, $len:expr),* $(,)?) => {$(
        pub fn $get(&self) -> Cow<'_, str> {
            let raw = self.bytes($off, $len);
            let end = raw.iter().rposition(|b| *b != b' ').map_or(0, |i| i + 1);
            String::from_utf8_lossy(&raw[..end])
        }

        pub fn $set(&mut self, value: &str) {
            self.0[$off..$off + $len].fill(b' ');
            let src = value.as_bytes();
            let n = src.len().min($len);
            self.0[$off..$off + n].copy_from_slice(&src[..n]);
        }
    )*};
}

/// `pic 9` / `pic x` single byte: the literal byte, unnormalised.
macro_rules! byte_field {
    ($($get:ident / $set:ident @ $off:expr),* $(,)?) => {$(
        pub fn $get(&self) -> u8 {
            self.read_u8($off)
        }

        pub fn $set(&mut self, value: u8) {
            self.write_u8($off, value);
        }
    )*};
}

/// `pic 99v99 comp` — big-endian, scaled by 100.
macro_rules! comp_rate {
    ($($get:ident / $set:ident @ $off:expr),* $(,)?) => {$(
        /// Hundredths: `256` is `2.56`.
        pub fn $get(&self) -> i16 {
            self.read_be16($off)
        }

        pub fn $set(&mut self, hundredths: i16) {
            self.write_be16($off, hundredths);
        }
    )*};
}

/// `binary-short` — native (little) endian.
macro_rules! short_field {
    ($($get:ident / $set:ident @ $off:expr),* $(,)?) => {$(
        pub fn $get(&self) -> i16 {
            self.read_le16($off)
        }

        pub fn $set(&mut self, value: i16) {
            self.write_le16($off, value);
        }
    )*};
}

/// `binary-long`; the date-ish ones also get a `CobolDate` view.
macro_rules! long_field {
    ($($get:ident / $set:ident @ $off:expr),* $(,)?) => {$(
        pub fn $get(&self) -> i32 {
            self.read_le32($off)
        }

        pub fn $set(&mut self, value: i32) {
            self.write_le32($off, value);
        }
    )*};
}

impl SystemRecord {
    text_field! {
        usera / set_usera @ 39, 32,
        user_code / set_user_code @ 71, 32,
        address_1 / set_address_1 @ 103, 24,
        address_2 / set_address_2 @ 127, 24,
        address_3 / set_address_3 @ 151, 24,
        address_4 / set_address_4 @ 175, 24,
        post_code / set_post_code @ 199, 12,
        country / set_country @ 211, 24,
        print_spool_name / set_print_spool_name @ 235, 48,
        pass_word / set_pass_word @ 322, 4,
        maps_ser_xx / set_maps_ser_xx @ 331, 2,
        rdbms_db_name / set_rdbms_db_name @ 337, 12,
        rdbms_user / set_rdbms_user @ 349, 12,
        rdbms_passwd / set_rdbms_passwd @ 361, 12,
        vat_reg_number / set_vat_reg_number @ 373, 11,
        print_spool_name_2 / set_print_spool_name_2 @ 424, 48,
        print_spool_name_3 / set_print_spool_name_3 @ 502, 48,
        extra_desc / set_extra_desc @ 576, 14,
        stk_abrev_ref / set_stk_abrev_ref @ 688, 6,
        client / set_client @ 904, 24,
        fn_1 / set_fn_1 @ 928, 9,
        fn_2 / set_fn_2 @ 937, 10,
        fn_3 / set_fn_3 @ 947, 8,
        fn_4 / set_fn_4 @ 955, 8,
        fn_5 / set_fn_5 @ 963, 12,
        system_ops / set_system_ops @ 975, 1,
        next_post / set_next_post @ 976, 5,
        vat_2_1 / set_vat_2_1 @ 981, 4,
        vat_2_2 / set_vat_2_2 @ 985, 4,
        vat_2_3 / set_vat_2_3 @ 989, 4,
        system_work_group / set_system_work_group @ 995, 18,
        pl_appropriation_ac / set_pl_appropriation_ac @ 1014, 5,
    }

    byte_field! {
        version_prime / set_version_prime @ 8,
        version_secondary / set_version_secondary @ 9,
        cyclea / set_cyclea @ 20,
        period / set_period @ 21,
        page_lines / set_page_lines @ 22,
        pass_value / set_pass_value @ 315,
        level_1 / set_level_1 @ 316,
        level_2 / set_level_2 @ 317,
        level_3 / set_level_3 @ 318,
        level_4 / set_level_4 @ 319,
        level_5 / set_level_5 @ 320,
        level_6 / set_level_6 @ 321,
        host / set_host @ 326,
        op_system / set_op_system @ 327,
        current_quarter / set_current_quarter @ 328,
        file_system_used / set_file_system_used @ 329,
        file_duplicates_in_use / set_file_duplicates_in_use @ 330,
        date_form / set_date_form @ 335,
        data_capture_used / set_data_capture_used @ 336,
        p_c / set_p_c @ 392,
        p_c_grouped / set_p_c_grouped @ 393,
        p_c_level / set_p_c_level @ 394,
        comps / set_comps @ 395,
        comps_active / set_comps_active @ 396,
        m_v / set_m_v @ 397,
        arch / set_arch @ 398,
        trans_print / set_trans_print @ 399,
        trans_printed / set_trans_printed @ 400,
        header_level / set_header_level @ 401,
        sales_range / set_sales_range @ 402,
        purchase_range / set_purchase_range @ 403,
        vat / set_vat @ 404,
        batch_id / set_batch_id @ 405,
        ledger_2nd_index / set_ledger_2nd_index @ 406,
        irs_instead / set_irs_instead @ 407,
        age_to_pay / set_age_to_pay @ 494,
        purchase_ledger / set_purchase_ledger @ 495,
        pl_delim / set_pl_delim @ 496,
        entry_level / set_entry_level @ 497,
        p_flag_a / set_p_flag_a @ 498,
        p_flag_i / set_p_flag_i @ 499,
        p_flag_p / set_p_flag_p @ 500,
        pl_stock_link / set_pl_stock_link @ 501,
        sales_ledger / set_sales_ledger @ 560,
        sl_delim / set_sl_delim @ 561,
        oi_3_flag / set_oi_3_flag @ 562,
        cust_flag / set_cust_flag @ 563,
        oi_5_flag / set_oi_5_flag @ 564,
        s_flag_oi_3 / set_s_flag_oi_3 @ 565,
        full_invoicing / set_full_invoicing @ 566,
        s_flag_a / set_s_flag_a @ 567,
        s_flag_i / set_s_flag_i @ 568,
        s_flag_p / set_s_flag_p @ 569,
        sl_dunning / set_sl_dunning @ 570,
        sl_charges / set_sl_charges @ 571,
        sl_own_nos / set_sl_own_nos @ 572,
        sl_stats_run / set_sl_stats_run @ 573,
        sl_day_book / set_sl_day_book @ 574,
        invoicer / set_invoicer @ 575,
        extra_type / set_extra_type @ 590,
        extra_print / set_extra_print @ 591,
        sl_stock_link / set_sl_stock_link @ 592,
        sl_stock_audit / set_sl_stock_audit @ 593,
        sl_days_1 / set_sl_days_1 @ 600,
        sl_days_2 / set_sl_days_2 @ 601,
        sl_days_3 / set_sl_days_3 @ 602,
        sl_credit / set_sl_credit @ 603,
        sl_comp_head_pick / set_sl_comp_head_pick @ 638,
        sl_comp_head_inv / set_sl_comp_head_inv @ 639,
        sl_comp_head_stat / set_sl_comp_head_stat @ 640,
        sl_comp_head_lets / set_sl_comp_head_lets @ 641,
        sl_vat_printed / set_sl_vat_printed @ 642,
        stk_debug / set_stk_debug @ 694,
        stk_manu_used / set_stk_manu_used @ 695,
        stk_oe_used / set_stk_oe_used @ 696,
        stk_audit_used / set_stk_audit_used @ 697,
        stk_mov_audit / set_stk_mov_audit @ 698,
        stk_period_cur / set_stk_period_cur @ 699,
        stk_period_dat / set_stk_period_dat @ 700,
        stock_control / set_stock_control @ 702,
        stk_averaging / set_stk_averaging @ 703,
        stk_activity_rep_run / set_stk_activity_rep_run @ 704,
        stk_page_lines / set_stk_page_lines @ 706,
        stk_audit_no / set_stk_audit_no @ 707,
        irs_pass_value / set_irs_pass_value @ 993,
        save_sequ / set_save_sequ @ 994,
        pl_app_created / set_pl_app_created @ 1013,
        first_time_flag / set_first_time_flag @ 1019,
    }

    comp_rate! {
        vat_rate_1 / set_vat_rate_1 @ 10,
        vat_rate_2 / set_vat_rate_2 @ 12,
        vat_rate_3 / set_vat_rate_3 @ 14,
        vat_rate_4 / set_vat_rate_4 @ 16,
        vat_rate_5 / set_vat_rate_5 @ 18,
        sl_late_per / set_sl_late_per @ 594,
        sl_disc / set_sl_disc @ 596,
        extra_rate / set_extra_rate @ 598,
    }

    short_field! {
        ledger_sec / set_ledger_sec @ 408,
        updates / set_updates @ 410,
        postings / set_postings @ 412,
        next_batch / set_next_batch @ 414,
        bl_next_batch / set_bl_next_batch @ 492,
        maps_ser_nn / set_maps_ser_nn @ 333,
        sl_min / set_sl_min @ 606,
        sl_max / set_sl_max @ 608,
        pf_retention / set_pf_retention @ 610,
        first_sl_batch / set_first_sl_batch @ 612,
    }

    long_field! {
        next_invoice / set_next_invoice @ 23,
        run_date / set_run_date @ 27,
        start_date / set_start_date @ 31,
        end_date / set_end_date @ 35,
        extra_charge_ac / set_extra_charge_ac @ 416,
        vat_ac / set_vat_ac @ 420,
        next_folio / set_next_folio @ 472,
        bl_pay_ac / set_bl_pay_ac @ 476,
        p_creditors / set_p_creditors @ 480,
        bl_purch_ac / set_bl_purch_ac @ 484,
        bl_end_cycle_date / set_bl_end_cycle_date @ 488,
        first_sl_inv / set_first_sl_inv @ 614,
        sl_limit / set_sl_limit @ 618,
        sl_pay_ac / set_sl_pay_ac @ 622,
        s_debtors / set_s_debtors @ 626,
        sl_sales_ac / set_sl_sales_ac @ 630,
        s_end_cycle_date / set_s_end_cycle_date @ 634,
    }

    /// `Scycle` redefines `Cyclea`; the boot gate reads either name.
    pub fn scycle(&self) -> u8 {
        self.cyclea()
    }

    pub fn set_scycle(&mut self, value: u8) {
        self.set_cyclea(value);
    }

    /// `File-Status` occurs 32 times, one display digit per file index.
    pub fn file_status(&self, index: usize) -> u8 {
        self.read_u8(283 + index.min(31))
    }

    pub fn set_file_status(&mut self, index: usize, value: u8) {
        self.write_u8(283 + index.min(31), value);
    }

    /// The whole 32-byte `File-Statuses` group, unnormalised.
    pub fn file_statuses(&self) -> &[u8] {
        self.bytes(283, 32)
    }

    pub fn run_date_cobol(&self) -> CobolDate {
        CobolDate(self.run_date())
    }

    pub fn start_date_cobol(&self) -> CobolDate {
        CobolDate(self.start_date())
    }

    pub fn end_date_cobol(&self) -> CobolDate {
        CobolDate(self.end_date())
    }

    pub fn bl_end_cycle_date_cobol(&self) -> CobolDate {
        CobolDate(self.bl_end_cycle_date())
    }

    pub fn s_end_cycle_date_cobol(&self) -> CobolDate {
        CobolDate(self.s_end_cycle_date())
    }

    pub fn next_folio_cobol(&self) -> CobolDate {
        CobolDate(self.next_folio())
    }

    pub fn next_invoice_date_cobol(&self) -> CobolDate {
        CobolDate(self.next_invoice())
    }
}

/// A `system.dat`: four records and the untouched trailer (F-B002 framing).
pub struct SystemFile {
    relative: RelativeFile,
}

impl SystemFile {
    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        Ok(Self {
            relative: RelativeFile::open(path, RECORD_LEN)?,
        })
    }

    pub fn create(path: impl AsRef<Path>) -> Result<Self> {
        let mut file = Self {
            relative: RelativeFile::create(path, RECORD_LEN),
        };
        for _ in 0..RECORD_COUNT {
            file.relative.append(&SystemRecord::zeroed().0)?;
        }
        Ok(file)
    }

    pub fn record_count(&self) -> usize {
        self.relative.len()
    }

    pub fn trailer(&self) -> &[u8] {
        self.relative.trailer()
    }

    pub fn record(&self, rrn: usize) -> Result<SystemRecord> {
        SystemRecord::from_slice(self.relative.read_record(rrn)?)
    }

    /// Record 1 — the only one main programs read.
    pub fn live(&self) -> Result<SystemRecord> {
        self.record(RRN_LIVE)
    }

    pub fn write(&mut self, rrn: usize, record: &SystemRecord) -> Result<()> {
        Ok(self.relative.write_record(rrn, record.as_bytes())?)
    }

    pub fn write_live(&mut self, record: &SystemRecord) -> Result<()> {
        self.write(RRN_LIVE, record)
    }

    pub fn save(&self) -> Result<()> {
        Ok(self.relative.save()?)
    }
}

impl std::fmt::Debug for SystemFile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SystemFile")
            .field("records", &self.relative.len())
            .field("trailer_len", &self.relative.trailer().len())
            .finish()
    }
}
