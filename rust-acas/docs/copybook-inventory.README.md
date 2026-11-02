# Copybook Inventory (auto-generated)

Tool: `/tmp/parse_copybooks.py` (run manually; output committed here).

This is the **Layer-0 census** — every named 01-level record, its statline,
and every field with PIC + class. Dispositions ("carry/rename/retire/defer/absorb")
are layered on top in `disposition.yaml.md` as slices port; the inventory is
agnostic.

Regenerate:
```
python3 /tmp/parse_copybooks.py
```

Known coverage gaps in parser v0.1 (acknowledged, tracked per-slice):
- `file0*.cob` system-file aliases use `FD filename IS EXTERNAL` form; parser
  currently sees 0 records (goal: absorb → folded into wssystem disposition).
- 88-level condition names counted per-file but not enumerated per-record.
- Group fields with `OCCURS n` get counted but their children don't get
  multiplied byte lengths; records with any OCCURS get byte-length None
  until disposition stage pins it down explicitly.

**Status:** 72 copybooks, 26 records with full fieldmaps, 47 valid-but-record-less
(enviorment files, pure SELECT copybooks). **wssystem.cob** and **fdval.cob**
parse clean and are the two next disposition targets.
