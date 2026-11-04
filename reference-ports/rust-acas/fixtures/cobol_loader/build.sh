#!/usr/bin/env bash
# Build the fixture loaders/dumpers. They exist because ACAS's ledger tables
# are INDEXED (BDB) while the fixtures are flat frames (F-B007).
set -euo pipefail
cd "$(dirname "$0")"
for p in mkidx mkpldx loadbatch loadledger loadpost loadinv loadpinv loadpur loadana loadval loadsal loaddel loadoi3 \
         dumpval dumpsanal dumpinv dumppinv dumpsales dumpoi3 dumppost dumpbatch dumpledger; do
    cobc -free -x -o "$p" "$p.cbl"
done
