---
id: EPIC-BACKLOG
type: epic-backlog
schema_version: 2
status: active
owner: "[Tech Lead Name]"
last_updated: "YYYY-MM-DD"
source_prd: docs/prd.md
source_onepager: docs/onepager.md
---

# Feature Backlog (Epic)

> Scope: [PROJECT_SCOPE_ONE_LINER]
> References: `docs/prd.md`, `docs/onepager.md`, `AGENTS.md`
> Execution log: `progress.md`

## How to use this file

- This is the single backlog source of truth for planning.
- Keep the **Story Index** current first (status, owner, dependencies).
- Keep detailed story sections below for acceptance criteria and implementation tasks.
- During implementation, AI executes from this file and writes run-state updates to `progress.md`.

## Status model

- `backlog` -> `ready` -> `in-progress` -> `done`
- `blocked` can be used from `ready` or `in-progress`

## Story Index (machine-readable, update first)

<!-- STORY_INDEX_START -->
```yaml
stories:
  - id: US-000
    title: Repository setup + local dev environment
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: []

  - id: US-001
    title: Database schema + initial migration
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: [US-000]

  - id: US-002
    title: CI pipeline
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: [US-000]
```
<!-- STORY_INDEX_END -->

## Issue naming

| Type | Format | Example |
|---|---|---|
| Epic | `EPIC-XX Module Name` | `EPIC-01 Authentication` |
| Story | `US-XXX Short outcome` | `US-010 Create an Order` |
| Task | `TSK-XXXX Implementation step` | `TSK-0101 Write migration for orders table` |

## Labels

- Phase: `mvp`, `phase2`, `future`
- Layer: `backend`, `frontend`, `mobile`, `infra`, `qa`
- Concern: project-specific tags like `auth`, `analytics`, `realtime`

## Story template (copy for new stories)

~~~markdown
## US-XXX Story title (short, outcome-focused)

**Story Meta**
```yaml
id: US-XXX
status: backlog
priority: medium
depends_on: []
owner: unassigned
```

**Persona:** Who benefits
**Outcome:** One sentence describing what becomes possible.

**Acceptance Criteria**
- [ ] Specific observable behavior #1
- [ ] Specific observable behavior #2
- [ ] Error or edge case behavior

**API Contract** (planning intent only)
Endpoint: `METHOD /api/path`
Request:
- `field` (type, required/optional) — description

Response:
- `data.field` (type) — description

Errors:
- 4XX `ERROR_CODE` — when this happens

**Tasks**
- [ ] `migrations/...` — migration changes
- [ ] `internal/<module>/queries.sql` — SQL queries
- [ ] `internal/<module>/service.go` — business logic
- [ ] `internal/<module>/handler.go` — HTTP handler
- [ ] `api.yaml` — contract updates
- [ ] `web/src/features/<module>/...` — UI changes
- [ ] Tests: handler + service + integration/E2E as needed
~~~

---

# EPIC-00 Project Scaffolding & Foundation

> Slice 0: Feature work cannot start until repo, DB workflow, and CI are in place.

## US-000 Repository setup + local dev environment

**Story Meta**
```yaml
id: US-000
status: backlog
priority: high
depends_on: []
owner: unassigned
```

**Persona:** Developer (human or LLM)
**Outcome:** Any contributor can clone, install, and run the full stack locally in under 10 minutes.

**Acceptance Criteria**

- [ ] `make dev-infra` starts Postgres, Redis, and object storage via Docker Compose
- [ ] `make migrate` applies all migrations successfully
- [ ] `make dev` starts the Go API and frontend dev server
- [ ] `make lint`, `make test`, and `make validate` all pass
- [ ] `.env.example` documents required environment variables
- [ ] `curl http://localhost:3000/api/health` returns `{"status":"ok"}`

**Tasks**

- [ ] Initialize repo via `$project-scaffold`
- [ ] `go.mod` initialized with core dependencies
- [ ] `web/` initialized with React + Vite + TypeScript + Tailwind
- [ ] `infra/docker-compose.yml` for Postgres/Redis/MinIO
- [ ] `Makefile` standard commands
- [ ] `.env.example` documented
- [ ] `sqlc.yaml` configured
- [ ] `.air.toml` configured
- [ ] `api.yaml` includes `/health`
- [ ] `pkg/httputil/` response helpers

## US-001 Database schema + initial migration

**Story Meta**
```yaml
id: US-001
status: backlog
priority: high
depends_on: [US-000]
owner: unassigned
```

**Persona:** Developer
**Outcome:** Core tables exist and migration workflow is proven.

**Acceptance Criteria**

- [ ] MVP tables created per data model
- [ ] `make migrate` applies on fresh DB
- [ ] `make schema-dump` produces accurate `schema.sql`
- [ ] `make generate-sqlc` generates typed Go code
- [ ] Seed script creates deterministic baseline data

**Tasks**

- [ ] `migrations/000001_initial.up.sql` create MVP tables + indexes
- [ ] `migrations/000001_initial.down.sql` reversible rollback
- [ ] `internal/<module>/queries.sql` initial CRUD queries
- [ ] `cmd/seed/main.go` deterministic seed script
- [ ] Verify fresh apply + rollback path

## US-002 CI pipeline

**Story Meta**
```yaml
id: US-002
status: backlog
priority: medium
depends_on: [US-000]
owner: unassigned
```

**Persona:** Developer
**Outcome:** PRs are gated by lint, validate, tests, and build.

**Acceptance Criteria**

- [ ] CI runs on every PR to `main`
- [ ] Pipeline: lint -> validate -> test -> build
- [ ] Postgres service available for integration tests
- [ ] Branch protection requires CI pass + approval

**Tasks**

- [ ] `.github/workflows/ci.yml` full pipeline
- [ ] Postgres service in CI
- [ ] `make validate` in CI
- [ ] Branch protection rules documented/enforced

---

# EPIC-01 [Module Name] (MVP)

> Why: [One sentence explaining why this module exists.]

## US-0XX [Story title]

**Story Meta**
```yaml
id: US-0XX
status: backlog
priority: medium
depends_on: []
owner: unassigned
```

**Persona:** [Role]
**Outcome:** [What becomes possible]

**Acceptance Criteria**

- [ ] [Specific testable behavior]
- [ ] [Error case]
- [ ] [Access/control case]

**API Contract**

Endpoint: `METHOD /api/path`
Request:
- `field` (type, required/optional) — description

Response:
- `data.field` (type) — description

Errors:
- `4XX ERROR_CODE` — when this happens

**Tasks**

- [ ] `migrations/` migration if needed
- [ ] `internal/<module>/queries.sql` SQL queries
- [ ] `internal/<module>/service.go` business logic
- [ ] `internal/<module>/handler.go` HTTP handler
- [ ] `api.yaml` contract updates
- [ ] `web/src/features/<module>/` UI updates
- [ ] Tests: handler + service + integration/E2E as needed
