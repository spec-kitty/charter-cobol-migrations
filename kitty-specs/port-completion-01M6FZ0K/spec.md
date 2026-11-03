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

## Functional Requirements

- **FR-1** The harness must never require manual keystrokes; every scenario is fully
  scripted and idempotent.
- **FR-2** Storage layers are external to domain code; domain functions take in-memory
  rows and are testable without I/O.
- **FR-3** The Rust ISAM layer must read files produced by GnuCOBOL (relative and
  indexed) without loss; writes must be byte-identical for the records it emits.
- **FR-4** Money is fixed-point at every layer; `f64` never touches a stored amount.
- **FR-5** Every byte layout encoded in a struct cites an `F-Bnnn` evidence note; a struct
  without evidence is a defect.
- **FR-6** Vendored COBOL and golden masters are read-only except through `PATCHES.md`.
- **FR-7** A blocked WP must be journaled and skipped after 45 minutes; the mission never
  idles on one gate.

## Non-Functional Requirements

- **NFR-1** `cargo test --workspace` and `cargo clippy --deny warnings` green at every
  commit on the feature branch.
- **NFR-2** Batch parity runs complete in seconds; the full parity suite under 10 minutes.
- **NFR-3** Binary size under 50 MB release; no network at runtime.
- **NFR-4** GPL-2.0-only licensing preserved; dependency licenses compatible.

## Key Entities

`Invoice`/`InvoiceRow` (headers + lines), `SystemFile` (1024-byte system record),
`OpenItem2` staging record, analysis `ValueRow`/`AnalysisRow`, ledger records. Each carries
a disposition ledger entry before it is typed.

## Success Criteria (mission-level)

Byte-parity across all batch programs, screen parity on a scripted session, packs
graduated, single release binary, and `PATCHES.md` the only vendored-tree deviation.
