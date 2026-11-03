---
work_package_id: WP01
title: Setup-exit wall
dependencies: []
requirement_refs:
- FR-001
- C-004
subtasks:
- T001
- T002
- T003
agent: "codex"
agent_profile: ''
authoritative_surface: reference-ports/rust-acas/harness/, docs/fd-evidence/
execution_mode: code_change
owned_files:
- reference-ports/rust-acas/harness/parity_harness.py
- reference-ports/rust-acas/harness/runs/**
- reference-ports/rust-acas/docs/fd-evidence/**
role: ''
tags: []
---

# Work Package Prompt: WP01 - Setup-exit wall

## Objective

Make the parity harness drive ACAS through SYS002 to a clean 'OK to file' and the system menu, with a persisted reusable system.dat, so every later work package can invoke ACAS non-interactively.

## Context

ACAS re-enters setup whenever scycle is zero (ACAS.cbl:236). cyclea is display-only on the SYS002 screen (sys002.cbl:455) and only advances in xl150 rollover code. Seeding cyclea=1 was not sufficient; screens 1-8 replay and the P-L Data screen-7 'OK to file' refuses to complete. The validator semantics must be read from sys002.cbl, not guessed from transcripts.

**Implementation command**: `spec-kitty agent action implement WP01 --agent <name>`

## Subtasks

### T001: Read the setup gates

- **Purpose**: Enumerate every validation/guard between the SY009 env gate and the menu: ACAS.cbl routing, sys002.cbl screen blocks and validators, xl150 scycle semantics. Record each gate and its accepted values in F-B004.
- **Files**: `reference-ports/rust-acas/docs/fd-evidence/F-B004-setup-gates.md`
- **Validation**: F-B004 exists and names every gate with quoting line references.

### T002: Build the keystroke schedule

- **Purpose**: From T001's gate list, write a scenario keystroke schedule that satisfies each gate deterministically, including the P-L Data screen 7 completion.
- **Files**: `harness/parity_harness.py (scenario setup-clean)`
- **Validation**: Scenario is fully scripted, no manual keys.

### T003: Prove idempotence

- **Purpose**: Run the scenario from a pristine env; assert the transcript tail contains menu text and the persisted system.dat has scycle != 0. Re-run with that file and assert no SYS002 screens appear.
- **Files**: `harness/runs/ golden master`
- **Validation**: Both assertions pass and the golden run is committed.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
