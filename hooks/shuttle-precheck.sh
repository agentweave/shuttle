#!/bin/bash
# Shuttle idle suppression pre-check
# Blocks Shuttle tick prompts when no active tasks exist.
# Installed by /shuttle:start, removed by /shuttle:stop.
#
# This is a reference template. /shuttle:start writes a customized
# version to .claude/hooks/shuttle-precheck.sh with the actual
# task file path hardcoded in TASK_FILE.

TASK_FILE=".shuttle.md"

if grep -q '^\*\*Status:\*\* \(ready\|in-progress\)' "$TASK_FILE" 2>/dev/null; then
  exit 0
else
  echo '{"decision":"block","reason":"No active tasks"}' >&2
  exit 2
fi
