# Slice 1 — current state & immediate next steps (2026-11-02 EOD)

## Landing zone tonight

- `fdinv2_builder.py` (ledger fixture author) — writes byte-correct `invoice.dat`
  for the relative file layout. Verified: 6 rows × 134 B + 32 B trailer; all
  field offsets (ih-date, ih-net comp-3, ih-status, il-pa) decode as designed.
- **Indexed ISAM format discovered to be BDB-variant pages**, not the simple
  relative-file framing. New findings note: see F-B003 (pending).

## Decision made tonight — fixture strategy, revised

**Instead of hand-authoring every file format, let COBOL itself create the
empty tables.**

- `invoice.dat` (indexed) — empty header written by COBOL on first OPEN
  OUTPUT. Our relative-style fixture bytes are useful for the *invoice*-file
  interpretation on the *Rust* side only; COBOL's own output becomes the
  golden master.
- `analysis.dat`, `value.dat` (indexed) — same.
- `openitm2.dat` (sequential) — COBOL also creates on OPEN EXTEND. We never
  fake this; the harness's diff after sl055 runs makes parity real.
- The `fdinv2_builder.py` invoice fixtures stay — they're hand-verified as
  matching the documented PIC/COMP layout, and the harness's role IS to
  prove or break that claim.

## Wrong turn logged in doctrine

Early draft: tried to *precompute* the empty-state files in the builder.
Thanks to the F-B002 framing work we caught that the indexed layout wasn't
pinned. Slice 1 now runs with COBOL-born empty files; fixtures *mutation*
starts from real data.

## Remaining items before first byte-parity run

1. Drive COBOL sl055 in harness (pty) with fixture invoice.dat present. First
   expected outcome: it processes rows and writes openitm2; SL002 likely fires
   during real runs due to COB_FILE trace noise, which we'll accept for now.
2. Confirm openitm2 format (sequential fixed-width) by direct observation.
   → F-B003 evidence note.
3. Author the harness compare that hashes `openitm2.dat` + `value.dat` +
   `analysis.dat` after COBOL vs Python fixture-builder + Rust extract run.
4. Only then does `acas_sales::posting::extract_inv` earn its behaviors (each
   becomes a test case).

## Design rule remembered

> "Bytes pin type; type must earn the byte."

Every byte-slide of the .dat has to pass through a verified F-B entry before
the Rust serde design gets committed to it.
