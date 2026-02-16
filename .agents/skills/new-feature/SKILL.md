---
name: new-feature
description: >
  Implement a new feature end-to-end. Use when asked to build a feature,
  implement a story, pick up a FEAT-XXX, or add functionality spanning
  backend and frontend.
metadata:
  short-description: Implement full-stack features end-to-end
---

# New Feature Implementation

> Detailed patterns: `docs/conventions.md`. Rules: `agents.md` §7-§10.

## Procedure

1. **Read** — `progress.md` → `api.yaml` → `schema.sql` → feature spec in `docs/features/` → existing code + tests. If spec conflicts with code, **code wins**.

2. **Contract** — Update `api.yaml` first (spec-first). Run `make generate-types`. Verify types before implementing.

3. **Migrate** (if needed) — `make migrate-new NAME=x` → write up + down SQL → `make migrate && make schema-dump`. Never edit committed migrations.

4. **Queries** — Write in `internal/<module>/queries.sql` → `make generate-sqlc`. Every list has `LIMIT`/`OFFSET`.

5. **Service** — Business logic in `service.go`. No `net/http` imports. Return domain types + errors.

6. **Handler** — Wire HTTP in `handler.go`. Parse → validate → call service → respond via `pkg/httputil`.

7. **Tests** — `handler_test.go`: happy path + every error case. `service_test.go`: edge cases. Table-driven when 3+ cases.

8. **Frontend** — Build in `web/src/features/<module>/`. Generated types only. TanStack Query. Handle loading/error/empty states.

9. **E2E** — Playwright test if critical user journey.

10. **Validate** — `make validate` → `make lint` → `make test`.

11. **Track** — Update `progress.md`. Log deviations as `DEV-XXX` if implementation differs from spec.

## Done checklist

- [ ] Acceptance criteria met
- [ ] `api.yaml` updated, types regenerated
- [ ] Handler test: happy + every error case
- [ ] Service test: business logic edges
- [ ] Frontend: loading, error, empty states
- [ ] List endpoints paginated
- [ ] `make validate` + `make lint` + `make test` pass
- [ ] `progress.md` updated
