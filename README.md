# README — LLM-Assisted Development Operating System

> A repeatable system for building software with LLM agents. Same stack, same conventions, same document flow — every project.

## The Stack

```
Backend:    Go · chi · sqlc · PostgreSQL · Redis
Frontend:   TypeScript · React · Vite · TanStack Query · shadcn/ui · Tailwind
Mobile:     Capacitor (optional)
Infra:      Docker Compose locally · Makefile as command runner
Contract:   OpenAPI 3.1 (api.yaml) → generated TypeScript types
```

## Document Flow

```
 onepager.md (the idea)  ──→ prd.md (product document)  ──→ epic.md (feature/sprint details) ──→ progress.md (track state)   ──→ AGENTS.md (loaded in memory) ──→ docs/conventions.md (conventions for building app)  
```

### Phase 1: `docs/onepager.md` — Define the problem
One-page pitch. What's broken, who feels it, what we'd build, how we'd measure. The "should we build this?" document.

### Phase 2: `docs/prd.md` — Specify the product
Full product spec. Personas, journeys, features, success metrics, rollout. No technical details. The "what and for whom?" document.

### Phase 3: `docs/epic.md` — Plan the build
Technical backlog. Stories with acceptance criteria, API contracts (planning intent), task checklists, sliced execution order. **Historical once implemented** — code is the truth after that.

### Phase 4: `$project-scaffold` + skill-local `bootstrap.sh` — Bootstrap the repo
Use the project skill and run the script:
1. Invoke `$project-scaffold`.
2. Run `./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>`.
3. Validate using `.agents/skills/project-scaffold/references/bootstrap.md`.
4. Frontend defaults include Tailwind v4, shadcn/ui, Zustand, React Hook Form + Zod, and test tooling.
5. Backend defaults include chi + CORS, pgx, Redis, validator, JWT, and testify.

### Phase 5: `AGENTS.md` + `progress.md` — Build features
`AGENTS.md` is the always-loaded rules file (~280 lines). Decision rules, guardrails, protocols.
`progress.md` is the living project state. Read first, update after.
`docs/conventions.md` has detailed code patterns and examples — read when starting a new module.

## Project Skills

Repository skills live in `.agents/skills/<skill-name>/`.
Do not place project skills in a top-level `skills/` directory.

Each skill must include:
- `SKILL.md` with YAML frontmatter containing `name` and `description`
- `metadata.short-description` in `SKILL.md` frontmatter for concise discovery text
- `agents/openai.yaml` for UI/runtime metadata (`interface.display_name`, `interface.short_description`, `interface.default_prompt`)

Use per-skill metadata files. Do not try to define all skills in one root `openai.yaml`.

## File Ownership

| File | Owner | In agent context? | Purpose |
|------|-------|-------------------|---------|
| `AGENTS.md` | Tech lead | **Always loaded** | Rules, protocols, guardrails |
| `.agents/skills/<skill>/SKILL.md` | Tech lead | Auto-discovered | Skill behavior and invocation guidance |
| `.agents/skills/<skill>/agents/openai.yaml` | Tech lead | Auto-discovered | Skill UI/runtime metadata |
| `.agents/skills/project-scaffold/scripts/bootstrap.sh` | Tech lead | Invoked by `$project-scaffold` | Repo bootstrap source of truth |
| `docs/conventions.md` | Tech lead | Read on demand | Code patterns, examples, review checklist |
| `progress.md` | Whoever is working | Read on demand | Project state, deviations, decisions |
| `docs/epic.md` | Tech lead + PM | Read on demand | Stories and acceptance criteria (historical) |
| `docs/prd.md` | PM | No | Product requirements |
| `docs/onepager.md` | PM | No | Problem statement and pitch |
| `docs/architecture.md` | Tech lead | Read on demand | Stack decisions, data flows |
| `api.yaml` | Agents + developers | Read on demand | API contract (source of truth) |
| `schema.sql` | Generated | Read on demand | DB schema (generated from migrations) |

## Truth Hierarchy

```
  4 ▸ CODE + GENERATED ARTIFACTS ← always wins
  3 ▸ progress.md ← what changed from the plan
  2 ▸ docs/epic.md ← what we planned (historical)
  1 ▸ docs/prd.md · docs/onepager.md ← business context
```
