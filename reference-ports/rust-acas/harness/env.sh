#!/usr/bin/env bash
# ACAS harness environment — source this before driving ACAS in the parity harness.
# Mirrors the shape of upstream install-ACAS.sh but rooted in the harness sandbox
# instead of $HOME, so runs are hermetic and repeatable.

export ACAS_HOME="${ACAS_HOME:-/tmp/acas-harness-env}"
mkdir -p "$ACAS_HOME/ACAS" "$ACAS_HOME/IRS" "$ACAS_HOME/bin"

export ACAS_LEDGERS="$ACAS_HOME/ACAS"
export ACAS_IRS="$ACAS_HOME/IRS"
export ACAS_BIN="$ACAS_HOME/bin"

# Terminal needed for curses screen I/O under a pty
export TERM="${TERM:-xterm-256color}"
