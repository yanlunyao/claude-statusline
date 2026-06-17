#!/bin/bash
# Claude Code status line: model + context window usage with color coding
# Green (<50%), Yellow (50-79%), Red (>=80%)
# Requires: jq

# --- Parse: extract all fields from JSON in one pass ---
parse_context() {
  local input="$1"
  read -r MODEL CONTEXT_SIZE INPUT_TOKENS OUTPUT_TOKENS USED_PCT <<< "$(
    jq -r '[
      .model.display_name // "",
      .context_window.context_window_size // 0,
      .context_window.total_input_tokens // 0,
      .context_window.total_output_tokens // 0,
      .context_window.used_percentage // ""
    ] | @tsv' <<< "$input"
  )"
}

# --- Format: display token count as Xk or X.Xk ---
format_tokens() {
  local v=$1
  if [ "$v" -ge 1000 ]; then
    printf "%dk" "$((v / 1000))"
  else
    printf "%d" "$v"
  fi
}

# --- Calculate percentage ---
calc_pct() {
  local total=$1 ctx_size=$2 used_pct="$3"
  if [ -n "$used_pct" ]; then
    printf '%.0f' "$used_pct"
  else
    echo $((total * 100 / ctx_size))
  fi
}

# --- Pick color based on percentage ---
pick_color() {
  local pct=$1
  if [ "$pct" -lt 50 ]; then
    echo '\033[32m'  # green
  elif [ "$pct" -lt 80 ]; then
    echo '\033[33m'  # yellow
  else
    echo '\033[31m'  # red
  fi
}

# --- Render: assemble final output ---
render_status() {
  local model="$1" pct=$2 used_fmt="$3" cap_fmt="$4" color="$5"
  if [ -n "$model" ]; then
    printf "${color}[%s] Ctx: %d%% (%s/%s)\033[0m\n" "$model" "$pct" "$used_fmt" "$cap_fmt"
  else
    printf "${color}Ctx: %d%% (%s/%s)\033[0m\n" "$pct" "$used_fmt" "$cap_fmt"
  fi
}

# --- Main ---
main() {
  local input
  input=$(cat)

  parse_context "$input"

  if [ -z "$CONTEXT_SIZE" ] || [ "$CONTEXT_SIZE" = "0" ]; then
    exit 0
  fi

  local total=$((INPUT_TOKENS + OUTPUT_TOKENS))
  local pct
  pct=$(calc_pct "$total" "$CONTEXT_SIZE" "$USED_PCT")
  local used_fmt cap_fmt color
  used_fmt=$(format_tokens "$total")
  cap_fmt=$(format_tokens "$CONTEXT_SIZE")
  color=$(pick_color "$pct")

  render_status "$MODEL" "$pct" "$used_fmt" "$cap_fmt" "$color"
}

main
