---
work_package_id: WP11
title: IRS subsystem
dependencies:
- WP08
requirement_refs:
- FR-008
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- T001
- T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-irs/src/**
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-irs/src/**
- reference-ports/rust-acas/harness/scenarios/irs*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP11 - IRS subsystem

## Objective

Port the incomplete-records system with parity scenarios.

## Context

IRS ships sample data and its own manual; use it for fixtures.

**Implementation command**: `spec-kitty agent action implement WP11 --agent <name>`

## Subtasks

### T001: Port irs* programs

- **Purpose**: Parity-gated port using shipped sample data.
- **Files**: `acas-irs/src/`
- **Validation**: Scenarios green.

### T002: IRS suite

- **Purpose**: Full parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
