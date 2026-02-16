---
name: db-migration
description: >
  Create and apply PostgreSQL schema migrations for this project. Use when
  adding or changing tables, columns, constraints, indexes, or query patterns
  that require schema updates and sqlc regeneration.
metadata:
  short-description: Safe PostgreSQL migration workflow
---

# Database Migration

Create safe, append-only schema changes with regeneration.

## Canonical files

- `migrations/*.up.sql` / `migrations/*.down.sql`
- `schema.sql` (generated)
- `internal/*/queries.sql` + `internal/store/*.go` (generated via sqlc)

## Procedure

1. Create a migration file pair:
   - `.agents/skills/db-migration/scripts/new-migration.sh <name>`
2. Write `up.sql` with explicit indexes for new query patterns.
3. Write `down.sql` that safely reverses `up.sql`.
4. Apply and regenerate:
   - `make migrate`
   - `make schema-dump`
   - `make generate-sqlc`
5. If queries changed, run `make generate`.
6. Update affected handlers/services/tests.
7. Update `progress.md` with migration status and follow-ups.

## Zero-downtime rules

- Never edit committed migration files; add new migrations only.
- Use two-step destructive changes:
  - Step 1: add nullable/new field and backfill
  - Step 2: remove old field later after code rollout
- Add indexes for filter/sort paths.
- Keep list queries bounded (`LIMIT/OFFSET`) and indexed.

## Commit rule

Commit migration files together with generated artifacts (`schema.sql`, sqlc output).
