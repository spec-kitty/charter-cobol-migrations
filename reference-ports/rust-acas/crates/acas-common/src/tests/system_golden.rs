//! `wssystem` format lock (F-B011) — driven by the golden `system.dat` the WP01
//! harness produced and by the probe table under `fixtures/sys_probe/`.
//!
//! The offsets asserted here are *runtime* offsets; the table's
//! `compile_offset` column is 8 lower and is what the copybook says.

use std::path::PathBuf;

use crate::cobol_date::CobolDate;
use crate::system::{SystemError, SystemFile, SystemRecord, RECORD_COUNT, RECORD_LEN};

fn fixture(rel: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../fixtures")
        .join(rel)
}

fn scratch(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("acas-system-{}-{name}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir.join(name)
}

/// Offset of `field` in the committed probe table (`runtime_offset`).
fn table_offset(field: &str) -> usize {
    let table = std::fs::read_to_string(fixture("sys_probe/field-map.tsv")).unwrap();
    table
        .lines()
        .filter(|l| !l.starts_with("runtime_offset"))
        .find_map(|line| {
            let mut cols = line.split('\t');
            let off = cols.next()?.parse::<usize>().ok()?;
            let _compile = cols.next()?;
            let _size = cols.next()?;
            (cols.next()? == field).then_some(off)
        })
        .unwrap_or_else(|| panic!("{field} missing from field-map.tsv"))
}

fn golden() -> Vec<u8> {
    std::fs::read(fixture("generated/setup/system.dat")).unwrap()
}

fn live_record() -> SystemRecord {
    let bytes = golden();
    SystemRecord::from_slice(&bytes[..RECORD_LEN]).unwrap()
}

#[test]
fn golden_record_decodes_to_the_values_setup_wrote() {
    let rec = live_record();
    // Prefix pad, opaque (F-B011): `00 04` then zeros.
    assert_eq!(rec.prefix(), &[0x00, 0x04, 0, 0, 0, 0, 0, 0]);
    assert_eq!(rec.usera(), "Harness Test Co");
    // F-B004: 15 Tabs + "01" set cyclea; the harness leaves period 3 (monthly).
    assert_eq!(rec.cyclea(), 1);
    assert_eq!(rec.scycle(), 1);
    assert_eq!(rec.period(), 3);
    assert_eq!(rec.page_lines(), 48);
    // Setup leaves every VAT rate at zero (the shipped defaults are written by
    // a later edit screen, not by SYS002).
    assert_eq!(rec.version_prime(), 1);
    assert_eq!(rec.version_secondary(), 1);
    for rate in [
        rec.vat_rate_1(), rec.vat_rate_2(), rec.vat_rate_3(), rec.vat_rate_4(), rec.vat_rate_5(),
    ] {
        assert_eq!(rate, 0);
    }
    assert_eq!(rec.run_date_cobol(), CobolDate::new(2026, 11, 3).unwrap());
    assert_eq!(rec.start_date(), rec.end_date());
}

#[test]
fn golden_round_trip_is_byte_identical() {
    let original = golden();
    let path = scratch("system.dat");
    std::fs::write(&path, &original).unwrap();

    let mut file = SystemFile::open(&path).unwrap();
    assert_eq!(file.record_count(), RECORD_COUNT);
    assert_eq!(file.trailer(), &original[RECORD_COUNT * RECORD_LEN..]);
    file.write_live(&file.live().unwrap()).unwrap();
    file.save().unwrap();

    assert_eq!(std::fs::read(&path).unwrap(), original);
}

#[test]
fn typed_setters_land_on_the_probe_offsets() {
    // One field from every block and both block edges, so a shifted block or a
    // dropped `+8` cannot pass by accident.
    macro_rules! check {
        ($rec:expr, $name:literal, $expected:expr) => {{
            let off = table_offset($name);
            let expected: &[u8] = $expected;
            assert_eq!(&$rec.as_bytes()[off..off + expected.len()], expected, $name);
        }};
    }
    macro_rules! check_text {
        ($rec:expr, $name:literal, $value:expr) => {{
            let off = table_offset($name);
            let value: &str = $value;
            assert_eq!(&$rec.as_bytes()[off..off + value.len()], value.as_bytes(), $name);
        }};
    }

    let mut rec = SystemRecord::new();
    rec.set_usera("Harness Test Co");
    check_text!(rec, "Usera", "Harness Test Co");
    rec.set_cyclea(1);
    check!(rec, "Cyclea", &[1]);
    rec.set_next_invoice(1);
    check!(rec, "Next-Invoice", &[1, 0, 0, 0]);
    rec.set_run_date(155_535);
    check!(rec, "Run-Date", &[0x8f, 0x5f, 0x02, 0x00]);
    rec.set_vat_rate_4(257);
    check!(rec, "Vat-Rate-4", &[0x01, 0x01]);
    rec.set_sl_late_per(512);
    check!(rec, "SL-Late-Per", &[0x02, 0x00]);
    rec.set_sl_disc(256);
    check!(rec, "SL-Disc", &[0x01, 0x00]);
    rec.set_extra_rate(257);
    check!(rec, "Extra-Rate", &[0x01, 0x01]);
    rec.set_p_c(b'P');
    check!(rec, "P-C", b"P");
    rec.set_extra_charge_ac(7);
    check!(rec, "Extra-Charge-Ac", &[7, 0, 0, 0]);
    rec.set_print_spool_name_2("spool");
    check_text!(rec, "Print-Spool-Name2", "spool");
    rec.set_purchase_ledger(b'Y');
    check!(rec, "Purchase-Ledger", b"Y");
    rec.set_sales_ledger(b'Y');
    check!(rec, "Sales-Ledger", b"Y");
    rec.set_sl_comp_head_lets(b'Y');
    check!(rec, "SL-Comp-Head-Lets", b"Y");
    rec.set_stock_control(b'Y');
    check!(rec, "Stock-Control", b"Y");
    rec.set_stk_abrev_ref("STK");
    check_text!(rec, "Stk-Abrev-Ref", "STK");
    rec.set_client("Client Ltd");
    check_text!(rec, "Client", "Client Ltd");
    rec.set_fn_5("prnfile");
    check_text!(rec, "fn-5", "prnfile");
    rec.set_first_time_flag(1);
    check!(rec, "1st-Time-Flag", &[1]);
}

#[test]
fn every_typed_text_field_is_inside_the_record() {
    // Cheap sweep: no accessor may address past the record, and the tail field
    // must end exactly at the record end (a table/type drift shows up here).
    let rec = live_record();
    let last = table_offset("1st-Time-Flag");
    assert_eq!(last, RECORD_LEN - 5);
    assert_eq!(rec.as_bytes().len(), RECORD_LEN);
}

#[test]
fn text_moves_pad_and_truncate() {
    let mut rec = SystemRecord::new();
    rec.set_post_code("AB1");
    let off = table_offset("Post-Code");
    assert_eq!(&rec.as_bytes()[off..off + 12], b"AB1         ");
    rec.set_post_code("");
    assert_eq!(&rec.as_bytes()[off..off + 12], b"            ");
    // Longer than the field: COBOL MOVE truncates on the right.
    rec.set_post_code("0123456789ABCDEF");
    assert_eq!(&rec.as_bytes()[off..off + 12], b"0123456789AB");
}

#[test]
fn filler_and_prefix_bytes_round_trip_untouched() {
    let mut rec = live_record();
    // +1020..1024 is the tail of the IRS block's 12-byte filler, +376..384 is
    // the system block's 8-byte filler; stack order is unchanged.
    for off in [2, 5, 376, 1020] {
        rec.as_bytes_mut()[off] = 0xEE;
    }
    let bytes = rec.as_bytes().to_vec();
    assert_eq!(SystemRecord::from_slice(&bytes).unwrap(), rec);
    assert_eq!(rec.prefix()[2], 0xEE);
}

#[test]
fn file_statuses_stay_raw() {
    let mut rec = SystemRecord::new();
    rec.set_file_status(0, 3);
    rec.set_file_status(31, b'9');
    assert_eq!(rec.file_status(0), 3);
    assert_eq!(rec.file_status(31), b'9');
    // Out of range clamps to the last slot rather than panicking.
    assert_eq!(rec.file_status(99), b'9');
    assert_eq!(rec.file_statuses().len(), 32);
}

#[test]
fn bad_length_is_rejected() {
    assert!(matches!(
        SystemRecord::from_slice(&[0; RECORD_LEN - 1]),
        Err(SystemError::BadLength(1023))
    ));
}

#[test]
fn create_writes_the_four_records_and_the_trailer() {
    let path = scratch("fresh.dat");
    let file = SystemFile::create(&path).unwrap();
    file.save().unwrap();
    let bytes = std::fs::read(&path).unwrap();
    assert_eq!(bytes.len(), RECORD_COUNT * RECORD_LEN + 32);
    assert_eq!(&bytes[RECORD_COUNT * RECORD_LEN..], b"                                ");
}
