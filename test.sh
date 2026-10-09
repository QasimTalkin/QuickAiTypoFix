#!/usr/bin/env bash
# Runs the safety-check tests. Needs only the Command Line Tools.
set -euo pipefail
cd "$(dirname "$0")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
swiftc -O -o "$TMP/check" Sources/TypoFix/CorrectionGuard.swift Tests/main.swift
"$TMP/check"
