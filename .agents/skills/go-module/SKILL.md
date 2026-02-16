---
name: go-module
description: >
  Implement or modify backend API modules in Go under internal/. Use when
  building handlers, services, module queries, and tests for contract-defined
  endpoints.
metadata:
  short-description: Build Go handler/service/query modules
---

# Go Module

Build backend modules with clear layer boundaries.

## Module shape

`internal/<module>/handler.go`, `service.go`, `queries.sql`, tests.

## Procedure

1. Confirm endpoint contract exists in `api.yaml`.
2. Update/create `internal/<module>/queries.sql`.
3. Run `make generate-sqlc`.
4. Implement `service.go`:
   - business logic only
   - no `net/http` types
   - wrap errors with context
5. Implement `handler.go`:
   - parse/validate/delegate/respond
   - use `pkg/httputil` response helpers only
6. Register routes in module route wiring.
7. Add tests:
   - handler happy path + error paths
   - service logic + edge cases
8. Run `make test` and `make lint`.

## Rules

- Handlers contain no business logic.
- Services contain no HTTP concerns.
- All list endpoints must be paginated.
- Never hand-edit `internal/store/*.go`.
