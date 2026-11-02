# ACAS Build Patches

The vendored baseline in `cobol-original/` is **unmodified upstream v3.01.07**, as
downloaded from SourceForge. The zero-deviation parity harness needs it readable
byte-for-byte. When a patch is needed to make the reference compiler (GnuCOBOL
3.1.2, Ubuntu noble) build the sources, that patch is recorded here and applied
only to *working build copies* (currently `/tmp/acas-build`), never to the
vendored tree. Each entry is a charter-class artifact: the *idiom* is being
retired, the *behavior* preserved.

## P-B001 — `copybooks/wsfnctn.cob`, line 10 (signed→unsigned binary-long for RELATIVE KEY)

**Date:** 2026-11-02
**Change:**
```diff
-     03  Rrn             binary-long.
+     03  Rrn             binary-long unsigned.  *> BUILD PATCH: GnuCOBOL requires unsigned RELATIVE KEY
```
- **Why**: Original compiler (Fujitsu-flavored — see `stockMT.cbl-Fujitsu-OO` artifact)
  permitted a signed `BINARY-LONG` field as `RELATIVE KEY`. GnuCOBOL refuses.
- **Behavior change**: **None at runtime.** ACAS only assigns `rrn` literal values
  `1`–`40`-ish at every one of 17 observed callsites; negative bits were a
  compiler schema permissiveness, not exercised feature.
- **Charter-class**: Idiom-fossil → single-idiom superseding. First worked example
  of L2R-003. When ported to Rust, `rrn` becomes `u32` in a storage-backend
  newtype, NOT `i32`.
- **Level**: 1 (per-token). Confirmed by reading all `rrn` usages.

## NOTE — vendored sources stay byte-exact

2026-11-02: I briefly tempted fate by trying to annotate dispositions INSIDE
`cobol-original/sales/fdinv2.cob`. Reverted immediately. Rule reaffirmed:
the vendored tree in `cobol-original/` is a *byte-for-byte mirror of
SourceForge v3.01.07* (plus its own `PATCHES.md` ledger). Commentary goes in
`rust-acas/docs/`, never in the vendored files.
