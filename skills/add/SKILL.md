---
name: add
description: Add a task to the Shuttle task file with ready status. Creates the file if it doesn't exist.
user_invocable: true
argument-hint: <description>
---

# /add — Add a Shuttle Task

Append a new task to the task file.

## Arguments

`<description>` — a short title for the task. If not provided, ask: "What task should I add?"

## Steps

### 1. Determine the task file path

Use `.shuttle.md` in the current working directory.

### 2. Create file if needed

If the task file does not exist, create it with an empty content.

### 3. Append the task

Append the following to the end of the task file using the Edit tool:

```
## <description>
**Status:** ready
```

Where `<description>` is the user's input, used as-is for the heading.

### 4. Confirm

> "Added task: **<description>**. Run `/shuttle:start` to begin working, or `/shuttle:add` to add more."

If the heartbeat is already running (check with CronList for a cron matching `Shuttle ` prefix), instead say:

> "Added task: **<description>**. It will be picked up on the next heartbeat tick."
