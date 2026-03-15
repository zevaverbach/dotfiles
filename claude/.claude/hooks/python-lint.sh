#!/bin/bash
# PostToolUse hook: run ruff + ty on Python files after Edit/Write
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a .py file
if [[ -z "$FILE_PATH" || "$FILE_PATH" != *.py ]]; then
  exit 0
fi

# Skip if file doesn't exist (was deleted)
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

ERRORS=""

# Run ruff check (lint + auto-fix)
if ! RUFF_OUT=$(ruff check --fix --force-exclude "$FILE_PATH" 2>&1); then
  ERRORS+="ruff check:\n$RUFF_OUT\n\n"
fi

# Run ruff format
if ! RUFF_FMT_OUT=$(ruff format --force-exclude "$FILE_PATH" 2>&1); then
  ERRORS+="ruff format:\n$RUFF_FMT_OUT\n\n"
fi

# Run ty type check
if ! TY_OUT=$(uvx ty check "$FILE_PATH" 2>&1); then
  ERRORS+="ty check:\n$TY_OUT\n\n"
fi

if [[ -n "$ERRORS" ]]; then
  printf "%b" "$ERRORS" >&2
  exit 2
fi

exit 0
