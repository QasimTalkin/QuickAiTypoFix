#!/usr/bin/env bash
# Builds build/TypoFix.app using only the Xcode Command Line Tools (no Xcode needed).
set -euo pipefail
cd "$(dirname "$0")"

BUNDLE_ID="io.github.qasimtalkin.TypoFix"
APP="build/TypoFix.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)"

rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/TypoFix" "$APP/Contents/MacOS/TypoFix"
cp Support/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp -R "$BIN"/*.bundle "$APP/Contents/Resources/" 2>/dev/null || true

# Ad-hoc signing normally pins the macOS Accessibility permission to this exact binary, so every
# rebuild would need it re-granted. An identifier-based requirement keeps the grant across rebuilds.
codesign --force --deep --sign - -r="designated => identifier \"$BUNDLE_ID\"" "$APP"
echo "Built $APP"
