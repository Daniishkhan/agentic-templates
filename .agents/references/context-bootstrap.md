# Context Bootstrap

Use this when starting a task or resuming after context switching.

## Recommended command

```bash
./scripts/context-brief.sh
```

## Why this exists

- Keeps `AGENTS.md` concise while still front-loading execution context.
- Surfaces current progress and epic story state quickly.
- Avoids loading unnecessary docs before starting implementation.

## Low-context read sequence

1. `progress.md`
2. `memory.md` latest lessons
3. `./scripts/incident-learn.sh --list --limit 5` (if `logs/learning.db` exists)
4. `docs/epic.md` Story Index
5. target story section in `docs/epic.md`
6. `api.yaml` / module files only as needed for implementation

## Diagram choice

- Prefer ASCII diagrams in `AGENTS.md` for low-token, tool-agnostic parsing.
- Use Mermaid in docs only when visual clarity for humans matters.
