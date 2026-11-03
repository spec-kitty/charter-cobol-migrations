# charter-packs/go — STATUS: draft, pending first reference port

COBOL → Go specialization of `common-core`. Filled by real porting work;
nothing here is law until a `reference-ports/go-acas` slice proves it.

## Target-idiom mapping (draft, evidence-pending)

| COBOL construct | Go landing | Notes |
|---|---|---|
| `pic s9(7)v99 comp-3` | `shopspring/decimal.Decimal` or i64-cents newtype | **never float64** — rounded-money drift is the #1 silent failure mode of naive ports |
| days-since-1600 `binary-long` dates | `type CobolDate int32` + `time.Time` adapter at report boundary | epoch rule identical to F-B001 |
| fall-through paragraphs / `GO TO` webs | small funcs + explicit state enum; `goto` reserved for error-cleanup of legacy shape | Go's `goto` is legal but the pack's stance is that porting one fall-through = one refactor |
| 88-level condition names | typed constants + `map[byte]bool` validated sets | Go has no enums; sum-type semantics via interface checkers where load-bearing |
| `PERFORM x THRU y` shareable paragraphs | closure-only funcs — THRU sharing is the idiom fossil, not a feature | |
| ISAM relative/indexed files | byte-layout-preserving file pkg, then `database/sql` at the strangler boundary | decision point: when does the port stop writing COBOL-compatible files? Tracked per-slice. |
| `WS-CALLING-DATA` global linkage | `&Env{...}` context struct threaded explicitly | mirrors `AcasEnv` in the Rust pack |

## What this pack needs to graduate from draft

- [ ] `reference-ports/go-acas` exists with go.mod + first crate-equivalent module
- [ ] F-Go001..N evidence entries (money encoding, date epoch, ISAM framing for Go)
- [ ] First slice (sl055-equivalent) with byte-parity findings against COBOL fixtures
- [ ] Tactics with `*(learned)*` markers accruing from real porting, same discipline as the Rust pack

## Explicit non-goals

- No CP/M-era compat shims Go doesn't need.
- No attempt at `SCREEN SECTION` TUI parity via tcell on day one — screen parity is
  the LAST thing ported per slice, after byte-level ledgers prove out.
