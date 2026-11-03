---
work_package_id: WP06
title: SystemFile type
dependencies:
- WP01
requirement_refs:
- FR-007
subtasks:
- T001
- T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-common/src/system.rs
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-common/src/system.rs
- reference-ports/rust-acas/docs/disposition-wssystem.md
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP06 - SystemFile type

## Objective

Full wssystem disposition plus a byte-exact SystemFile type so config reads/writes in later ledgers are safe.

## Context

F-B002 records the offsets verified so far. rrn 1 is the live record; 2-4 are default/final/version-4.

**Implementation command**: `spec-kitty agent action implement WP06 --agent <name>`

## Subtasks

### T001: Dispositions

- **Purpose**: Disposition all 1024 bytes (many are filler-space).
- **Files**: `docs/disposition-wssystem.md`
- **Validation**: Complete field ledger.

### T002: Struct + round-trip

- **Purpose**: Type the fields with golden round-trip.
- **Files**: `system.rs`
- **Validation**: Golden system.dat round-trips.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
