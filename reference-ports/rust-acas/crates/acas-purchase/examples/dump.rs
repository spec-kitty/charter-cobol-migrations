use acas_purchase::extract::{extract, AnalysisRow, ExtractRun, ValueRow};
use acas_purchase::purchase_invoice::{
    InvoiceRow, ACAS_INVOICE_RECORD_BYTES, ANALYSIS_RECORD_BYTES, VALUE_RECORD_BYTES,
};
use std::path::Path;

fn main() {
    let case = std::env::args().nth(1).expect("case");
    let out = Path::new("/tmp/pl055dump");
    std::fs::create_dir_all(out).unwrap();
    let dir = format!("fixtures/generated/pl055-{case}");
    let read = |name: &str| std::fs::read(format!("{dir}/{name}")).unwrap();
    let analysis = read("analysis.flat")
        .chunks(ANALYSIS_RECORD_BYTES)
        .filter_map(AnalysisRow::from_bytes)
        .collect::<Vec<_>>();
    let values = read("value.flat")
        .chunks(VALUE_RECORD_BYTES)
        .filter_map(ValueRow::from_bytes)
        .collect::<Vec<_>>();
    let rows = read("pinvoice.flat")
        .chunks(ACAS_INVOICE_RECORD_BYTES)
        .map(|c| {
            let f: [u8; ACAS_INVOICE_RECORD_BYTES] = c.try_into().unwrap();
            InvoiceRow::from_bytes(&f)
        })
        .collect::<Vec<_>>();
    let mut run = ExtractRun::with_tables(analysis, values);
    extract(&mut run, &rows);
    run.finish();
    std::fs::write(out.join("pinvoice.flat"), run.invoice_artifact()).unwrap();
    std::fs::write(out.join("openitm4.dat"), run.item4_artifact()).unwrap();
    std::fs::write(out.join("value.flat"), run.value_artifact()).unwrap();
    std::fs::write(out.join("analysis.flat"), run.analysis_artifact()).unwrap();
    println!(
        "{} {} {}",
        run.invoices_this_month, run.credit_notes_this_month, run.analysis_created
    );
}
