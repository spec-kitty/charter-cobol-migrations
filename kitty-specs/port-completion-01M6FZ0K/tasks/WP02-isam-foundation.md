---
work_package_id: WP02
title: ISAM foundation + fixtures
dependencies:
- WP01
requirement_refs:
- C-003
- FR-002
- NFR-004
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- T001
- T002
- T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-common/src/isam*.rs
create_intent:
- reference-ports/rust-acas/docs/fd-evidence/F-B005*
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-common/src/isam*.rs
- reference-ports/rust-acas/fixtures/**
- reference-ports/rust-acas/docs/fd-evidence/F-B005*
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP02 - ISAM foundation + fixtures

## Objective

Implement relative-file read/write to the F-B002 layout and an indexed-ISAM reader for ACAS-authored files, plus fixture builders for every file slice 1 touches.

## Context

F-B002 pins the relative framing (1024-byte records, no markers, 32-byte space trailer). Indexed files (invoice/value/analysis) are only observed (F-B003) — reader first, writer deferred. Fixtures must be byte-identical between both sides of a parity run.

**Implementation command**: `spec-kitty agent action implement WP02 --agent <name>`

## Subtasks

### T001: Relative read/write

- **Purpose**: Implement read/write per F-B002 with round-trip and golden-file tests.
- **Files**: `crates/acas-common/src/isam/relative.rs`
- **Validation**: Round-trip of the checked-in system.dat golden is byte-identical.

### T002: Indexed reader

- **Purpose**: Decode the indexed header and page structure far enough to iterate records in key order; write F-B005 first.
- **Files**: `crates/acas-common/src/isam/indexed.rs`
- **Validation**: Reader lifts every record from an ACAS-produced invoice.dat.

### T003: Fixture builders

- **Purpose**: Author value/analysis/openitm2 builders; regression-test one record per file.
- **Files**: `fixtures/`
- **Validation**: Fixtures generated and self-checked in tests.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
