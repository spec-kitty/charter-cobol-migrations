fn main() {
    let mut m = acas_purchase::PackedMoney::from_cents(150000).unwrap();
    println!("before {:02x?} {}", m.raw(), m.cents());
    m.negate();
    println!("after  {:02x?} {}", m.raw(), m.cents());
}
