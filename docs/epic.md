# Feature Backlog (Epic)

> **Scope:** {{PROJECT_SCOPE_ONE_LINER}}
> **References:** [Architecture](./architecture.md) · [PRD](./prd.md) · [Agents](../AGENTS.md)
> **Tracking:** Progress tracked in `progress.md` at repo root.
>
> **How to use this document:**
> - PMs and tech leads write stories here during planning.
> - Developers and LLM agents read stories for **intent and acceptance criteria**.
> - Once a story is implemented, this document becomes **historical**. The code, `api.yaml`, and `schema.sql` are the truth — not this file.
> - If implementation differs from what's written here, log a deviation in `progress.md` (see `AGENTS.md`, Progress Discipline). Do NOT update this file to match the code.
>
> **Conventions and validation expectations** are defined in `AGENTS.md`. They are not repeated here to avoid drift.

---

## Issue naming

| Type | Format | Example |
|------|--------|---------|
| Epic | `EPIC-XX Module Name` | `EPIC-01 Authentication` |
| Story | `US-XXX Short outcome` | `US-010 Create an Order` |
| Task | `TSK-XXXX Implementation step` | `TSK-0101 Write migration for orders table` |

## Labels

- **Phase:** `mvp`, `phase2`, `future`
- **Layer:** `backend`, `frontend`, `mobile`, `infra`, `qa`
- **Concern:** (project-specific, e.g. `realtime`, `offline`, `auth`, `analytics`)

---

## How to write a story

Each story follows a consistent format that both humans and LLM agents can parse. Template:

```markdown
## US-XXX Story title (short, outcome-focused)

**Persona:** Who benefits from this story
**Outcome:** One sentence describing what becomes possible when this is done.

**Acceptance Criteria**
<!-- Bulleted list. Each bullet is independently testable. -->
<!-- Be specific about behavior, not implementation. -->
<!-- Include error cases and edge cases. -->

* [Specific observable behavior #1]
* [Specific observable behavior #2]
* [Error case: what happens when X goes wrong]

**API Contract** (if this story involves API endpoints)
<!-- This is PLANNING INTENT. Once implemented, api.yaml is the truth. -->

Endpoint: `POST /api/resource`
Request:
- `field_name` (type, required/optional) — description

Response (201):
- `data.id` (uuid) — created resource ID
- `data.field_name` (type) — description

Errors:
- 422 `VALIDATION_ERROR` — missing required fields
- 409 `DUPLICATE` — resource already exists

**Tasks**
<!-- Ordered checklist. Include file paths for LLM navigation. -->

* [ ] `migrations/` — Create migration for new table(s)
* [ ] `internal/<module>/queries.sql` — Write SQL queries
* [ ] `internal/<module>/service.go` — Implement business logic
* [ ] `internal/<module>/handler.go` — Wire HTTP handler
* [ ] `api.yaml` — Define endpoint contract
* [ ] `web/src/features/<module>/` — Build UI
* [ ] **Test (handler):** Happy path + error cases
* [ ] **Test (service):** Business logic edge cases
* [ ] **Test (E2E):** [Only if critical user journey]
```

### Writing good acceptance criteria

**Good (specific, testable):**
- ✅ "Order list returns max 20 results per page"
- ✅ "Submitting without a required field returns 422 with field-level errors"
- ✅ "Rider role cannot access the `/api/admin/*` endpoints (returns 403)"

**Bad (vague, untestable):**
- ❌ "System should be fast"
- ❌ "Errors are handled properly"
- ❌ "UI looks good"

### Writing good API contracts

Include enough detail for an LLM to implement the endpoint. Accept that this is **planning intent** — the real contract lives in `api.yaml` after implementation.

**Good:**
```
Endpoint: POST /api/orders
Request:
- customer_name (string, required) — customer display name
- phone (string, required) — contact number
- items (array, required, min 1) — at least one item
  - description (string, required)
  - quantity (integer, required, min 1)

Response (201):
- data.id (uuid)
- data.status (string) — always "CREATED" on creation
- data.items[] (array) — created items with IDs

Errors:
- 422 VALIDATION_ERROR — missing or invalid fields
- 401 UNAUTHENTICATED — no valid token
- 403 FORBIDDEN — role not authorized
```

**Bad:**
```
Create an order endpoint that takes order data and returns the order.
```

---

## MVP user journeys

<!-- Define the critical end-to-end paths. Used for slice ordering and E2E tests. -->

### J1 — {{Primary Journey Name}}

1. {{Actor}} does {{action}} → {{observable result}}
2. {{Actor}} does {{action}} → {{observable result}}
3. ...

### J2 — {{Secondary Journey Name}}

1. {{Actor}} does {{action}} → {{observable result}}
2. ...

---

# EPIC-00 Project Scaffolding & Foundation

> Slice 0: Feature work cannot start until the repo, database, CI, and shared utilities are in place.

## US-000 Repository setup + local dev environment

**Persona:** Developer (human or LLM)
**Outcome:** Any contributor can clone, install, and run the full stack locally in under 10 minutes.

**Acceptance Criteria**

* `make dev-infra` starts Postgres, Redis, and object storage via Docker Compose
* `make migrate` applies all migrations successfully
* `make dev` starts the Go API and frontend dev server
* `make lint`, `make test`, and `make validate` all pass
* `.env.example` documents all required environment variables
* `curl http://localhost:3000/api/health` returns `{"status":"ok"}`

**Tasks**

* [ ] Initialize repo with directory structure via `$project-scaffold` and `.agents/skills/project-scaffold/scripts/bootstrap.sh`
* [ ] `go.mod` initialized with core dependencies
* [ ] `web/` initialized with React + Vite + TypeScript + Tailwind
* [ ] `infra/docker-compose.yml` — Postgres, Redis, MinIO
* [ ] `Makefile` — all standard commands working
* [ ] `.env.example` — all vars documented
* [ ] `sqlc.yaml` — configured for the project
* [ ] `.air.toml` — Go hot reload configured
* [ ] `api.yaml` — stub with /health endpoint
* [ ] `pkg/httputil/` — response helpers (JSON, PagedJSON, Error, ValidationError)
* [ ] `progress.md` — initialized with Slice 0

---

## US-001 Database schema + initial migration

**Persona:** Developer
**Outcome:** Core tables exist and the migration workflow is proven.

**Acceptance Criteria**

* All MVP tables created per the data model in the PRD
* `make migrate` applies cleanly on a fresh database
* `make schema-dump` produces an accurate `schema.sql`
* `make generate-sqlc` produces typed Go code from initial queries
* Seed script creates baseline test data

**Tasks**

* [ ] `migrations/000001_initial.up.sql` — create all MVP tables with indexes
* [ ] `migrations/000001_initial.down.sql` — drop all tables (reversible)
* [ ] `internal/<module>/queries.sql` — basic CRUD queries for each entity
* [ ] `make generate-sqlc` — verify generation succeeds
* [ ] `cmd/seed/main.go` — seed script with deterministic test data
* [ ] Verify: migration applies on fresh Postgres, rollback works

---

## US-002 CI pipeline

**Persona:** Developer
**Outcome:** PRs are gated by lint, typecheck, tests, generation check, and build.

**Acceptance Criteria**

* CI runs on every PR to `main`
* Pipeline: lint → validate (generate check) → test → build
* Postgres service available in CI for integration tests
* Branch protection on `main`: require CI pass + 1 approval

**Tasks**

* [ ] `.github/workflows/ci.yml` — full pipeline
* [ ] Postgres service container in CI
* [ ] `make validate` runs in CI (catches drift)
* [ ] Branch protection rules configured

---

<!-- TEMPLATE: Copy and customize the sections below per feature -->

# EPIC-01 {{Module Name}} (MVP)

> **Why:** {{One sentence explaining why this module exists and what user problem it solves.}}

## US-0XX {{Story title}}

**Persona:** {{Role}}
**Outcome:** {{What becomes possible.}}

**Acceptance Criteria**

* {{Specific testable behavior}}
* {{Error case}}
* {{Access control case}}

**API Contract**

```
Endpoint: METHOD /api/path
Request:
- field (type, required/optional) — description

Response (status):
- data.field (type) — description

Errors:
- 4XX ERROR_CODE — when this happens
```

**Tasks**

* [ ] `migrations/` — migration if schema changes needed
* [ ] `internal/<module>/queries.sql` — SQL queries
* [ ] `internal/<module>/service.go` — business logic
* [ ] `internal/<module>/handler.go` — HTTP handler
* [ ] `api.yaml` — endpoint contract
* [ ] `web/src/features/<module>/` — UI implementation
* [ ] **Test (handler):** happy path + error cases
* [ ] **Test (service):** business logic
* [ ] **Test (E2E):** if critical journey (reference Jx)

---

# MVP Slice Plan

> Each slice is shippable and testable end-to-end. Update `progress.md` as slices complete.

### Slice 0 — "Foundation"

**Stories:** US-000, US-001, US-002
**Delivers:** Repo running. DB schema. CI pipeline. Local dev working.
**Exit criteria:** Any contributor can clone → `make dev-infra && make migrate && make dev` → working stack. CI passes.

---

### Slice 1 — "{{First Vertical Feature}}"

**Stories:** US-0XX, US-0XX, ...
**Depends on:** Slice 0
**Delivers:** {{What end-to-end journey this unlocks.}}
**Exit criteria:** {{Specific testable condition.}}

---

### Slice 2 — "{{Second Feature}}"

**Stories:** US-0XX, US-0XX, ...
**Depends on:** Slice 1
**Delivers:** {{Description.}}
**Exit criteria:** {{Condition.}}

---

## Handoff notes

Before starting any slice, read `AGENTS.md` in full. It contains guardrails, validation strategy, and the truth hierarchy. Do not rely on this epic for current implementation details — it is historical once stories are built.
