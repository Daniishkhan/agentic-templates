# Progress

> Keep this short. Pull story IDs and scope from docs/epic.md.
> Last updated: 2026-02-18

## Done
- Simplified planning model to one backlog file: `docs/epic.md`.
- Restored epic-first workflow: onepager -> PRD -> epic -> execution.
- Added machine-readable Story Index block inside `docs/epic.md` for status/dependency tracking.
- Added major-incident learning loop:
  - new skill: `$error-learning`
  - centralized capture/query script: `scripts/incident-learn.sh`
  - SQLite directive store: `logs/learning.db`
  - durable lessons store: `memory.md`
  - scaffold defaults now include runtime logs + directive commands (`learn-error`, `learn-list`, `learn-rules`).
- Added closed-vocabulary story operations:
  - new command layer: `scripts/story-op.sh` (`ready|start|done|block`)
  - automatic status sync between Story Index and Story Meta
  - automatic `progress.md` updates on `done` and `block`
  - regression harness: `scripts/test-story-op.sh`
  - scaffold Make targets: `story-ready`, `story-start`, `story-done`, `story-block`

## Inactive / Blocked
- (none)

## Needs Rework
- (none)

## Next Up
- When first major error occurs, run `./scripts/incident-learn.sh` and validate lesson quality in `memory.md`.
