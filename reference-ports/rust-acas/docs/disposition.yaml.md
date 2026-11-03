# Copybook Field Dispositions

Per directive **L2R-005**: every field in every copybook record layout used by a
ported slice must appear here with one of:

- **carry** — ported as-is to Rust (same semantics)
- **rename** — ported with a Rust-idiomatic name; record the mapping here
- **retire** — deliberately not ported; justification required (e.g., padding slack)
- **defer** — port later; enters a ticket
- **absorb** — behavioral content moved into a type-level guarantee (e.g., 88-level
  condition-name becomes an enum variant)

## Format

```yaml
copybook: <file.cpy>
  record: <01-level name>
    fields:
      - name: <COBOL field>
        pic: <PIC clause>
        disposition: carry|rename|retire|defer|absorb
        target: <rust equivalent, if applicable>
        rationale: <required for rename/retire>
```

## Status

No dispositions yet — they accrete as slices are ported, starting with
`wssystem.cob` (system-parameter record, 1024 bytes, fields accreted 2009–2013)
which is the first audit target in phase 1.

## Recorded departures

Non-field departures that the parity gate needs on the record. Each needs a
STATUS.log entry in the mission log as well.

### DP-001 — harness fixtures are flat-framed indexed files (2026-11-03, WP02)

`fixtures/fdinv2_builder.py` authors `invoice/value/analysis.dat` in F-B005
shape B (contiguous records + 32 B space trailer) instead of the shape
GnuCOBOL itself writes (BDB metadata page + leaf pages). ACAS opens them `i-o`
and rewrites in place without changing size, and the invoice bytes after an
`sl055` run are identical to the pre-change run, so the framing is
behavior-preserving for reads. libcob logs three lines per run:

```
BDB0210 …/invoice.dat: metadata page checksum error
BDB0004 fop_read_meta: …/value.dat: unexpected file type or format
BDB0004 fop_read_meta: …/analysis.dat: unexpected file type or format
```

Consequence: harness transcripts carry BDB noise, and any future exit-status
check must not treat BDB0004 as fatal. **Follow-up:** teach the builder to emit
shape A (BDB pages) so the noise disappears; the Rust reader already accepts
both shapes, so no reader change is needed.

### DP-002 — record sizes corrected in the fixture builder (2026-11-03, WP02)

`analysis/value/openitm2` were built at 73/37/100 B. The FDs are 36/66/114
(`fdanal.cob`, `fdval.cob`, `fdoi2.cob`, each re-measured off a GnuCOBOL
write). The old sizes mis-framed every record after the first; fixture sizes
are now pinned by
`crates/acas-common/src/tests/isam_golden.rs::checked_in_fixtures_are_self_consistent`.

### DP-003 — `sl055` pending invoices: preflight instead of post-run warning (2026-11-03, WP04)

COBOL completes the whole extract and only then, at `da040-Close-Files`, sets
`file-status(18)` and displays SL122 for the unprinted/pending invoices it
skipped. Its caller learns the condition *after* the files have been rewritten.

`acas_sales::posting::extract` computes the identical work and returns the
unprinted count; `preflight(&rows)` reports the same condition before any file
state is committed, so the Rust caller can refuse the run without a rollback.
Artifacts therefore stay comparable in both styles:

- the pending fixture's `openitm2` delta is identical to COBOL's (the posted
  invoice is staged, the pending one is not);
- the pending `value.flat` is identical, including the F-B008
  first-invoice-only totals bug;
- `extract` returns 1 and `preflight` returns `Some(1)`.

The departure is only about *when* the caller is told, so no artifact hash
needs a carve-out.
