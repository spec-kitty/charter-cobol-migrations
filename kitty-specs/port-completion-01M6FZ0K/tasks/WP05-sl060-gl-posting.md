---
work_package_id: WP05
title: sl060 GL posting parity
dependencies:
- WP04
requirement_refs:
- FR-004
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- WP05-T001
- WP05-T002
- WP05-T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-sales/src/post.rs
create_intent:
- reference-ports/rust-acas/crates/acas-sales/src/post.rs
- reference-ports/rust-acas/docs/disposition-fdoi2.md
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-sales/src/post.rs
- reference-ports/rust-acas/docs/disposition-fdoi2.md
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP05 - sl060 GL posting parity

## Objective

Port the sl060 posting half: staged open items to sales ledger and general ledger, byte-identical on both sides.

## Context

sl060 consumes the openitm2 staging file that WP04's parity run produces. Ledger and GL record layouts need dispositions before types.

**Implementation command**: `spec-kitty agent action implement WP05 --agent <name>`

## Subtasks

### WP05-T001: fdoi2 dispositions

- **Purpose**: Disposition the staging record fully.
- **Files**: `docs/disposition-fdoi2.md`
- **Validation**: Every field carrying a disposition.

### WP05-T002: Posting logic

- **Purpose**: Implement open-item and GL writes.
- **Files**: `post.rs`
- **Validation**: both ledger files hash-match COBOL.

### WP05-T003: Chain parity

- **Purpose**: Harness scenario running sl055+sl060 chained, comparing both.
- **Files**: `harness/scenarios/`
- **Validation**: Chained scenario green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
