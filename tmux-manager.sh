#!/usr/bin/env bash
set -euo pipefail

get_sessions() {
  mapfile -t SESSIONS < <(tmux ls -F "#{session_name}" 2>/dev/null || true)
}

list_sessions() {
  if get_sessions && ((${#SESSIONS[@]})); then
    echo -e "\n📋 Active sessions:"
    printf "  • %s\n" "${SESSIONS[@]}"
  else
    echo -e "\n📋 No active tmux sessions."
  fi
  read -rsp $'\nPress ENTER to go back to main menu…'
}

attach_session() {
  get_sessions
  [[ ${#SESSIONS[@]} -eq 0 ]] && { echo "⚠️ No sessions to attach."; read -rsp $'\nPress ENTER to go back to main menu…'; return; }
  PS3="▶ Attach to session (choose number): "
  select NAME in "${SESSIONS[@]}" "Go back"; do
    if [[ $NAME == "Go back" ]]; then
      echo "↩️ Returning to main menu…"; sleep 0.5; return
    elif [[ -n $NAME ]]; then
      tmux attach-session -t "$NAME"
      break
    else
      echo "❌ Invalid choice"
    fi
  done
}

kill_session() {
  get_sessions
  [[ ${#SESSIONS[@]} -eq 0 ]] && { echo "⚠️ No sessions to kill."; read -rsp $'\nPress ENTER to go back to main menu…'; return; }
  PS3="❌ Kill session (choose number): "
  select NAME in "${SESSIONS[@]}" "Go back"; do
    if [[ $NAME == "Go back" ]]; then
      echo "↩️ Returning to main menu…"; sleep 0.5; return
    elif [[ -n $NAME ]]; then
      tmux kill-session -t "$NAME" && echo "✅ Killed session: $NAME"
      read -rsp $'\nPress ENTER to go back to main menu…'
      break
    else
      echo "❌ Invalid choice"
    fi
  done
}

new_session() {
  read -rp "➕ Enter new session name: " NAME
  if [[ -z $NAME ]]; then
    echo "⚠️ Name cannot be empty."
  else
    tmux new-session -s "$NAME"
    echo "✅ Created session: $NAME"
  fi
  read -rsp $'\nPress ENTER to go back to main menu…'
}

kill_all() {
  read -rp "💣 Really kill ALL tmux sessions? (y/N): " REPLY
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux kill-server && echo "✅ All sessions killed."
  else
    echo "↩️ Aborted."
  fi
  read -rsp $'\nPress ENTER to go back to main menu…'
}

MAIN_OPTIONS=("List sessions" "Attach session" "Kill session" "New session" "Kill all sessions" "Exit")
while true; do
  clear
  echo "===== TMUX SESSION MANAGER ====="
  PS3="Select action ➤ "
  select CHOICE in "${MAIN_OPTIONS[@]}"; do
    case $CHOICE in
      "List sessions")    list_sessions; break;;
      "Attach session")   attach_session; break;;
      "Kill session")     kill_session; break;;
      "New session")      new_session; break;;
      "Kill all sessions")kill_all; break;;
      "Exit")             echo "👋 Goodbye!"; exit 0;;
      *) echo "❌ Invalid choice";;
    esac
  done
done
