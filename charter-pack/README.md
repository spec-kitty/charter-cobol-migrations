# Legacy → Rust Migration Charter Pack

A Spec Kitty doctrine pack for the task category **"port a working legacy-language system to Rust."**
Developed against ACAS (Applewood Computers Accounting System), designed to generalize to any
COBOL/CICS/Fortran/Pascal → Rust migration where feature-parity matters and idiom-parity does not (only behavior-parity does).

## Load this pack when

- You are porting a *real, previously-executable* legacy codebase to Rust.
- The source system is the spec of record — there are no trustworthy written requirements.
- You must preserve observable behavior while retiring obsolete implementation idioms.

## Core doctrine

| # | Directive | Severity | Intent |
|---|-----------|----------|--------|
| L2R-001 | **Characterize before you translate** — no `rust-acas` module exists without golden-masters of its COBOL counterpart's observable behavior. | error | Behavior is data, not prose. Capture it first. |
| L2R-002 | **The source system is the executable spec.** | error | No inventing requirements from "what it probably does." |
| L2R-003 | **Features are obligations; idioms are liabilities.** Port `EVALUATE-AS-DISPATCH` as match statements; *don't* port fall-through paragraphs. | warn | Distinguish requirement from fossil at every port decision. |
| L2R-004 | **Never both rename *and* restructure in a single commit.** Structure-shifts and name-shifts interleave; they don't coincide. | warn | Bisectability over elegance. |
| L2R-005 | **Every record-layout field gets a disposition entry:** carry / rename / retire / defer. Nothing silent. | error | Data migration is where old systems keep their secrets. |
| L2R-006 | **If the Rust port is *cleaner* than COBOL, suspect you've lost a behavior.** | info | Clean code on an old spec usually means thin coverage. |

## Tactics

- `golden-master-characterization` — Run the COBOL program under controlled input, snapshot outputs (screens, reports, ISAM diffs) and store as byte-exact test fixtures.
- `slice-with-posting-edge` — Port one workflow end-to-end at a time (e.g., *Sales Ledger posting → GL*), not one module at a time. Preserves the transactional edges where behavior lives.
- `idiom-fossil-audit` — For each ported construct, record the COBOL idiom, its behavioral content, the Rust idiom chosen. The audit trail is how we prove nothing was silently dropped.
- `strangler-fig-boundary` — COBOL and Rust halves share files/IPC until a slice is fully strangled; parity harness tests across the boundary.
- `88-level-decision-tree` — COBOL `88`-level condition-names become explicit Rust enums or validated newtypes, never raw ints.
- `late-fail-detection` *(learned from ACAS sl055)* — Legacy code often detects
  the failure condition *after* doing half the work, then warns and pauses.
  The suspicion rule L2R-006 applies doubly: don't port the half-done state.
  Pre-flight the validation, return a typed error. Behavior at ledger-level
  preserved; at temp-file-level deliberately not.
- `file-status-slot-table` *(learned from ACAS)* — `File-Status(N)` array slots
  checked by number become an `enum FileStatusSlot` with stable discriminants.
  The `88` condition-names on those slots become enum variants, not mappings.

## Worked-example catalog (grows as slices port)

| Date | How found | Copybook/source | Directive exercised |
|---|---|---|---|
| 2026-11-02 | GnuCOBOL boot build | `copybooks/wsfnctn.cob` | L2R-003 — signed RELATIVE KEY that was never actually negative |
| 2026-11-02 | sl055 reading | `fdinv2.cob` invoice-date | L2R-005 — 17/05/13 5-byte filler accretion in file layout |
| 2026-11-02 | sl055 reading | da010-Read-Loop flow | L2R-006 — SL122 late-fail skipped *after* the extract work |
| 2026-11-02 | harness drive of SYS002 | `common/sys002.cbl:455` | L2R-001 — Current Cycle `cyclea` is PIC 99 on screen 1; subagent found valid-path only after inspecting validation code |
| 2026-11-02 | integer-of-date decode | `maps04.cbl` comment | L2R-005 → F-B001 evidence kind; datasheet-level claim pinned via bytes before type layer trusts it |

## Evidence as doctrine

`F-B001`-style entries (worked bytes → epoch mapping) are pinned in
`rust-acas/docs/fd-evidence/`. Each is a tiny self-contained proof ("this
offset in this fixture decodes as this calendar date via this formula"). The
pack's expectation: when a behavior is encountered that's load-bearing (dates,
money, ISAM framing), the bytes get observed BEFORE the type gets authored.



## Styleguides (both ends)

- `cobol-reading-notes-styleguide` — How to write reading-notes on legacy COBOL so later porters can retrace decisions.
- `rust-migration-target-styleguide` — `no_std`-unfriendly ISAM decoupling, domain types over `PIC X(n)` carry-overs, explicit decimal/fixed-point strategy (`rust_decimal` vs bignum).

## Procedures

1. `establish-parity-harness` — Before any port: build COBOL binary + snapshot fixture run, confirm reproducibility.
2. `port-slice` — Characterize → structure map → Rust shape → parity assertion → dispose of COBOL for that slice.
3. `disposition-copybooks` — Every copybook/record-layout filed in `disposition.yaml` before its downstream programs port.
4. `retro-port-audit` — After each subsystem: diff behavior inventory against COBOL inventory; anything missing gets a disposition entry or a ticket.

## Reference corpus

- `references/acas-autopsy.md` — Domain model, module map, goto-count, copybook oddities (2009–2013 file-layout folklore).
- `references/charter-interview-answers.yaml` — The interview responses that seeded this pack.
- `references/parity-harness-howto.md` — Building the characterization harness step-by-step.

- `references/fd-evidence/` — Field-evidence notes pinning observed bytes to Rust type decisions (e.g., F-B001 date-epoch 1600-12-31).
