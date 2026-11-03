<!-- spec-kitty intake: ingested from docs/missions/port-completion/MISSION-OUTLINE.md at 2026-11-03T05:44:40.241077+00:00 -->
<!-- brief_hash: bea2f25eaf56d8f25a769350beffedf811f31d2d455fdd8fd3ba3f4dbd32e405 -->

# ACAS → Rust Complete Port — Mission Outline

**Status:** APPROVED (Lynn, 2026-11-02) · **License:** GPL-2.0-only (source corpus) ·
**Build agent:** autonomous agent — authority defined in [PERMISSION_GRANT.md](PERMISSION_GRANT.md)

## 1. Purpose

Finish what this repo started: a **complete, behaviorally-faithful Rust port of ACAS**,
the GPLv2 Applewood Computers Accounting System (sales, purchase, nominal ledgers, stock
control, incomplete-records system), plus the generalized **legacy→modern migration
charter packs** (`charter-packs/{common-core,rust,go,java}`) that make the method reusable
by other teams.

When the mission succeeds, `acas` is a single Rust binary running on Linux/macOS/Windows
with the same observable accounting behavior as the 1976-origin COBOL system, proven
byte-for-byte by a parity harness; and the charter packs are graduated doctrine a
stranger can follow to port a different legacy system to Rust, Go, or Java.

## 2. Observation surface / problem space

- **Source corpus (read-only authority):** `reference-ports/rust-acas/cobol-original/` —
  ACAS v3.01.07, unmodified, byte-exact. The source system is the executable spec.
- **Reference implementation:** `reference-ports/rust-acas/` — Cargo workspace, parity
  harness (`harness/parity_harness.py`), fixtures, evidence notes (`docs/fd-evidence/`).
- **Toolchain:** GnuCOBOL 3.1.2 (`cobc`) at `/usr/bin/cobc`; built tree at `/tmp/acas-build`
  (rebuild script documented in `docs/build-logs/`).
- **Method doctrine:** `charter-packs/common-core/` (L2R-001..006), `charter-packs/rust/`
  (proven tactics + worked-example catalog). Doctrine grows *from* porting work; it is
  not authored speculatively.
- **Known blocker (phase A):** ACAS re-enters its SYS002 setup whenever `scycle = 0`.
  The harness cannot yet reach the system menu with a stable system file. Symptoms and
  partial diagnosis: `docs/slice-1-status-2026-11-02.md`, `docs/fd-evidence/F-B003-*.md`.

## 3. Success criteria

Mission is complete when **all** of the following hold:

1. `cargo build --release` produces one `acas` binary; `cargo test --workspace` green.
2. Parity harness scenarios cover **every batch program** in `common/`, `general/`,
   `sales/`, `purchase/`, `stock/`, `incomplete_records_system/`; every scenario's
   output artifacts hash-match the COBOL golden master (except where a deliberate
   idiom departure is documented in `docs/disposition-*.md` and approved in STATUS.log).
3. Interactive screens reproduce COBOL screen text and field order; a scripted
   end-to-end run (setup → invoice → post → report) matches the COBOL transcript.
4. `charter-packs/rust/` has full tactic pages, ≥1 graduated worked example per
   directive, and a `GRADUATED` marker with the evidence index that earned it.
5. `charter-packs/go/` and `charter-packs/java/` each have a reference port of at least
   the `fdinv2` + `sl055` slice against the same fixtures, and their graduation
   checklists are satisfied or explicitly deferred with rationale.
6. No vendored source file differs from upstream except entries in `PATCHES.md`.

## 4. Architecture sketch

Owner-fixed constraints (do not re-cut): **Rust** target language; **GPL-2.0-only**;
vendored COBOL corpus stays byte-exact; parity-harness-first method; doctrine pack
policy (L2R-001..006).

Builder-fixed, refinable (log deviations): crate decomposition, ISAM backend
reimplementation vs. adapter, decimal representation, screen layer (rato/crossterm),
installer shape.

Guiding shape already established and to be continued:

- `acas-common` — file formats (relative + indexed ISAM), date epoch (F-B001),
  domain primitives, env resolution.
- Per-ledger crates mirroring COBOL modules; domain code takes in-memory rows, storage
  stays external so behavior is testable without I/O.
- Harness drives COBOL via pty; Rust side is driven by the same fixtures; artifacts are
  hash-diffed.

## 5. Delivery

Repo `spec-kitty/charter-cobol-migrations`, branch `feature/port-completion-*`.
Merges to `main` per Spec Kitty gates. No deployment/hosting; distribution is
`cargo install` + release binaries. Human-gated: nothing (no credentials, no VMs) —
GnuCOBOL is already installed on the build host.

## 6. Non-goals (v1)

- New features beyond ACAS parity (no multi-currency, no new reports).
- Windows-native screen polish beyond "it runs".
- RDBMS backends (ACAS's own 3.02 RDBMS work is out of scope).
- Modernizing ACAS's file formats (byte parity wins).
- Ports of other legacy systems (only the go/java *packs* are in scope, with a slice).

## 7. Work packages

Each WP is independently reviewable and gated by evidence, not prose.

1. **WP1 — Setup-exit wall.** Read `ACAS.cbl`/`sys002.cbl` validators; produce a
   deterministic keystroke script that reaches a clean "OK to file" and the system menu,
   with a persisted `system.dat`. Golden master + F-B004 evidence note.
2. **WP2 — Fixture & ISAM foundation.** `acas-common` relative-file read/write
   (F-B002), indexed-ISAM read of ACAS-produced files, fixture builder for all
   files slice 1 touches.
3. **WP3 — sl055 `extract` parity.** Implement the ten documented rules; byte-identical
   `openitm2` + `value` output on clean, pending, and credit-note fixtures.
4. **WP4 — sl060 posting to GL.** Same method; parity on ledger + GL writes.
5. **WP5 — Full `fdinv2` type surface + dispositions** (every field, serde-pinned).
6. **WP6 — `SystemFile` (`wssystem`) dispositions + struct.**
7. **WP7 — Remaining sales programs** (`sl010`…`sl960`) in dependency order.
8. **WP8 — Nominal ledger (`general/`)** end-to-end.
9. **WP9 — Purchase ledger (`purchase/`).**
10. **WP10 — Stock control (`stock/`).**
11. **WP11 — IRS (`incomplete_records_system/`).**
12. **WP12 — Screen layer + end-to-end scripted session.**
13. **WP13 — Installer, docs, `acas` binary release flow.**
14. **WP14 — Pack graduation (rust) + go/java reference slices.**

## 8. Workflow notes for the build agent

- Mission slug: recorded by `specify`. **Author `spec.md` from this outline as your first
  act** — the scaffold is deliberately empty.
- Loop: `spec-kitty next --agent codex --mission <slug>` → plan → tasks →
  implement/review per WP.
- **Blocked-and-skippable:** if a WP stalls >45 min, journal it (STATUS.log) and move to
  the next independent WP; never idle.
- Every plan deviation → STATUS.log. Every spec-kitty issue activity → STATUS.log.
- Doctrine first: when a new idiom class appears, add the tactic/worked-example row
  *before* writing the port code for it.
- Keep `PATCHES.md` current; vendored tree is byte-exact except listed patches.
- Evidence before types: no struct may encode a byte layout without an `F-Bnnn` note.
