# Shuttle

A Claude Code plugin for autonomous long-running work. Task protocol on top of /loop (CronCreate), with idle suppression via shell pre-check. Part of the agentweave suite.

## Project Structure

```
skills/                  — Claude Code skills (the plugin)
  kickoff/SKILL.md       — interactive task scoping
  add/SKILL.md           — add a task to the task file
  start/SKILL.md         — start heartbeat + install hook
  stop/SKILL.md          — stop heartbeat + full cleanup
  status/SKILL.md        — show tasks + heartbeat state
hooks/
  shuttle-precheck.sh    — idle suppression script template (copied to user's project on start)
.claude-plugin/
  plugin.json            — plugin metadata
  marketplace.json       — marketplace definition
```

## Key Concepts

- **Task file** — a markdown file (default: `.shuttle.md`) containing tasks with `**Status:** ready | in-progress | done`. This is the only required protocol element.
- **Heartbeat** — CronCreate fires on interval. Shell pre-check greps for active tasks before invoking the model. No active tasks = skip tick, zero tokens burned.
- **Two modes** — task mode (default: task file + pre-check) and custom prompt mode (caller provides tick prompt, no pre-check). Cortex uses custom prompt mode for its coordinator.
- **Skills are prompts, not code** — each SKILL.md is instructions that Claude Code follows. No runtime, no build step.

## Cortex Integration

Cortex delegates heartbeat management to Shuttle:
- **Workers** — full Shuttle: task file + pre-check + idle suppression
- **Chief of staff** — Shuttle as heartbeat manager only: custom tick prompt, no pre-check

Cortex's `/join` calls `/shuttle:start`, `/leave` calls `/shuttle:stop`.

## Conventions

- Commit messages: `feat:`, `fix:`, `docs:`, `chore:` prefixes
- Skills are self-contained — each SKILL.md includes all templates inline
- Task file path is configurable (solo: `.shuttle.md`, Cortex: `{team_dir}/agents/{slug}/tasks.md`)
