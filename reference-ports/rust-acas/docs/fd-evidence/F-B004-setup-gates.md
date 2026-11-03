# F-B004 — SYS002 setup gates and the scycle exit condition

Date: 2026-11-03 · WP01 · verified by `setup-clean` + `menu-boot` scenarios

## The wall, stated precisely

`ACAS.cbl:236` routes to `call-system-setup` whenever the freshly read system record has
`scycle = 0`. `scycle` REDEFINES `cyclea` (`wssystem.cob:46-47`), so the exit condition is
"Current Cycle is non-zero after this setup run". Setup always ends with a `rewrite
system-record` at `sys002.cbl:873` (Menu-Option), so whatever `cyclea` holds at that
moment is what persists.

`cyclea` advances in daily operation only via quarterly rollover (`xl150.cbl:1034-1065`),
so a first-run instance must have it typed explicitly. It is the **16th input field** of
SYS002 screen 1, after: name, address-1..4, post-code, country, date-form, p-start,
p-end, page-lines, vat-rate-1, vat-rate-4, vat-rate-2, vat-rate-5, vat-rate-3.

## Offset correction (supersedes F-B002's field table)

F-B002 placed `cyclea` at +12. It is at **+20**; the `Vat-Rates comp` group is wider than
assumed. Verified against a live record: `+20 = 01`, `+21 = 03` (period monthly),
`+22 = 0x30` (page-lines 48). Corrected anchors: next-invoice +23, run-date +27,
start +31, end +35, company/user area +39. The three consecutive LE date values
(`0x25f8f`) at 27/31/35 are the audit trail for the correction.

## Gate map (what the harness must satisfy, in order)

| # | Gate | Satisfied by |
|---|---|---|
| 0 | Env vars (ACAS_LEDGERS/IRS/BIN) present | harness env |
| 1 | mapser level 1: company name | literal text + Enter |
| 2 | level-1 verify prompt (pre-filled Y) | Enter |
| 3 | six ledger toggles (pre-filled Y) | 6 × Enter |
| 4 | level-1 confirm | `Y` + Enter |
| 5 | SYS002 screen 1 (User Data) | 15 × Tab, `01`, Enter |
| 6 | screen-1 verify (pre-filled Y) | Enter |
| 7 | OPS Data 1 | Enter |
| 8 | CUPS spool sub-screen (op-system = 6) | Enter |
| 9 | OPS verify | Enter |
| 10 | G-L Data | Enter + verify |
| 11 | S-L Data 1 | Enter + verify |
| 12 | S-L Data 2 | Enter + verify |
| 13 | P-L Data | Enter + verify |
| 14 | Stock Data | Enter + verify |
| 15 | Print report prompt (pre-filled Y) | `N` + Enter (skip printing) |

**Screens do not gate on completeness.** Unset accounts print "Unset" in blink and roll on
(`sys002.cbl:1395-1412`); the only blocker in the whole flow is `cyclea` (gate 5).

## Non-gates, recorded to stop future re-investigation

- Screen 3 (RDBMS) is skipped entirely unless `File-System-Used ≠ 0` (`sys002.cbl:1146`).
- Page-lines 000 self-corrects; leaving defaults everywhere else is legal.
- Verify prompts accept Enter because `ws-reply` is pre-set to `"Y"` before each accept.

## Result

`setup-clean` scenario: one pass, no loop, menu in the transcript tail, record rewritten
with `cyclea = 1`. `menu-boot` with that record: no SYS002 at all. Golden record stored at
`fixtures/generated/setup/system.dat`.
