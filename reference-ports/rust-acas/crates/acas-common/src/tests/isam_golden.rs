//! Format locks for F-B002 (relative) and F-B005 (indexed), driven by golden
//! bytes rather than reconstructed ones.
//!
//! The paged fixtures in `fixtures/generated/indexed/` were written by
//! GnuCOBOL itself (`fixtures/isam_probe/regenerate.sh`); the relative golden
//! is the WP01 `setup` capture; the flat fixture is the transport the loader
//! streams into a BDB table for ACAS (F-B007) — flat files therefore carry no
//! trailer. Any drift in the decoder shows up as a failing assertion here.

use std::path::PathBuf;

use crate::isam::{fixtures, FileKind, IndexedFile, IndexedLayout, IsamError, RelativeFile};

fn fixture(rel: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../fixtures/generated")
        .join(rel)
}

fn scratch(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("acas-isam-{}-{name}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir.join(name)
}

#[test]
fn relative_round_trip_is_byte_identical_on_golden_system_dat() {
    let golden = std::fs::read(fixture("setup/system.dat")).unwrap();
    assert_eq!(golden.len(), 4128, "F-B002: 4 x 1024 B + 32 B trailer");
    let copy = scratch("system.dat");
    std::fs::write(&copy, &golden).unwrap();

    let file = RelativeFile::open(&copy, 1024).unwrap();
    assert_eq!(file.len(), 4);
    assert_eq!(file.trailer(), &[b' '; 32]);
    file.save().unwrap();

    assert_eq!(std::fs::read(&copy).unwrap(), golden, "round trip drifted");
}

#[test]
fn relative_write_then_reread_keeps_trailer_and_order() {
    // 64-byte records keep the 32-byte trailer shorter than one record, which
    // is what makes it recoverable (see `RelativeFile::open`).
    let path = scratch("ledger.dat");
    let mut file = RelativeFile::create(&path, 64);
    assert_eq!(file.append(&[b'1'; 64]).unwrap(), 1);
    file.append(&[b'2'; 64]).unwrap();
    // RRN 4 leaves RRN 3 space-filled, as GnuCOBOL extension does.
    file.write_record(4, &[b'4'; 64]).unwrap();
    file.save().unwrap();

    let back = RelativeFile::open(&path, 64).unwrap();
    assert_eq!(back.len(), 4);
    assert_eq!(back.read_record(1).unwrap(), &[b'1'; 64]);
    assert_eq!(back.read_record(3).unwrap(), &[b' '; 64]);
    assert_eq!(back.trailer().len(), 32);
    assert!(matches!(back.read_record(9), Err(IsamError::NoRecord { .. })));
}

#[test]
fn relative_rejects_zero_record_size() {
    let path = scratch("zero.dat");
    std::fs::write(&path, vec![0u8; 16]).unwrap();
    assert!(matches!(
        RelativeFile::open(&path, 0),
        Err(IsamError::Malformed(_))
    ));
}

#[test]
fn indexed_reads_gnucobol_paged_file_in_key_order() {
    let file = IndexedFile::open(
        fixture("indexed/invoice-paged.dat"),
        FileKind::Invoice.record_size(),
        FileKind::Invoice.key_len(),
    )
    .unwrap();
    assert_eq!(file.layout(), IndexedLayout::Paged);
    assert_eq!(file.page_count(), 1, "block 0 followed by one leaf page");
    assert_eq!(file.len(), 2);

    let keys: Vec<&[u8]> = file.iter().map(|(k, _)| k).collect();
    let expected: Vec<&[u8]> = vec![b"00000001 \x00", b"00000002 \x00"];
    assert_eq!(keys, expected);

    let body = file.get(b"00000002 \x00").unwrap();
    assert_eq!(body.len(), FileKind::Invoice.record_size());
    assert_eq!(&body[10..17], b"CUST01 ");

    // Separator items carry only the key; they must not become records.
    assert_eq!(file.len(), 2);
}

#[test]
fn indexed_reads_flat_fixture_in_key_order() {
    let file = IndexedFile::open(
        fixture("clean/invoice.dat"),
        FileKind::Invoice.record_size(),
        FileKind::Invoice.key_len(),
    )
    .unwrap();
    assert_eq!(file.layout(), IndexedLayout::Flat);
    // F-B007: a flat fixture is exactly N whole records — the 32 B trailer
    // belongs to the *relative* framing, not to the indexed transport.
    assert!(file.trailer().is_empty());
    assert_eq!(file.len(), 6);

    let keys: Vec<&[u8]> = file.iter().map(|(k, _)| k).collect();
    let expected: Vec<&[u8]> = vec![
        b"00001001 \x00",
        b"00001001 \x01",
        b"00001001 \x02",
        b"00001002 \x00",
        b"00001002 \x01",
        b"00001002 \x02",
    ];
    assert_eq!(keys, expected);
}

#[test]
fn indexed_start_at_or_after_walks_the_rest() {
    let file = IndexedFile::open(
        fixture("clean/invoice.dat"),
        FileKind::Invoice.record_size(),
        FileKind::Invoice.key_len(),
    )
    .unwrap();
    let tail: Vec<&[u8]> = file.first_at_or_after(b"00001002").map(|(k, _)| k).collect();
    assert_eq!(tail.len(), 3, "00001002 header + 2 lines");
    assert!(tail.iter().all(|k| *k >= b"00001002".as_slice()));
}

#[test]
fn indexed_detects_neither_shape() {
    let path = scratch("nonsense.dat");
    std::fs::write(&path, vec![0x7fu8; 5]).unwrap();
    assert!(matches!(
        IndexedFile::open(&path, 134, 10),
        Err(IsamError::Malformed(_))
    ));
}

#[test]
fn builder_record_sizes_match_their_fds() {
    assert_eq!(FileKind::Value.record_size(), 66);
    assert_eq!(FileKind::Analysis.record_size(), 36);
    assert_eq!(FileKind::OpenItem2.record_size(), 114);
    assert_eq!(
        fixtures::value_record(b'S', b'v', b'o', 123, b"probe").len(),
        66
    );
    assert_eq!(
        fixtures::analysis_record(b'A', b'A', b'B', 123, b"probe").len(),
        36
    );
    assert_eq!(fixtures::open_item2_record(b"payload").len(), 114);
}

#[test]
fn builder_output_is_readable_back_as_flat_indexed() {
    // Same key shape as the GnuCOBOL probe (gen_value.cbl), so the fixture is
    // a drop-in for it: the reader must see both rows in key order.
    let records = vec![
        fixtures::value_record(b'S', b'v', b'1', 123, b"one"),
        fixtures::value_record(b'S', b'v', b'2', 124, b"two"),
    ];
    let bytes = fixtures::flat_file(&records);
    let path = scratch("value.dat");
    std::fs::write(&path, &bytes).unwrap();

    let file = IndexedFile::open(
        &path,
        FileKind::Value.record_size(),
        FileKind::Value.key_len(),
    )
    .unwrap();
    assert_eq!(file.len(), 2);
    assert_eq!(file.get(b"Sv2").unwrap(), records[1].as_slice());
}

#[test]
fn paged_value_fixture_matches_the_probe_shape() {
    let file = IndexedFile::open(
        fixture("indexed/value-paged.dat"),
        FileKind::Value.record_size(),
        FileKind::Value.key_len(),
    )
    .unwrap();
    assert_eq!(file.layout(), IndexedLayout::Paged);
    assert_eq!(file.len(), 2);
    assert_eq!(file.page_count(), 1);
}

#[test]
fn checked_in_fixtures_are_self_consistent() {
    // Guards the harness inputs: a size drift here silently mis-frames every
    // record after the first (the old 73/37/100 guesses did exactly that).
    // F-B007: these are the loader transport for the indexed tables and hold
    // bare records, so "consistent" means an exact multiple of the FD record
    // size. Only the invoice stream is required to carry rows — sl070 seeds
    // the analysis/value tables on the first run.
    for name in ["clean", "pending", "credit_note", "mixed", "comment_lines"] {
        for (suffix, size) in [
            ("invoice.dat", FileKind::Invoice.record_size()),
            ("analysis.dat", FileKind::Analysis.record_size()),
            ("value.dat", FileKind::Value.record_size()),
            ("openitm2.dat", FileKind::OpenItem2.record_size()),
        ] {
            let bytes = std::fs::read(fixture(&format!("{name}/{suffix}"))).unwrap();
            assert_eq!(
                bytes.len() % size,
                0,
                "{name}/{suffix}: {} B is not a whole number of {size} B records",
                bytes.len()
            );
        }
        let invoices = std::fs::read(fixture(&format!("{name}/invoice.dat"))).unwrap();
        assert!(!invoices.is_empty(), "{name}: no invoice rows");
    }

    // The indexed fixtures must decode through the real reader, not just be
    // the right length.
    // (`x.dat` and `x.flat` carry the same bytes: `.flat` feeds the COBOL
    // loader, `.dat` keeps the Rust-side name stable.)
    let value = IndexedFile::open(
        fixture("clean/value.dat"),
        FileKind::Value.record_size(),
        FileKind::Value.key_len(),
    );
    let clean = IndexedFile::open(
        fixture("clean/invoice.dat"),
        FileKind::Invoice.record_size(),
        FileKind::Invoice.key_len(),
    )
    .unwrap();
    assert_eq!(clean.len(), 6);
    // The value table starts empty, so an empty file has no shape to detect.
    assert!(matches!(value, Err(IsamError::Malformed(_))));
}
