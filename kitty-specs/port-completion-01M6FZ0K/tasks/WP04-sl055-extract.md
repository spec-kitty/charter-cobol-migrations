---
work_package_id: WP04
title: sl055 extract parity
dependencies:
- WP02
- WP03
requirement_refs:
- FR-003
- FR-005
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- T001
- T002
- T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-sales/src/posting.rs
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-sales/src/posting.rs
- reference-ports/rust-acas/harness/scenarios/sl055*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP04 - sl055 extract parity

## Objective

Implement the ten documented sl055 extract rules so clean, credit-note and pending fixtures produce identical openitm2 and value artifacts on both sides.

## Context

Rules and skip conditions are documented in docs/slice1-reading-notes.md. The pending case is a deliberate departure: COBOL completes work then warns SL122; Rust preflights and returns UnprintedPresent — the openitm2 delta must still match.

**Implementation command**: `spec-kitty agent action implement WP04 --agent <name>`

## Subtasks

### T001: Line analysis path

- **Purpose**: Implement the S+il_pa analysis update including the Emergency Name creation fallback.
- **Files**: `posting.rs`
- **Validation**: Line fixture produces identical value.dat on both sides.

### T002: Header extract + specials

- **Purpose**: Stage headers and accumulate the four specials with credit-note sign handling.
- **Files**: `posting.rs`
- **Validation**: openitm2 + specials hashes match COBOL.

### T003: Pending preflight + departure note

- **Purpose**: Preflight pending invoices; document the departure in the disposition ledger and STATUS.log.
- **Files**: `posting.rs, docs/`
- **Validation**: Pending fixture: openitm2 delta identical, departure documented.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
