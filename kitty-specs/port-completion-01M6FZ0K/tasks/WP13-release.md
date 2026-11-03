---
work_package_id: WP13
title: Release artifact + docs
dependencies:
- WP12
requirement_refs:
- FR-010
- NFR-003
planner_estimates: {}
subtasks:
- T001
- T002
agent: "codex"
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/ (build + docs)
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/README.md
- reference-ports/rust-acas/docs/install.md
- reference-ports/rust-acas/Cargo.toml
role: ''
tags: []
---

# Work Package Prompt: WP13 - Release artifact + docs

## Objective

Single release binary, install docs, size and clippy gates.

## Context

NFR-003 bounds size; C-001 forbids FFI in shipped builds.

**Implementation command**: `spec-kitty agent action implement WP13 --agent <name>`

## Subtasks

### T001: Release profile

- **Purpose**: Binary + size gate.
- **Files**: `Cargo.toml`
- **Validation**: Release build under 50 MB.

### T002: Install docs

- **Purpose**: Install and first-run documentation.
- **Files**: `docs/install.md`
- **Validation**: Docs reviewed against a clean-host run.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
