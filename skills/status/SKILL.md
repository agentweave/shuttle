---
name: status
description: Show Shuttle task counts and heartbeat state.
user_invocable: true
---

# /status — Shuttle Status

Report current task state and heartbeat status.

## Steps

### 1. Read the task file

Read `.shuttle.md` in the current working directory.

If the file doesn't exist, report:

> "No task file found. Run `/shuttle:kickoff` or `/shuttle:add` to create one."

Then skip to Step 2.

If the file exists, count tasks by status:
- Count occurrences of `**Status:** ready`
- Count occurrences of `**Status:** in-progress`
- Count occurrences of `**Status:** done`

Also check for the last-tick timestamp: `<!-- shuttle:last-tick ... -->`. If found, note when the last tick was.

### 2. Check heartbeat state

Use CronList to check for any cron whose prompt starts with `Shuttle `.

If found, extract the cron schedule to determine the interval.

### 3. Report

Format the output as:

```
Shuttle Status
──────────────
Tasks:  X ready · Y in-progress · Z done
Heartbeat: running (every <interval>) | stopped
Last tick: <timestamp> | never
```

If the heartbeat is stopped but tasks remain (ready or in-progress), add:

> "Tip: run `/shuttle:start` to resume."
