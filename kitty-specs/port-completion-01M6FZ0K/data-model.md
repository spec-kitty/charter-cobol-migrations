# Phase 1 Data Model — port-completion

Entities the port must represent, with disposition status. Byte layouts cite evidence
notes; nothing is typed before its disposition row exists.

| Entity | Source record | Bytes | Disposition status | Notes |
|---|---|---|---|---|
| `InvoiceRow` (enum Header/Line) | `fdinv2.cob` invoice-record | 134 | **done** — `docs/disposition-fdinv2.md` | dual variant on `item-nos`; serde round-trip tested |
| `InvoiceHeader` fields | `fdinv2.cob` invoice-header | 134 overlay | **done** | carry/absorb rows per field; money as `Money`(i64 cents) |
| `InvoiceLine` fields | `fdinv2.cob` invoice-line | 134 overlay | **done** | `il-product` x(13) fossil-extension carried |
| `SystemFile` | `wssystem.cob` system-record | 1024 | **pending** (WP6) | offsets from F-B002; version prime/secondary at +0/+1 |
| `OpenItem2` header | `fdoi2.cob` | pending read | **pending** (WP3) | sequential staging target; parity artifact |
| `ValueRow` | `fdval.cob` | pending read | **pending** (WP3) | analysis value counters (t/v × this/last/year) |
| `AnalysisRow` | `fdanal.cob` | pending read | **pending** (WP3) | code table; `Emergency Name` fallback is behavior |
| `SpecialsTotals` | in-program ws | n/a | **done** (struct) | four special buckets Svo/vp/zc/zd |
| `CobolDate` | binary-long | 4 | **done** — F-B001 | days since 1600-12-31 |
| `AcasEnv` | env vars | n/a | **done** | SY009 gate carries as a feature |

## Relationships

- `InvoiceHeader 1—* InvoiceLine` by `(invoice_nos, invoice_let)`; header is `item_nos = 0`.
- `InvoiceLine *—1 ValueRow` via `"S" + il_pa` code (creates on miss — the `Emergency
  Name` fallback is observable behavior and is kept).
- `InvoiceHeader 1—1 OpenItem2` on extract (staged, then posted by `sl060`).
- `SystemFile` is singular (rrn 1); rrn 2-4 are default/final/version-4 records.

## Invariants

- Money is fixed-point; `f64` never appears in a stored field.
- `InvoiceType::Other(u8)` preserves unknown codes rather than failing decode.
- Status bytes (`ih-status`, `ih-status-{P,L,C,A,I}`) round-trip as the same characters;
  enums are conveniences, the byte is truth.
- Analysed flags are `z`/`Z`/space; any other value is preserved.

## Storage mapping

| File | Organization | Rust side today |
|---|---|---|
| `system.dat` | relative, 1024 | reader via F-B002 framing |
| `invoice.dat` | indexed | ACAS-authored; reader per F-B005 (pending) |
| `value.dat` | indexed | same |
| `analysis.dat` | indexed | same |
| `openitm2.dat` | sequential | fixture-authored; writer must match byte layout |
