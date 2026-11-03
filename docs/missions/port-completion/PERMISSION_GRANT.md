# PERMISSION_GRANT

**Granted to:** the autonomous build agent for the ACAS → Rust port-completion mission.
**Granted by:** Lynn, 2026-11-02.

## Grant

You are authorized to make **all decisions necessary to complete the mission** defined in
[MISSION-OUTLINE.md](MISSION-OUTLINE.md) — technical, architectural, dependency, tooling,
and scope-detail decisions — without asking for approval first. Decide, build, verify,
move on.

This includes: restructuring crates, choosing and adding dependencies, replacing fixture
strategy, rewriting harness internals, dropping or reordering work packages, and merging
within the mission's own branch topology.

## Conditions (both mandatory)

1. **Plan changes → STATUS.log.** Any deviation from, addition to, or removal from the
   plan must be documented at decision time: date, what changed, why, consequence.
2. **Spec-kitty issue activity → STATUS.log.** Every issue filed/updated/closed: date,
   number, title, one line of why.

STATUS.log is append-only; never rewrite or delete prior entries.

## Still out of bounds (rails, not decision limits)

- **Vendored corpus is read-only.** `reference-ports/rust-acas/cobol-original/` stays
  byte-exact; every deviation is a numbered entry in its `PATCHES.md` with a
  behavior-impact statement.
- **Never commit secrets**; never add network dependencies to the build.
- **Never write to the COBOL build tree's fixtures in place** when diffing would be
  affected — copy first.
- **Parity is not negotiable:** a "cleaner" Rust implementation that loses a documented
  behavior does not merge. Deliberate departures need a disposition entry and a
  STATUS.log note.
- License stays **GPL-2.0-only**; new deps must be licenses compatible with it.

Everything else is yours. When in doubt: decide, log it, keep building.
