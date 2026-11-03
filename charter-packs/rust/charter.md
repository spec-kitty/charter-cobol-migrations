# Legacy → Rust Porting Charter

**Task category:** porting working legacy-language systems to Rust
**Doctrine pack:** legacy-to-rust-migration v0.1 (this repo's `charter-pack/`)
**Paradigm:** behavioral-parity-first strangler-fig migration

## Project intent

Port ACAS — a complete, GPLv2, COBOL accounting ledger system (Sales AR, Purchase AP,
Nominal GL, Stock/Inventory control, incomplete-records IRS) — into idiomatic Rust,
**preserving every observed feature while deliberately declining to port obsolete
implementation idioms.** The charter pack we author along the way is the deliverable
for the broader task category.

## Governance

```yaml
testing:
  framework: cargo-test
  fixtureas: golden-master byte-exact fixtures from live COBOL runs
  min_coverage: 70   # core ledger logic; screens exempt
  parity_gate: every ported module must pass byte-parity fixture runs before merge

quality:
  linting: clippy --deny warnings
  pr_approvals: 1
  commit_convention: conventional

risk_boundaries:
  - Never silently drop a record-layout field — explicit disposition required
  - Never both restructure logic AND rename in one commit
  - Never port a control-flow idiom whose behavioral content isn't identified
  - Non-goals: new features, UI modernization beyond behavior-parity

performance_targets:
  batch_phase: at least as fast as COBOL harness (measured per posting cycle)
```

## Directives (live from charter-pack)

- L2R-001 through L2R-006 (see `charter-pack/README.md`)

## Available tools

- spec-kitty, git, cargo, cobc (GnuCOBOL), python (fixture tooling)

## Amendment process

Any pitch that changes what "feature-parity" means, or that touches the fixture
corpus, requires a dated charter amendment committed with the change.
