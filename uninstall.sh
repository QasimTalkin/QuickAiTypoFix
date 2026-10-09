#!/usr/bin/env bash
# Removes TypoFix and its saved settings. Usage: ./uninstall.sh [--install-dir DIR]
set -euo pipefail

APP_NAME="TypoFix"
BUNDLE_ID="io.github.qasimtalkin.TypoFix"
DIRS=("/Applications" "$HOME/Applications")

if [[ "${1:-}" == "--install-dir" ]]; then DIRS=("${2:?--install-dir needs a value}"); fi

pkill -x "$APP_NAME" 2>/dev/null && echo "Stopped $APP_NAME" || true
for d in "${DIRS[@]}"; do
  if [[ -d "$d/$APP_NAME.app" ]]; then rm -rf "$d/$APP_NAME.app" && echo "Removed $d/$APP_NAME.app"; fi
done
defaults delete "$BUNDLE_ID" 2>/dev/null && echo "Removed saved settings" || true

cat <<EOM

One leftover only you can remove (macOS protects it):
  System Settings → Privacy & Security → Accessibility → select $APP_NAME → click "−".
(Ollama and the qwen2.5:1.5b model are untouched. Remove the model with: ollama rm qwen2.5:1.5b)
EOM
