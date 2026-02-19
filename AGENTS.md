# AGENTS.md — LLM Operating Rules

> Purpose: keep agents on a reliable path without over-constraining delivery.
> Stack: Go + TypeScript (React/Vite) + PostgreSQL + Redis + Docker Compose.
> Contract bridge: `api.yaml` -> generated TS types in `web/src/lib/api/schema.d.ts`.

## 1) Operating Intent

- Optimize for delivery velocity with safety.
- Prefer the smallest correct change over broad refactors.
- Keep planning simple: use `docs/epic.md` as the single backlog source.
- Keep learning durable: store major incident lessons in `memory.md`.

## 2) Hard Constraints (MUST)

1. Spec-first for API work: update `api.yaml` before implementation.
2. Never hand-edit generated files: `schema.sql`, `web/src/lib/api/schema.d.ts`, `internal/store/*.go`.
3. Respect boundaries:
   - `internal/` is Go-only domain/backend logic.
   - `web/` is TypeScript UI/client only.
   - `api.yaml` is the backend/frontend contract bridge.
4. Never commit secrets (`.env` stays local, keep `.env.example` current).
5. All list endpoints are bounded and paginated.
6. Planning state belongs in `docs/epic.md` (Story Index + story sections).
7. Major/critical incident learnings must be captured as directives in `logs/learning.db` via `./scripts/workflow.sh incident learn` (delegates to `incident-learn.sh`); durable rules live in `memory.md`.
8. If implementation intentionally deviates from plan, log it in `progress.md`.

## 3) Context Bootstrap (SHOULD First)

Recommended first command:

```bash
./scripts/workflow.sh context brief
```

Then read based on task type:

- Always: `progress.md`
- Always: `memory.md` (latest lessons)
- Planning intent/state: `docs/epic.md`
- Domain model and bounded contexts: `docs/ddd.md`
- API change: `api.yaml`
- DB/schema change: `migrations/` + `schema.sql`
- Backend module work: `internal/<module>/`
- Frontend feature work: `web/src/features/<module>/`
- Pattern references when needed: `docs/conventions.md`

Quick routing:

```text
START
|- Planning question?        -> docs/epic.md (Story Index -> target story)
|- API surface changed?      -> api.yaml -> generate types -> implement
|- DB shape changed?         -> new migration -> migrate/schema/sqlc
|- Backend behavior changed? -> handler/service/queries + tests
`- Frontend behavior changed?-> feature hooks/views + states + tests
```

## 4) Core Workflows

### Story execution workflow

1. Choose next ready story with `./scripts/workflow.sh story ready`.
2. Start it with `./scripts/workflow.sh story start --story US-XXX [--owner <name>]`.
3. Implement smallest correct code change.
4. Run validation based on risk (Section 5).
5. Complete it with `./scripts/workflow.sh story done --story US-XXX --summary "..."`.

### API Change

1. Update `api.yaml`.
2. Run `make generate-types`.
3. Update backend + frontend code to match generated types.
4. Add/update tests.

### DB Schema Change

1. Create a new migration pair (append-only).
2. Apply + regenerate:
   - `make migrate`
   - `make schema-dump`
   - `make generate-sqlc` (or `make generate` when needed)
3. Update calling code/tests.

### Bug Fix

1. Reproduce from report/log/test.
2. Add a failing regression test when practical.
3. Implement minimal fix.
4. Re-run checks based on risk (Section 5).

### Error Learning (major incidents only)

1. Record directive:
   - `./scripts/workflow.sh incident learn --story US-XXX --title \"...\" --signal \"...\" --root-cause \"...\" --correction \"...\" --prevention-rule \"...\" --checks \"...\"`
2. Add `--with-snapshot` only when raw evidence is necessary.
3. Inspect directives/rules:
   - `./scripts/workflow.sh incident list`
   - `./scripts/workflow.sh incident rules`
4. Apply prevention rule to active story and continue execution.

## 5) Validation Strategy (Risk-Based)

- Low risk (`docs/`, comments, copy): run only relevant checks.
- Normal code changes: run `make lint` and `make test`.
- Contract/schema/shared-layer changes: run `make validate`, `make lint`, `make test`.
- Before PR/merge: ensure `make validate`, `make lint`, `make test` are green.

Use `make test-integration` when DB-dependent behavior changes.

## 6) Source of Truth

```text
1) Code + generated artifacts (current truth)
2) docs/epic.md (planned backlog + story state)
3) logs/learning.db (incident directives + queryable history)
4) memory.md (high-signal prevention rules)
5) progress.md (what changed and why)
6) docs/prd.md + docs/onepager.md + docs/ddd.md (business and domain context)
```

## 7) Progress Discipline

Keep `progress.md` short and current:

- What was done?
- What is inactive/blocked?
- What needs rework?

When implementation intentionally diverges from epic intent, append:

```text
### DEV-XXX - Short description (YYYY-MM-DD)
Story: US-XXX
What changed:
Why:
Affected files:
```

## 8) Skills

- Skills are project-scoped under `.agents/skills/`.
- Use core skills by task:
  - `$api-contract`
  - `$db-migration`
  - `$go-module`
  - `$web-feature`
- Use optional skills when needed:
  - `$fix-bug`
  - `$error-learning`
  - `$task-ops`
  - `$frontend-design`
  - `$project-scaffold` (template/bootstrap use)

## 9) Stop-The-Line Cases

Pause feature work and fix immediately if any of these occur:

- generated artifacts are out of sync
- migration failure or data integrity risk
- repeated unknown major error pattern (run `$error-learning` before continuing)
- critical auth/security bug
- critical user journey broken on `main`

## 10) Never Do

- Edit generated files directly.
- Implement endpoint changes without updating `api.yaml` first.
- Edit old migrations in place (add new migrations instead).
- Import backend code into `web/` or frontend concerns into `internal/`.
- Commit secrets.
