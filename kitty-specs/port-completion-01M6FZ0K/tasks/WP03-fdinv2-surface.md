---
work_package_id: WP03
title: fdinv2 full field surface
dependencies:
- WP02
requirement_refs:
- FR-006
subtasks:
- T001
- T002
- T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-sales/src/invoice.rs, docs/disposition-fdinv2.md
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-sales/src/invoice.rs
- reference-ports/rust-acas/docs/disposition-fdinv2.md
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP03 - fdinv2 full field surface

## Objective

Complete every fdinv2 field as a dispositioned, serde-pinned type with byte-exact round-trip, including the comp-3 money fields and all status bytes.

## Context

Dispositions for the money and status fields exist in the ledger but several landings are marked pending. Comp-3 fields must round-trip nibble-exactly; status bytes must preserve unknown values.

**Implementation command**: `spec-kitty agent action implement WP03 --agent <name>`

## Subtasks

### T001: Money fields

- **Purpose**: Represent the eight comp-3 fields with byte-exact packed encode/decode and tests.
- **Files**: `invoice.rs`
- **Validation**: Round-trip tests at min/max/negative values.

### T002: Status bytes + flags

- **Purpose**: Type the status columns and analysed flags, preserving unknown characters.
- **Files**: `invoice.rs`
- **Validation**: Unknown-byte round-trip test.

### T003: Full-record round-trip

- **Purpose**: Extend the round-trip test to a fully populated record from a real captured row.
- **Files**: `invoice.rs tests`
- **Validation**: Captured-row fixture round-trips byte-identically.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
