# Implementation Plan: ACAS → Rust Complete Port

**Branch**: `feature/port-completion` | **Date**: 2026-11-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/kitty-specs/port-completion-01M6FZ0K/spec.md`

## Summary

Complete the behavioral port of ACAS (1976-origin COBOL accounting system, GPLv2) to
Rust with byte-level parity to the vendored COBOL corpus, then graduate the migration
doctrine packs. Method is fixed: golden-master characterization first, dispositioned field
by field, storage kept external to domain code, every byte layout backed by an `F-Bnnn`
evidence note. Work proceeds WP-by-WP behind the pty parity harness.

The single blocker to clear first (WP1) is ACAS's setup re-entry loop: `scycle = 0` in the
system record routes ACAS back into SYS002 on every boot. The harness must produce a clean,
persisted setup run so all later slices can invoke batch programs.

## Technical Context

**Language/Version**: Rust 2021 edition (toolchain 1.96.0 present)
**Primary Dependencies**: serde, thiserror, rust_decimal (pending money decision), ratatui/crossterm (screens, last)
**Storage**: GnuCOBOL ISAM files (relative + indexed) read/written byte-exactly; no DB
**Testing**: cargo test + pty parity harness against COBOL golden masters (fixture hash equality)
**Target Platform**: Linux/macOS/Windows x86_64 + aarch64, terminal UI
**Project Type**: multi-crate Rust workspace (per-ledger crates mirroring COBOL modules)
**Performance Goals**: posting at least as fast as COBOL baseline; parity suite < 10 min
**Constraints**: GPL-2.0-only, no runtime network, f64 never touches money, vendored corpus byte-exact
**Scale/Scope**: ~84.6K LOC COBOL across 6 domains, 114 compiled modules, 77 copybooks

## Charter Check

- **L2R-001 characterize first** → every WP lands fixtures before port code. ✔ planned
- **L2R-002 source is the spec** → no requirement invented from prose. ✔
- **L2R-003 features vs idioms** → disposition ledger per field; tactic/worked-example rows.
- **L2R-004 no rename+restructure in one commit** → commit discipline in WP notes.
- **L2R-005 no silent field** → disposition entries before types; `F-Bnnn` evidence notes.
- **L2R-006 cleaner-than-source suspicion** → parity gate rejects unlost-behavior claims
  unless a disposition row documents the departure.
- **NFR-002 lint/test gate** → clippy `-D warnings` in CI-ish local gate before each commit.

## Project Structure

### Documentation (this mission)

```
kitty-specs/port-completion-01M6FZ0K/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks/               # Phase 2 output (per-WP task files)
```

### Source Code (repository root)

```
charter-packs/
├── common-core/         # L2R directives + tactics (language-agnostic)
├── rust/                # active pack; graduates via worked examples
├── go/                  # draft; needs reference slice
└── java/                # draft; needs reference slice

reference-ports/
├── rust-acas/           # the port
│   ├── cobol-original/  # vendored v3.01.07 (byte-exact + PATCHES.md)
│   ├── crates/          # acas-common, -gl, -sales, -purchase, -stock, -irs
│   ├── docs/
│   │   ├── fd-evidence/ # F-Bnnn byte evidence notes
│   │   └── disposition-*.md
│   ├── fixtures/        # fixture builders + generated scenarios
│   └── harness/         # pty parity harness + golden runs
├── go-acas/             # reference slice (fdinv2 + sl055)
└── java-acas/           # reference slice (fdinv2 + sl055)
```

## Phase 0 — Setup-exit wall (WP1)

Read the SYS002 validator code paths (`ACAS.cbl` gates, `sys002.cbl` screen blocks,
`xl150.cbl` for `scycle`/`cyclea` semantics). Produce:
- a keystroke schedule reaching a clean "OK to file" and menu;
- a persisted, reusable `system.dat` checked in as a golden fixture;
- `docs/fd-evidence/F-B004-setup-gates.md` naming every gate and accepted value.

Done when the scenario reaches menu text, and a second run with the resulting file skips
setup entirely.

## Phase 1 — Foundation (WP2)

- `acas-common::isam`: relative read/write per F-B002 (write == COBOL byte layout).
- Indexed-ISAM reader for ACAS-authored files (F-B003); F-B005 note before struct work.
- Fixture builders for every file slice 1 touches (invoice, value, analysis, openitm2).
- `SystemFile` disposition + struct (F-B002 offsets).

## Phase 2 — Slice 1 (WP3–WP5)

- Full `fdinv2` dispositions and type surface (serde round-trip tests).
- `posting::extract` implementing the ten documented sl055 rules.
- Parity: clean / pending / credit-note fixtures, artifact hash equality; the pending
  departure documented (preflight vs post-hoc SL122).
- Then `sl060` posting half (WP4) to ledger + GL.

## Phase 3 — Coverage (WP6–WP13)

Dependency-ordered porting of remaining programs per domain; each with a parity scenario.
Screens (WP12) last, driven by the same harness. Installer + docs at the end.

## Phase 4 — Doctrine (WP14)

Rust pack: full tactic pages, ≥1 graduated worked example per directive, `GRADUATED`
marker with evidence index. Go and Java reference slices on the same fixtures.

## Complexity Tracking

| Area | Risk | Mitigation |
|---|---|---|
| Setup wall | unknown validator semantics | source-read, not keystroke-guess; 45-min skip rule |
| Indexed ISAM | BDB-ish paged format | read-only first; round-trip only on sequential writes |
| Money semantics | COMP-3 rounding | i64 cents now; rust_decimal decided by F-B006 fixture study |
| Screen parity | curses escape noise | compare stripped text + hashes, not raw bytes |
| Scale | 84.6K LOC | slice-by-slice; parallel-safe WPs; no big-bang |
