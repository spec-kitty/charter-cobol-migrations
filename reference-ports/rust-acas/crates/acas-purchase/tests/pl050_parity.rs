//! pl050 invoice-proof parity against the COBOL goldens.
//!
//! Each case replays one entry of `harness/scenarios/pl050_proof.py`: the COBOL
//! was driven through the real purchase menu with `G`, and the whole
//! 132-byte-record `prt-1` spool — rows, analysis lines, the prompt-pay and
//! carriage blocks, the page mechanics, the three group totals and the VAT
//! reconciliation — is compared byte for byte.
//!
//! The goldens were captured on 2026-11-04 against the seeded `system.dat`
//! (user `Harness Test Co`, `date-form 1`, `page-lines 48`, every VAT rate
//! zero) and every case was re-run afterwards with identical bytes.
//!
//! The report carries the run date on every page, so the test feeds the
//! golden's own `to-day` rather than re-deriving one.

use acas_purchase::invoice_proof::{convert_today, run, Proof, ProofContext, SupplierRow};
use acas_purchase::purchase_invoice::{InvoiceRow, ACAS_INVOICE_RECORD_BYTES};
use std::path::{Path, PathBuf};

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(case: &str, name: &str) -> Vec<u8> {
    let path = fixtures().join("generated").join(case).join(name);
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn golden(case: &str) -> Vec<u8> {
    let path = fixtures().join("golden/pl050").join(case).join("prt-1");
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn invoice_rows(bytes: &[u8]) -> Vec<InvoiceRow> {
    bytes
        .chunks(ACAS_INVOICE_RECORD_BYTES)
        .map(|chunk| {
            InvoiceRow::from_bytes(chunk.try_into().expect("whole 129-byte invoice frame"))
        })
        .collect()
}

fn supplier_rows(bytes: &[u8]) -> Vec<SupplierRow> {
    bytes
        .chunks(acas_purchase::PURCHASE_RECORD_BYTES)
        .map(|chunk| SupplierRow::from_bytes(chunk.try_into().expect("whole 300-byte row")))
        .collect()
}

fn context() -> ProofContext {
    ProofContext {
        user: "Harness Test Co".into(),
        report_date: convert_today("04/11/2026", 1),
        date_form: 1,
        page_lines: 48,
        vat_rates: [0; 3],
    }
}

/// Run one case: invoices from the generator, suppliers from the same dataset.
fn replay(_case: &str, invoice: &str) -> Vec<u8> {
    let suppliers = supplier_rows(&generated("pl050-proof", "purchase.flat"));
    let records = invoice_rows(&generated("pl050-proof", invoice));
    let proof = Proof {
        records: &records,
        suppliers: &suppliers,
    };
    run(&proof, &context()).into_bytes()
}

#[test]
fn every_case_reproduces_the_cobol_spool_file() {
    for (case, invoice) in [
        ("proof", "pinvoice.flat"),
        ("busy", "busy-pinvoice.flat"),
        ("empty", "empty-pinvoice.flat"),
    ] {
        let produced = replay(case, invoice);
        let expected = golden(case);
        assert_eq!(produced.len(), expected.len(), "{case}: spool length");
        assert_eq!(produced, expected, "{case}: spool bytes");
    }
}

/// The spool is a sequence of 132-byte records joined by newlines, with the
/// page eject standing at the head of the first line of each later page.
fn lines(spool: &[u8]) -> Vec<&[u8]> {
    spool
        .split(|byte| *byte == b'\n')
        .filter(|line| line.len() == 132)
        .collect()
}

#[test]
fn a_proforma_prints_but_never_reaches_the_group_totals() {
    // Type 4 is the group subscript, and the table is only three entries long,
    // so both proformas print (as `Cr. Note`, with no sign flip) and their
    // amounts are stored past the end of the table (F-B050 Part 1).
    let spool = replay("proof", "pinvoice.flat");
    let text = lines(&spool);
    let proformas: Vec<&&[u8]> = text
        .iter()
        .filter(|line| line.windows(8).any(|window| window == b"Cr. Note"))
        .collect();
    assert_eq!(
        proformas.len(),
        3,
        "two proformas plus the real credit note"
    );
    assert_eq!(
        &proformas[0][..9],
        b"       3 ",
        "the real credit note comes first"
    );
    assert_eq!(&proformas[1][..9], b"       4 ", "proforma 4");
    assert_eq!(&proformas[2][..9], b"      41 ", "proforma 41");
    assert!(
        proformas[1].windows(6).any(|w| w == b" 77.00"),
        "77.00 row present"
    );

    // Receipts total 515.00 = 500.00 + 15.00 — the proformas' 77.00 and 5.00
    // are absent from every group.
    let totals: Vec<String> = text
        .iter()
        .map(|line| String::from_utf8_lossy(line).into_owned())
        .filter(|line| line.contains("Total "))
        .collect();
    assert_eq!(totals.len(), 3, "one total per group");
    assert!(totals[0].contains("515.00") && totals[0].contains("108.15"));
    assert!(totals[1].contains("231.99") && totals[1].contains("49.77"));
    assert!(totals[2].contains("40.00CR") && totals[2].contains("8.82CR"));
}

#[test]
fn the_missed_supplier_prints_the_literal_and_the_warning() {
    let spool = replay("proof", "pinvoice.flat");
    let text = String::from_utf8_lossy(&spool).into_owned();
    assert!(
        text.contains("Supplier Unknown"),
        "the literal replaces the name"
    );
    assert!(
        text.contains("Warning: Record/s missing in Purchase File"),
        "and the sticky flag prints the closing warning"
    );
    // The flag is sticky: exactly one warning however many keys missed.
    assert_eq!(text.matches("Warning: Record/s missing").count(), 1);
}

#[test]
fn the_analysis_reads_the_thirteenth_product_byte_as_the_code() {
    // `il-product` is twelve bytes against a thirteen-byte disk field, so the
    // code column carries `product (13)` + `pa (1:1)` (F-B050 Part 2).
    let spool = replay("proof", "pinvoice.flat");
    let codes: Vec<String> = lines(&spool)
        .iter()
        .filter(|line| line.starts_with(b"                                              Analysis"))
        .map(|line| String::from_utf8_lossy(&line[58..64]).trim().to_string())
        .collect();
    assert_eq!(codes, ["V1", "V1", "", "V1", "V2", "V1", "V2"]);
}

#[test]
fn a_credit_note_carries_its_cr_suffix_past_position_132() {
    // `line-5` composes to exactly 132 bytes here, so unlike the sales proof
    // nothing of the `CR` is lost (F-B050 Part 3).
    let spool = replay("proof", "pinvoice.flat");
    let row = lines(&spool)
        .into_iter()
        .find(|line| &line[..9] == b"       3 " && &line[58..66] == b"Cr. Note")
        .expect("the credit note row");
    assert_eq!(
        &row[130..132],
        b"CR",
        "the suffix survives to the record end"
    );
}

#[test]
fn a_comment_line_abandons_the_rest_of_its_invoices_analysis() {
    // Invoice 7 declares two lines; the first is a comment, so its second line
    // comes back through the main loop as a non-header and prints nothing.
    let spool = replay("proof", "pinvoice.flat");
    let text = String::from_utf8_lossy(&spool).into_owned();
    assert!(text.contains("       7 "), "invoice 7 prints its own row");
    assert!(
        !text.contains("HMER-1"),
        "its declared second line never prints"
    );
}
