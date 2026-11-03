---
work_package_id: WP09
title: Purchase ledger
dependencies:
- WP08
requirement_refs:
- FR-008
planner_estimates: {}
subtasks:
- T001
- T002
agent: "codex"
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-purchase/src/
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-purchase/src/**
- reference-ports/rust-acas/harness/scenarios/pl*.py
role: ''
tags: []
---

# Work Package Prompt: WP09 - Purchase ledger

## Objective

Port the purchase ledger (AP) with parity scenarios mirroring sales.

## Context

Purchase is a subset of sales behavior per the ACAS readme; reuse the sales patterns and dispositions rather than re-deriving.

**Implementation command**: `spec-kitty agent action implement WP09 --agent <name>`

## Subtasks

### T001: Port pl* programs

- **Purpose**: Parity-gated port.
- **Files**: `acas-purchase/src/`
- **Validation**: Scenarios green.

### T002: Purchase suite

- **Purpose**: Full parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
