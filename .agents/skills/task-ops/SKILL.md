---
name: task-ops
description: >
  Manage story execution state with closed-vocabulary operations backed by
  scripts/story-op.sh. Use when selecting ready work, starting stories,
  completing stories, or marking stories blocked.
metadata:
  short-description: Closed-vocabulary story state operations
---

# Task Ops

Use this skill for all story state mutations. Avoid manual status edits in
`docs/epic.md` unless repairing malformed files.

## Canonical source

- Script: `scripts/story-op.sh`
- Planning source of truth: `docs/epic.md`
- Execution log: `progress.md`

## Commands

- List ready stories:
  - `./scripts/story-op.sh ready`
  - `./scripts/story-op.sh ready --json`
- Start work:
  - `./scripts/story-op.sh start --story US-XXX [--owner <name>] [--note "..."]`
- Complete work:
  - `./scripts/story-op.sh done --story US-XXX --summary "..."`
- Mark blocked:
  - `./scripts/story-op.sh block --story US-XXX --reason "..."`

## Rules

- Story status changes must go through `story-op.sh`.
- `done` and `block` operations append concise notes to `progress.md`.
- Do not add automatic commit hooks that mutate story state.
- If `story-op.sh` fails on malformed epic markers, repair file structure first.
