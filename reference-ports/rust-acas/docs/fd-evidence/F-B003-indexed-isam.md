# F-B003 — Indexed ISAM format (observed, slice-1 blocking)

Date: 2026-11-02 21:15 UTC // Author: Kat

## Observation

`invoice.dat`/`value.dat`/`analysis.dat` are `ORGANIZATION INDEXED` in COBOL.
The bytes on disk GnuCOBOL 3.1.2 produces are **not** the simple relative
framing covered in F-B002. A 2-record probe (struct 8+126 bytes, key at
offset 0..8) produced 8192 bytes total — a 4 KiB "block-0" header followed by
space-padded record bodies in 4 KiB pages. Layout family is **BDB-style paged
records** (libcob's isam9x backend).

We did NOT reverse-engineer the whole format tonight; running one hand-built
byte pattern instead of asking the compiler tests is the specific way to
ship the Rust isam backend. Instead we have:

```
  [0 .. 4095]    header block
                 +0  16 B header  (file size, page size, record size)
                 +16 196 B root   (free-page list pointers, etc.)
  [4096 .. 8191] page 1 (first data page)
                 records in insert order with control bytes we haven't
                 fully decoded yet
```

## Slice 1 consequence

Hand-authoring coerce **invoice.dat** is not viable. Instead:
- **ACAS authors it** (sl010 invoice entry; harness drives this once and
  preserves the result as the fixture).
- **Rust reads its own copy**; byte-diffing happens at *postings* (openitm2 +
  value-file content), not at the invoice register itself.

That's the *real* strangler-fig shape: the file ACAS reads opaque, the file
ACAS writes observable. Slice 1's "first parity" will show up in the
openitm2 staging stream (sequential, fixed-record, trivial).

## Investigation rules that held tonight

1. Bytes pin types — but the reversed direction also holds: reading ACAS
   sources for incoming behaviors *expected* the file to be pickier than it
   is. (sl055 rewrites `invoice-record` mid-post with `il-update = "Z"`;
   the format must support in-place rewrite — and it does, indexed + ISAM
   records are stable-sized fixed blocks.)
2. ACAS.cbl re-enters setup whenever `scycle = 0`, regardless of other crit:
   SYS002 screen-1 cell "Current Cycle" is **display-only**; cyclea advances
   only from xl150 (quarterly/weekly rollover). Slice-1 harness learned this
   the hard way. We seed system.dat with cyclea=1 directly.
3. The P-L Data screen 7 validator is what trapped the subagent: its final
   "OK to file" prompt auto-completes only when a specific subset of prior
   fields was left at defaults. Documenting the accepted shape is slice-1's
   next notebook entry.

## Correction 2026-11-03 (F-B005)

The block-0/page structure below is **accurate**; what was missing is that it
is what GnuCOBOL writes when *it* creates the file. The 2026-11-02 fixture
files are flat (no header, records from offset 0, 32 B trailer) because our
builder authored them and ACAS merely opened `i-o` and rewrote in place.
Anyone reading `invoice.dat` from a harness run is looking at the flat shape.
Read both; write paged. Details, offsets and discriminator: F-B005.
