# F-B012 — sl170 customer-file dump: print mechanics, selection filters, fossils

**Program:** `sales/sl170.cbl` (3.01.07), 796 lines. Read-only over `sales-file`;
writes `print-file` (`prt-1`). **Measured** on 2026-11-03 against the vendored
source compiled by GnuCOBOL 3.1.2, driven through the real `ACAS` menu.

**Why this note exists:** `file_dump.rs` types a whole report program. Every
claim below is either read straight out of the copybook with a byte count or was
observed in a run whose transcript is committed
(`harness/runs/20261103-115507-repro`, `…-115726-dbg`, `…-115843-dbg2`).

> Numbering note: this note was drafted as F-B011 while WP06 was writing its own
> F-B011 on another lane. WP06 landed first; the dump is **F-B012** and every
> reference in the source was updated.

## Part 1 — the print file is the artifact

`print-file` is `select ... assign "prt-1" organization line sequential`
(`selprint.cob`), one `01 print-record pic x(132)`.

GnuCOBOL's line-sequential `WRITE ... ADVANCING` behaves like this (probed):

| statement | bytes emitted |
|---|---|
| `WRITE rec AFTER ADVANCING n` | `n` × `0x0A`, then the 132-byte record |
| `WRITE rec BEFORE ADVANCING 1` | the record, then `0x0A` |
| `WRITE rec AFTER ADVANCING PAGE` | `0x0C` appended to the **previous** line, then the record on that same line |

The page eject is why the spool file has variable-length lines: an eject after a
132-byte record produces a 133-byte line. `PrintFile` reproduces all three forms
byte for byte; a `Vec<String>` would not.

`close print-file` appends one `0x0A` if the file does not already end in one.

## Part 2 — `line-4`, the customer block

`line-4` is 132 bytes and is **reused** between customers and between the eight
writes of one block. Only the pieces a `move` touches change; everything else is
whatever the previous line left there. Field map from the picture clauses:

| bytes | field | picture |
|---|---|---|
| 1..14 | `l4-name-1` | `x(14)` |
| 15..70 | `l4-value-1` | `x(56)` |
| 71..86 | `l4-name-2` | `x(16)` |
| 87..100 | `l4-value-2` | `z(7)9.99bbb` |
| 87..89 / 90..100 | `l4-d-filler` / `l4-date` | redefine of `l4-value-2` |
| 101..118 | `l4-name-3` | `x(18)` |
| 119..131 | `l4-value-3` | `z(7)9.99cr` |
| 119..131 | `l4-filler` | redefine, `x(13)` |

`l4-value-3` is thirteen bytes and fits inside the record with nothing clipped;
`l4-value-2` is fourteen, so its trailing `bbb` are three literal spaces.

`line-5` — the rule between customers — is 40 spaces, `<`, fifty dashes, `>`,
then spaces to 132: `<` lands on column 41 and `>` on column 92.

`headings-1` writes `line-1` (page number `pic zz9` on column 130) `before 1` on
page 1, and for every later page writes it `after page`, then blank-fills a
record and writes it `after 1`, then `line-3` (the `Report On :` text) `after 2`.

## Part 3 — selection and filters

- The screen is `display-03`; the six typed fields are `cust-in` (`x(6)`,
  upper-cased), and `pic 9(5)`/`pic 99` numerics with a one-character operator.
  A value that is not `L`/`G`/`E`/space re-runs `accept-data`.
- `cust-in` is copied to `customer-in` (`x(92)`), then
  `inspect customer-in replacing all space by "Z"` — the probe therefore pads
  with `Z`, which sorts after every real key sharing the prefix.
- The keyed `read sales-file invalid key move 1 to a` uses `sales-key`, a
  seven-byte key fed from a six-byte field, so it is space-padded and **can
  never match**: every keyed run is an invalid-key run. The failed read leaves
  the file positioned at the first key greater than the padded key, and the
  `read next` at the top of the loop yields *that* record — it is examined and
  can be printed. Observed in `…-115843-dbg2`: key `CUSTD3` prints `CUSTD30`.
- `test-array` compares `array-l (y)` against `Sales-Key (y:1)` with
  `varying y from 1 by 1 until y > 6`: **six** positions. The check digit at
  position 7 is never compared.
- `test-num` sets `truth` 0 then 1 on a hit; the caller skips the record on
  `a-false`.
- The overdue test is the only one with a gate, and the `a-false` check lives
  *inside* it:

  ```cobol
  if overdue-op not = space and sales-current > 0.00
         move overdue-in to test-1
         subtract sales-last-inv from run-date giving test-2
         move overdue-op to test-op
         perform test-num
         if a-false  go to read-loop.
  ```

  A customer whose balance is zero or negative therefore never reaches the
  comparison and is **listed regardless of the day count** — `truth` keeps the
  previous customer's value, and for the last record of a file it can still be
  0. Observed in `…-115843-dbg2`: `CUSTD60` prints with `truth=0` and a failed
  gate. A blank `comp-3` balance reads as `2020202.02` (F-B010) and counts as
  positive.
- `sales-current > 0.00` compares numerically (probed with a
  `pic s9(9)v99 comp-3` matrix: `500.00` and `12000.00` pass, `0.00` and every
  negative fail).

## Part 4 — driving the screen

Encoded in `harness/scenarios/sl170_file_dump.py`, all measured:

- The sales menu runs `sl000` (start of day) before it draws, so the date screen
  needs one CR and the menu letter follows it.
- The menu's accept is `auto`: the letter alone completes it, so it is sent
  without a trailing CR — a stray CR would end the selection accept with every
  field still blank.
- The selection has to be typewritten after the screen is up: fields are entered
  in order with TAB, each burst kept short because the screen runtime drops the
  last character or two of a longer one.
- The report is committed by a single CR well after the last burst, and the
  ledger is left with `X`.

## Part 5 — rendering rules confirmed against the golden

- An untouched `pic 9` (the delivery tag) prints the space it holds; an
  untouched `pic 99` credit prints `     .00` (blank integer part, `.00` after
  the point) because GnuCOBOL does not turn a blank digit into a zero.
- `move spaces to l4-name-3 l4-filler` on the status line clears the whole
  thirteen-byte third column, so that line and every later one print it blank —
  the column is not carried past it.
- The email legend is built with `string ... with pointer p`, and each later
  entry first does `subtract 2 from p` so the comma replaces the previous
  `". "`: `Invoicing, Statements, Dunning.`
- `sales-last-inv` / `sales-last-pay` are `binary-long`; an untouched field
  holds `0x20202020`, which is not zero, so the `= zero` guard misses and
  `maps04` renders `00/00/0000`.
- `listing` subtracts `sales-unapplied` from `sales-current` in place before
  printing it (`Sales-Current` shows a balance the file does not hold).
- The report is spooled (`call "SYSTEM"`) only when `rec-cnt not = 0`; a
  selection that matches nothing leaves `prt-1` closed but empty of content
  beyond the headings.

## Corroboration

The committed goldens under `fixtures/golden/sl170/` were re-run on 2026-11-03
(`harness/runs/20261103-115507-repro`) and hash-match the committed copies, so
the Rust parity test is checking live COBOL behaviour, not a stale capture.
