#!/usr/bin/env bash
set -euo pipefail

# Claude Code status line: model + context window usage with color coding
# Green (<50%), Yellow (50-79%), Red (>=80%)
# Requires: jq

# ----------------------------
# Parse JSON
# ----------------------------
parse_context() {
    jq -r '[
        .model.display_name // "",
        .context_window.context_window_size // 0,
        .context_window.total_input_tokens // 0,
        .context_window.total_output_tokens // 0,
        .context_window.used_percentage // ""
    ] | @tsv'
}

# ----------------------------
# Format token count
# ----------------------------
format_tokens() {
    local v=$1

    if (( v >= 1000 )); then
        printf "%dk" "$((v / 1000))"
    else
        printf "%d" "$v"
    fi
}

# ----------------------------
# Calculate percentage
# ----------------------------
calc_pct() {
    local total=$1
    local ctx_size=$2
    local used_pct=$3

    if [[ -n "$used_pct" ]]; then
        printf "%.0f" "$used_pct"
    else
        echo $(( total * 100 / ctx_size ))
    fi
}

# ----------------------------
# Pick color
# ----------------------------
pick_color() {
    local pct=$1

    if (( pct < 50 )); then
        printf '\033[32m'
    elif (( pct < 80 )); then
        printf '\033[33m'
    else
        printf '\033[31m'
    fi
}

# ----------------------------
# Render output
# ----------------------------
render_status() {
    local model=$1
    local pct=$2
    local used_fmt=$3
    local cap_fmt=$4
    local color=$5

    local prefix=""
    [[ -n "$model" ]] && prefix="[$model] "

    printf "%b%sCtx: %d%% (%s/%s)\033[0m\n" \
        "$color" \
        "$prefix" \
        "$pct" \
        "$used_fmt" \
        "$cap_fmt"
}

# ----------------------------
# Main
# ----------------------------
main() {
    local input
    input=$(cat)

    local MODEL
    local CONTEXT_SIZE
    local INPUT_TOKENS
    local OUTPUT_TOKENS
    local USED_PCT

    # 关键：只按 TAB 分割，而不是空格
    IFS=$'\t' read -r \
        MODEL \
        CONTEXT_SIZE \
        INPUT_TOKENS \
        OUTPUT_TOKENS \
        USED_PCT \
        < <(parse_context <<< "$input")

    # Context 不存在，直接退出
    if [[ -z "$CONTEXT_SIZE" || "$CONTEXT_SIZE" == "0" ]]; then
        exit 0
    fi

    local total=$(( INPUT_TOKENS + OUTPUT_TOKENS ))
    local pct
    pct=$(calc_pct "$total" "$CONTEXT_SIZE" "$USED_PCT")

    local used_fmt
    local cap_fmt
    local color

    used_fmt=$(format_tokens "$total")
    cap_fmt=$(format_tokens "$CONTEXT_SIZE")
    color=$(pick_color "$pct")

    render_status \
        "$MODEL" \
        "$pct" \
        "$used_fmt" \
        "$cap_fmt" \
        "$color"
}

main
