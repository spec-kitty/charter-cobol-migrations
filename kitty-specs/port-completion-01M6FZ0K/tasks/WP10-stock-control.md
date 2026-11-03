---
work_package_id: WP10
title: Stock control
dependencies:
- WP08
requirement_refs:
- FR-008
subtasks:
- T001
- T002
agent: "codex"
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-stock/src/
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-stock/src/**
- reference-ports/rust-acas/harness/scenarios/st*.py
role: ''
tags: []
---

# Work Package Prompt: WP10 - Stock control

## Objective

Port stock control with parity scenarios.

## Context

StockMT is the largest program (3478 lines); expect to split it by section.

**Implementation command**: `spec-kitty agent action implement WP10 --agent <name>`

## Subtasks

### T001: Port st* programs

- **Purpose**: Parity-gated port, stockMT split by section.
- **Files**: `acas-stock/src/`
- **Validation**: Scenarios green.

### T002: Stock suite

- **Purpose**: Full parity suite.
- **Files**: `harness/`
- **Validation**: Suite green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
