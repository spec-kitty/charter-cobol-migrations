---
work_package_id: WP08
title: Nominal ledger (general/)
dependencies:
- WP06
requirement_refs:
- FR-008
- FR-009
subtasks:
- T001
- T002
- T003
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-gl/src/
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-gl/src/**
- reference-ports/rust-acas/harness/scenarios/gl*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP08 - Nominal ledger (general/)

## Objective

Port the general/nominal ledger end to end with parity scenarios.

## Context

GL is the posting target for every other ledger; it must accept sl060 writes early, then cover its own programs (gl030 etc.).

**Implementation command**: `spec-kitty agent action implement WP08 --agent <name>`

## Subtasks

### T001: Accept posted entries

- **Purpose**: Ensure GL records round-trip writes from WP05.
- **Files**: `acas-gl/src/`
- **Validation**: sl060 output applied without diff.

### T002: Port GL programs

- **Purpose**: Port remaining gl* programs parity-gated.
- **Files**: `acas-gl/src/`
- **Validation**: Scenarios green.

### T003: GL suite

- **Purpose**: Run the GL parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
