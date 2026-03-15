#!/usr/bin/env bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // empty')
WINDOW_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

if [ "$WINDOW_SIZE" -gt 0 ] 2>/dev/null && [ "$USED_PCT" -gt 0 ] 2>/dev/null; then
  PCT=$(( USED_PCT * WINDOW_SIZE / 350000 ))
else
  PCT=0
fi

printf '%s' "${MODEL}: ${PCT}% of 350K"
