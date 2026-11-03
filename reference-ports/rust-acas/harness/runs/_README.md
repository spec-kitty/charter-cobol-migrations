# Parity harness runs — cheat sheet

## Layout

```
runs/<YYYYMMDD-HHMMSS>-<label>/
  manifest.json           # scenario, bytes observed, hash_screen, file_hashes, sy009 flag
  screen.transcript.bin   # raw pty byte-stream observed
runs/_README.md           # this file
```

## Existing scenarios

| scenario | Drives | Golden state when it works |
|---|---|---|
| `boot` | `./ACAS` without env vars | SY009 abort; hash_screen matches `f2332939…` |
| `mainmenu` | `./ACAS` with env sandbox | reaches SYS002 System Parameters (drives multi-screen) |

## The raw byte stream

Transcripts are raw VT100 bytes from a pty. To read them:

```python
import re
raw = open(f"runs/<label>/screen.transcript.bin","rb").read()
txt = re.sub(rb"\x1b\[[0-9;?]*[A-Za-z@]", b" ", raw)
txt = re.sub(rb"\x1b[B()=>][0-9A-Za-z]?", b" ", txt)
print(re.sub(rb"[ \x00]+", b" ", txt).decode("utf-8","replace"))
```

## Snapshot comparison

`python3 parity_harness.py diff <labelA> <labelB>` reports
`same/ADDED/REMOVED/DIFF` per file path.

## Fixture use

Pinning observed behaviors into fixtures is the workflow: each run dir is
a byte-exact golden master. When the Rust side catches up, the same
scenarios re-run against `acas-*` binaries (TBD) and `diff` compares.
