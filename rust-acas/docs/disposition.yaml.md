# Copybook Field Dispositions

Per directive **L2R-005**: every field in every copybook record layout used by a
ported slice must appear here with one of:

- **carry** — ported as-is to Rust (same semantics)
- **rename** — ported with a Rust-idiomatic name; record the mapping here
- **retire** — deliberately not ported; justification required (e.g., padding slack)
- **defer** — port later; enters a ticket
- **absorb** — behavioral content moved into a type-level guarantee (e.g., 88-level
  condition-name becomes an enum variant)

## Format

```yaml
copybook: <file.cpy>
  record: <01-level name>
    fields:
      - name: <COBOL field>
        pic: <PIC clause>
        disposition: carry|rename|retire|defer|absorb
        target: <rust equivalent, if applicable>
        rationale: <required for rename/retire>
```

## Status

No dispositions yet — they accrete as slices are ported, starting with
`wssystem.cob` (system-parameter record, 1024 bytes, fields accreted 2009–2013)
which is the first audit target in phase 1.
