//! sl050 invoice-proof parity against the COBOL goldens.
//!
//! Each case replays one entry of `harness/scenarios/sl050_proof.py`: the COBOL
//! was driven through the real sales menu, keyed with `F` at the sales menu and
//! the whole 132-byte-record `prt-1` spool — rows, analysis lines, deduction
//! blocks, page mechanics, totals and the VAT reconciliation — is compared byte
//! for byte.
//!
//! The goldens were captured on 2026-11-03 against the seeded `system.dat`
//! (user `Harness Test Co`, `date-form 1`, `page-lines 48`, every VAT rate
//! zero).
//!
//! `proof` ends on a header that declares no lines, because `at end` only
//! fires once: a trailing line leaves the program reading status 46 forever
//! (F-B016 Part 3). Its last real header declares two lines and has one, so the
//! second analysis read consumes the following header — which is why invoice
//! 8 never gets a row of its own.

use acas_sales::invoice::InvoiceRow;
use acas_sales::invoice_proof::{run, Proof, ProofContext};
use acas_sales::post::{SalesRow, SALES_RECORD_BYTES};
use std::path::{Path, PathBuf};

const INVOICE_ROW: usize = 134;

fn fixtures() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures")
}

fn generated(case: &str, name: &str) -> Vec<u8> {
    std::fs::read(fixtures().join("generated/sl050-proof").join(case).join(name))
        .or_else(|_| std::fs::read(fixtures().join("generated/sl050-proof").join(name)))
        .unwrap()
}

fn sales_rows(bytes: &[u8]) -> Vec<SalesRow> {
    bytes
        .chunks(SALES_RECORD_BYTES)
        .map(|chunk| SalesRow::from_bytes(chunk.try_into().expect("whole 300-byte record")))
        .collect()
}

fn invoice_rows(bytes: &[u8]) -> Vec<InvoiceRow> {
    bytes
        .chunks(INVOICE_ROW)
        .map(|chunk| InvoiceRow::from_bytes(chunk).expect("whole 134-byte record"))
        .collect()
}

fn context() -> ProofContext {
    ProofContext {
        user: "Harness Test Co".into(),
        report_date: "03/11/2026".into(),
        date_form: 1,
        page_lines: 48,
        vat_rates: [0; 5],
        extra_desc: [b' '; 12],
    }
}

fn golden(case: &str) -> Vec<u8> {
    let path = fixtures().join("golden/sl050").join(case).join("prt-1");
    std::fs::read(&path).unwrap_or_else(|error| panic!("{}: {error}", path.display()))
}

fn replay(case: &str) {
    let (sales, invoice) = match case {
        "busy" => ("busy-sales.flat", "busy-invoice.flat"),
        _ => ("sales.flat", "invoice.flat"),
    };
    let sales = sales_rows(&generated(case, sales));
    let records = invoice_rows(&generated(case, invoice));
    let proof = Proof { records: &records, sales: &sales };
    let produced = run(&proof, &context()).into_bytes();
    let expected = golden(case);
    assert_eq!(produced.len(), expected.len(), "{case}: spool length");
    assert_eq!(produced, expected, "{case}: spool bytes");
}

#[test]
fn every_proof_reproduces_the_cobol_spool_file() {
    replay("proof");
    replay("busy");
}

#[test]
fn the_report_is_built_from_the_fixtures_the_scenarios_use() {
    // The generated files live under the case name the builder writes.
    let dir = fixtures().join("generated/sl050-proof");
    for name in ["sales.flat", "invoice.flat", "busy-sales.flat", "busy-invoice.flat"] {
        assert!(dir.join(name).exists(), "{} missing", name);
    }
}

#[test]
fn dump_for_debugging() {
    for case in ["proof", "busy"] {
        let (sales, invoice) = match case {
            "busy" => ("busy-sales.flat", "busy-invoice.flat"),
            _ => ("sales.flat", "invoice.flat"),
        };
        let sales = sales_rows(&generated(case, sales));
        let records = invoice_rows(&generated(case, invoice));
        let proof = Proof { records: &records, sales: &sales };
        std::fs::write(
            format!("/tmp/sl050_{case}.bin"),
            run(&proof, &context()).into_bytes(),
        )
        .unwrap();
    }
}
