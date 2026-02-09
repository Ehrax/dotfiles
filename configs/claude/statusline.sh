#!/usr/bin/env bash

# Claude Code Status Line (One Dark themed, no directory)
# Model | Cost | Duration | Lines +/- | Context %

input=$(cat)

# One Dark colors
C_MODEL='\033[38;2;97;175;239m'    # #61afef blue
C_COST='\033[38;2;224;108;117m'    # #e06c75 red
C_DUR='\033[38;2;198;120;221m'     # #c678dd purple
C_ADD='\033[38;2;152;195;121m'     # #98c379 green
C_DEL='\033[38;2;224;108;117m'     # #e06c75 red
C_CTX='\033[38;2;229;192;123m'     # #e5c07b yellow
C_DIM='\033[38;2;84;88;98m'        # #545862 muted
R='\033[0m'

# Extract fields (using official API fields)
MODEL=$(echo "$input" | jq -r '.model.display_name // "—"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Format cost
COST_FMT=$(printf '$%.2f' "$COST")

# Format duration
DURATION_SEC=$((DURATION_MS / 1000))
MINS=$((DURATION_SEC / 60))
SECS=$((DURATION_SEC % 60))
if [ $MINS -ge 60 ]; then
    DUR_FMT="$((MINS / 60))h$((MINS % 60))m"
elif [ $MINS -gt 0 ]; then
    DUR_FMT="${MINS}m${SECS}s"
else
    DUR_FMT="${SECS}s"
fi

# Build output
printf '%b' \
    "${C_MODEL}${MODEL}${R}" \
    "  ${C_COST}${COST_FMT}${R}" \
    "  ${C_DUR}${DUR_FMT}${R}" \
    "  ${C_ADD}+${LINES_ADD}${R}" \
    " ${C_DEL}-${LINES_DEL}${R}" \
    "  ${C_CTX}[${PCT}%]${R}" \
    "\n"
