#!/usr/bin/env bash
# Regenerate the indexed-ISAM golden fixtures with GnuCOBOL itself.#
# Outputs land in ../generated/indexed/. Byte-exactness is the point:
# these are the bytes libcob actually writes for ACAS's own FDs,
# and the Rust reader must accept them (F-B005).
set -euo pipefail
cd "$(dirname "$0")"
out=../generated/indexed
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cobc -free -x -o "$work/gen_invoice" gen_invoice.cbl
cobc -free -x -o "$work/gen_value"   gen_value.cbl
( cd "$work" && ./gen_invoice )
cp "$work/file-16" "$out/invoice-paged.dat"
( cd "$work" && ./gen_value )
cp "$work/file-13" "$out/value-paged.dat"
ls -l "$out"
