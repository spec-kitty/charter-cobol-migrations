# Tasks — port-completion-01M6FZ0K

Dependency-ordered work packages. Each WP owns a disjoint file surface; parity gate per WP.

| WP | Title | Depends on | Requirement refs |
|----|-------|-----------|------------------|
| WP01 | Setup-exit wall | — | FR-001, C-004 |
| WP02 | ISAM foundation + fixtures | WP01 | FR-002, NFR-004 |
| WP03 | fdinv2 full surface | WP02 | FR-006 |
| WP04 | sl055 extract parity | WP02, WP03 | FR-003, FR-005 |
| WP05 | sl060 GL posting parity | WP04 | FR-004 |
| WP06 | SystemFile type | WP01 | FR-007 |
| WP07 | Remaining sales programs | WP05 | FR-008 |
| WP08 | Nominal ledger (general/) | WP06 | FR-008 |
| WP09 | Purchase ledger | WP08 | FR-008 |
| WP10 | Stock control | WP08 | FR-008 |
| WP11 | IRS subsystem | WP08 | FR-008 |
| WP12 | Screen layer + session parity | WP07, WP09, WP10 | FR-009 |
| WP13 | Release artifact + docs | WP12 | FR-010, NFR-003 |
| WP14 | Doctrine graduation + go/java slices | WP05 | FR-011 |

## Sequencing notes

- WP01 is the gate for everything; nothing runs under the harness until setup exits cleanly.
- WP06 (SystemFile) is independent of sales and unblocks the non-sales ledgers.
- WP12 screens need the batch logic beneath them; screens do not block ledger parity.
- WP14 can start once slice 1 is proven (rest of the ledger work need not finish first).

## Lane sketch

Lane A: WP01 → WP02 → WP03 → WP04 → WP05 → WP07
Lane B (after WP01): WP06 → WP08 → {WP09, WP10, WP11}
Lane C (after WP05): WP14
Join: WP12 → WP13
