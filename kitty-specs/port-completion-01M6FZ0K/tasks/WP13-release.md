---
work_package_id: WP13
title: Release artifact + docs
dependencies:
- WP12
requirement_refs:
- C-001
- C-002
- FR-010
- NFR-002
- NFR-003
planning_base_branch: feature/port-completion
merge_target_branch: feature/port-completion
branch_strategy: Planning artifacts for this mission were generated on feature/port-completion. During /spec-kitty.implement this WP may branch from a dependency-specific base, but completed changes must merge back into feature/port-completion unless the human explicitly redirects the landing branch.
subtasks:
- WP13-T001
- WP13-T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/README.md
create_intent:
- reference-ports/rust-acas/docs/install.md
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/README.md
- reference-ports/rust-acas/docs/install.md
- reference-ports/rust-acas/Cargo.toml
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP13 - Release artifact + docs

## Objective

Single release binary, install docs, size and clippy gates.

## Context

NFR-003 bounds size; C-001 forbids FFI in shipped builds.

**Implementation command**: `spec-kitty agent action implement WP13 --agent <name>`

## Subtasks

### WP13-T001: Release profile

- **Purpose**: Binary + size gate.
- **Files**: `Cargo.toml`
- **Validation**: Release build under 50 MB.

### WP13-T002: Install docs

- **Purpose**: Install and first-run documentation.
- **Files**: `docs/install.md`
- **Validation**: Docs reviewed against a clean-host run.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
