# Context Bootstrap

Use this when starting a task or resuming after context switching.

## Recommended command

```bash
./scripts/context-brief.sh
```

## Why this exists

- Keeps `AGENTS.md` concise while still front-loading execution context.
- Surfaces `progress.md` sections and active epic story IDs quickly.
- Avoids duplicating dynamic state inside static policy files.

## Diagram choice

- Prefer ASCII diagrams in `AGENTS.md` for low-token, tool-agnostic parsing.
- Use Mermaid in docs only when visual clarity for humans matters.
