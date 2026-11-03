---
work_package_id: WP09
title: Purchase ledger
dependencies:
- WP08
requirement_refs:
- FR-008
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- WP09-T001
- WP09-T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-purchase/src/**
create_intent:
- reference-ports/rust-acas/harness/scenarios/pl*.py
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-purchase/src/**
- reference-ports/rust-acas/harness/scenarios/pl*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP09 - Purchase ledger

## Objective

Port the purchase ledger (AP) with parity scenarios mirroring sales.

## Context

Purchase is a subset of sales behavior per the ACAS readme; reuse the sales patterns and dispositions rather than re-deriving.

**Implementation command**: `spec-kitty agent action implement WP09 --agent <name>`

## Subtasks

### WP09-T001: Port pl* programs

- **Purpose**: Parity-gated port.
- **Files**: `acas-purchase/src/`
- **Validation**: Scenarios green.

### WP09-T002: Purchase suite

- **Purpose**: Full parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
