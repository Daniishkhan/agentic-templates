# README — LLM-Assisted Development Operating System

> A repeatable system for building software with LLM agents.

## The Stack

```text
Backend:    Go · chi · sqlc · PostgreSQL · Redis
Frontend:   TypeScript · React · Vite · TanStack Query · shadcn/ui · Tailwind
Mobile:     Capacitor (optional)
Infra:      Docker Compose locally · Makefile as command runner
Contract:   OpenAPI 3.1 (api.yaml) -> generated TypeScript types
```

## Simple Planning Flow (recommended)

```text
1) docs/onepager.md  (idea + MVP scope)
2) docs/prd.md       (full product requirements)
3) docs/epic.md      (single backlog source: epics, stories, tasks, dependencies, status)
4) progress.md       (execution log maintained while implementing)
```

`docs/epic.md` is the big bucket. Fill all epics/stories/tasks there.
Use the Story Index block in `docs/epic.md` for machine-readable state.

## Execution Loop

1. Run `./scripts/context-brief.sh`.
2. Pick the next `ready` story from `docs/epic.md` Story Index.
3. Move it to `in-progress` in `docs/epic.md`.
4. Implement code changes.
5. Run checks (`make lint`, `make test`, plus `make validate` when needed).
6. Mark story `done` in `docs/epic.md` and log key notes in `progress.md`.

## Why this is the middle ground

- Not over-engineered: one backlog file (`docs/epic.md`) instead of many planning artifacts.
- Not under-engineered: frontmatter + Story Index provide clear machine-readable state.
- Scalable enough: dependencies and status are explicit and easy for agents to traverse.

## Project Skills

Repository skills live in `.agents/skills/<skill-name>/`.
Each skill should include:
- `SKILL.md` with frontmatter (`name`, `description`)
- `metadata.short-description`
- `agents/openai.yaml`

## File Ownership

| File | Owner | Purpose |
|---|---|---|
| `AGENTS.md` | Tech lead | Always-loaded operating rules |
| `docs/onepager.md` | PM/founder | Problem framing |
| `docs/prd.md` | PM/founder | Product requirements |
| `docs/epic.md` | PM + tech lead | Backlog and execution state |
| `progress.md` | Implementer/agent | Ongoing implementation log |
| `docs/conventions.md` | Tech lead | Code patterns and references |
| `api.yaml` | Developers + agents | API contract source of truth |
| `schema.sql` | Generated | Schema artifact |

## Truth Hierarchy

```text
1) Code + generated artifacts
2) docs/epic.md + progress.md
3) docs/prd.md + docs/onepager.md
```
