# charter-packs/java — STATUS: draft, pending first reference port

COBOL → Java specialization of `common-core`. Filled by real porting work;
nothing here is law until a `reference-ports/java-acas` slice proves it.

## Target-idiom mapping (draft, evidence-pending)

| COBOL construct | Java landing | Notes |
|---|---|---|
| `pic s9(7)v99 comp-3` | `BigDecimal` with explicit `MathContext` | the best mainstream language choice for money — use it, don't degrade to i64 cents |
| days-since-1600 `binary-long` dates | `long` + adapter to `java.time.LocalDate` at report boundary | epoch rule identical to F-B001 |
| fall-through paragraphs | small methods + explicit state enum | checked exceptions mirror COBOL's `DECLARATIVES` USE-AFTER-ERROR in spirit |
| 88-level condition names | `enum` + `fromByte(byte)` | Java enums are the cleanest of the three packs for this |
| Open-item staging files | staged DTOs + transactional write | see "two-layer rule" below |
| Screen-section curses UI | **leave for last** — lanterna or ASCII re-render of layout only when behavior parity demands it |

## The two-layer rule (Java-specific doctrine)

Java *wants* JPA/entities. The pack's rule:

1. **Serde layer**: byte-exact COBOL file layouts (positional, packed-decimal,
   EBCDIC-host corners where they exist). Lives in `acas.codec.*`. No domain
   logic.
2. **Domain layer**: rich `BigDecimal`-using model. Lives in `acas.domain.*`.
   Never imports `acas.codec.*` directly — a hand-rolled mapper sits between.

The failure mode this prevents: domain objects whose *field order* silently
depends on a 134-byte record layout. (The Rust pack gets this via enum
decoupling in `InvoiceRow`; Java needs the rule explicitly because `@Entity`
makes the wrong thing one annotation away.)

## What this pack needs to graduate from draft

- [ ] `reference-ports/java-acas` exists with first codec test
- [ ] F-Java001..N evidence entries (BigDecimal rounding vs COBOL COMP-3 truncation
      semantics — likely the single most load-bearing investigation in this pack)
- [ ] First slice parity vs COBOL fixtures, screen-exempt, byte-level
