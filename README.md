# TypoFix

**Select text. Press ⌘U. Typos fixed in place.** No popup, no cloud account, runs on a tiny local model.

```text
before:  i has a apple and she dont like it
after:   I have an apple and she doesn't like it.
```

TypoFix is a small macOS menu-bar app. Select text in almost any app (Slack, Chrome, Notes, Mail…), press **⌘U**, and a moment later your selection is replaced with the corrected version. By default it uses [Ollama](https://ollama.com) with **`qwen2.5:1.5b`**, so it takes about a second and your text never leaves your Mac.

> This repository is called **QuickAiTypoFix**; the app it installs is called **TypoFix**.
>
> Early version (0.1.0). Tested on Apple Silicon with macOS 26. Based on [GrammifyAI](https://github.com/harentius/GrammifyAI) (see [Credits](#credits)).

## Quick start

You need: **macOS 14.5+**, the **Xcode Command Line Tools** (`xcode-select --install`, no full Xcode needed) and **[Ollama](https://ollama.com/download)**.

```bash
git clone https://github.com/QasimTalkin/QuickAiTypoFix.git
cd QuickAiTypoFix
./install.sh
```

`install.sh` downloads `qwen2.5:1.5b` (about 1 GB, once) if you don't have it, builds the app, installs it to `/Applications`, points it at your local Ollama, and launches it.

**One manual step**, because macOS only lets you do it yourself: open **System Settings → Privacy & Security → Accessibility**, click **+**, choose `TypoFix.app`, and switch it on. The installer opens that page for you.

Now try it: type `i has a apple and she dont like it` in any text field, select it, press **⌘U**.

## How it works

1. **⌘U** reads your selected text through the macOS Accessibility API.
2. It sends the text to the model with a "correct this writing" prompt.
3. It sanity-checks the answer, then pastes it over your selection (a simulated ⌘V). The fix also stays on your clipboard.

The menu bar icon tells you what's happening: a wand when idle, `…` while working, and a warning triangle plus a beep if something went wrong (click it to read why).

## Safety checks

Because there's no preview, TypoFix **refuses** results that look wrong and leaves your text alone. It won't paste an empty answer, raw JSON, a result much shorter or longer than your text, or something that looks like a rewrite or translation. It also won't paste if you switched apps or changed the selection while the model was working. In those cases it beeps and puts the correction on your clipboard instead where that makes sense. Pressed it by mistake? **⌘Z** in that app undoes the replacement.

Small models still make mistakes, so read what it did. Run `./test.sh` to see the safety checks pass.

## Choosing a model

The default is `qwen2.5:1.5b`. Measured on an Apple Silicon Mac with 48 GB of RAM:

| Model | Typical time per fix (warm) | Notes |
|---|---|---|
| `qwen2.5:1.5b` (default) | about 0.5–1.5 s | Fast. Best on one paragraph at a time. |
| Reasoning models (e.g. `gemma4`) | about 6 s for a sentence, 25–35 s for a few lines | Slow here: TypoFix can't switch their "thinking" off. |

Use another model with `./install.sh --model <name>` (it must appear in `ollama list`), or change it any time in the menu bar → **Settings**.

To use a cloud API instead of Ollama (your text is then sent to that provider):

```bash
./install.sh --url https://api.openai.com/v1 --model gpt-4o-mini
```

then open the menu bar icon → **Settings** and paste your API key. The key is stored unencrypted in the app's preferences, so use a key you can rotate.

## Known limitations

- **Multi-line text with a small model.** `qwen2.5:1.5b` sometimes drops lines or rewrites more than it should. TypoFix refuses the worst cases (you'll hear a beep). Select one paragraph at a time, or use a larger model.
- **It can still be wrong.** One 1.5B-model run translated an English sentence into German; the similarity check now catches that, but not every mistake.
- **Paste-based replacement.** It overwrites your clipboard with the corrected text. Apps that don't accept ⌘V or don't expose their selection (for example Google Docs) won't work.
- **Removed from upstream GrammifyAI:** correction history, statistics, the diff popup and auto-update. These need Xcode to build.

## Troubleshooting

| What you see | What to do |
|---|---|
| Beep and "macOS has not allowed this build…" | Open Accessibility settings, select **TypoFix**, click **−**, then **+** and add `/Applications/TypoFix.app` again and switch it on. |
| "Network error" or connection refused | Ollama isn't running. Open the Ollama app (or run `ollama serve`). |
| "HTTP error 404" / model not found | Run `ollama pull qwen2.5:1.5b`, and make sure the model name in **Settings** matches `ollama list`. |
| Beep and "much shorter / rewrite / translation" | The safety check refused the result. Select less text and try again. |
| ⌘U does nothing and nothing beeps | Another app owns ⌘U (such as the original GrammifyAI). Quit it, or change the shortcut in **Settings**. |
| First fix after a break takes a few seconds | Ollama unloads idle models after about 5 minutes; the first request reloads it. |

## Uninstall

```bash
./uninstall.sh
```

This removes the app and its settings. Remove TypoFix from the Accessibility list yourself (macOS protects it). Ollama and the model stay; remove the model with `ollama rm qwen2.5:1.5b`.

## For AI agents: copy-paste setup prompt

Paste this into Claude Code, Codex, or any coding agent that can run shell commands on your Mac:

```text
Set up TypoFix on this Mac: https://github.com/QasimTalkin/QuickAiTypoFix
It is a macOS menu-bar app: select text, press Cmd+U, and the typos are fixed in place using a
local Ollama model (qwen2.5:1.5b).

Rules:
- macOS only. Never ask for, type, or store passwords or API keys.
- Do not edit macOS privacy settings or run tccutil. The Accessibility permission must be granted
  by the human, by hand.
- Ask the human before installing anything that is missing (Xcode Command Line Tools, Ollama) and
  before the model download (about 1 GB).
- Report honestly what worked and what failed. Do not claim it works until the final check passes.

Steps:
1. Check prerequisites:
   - `sw_vers -productVersion` must be 14.5 or newer.
   - `xcode-select -p` must succeed. If not, tell the human to run `xcode-select --install`, then wait.
   - `ollama --version` must succeed. If not, tell the human to install it from
     https://ollama.com/download (or `brew install ollama`) and open the Ollama app.
2. Confirm Ollama is running: `curl -fsS http://localhost:11434/api/tags`
3. `git clone https://github.com/QasimTalkin/QuickAiTypoFix.git && cd QuickAiTypoFix`
4. Run `./test.sh`. It must end with "All checks passed".
5. Run `./install.sh`. It builds the app, pulls qwen2.5:1.5b if missing, installs
   /Applications/TypoFix.app, writes its settings and launches it.
6. Verify:
   - `pgrep -x TypoFix` prints a process id.
   - `defaults read io.github.qasimtalkin.TypoFix AI_MODEL` prints qwen2.5:1.5b.
   - `curl -s http://localhost:11434/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"qwen2.5:1.5b","messages":[{"role":"user","content":"Fix the typos, reply with only the fixed text: i has a apple"}]}'`
     returns a sensible answer.
7. Tell the human to do the one manual step: System Settings > Privacy & Security > Accessibility >
   "+" > choose /Applications/TypoFix.app > switch it on. Then ask them to type
   "i has a apple and she dont like it" in any text field, select it, and press Cmd+U.
8. If TypoFix says "macOS has not allowed this build", tell the human to select TypoFix in the
   Accessibility list, click "-", then add /Applications/TypoFix.app again with "+".
9. Summarize: what you installed, the exact commands you ran, and anything left for the human.
```

## Credits

TypoFix is a fork of **[GrammifyAI](https://github.com/harentius/GrammifyAI)** by harentius (MIT), reworked to replace text in place, add safety checks, and install with one command. It bundles a copy of **[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)** by Sindre Sorhus (MIT) in `Vendor/`, with its Xcode-only `#Preview` blocks removed. Both licenses are kept in this repository.

## License

MIT. See [LICENSE](LICENSE).
