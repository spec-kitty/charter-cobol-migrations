# Disposition ledger — fdinv2.cob (invoice file records)

Slice 1 target. Created 2026-11-02 alongside `acas-sales/src/invoice.rs` v0.
Every row below **landed** under WP03 (2026-11-03); offsets are the ones
GnuCOBOL actually writes, re-measured in `docs/fd-evidence/F-B006`.

## The physical fact that frames all of this

`invoice-header` is a **137-byte** overlay on a **134-byte** FD record. ACAS
writes `move sinvoice-header to invoice-record`, so three trailing bytes are
truncated on every write (F-B006). The Rust type therefore carries fields that
are *not* in the 134-byte image, and says so per field. Round-tripping a
134-byte record is byte-exact; a value set on a truncated field survives only
in memory, exactly as in COBOL.

## invoice-record (the raw FD, 134 bytes)

**Disposition: absorb.** Physical layout retained on disk exactly; in Rust this
collapses into a serde framing over `InvoiceRow::Header`/`InvoiceRow::Line`.
The dual-purpose physical record (`item-nos`: 0 = header / 1.. = line) is
carried at the wire level without being copied into the type system as scalar
polling. `InvoiceLineNo::{Header,Line(u8)}` is where it lives.

| COBOL field | PIC | Disposition | Rust landing site | Rationale |
|---|---|---|---|---|
| invoice-key | group | absorb | tuple on both variants | key layout preserved; sub-fields carry to right variant |
| invoice-nos | 9(8) | carry | `InvoiceNumber(u32)` | bounded range, format-preserved as zero-padded string on wire |
| invoice-let | x | carry | `InvoiceLetter(u8)` | ASCII byte; N-M disambiguator for manual dup invoices |
| item-nos | binary-char | absorb | `InvoiceLineNo` enum | 88-level dispatch becomes enum |
| invoice-customer | x(7) | carry | `CustomerKey([u8; 7])` | raw bytes; never validated to ASCII |
| invoice-date | binary-long | carry | `CobolDate(i32)` days-since-1900 | wrapper newtype; calendar conversion only at report time |
| filler (10B) @21 | x(10) | carry (was "retire") | `order: [u8; 10]` | F-B006: it is `ih-order`, a live field, not pad |
| invoice-type | 9 | carry | `InvoiceType` enum | {Invoice=1, CreditNote=3, Proforma=4, Other(u8)} |
| filler (10B) + (92B) | x(102) | carry (was "retire") | `ref: [u8;10]` + the header overlay | F-B006: bytes 32..42 are `ih-ref`; 42..134 are the sub-prime |

## invoice-header (137-byte overlay over the 134-byte record)

| COBOL field | PIC | Bytes | Disposition | Rust landing site |
|---|---|---|---|---|
| ih-invoice | 9(8) | 8 | carry | `invoice_nos` |
| ih-letter | x | 1 | carry | `invoice_let` |
| ih-test | binary-char | 1 | absorb | `InvoiceLineNo::Header` invariant (0 asserted on encode) |
| ih-customer | x(6) + 9 | 7 | carry | `CustomerKey` + `CustomerKey::nos()` / `::check_digit()` views |
| ih-date | binary-long | 4 | carry | `CobolDate` |
| ih-order | x(10) | 10 | carry | `order: [u8; 10]` (spaces = no order) |
| ih-type | 9 | 1 | carry | `InvoiceType` |
| ih-ref | x(10) | 10 | carry | `ref: [u8; 10]` |
| ih-description | x(32) | 32 | carry | `description: [u8; 32]`; trim/pad behaviours stay at the call site |
| ih-fig ×8 | comp-3 s9(7)v99 | 5 each | carry | `PackedMoney` per field (raw 5 bytes + `cents()`), nibble-exact |
| ih-status | x + 88s | 1 | absorb → enum | `HeaderStatus`: Pending, Invoiced, Applied(z\|Z), Other(u8) — exact byte kept |
| ih-status-P L C A I | x ×5 | 5 | carry | `[StatusFlag; 5]`, byte space = truth, `is_set()` view only |
| ih-lines | binary-char | 1 | carry | `u8` |
| ih-deduct-days | binary-char | 1 | carry | `u8` |
| ih-deduct-amt / -vat | 999v99 comp | 4 + 4 | carry | `CompAmount` (4 raw BE bytes + `hundredths()`) |
| ih-days | binary-char | 1 | carry | `u8` |
| ih-cr | binary-long | 4 on disk → **3 persisted** | carry | `CobolDate`; DP-003 |
| ih-day-book-flag | x (+88 B) | 1 | carry, memory-only | `day_book_flag: u8`, `day_booked()`; DP-003 |
| ih-update | x (+88 z/Z) | 1 | carry, memory-only | `update: u8`, `analysed()`; DP-003 |

## invoice-line (80-byte overlay; bytes 80..134 not covered)

| COBOL field | PIC | Bytes | Disposition | Rust landing site |
|---|---|---|---|---|
| il-invoice / il-letter / il-line | 9(8) / x / binary-char | 10 | carry | `invoice_nos`, `invoice_let`, `line_no` |
| il-product | x(13) | 13 | carry | `product: [u8; 13]` — "+1 17/5/13" fossil extension, current width carried |
| il-pa | xx | 2 | carry | `pa: [u8; 2]` product-analysis key |
| il-qty | binary-short | 2 | carry | `qty: i16` (signed storage; ACAS uses positives) |
| il-type | x | 1 | carry | `line_type: u8` — digit char, `is_credit()` = `b'3'` |
| il-description | x(32) | 32 | carry | `description: [u8; 32]` |
| il-net / il-unit / il-vat | s9(7)v99 comp-3 | 5 each | carry | `PackedMoney` |
| il-discount | 99v99 comp | 2 | carry | `CompRate` (2 raw BE bytes + `hundredths()`) |
| il-vat-code | 9 | 1 | carry | `vat_code: u8` |
| il-update | x (+88 z/Z) | 1 | carry | `update: u8`, `analysed()` |
| filler | x | 1 | carry | `filler: u8` |
| — | — | 54 | carry (new) | `tail: [u8; 54]` — outside the overlay, but inside the frame |

## Status byte conventions (the 88 confusion point everyone hits)

`ih-status` is the **tri-state display flag**: P=pending, I=invoiced,
z/Z=applied. The five `ih-status-{P,L,C,A,I}` are independent single-letter
columns for pick-list/invoice-printed/cleared/applied/item-deleted. A single
struct with boolean semantics is the idiom to absorb, but on file they must
round-trip as the SAME byte characters — byte-parity wins over type-safety, so
the bytes stay raw and the semantics live in accessors.

## Departures from the copybook's own comments

| DP | What the comment claims | What GnuCOBOL does | Handling |
|---|---|---|---|
| DP-003 | `ih-sub-prime` is 92 B; `comp` for 999v99 is unspecified | sub-prime is 95 B over 2×4-byte comps; header is 137 B over a 134 B record | header modelled at 137, encoded to 134, truncation carried explicitly |

### DP-003 detail

- Header gains fields that are not persisted. Modelled, doc'd, decoded as
  space — not dropped, because `sl055` sets them and a future widening of the
  FD must find them present.
- `ih-cr` is encoded as its low 3 bytes. Decode yields the 24-bit value with a
  zero high byte; COBOL instead sees `0x20` in the 4th byte (MOVE pad), so
  COBOL's cr values read ~0x20000000 high. Recorded here so a later
  date-comparison port does not "fix" one side only.
- `fixtures/fdinv2_builder.py` was re-framed from byte 122 (it wrote 2-byte
  LE shorts and put `days`/`cr` at 126/127). Fixtures regenerated.

## Parity evidence (WP03)

Corpus: `fixtures/generated/clean/invoice.dat`, re-framed under DP-003,
sha256 `bfe2b857…dbd55b7`.

- COBOL read and re-wrote all six records through `sl055`
  (`harness/runs/20261103-015937-sl055-wp03`): **zero byte diffs** against the
  input corpus, no `SY009` abort. The re-framed layout is what ACAS itself
  produces, not just what the builder thinks.
- Rust: `every_harness_fixture_record_round_trips` decodes and re-encodes the
  same six records and asserts byte identity; `full_{header,line}_record_
  round_trips_byte_identically` do the same on the GnuCOBOL capture.
- The analysed flag `sl055` sets is still dropped on write — that is ACAS's
  behaviour (F-B006), not a regression of this port. It stays listed here so
  WP04/WP05 do not "fix" it in one place only.
- Invoice artifact hash moved from `746c1e3a…` (WP02 framing, mis-offset from
  byte 122) to the value above. Everything downstream of byte 121 changed
  intentionally; the line records are unaffected.
