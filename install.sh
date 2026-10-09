#!/usr/bin/env bash
# TypoFix installer: builds the app, installs it, and points it at a local Ollama model.
#
#   ./install.sh                         # qwen2.5:1.5b via local Ollama (recommended)
#   ./install.sh --model llama3.2:3b     # a different local model
#   ./install.sh --url https://api.openai.com/v1 --model gpt-4o-mini   # a cloud API
#                                        # (then add your API key in the menu bar → Settings)
#
# Options: --model NAME  --url URL  --install-dir DIR  --no-pull  --no-launch  --help
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="TypoFix"
BUNDLE_ID="io.github.qasimtalkin.TypoFix"
MODEL="qwen2.5:1.5b"
API_URL="http://localhost:11434/v1"
INSTALL_DIR="/Applications"
MODEL_SET=0; URL_SET=0; PULL=1; LAUNCH=1

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)       MODEL="${2:?--model needs a value}"; MODEL_SET=1; shift 2 ;;
    --url)         API_URL="${2:?--url needs a value}"; URL_SET=1; shift 2 ;;
    --install-dir) INSTALL_DIR="${2:?--install-dir needs a value}"; shift 2 ;;
    --no-pull)     PULL=0; shift ;;
    --no-launch)   LAUNCH=0; shift ;;
    -h|--help)     sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)             fail "Unknown option: $1 (try --help)" ;;
  esac
done

is_local_url() { [[ "$API_URL" =~ ^https?://(localhost|127\.0\.0\.1|\[::1\])(:|/|$) ]]; }

say "1/5  Checking your Mac"
[[ "$(uname -s)" == "Darwin" ]] || fail "TypoFix only runs on macOS."
MACOS="$(sw_vers -productVersion)"
if [[ "$(printf '%s\n14.5\n' "$MACOS" | sort -V | head -1)" != "14.5" ]]; then
  fail "macOS 14.5 or newer is required (you have $MACOS)."
fi
if ! command -v swift >/dev/null 2>&1 || ! xcode-select -p >/dev/null 2>&1; then
  fail "The Xcode Command Line Tools are missing. Run: xcode-select --install   (then re-run ./install.sh)"
fi
echo "macOS $MACOS, $(swift --version 2>&1 | head -1)"

if is_local_url; then
  say "2/5  Checking Ollama and the model ($MODEL)"
  command -v ollama >/dev/null 2>&1 || fail "Ollama is not installed. Get it from https://ollama.com/download (or: brew install ollama), then re-run ./install.sh"
  if ! curl -fsS -m 3 http://localhost:11434/api/tags >/dev/null 2>&1; then
    if [[ -d /Applications/Ollama.app ]]; then
      echo "Starting Ollama..."; open -a Ollama
      for _ in $(seq 1 20); do curl -fsS -m 2 http://localhost:11434/api/tags >/dev/null 2>&1 && break; sleep 1; done
    fi
    curl -fsS -m 3 http://localhost:11434/api/tags >/dev/null 2>&1 || fail "Ollama is not running. Open the Ollama app (or run: ollama serve) and re-run ./install.sh"
  fi
  if ollama list | awk 'NR>1 {print $1}' | grep -qx "$MODEL"; then
    echo "$MODEL is already installed."
  elif [[ "$PULL" == "1" ]]; then
    echo "Downloading $MODEL (one time)..."; ollama pull "$MODEL"
  else
    fail "$MODEL is not installed and --no-pull was given. Run: ollama pull $MODEL"
  fi
else
  say "2/5  Using a remote API ($API_URL), skipping Ollama"
fi

say "3/5  Building $APP_NAME (about a minute the first time)"
./build.sh >/dev/null
echo "Built build/$APP_NAME.app"

say "4/5  Installing to $INSTALL_DIR"
if ! mkdir -p "$INSTALL_DIR" 2>/dev/null || [[ ! -w "$INSTALL_DIR" ]]; then
  INSTALL_DIR="$HOME/Applications"; mkdir -p "$INSTALL_DIR"
  echo "/Applications is not writable; using $INSTALL_DIR instead"
fi
pkill -x "$APP_NAME" 2>/dev/null && sleep 1 || true
rm -rf "$INSTALL_DIR/$APP_NAME.app"
ditto "build/$APP_NAME.app" "$INSTALL_DIR/$APP_NAME.app"
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
echo "Installed $INSTALL_DIR/$APP_NAME.app"

say "5/5  Configuring"
# Only fill in settings that are missing, so re-running never overwrites your own choices.
seed() { # key value force
  if [[ "$3" == "1" ]] || ! defaults read "$BUNDLE_ID" "$1" >/dev/null 2>&1; then
    defaults write "$BUNDLE_ID" "$1" -string "$2"
  fi
}
seed API_URL "$API_URL" "$URL_SET"
seed AI_MODEL "$MODEL" "$MODEL_SET"
if is_local_url; then seed OPENAI_TOKEN "ollama" 0; fi   # the app wants a non-empty key; Ollama ignores it
echo "URL:   $(defaults read "$BUNDLE_ID" API_URL)"
echo "Model: $(defaults read "$BUNDLE_ID" AI_MODEL)"

if pgrep -x GrammifyAI >/dev/null 2>&1; then
  printf '\n\033[33mNote:\033[0m the original GrammifyAI app is running and also uses ⌘U. Quit it so TypoFix gets the shortcut.\n'
fi

if [[ "$LAUNCH" == "1" ]]; then
  open "$INSTALL_DIR/$APP_NAME.app"
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
fi

cat <<EOM

Almost done: one manual step (macOS only lets you do this yourself)
  System Settings → Privacy & Security → Accessibility → click "+" → choose
  $INSTALL_DIR/$APP_NAME.app → switch it on.

Then try it: type   i has a apple and she dont like it   anywhere, select it, press ⌘U.
Problems? See the Troubleshooting section of the README.
EOM
