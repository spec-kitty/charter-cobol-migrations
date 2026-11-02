# rust-acas

Port of **ACAS (Applewood Computers Accounting System)** v3.01.07 from COBOL to Rust.

## Upstream

- Source: SourceForge — https://sourceforge.net/projects/acas/
- License: GPLv2-only (per source file headers). This port and the original remain GPLv2.
- Vendored baseline in `cobol-original/` is *unmodified* upstream for parity harness reference.
- Not affiliated with Applewood Computers — see original docs in `cobol-original/ACAS-Manuals/`.

## Module map (COBOL → Rust crate structure)

| COBOL dir | Domain | Rust crate |
|-----------|--------|------------|
| `common/` | system config, shared utilities | `acas-common` |
| `general/` | Nominal / General Ledger | `acas-gl` |
| `sales/` | Sales Ledger (AR), invoicing | `acas-sales` |
| `purchase/` | Purchase Ledger (AP) | `acas-purchase` |
| `stock/` | Stock / inventory control | `acas-stock` |
| `incomplete_records_system/` | IRS small-business bookkeep | `acas-irs` |

## Approach

Each domain is ported slice-by-slice (a full *workflow*, not a full directory):
1. Golden-master characterization of the COBOL slice.
2. Disposition audit of every copybook record field used by the slice.
3. Rust design following `charter-pack` directives (replace idiom, preserve behavior).
4. Parity harness runs COBOL + Rust side-by-side; byte-level diffs where allowed.

## Phases

- **Phase 0** ✅ (this commit) — topology + vendored baseline
- **Phase 1** — Parity harness + copybook disposition backbone
- **Phase 2** — `acas-common` (system file, date handling, screen plumbing)
- **Phase 3** — one full posting slice end-to-end (Sales ledger invoice posting → GL)
- **Phase 4+** — remaining ledgers
