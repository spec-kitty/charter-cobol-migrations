---
work_package_id: WP07
title: Remaining sales programs
dependencies:
- WP05
requirement_refs:
- FR-008
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- WP07-T001
- WP07-T002
- WP07-T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-sales/src/**
create_intent:
- reference-ports/rust-acas/harness/scenarios/sl*.py
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-sales/src/**
- reference-ports/rust-acas/harness/scenarios/sl*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP07 - Remaining sales programs

## Objective

Port the remaining sales programs (sl010..sl960) in dependency order, each with a parity scenario.

## Context

Slice 1 established the pattern: characterize, disposition, port, parity. Order follows data dependencies from sl010 outward.

**Implementation command**: `spec-kitty agent action implement WP07 --agent <name>`

## Subtasks

### WP07-T001: Map the dependency order

- **Purpose**: Record which programs consume which files; sequence them.
- **Files**: `STATUS.log`
- **Validation**: Ordered list committed.

### WP07-T002: Port in order

- **Purpose**: One program per iteration, parity-gated.
- **Files**: `crates/acas-sales/src/`
- **Validation**: Each program's scenario green.

### WP07-T003: Sales suite run

- **Purpose**: Full sales parity suite.
- **Files**: `harness/`
- **Validation**: Suite green under NFR-001 runtime.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
