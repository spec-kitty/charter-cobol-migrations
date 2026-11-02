# Disposition ledger — fdinv2.cob (invoice file records)

Slice 1 target. Created 2026-11-02 alongside `acas-sales/src/invoice.rs` v0.

## invoice-record (the raw FD, 134 bytes)

**Disposition: absorb.** Physical layout retained on disk exactly; in Rust this
collapses into a serde framing over `InvoiceRow::Header`/`InvoiceRow::Line`.
The dual-purpose physical record (`item-nos`: 0 = header / 1.. = line) is
carried at the wire level without being copied into the type system as
scalar polling. `InvoiceLineNo::{Header,Line(u8)}` is where it lives.

| COBOL field | PIC | Disposition | Rust landing site | Rationale |
|---|---|---|---|---|
| invoice-key | group | absorb | tuple on both variants | key layout preserved; sub-fields carry to right variant |
| invoice-nos | 9(8) | carry | `InvoiceNumber(u32)` | bounded range, format-preserved as zero-padded string on wire |
| invoice-let | x | carry | `InvoiceLetter(u8)` | ASCII byte; N-M disambiguator for manual dup invoices |
| item-nos | binary-char | absorb | `InvoiceLineNo` enum | 88-level dispatch becomes enum |
| invoice-customer | x(7) | carry | `CustomerKey([u8; 7])` | raw bytes; never validated to ASCII |
| invoice-date | binary-long | carry | `CobolDate(i32)` days-since-1900 | wrapper newtype; calendar conversion only at report time |
| filler (10B) | x(10) | retire | — | legacy pad; zero-fill on write |
| invoice-type | 9 | carry | `InvoiceType` enum | {Invoice=1, CreditNote=3, Proforma=4, Other(u8)} |
| filler (10B) + (92B) | x(102) | retire | — | legacy pad; zero-fill on write |

## invoice-header (134 bytes overlay, used by sl055)

Fields currently exercised by sl055 extract logic — full set present, byte
offsets verified against `fdinv2.cob`:

| COBOL field | PIC | Bytes | Disposition | Rust / remark |
|---|---|---|---|---|
| ih-invoice | 9(8) | 8 (display) | carry | invoice_nos |
| ih-letter | x | 1 | carry | invoice_let |
| ih-test | binary-char | 1 | absorb | `InvoiceLineNo` continuity anchor — 0 means header |
| ih-customer | x(6) + 9 | 7 | carry | CustomerKey 6-char + check-digit |
| ih-date | binary-long | 4 | carry | CobolDate |
| ih-order | x(10) | 10 | carry | `[u8; 10]` raw (order ref; spaces mean "no order") |
| ih-type | 9 | 1 | carry | InvoiceType |
| ih-ref | x(10) | 10 | carry | raw `[u8; 10]` |
| ih-description | x(32) | 32 | carry | raw `[u8; 32]` (4 trim/pad behaviors to lock down on write) |
| ih-fig group | comp-3 multi | 8×5=40 | absorb | individual money field accessors; decimal-decimals modelled as i64-cents |
| ih-status | x + 88s | 1 | absorb → enum | `HeaderStatus::{Pending, Invoiced, Applied(z Z), Unknown(u8)}` |
| ih-status-P L C A I | x × 5 | 5 | carry | `[u8;5]` status bits (byte space = truth; enum lifecycle validated at write-time only) |
| ih-lines | binary-char | 1 | carry | u8 count |
| ih-deduct-days | binary-char | 1 | carry | u8 |
| ih-deduct-amt vat | 999v99 comp ×2 | 4 | carry | i16+i16? wait: 5-digit COBOL COMP is 4 bytes — treat as u32-deci-decimal, but uses s9(5)v99 across comp semantics → pinned via fixture |
| ih-days | binary-char | 1 | carry | u8 ageing on dispatch terms |
| ih-cr | binary-long | 4 | carry | CobolDate (credit dayes) |
| ih-day-book-flag | x | 1 | absorb → bool | presence of "B" == day-booked; other states omitted (we haven't observed others yet) |
| ih-update | x + 88 il-analyised | 1 | absorb → enum | `Analysed晦 Flag::{Unmarked, Analysied-z}` — byte preserves flora elsewise |

## invoice-line (80 bytes overlay, used by sl055 loop)

| COBOL field | PIC | Bytes | Disposition | Rust / remark |
|---|---|---|---|---|
| il-invoice | 9(8) | 8 | carry | invoice_nos |
| il-letter | x | 1 | carry | invoice_let |
| il-line | binary-char | 1 | absorb | u8 1..=99 via LineNo |
| il-product | x(13) | 13 | carry(*) | "+1 17/5/13" inline comment → was x12 → x13 product code; fossil-extension pattern, carry the current bytes |
| il-pa | xx | 2 | carry | product-analysis key (two-char code); raw [u8;2] |
| il-qty | binary-short | 2 | carry | i16; signed? expected positive, treat as u16 and audit |
| il-type | x | 1 | carry-but-enum | seen values {"1".."4"} in sl055 conditionals; 3 = credit-note |
| il-description | x(32) | 32 | carry | raw [u8;32] |
| il-net, il-unit, il-vat | s9(7)v99 comp-3 ×3 | 15 | carry | Money-cents i64 (rates incl sign) |
| il-discount | 999v99 comp | 2+? comp | carry with audit | percent×100 — u16? rate as fixdec-2 |
| il-vat-code | 9 | 1 | carry | u8 0..=9 (one VAT rate code of 8) |
| il-update | x | 1 | absorb → Analyzed flag | enum {Unanalysed, Analysied (z), Analysied-Z} |
| filler | x | 1 | retire | trailing pad byte (record aligns at 80) |

✳ Money (`comp-3 s9(7)v99`) storage: 5 bytes packed decimal. COBOL allows
negative. Rust accessor returns i64 cents; encoding back to packed is
nibble-accurate.

✳ comp `999v99` (binary-comp) is **GnuCOBOL comp = big-endian machine binary**,
size per digits via config; for 3-digit-v2 it's actually 4 bytes. Pinned via
next fixture.

## Status byte conventions (the 88 confusion point everyone hits)

`ih-status` is **the tri-state display flag**: P=pending, I=invoiced, z/Z=applied.
The five `ih-status-{P,L,C,A,I}` are independent single-letter columns for
pick-list/invoice-printed/cleared/applied/item-deleted respectively.
This is the idiom to absorb into a single struct with boolean semantics on
write, but on file they must round-trip as the SAME byte characters —
byte-parity wins over type-safety here.
