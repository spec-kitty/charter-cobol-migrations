---
work_package_id: WP05
title: sl060 GL posting parity
dependencies:
- WP04
requirement_refs:
- FR-004
subtasks:
- T001
- T002
- T003
agent: "codex"
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-sales/src/post.rs
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-sales/src/post.rs
- reference-ports/rust-acas/docs/disposition-fdoi2.md
role: ''
tags: []
---

# Work Package Prompt: WP05 - sl060 GL posting parity

## Objective

Port the sl060 posting half: staged open items to sales ledger and general ledger, byte-identical on both sides.

## Context

sl060 consumes the openitm2 staging file that WP04's parity run produces. Ledger and GL record layouts need dispositions before types.

**Implementation command**: `spec-kitty agent action implement WP05 --agent <name>`

## Subtasks

### T001: fdoi2 dispositions

- **Purpose**: Disposition the staging record fully.
- **Files**: `docs/disposition-fdoi2.md`
- **Validation**: Every field carrying a disposition.

### T002: Posting logic

- **Purpose**: Implement open-item and GL writes.
- **Files**: `post.rs`
- **Validation**: both ledger files hash-match COBOL.

### T003: Chain parity

- **Purpose**: Harness scenario running sl055+sl060 chained, comparing both.
- **Files**: `harness/scenarios/`
- **Validation**: Chained scenario green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
