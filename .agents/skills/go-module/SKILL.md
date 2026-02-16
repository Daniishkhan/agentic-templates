---
name: go-module
description: >
  Create or modify a Go module in internal/. Use when asked to create a
  backend module, add a handler, write a service, or implement Go business logic.
metadata:
  short-description: Create or update backend Go modules
---

# Go Module

> Full code patterns with examples: `docs/conventions.md` (Go module section).

## Module layout (every module, no exceptions)

```
internal/<module>/
├── handler.go          # Parse → validate → call service → respond
├── handler_test.go     # HTTP-level tests (status + body assertions)
├── service.go          # Business logic (no net/http imports)
├── service_test.go     # Logic tests (mock DB interface)
└── queries.sql         # SQL for sqlc → generates into internal/store/
```

## Procedure

1. Check if the module already exists (`internal/<module>/`). Don't create duplicates.
2. Write `queries.sql` → `make generate-sqlc`.
3. Write `service.go` — business logic. Accept `store.Querier` interface. No HTTP types. Return domain types + errors.
4. Write `handler.go` — HTTP wiring. Use `pkg/httputil` for ALL responses. Follow parse → validate → service → respond flow.
5. Register routes in `RegisterRoutes(r chi.Router)`.
6. Write `handler_test.go` — happy path + every error case. Table-driven when 3+ cases.
7. Write `service_test.go` — edge cases, mock the Querier.

## Rules

- Handlers: **zero** business logic. Parse, delegate, respond.
- Services: **zero** HTTP types. No `http.Request`, no `http.ResponseWriter`.
- Use `pkg/httputil` — never `w.WriteHeader()` + `json.Encode()`.
- Error codes registered in `pkg/errors/codes.go`.
- Every list endpoint paginated. No exceptions.
- Wrap errors: `fmt.Errorf("create order: %w", err)`.
