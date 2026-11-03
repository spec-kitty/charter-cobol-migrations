---
work_package_id: WP10
title: Stock control
dependencies:
- WP08
requirement_refs:
- FR-008
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- WP10-T001
- WP10-T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-stock/src/**
create_intent:
- reference-ports/rust-acas/harness/scenarios/st*.py
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-stock/src/**
- reference-ports/rust-acas/harness/scenarios/st*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP10 - Stock control

## Objective

Port stock control with parity scenarios.

## Context

StockMT is the largest program (3478 lines); expect to split it by section.

**Implementation command**: `spec-kitty agent action implement WP10 --agent <name>`

## Subtasks

### WP10-T001: Port st* programs

- **Purpose**: Parity-gated port, stockMT split by section.
- **Files**: `acas-stock/src/`
- **Validation**: Scenarios green.

### WP10-T002: Stock suite

- **Purpose**: Full parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
