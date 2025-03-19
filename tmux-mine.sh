#!/bin/bash

# Define session name (default)
SESSION_NAME="default"

# Check if a session is already running
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Attaching to existing tmux session: $SESSION_NAME"
    tmux attach-session -t $SESSION_NAME
else
    echo "No existing session found. Creating a new one: $SESSION_NAME"
    tmux new-session -s $SESSION_NAME
fi
