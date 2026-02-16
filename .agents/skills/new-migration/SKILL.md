---
name: new-migration
description: >
  Create a database migration. Use when asked to add a table, column,
  index, change a type, rename or drop something, or any schema change.
metadata:
  short-description: Create safe append-only schema migrations
---

# Database Migration

## Procedure

1. **Create files:** `make migrate-new NAME=short_description`

2. **Write up.sql:**

```sql
-- New table
CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    owner_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX idx_resources_status_created ON resources (status, created_at DESC);
CREATE INDEX idx_resources_owner ON resources (owner_id);
CREATE INDEX idx_resources_deleted ON resources (deleted_at) WHERE deleted_at IS NULL;

-- Add column
ALTER TABLE resources ADD COLUMN description TEXT;

-- Add index (on large tables use CONCURRENTLY)
CREATE INDEX CONCURRENTLY idx_resources_name ON resources (name);
```

3. **Write down.sql** (must undo the up):

```sql
DROP TABLE IF EXISTS resources;
-- or: ALTER TABLE resources DROP COLUMN IF EXISTS description;
-- or: DROP INDEX IF EXISTS idx_resources_name;
```

4. **Apply:** `make migrate && make schema-dump && make generate-sqlc`

5. **Commit together:** migration files + `schema.sql` + sqlc generated files.

## Destructive changes — two-step approach

**Migration 1** (deploy first):
```sql
ALTER TABLE resources ALTER COLUMN old_field DROP NOT NULL;
-- or: ADD COLUMN new_field alongside old
```

**Migration 2** (after confirming no code reads old data):
```sql
ALTER TABLE resources DROP COLUMN old_field;
```

## Rules

- **Never** edit a committed migration — create a new one
- Every `up.sql` has a matching `down.sql`
- Every new query pattern needs a supporting index
- Filter columns first, sort columns second in indexes
- Partial indexes (`WHERE deleted_at IS NULL`) for soft-delete tables
- `CREATE INDEX CONCURRENTLY` for large existing tables

## Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Tables | snake_case, plural | `orders`, `order_items` |
| Columns | snake_case | `created_at`, `assigned_user_id` |
| Primary keys | `id` (UUID) | `id UUID PRIMARY KEY` |
| Foreign keys | `<entity>_id` | `order_id`, `user_id` |
| Indexes | `idx_<table>_<columns>` | `idx_orders_status_created` |
