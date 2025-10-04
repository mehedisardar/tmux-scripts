#!/usr/bin/env bash
set -euo pipefail

get_sessions() {
  mapfile -t SESSIONS < <(tmux ls -F "#{session_name}" 2>/dev/null || true)
}

list_sessions() {
  if get_sessions && ((${#SESSIONS[@]})); then
    echo
    echo "Active sessions:"
    printf "  - %s\n" "${SESSIONS[@]}"
  else
    echo
    echo "No active tmux sessions"
  fi
  read -rsp $'\nPress ENTER to return...'
}

attach_session() {
  get_sessions
  [[ ${#SESSIONS[@]} -eq 0 ]] && { echo "No sessions available"; read -rsp $'\nPress ENTER to return...'; return; }
  PS3="Choose session number: "
  select NAME in "${SESSIONS[@]}" "Back"; do
    if [[ $NAME == "Back" ]]; then
      echo "Going back..."; sleep 0.3; return
    elif [[ -n $NAME ]]; then
      tmux attach-session -t "$NAME"
      break
    else
      echo "Not a valid option"
    fi
  done
}

kill_session() {
  get_sessions
  [[ ${#SESSIONS[@]} -eq 0 ]] && { echo "No sessions to kill"; read -rsp $'\nPress ENTER to return...'; return; }
  PS3="Kill which session? "
  select NAME in "${SESSIONS[@]}" "Back"; do
    if [[ $NAME == "Back" ]]; then
      echo "Going back..."; sleep 0.3; return
    elif [[ -n $NAME ]]; then
      tmux kill-session -t "$NAME" && echo "Killed: $NAME"
      read -rsp $'\nPress ENTER to return...'
      break
    else
      echo "Not a valid option"
    fi
  done
}

new_session() {
  read -rp "Session name: " NAME
  if [[ -z $NAME ]]; then
    echo "Name can't be empty"
  else
    tmux new-session -s "$NAME"
    echo "Created: $NAME"
  fi
  read -rsp $'\nPress ENTER to return...'
}

kill_all() {
  read -rp "Kill ALL sessions? (y/N): " REPLY
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux kill-server && echo "Done. All sessions killed."
  else
    echo "Cancelled"
  fi
  read -rsp $'\nPress ENTER to return...'
}

MAIN_OPTIONS=("List sessions" "Attach session" "Kill session" "New session" "Kill all sessions" "Exit")
while true; do
  clear
  echo "==== tmux session manager ===="
  PS3="Pick an option: "
  select CHOICE in "${MAIN_OPTIONS[@]}"; do
    case $CHOICE in
      "List sessions")    list_sessions; break;;
      "Attach session")   attach_session; break;;
      "Kill session")     kill_session; break;;
      "New session")      new_session; break;;
      "Kill all sessions")kill_all; break;;
      "Exit")             echo "Bye"; exit 0;;
      *) echo "Not a valid option";;
    esac
  done
done
