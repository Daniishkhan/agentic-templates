# Project Bootstrap Guide

> **What this file is:** How to scaffold a new project. Run one script, verify the checklist, start building.
> **After bootstrapping:** Keep this file under `.agents/skills/project-scaffold/references/` as the canonical checklist.

---

## Quick start

```bash
chmod +x .agents/skills/project-scaffold/scripts/bootstrap.sh
./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>
# Example: ./.agents/skills/project-scaffold/scripts/bootstrap.sh rideshare mycompany
```

The script handles everything: prerequisite checks, directory structure, config files, Go/frontend initialization, starter code stubs, CI pipeline, and initial commit. It installs missing Go tools automatically.

Frontend defaults installed by the script:
- Tailwind CSS v4 via Vite plugin (`@tailwindcss/vite`)
- shadcn/ui CLI (`shadcn@latest`) with starter components
- Default shadcn theme baseline via tweakcn: `modern-minimal`
- TanStack Query + React Router + Zustand
- React Hook Form + Zod + resolver bridge
- Vitest + Testing Library + Playwright

Note: the script attempts non-interactive `shadcn` initialization, starter component add, and default theme install. It also writes a fallback `web/components.json` automatically if `shadcn init` does not complete.

Manual rerun commands (optional):
- `cd web && pnpm dlx shadcn@latest init --yes --base-color zinc`
- `cd web && pnpm dlx shadcn@latest add button card input form sonner --yes`
- `cd web && pnpm dlx shadcn@latest add https://tweakcn.com/r/themes/modern-minimal.json --yes`

If the remote theme install fails, the bootstrap script writes the same `modern-minimal` token set directly to `web/src/index.css` as a fallback.

Local infrastructure ports used by scaffold (to avoid common host collisions):
- Postgres: `localhost:55432`
- Redis: `localhost:56379`
- MinIO API: `localhost:59000`
- MinIO Console: `localhost:59001`

Compose isolation: `make dev-infra` uses a compose project name derived from the repo folder, so multiple scaffolded projects can run concurrently without container/volume name collisions.

Backend defaults installed by the script:
- chi router + CORS middleware
- pgx + Redis client
- validator + JWT + uuid + testify

---

## Prerequisites

The script auto-installs everything via Homebrew. Only Homebrew itself must be pre-installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

The script will `brew install` any missing tools: `go`, `node@22`, `docker` (cask), `sqlc`, `golang-migrate`, `air`, `golangci-lint`. It sets up `pnpm` via corepack and installs `oapi-codegen` via `go install` (no brew formula).

---

## After scaffolding

The script creates a working repo but leaves two things for you to fill in:

1. **Data model** — Edit `migrations/000001_initial.up.sql` with your MVP tables from the epic, write the matching `down.sql`.
2. **Documentation** — Copy `AGENTS.md` into the repo root. Fill in `docs/epic.md`, `docs/prd.md`, `docs/onepager.md`.

Then run the stack:

```bash
cd <project_name>
make dev-infra          # Start Postgres, Redis, MinIO
make migrate            # Apply your migration
make schema-dump        # Generate schema.sql
make generate           # Run all codegen
make dev                # Start API + frontend + worker
```

---

## What the script creates

```
<project>/
├── api.yaml                       # OpenAPI spec (health endpoint stub)
├── .air.toml                      # Go hot reload config
├── .env.example / .env            # Environment variables
├── .gitignore                     # Includes agent tooling patterns
├── Makefile                       # All standard commands
├── go.mod / go.sum                # Go module + deps
├── package.json                   # Root pnpm workspace
├── pnpm-workspace.yaml / lock     # Workspace config
├── progress.md                    # Minimal placeholder (agent-maintained)
├── sqlc.yaml                      # SQL codegen config
│
├── cmd/api/main.go                # API entrypoint (serves /health)
├── cmd/worker/main.go             # Worker stub
├── cmd/seed/main.go               # Seed script stub
│
├── pkg/httputil/response.go       # JSON/Error/Paged response helpers
├── pkg/errors/codes.go            # Registered error code constants
├── internal/system/queries.sql    # Placeholder sqlc query (keeps generate green)
├── internal/store/                # sqlc output directory (empty pre-migration)
│
├── migrations/000001_initial.*    # Placeholder migration (you fill in)
├── infra/docker-compose.yml       # Postgres, Redis, MinIO
│
├── web/                           # React + Vite + TanStack Query
│   ├── package.json               # dev/build/lint/test/typecheck scripts
│   ├── index.html / vite.config   # Entry + build config
│   ├── vitest.config.ts           # Vitest (jsdom + setup + coverage)
│   ├── eslint.config.js           # Flat ESLint config for TS/React
│   ├── components.json            # shadcn/ui config (if CLI init succeeds)
│   ├── src/main.tsx / App.tsx     # App shell
│   ├── src/lib/store/app-store.ts # Zustand starter store
│   ├── src/test/setup.ts          # Testing Library setup
│   └── src/lib/api/schema.d.ts    # Type placeholder (overwritten by codegen)
│
├── ui/                            # Shared UI workspace package
├── docs/                          # epic, prd, onepager stubs
└── .github/workflows/ci.yml      # Lint → validate → test → build
```

---

## Slice 0 acceptance checklist

Every item must pass before moving to Slice 1.

| # | Command | Pass criteria |
|---|---------|---------------|
| 1 | `make dev-infra` | `docker ps` shows postgres, redis, minio healthy |
| 2 | `make migrate` | Exit 0. Tables exist in DB. |
| 3 | `make schema-dump` | `schema.sql` exists with your table definitions |
| 4 | `make generate` | Exit 0. `internal/store/*.go` + `web/src/lib/api/schema.d.ts` generated |
| 5 | `make dev-api` | `curl localhost:3000/api/health` → `{"status":"ok"}` |
| 6 | `make dev-web` | Browser at `localhost:5173` shows app shell |
| 7 | `make test` | Exit 0. Go + frontend tests pass. |
| 8 | `make lint` | Exit 0. golangci-lint + ESLint clean. |
| 9 | `make validate` | Exit 0. "All generated files are in sync." |
| 10 | `make build` | `bin/api`, `bin/worker` exist. `web/dist/` built. |
| 11 | `cd web && pnpm exec shadcn --help` | shadcn CLI available for adding components |

### One-shot smoke test

```bash
make dev-infra && sleep 3 && make migrate && make schema-dump && make generate \
  && make lint && make test && make build \
  && (make dev-api & sleep 3 && curl -sf localhost:3000/api/health && kill %1) \
  && echo "✅ Slice 0 passed"
```

---

## Ignored local files

The `.gitignore` includes patterns for LLM agent workspace artifacts. These are local to each developer or agent session — never committed:

```
.agents/  .claude/  .cursor/  .aider/  .copilot/
*.skill   CLAUDE.md  .cursorules  .aiderignore
```

Add new patterns as new tools emerge.

---

## Clean up

Keep `.agents/skills/project-scaffold/scripts/bootstrap.sh` and this skill reference in the template repo.
If you copied temporary bootstrap notes into a generated project, remove only those temporary notes.

Build features slice by slice from `docs/epic.md`, with `AGENTS.md` as the rules and `progress.md` as the tracker.
