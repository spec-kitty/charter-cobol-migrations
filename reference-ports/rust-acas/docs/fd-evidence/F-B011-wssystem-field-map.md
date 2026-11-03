# F-B011 — wssystem field map: runtime offsets, the 8-byte prefix, and 88 values

Measured 2026-11-03 for WP06. `fixtures/sys_probe/regenerate.sh` reproduces the
whole table from the vendored copybook; `fixtures/sys_probe/field-map.tsv` is
the checked-in result.

## Why this note exists

F-B002 mapped only the first 40 bytes of record 1 and flagged the rest as
"full map lands in `system.rs`". This note is that map. It also corrects two
things F-B002 and the copybook comments would otherwise let a porter assume:

1. **There is an 8-byte prefix before the field list.** The compiled ACAS
   binary does *not* place `System-Record-Version-Prime` at byte 0; it places
   it at byte 8. Every field is 8 bytes later than the copybook's own layout.
2. **The 32-byte trailer of the file is not part of record 4** — unchanged from
   F-B002, restated because record offsets here are all record-relative.

## How the offsets were measured

Two channels, because either alone is ambiguous:

**A. Compile-time table.** A throwaway program references every field of the
copybook; `cobc -C` emits `cob_field f_NN = {len, b_250 + off}` per field.
`regenerate.sh` extracts all 172 of them. This fixes the *relative order* of
every field, which is what the copybook actually states.

**B. Runtime delta, measured on the running binary.** Plant a byte-ramp
(`record[i] = i % 256`) in a copy of the WP01 golden, boot ACAS, walk into
SYS002 screen 1 and read back what each field *displays*:

```
Vat Rates : (1)- [25.71]     -> int 2571 = 0x0A0B -> bytes 10,11
            (2)- [30.85]     -> 0x0C0D -> 12
            (3)- [35.99]     -> 0x0E0F -> 14
            (4)- [41.13]     -> 0x1011 -> 16
            (5)- [46.27]     -> 0x1213 -> 18
Current Cycle- [20]          -> 0x0014 -> 20      (cyclea)
Cycle Period-  [21]          -> 0x0015 -> 21      (period)
System Print Lines - [022]   -> 0x0016 -> 22      (page-lines)
Current Quarter - [48]       -> 0x30   -> 48      (current-quarter)
Data File Handling - [I]     -> 0x49   -> 73      (file-system-used)
Dual file type Flag - [J]    -> 0x4A   -> 74      (file-duplicates-in-use)
VAT Reg no - [u...]          -> 0x75   -> 117 = 373 mod 256 (vat-reg-number)
Name    - [ ... ()*+ ...]    -> control bytes 39..47 then 0x28 -> 40 (usera at 39)
Address - [ g...]            -> 0x67   -> 103     (address-1)
```

Every probe lands exactly `compile_offset + 8`, from byte 10 to the end of the
record — the delta is constant, not local.

**C. The delta is a property of the binary, not of a build.** Recompiling
`common/sys002.cbl` and `ACAS.cbl` from the vendored copybooks and re-running
SYS002 still writes `Harness Test Co` at byte 39 (run `20261103-090956-wp06-acasrebuilt`).
The vendored copybook in `cobol-original/copybooks/` therefore describes 8
bytes *less* than the shipped binary lays down; the extra bytes are below.

**D. The gate reads cyclea at 20.** Zeroing byte 12 (the copybook position) and
setting byte 20 to `01` lets boot skip setup; zeroing byte 20 re-enters setup
(run `20261103-090601-wp06-offsetA`). This is the measurement that kills the
copybook-position reading.

## The prefix pad [0,8)

```
00 04 00 00 00 00 00 00     <- golden system.dat record 1
```

- `+0..1` = `00 04`; the FD header comment calls the layout "v4" and the
  copybook calls the versions "NEW". We read `00 04` as a layout tag.
- `+2..7` = six zero bytes.
- Never written by ACAS after the first-run record is created (`initialize`
  zeroes it, nothing moves into it), and no program reads it. Opaque, carried
  verbatim: `SystemRecord::prefix()`.

Versions follow at `+8`/`+9` (`01 01` in the golden — the record was created by
a run whose `System-Record-Version-Prime/Secondary` came out as v1.1, not the
`00 04` the FD comment suggests; the two bytes are independent of the pad).

## Consequences for the port

- `acas-common/src/system.rs` uses these **runtime** offsets, never the
  copybook's. Round-trip is against the golden.
- Because the record is 1024 bytes and the copybook now overflows it by 8 at
  the tail, the last 4 bytes of the IRS block's trailing filler (`+1020..1024`)
  are all that is left of a 12-byte filler; nothing there is lost (the last
  field above it, `1st-Time-Flag`, ends at `+1020`) — but this is why the
  record size and the copybook no longer agree and must not be reconciled
  blindly.

## Field table

`fixtures/sys_probe/field-map.tsv` — `runtime_offset`, `compile_offset`,
`size`, `field`, all 172 fields, sorted by runtime offset. Whole-record
dispositions with filler ranges are in `docs/disposition-wssystem.md`.

## 88 condition values (carried as constants, `system.rs::cond`)

`G-L/B-L/S-L/Stock/O-E/Payroll` = 1 · `Multi-User` = 1 · `Dos/Windows/Mac/Os2/
Unix/Linux` = 1..6 · `OS-Single` {1,2,4} · `FS-Cobol-Files-Used` = 0,
`FS-RDBMS-Used` = 1, `FS-Valid-Options` {0,1} · `FS-Duplicate-Processing` = 1 ·
`Date-UK/USA/Intl` = 1/2/3 · `DC-Cobol-Standard` = 0, `DC-GUI` = 1,
`DC-Widget` = 2 · `Profit-Centres` 'P', `Branches` 'B', `Grouped` 'Y',
`Revenue-Only` 'R', `Comparatives(-Active)` 'Y', `Minimum-Validation` 'Y',
`Archiving` 'Y', `Mandatory/Trans-Done` 'Y', `Auto-Vat` 'Y',
`Preserve-Batch` 'Y', `Index-2` 'Y', `Irs-Used` 'Y', `P-L-Exists` 'Y',
`S-L-Exists` 'Y', `Stock-Audit-On` 'Y', `SL-Comp-*-Head` 'Y',
`SL-VAT-Prints` 'Y', `Stock-Control-Exists` 'Y', `Stock-Averaging` = 1,
`I-Level-0/1/2` = 0/1/2, `Not-Invoicing` = 9, `Discount` 'D', `Charge` 'C'.
