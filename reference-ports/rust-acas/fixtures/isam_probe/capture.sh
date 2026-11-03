#!/usr/bin/env bash
# Regenerate the fdinv2 field-surface capture (WP03, F-B006).
# One header record + one line record, every field populated with a
# distinctive value, written by GnuCOBOL itself through ACAS's own
# invoice-header / invoice-line overlays onto the 134-byte invoice-record.
# The Rust round-trip test replays these exact bytes.
set -euo pipefail
cd "$(dirname "$0")"
out=../generated/capture
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cobc -free -x -o "$work/cap" capture_header.cbl
( cd "$work" && ./cap )
cp "$work/invoice-capture.dat" "$out/invoice-capture.dat"
ls -l "$out"
