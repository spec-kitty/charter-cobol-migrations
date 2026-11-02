

## F-B001 — Date epoch: COBOL `integer-of-date` is days-since-1600-12-31

Confirmed 2026-11-02 while decoding the harness's `system.dat` run:

- ACAS `Run-Date` (and every `u-bin` dated field) stores the value `integer-of-date(dd/mm/yyyy)`.
- Empirically: 2026-11-02 was persisted by ACAS → little-endian i32 155534 at offset 27 of record 1 in `system.dat` (run bytes: `8e 5f 02 00`).
- `155534` = days from epoch day **0 = 1600-12-31** (COBOL intrinsic convention).
- maps04.cbl carries the conversion functions (`function integer-of-date`, `function date-of-integer`) — they're intrinsic in GnuCOBOL, no custom code.
- **Port disposition: carry.** Rust `CobolDate::from_iso_date()` uses the same epoch (1600-12-31) explicitly. Do NOT normalize to unix time in domain code; that creates an off-by-one drift risk vs ACAS fixtures.
- Tests pin this in `acas-common/src/cobol_date.rs` with the observed 155534↔2026-11-02 mapping.
