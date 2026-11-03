# charter-packs/common-core

Language-agnostic doctrine for **porting a working legacy-language system to a
modern target language**. The task-class contract; every per-language pack
inherits from this.

## Directives

| # | Directive | Severity |
|---|---|---|
| L2R-001 | **Characterize before you translate.** No port module exists without golden-master byte evidence of the source counterpart's behavior. | error |
| L2R-002 | **The source system is the executable spec.** Never port from "what it probably does." | error |
| L2R-003 | **Features are obligations; idioms are liabilities.** Each ported construct records: the legacy idiom, its behavioral content, and the target idiom chosen. | warn |
| L2R-004 | **Never both rename and restructure in a single commit.** Structure-shifts interleave with name-shifts; they do not coincide. | warn |
| L2R-005 | **Every record-layout field gets a disposition entry** (carry / rename / retire / defer / absorb). Nothing silent. | error |
| L2R-006 | **If the port looks cleaner than the source, suspect a behavior was lost.** | info |

## Tactics (language-agnostic vocabulary)

- `golden-master-characterization` — capture executable outputs as byte-exact fixtures.
- `slice-with-posting-edge` — port workflows end-to-end, not modules directory-by-directory.
- `strangler-fig-boundary` — both halves share data files or IPC until a slice is fully strangled.
- `idiom-fossil-audit` — explicit catalog of replaced idioms.
- `late-fail-detection` — preflight typed errors instead of porting after-the-work warnings.
- `88-level-decision-tree` — condition-names as enums, never bare ints.

## Evidence convention

Each load-bearing behavior gets an **F-*numbered evidence note** worked bytes → claimed decoding, in `reference-ports/<lang>-acas/docs/fd-evidence/`. Bytes pin types, not vice versa.

## Verification gates

Same gates regardless of target:
1. Build clean against source compiler (GnuCOBOL for this corpus).
2. Parity harness drives source; transcripts/hashes captured.
3. Ported module reproduces fixture bytes **or** the diff is documented as a deliberate idiom departure.
