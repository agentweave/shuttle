---
name: start
description: Start the Shuttle heartbeat — creates a CronCreate job and installs the idle suppression hook. Idempotent.
user_invocable: true
argument-hint: [path] [interval] [--prompt "..."]
---

# /start — Start the Shuttle Heartbeat

Start the heartbeat that drives autonomous task execution.

## Arguments

All arguments are optional and order-independent:

- **path** — task file path. Default: `.shuttle.md`. Any argument that is not a duration and not `--prompt` is treated as a path.
- **interval** — heartbeat interval. Default: `15m`. Detected by matching the pattern: one or more digits followed by `m` (e.g., `5m`, `15m`, `30m`).
- **--prompt "..."** — custom prompt mode. Shuttle manages the CronCreate lifecycle only. No task file, no pre-check hook.

Examples:
```
/start                              → .shuttle.md, 15m
/start 5m                           → .shuttle.md, 5m
/start path/to/tasks.md             → custom path, 15m
/start path/to/tasks.md 5m          → custom path, 5m
/start 5m path/to/tasks.md          → same as above
/start --prompt "..." 15m           → custom prompt, 15m
```

## Steps

### 1. Parse arguments

From the provided arguments:
- If `--prompt "..."` is present, extract the prompt string. This is **custom prompt mode**.
- For remaining arguments, check each: if it matches `^\d+m$`, it's the interval. Otherwise, it's the path.
- Apply defaults: path = `.shuttle.md`, interval = `15m`.

### 2. Branch by mode

If `--prompt` was provided, go to **Step 7** (custom prompt mode).

Otherwise, continue with **task mode**.

---

**Task Mode**

### 3. Verify task file

Read the task file at the resolved path.

If the file does not exist or contains no `**Status:** ready` or `**Status:** in-progress` lines, stop and respond:

> "No tasks found in `<path>`. Run `/shuttle:kickoff` to scope your work, or `/shuttle:add` to add a task."

### 4. Check for multi-session collision

Read the task file and look for a comment matching:
```
<!-- shuttle:last-tick YYYY-MM-DDTHH:MM -->
```

If found, parse the timestamp. If the timestamp is less than `<interval>` minutes ago, ask the user:

> "A Shuttle heartbeat was active X minutes ago (possibly in another session). Start anyway?"

If the user says no, stop. If yes (or no timestamp found), continue.

### 5. Clean up existing cron (idempotency)

Use CronList to check for any cron whose prompt starts with `Shuttle `. If found, use CronDelete to remove it.

### 6. Create the heartbeat cron

Convert the interval to a cron expression: `<interval>m` becomes `*/<interval> * * * *`.

Use CronCreate with:
- **cron:** `*/<interval> * * * *`
- **prompt:**

```
Shuttle tick: read <path> and continue working.

1. Read <path>
2. If a task is in-progress, continue it (you may be resuming from a previous session — read progress notes carefully)
3. If no task is in-progress, pick the first ready task and mark it in-progress
4. Do the work
5. Update progress in <path> as you go
6. When a task is complete, mark it done with a summary under ### Summary
7. If more ready tasks remain, pick up the next one
8. Update the last-tick timestamp: <!-- shuttle:last-tick YYYY-MM-DDTHH:MM -->
```

Replace `<path>` with the actual resolved task file path.

### 6b. Install the pre-check hook

**Write the hook script:**

Create the `.claude/hooks/` directory if it doesn't exist. Write the following script to `.claude/hooks/shuttle-precheck.sh`:

```bash
#!/bin/bash
# Shuttle idle suppression pre-check
# Blocks Shuttle tick prompts when no active tasks exist.
# Installed by /shuttle:start, removed by /shuttle:stop.

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

TASK_FILE="<path>"

if grep -q '^\*\*Status:\*\* \(ready\|in-progress\)' "$TASK_FILE" 2>/dev/null; then
  exit 0
else
  echo '{"decision":"block","reason":"No active tasks"}' >&2
  exit 2
fi
```

Replace `<path>` with the resolved task file path (e.g., `.shuttle.md` or the custom path provided).

Make the script executable using Bash: `chmod +x .claude/hooks/shuttle-precheck.sh`.

**Add the hook entry:**

Read `.claude/settings.json` in the current project directory. If it doesn't exist, create it. If it exists, parse the existing JSON.

If the `hooks.UserPromptSubmit` array does NOT already contain an entry with `"command": ".claude/hooks/shuttle-precheck.sh"`, add the following entry to the array:

```json
{
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/shuttle-precheck.sh"
    }
  ]
}
```

Preserve all existing hook entries. If `hooks` or `hooks.UserPromptSubmit` keys don't exist, create them.

### 6c. Update CLAUDE.local.md

Read `CLAUDE.local.md` in the current working directory.

If it exists and does NOT contain the text `## Shuttle`:
- Append this section at the very end:

```
## Shuttle
Run /shuttle:start to resume the heartbeat. See .shuttle.md for tasks.
```

If `CLAUDE.local.md` doesn't exist, create it with just that content.

If it already contains `## Shuttle`, do nothing.

### 6d. Confirm

> "Shuttle started. Heartbeat every <interval> on `<path>`. Pre-check hook installed. Run `/shuttle:stop` to stop, `/shuttle:status` to check progress."

**End of task mode.**

---

**Custom Prompt Mode**

### 7. Clean up existing cron (idempotency)

Same as Step 5 — use CronList to find and CronDelete any cron matching `Shuttle ` prefix.

### 8. Create the custom heartbeat cron

Convert the interval to a cron expression: `*/<interval> * * * *`.

Use CronCreate with:
- **cron:** `*/<interval> * * * *`
- **prompt:** `Shuttle custom: <prompt>`

Where `<prompt>` is the value from `--prompt`.

### 9. Update CLAUDE.local.md

Same as Step 6c.

### 10. Confirm

> "Shuttle started (custom prompt mode). Heartbeat every <interval>. Run `/shuttle:stop` to stop."
