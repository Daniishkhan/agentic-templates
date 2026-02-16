# Coding Conventions (Reference)

> **Purpose:** Detailed patterns and code examples for this stack. Referenced by `AGENTS.md` — read this file when starting a new module or when unsure about a pattern. Not loaded into agent context by default.

---

## Go module structure

Every domain module in `internal/` follows this layout:

```
internal/{{module}}/
├── handler.go          # HTTP handlers
├── handler_test.go     # HTTP-level tests (httptest recorder)
├── service.go          # Business logic (no HTTP types)
├── service_test.go     # Unit tests (mock DB interface)
└── queries.sql         # Raw SQL for sqlc
```

### Handler pattern

```go
// internal/{{module}}/handler.go
type Handler struct {
    service *Service
}

func (h *Handler) RegisterRoutes(r chi.Router) {
    r.Post("/api/{{resource}}", h.Create)
    r.Get("/api/{{resource}}", h.List)
    r.Get("/api/{{resource}}/{id}", h.Get)
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
    // 1. Parse + validate request body
    // 2. Call h.service method
    // 3. Return response using httputil helpers
}
```

**Rules:**
- Handlers parse, delegate, respond. No business logic.
- Always validate request bodies before calling the service.
- Always use `pkg/httputil` for responses — never `w.WriteHeader()` + `json.NewEncoder()`.

### Service pattern

```go
// internal/{{module}}/service.go
type Service struct {
    db    *store.Queries   // sqlc-generated
    cache *redis.Client    // if needed
}

// Methods contain business rules, validation, orchestration.
// No HTTP concerns (no http.Request, no http.ResponseWriter).
// Returns domain types and errors — handlers translate to HTTP.
```

**Rules:**
- Accept sqlc `Queries` interface (enables testing with mocks).
- Never import `net/http`.
- Return domain types and errors — handlers translate to HTTP status codes.

### Query pattern (sqlc)

```sql
-- name: GetByID :one
SELECT * FROM {{table}} WHERE id = $1;

-- name: List :many
SELECT * FROM {{table}} WHERE deleted_at IS NULL
ORDER BY created_at DESC LIMIT $1 OFFSET $2;

-- name: Create :one
INSERT INTO {{table}} (id, name, created_at)
VALUES ($1, $2, NOW())
RETURNING *;
```

**Rules:**
- One `queries.sql` per module.
- sqlc generates into `internal/store/` (configured in `sqlc.yaml`).
- Complex joins are fine — sqlc handles them.
- Every new query pattern needs a supporting index.

### Response helpers

```go
httputil.JSON(w, http.StatusOK, data)                    // { "data": ... }
httputil.PagedJSON(w, items, page, pageSize, total)      // { "data": [...], "meta": {...} }
httputil.Error(w, http.StatusNotFound, "NOT_FOUND", "Resource not found")
httputil.ValidationError(w, validationErrors)
```

### Test patterns

Handler tests:
```go
func TestCreateOrder(t *testing.T) {
    tests := []struct {
        name       string
        body       string
        wantStatus int
        wantCode   string
    }{
        {"happy path", `{"name":"test"}`, 201, ""},
        {"missing name", `{}`, 422, "VALIDATION_ERROR"},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            req := httptest.NewRequest("POST", "/api/orders", strings.NewReader(tt.body))
            rec := httptest.NewRecorder()
            handler.Create(rec, req)
            assert.Equal(t, tt.wantStatus, rec.Code)
        })
    }
}
```

Table-driven tests preferred. Co-locate tests with code.

---

## TypeScript frontend structure

```
web/src/features/{{module}}/
├── {{Module}}Page.tsx       # Route-level page component
├── {{Module}}List.tsx       # List view component
├── {{Module}}Detail.tsx     # Detail view component
├── {{Module}}Form.tsx       # Create/edit form
├── use{{Module}}.ts         # TanStack Query hooks
└── components/              # Feature-specific sub-components (optional)
```

### API type imports

```typescript
import type { paths } from '@/lib/api/schema';

type CreateRequest = paths['/api/orders']['post']['requestBody']['content']['application/json'];
type CreateResponse = paths['/api/orders']['post']['responses']['201']['content']['application/json'];
```

Never hand-write API types. Always import from generated schema.

### Data fetching

```typescript
// use{{Module}}.ts
import { useQuery, useMutation } from '@tanstack/react-query';

export function useOrders(page: number) {
    return useQuery({
        queryKey: ['orders', page],
        queryFn: () => api.get(`/api/orders?page=${page}&page_size=20`),
    });
}

export function useCreateOrder() {
    return useMutation({
        mutationFn: (data: CreateRequest) => api.post('/api/orders', data),
    });
}
```

### Component rules
- Forms: React Hook Form + Zod validation
- UI primitives: shadcn/ui from `ui/src/components/`
- Styling: `cn()` for conditional Tailwind classes
- Every view handles: empty state, loading state, error state

---

## File naming

| Context | Convention | Example |
|---------|-----------|---------|
| Go files | lowercase, underscores | `handler.go`, `handler_test.go` |
| Go packages | short, lowercase, no underscores | `orders`, `httputil` |
| React components | PascalCase | `OrderDetail.tsx` |
| React hooks | camelCase, `use` prefix | `useOrders.ts` |
| TS utils | camelCase | `formatTimestamp.ts` |
| Migrations | sequential numbered pairs | `000001_initial.up.sql` |
| Tests | co-located | `handler_test.go`, `OrderDetail.test.tsx` |

---

## API response shapes

### Success (single resource)
```json
{
    "data": {
        "id": "uuid",
        "name": "Example",
        "created_at": "2025-01-01T00:00:00Z"
    }
}
```

### Success (list with pagination)
```json
{
    "data": [{ ... }, { ... }],
    "meta": {
        "page": 1,
        "page_size": 20,
        "total": 143
    }
}
```

### Error
```json
{
    "error": {
        "code": "RESOURCE_NOT_FOUND",
        "message": "Order with ID abc-123 does not exist",
        "details": {}
    }
}
```

**Error code rules:**
- `code` is a machine-readable constant string (not an HTTP status number)
- `message` is human-readable
- `details` is optional (validation errors, extra context)
- All error codes must be registered in `pkg/errors/codes.go`
- Never invent a code in a handler without registering it

---

## Code review checklist

Reviewers check every PR against:

- [ ] Does this break an existing user journey?
- [ ] Are access control / authorization boundaries preserved?
- [ ] Are list endpoints paginated and filtered?
- [ ] Are the right tests added per `AGENTS.md` validation strategy?
- [ ] Is `api.yaml` updated for new/changed endpoints?
- [ ] Are generated files regenerated and committed (not hand-edited)?
- [ ] Do error responses follow response shape conventions?
- [ ] For UI: empty states, loading states, error states handled?
- [ ] Is `progress.md` updated?
- [ ] Are new env vars added to `.env.example`?
- [ ] Destructive schema changes using two-step migration?
- [ ] `make validate` passes?

---

## Environment rules

- `.env.example` documents every variable. No secrets committed.
- Env vars validated at startup — missing required var = immediate clear error.
- When adding a new var: add to `.env.example`, add to startup validation, document in PR.
- Same variable names across local/staging/production.

## Dependency rules

- Check `go.mod` / `package.json` before adding — it may exist already.
- Prefer Go stdlib when possible.
- Check bundle size impact for TS packages.
- Update deps in dedicated `chore/` PRs, not mixed with features.
