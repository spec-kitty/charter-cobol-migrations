# F-B005 — Indexed ISAM: two on-disk shapes, and which one ACAS produces

Date: 2026-11-03 00:50 UTC // Author: Kat
Basis: GnuCOBOL 3.1.2 (`cobc`) probes compiled against **ACAS's own FDs**
(`copybooks/selinv.cob` + `sales/fdinv2.cob`, `copybooks/selval.cob` +
`copybooks/fdval.cob`, `copybooks/selanal.cob` + `copybooks/fdanal.cob`),
plus the four `sl055-*` harness runs of 2026-11-02.

## Two shapes exist. Which one you get depends on who created the file.

| Shape | How produced | Bytes on disk |
|---|---|---|
| **A. Paged** | GnuCOBOL **creates** the file (`open output`) | 4 KiB block 0 header + 4 KiB pages, records length-prefixed inside pages |
| **B. Flat** | A hand-authored byte stream (our `fixtures/fdinv2_builder.py`) that ACAS subsequently opens `i-o`, `read`s and `rewrite`s | fixed-stride records starting at offset 0, 32-byte space trailer |

Shape B is what all four `sl055-*` runs left on disk (836 B = 6 × 134 + 32,
first 10 bytes `"00001001 \0"` — the key of record 1, no header). Shape A is
what a probe emits for the same FD: 8192 B for two 134-byte records.

So F-B003's "header block + pages" observation was **right about the format**
and the flat fixtures were the anomaly, not the rule. Correction appended to
F-B003. Consequence: the Rust layer must **read both**; it must **write
shape A**, because that is what ACAS-reading-ACAS sees.

## Shape A anatomy (probe: 2 records, key 00000001/00000002)

Block 0 (offset 0, 4096 B), header fields observed:

| Offset | Bytes | Meaning |
|---|---|---|
| 0..3 | `00 00 00 00` | block id 0 |
| 4..7 | `01 00 00 00` | format version 1 |
| 16..19 | `09 00 00 00` | constant 9 |
| 20..23 | `00 10 00 00` | **page size = 4096** |
| 24..27 | `09 00 00 00` | constant 9 |
| 32..35 | `01 00 00 00` | **page count** (6 pages in the 100-record probe) |
| 52..55 | `9c cd de 01` | backend magic |
| 80..83 | `20 00 00 00` | 32 — constant, purpose unknown |

Record size and key length are **not** in the header: they come from the FD
(134/10 for invoice, 66/3 for value, 36/3 for analysis).

Page layout:

| Offset | Bytes | Meaning |
|---|---|---|
| 0..3 | `00 00 00 00` | unused |
| 4..7 | `01 00 00 00` | page type 1 = leaf |
| 8..11 | page number | own id |
| 12..15 | page number | previous id |
| 16..19 | page number | next id (0 = none) |
| 20..21 | u16 count | slot entries |
| 22..   | u16… | slot pointer array, descending |
| … | — | item area, filled downward from page end |

Items are self-delimiting and look like:

```
[ len: u8 ][ 00 01 ][ body: len bytes ]      <- a record, body[0..key_len] IS the key
[ key_len: u8 ][ 00 01 ][ key: key_len B ]   <- separator/high-key, no body
```

Two record items in a 2-record probe sit at page offsets `0x0EC8` and `0x0F64`;
the separators for the same keys sit at `0x0F54` and `0x0FF0`. Both a record
item and a separator carry the *same* leading key, so the discriminator is
`len == record_size` vs `len == key_len`.

### Reader algorithm that works (validated on 100 records)

For every page 1..page_count: scan the page for `[record_size][00][01]`, take
the next `record_size` bytes as the body, key = `body[..key_len]`; collect into
a map keyed by key bytes. Page order is already key order; sorting by key is
idempotent. `fixtures/isam_probe/` reproduces the probes; `regenerate.sh`
rebuilds the committed fixtures under `fixtures/generated/indexed/`.

100-record probe: all 100 keys recovered, ascending, bodies intact, 6 leaf
pages, no root/internal page (the backend keeps leaves only at this size).

## Shape B anatomy

`[ payload ][ 32 B spaces ]`, payload = N × record_size contiguous records,
key at body offset 0. No markers, no header. See F-B002.

## Data at key offset 0

Every ACAS indexed FD puts its key first, so the key is a prefix of the body
record (`invoice-key` 10 B at offset 0, `va-code` 3 B, `pa-code` 3 B). Keys are
therefore free — no key copy table to keep consistent.

## Cross-checks performed

- `sl055.cbl:262` opens `invoice-file value-file analysis-file` `i-o`, then
  `read … next record` (`sl055.cbl:269`) and `rewrite` — dynamic access on
  indexed files, so in-place rewrite of fixed-size paged records is required.
  Paged records are stable-size; rewrite works.
- The 836 B flat file was accepted and rewritten by ACAS with the size and
  first key unchanged in all four runs — flat shape B is genuinely readable by
  the runtime, not just by our builder.
