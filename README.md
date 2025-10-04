# tmux session manager

A simple bash script for managing tmux sessions without needing to remember all the commands.

## what it does

This script gives you a menu to:
- List all active tmux sessions
- Attach to an existing session
- Kill a specific session
- Create a new session
- Kill all sessions at once

Basically just wraps the common tmux commands in a menu so you don't have to type them out every time.

## installation

Clone or download the script somewhere, then make it executable:

```bash
chmod +x tmux-manager.sh
```

If you want to run it from anywhere, move it to your PATH:

```bash
sudo mv tmux-manager.sh /usr/local/bin/tmux-manager
```

## usage

Just run it:

```bash
./tmux-manager.sh
```

Or if you moved it to your PATH:

```bash
tmux-manager
```

You'll see a menu with options. Pick a number and press enter. Most options will bring you back to the main menu when you're done.

## requirements

- bash
- tmux (obviously)

That's it. Should work on Linux and macOS.

## notes

The script uses `set -euo pipefail` at the top, so it'll exit if anything goes wrong. If you're getting errors, make sure tmux is installed and running properly.

If you want to customize the prompts or messages, they're pretty straightforward to edit in the script itself.
