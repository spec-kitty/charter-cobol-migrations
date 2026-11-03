# F-B002 — GnuCOBOL relative-file framing (system.dat golden master)

Verified 2026-11-02 against harness-produced `system.dat` (4128 bytes, 4 records × 1024 B + 32-B space-pad trailer).

## Frame

```
[0        .. 1023]  record rrn=1 (system-record)
[1024     .. 2047]  record rrn=2
[2048     .. 3071]  record rrn=3
[3072     .. 4095]  record rrn=4
[4096     .. 4127]  32-byte trailing pad (all spaces)
```

- No per-record used/free markers. RRN is pure positional index — `READ KEY rrn` translates to `pread(fd, rrn-1) * rec_size`.
- The 32-byte trailer is all spaces (0x20) in our sample; not a checksum, EOF padding of unknown purpose. Copied verbatim on write (behavior carried).
- **No fixed 128-byte GnuCOBOL header** (that guess from early exploration was wrong — the first 32 bytes belong to record 1's own layout).

## system-record field map (rrn=1; offsets within the 1024-byte record)

| Offset | Field | PIC/usage | Verified |
|---|---|---|---|
| 0, 1 | System-Record-Version-Prime, -Secondary | binary-char ×2 | `00 04` = v4 (matches FD comment) |
| 2..12 | Vat-Rates comp ×5 | comp (big-endian i16, 99v99) | zeros in fixture |
| 12 | Cyclea / Scycle | binary-char | flag |
| 13 | Period | binary-char | |
| 14 | Page-Lines | binary-char unsigned | |
| 15..19 | Next-Invoice | binary-long LE | 1 in fixture |
| 19..23 | Run-Date | binary-long LE (F-B001) | 155534 = 2026-11-02 ✓ |
| 23..27 | Start-Date | binary-long LE | 155534 (same-day on setup) |
| 27..31 | End-Date | binary-long LE | 155534 |
| 31..71 | Suser (40 B) area; User-Code overlaps first 32 B | x | "Harness Test Co" + trailing spaces |
| 71..167 | Address-1..4 + Post-Code + Country | x(24)×4 + x(12) + x(24) | spaces in fixture |
| ... | Print-Spool-Name x(48) | x | spaces |
| ... | File-Statuses | — | |
| ... | Pass-Value, Level, Pass-Word x(4), Host, Op-System, Current-Quarter | mixed | |
| ... | (remaining fields — full map lands in `acas-common/src/system.rs` as static layout data) |

## Verified bytes

```
offset 24–40 of file: 00 00 8e5f0200 8e5f0200 8e5f0200 48
                      +23 start  +27 end    +31 'H' of usera
```
