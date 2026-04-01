---
name: kickoff
description: Interactive scoping session — collaboratively break down work into a Shuttle task queue.
user_invocable: true
---

# /kickoff — Scope and Build a Shuttle Task Queue

An interactive session that helps the user decompose their work into well-scoped tasks.

## Steps

### 1. Check for existing tasks

Read `.shuttle.md` in the current working directory.

If the file exists and contains tasks (any `## ` headings), ask:

> "You have existing tasks in `.shuttle.md`. Want to **add to them** or **start fresh**?"

If "start fresh", the file will be overwritten in Step 5. If "add to", new tasks will be appended.

### 2. Understand the work

Ask the user: "What do you want to accomplish?"

Let them describe the work in their own words. Do not interrupt with follow-ups yet — let them finish.

### 3. Ask clarifying questions

Ask questions **one at a time** to understand:
- **Scope** — what's in, what's out?
- **Constraints** — dependencies, blockers, things to avoid?
- **Priority** — what order should tasks run in?
- **Success criteria** — how will you know it's done?

Prefer multiple-choice questions when possible. Keep going until you have enough to break the work into concrete tasks. Typically 2-5 questions is enough — don't over-interrogate.

### 4. Propose the task breakdown

Present the proposed `.shuttle.md` content to the user. Show the exact markdown that will be written:

```markdown
## <Task 1 title>
**Status:** ready

<Description of what to do>

## <Task 2 title>
**Status:** ready

<Description of what to do>

...
```

Each task should be:
- **Self-contained** — can be picked up without reading other tasks
- **Actionable** — clear what "done" looks like
- **Right-sized** — achievable in a handful of model turns, not too granular

Ask: "Does this look right? Want to adjust anything?"

Iterate until the user approves.

### 5. Write the task file

If starting fresh or no file exists: write the approved content to `.shuttle.md`.

If adding to existing tasks: append the approved content to the end of `.shuttle.md`.

### 6. Suggest next step

> "Tasks ready in `.shuttle.md`. Run `/shuttle:start` to begin the heartbeat."

Do NOT start the heartbeat — that is an explicit user action.
