# Project Bootstrap Guide

> How to scaffold a new project, verify Slice 0, and start building.

## Quick start

```bash
chmod +x .agents/skills/project-scaffold/scripts/bootstrap.sh
./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>
# Example: ./.agents/skills/project-scaffold/scripts/bootstrap.sh rideshare mycompany
```

The script handles prerequisites, repo structure, config files, backend/frontend initialization, starter code, CI, and initial commit.

It also includes a minimal AI feedback loop:
- centralized runtime log paths under `logs/`
- SQLite directive store at `logs/learning.db`
- `memory.md` for durable lessons
- `scripts/incident-learn.sh` for atomic capture + lesson update

## Frontend defaults

- Tailwind CSS v4 via Vite plugin (`@tailwindcss/vite`)
- shadcn/ui CLI (`shadcn@latest`) starter setup
- tweakcn baseline theme (`modern-minimal`) with fallback
- TanStack Query + React Router + Zustand
- React Hook Form + Zod
- Vitest + Testing Library + Playwright

## Backend defaults

- chi router + CORS middleware
- pgx + Redis
- validator + JWT + uuid + testify

## Prerequisites

The script auto-installs tools via Homebrew. Only Homebrew must already exist:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## After scaffolding

1. Edit `migrations/000001_initial.up.sql` with MVP tables.
2. Edit `migrations/000001_initial.down.sql` for rollback.
3. Copy `AGENTS.md` into the generated repo root.
4. Fill `docs/onepager.md`, `docs/prd.md`, and `docs/epic.md`.

Then run:

```bash
cd <project_name>
make dev-infra
make migrate
make schema-dump
make generate
make dev
```

When debugging major issues, prefer:

```bash
make dev-log
make logs-infra
make learn-list
make learn-rules
./scripts/incident-learn.sh --help
```

## What the script creates

```text
<project>/
├── api.yaml
├── .air.toml
├── .env.example / .env
├── .gitignore
├── Makefile
├── go.mod / go.sum
├── package.json / pnpm-workspace.yaml / lockfile
├── progress.md
├── memory.md
├── sqlc.yaml
├── scripts/context-brief.sh
├── scripts/incident-learn.sh
├── logs/{runtime,snapshots}/
├── logs/learning.db            # created on first incident directive
├── cmd/{api,worker,seed}/
├── internal/
├── pkg/
├── migrations/000001_initial.*
├── infra/docker-compose.yml
├── web/
├── ui/
├── docs/{onepager.md,prd.md,epic.md,conventions.md,architecture.md}
└── .github/workflows/ci.yml
```

## Slice 0 acceptance checklist

| # | Command | Pass criteria |
|---|---|---|
| 1 | `make dev-infra` | DB/Redis/MinIO healthy |
| 2 | `make migrate` | Exit 0 |
| 3 | `make schema-dump` | `schema.sql` generated |
| 4 | `make generate` | Codegen succeeds |
| 5 | `make dev-api` | `/api/health` returns ok |
| 6 | `make dev-web` | Frontend loads |
| 7 | `make test` | Tests pass |
| 8 | `make lint` | Lint passes |
| 9 | `make validate` | Generated artifacts in sync |
| 10 | `make build` | API/worker binaries + web build |
| 11 | `make learn-error ARGS='--story US-000 --title \"...\" --signal \"...\" --root-cause \"...\" --correction \"...\" --prevention-rule \"...\" --checks \"...\"'` | Incident directive recorded in `logs/learning.db` |

## One-shot smoke test

```bash
make dev-infra && sleep 3 && make migrate && make schema-dump && make generate \
  && make lint && make test && make build \
  && (make dev-api & sleep 3 && curl -sf localhost:3000/api/health && kill %1) \
  && echo "Slice 0 passed"
```
