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

1. Run `./scripts/workflow.sh context brief`.
2. Pick the next unblocked story with `./scripts/workflow.sh story ready`.
3. Start it with `./scripts/workflow.sh story start --story US-XXX [--owner <name>]`.
4. Implement code changes.
5. Run checks (`make lint`, `make test`, plus `make validate` when needed).
6. Complete it with `./scripts/workflow.sh story done --story US-XXX --summary "..."`.

`workflow.sh` is the unified command surface for agents and humans:
- `context brief` runs project bootstrap context + state summary
- `story ...` handles execution state transitions
- `incident ...` manages major incident learnings
- `doctor` validates local workflow invariants
- `llm prompt` supports optional provider-backed prompt execution in scripts

`story-op.sh` remains the closed-vocabulary state writer for stories:
- `ready` computes dependency-aware ready queue from `docs/epic.md`.
- `start` updates Story Index + Story Meta status to `in-progress`.
- `done` updates status to `done` and appends concise completion notes to `progress.md`.
- `block` updates status to `blocked` and appends reason to `progress.md`.

## Failure Learning Loop (major incidents only)

When a story is blocked by a major/critical error or repeated failure pattern:

1. Write an incident directive:
   - `./scripts/workflow.sh incident learn --story US-XXX --title \"...\" --signal \"...\" --root-cause \"...\" --correction \"...\" --prevention-rule \"...\" --checks \"...\"`
2. Optional evidence when needed:
   - add `--with-snapshot` (writes `logs/snapshots/INC-*.log`)
3. Inspect and reuse learnings:
   - `./scripts/workflow.sh incident list`
   - `./scripts/workflow.sh incident rules`
4. The script updates:
   - `logs/learning.db` (canonical directive store)
   - `memory.md` (durable anti-regression rules, deduped by prevention rule)

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
| `logs/learning.db` | AI runtime | Incident directive ledger (queryable) |
| `memory.md` | AI + tech lead | Durable lessons from major incidents |
| `scripts/workflow.sh` | AI runtime + developers | Unified workflow CLI for context/story/incident/doctor/llm |
| `scripts/story-op.sh` | AI runtime + developers | Closed-vocabulary story state operations |
| `progress.md` | Implementer/agent | Ongoing implementation log |
| `docs/conventions.md` | Tech lead | Code patterns and references |
| `api.yaml` | Developers + agents | API contract source of truth |
| `schema.sql` | Generated | Schema artifact |

## Truth Hierarchy

```text
1) Code + generated artifacts
2) docs/epic.md
3) logs/learning.db + memory.md
4) progress.md
5) docs/prd.md + docs/onepager.md
```
