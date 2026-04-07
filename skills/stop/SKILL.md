---
name: stop
description: Stop the Shuttle heartbeat — removes cron, hook, and CLAUDE.local.md hint. Does not delete the task file.
user_invocable: true
---

# /stop — Stop the Shuttle Heartbeat

Full cleanup of all Shuttle artifacts. The task file is not deleted — it's user data.

## Steps

### 1. Cancel the heartbeat cron

Use CronList to find all crons whose prompt starts with `Shuttle ` (this matches both `Shuttle tick:` and `Shuttle custom:` prompts).

For each match, use CronDelete to remove it.

If no matching cron is found, note this but continue cleanup (the cron may have been lost when a session ended).

### 2. Remove the pre-check hook entry

Read `.claude/settings.json` in the current project directory.

If it exists and contains a `hooks.UserPromptSubmit` entry whose `hooks` array includes `"command": ".claude/hooks/shuttle-precheck.sh"`, remove that entry from the array. Write the updated JSON back.

If the `UserPromptSubmit` array is now empty, remove the `UserPromptSubmit` key. If the `hooks` object is now empty, remove the `hooks` key.

If `.claude/settings.json` doesn't exist, skip this step.

### 3. Delete the hook script

If `.claude/hooks/shuttle-precheck.sh` exists, delete it using Bash: `rm .claude/hooks/shuttle-precheck.sh`.

If `.claude/hooks/` directory is now empty, delete it using Bash: `rmdir .claude/hooks/` (this will only succeed if empty, which is correct).

### 4. Remove CLAUDE.local.md hint

Read `CLAUDE.local.md` in the current working directory.

If it contains a `## Shuttle` section, remove the entire section (from `## Shuttle` to the next `##` heading or end of file) using the Edit tool.

If `CLAUDE.local.md` is now empty after removal, delete the file.

### 5. Confirm

> "Shuttle stopped. Cron removed, hook cleaned up. Task file preserved at `<path>`."

If no cron was found in step 1:

> "Shuttle stopped (no active heartbeat found — session may have ended). Hook cleaned up. Task file preserved at `<path>`."
