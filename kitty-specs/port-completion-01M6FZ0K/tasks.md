# Tasks — port-completion-01M6FZ0K

Dependency-ordered work packages. Each WP owns a disjoint file surface; parity gate per WP.

> Detailed prompts live in `tasks/WP*.md`.

## WP01 — Setup-exit wall

**Depends on**: —  
**Requirement refs**:   
**Prompt**: `tasks/WP01-setup-exit-wall.md`

Make the parity harness drive ACAS through SYS002 to a clean 'OK to file' and the system menu, with a persisted reusable system.dat, so every later work package can invoke ACAS non-interactively.

**Subtasks**: T001: Read the setup gates; T002: Build the keystroke schedule; T003: Prove idempotence

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP02 — ISAM foundation + fixtures

**Depends on**: WP01  
**Requirement refs**:   
**Prompt**: `tasks/WP02-isam-foundation.md`

Implement relative-file read/write to the F-B002 layout and an indexed-ISAM reader for ACAS-authored files, plus fixture builders for every file slice 1 touches.

**Subtasks**: T001: Relative read/write; T002: Indexed reader; T003: Fixture builders

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP03 — fdinv2 full field surface

**Depends on**: WP02  
**Requirement refs**:   
**Prompt**: `tasks/WP03-fdinv2-surface.md`

Complete every fdinv2 field as a dispositioned, serde-pinned type with byte-exact round-trip, including the comp-3 money fields and all status bytes.

**Subtasks**: T001: Money fields; T002: Status bytes + flags; T003: Full-record round-trip

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP04 — sl055 extract parity

**Depends on**: WP02, WP03  
**Requirement refs**:   
**Prompt**: `tasks/WP04-sl055-extract.md`

Implement the ten documented sl055 extract rules so clean, credit-note and pending fixtures produce identical openitm2 and value artifacts on both sides.

**Subtasks**: T001: Line analysis path; T002: Header extract + specials; T003: Pending preflight + departure note

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP05 — sl060 GL posting parity

**Depends on**: WP04  
**Requirement refs**:   
**Prompt**: `tasks/WP05-sl060-gl-posting.md`

Port the sl060 posting half: staged open items to sales ledger and general ledger, byte-identical on both sides.

**Subtasks**: T001: fdoi2 dispositions; T002: Posting logic; T003: Chain parity

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP06 — SystemFile type

**Depends on**: WP01  
**Requirement refs**:   
**Prompt**: `tasks/WP06-system-file-type.md`

Full wssystem disposition plus a byte-exact SystemFile type so config reads/writes in later ledgers are safe.

**Subtasks**: T001: Dispositions; T002: Struct + round-trip

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP07 — Remaining sales programs

**Depends on**: WP05  
**Requirement refs**:   
**Prompt**: `tasks/WP07-sales-remaining.md`

Port the remaining sales programs (sl010..sl960) in dependency order, each with a parity scenario.

**Subtasks**: T001: Map the dependency order; T002: Port in order; T003: Sales suite run

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP08 — Nominal ledger (general/)

**Depends on**: WP06  
**Requirement refs**:   
**Prompt**: `tasks/WP08-nominal-ledger.md`

Port the general/nominal ledger end to end with parity scenarios.

**Subtasks**: T001: Accept posted entries; T002: Port GL programs; T003: GL suite

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP09 — Purchase ledger

**Depends on**: WP08  
**Requirement refs**:   
**Prompt**: `tasks/WP09-purchase-ledger.md`

Port the purchase ledger (AP) with parity scenarios mirroring sales.

**Subtasks**: T001: Port pl* programs; T002: Purchase suite

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP10 — Stock control

**Depends on**: WP08  
**Requirement refs**:   
**Prompt**: `tasks/WP10-stock-control.md`

Port stock control with parity scenarios.

**Subtasks**: T001: Port st* programs; T002: Stock suite

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP11 — IRS subsystem

**Depends on**: WP08  
**Requirement refs**:   
**Prompt**: `tasks/WP11-irs.md`

Port the incomplete-records system with parity scenarios.

**Subtasks**: T001: Port irs* programs; T002: IRS suite

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP12 — Screen layer + session parity

**Depends on**: WP07, WP09, WP10  
**Requirement refs**:   
**Prompt**: `tasks/WP12-screens.md`

Port the interactive screens and prove a scripted setup→invoice→post→report session against the COBOL transcript.

**Subtasks**: T001: Screen rendering; T002: Session parity

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP13 — Release artifact + docs

**Depends on**: WP12  
**Requirement refs**:   
**Prompt**: `tasks/WP13-release.md`

Single release binary, install docs, size and clippy gates.

**Subtasks**: T001: Release profile; T002: Install docs

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.

## WP14 — Doctrine graduation + go/java slices

**Depends on**: WP05  
**Requirement refs**:   
**Prompt**: `tasks/WP14-doctrine-graduation.md`

Graduate the rust pack with tactic pages and evidence index; build go and java reference slices on the same fixtures.

**Subtasks**: T001: Rust pack graduation; T002: Go slice; T003: Java slice

**Done when**: parity gate green (or departure documented + logged), tests and clippy clean, STATUS.log updated.
