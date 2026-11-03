---
work_package_id: WP14
title: Doctrine graduation + go/java slices
dependencies:
- WP05
requirement_refs:
- FR-011
planner_estimates: {}
subtasks:
- T001
- T002
- T003
agent: "codex"
agent_profile: ''
authoritative_surface: charter-packs/, reference-ports/go-acas/, reference-ports/java-acas/
execution_mode: code_change
owned_files:
- charter-packs/**
- reference-ports/go-acas/**
- reference-ports/java-acas/**
role: ''
tags: []
---

# Work Package Prompt: WP14 - Doctrine graduation + go/java slices

## Objective

Graduate the rust pack with tactic pages and evidence index; build go and java reference slices on the same fixtures.

## Context

Drafts in go/ and java/ name their graduation conditions. Packs graduate on evidence, not prose.

**Implementation command**: `spec-kitty agent action implement WP14 --agent <name>`

## Subtasks

### T001: Rust pack graduation

- **Purpose**: Full tactic pages + worked-example index + GRADUATED marker.
- **Files**: `charter-packs/rust/`
- **Validation**: Every directive has a graduated example.

### T002: Go slice

- **Purpose**: fdinv2+sl055 reference slice passing fixtures.
- **Files**: `reference-ports/go-acas/`
- **Validation**: Slice parity green.

### T003: Java slice

- **Purpose**: Same for Java with the BigDecimal study (F-Java001).
- **Files**: `reference-ports/java-acas/`
- **Validation**: Slice parity green.

## Completion criteria

- Parity gate green (artifact hashes match) or the departure is documented and logged.
- `cargo test --workspace` and `cargo clippy -- --deny warnings` clean.
- STATUS.log entry for any plan deviation.
