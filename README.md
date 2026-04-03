# Shuttle

Give your agent a todo list.

Shuttle lets Claude Code work autonomously through a queue of tasks. You scope the work, start the heartbeat, and walk away. It picks them up one by one, tracks progress, and idles when there's nothing left to do.

Part of the [agentweave](https://github.com/agentweave) suite.

## Install

```bash
claude plugin install agentweave/shuttle
```

## Quick Start

```
/shuttle:kickoff                  — scope work into tasks (interactive)
/shuttle:start                    — start the heartbeat
/shuttle:status                   — check progress
/shuttle:stop                     — stop the heartbeat
```

Or skip the kickoff and add tasks directly:

```
/shuttle:add "Fix the login redirect bug"
/shuttle:add "Add rate limiting to /api routes"
/shuttle:start
```

## How it works

1. **Task file** (`.shuttle.md`) — markdown with `**Status:** ready | in-progress | done`. The only required protocol.
2. **Heartbeat** — CronCreate fires every 15 minutes (configurable). The model reads the task file, picks up work, updates progress.
3. **Idle suppression** — a shell pre-check greps for active tasks before invoking the model. No active tasks = tick skipped, zero tokens burned.

## Configuration

`/shuttle:start` accepts optional arguments (any order):

```
/shuttle:start                              — defaults: .shuttle.md, 15m
/shuttle:start 5m                           — custom interval
/shuttle:start path/to/tasks.md             — custom task file
/shuttle:start path/to/tasks.md 5m          — both
/shuttle:start --prompt "..."               — custom prompt mode (no task file, no pre-check)
```

## Protocol

The task file format and behavioral contract are defined in the [Shuttle Protocol spec](docs/protocol.md), so other implementations can produce and consume compatible task files.

## Cortex Integration

Cortex delegates heartbeat management to Shuttle. Workers get full task mode with idle suppression. The coordinator uses custom prompt mode (`--prompt`).

## License

MIT
