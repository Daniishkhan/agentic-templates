---
name: new-endpoint
description: >
  Create a new API endpoint using spec-first development. Use when asked to
  add an endpoint, API route, REST resource, or POST/GET/PUT/DELETE handler.
metadata:
  short-description: Add spec-first API endpoints safely
---

# New API Endpoint (Spec-First)

> Go patterns: `docs/conventions.md`. Response shapes: `agents.md` §7.

## Procedure

1. **Define contract in `api.yaml` BEFORE any Go code:**

```yaml
/api/<resources>:
  post:
    summary: Short description
    operationId: create<Resource>
    tags: [<resources>]
    security:
      - bearerAuth: []
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required: [field_name]
            properties:
              field_name:
                type: string
    responses:
      "201":
        description: Created
        content:
          application/json:
            schema:
              type: object
              properties:
                data:
                  $ref: "#/components/schemas/<Resource>"
      "401": { description: Not authenticated }
      "422": { description: Validation error }
```

2. **Generate types** — `make generate-types`. Verify `schema.d.ts` has the new types.

3. **Queries** (if new data) — Write in `queries.sql` → `make generate-sqlc`.

4. **Service** — Business logic in `service.go`. No `net/http`. See `docs/conventions.md` for pattern.

5. **Handler** — Wire HTTP in `handler.go`. Parse → validate → service → `pkg/httputil` response. See `docs/conventions.md` for pattern.

6. **Register route** in `RegisterRoutes`.

7. **Handler tests** — Cover every response code from the contract:

| Case | Status |
|------|--------|
| Valid input | 201 |
| Missing required field | 422 `VALIDATION_ERROR` |
| Invalid JSON | 400 `INVALID_JSON` |
| No auth token | 401 `UNAUTHENTICATED` |
| Wrong role | 403 `FORBIDDEN` |
| Not found (GET/PUT/DELETE) | 404 `NOT_FOUND` |
| Duplicate (if applicable) | 409 `CONFLICT` |

8. **Validate** — `make validate`.

## Rules

- Contract in `api.yaml` BEFORE Go code — non-negotiable
- All responses via `pkg/httputil` helpers
- Error codes registered in `pkg/errors/codes.go`
- List endpoints paginated
