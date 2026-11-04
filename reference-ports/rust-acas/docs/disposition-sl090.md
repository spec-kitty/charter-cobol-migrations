# Disposition — `sl090` payment-proof sort

`sl090` reads the open-item file sequentially, drops the rows that are not
payment rows, and sorts the rest into a second file with `sort ... giving`.
It prints nothing; `sl095` reads the sorted file next and does all the
printing, so the artifact of this program is `oisort.wrk`.

The `oi-header` layout (114 B) is dispositioned in `disposition-sl055.md`;
the money and status fields are not read here and are not repeated. Offsets
zero-based. Ported in `crates/acas-sales/src/payment_proof_sort.rs`; evidence
is `docs/fd-evidence/F-B090-sl090-payment-proof-sort.md`.

## Fields the program reads

| off | len | field | disposition |
|---|---|---|---|
| 0 | 7 | `oi-customer` (incl. `oi-check`) | sort-neutral; carried in the record and, later, the `sl095` sales key |
| 7 | 4 | `oi-invoice` | last sort key, ascending (Part 4) |
| 11 | 4 | `oi-date` | fourth sort key, ascending |
| 15 | 4 | `oi-b-nos` | first sort key, ascending; zero means "no batch" |
| 19 | 2 | `oi-b-item` | second sort key, ascending; with `oi-b-nos` zero it drops the row |
| 21 | 1 | `oi-type` | skip on `1` (receipt) and `3` (credit note); third sort key, **descending** |
| 22 | 92 | description, hold, unapl, money, status, clears | not read; carried verbatim (Part 6) |

## Controls

| element | disposition |
|---|---|
| `s-flag-p = 0` | errors 30/15 via `maps99`, exit before any open — no file at all (Part 1) |
| input open status ≠ 0 | close, then create a zero-length output, exit (Part 3) |
| `function length` mismatch | unreachable: both records are 114 (Part 6) |
| `move "Y" to oi-3-flag` | only after the gate passes; caller-owned system byte 562 |
| screen output | `prog-name` and the two `maps99` errors only — WP12 owns the map rendering; the refusal surfaces as a distinct outcome variant instead |

## Environment flags

| byte | field | why |
|---|---|---|
| 569 | `s-flag-p` | the program's whole gate; the scenario seeds it (DP-016) |
| 560 | `sales-ledger` | DP-010's reason — `sl095`, which runs immediately after, opens the sales file |
