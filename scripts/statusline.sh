#!/usr/bin/env bash
# CC-statusline-kit — Calm mode (抗焦虑档)
# Only answers two questions: 「还能聊多久?」(context left) + 「我在哪?」(directory)
# Receives Claude Code status JSON via stdin.

input=$(cat)

RESET='\033[0m'
DIM='\033[38;5;240m'
GRAY='\033[38;5;245m'
C_PATH='\033[38;5;110m'   # steel blue — directory
C_GIT='\033[38;5;108m'    # sage       — git branch
C_OK='\033[38;5;118m'     # lime       — plenty of context left
C_WARN='\033[38;5;220m'   # gold       — getting tight
C_LOW='\033[38;5;203m'    # coral red  — running out

# --- Context left ("额度") ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | xargs printf "%.0f" 2>/dev/null || echo "0")
left_pct=$(( 100 - used_pct ))
[ $left_pct -lt 0 ] && left_pct=0

# Color by remaining budget: >50% calm, 20-50% caution, <20% alert
if   [ $left_pct -gt 50 ]; then C_CTX="$C_OK"
elif [ $left_pct -gt 20 ]; then C_CTX="$C_WARN"
else C_CTX="$C_LOW"; fi

# --- Directory ("坐标") ---
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null)
proj_path=$(echo "$cwd" | sed "s|^${HOME}|~|")
[ -z "$proj_path" ] && proj_path="~"

git_branch=$(echo "$input" | jq -r '.git.branch // ""' 2>/dev/null)
git_dirty=$(echo "$input" | jq -r '.git.dirty // false' 2>/dev/null)
[ "$git_dirty" = "true" ] && git_suffix="*" || git_suffix=""

# Progress bar: make_bar <pct> <width> <color>
make_bar() {
  local pct=$1 width=${2:-14} color=$3
  local filled=$(( pct * width / 100 ))
  [ $filled -gt $width ] && filled=$width
  [ $filled -lt 0 ] && filled=0
  local empty=$(( width - filled )) bar=""
  for ((i=0;i<filled;i++)); do bar+="█"; done
  for ((i=0;i<empty;i++)); do bar+="░"; done
  echo -e "${color}${bar}${RESET}"
}

bar=$(make_bar "$left_pct" 14 "$C_CTX")

# Line 1 — 还能聊多久
line1="${GRAY}Context left${RESET} ${bar} ${C_CTX}${left_pct}%${RESET}"

# Line 2 — 我在哪
line2="${C_PATH}${proj_path}${RESET}"
[ -n "$git_branch" ] && line2+=" ${C_GIT}git:(${git_branch}${git_suffix})${RESET}"

echo -e "$line1"
echo -e "$line2"
