# Phase 0 Research — port-completion

Evidence-first. Every decision below cites an `F-Bnnn` note, a source file, or an observed
golden master. Unresolved items are listed last and feed WP scoping, not guesses.

## D1 — Test harness: pty-driven, artifact-hash parity

**Decision:** keep the existing Python pty harness; every scenario pre-stages inputs, runs
one side, snapshots output artifacts and transcript, and (in parity mode) runs the other
side over identical inputs and hash-compares.

**Evidence:** `harness/parity_harness.py` already does staging + capture + `diff`
(developed and exercised this session: boot, setup, sl055 attempts). Golden masters exist
under `harness/runs/`.

**Rationale:** ACAS is curses-interactive; there is no batch CLI. A pty with a scripted
keystroke schedule is the only way to exercise it without modifying sources.

## D2 — Setup wall: scycle/cyclea and the SYS002 gates

**Finding:** `ACAS.cbl:236` routes to `call-system-setup` whenever `scycle = 0`
(`scycle` REDEFINES `cyclea`, `wssystem.cob:46-47`). SYS002's "Current Cycle" cell is a
display-only template item (`.kps` `using cyclea`, `sys002.cbl:455`); `cyclea` advances
only in quarterly reset code (`xl150.cbl:1034-1065`).

**Consequence:** seeding `cyclea = 1` alone is not sufficient — the harness run still
re-enters SYS002, so something else in the record is validated too (observed: P-L Data
screen 7 refuses to complete; screens 1-8 replay).

**Next action (WP1):** read the SYS002 screen-7 "OK to file" validator and the field
validators for screens 1-8; build a keystroke schedule that satisfies each; persist the
resulting `system.dat` as a golden fixture; write `F-B004`.

## D3 — Relative-file framing (settled)

`F-B002`: records at `1024 × (rrn-1)`, no markers, 32-byte space trailer. `system.dat`
4128 B = 4 records + trailer. Field offsets verified (run-date at +19, usera at +31).

## D4 — Date epoch (settled)

`F-B001`: COBOL `integer-of-date`; 2026-11-02 = 155534. Implemented in
`acas_common::CobolDate` with pinning tests.

## D5 — Invoice record (settled)

`fdinv2.cob`: 134-byte record, header/line dual variant on `item-nos` (0 = header).
Dispositions complete in `docs/disposition-fdinv2.md`; `InvoiceRow` round-trips bytes
with tests. Field offsets confirmed by hand-parse and fixture self-check.

## D6 — Indexed ISAM (open)

`F-B003`: relative-file fixtures are not sufficient — `invoice.dat`, `value.dat`,
`analysis.dat` are `ORGANIZATION INDEXED` and GnuCOBOL writes a paged BDB-style file
(4 KiB header block observed from a 2-record probe).

**Decision:** treat ACAS as the *author* of indexed files. Rust reads them; writes are
compared on the sequential `openitm2` handoff first. A full indexed writer is deferred
until a slice needs it (log to STATUS.log when it bites).

**Next action:** F-B005 — decode the indexed header + page structure far enough to read
records with keys; add `acas_common::isam::indexed::Reader`.

## D7 — Money representation (open, decision deferred to fixture study)

COBOL money fields are `s9(7)v99 COMP-3` (packed decimal, 5 bytes). Options: i64 cents
(simple, exact for these scales), `rust_decimal`, or BCD. **Decision rule:** pick i64
cents unless the F-B006 rounding study shows a scale/rounding case that breaks it — the
field widths cap at 7+2 digits, so overflow is not the risk; truncation semantics are.

## D8 — Domain/storage split

Domain functions take in-memory rows (`Vec<InvoiceRow>`, `ExtractRun`) and never touch
files; codecs live in `acas-common`. This makes the parity harness drive identical inputs
into both sides without a shared storage layer, and keeps tests fast.

## D9 — Screens last

Curses output includes timing-variable escapes. Screens are ported after all batch logic
and compared on stripped text + field order, never raw bytes.

## D10 — Doctrine growth is part of the work

Each new idiom class gets a tactic/worked-example row *before* the port code for it
(L2R-003). Pack graduation (WP14) is satisfied by the evidence index accumulated, not by
new prose.

## Open questions / risks

1. Which SYS002 fields the screen-7 validator actually requires (WP1, blocking).
2. Whether the indexed reader can be limited to sequential-in-key-order (likely yes;
   ACAS uses sequential access patterns).
3. COMP-3 truncation vs rounding on half-cent products (F-B006 fixture study).
4. `xl150` quarterly rollover behavior — must be ported for long-run parity, but after
   the posting slices.
5. Screen text of ~40 interactive programs is a large tail; schedule after batch parity.
