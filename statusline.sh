#!/bin/bash
# Claude Code status line: model + context window usage with color coding
# Green (<50%), Yellow (50-79%), Red (>=80%)
# Requires: jq

input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // empty')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [ -z "$CONTEXT_SIZE" ] || [ "$CONTEXT_SIZE" = "0" ]; then
  exit 0
fi

INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
TOTAL=$((INPUT_TOKENS + OUTPUT_TOKENS))

# Format tokens as Xk or X.Xk
fmt() {
  local v=$1
  if [ "$v" -ge 1000 ]; then
    printf "%dk" "$((v / 1000))"
  else
    printf "%d" "$v"
  fi
}

# Calculate percentage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$used" ]; then
  used=$((TOTAL * 100 / CONTEXT_SIZE))
fi

pct=$(printf '%.0f' "$used")
used_fmt=$(fmt "$TOTAL")
cap_fmt=$(fmt "$CONTEXT_SIZE")

if [ "$pct" -lt 50 ]; then
  color='\033[32m'  # green
elif [ "$pct" -lt 80 ]; then
  color='\033[33m'  # yellow
else
  color='\033[31m'  # red
fi

if [ -n "$MODEL" ]; then
  printf "${color}[%s] Ctx: %d%% (%s/%s)\033[0m\n" "$MODEL" "$pct" "$used_fmt" "$cap_fmt"
else
  printf "${color}Ctx: %d%% (%s/%s)\033[0m\n" "$pct" "$used_fmt" "$cap_fmt"
fi
