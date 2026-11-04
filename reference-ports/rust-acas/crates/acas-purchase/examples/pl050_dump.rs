//! Render a pl050 proof from a fixture case and drop the spool in
//! `/tmp/pl050dump`, beside the case's input frames.
//!
//! `cargo run -p acas-purchase --example pl050_dump -- proof`
//!
//! The report date is fixed to the golden's so a dump stays diffable against
//! `fixtures/golden/pl050/<case>/prt-1`.

use acas_purchase::invoice_proof::{run, Proof, ProofContext, SupplierRow};
use acas_purchase::purchase_invoice::{InvoiceRow, ACAS_INVOICE_RECORD_BYTES};
use std::path::{Path, PathBuf};

/// The day every golden was captured on.
const REPORT_DATE: &str = "04/11/2026";

fn main() {
    let case = std::env::args().nth(1).expect("case");
    let fixtures: PathBuf = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../fixtures");
    let read = |name: &str| {
        std::fs::read(
            fixtures
                .join("generated")
                .join(format!("pl050-{case}"))
                .join(name),
        )
        .unwrap_or_else(|error| panic!("{case}/{name}: {error}"))
    };

    let suppliers = read("purchase.flat")
        .chunks(acas_purchase::PURCHASE_RECORD_BYTES)
        .map(|chunk| SupplierRow::from_bytes(chunk.try_into().expect("whole 300-byte row")))
        .collect::<Vec<_>>();
    let records = read("pinvoice.flat")
        .chunks(ACAS_INVOICE_RECORD_BYTES)
        .map(|chunk| InvoiceRow::from_bytes(chunk.try_into().expect("whole 129-byte frame")))
        .collect::<Vec<_>>();

    let context = ProofContext {
        user: "Harness Test Co".into(),
        report_date: REPORT_DATE.into(),
        date_form: 1,
        page_lines: 48,
        vat_rates: [0; 3],
    };
    let proof = Proof {
        records: &records,
        suppliers: &suppliers,
    };
    let report = run(&proof, &context);

    let rows = report.rows;
    let out = Path::new("/tmp/pl050dump");
    std::fs::create_dir_all(out).unwrap();
    std::fs::write(out.join("prt-1"), report.into_bytes()).unwrap();
    println!("rows {rows} → {}/prt-1", out.display());
}
