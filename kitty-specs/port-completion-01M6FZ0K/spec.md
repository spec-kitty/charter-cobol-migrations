# Mission Specification: ACAS → Rust Complete Port

**Mission Branch**: `feature/port-completion`
**Created**: 2026-11-02
**Status**: Ready for plan
**Input**: `docs/missions/port-completion/MISSION-OUTLINE.md` (approved by Lynn)

## Context

ACAS is a working 1976-origin COBOL accounting system (sales/purchase/nominal ledgers,
stock, IRS), vendored byte-exact in `reference-ports/rust-acas/cobol-original/`. The repo
already holds: a pty parity harness, hand-verified fixtures for `fdinv2`, byte-pinned
evidence notes (F-B001 date epoch, F-B002 relative-file framing), an `InvoiceRow` type with
byte-exact round-trip, and a stub `posting::extract`. The port must be completed with
byte-level behavior parity, and the migration doctrine packs graduated from the work.

Work proceeds WP-by-WP in the outline's order. Each WP lands behind the parity harness:
a WP is done when its scenario's artifact hashes match the COBOL golden master, or when
the divergence is dispositioned and logged.

## User Scenarios & Testing

### User Story 1 — Harness reaches the system menu reliably (Priority: P1)

The builder needs a repeatable way to get ACAS from cold start to the system menu with a
valid, persisted system file. Today ACAS re-enters SYS002 forever because `scycle = 0`.

**Why this priority**: every downstream slice is blocked on it. No menu, no batch invoke,
no parity.

**Independent Test**: `python3 harness/parity_harness.py run --scenario setup-clean`
produces a transcript whose tail contains menu text and a persisted `system.dat` with
`scycle != 0`; re-running the same scenario skips setup entirely.

**Acceptance Scenarios**:

1. **Given** a pristine harness env, **When** the setup-clean scenario runs, **Then** ACAS
   completes all SYS002 screens, writes the system record, and lands on the ACAS system
   menu; the transcript is stored as a golden master.
2. **Given** that run's `system.dat`, **When** the scenario runs again without a clean env,
   **Then** ACAS boots straight to the menu (no SYS002 screens in the transcript).
3. **Given** the validators that caused the five-times setup loop, **When** they are read,
   **Then** an F-B004 evidence note documents each gate, its accepted values, and the
   keystroke schedule that satisfies them.

---

### User Story 2 — Slice 1 parity: invoice posting extract (Priority: P1)

An operator posts a book of invoices; the Rust `extract` writes an open-item staging file
and analysis value updates indistinguishable from COBOL's.

**Why this priority**: it is the first whole workflow, and the template every later slice
copies.

**Independent Test**: for the `clean` fixture, COBOL `sl055` and Rust
`acas_sales::posting::extract` both run against byte-identical inputs; `openitm2.dat` and
`value.dat` hash-equal.

**Acceptance Scenarios**:

1. **Given** two printed invoices with lines, **When** extract runs on either side,
   **Then** every header is staged to openitm2 with identical bytes and lines are marked
   analysed (`il-update = "Z"`).
2. **Given** a credit note, **When** extract runs, **Then** the four specials
   (`Svo`/`vp`/`zc`/`zd`) carry the same sign-adjusted totals on both sides.
3. **Given** a pending/unprinted invoice, **When** extract runs, **Then** COBOL completes
   work and then warns SL122, while Rust preflights and returns `UnprintedPresent`; the
   openitm2 delta is identical (departure documented in the disposition ledger).

---

### User Story 3 — GL posting (Priority: P2)

`sl060` posts staged open items to the sales ledger and general ledger with identical
writes on both sides.

**Independent Test**: harness runs COBOL then Rust over the same staged file; ledger and
GL files hash-equal.

---

### User Story 4 — Remaining programs by ledger (Priority: P2/P3)

Every remaining batch program in `common/`, `general/`, `sales/`, `purchase/`, `stock/`,
`incomplete_records_system/` gets the same treatment in dependency order.

**Independent Test**: per-program parity scenario exists and passes.

---

### User Story 5 — Interactive session parity (Priority: P3)

A scripted end-to-end session (setup → create invoice → post → print report) reproduces
COBOL's screen text and field order.

---

### User Story 6 — Doctrine graduation + cross-language proof (Priority: P3)

The rust pack gains full tactic pages and graduated worked examples; go and java packs
gain a `fdinv2`+`sl055` reference slice each and satisfy their graduation checklists.

**Independent Test**: `charter-packs/*/GRADUATED` markers cite the evidence that earned
them, and both new reference ports pass the same fixture parity.

---

## Requirements

### Functional Requirements

| ID | Title | User Story | Priority | Status |
|----|-------|------------|----------|--------|
| FR-001 | Scripted setup exit | As a builder, I want a fully scripted ACAS setup run that lands on the system menu with a persisted system record, so every later slice is unblocked. | High | Open |
| FR-002 | GnuCOBOL file reading | As the port, I want to read relative and indexed ISAM files GnuCOBOL writes without loss, so fixtures and golden masters round-trip. | High | Open |
| FR-003 | Invoice extract parity | As an operator, I want posting to stage open items and analysis updates byte-identically to COBOL, so ledgers stay consistent across the switchover. | High | Open |
| FR-004 | GL posting parity | As an accountant, I want `sl060`-equivalent posting to write ledger and GL entries identically, so balances carry over. | High | Open |
| FR-005 | Pending-invoice preflight | As an operator, I want pending invoices refused before work begins, with the same downstream artifacts as COBOL's post-hoc warning. | Medium | Open |
| FR-006 | Full invoice type surface | As the port, I want every `fdinv2` field dispositioned and serialized, so no byte of the record is lost. | High | Open |
| FR-007 | System file type | As the port, I want a typed, byte-exact `SystemFile`, so config reads/writes are safe. | High | Open |
| FR-008 | Per-ledger program coverage | As a user, I want every batch program ported in dependency order with a parity scenario. | High | Open |
| FR-009 | Interactive session parity | As a user, I want a scripted end-to-end session to reproduce COBOL screens and output. | Medium | Open |
| FR-010 | Release artifact | As an operator, I want a single `acas` binary and installer docs. | Medium | Open |
| FR-011 | Doctrine graduation | As another team, I want the rust pack graduated and go/java packs proven on a slice. | Medium | Open |

### Non-Functional Requirements

| ID | Title | Requirement | Category | Priority | Status |
|----|-------|-------------|----------|----------|--------|
| NFR-001 | Suite runtime | Full parity suite completes in under 10 minutes; each scenario under 60 s. | Performance | High | Open |
| NFR-002 | Lint/test gate | `cargo test --workspace` green and `clippy --deny warnings` clean on every commit. | Reliability | High | Open |
| NFR-003 | Binary size | Release binary under 50 MB, statically linkable, no runtime network. | Performance | Medium | Open |
| NFR-004 | Determinism | Identical inputs produce identical artifact hashes across runs. | Reliability | High | Open |

### Constraints

| ID | Title | Constraint | Category | Priority | Status |
|----|-------|------------|----------|----------|--------|
| C-001 | Target language | Rust only; no FFI to live COBOL in shipped builds. | Technical | High | Open |
| C-002 | License | GPL-2.0-only preserved; compatible dependencies only. | Regulatory | High | Open |
| C-003 | Vendored corpus | `cobol-original/` stays byte-exact; deviations only via numbered `PATCHES.md` entries. | Technical | High | Open |
| C-004 | Evidence rule | No struct encodes a byte layout without an `F-Bnnn` note. | Technical | High | Open |

### Key Entities

- **InvoiceRow / InvoiceHeader / InvoiceLine**: the 134-byte dual-variant invoice record.
- **SystemFile**: the 1024-byte system parameter record (rrn 1 of `system.dat`).
- **OpenItem2**: staged posting record handed from extract to the GL poster.
- **ValueRow / AnalysisRow**: analysis counters and code table.
- **Disposition ledger**: per-field carry/rename/retire/defer/absorb record.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of batch programs have a parity scenario whose artifact hashes match the COBOL golden master.
- **SC-002**: A scripted setup→invoice→post→report session matches the COBOL transcript line-for-line.
- **SC-003**: Full parity suite runs in under 10 minutes on the build host.
- **SC-004**: Zero vendored-tree deviations outside `PATCHES.md`.
- **SC-005**: All six ledger domains (common, GL, sales, purchase, stock, IRS) build and pass.
