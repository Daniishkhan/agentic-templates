# AGENTS.md — LLM Operating Rules

> Purpose: keep agents on a reliable path without over-constraining normal delivery.
> Stack: Go + TypeScript (React/Vite) + PostgreSQL + Redis + Docker Compose.
> Contract bridge: `api.yaml` -> generated TS types in `web/src/lib/api/schema.d.ts`.

## 1) Operating Intent

- Optimize for delivery velocity with safety.
- Prefer the smallest correct change over broad refactors.
- Treat this file as guardrails, not a script to follow blindly.

## 2) Hard Constraints (MUST)

1. Spec-first for API work: update `api.yaml` before implementation.
2. Never hand-edit generated files: `schema.sql`, `web/src/lib/api/schema.d.ts`, `internal/store/*.go`.
3. Respect boundaries:
   - `internal/` is Go-only domain/backend logic.
   - `web/` is TypeScript UI/client only.
   - `api.yaml` is the backend/frontend contract bridge.
4. Never commit secrets (`.env` stays local, keep `.env.example` current).
5. All list endpoints are bounded and paginated.
6. When plan docs conflict with code, code + generated artifacts win.
7. If you intentionally deviate from planned behavior, log it in `progress.md`.

## 3) Context Bootstrap (SHOULD First)

Recommended first command:

```bash
./scripts/context-brief.sh
```

Reference: `.agents/references/context-bootstrap.md`

Then read based on task type:

- Always: `progress.md`
- API change: `api.yaml`
- DB/schema change: `migrations/` + `schema.sql`
- Backend module work: `internal/<module>/`
- Frontend feature work: `web/src/features/<module>/`
- Planning intent only: `docs/epic.md`
- Pattern references when needed: `docs/conventions.md`

Quick routing:

```text
START
|- API surface changed?      -> api.yaml -> generate types -> implement
|- DB shape changed?         -> new migration -> migrate/schema/sqlc
|- Backend behavior changed? -> handler/service/queries + tests
`- Frontend behavior changed?-> feature hooks/views + states + tests
```

## 4) Core Workflows

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
4. Re-run checks based on risk (see Section 5).

## 5) Validation Strategy (Risk-Based)

- Low risk (`docs/`, comments, copy): run only relevant checks.
- Normal code changes: run `make lint` and `make test`.
- Contract/schema/shared-layer changes: run `make validate`, `make lint`, `make test`.
- Before PR/merge: ensure `make validate`, `make lint`, `make test` are green.

Use `make test-integration` when DB-dependent behavior is changed.

## 6) Source of Truth

```text
1) Code + generated artifacts (current truth)
2) progress.md (what changed and why)
3) docs/epic.md (planning intent; historical after implementation)
4) docs/prd.md + docs/onepager.md (business context)
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
  - `$frontend-design`
  - `$project-scaffold` (template/bootstrap use)

## 9) Stop-The-Line Cases

Pause feature work and fix immediately if any of these occur:

- generated artifacts are out of sync
- migration failure or data integrity risk
- critical auth/security bug
- critical user journey broken on `main`

## 10) Never Do

- Edit generated files directly.
- Implement an endpoint change without first updating `api.yaml`.
- Edit old migrations in place (add new migrations instead).
- Import backend code into `web/` or frontend concerns into `internal/`.
- Commit secrets.
