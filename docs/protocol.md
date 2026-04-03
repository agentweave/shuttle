# Shuttle Protocol v0.1

A task protocol for autonomous long-running agent work. This document specifies the data format and behavioral contract so that any implementation — plugin, script, or agent framework — can produce and consume Shuttle-compatible task files.

The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## 1. Task File

The task file is a UTF-8 Markdown file. The default path is `.shuttle.md`, but implementations MUST support a configurable path.

When a non-default path is used, all operations (add, status, start, stop) MUST resolve to the same path. How the path is communicated across operations is implementation-specific.

### 1.1 Task Structure

Each task is a level-2 heading followed by a status marker and optional body:

```markdown
## <title>
**Status:** <status>
**Started:** <timestamp>
**Completed:** <timestamp>

<body>
```

- **Title** — free-form text. Used as the task identifier within the file.
- **Status** — one of three values: `ready`, `in-progress`, `done`. The marker MUST be formatted exactly as `**Status:** <value>` on its own line, as the first metadata line after the heading. The status line MUST NOT be indented — it starts at column 1.
- **Started** — optional. Written when a task transitions to `in-progress`. Format: `YYYY-MM-DDTHH:MM` in local time.
- **Completed** — optional. Written when a task transitions to `done`. Format: `YYYY-MM-DDTHH:MM` in local time.
- **Body** — optional. Free-form markdown for context, notes, subtasks, or progress updates.

### 1.2 Completion Summary

When a task is marked `done`, implementations SHOULD append a summary:

```markdown
## Fix the login redirect bug
**Status:** done
**Started:** 2026-04-03T14:30
**Completed:** 2026-04-03T15:45

### Summary
Traced the issue to missing redirect_uri validation in the OAuth callback.
Fixed in auth/callback.ts — added URI allowlist check before redirect.
```

### 1.3 Last-Tick Timestamp

Implementations that use a recurring heartbeat MUST write a timestamp comment at the end of the task file after each tick:

```markdown
<!-- <prefix>:last-tick 2026-04-03T14:30 -->
```

Format: `YYYY-MM-DDTHH:MM` in local time. The prefix MUST match the implementation's prompt prefix (§3.1), lowercased (e.g., `shuttle:last-tick`, `cortex:last-tick`). This enables collision detection (§4) and observability.

If a timestamp already exists, replace it — the file MUST contain at most one.

### 1.4 Example

```markdown
## Add rate limiting to /api routes
**Status:** done
**Started:** 2026-04-03T13:00
**Completed:** 2026-04-03T14:15

### Summary
Added express-rate-limit middleware to all /api routes. 100 req/min per IP.

## Fix the login redirect bug
**Status:** in-progress
**Started:** 2026-04-03T14:30

Investigating — the OAuth callback doesn't validate redirect_uri.

## Write integration tests for auth flow
**Status:** ready

<!-- shuttle:last-tick 2026-04-03T14:30 -->
```

## 2. Task Lifecycle

Tasks follow a strict state machine:

```
ready → in-progress → done
```

Rules:
- A task MUST start as `ready`.
- Only one task SHOULD be `in-progress` at a time. Implementations MAY allow multiple, but the default behavior is serial execution.
- A task transitions to `in-progress` when an agent begins work on it.
- A task transitions to `done` when work is complete. This transition MUST NOT be reversed.
- Removing completed tasks from the file, archiving them, or replacing the file entirely for a new work scope is permitted — the irreversibility rule applies to individual task state transitions, not file-level operations.
- Tasks are picked up in document order — the first `ready` task is next.

## 3. Heartbeat

The heartbeat is a recurring trigger that drives autonomous execution. The protocol does not prescribe a specific mechanism — it could be a cron job, a timer, a webhook, or any scheduler.

### 3.1 Prompt Prefix Convention

Heartbeat prompts MUST use a consistent prefix to enable discovery, cleanup, and mode discrimination. The prefix pattern is:

- **Task mode:** `<prefix> tick: <instructions>`
- **Custom prompt mode:** `<prefix> custom: <prompt>`

The reference implementation uses `Shuttle` as its prefix (e.g., `Shuttle tick: ...`). Other implementations SHOULD choose a distinct prefix to avoid conflicts when multiple heartbeats coexist in the same session (e.g., `Cortex tick: ...`).

Implementations MUST use their own prefix to identify their heartbeats when listing, stopping, or checking status. Matching on `<prefix> ` (with trailing space) catches both modes.

### 3.2 Tick Behavior

On each tick, the agent MUST:

1. Read the task file.
2. If a task is `in-progress`, continue working on it.
3. If no task is `in-progress`, find the first `ready` task and mark it `in-progress` (with `**Started:**` timestamp if supported).
4. Do the work.
5. Update the task file with progress or completion (with `**Completed:**` timestamp if supported).
6. If the task was completed and `ready` tasks remain, the agent MAY continue to the next task within the same tick.
7. Update the last-tick timestamp (§1.3).

If no tasks are `ready` or `in-progress`, the tick is a no-op.

Implementations MAY extend the tick with additional pre- or post-steps (e.g., updating external state, writing heartbeat timestamps to other files). Extensions MUST NOT alter the task lifecycle defined in §2.

### 3.3 Resumability

Ticks are stateless. The agent may be a different process or session than the one that started the task. All state lives in the task file.

Implementations SHOULD include a note in the tick prompt that the agent may be resuming from a previous session, so it reads progress notes carefully before acting.

### 3.4 Two Modes

Implementations SHOULD support two modes:

- **Task mode** (default) — the heartbeat reads and works from the task file. Uses the `<prefix> tick:` prompt. Idle suppression (§5) applies.
- **Custom prompt mode** — the caller provides a tick prompt. Uses the `<prefix> custom:` prompt. The heartbeat manages lifecycle only (start/stop). No task file, no idle suppression. Useful for coordinators that define their own tick behavior.

## 4. Collision Detection

Multiple agents or sessions may accidentally target the same task file. The last-tick timestamp (§1.3) enables detection:

Before starting a heartbeat, implementations SHOULD:

1. Read the task file.
2. Parse the `<!-- <prefix>:last-tick ... -->` timestamp.
3. If the timestamp is recent (within one heartbeat interval), warn the user that another heartbeat may be active.

This is advisory, not a lock. The protocol trusts the user to resolve conflicts.

## 5. Idle Suppression

When all tasks are `done` (or the file is empty), the heartbeat SHOULD skip its tick to avoid wasting resources.

Idle suppression applies only to **task mode** (`<prefix> tick:` prompts). Custom prompt mode (`<prefix> custom:`) MUST NOT be gated by idle suppression — the caller owns the tick logic.

### 5.1 Pre-Check Contract

Before invoking the agent on a task-mode tick, implementations SHOULD run a pre-check:

```
if the task file contains at least one task with status ready or in-progress:
    proceed with tick
else:
    skip tick
```

The reference implementation uses a shell script and the `UserPromptSubmit` hook with a matcher on its prefix (`Shuttle tick:`) to block the prompt before it reaches the model. Other implementations MAY use any gating mechanism, but MUST scope it to task-mode ticks only.

### 5.2 Matching Pattern

The pre-check greps for:

```
**Status:** ready
**Status:** in-progress
```

The regex for this (POSIX BRE):

```
^\*\*Status:\*\* \(ready\|in-progress\)
```

## 6. Heartbeat Lifecycle

### 6.1 Start

Starting a heartbeat MUST be idempotent. If a heartbeat is already running (detected by matching the implementation's own prompt prefix), the existing one MUST be removed before creating a new one.

### 6.2 Stop

Stopping a heartbeat MUST remove the scheduling entry. Implementations SHOULD also clean up any installed hooks and session hints. Stop MUST be idempotent — if no active heartbeat is found, cleanup of other artifacts (hooks, hints) SHOULD still proceed.

The task file MUST NOT be deleted on stop — it is user data.

## 7. Session Resume

Heartbeats are typically scoped to a session. When a session ends, the heartbeat stops but the task file persists.

Implementations SHOULD leave a hint so the next session knows to restart:

The content of the hint is implementation-specific. Example: "Run `/shuttle:start` to resume the heartbeat."

The mechanism for this hint is implementation-specific. The reference implementation uses `CLAUDE.local.md`.

## 8. Conformance

### Required

An implementation is **Shuttle-compatible** if it:

- Reads and writes the task file format (§1).
- Follows the task lifecycle (§2).
- Executes tick behavior correctly (§3.2).
- Writes the last-tick timestamp (§1.3).

### Recommended

- Idle suppression (§5).
- Collision detection (§4).
- Heartbeat lifecycle management (§6).
- Session resume hints (§7).
- Two-mode support (§3.4).
- Serial task execution (one in-progress at a time).
- Lifecycle timestamps — Started and Completed (§1.1).
- Completion summaries (§1.2).

## Reference Implementation

The reference implementation is the [Shuttle Claude Code plugin](https://github.com/agentweave/shuttle), which uses CronCreate for the heartbeat, UserPromptSubmit hooks for idle suppression, and CLAUDE.local.md for session resume.
