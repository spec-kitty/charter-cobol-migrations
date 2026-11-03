---
work_package_id: WP12
title: Screen layer + session parity
dependencies:
- WP07
- WP09
- WP10
requirement_refs:
- FR-009
subtasks:
- T001
- T002
history: []
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/crates/acas-ui/src/
create_intent: []
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/crates/acas-ui/src/**
- reference-ports/rust-acas/harness/scenarios/session*.py
role: ''
tags: []
tracker_refs: []
---

# Work Package Prompt: WP12 - Screen layer + session parity

## Objective

Port the interactive screens and prove a scripted setup→invoice→post→report session against the COBOL transcript.

## Context

Compare stripped text and field order, never raw escape bytes.

**Implementation command**: `spec-kitty agent action implement WP12 --agent <name>`

## Subtasks

### T001: Screen rendering

- **Purpose**: Render each screen's static text and field order.
- **Files**: `acas-ui/src/`
- **Validation**: Stripped-text equality per screen.

### T002: Session parity

- **Purpose**: Full scripted session parity run.
- **Files**: `harness/scenarios/session*.py`
- **Validation**: Transcript matches line for line.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
