#!/usr/bin/env bash
set -euo pipefail

# ─── Theme & Colors ───────────────────────────────────────────────────────────
RST=$'\e[0m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
ITALIC=$'\e[3m'

# Foreground
FG_BLACK=$'\e[30m'
FG_RED=$'\e[31m'
FG_GREEN=$'\e[32m'
FG_YELLOW=$'\e[33m'
FG_BLUE=$'\e[34m'
FG_MAGENTA=$'\e[35m'
FG_CYAN=$'\e[36m'
FG_WHITE=$'\e[37m'
FG_GRAY=$'\e[90m'

# Background
BG_BLACK=$'\e[40m'
BG_RED=$'\e[41m'
BG_GREEN=$'\e[42m'
BG_YELLOW=$'\e[43m'
BG_BLUE=$'\e[44m'
BG_MAGENTA=$'\e[45m'
BG_CYAN=$'\e[46m'
BG_WHITE=$'\e[47m'
BG_BRIGHT_BLACK=$'\e[100m'

# Accent palette
ACCENT="${BOLD}${FG_CYAN}"
ACCENT2="${BOLD}${FG_MAGENTA}"
HIGHLIGHT="${BOLD}${FG_BLACK}${BG_CYAN}"
DANGER="${BOLD}${FG_RED}"
SUCCESS="${BOLD}${FG_GREEN}"
WARN="${BOLD}${FG_YELLOW}"
MUTED="${DIM}${FG_GRAY}"
BORDER="${FG_CYAN}"
BORDER_DIM="${DIM}${FG_CYAN}"

# Box-drawing characters
BX_TL="╭" BX_TR="╮" BX_BL="╰" BX_BR="╯"
BX_H="─" BX_V="│" BX_LT="├" BX_RT="┤"

# ─── Terminal Helpers ─────────────────────────────────────────────────────────
term_width()  { tput cols  2>/dev/null || echo 80; }
term_height() { tput lines 2>/dev/null || echo 24; }
hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
move_to()     { printf '\e[%d;%dH' "$1" "$2"; }
clear_line()  { printf '\e[2K'; }
clear_below() { printf '\e[J'; }
save_cursor() { printf '\e[s'; }
restore_cursor() { printf '\e[u'; }

cleanup() {
  show_cursor
  stty echo 2>/dev/null
  tput rmcup 2>/dev/null
  printf '%s' "$RST"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# ─── Animation Helpers ────────────────────────────────────────────────────────
typewrite() {
  local text="$1" delay="${2:-0.02}"
  for ((i = 0; i < ${#text}; i++)); do
    printf '%s' "${text:$i:1}"
    sleep "$delay"
  done
}

fade_in_line() {
  local row="$1" col="$2" text="$3" color="${4:-$RST}"
  local len=${#text}
  move_to "$row" "$col"
  # Print dim first, then bold
  printf '%s%s%s' "$DIM" "$text" "$RST"
  sleep 0.03
  move_to "$row" "$col"
  printf '%s%s%s' "$color" "$text" "$RST"
}

spinner_brief() {
  local msg="$1" duration="${2:-0.5}"
  local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  local end_time i=0
  end_time=$(awk -v now="$(date +%s)" -v dur="$duration" 'BEGIN{printf "%d", now + int(dur + 1)}')
  hide_cursor
  while (( $(date +%s) < end_time )); do
    printf '\r  %s%s%s %s' "$ACCENT" "${frames[$i]}" "$RST" "$msg"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.08
  done
  printf '\r\e[2K'
}

progress_bar() {
  local width=30 msg="${1:-Loading}"
  local tw
  tw=$(term_width)
  # Total visible width: bar + space + "100%" + 2 spaces + msg
  local total_w=$(( width + 1 + 4 + 2 + ${#msg} ))
  local col=$(( (tw - total_w) / 2 ))
  if (( col < 1 )); then col=1; fi
  hide_cursor
  for ((i = 0; i <= width; i++)); do
    local filled="" empty=""
    for ((j = 0; j < i; j++)); do filled+="━"; done
    for ((j = i; j < width; j++)); do empty+="─"; done
    local pct=$(( i * 100 / width ))
    printf '\r\e[%dG%s%s%s%s%s %3d%%  %s' "$col" "$ACCENT" "$filled" "$MUTED" "$empty" "$RST" "$pct" "$msg"
    sleep 0.02
  done
  printf '\r\e[2K'
}

pulse_text() {
  local row="$1" col="$2" text="$3" times="${4:-2}"
  for ((t = 0; t < times; t++)); do
    move_to "$row" "$col"
    printf '%s%s%s' "$BOLD${FG_WHITE}" "$text" "$RST"
    sleep 0.15
    move_to "$row" "$col"
    printf '%s%s%s' "$ACCENT" "$text" "$RST"
    sleep 0.15
  done
}

# ─── Drawing Primitives ──────────────────────────────────────────────────────
draw_box() {
  local row="$1" col="$2" width="$3" height="$4" color="${5:-$BORDER}"
  local inner=$(( width - 2 ))
  local hline=""
  for ((i = 0; i < inner; i++)); do hline+="$BX_H"; done

  move_to "$row" "$col"
  printf '%s%s%s%s%s' "$color" "$BX_TL" "$hline" "$BX_TR" "$RST"

  for ((r = 1; r < height - 1; r++)); do
    move_to $(( row + r )) "$col"
    printf '%s%s%s' "$color" "$BX_V" "$RST"
    move_to $(( row + r )) $(( col + width - 1 ))
    printf '%s%s%s' "$color" "$BX_V" "$RST"
  done

  move_to $(( row + height - 1 )) "$col"
  printf '%s%s%s%s%s' "$color" "$BX_BL" "$hline" "$BX_BR" "$RST"
}

draw_hline() {
  local row="$1" col="$2" width="$3" color="${4:-$BORDER_DIM}"
  move_to "$row" "$col"
  printf '%s%s' "$color" "$BX_LT"
  for ((i = 0; i < width - 2; i++)); do printf '%s' "$BX_H"; done
  printf '%s%s' "$BX_RT" "$RST"
}

center_text() {
  local row="$1" width="$2" text="$3" color="${4:-$RST}"
  # Strip ANSI for length calculation
  local plain
  plain=$(printf '%s' "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local plen=${#plain}
  local col=$(( (width - plen) / 2 + 1 ))
  if (( col < 1 )); then col=1; fi
  move_to "$row" "$col"
  printf '%s%s%s' "$color" "$text" "$RST"
}

fill_row() {
  local row="$1" col="$2" width="$3" char="${4:- }" color="${5:-$RST}"
  move_to "$row" "$col"
  printf '%s' "$color"
  for ((i = 0; i < width; i++)); do printf '%s' "$char"; done
  printf '%s' "$RST"
}

# ─── ASCII Art Logo ──────────────────────────────────────────────────────────
LOGO=(
  "  ████████╗███╗   ███╗██╗   ██╗██╗  ██╗"
  "  ╚══██╔══╝████╗ ████║██║   ██║╚██╗██╔╝"
  "     ██║   ██╔████╔██║██║   ██║ ╚███╔╝ "
  "     ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗ "
  "     ██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
  "     ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
)

draw_logo() {
  local start_row="$1" w
  w=$(term_width)
  local colors=("$FG_CYAN" "$FG_CYAN" "$FG_MAGENTA" "$FG_MAGENTA" "$FG_BLUE" "$FG_BLUE")
  for i in "${!LOGO[@]}"; do
    local line="${LOGO[$i]}"
    local plain
    plain=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
    local plen=${#plain}
    local col=$(( (w - plen) / 2 ))
    if (( col < 1 )); then col=1; fi
    move_to $(( start_row + i )) "$col"
    printf '%s%s%s%s' "${BOLD}" "${colors[$i]}" "$line" "$RST"
    sleep 0.04
  done
}

# ─── Session Data ─────────────────────────────────────────────────────────────
SESSIONS=()
SESSION_INFO=()

refresh_sessions() {
  SESSIONS=()
  SESSION_INFO=()
  local raw
  raw=$(tmux ls -F "#{session_name}|#{session_windows}|#{session_attached}|#{session_created}" 2>/dev/null || true)
  if [[ -n "$raw" ]]; then
    while IFS= read -r line; do
      local name wins att created
      name="${line%%|*}"; line="${line#*|}"
      wins="${line%%|*}"; line="${line#*|}"
      att="${line%%|*}"; line="${line#*|}"
      created="$line"
      SESSIONS+=("$name")
      local status_icon status_color
      if [[ "$att" -gt 0 ]]; then
        status_icon="●"
        status_color="$SUCCESS"
      else
        status_icon="○"
        status_color="$MUTED"
      fi
      local age=""
      if [[ -n "$created" ]]; then
        local now
        now=$(date +%s)
        local diff=$(( now - created ))
        if (( diff < 60 )); then
          age="${diff}s ago"
        elif (( diff < 3600 )); then
          age="$(( diff / 60 ))m ago"
        elif (( diff < 86400 )); then
          age="$(( diff / 3600 ))h ago"
        else
          age="$(( diff / 86400 ))d ago"
        fi
      fi
      SESSION_INFO+=("${status_color}${status_icon}${RST} ${BOLD}${name}${RST}  ${MUTED}${wins} win${RST}  ${MUTED}${age}${RST}")
    done <<< "$raw"
  fi
}

# ─── Interactive Selector ─────────────────────────────────────────────────────
# Arrow-key driven menu; returns selected index in SEL_IDX, or -1 for escape.
SEL_IDX=0

interactive_select() {
  local -n items_ref=$1
  local title="$2"
  local start_row="$3"
  local count=${#items_ref[@]}

  if (( count == 0 )); then SEL_IDX=-1; return; fi

  local cur=0
  local w
  w=$(term_width)
  local box_w=$(( w - 8 ))
  if (( box_w > 72 )); then box_w=72; fi
  local box_col=$(( (w - box_w) / 2 ))
  local box_h=$(( count + 5 ))

  hide_cursor

  # Draw selection box
  draw_box "$start_row" "$box_col" "$box_w" "$box_h" "$BORDER"
  move_to $(( start_row + 1 )) $(( box_col + 2 ))
  printf '%s %s %s' "$ACCENT" "$title" "$RST"
  draw_hline $(( start_row + 2 )) "$box_col" "$box_w"

  local hint_row=$(( start_row + box_h ))
  center_text "$hint_row" "$w" "↑↓ navigate  ⏎ select  esc back" "$MUTED"

  while true; do
    for ((i = 0; i < count; i++)); do
      local r=$(( start_row + 3 + i ))
      move_to "$r" $(( box_col + 2 ))
      # Clear the inner area
      printf '%*s' $(( box_w - 4 )) ""
      move_to "$r" $(( box_col + 2 ))
      if (( i == cur )); then
        printf ' %s▸ %s%s' "$ACCENT" "${items_ref[$i]}" "$RST"
      else
        printf '   %s' "${items_ref[$i]}"
      fi
    done

    # Read key
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.05 seq || true
        case "$seq" in
          '[A') if (( cur > 0 )); then cur=$(( cur - 1 )); fi ;;            # Up
          '[B') if (( cur < count - 1 )); then cur=$(( cur + 1 )); fi ;;  # Down
          *)    SEL_IDX=-1; return ;;                       # Esc alone
        esac
        ;;
      '')  # Enter
        SEL_IDX=$cur
        return
        ;;
      'k') if (( cur > 0 )); then cur=$(( cur - 1 )); fi ;;   # vim up
      'j') if (( cur < count - 1 )); then cur=$(( cur + 1 )); fi ;; # vim down
      'q') SEL_IDX=-1; return ;;
    esac
  done
}

# ─── Text Input ───────────────────────────────────────────────────────────────
INPUT_VALUE=""

interactive_input() {
  local prompt_text="$1"
  local start_row="$2"
  local w
  w=$(term_width)
  local box_w=$(( w - 8 ))
  if (( box_w > 60 )); then box_w=60; fi
  local box_col=$(( (w - box_w) / 2 ))

  draw_box "$start_row" "$box_col" "$box_w" 5 "$BORDER"
  move_to $(( start_row + 1 )) $(( box_col + 2 ))
  printf '%s %s %s' "$ACCENT" "$prompt_text" "$RST"
  draw_hline $(( start_row + 2 )) "$box_col" "$box_w"

  move_to $(( start_row + 3 )) $(( box_col + 3 ))
  printf '%s▸%s ' "$ACCENT" "$RST"
  show_cursor

  local val=""
  while true; do
    IFS= read -rsn1 ch
    case "$ch" in
      $'\x1b')
        read -rsn2 -t 0.05 _ || true
        INPUT_VALUE=""
        hide_cursor
        return
        ;;
      '')  # Enter
        INPUT_VALUE="$val"
        hide_cursor
        return
        ;;
      $'\x7f'|$'\b')  # Backspace
        if [[ -n "$val" ]]; then
          val="${val%?}"
          move_to $(( start_row + 3 )) $(( box_col + 5 ))
          printf '%*s' $(( box_w - 7 )) ""
          move_to $(( start_row + 3 )) $(( box_col + 5 ))
          printf '%s' "$val"
        fi
        ;;
      *)
        if (( ${#val} < box_w - 8 )); then
          val+="$ch"
          move_to $(( start_row + 3 )) $(( box_col + 5 ))
          printf '%s' "$val"
        fi
        ;;
    esac
  done
}

# ─── Confirm Dialog ──────────────────────────────────────────────────────────
CONFIRM_RESULT=false

interactive_confirm() {
  local msg="$1"
  local start_row="$2"
  local w
  w=$(term_width)
  local box_w=$(( w - 8 ))
  if (( box_w > 60 )); then box_w=60; fi
  local box_col=$(( (w - box_w) / 2 ))

  draw_box "$start_row" "$box_col" "$box_w" 6 "$DANGER"
  move_to $(( start_row + 1 )) $(( box_col + 3 ))
  printf '%s⚠  WARNING%s' "$DANGER" "$RST"
  draw_hline $(( start_row + 2 )) "$box_col" "$box_w" "$DANGER"
  move_to $(( start_row + 3 )) $(( box_col + 3 ))
  printf '%s' "$msg"

  local opts=("Yes" "No")
  local cur=1  # default to "No"
  hide_cursor

  while true; do
    move_to $(( start_row + 4 )) $(( box_col + 3 ))
    printf '%*s' $(( box_w - 6 )) ""
    move_to $(( start_row + 4 )) $(( box_col + 3 ))
    for ((i = 0; i < 2; i++)); do
      if (( i == cur )); then
        printf ' %s[%s]%s ' "$ACCENT" "${opts[$i]}" "$RST"
      else
        printf '  %s%s%s  ' "$MUTED" "${opts[$i]}" "$RST"
      fi
    done

    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.05 seq || true
        case "$seq" in
          '[D'|'[C')  # Left/Right
            cur=$(( 1 - cur ))
            ;;
          *) CONFIRM_RESULT=false; return ;;
        esac
        ;;
      '')
        [[ $cur -eq 0 ]] && CONFIRM_RESULT=true || CONFIRM_RESULT=false
        return
        ;;
      'h') cur=$(( 1 - cur )) ;;
      'l') cur=$(( 1 - cur )) ;;
      'y'|'Y') CONFIRM_RESULT=true; return ;;
      'n'|'N'|'q') CONFIRM_RESULT=false; return ;;
    esac
  done
}

# ─── Toast / Notification ────────────────────────────────────────────────────
toast() {
  local msg="$1" color="${2:-$SUCCESS}" row="${3:-}"
  local w
  w=$(term_width)
  if [[ -z "$row" ]]; then
    row=$(( $(term_height) - 2 ))
  fi
  local plain
  plain=$(printf '%s' "$msg" | sed 's/\x1b\[[0-9;]*m//g')
  local plen=${#plain}
  local col=$(( (w - plen - 6) / 2 ))
  if (( col < 1 )); then col=1; fi

  move_to "$row" "$col"
  printf '%s %s  %s  %s %s' "${color}${BOLD}" " " "$msg" " " "$RST"
  sleep 1.2
  move_to "$row" "$col"
  printf '%*s' $(( plen + 6 )) ""
}

# ─── Status Bar ───────────────────────────────────────────────────────────────
draw_status_bar() {
  local w h
  w=$(term_width)
  h=$(term_height)
  move_to "$h" 1
  printf '%s' "$BG_BRIGHT_BLACK$FG_WHITE"
  printf '%*s' "$w" ""
  move_to "$h" 2
  local sess_count=${#SESSIONS[@]}
  local tmux_status
  if tmux info &>/dev/null; then
    tmux_status="${SUCCESS}tmux running${RST}${BG_BRIGHT_BLACK}${FG_WHITE}"
  else
    tmux_status="${DANGER}tmux stopped${RST}${BG_BRIGHT_BLACK}${FG_WHITE}"
  fi
  printf ' %s  │  %s sessions  │  %s ' "$tmux_status" "$sess_count" "$(date +%H:%M)"
  printf '%s' "$RST"
}

# ─── Session Detail Panel ────────────────────────────────────────────────────
draw_session_detail() {
  local name="$1" start_row="$2"
  local w
  w=$(term_width)
  local box_w=$(( w - 8 ))
  if (( box_w > 72 )); then box_w=72; fi
  local box_col=$(( (w - box_w) / 2 ))

  local info
  info=$(tmux ls -t "=$name" -F "Windows: #{session_windows}  |  Attached: #{?session_attached,yes,no}  |  Created: #{t:session_created}" 2>/dev/null || echo "No details available")
  local windows
  windows=$(tmux list-windows -t "=$name" -F "  #{window_index}: #{window_name} #{?window_active,← active,}" 2>/dev/null || true)

  local wcount=0
  if [[ -n "$windows" ]]; then
    wcount=$(echo "$windows" | wc -l)
  fi
  local panel_h=$(( wcount + 6 ))

  draw_box "$start_row" "$box_col" "$box_w" "$panel_h" "$BORDER_DIM"
  move_to $(( start_row + 1 )) $(( box_col + 2 ))
  printf ' %s%s Session: %s%s' "$ACCENT2" "$BOLD" "$name" "$RST"
  draw_hline $(( start_row + 2 )) "$box_col" "$box_w" "$BORDER_DIM"
  move_to $(( start_row + 3 )) $(( box_col + 3 ))
  printf '%s%s%s' "$MUTED" "$info" "$RST"
  draw_hline $(( start_row + 4 )) "$box_col" "$box_w" "$BORDER_DIM"

  local r=$(( start_row + 5 ))
  if [[ -n "$windows" ]]; then
    while IFS= read -r wline; do
      move_to "$r" $(( box_col + 2 ))
      if [[ "$wline" == *"← active"* ]]; then
        printf '%s%s%s' "$SUCCESS" "$wline" "$RST"
      else
        printf '%s%s%s' "$FG_WHITE" "$wline" "$RST"
      fi
      r=$(( r + 1 ))
    done <<< "$windows"
  fi
}

# ─── Main Menu Items ─────────────────────────────────────────────────────────
MENU_LABELS=("Attach Session" "New Session" "Kill Session" "Kill All Sessions" "Quit")
MENU_ICONS=("" "" "" "" "")
MENU_DESCS=(
  "Connect to an existing tmux session"
  "Create and enter a new tmux session"
  "Terminate a specific session"
  "Destroy all running sessions"
  "Exit tmux manager"
)

# ─── Screens ──────────────────────────────────────────────────────────────────

draw_main_screen() {
  local cur="$1"
  local w h
  w=$(term_width)
  h=$(term_height)

  printf '\e[2J'  # Clear screen
  draw_logo 2

  local subtitle="session manager"
  center_text 9 "$w" "$subtitle" "$MUTED"

  # Animated separator
  local sep_w=$(( w - 12 ))
  if (( sep_w > 68 )); then sep_w=68; fi
  local sep=""
  for ((i = 0; i < sep_w; i++)); do sep+="─"; done
  center_text 10 "$w" "$sep" "$BORDER_DIM"

  # Session count badge
  refresh_sessions
  local badge
  if (( ${#SESSIONS[@]} > 0 )); then
    badge="${SUCCESS}● ${#SESSIONS[@]} active session(s)${RST}"
  else
    badge="${MUTED}○ no active sessions${RST}"
  fi
  center_text 11 "$w" "$(printf '%s' "$badge" | sed 's/\x1b\[[0-9;]*m//g')" ""
  # Reprint with colors
  local plain_badge
  plain_badge=$(printf '%s' "$badge" | sed 's/\x1b\[[0-9;]*m//g')
  local badge_col=$(( (w - ${#plain_badge}) / 2 + 1 ))
  move_to 11 "$badge_col"
  printf '%s' "$badge"

  # Menu items
  local menu_start=13
  local box_w=48
  local box_col=$(( (w - box_w) / 2 ))
  local menu_count=${#MENU_LABELS[@]}

  for ((i = 0; i < menu_count; i++)); do
    local r=$(( menu_start + i ))
    move_to "$r" "$box_col"
    if (( i == cur )); then
      printf '%s  %s  %s  %s%s' "$HIGHLIGHT" "${MENU_ICONS[$i]}" "${MENU_LABELS[$i]}" "$(printf '%*s' $(( box_w - ${#MENU_LABELS[$i]} - 8 )) '')" "$RST"
    else
      printf '  %s%s%s  %s' "$FG_GRAY" "${MENU_ICONS[$i]}" "$RST" "${MENU_LABELS[$i]}"
    fi
  done

  # Description of selected item below the menu
  local desc_row=$(( menu_start + menu_count + 1 ))
  local desc="${MENU_DESCS[$cur]}"
  local max_desc=$(( box_w ))
  if (( ${#desc} > max_desc )); then desc="${desc:0:max_desc-1}…"; fi
  center_text "$desc_row" "$w" "$(printf '%*s' "$max_desc" '')" ""
  center_text "$desc_row" "$w" "$desc" "$MUTED"

  # Key hints
  local hint_row=$(( desc_row + 2 ))
  center_text "$hint_row" "$w" "────────────────────────────────" "$BORDER_DIM"
  center_text $(( hint_row + 1 )) "$w" "↑↓/jk navigate   ⏎ select   q quit" "$MUTED"

  # Session quick-list in sidebar if space allows
  if (( w > 90 && ${#SESSIONS[@]} > 0 )); then
    local side_col=$(( box_col + box_w + 4 ))
    local side_w=$(( w - side_col - 2 ))
    if (( side_w > 40 )); then side_w=40; fi
    if (( side_w > 12 )); then
      local side_h=$(( ${#SESSIONS[@]} + 3 ))
      if (( side_h > 12 )); then side_h=12; fi
      draw_box "$menu_start" "$side_col" "$side_w" "$side_h" "$BORDER_DIM"
      move_to $(( menu_start + 1 )) $(( side_col + 2 ))
      printf '%s Sessions%s' "$MUTED$BOLD" "$RST"
      local avail=$(( side_w - 4 ))
      for ((s = 0; s < ${#SESSIONS[@]} && s < side_h - 3; s++)); do
        move_to $(( menu_start + 2 + s )) $(( side_col + 2 ))
        local plain
        plain=$(printf '%s' "${SESSION_INFO[$s]}" | sed 's/\x1b\[[0-9;]*m//g')
        if (( ${#plain} <= avail )); then
          printf '%-*s' "$avail" ""
          move_to $(( menu_start + 2 + s )) $(( side_col + 2 ))
          printf '%s' "${SESSION_INFO[$s]}"
        else
          printf '%s%s…%s' "$MUTED" "${plain:0:avail-1}" "$RST"
        fi
      done
    fi
  fi

  draw_status_bar
}

screen_attach() {
  printf '\e[2J'
  local w
  w=$(term_width)
  center_text 2 "$w" "╸ Attach Session ╺" "$ACCENT"
  center_text 3 "$w" "────────────────────────────────" "$BORDER_DIM"

  refresh_sessions
  if (( ${#SESSIONS[@]} == 0 )); then
    center_text 6 "$w" "No active sessions found." "$WARN"
    center_text 8 "$w" "Press any key to return..." "$MUTED"
    read -rsn1
    return
  fi

  interactive_select SESSION_INFO "Select a session to attach" 5
  if (( SEL_IDX >= 0 )); then
    local name="${SESSIONS[$SEL_IDX]}"
    show_cursor
    tput rmcup 2>/dev/null || true
    # Show brief transition
    printf '\e[2J\e[H'
    printf '%s  Attaching to %s...%s\n' "$ACCENT" "$name" "$RST"
    sleep 0.3
    if ! tmux attach-session -t "=$name"; then
      printf '%s  Failed to attach (session may have ended)%s\n' "$DANGER" "$RST"
      sleep 1
    fi
    tput smcup 2>/dev/null || true
    hide_cursor
  fi
}

screen_new() {
  printf '\e[2J'
  local w
  w=$(term_width)
  center_text 2 "$w" "╸ New Session ╺" "$ACCENT"
  center_text 3 "$w" "────────────────────────────────" "$BORDER_DIM"

  interactive_input "Enter session name" 5
  if [[ -n "$INPUT_VALUE" ]]; then
    # Validate session name: no colons, periods, or control characters
    if [[ "$INPUT_VALUE" =~ [.:] || "$INPUT_VALUE" != "${INPUT_VALUE//[[:cntrl:]]/}" ]]; then
      toast "Invalid name (cannot contain . : or control chars)" "$DANGER"
      sleep 0.5
      return
    fi
    # Check if session already exists
    if tmux has-session -t "=$INPUT_VALUE" 2>/dev/null; then
      toast "Session '$INPUT_VALUE' already exists!" "$DANGER"
      sleep 0.5
      return
    fi
    show_cursor
    tput rmcup 2>/dev/null || true
    printf '\e[2J\e[H'
    spinner_brief "Creating session '$INPUT_VALUE'..." 0.4
    if ! tmux new-session -s "$INPUT_VALUE"; then
      tput smcup 2>/dev/null || true
      hide_cursor
      toast "Failed to create session" "$DANGER"
      return
    fi
    tput smcup 2>/dev/null || true
    hide_cursor
  fi
}

screen_kill() {
  printf '\e[2J'
  local w
  w=$(term_width)
  center_text 2 "$w" "╸ Kill Session ╺" "$DANGER"
  center_text 3 "$w" "────────────────────────────────" "$BORDER_DIM"

  refresh_sessions
  if (( ${#SESSIONS[@]} == 0 )); then
    center_text 6 "$w" "No active sessions to kill." "$WARN"
    center_text 8 "$w" "Press any key to return..." "$MUTED"
    read -rsn1
    return
  fi

  interactive_select SESSION_INFO "Select a session to kill" 5
  if (( SEL_IDX >= 0 )); then
    local name="${SESSIONS[$SEL_IDX]}"

    # Show detail before confirming
    local detail_row=$(( 5 + ${#SESSIONS[@]} + 7 ))
    draw_session_detail "$name" "$detail_row"

    local confirm_row=$(( detail_row + 10 ))
    interactive_confirm "Kill session '$name'?" "$confirm_row"
    if $CONFIRM_RESULT; then
      tmux kill-session -t "=$name" 2>/dev/null || true
      toast "Session '$name' terminated" "$SUCCESS"
    else
      toast "Cancelled" "$MUTED"
    fi
  fi
}

screen_kill_all() {
  printf '\e[2J'
  local w
  w=$(term_width)
  center_text 2 "$w" "╸ Kill All Sessions ╺" "$DANGER"
  center_text 3 "$w" "────────────────────────────────" "$BORDER_DIM"

  refresh_sessions
  if (( ${#SESSIONS[@]} == 0 )); then
    center_text 6 "$w" "No active sessions." "$WARN"
    center_text 8 "$w" "Press any key to return..." "$MUTED"
    read -rsn1
    return
  fi

  # Show all sessions that will be killed
  local r=5
  center_text "$r" "$w" "The following sessions will be destroyed:" "$FG_WHITE"
  r=$(( r + 2 ))

  local box_w=50
  local box_col=$(( (w - box_w) / 2 ))
  draw_box "$r" "$box_col" "$box_w" $(( ${#SESSIONS[@]} + 2 )) "$DANGER"
  for ((i = 0; i < ${#SESSIONS[@]}; i++)); do
    move_to $(( r + 1 + i )) $(( box_col + 3 ))
    printf '%s✕%s  %s' "$DANGER" "$RST" "${SESSION_INFO[$i]}"
  done

  local confirm_row=$(( r + ${#SESSIONS[@]} + 4 ))
  interactive_confirm "Destroy ALL ${#SESSIONS[@]} session(s)?" "$confirm_row"
  if $CONFIRM_RESULT; then
    spinner_brief "Killing all sessions..." 0.6
    tmux kill-server 2>/dev/null || true
    toast "All sessions destroyed" "$DANGER"
  else
    toast "Cancelled" "$MUTED"
  fi
}

screen_exit() {
  local w h
  w=$(term_width)
  h=$(term_height)
  printf '\e[2J'
  center_text $(( h / 2 - 1 )) "$w" "Goodbye!" "$ACCENT"
  center_text $(( h / 2 + 1 )) "$w" "━━━━━━━━━━" "$BORDER_DIM"
  sleep 0.4
}

# ─── Intro Animation ─────────────────────────────────────────────────────────
intro_animation() {
  local w h
  w=$(term_width)
  h=$(term_height)
  printf '\e[2J'

  draw_logo $(( h / 2 - 5 ))
  sleep 0.3

  center_text $(( h / 2 + 2 )) "$w" "session manager" "$MUTED"
  sleep 0.15
  progress_bar "Initializing"
  sleep 0.2
}

# ─── Menu Item Redraw ─────────────────────────────────────────────────────────
# Redraws only the old and new highlighted menu items instead of the full screen.
redraw_menu_items() {
  local old="$1" new="$2"
  local w
  w=$(term_width)
  local menu_start=13
  local menu_count=${#MENU_LABELS[@]}
  local box_w=48
  local box_col=$(( (w - box_w) / 2 ))

  # Un-highlight old item
  local r=$(( menu_start + old ))
  move_to "$r" "$box_col"
  printf '%*s' "$box_w" ""
  move_to "$r" "$box_col"
  printf '  %s%s%s  %s' "$FG_GRAY" "${MENU_ICONS[$old]}" "$RST" "${MENU_LABELS[$old]}"

  # Highlight new item
  r=$(( menu_start + new ))
  move_to "$r" "$box_col"
  printf '%*s' "$box_w" ""
  move_to "$r" "$box_col"
  printf '%s  %s  %s  %s%s' "$HIGHLIGHT" "${MENU_ICONS[$new]}" "${MENU_LABELS[$new]}" "$(printf '%*s' $(( box_w - ${#MENU_LABELS[$new]} - 8 )) '')" "$RST"

  # Update description area
  local desc_row=$(( menu_start + menu_count + 1 ))
  local desc="${MENU_DESCS[$new]}"
  local max_desc=$(( box_w ))
  if (( ${#desc} > max_desc )); then desc="${desc:0:max_desc-1}…"; fi
  center_text "$desc_row" "$w" "$(printf '%*s' "$max_desc" '')" ""
  center_text "$desc_row" "$w" "$desc" "$MUTED"
}

# ─── Main Loop ────────────────────────────────────────────────────────────────
main() {
  tput smcup 2>/dev/null || true   # Alternate screen buffer
  hide_cursor
  stty -echo 2>/dev/null || true

  intro_animation

  local cur=0
  local menu_count=${#MENU_LABELS[@]}

  draw_main_screen "$cur"

  while true; do
    # Read key
    IFS= read -rsn1 key
    local prev=$cur
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.05 seq || true
        case "$seq" in
          '[A') if (( cur > 0 )); then cur=$(( cur - 1 )); fi ;;
          '[B') if (( cur < menu_count - 1 )); then cur=$(( cur + 1 )); fi ;;
        esac
        ;;
      '')  # Enter
        case $cur in
          0) screen_attach ;;
          1) screen_new ;;
          2) screen_kill ;;
          3) screen_kill_all ;;
          4) screen_exit; exit 0 ;;
        esac
        draw_main_screen "$cur"
        continue
        ;;
      'k') if (( cur > 0 )); then cur=$(( cur - 1 )); fi ;;
      'j') if (( cur < menu_count - 1 )); then cur=$(( cur + 1 )); fi ;;
      '1') cur=0 ;;
      '2') cur=1 ;;
      '3') cur=2 ;;
      '4') cur=3 ;;
      'q'|'Q') screen_exit; exit 0 ;;
      *) continue ;;
    esac
    if (( prev != cur )); then
      redraw_menu_items "$prev" "$cur"
    fi
  done
}

main "$@"
