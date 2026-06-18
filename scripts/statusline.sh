#!/usr/bin/env bash
# Claude Code statusline script
# Receives JSON via stdin, outputs formatted status

input=$(cat)

# Colors
RESET='\033[0m'
BOLD='\033[1m'
YELLOW='\033[38;5;220m'
CYAN='\033[38;5;81m'
PINK='\033[38;5;205m'
GRAY='\033[38;5;245m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;40m'
BLUE='\033[38;5;33m'
DIM='\033[38;5;240m'

# Distinct accent palette — each metric on line 1 gets its own hue
C_CTX='\033[38;5;118m'    # lime green   — context %
C_COST='\033[38;5;220m'   # gold         — cost
C_RATE='\033[38;5;208m'   # orange       — burn rate $/hr
C_ADD='\033[38;5;48m'     # emerald      — lines added
C_DEL='\033[38;5;203m'    # coral red    — lines removed
C_TOKW='\033[38;5;81m'    # cyan         — token window
C_TOKS='\033[38;5;141m'   # violet       — token session
C_MODEL='\033[38;5;213m'  # orchid       — model name
C_GIT='\033[38;5;108m'    # sage         — git branch
C_PATH='\033[38;5;110m'   # steel blue   — project path

# Parse JSON fields
model=$(echo "$input" | jq -r '
  if (.model | type) == "array" then
    .model[0].display_name // .model[0].name // .model[0].id // "Claude"
  elif (.model | type) == "object" then
    .model.display_name // .model.name // .model.id // "Claude"
  elif (.model | type) == "string" then
    .model
  else "Claude"
  end' 2>/dev/null)
# Shorten model name if it's still in raw format: claude-sonnet-4-6 -> Sonnet 4.6
model=$(echo "$model" | sed 's/claude-//i' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
# Drop trailing parenthetical like "(1M context)" -> keep just "Opus 4.8"
model=$(echo "$model" | sed 's/ *([^)]*)//g' | sed 's/[[:space:]]*$//')

plan=$(echo "$input" | jq -r '.account.plan_display_name // .account.plan // "Pro"' 2>/dev/null)
# Capitalize plan
plan=$(echo "$plan" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null)
dir_name=$(basename "$cwd" 2>/dev/null)
# Project path, abbreviated with ~ (so you know which folder this window is in)
proj_path=$(echo "$cwd" | sed "s|^${HOME}|~|")
[ -z "$proj_path" ] && proj_path="~"

git_branch=$(echo "$input" | jq -r '.git.branch // ""' 2>/dev/null)
git_dirty=$(echo "$input" | jq -r '.git.dirty // false' 2>/dev/null)
if [ "$git_dirty" = "true" ]; then
  git_suffix="*"
else
  git_suffix=""
fi

effort=$(echo "$input" | jq -r '(.effort.level // .effort) // ""' 2>/dev/null)

# Permission mode (Shift+Tab cycles through these)
raw_mode=$(echo "$input" | jq -r '.output_style.name // ""' 2>/dev/null)
case "$raw_mode" in
  plan)           mode_label="Plan" ;          mode_color="$PINK" ;;
  acceptEdits)    mode_label="Edit" ;          mode_color="$CYAN" ;;
  bypassPermissions) mode_label="Bypass" ;    mode_color="${YELLOW}" ;;
  auto)           mode_label="Auto" ;          mode_color="$GREEN" ;;
  dontAsk)        mode_label="AutoRun" ;       mode_color="$GREEN" ;;
  *)              mode_label="Default" ;       mode_color="$DIM" ;;
esac

# Context window
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | xargs printf "%.0f" 2>/dev/null || echo "0")

# Context tokens (absolute) -> compact form like 104.9k
ctx_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null)
tokens_str=$(awk -v t="$ctx_tokens" 'BEGIN{ if(t>=1000) printf "%.1fk", t/1000; else printf "%d", t }' 2>/dev/null || echo "0")

# Lines added / removed (this session)
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0' 2>/dev/null)
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0' 2>/dev/null)

# Window tokens (current context occupancy), in millions
win_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0' 2>/dev/null)
win_m=$(awk -v t="$win_tokens" 'BEGIN{printf "%.2f", t/1000000}' 2>/dev/null || echo "0.00")

# Session cumulative tokens (sum over transcript: input+output+cache), in millions
transcript=$(echo "$input" | jq -r '.transcript_path // ""' 2>/dev/null)
sess_m=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  sess_m=$(python3 -c "
import json,sys
tot=0
for line in open('$transcript'):
    try: u=json.loads(line).get('message',{}).get('usage')
    except: u=None
    if u: tot+=u.get('input_tokens',0)+u.get('output_tokens',0)+u.get('cache_creation_input_tokens',0)+u.get('cache_read_input_tokens',0)
print('%.2f'%(tot/1000000))
" 2>/dev/null)
fi

# Session elapsed time (ms → min + sec)
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null | xargs printf "%.0f" 2>/dev/null || echo "0")
session_min=$(( duration_ms / 60000 ))
session_sec=$(( (duration_ms % 60000) / 1000 ))

# Session cost
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null | xargs printf "%.2f" 2>/dev/null || echo "0.00")

# Burn rate via ccusage (cached, ~0.06s; fails silently if unavailable)
hr_rate=""
CCUSAGE_BIN=$(command -v ccusage 2>/dev/null)
if [ -n "$CCUSAGE_BIN" ]; then
  cc_out=$(printf '%s' "$input" | "$CCUSAGE_BIN" statusline 2>/dev/null)
  hr_rate=$(echo "$cc_out" | grep -oE '\$[0-9.]+/hr' | grep -oE '[0-9.]+' | head -1)
fi

# Progress bar function: make_bar <pct> <width> <color>
make_bar() {
  local pct=$1
  local width=${2:-10}
  local color=${3:-$BLUE}
  local filled=$(( pct * width / 100 ))
  [ $filled -gt $width ] && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo -e "${color}${bar}${RESET}"
}


# --- Line 1 ---
line1=""

# [Model]
line1+="${C_MODEL}${model}${RESET}"


# git branch
if [ -n "$git_branch" ]; then
  line1+=" ${C_GIT}git:(${git_branch}${git_suffix})${RESET}"
fi

# project path (so each window shows which folder it's in)
line1+="  ${C_PATH}${proj_path}${RESET}"

# --- Line 2 ---
ctx_bar=$(make_bar "$ctx_pct" 10 "$C_CTX")

# Context: bar + pct only
line2="${GRAY}Context${RESET} ${ctx_bar} ${C_CTX}${ctx_pct}%${RESET}"

# Cost: session amount + burn-rate
line2+=" ${DIM}|${RESET} ${GRAY}Cost${RESET} ${C_COST}\$${session_cost}${RESET}"
if [ -n "$hr_rate" ]; then
  line2+=" ${DIM}·${RESET} ${C_RATE}\$${hr_rate}/hr${RESET}"
fi

# Lines added / removed (only if any churn)
if [ "$lines_added" != "0" ] || [ "$lines_removed" != "0" ]; then
  line2+=" ${DIM}|${RESET} ${C_ADD}+${lines_added}${RESET} ${C_DEL}-${lines_removed}${RESET}"
fi

# Tokens: window occupancy + session cumulative (millions)
line2+=" ${DIM}|${RESET} ${GRAY}Tok${RESET} ${C_TOKW}${win_m}M${RESET}"
if [ -n "$sess_m" ]; then
  line2+="${DIM}/${RESET}${C_TOKS}${sess_m}M${RESET}"
fi

# Output: Context line on top, model/path line below (swapped per request)
echo -e "$line2"
echo -e "${line1}"
