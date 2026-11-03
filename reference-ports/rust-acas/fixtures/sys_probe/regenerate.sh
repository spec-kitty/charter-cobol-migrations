#!/usr/bin/env bash
# Regenerate field-map.tsv (WP06, F-B011).
#
# Two independent measurements, both needed:
#
#   1. COMPILE-TIME offsets. A throwaway program references every copybook
#      field; `cobc -C` emits one `cob_field f_NN = {len, base + off}` line per
#      field, which the extractor below turns into a table. These are the
#      offsets the *source* describes.
#
#   2. RUNTIME delta. The compiled ACAS binary carries an 8-byte prefix ahead
#      of `System-Record-Version-Prime`, so every field sits 8 bytes later on
#      disk than the source says (F-B011). The extractor adds that delta and
#      keeps both columns so the delta stays auditable.
#
# The delta is independent of the compiler and of the build: rebuilding ACAS
# and sys002 from the vendored copybooks still writes at +8 (checked
# 2026-11-03), and a field planted at the +8 offset is the one the SYS002
# screen echoes back.
set -euo pipefail
cd "$(dirname "$0")"
root=$(git rev-parse --show-toplevel)
copybooks="$root/reference-ports/rust-acas/cobol-original/copybooks"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

python3 - "$copybooks/wssystem.cob" "$work/allf.cbl" <<'PY'
import re, sys
items = []
for line in open(sys.argv[1]):
    code = line.split('*>')[0].strip()
    m = re.match(r'^([0-9]{2})\s+([A-Za-z0-9-]+)', code)
    if not m:
        continue
    lvl, name = m.group(1), m.group(2)
    if lvl == '88' or name.lower() == 'filler' or name == 'System-Record':
        continue
    if 'REDEFINES' in code.upper():
        continue
    items.append(name + ('(1)' if ' OCCURS ' in code.upper() else ''))
body = ['>>source free', 'identification division.', 'program-id. allf.',
        'data division.', 'working-storage section.', 'copy "wssystem.cob".',
        'procedure division.']
body += [' display ' + i + '.' for i in items]
body.append(' stop run.')
open(sys.argv[2], 'w').write('\n'.join(body) + '\n')
PY

cobc -C -free -I "$copybooks" "$work/allf.cbl" -o "$work/allf.c"

python3 - "$work/allf.c.l.h" <<'PY' > field-map.tsv
import re, sys
pat = re.compile(r'\{(\d+), b_\d+(?: \+ (\d+))?, &a_\d+\};\s*/\* (.*?) \*/')
rows = [(int(m.group(2) or 0) + 8, int(m.group(2) or 0), int(m.group(1)), m.group(3))
        for m in (pat.search(l) for l in open(sys.argv[1])) if m]
rows.sort(key=lambda r: (r[0], -r[2]))
print('runtime_offset\tcompile_offset\tsize\tfield')
seen = set()
for row in rows:
    if (row[0], row[3]) in seen:
        continue
    seen.add((row[0], row[3]))
    print('\t'.join(str(v) for v in row))
PY

wc -l field-map.tsv
