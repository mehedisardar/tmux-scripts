# tmux

A terminal UI for managing tmux sessions — with animations, arrow-key navigation, and a full color theme.

![bash](https://img.shields.io/badge/bash-5.0%2B-blue) ![tmux](https://img.shields.io/badge/tmux-required-orange) ![platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)

---

## features

- Animated intro with ASCII logo and progress bar
- Arrow-key (or `j`/`k`) driven menu — no typing numbers
- Session sidebar showing attached state and age at a glance
- Detail panel before killing a session so you know what you're destroying
- Confirmation dialog for destructive actions, defaulting to **No**
- Toast notifications for success/error feedback
- Runs in an alternate screen buffer — your terminal history is left untouched

## requirements

- `bash` 5.0+
- `tmux`
- A terminal emulator that supports 256 colors and UTF-8 (basically anything modern)

## installation

```bash
git clone https://github.com/yourname/tmux-manager.git
cd tmux-manager
chmod +x tmux-manager.sh
```

To run it from anywhere:

```bash
sudo mv tmux-manager.sh /usr/local/bin/tmux-manager
```

## usage

```bash
./tmux-manager.sh
# or, if installed to PATH:
tmux-manager
```

You'll land on the main menu after a short intro animation.

### navigation

| Key | Action |
|---|---|
| `↑` / `↓` or `j` / `k` | Move through menu items |
| `Enter` | Select |
| `1`–`4` | Jump directly to a menu item |
| `q` / `Q` | Quit |
| `Esc` | Go back from a sub-screen |

### menu options

**Attach Session** — lists all active sessions with their window count and age. Select one to attach.

**New Session** — prompts for a name and drops you straight into a new tmux session. Warns you if the name is already taken.

**Kill Session** — select a session, review its window list in a detail panel, then confirm before it's terminated.

**Kill All Sessions** — shows every session that will be destroyed and requires explicit confirmation before running `tmux kill-server`.

**Quit** — exits back to your shell cleanly.

## notes

- The script uses `set -euo pipefail`, so unexpected errors exit early rather than silently continuing.
- On exit (including `Ctrl-C`), the alternate screen buffer and cursor are always restored — you won't be left with a broken terminal.
- The session sidebar only appears when your terminal is wider than 90 columns.
- If `tput` isn't available, the script falls back to 80×24 dimensions gracefully.
