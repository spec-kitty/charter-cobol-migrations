# charter-cobol-migrations

**One task class**: porting working legacy-language systems to modern targets
**with behavioral parity** (features carried, idioms selectively retired).

Originally scoped COBOL → Rust only; broadened 2026-11-02 to a family of packs.

## Layout

```
charter-packs/
├── common-core/    # task-class doctrine: L2R-001..006 + tactics + evidence convention
├── rust/           # Rust specialization — ACTIVE (proven against ACAS)
├── go/             # Go specialization — DRAFT
└── java/           # Java specialization — DRAFT
reference-ports/
└── rust-acas/      # ACAS v3.01.07 port (in progress): harness, crates, docs
```

## Rules of the house

- A pack graduates out of DRAFT only by proving itself on a real slice
  inside `reference-ports/`. Common-core doctrine is shared; target idioms
  are earned.
- New target language? Add `charter-packs/<lang>/README.md` as a draft,
  referencing `common-core`. Do not fork doctrine.
- Legacy source systems other than COBOL (e.g., a Fortran estate) would go
  in a sibling **repo** with the same two-directory layout; this one stays
  COBOL-specific because ACAS is the reference corpus.

## Lineage

Spec Kitty org · doctrine conventions per `spec-kitty-charter`. GPL-2.0-only
(tracked with the ACAS sources it ports).
