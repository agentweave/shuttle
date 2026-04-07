#!/bin/bash
# Shuttle idle suppression pre-check
# Blocks Shuttle tick prompts when no active tasks exist.
# Installed by /shuttle:start, removed by /shuttle:stop.
#
# This is a reference template. /shuttle:start writes a customized
# version to .claude/hooks/shuttle-precheck.sh with the actual
# task file path hardcoded in TASK_FILE.
#
# NOTE: matcher is ignored for UserPromptSubmit hooks, so this
# script must filter by prompt content itself.

# Read hook input and extract the prompt (requires jq).
# If jq is missing, PROMPT is empty and the script defaults to allow.
PROMPT=$(jq -r '.prompt // empty' 2>/dev/null)

# Only apply to Shuttle tick prompts — pass everything else through
case "$PROMPT" in
  "Shuttle tick:"*) ;;
  *) exit 0 ;;
esac

TASK_FILE=".shuttle.md"

if grep -q '^\*\*Status:\*\* \(ready\|in-progress\)' "$TASK_FILE" 2>/dev/null; then
  exit 0
else
  echo '{"decision":"block","reason":"No active tasks"}' >&2
  exit 2
fi
