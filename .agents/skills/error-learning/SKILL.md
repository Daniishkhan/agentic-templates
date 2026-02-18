---
name: error-learning
description: >
  Capture major runtime/build incidents, inspect centralized logs, and persist
  high-signal lessons so future implementations avoid repeating the same mistakes.
metadata:
  short-description: Learn from major errors and update durable memory
---

# Error Learning

Use this skill when a feature is blocked, a major bug appears, or the same failure repeats.
Do not run for routine warnings.

## Trigger threshold

Run when at least one is true:

- same error pattern repeated 2+ times
- critical/major failure in build, migration, or runtime
- story blocked and root cause unclear after normal debugging

## Procedure

1. Record incident directive in SQLite:
   - `./scripts/incident-learn.sh --story US-XXX --title "..." --signal "..." --root-cause "..." --correction "..." --prevention-rule "..." --checks "..."`
2. Add optional evidence only when needed:
   - add `--with-snapshot` to capture raw logs under `logs/snapshots/`
3. Inspect history quickly:
   - `./scripts/incident-learn.sh --list`
   - `./scripts/incident-learn.sh --list-rules`
4. Confirm durable lesson was appended:
   - `memory.md` (deduped by prevention rule)
5. Apply prevention rule in active implementation and continue.

## Rules

- Log only major/critical learnings (high signal, low bloat).
- Keep `logs/learning.db` as the canonical directive store.
- Every lesson must include an executable check command.
- Keep prevention rules concrete and imperative.
- If a lesson changes planned behavior, note deviation in `progress.md`.
