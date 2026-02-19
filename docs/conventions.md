# Coding Conventions (Reference)

> Purpose: detailed engineering patterns and examples for this stack.
> This file is intentionally “technical”. Product/domain planning lives in:
> - `docs/onepager.md`
> - `docs/prd.md`
> - `docs/ddd.md`
> - `docs/epic.md`

## DDD alignment (read first)

- Names in `docs/ddd.md` (Domain Modules, Aggregates, statuses) are the **source of truth** for naming in:
  - API resource names
  - UI copy and feature folder names
  - service/module naming in backend code
- Prefer one **Domain Module** per major product area in MVPs. If it grows, you can subdivide internally, but keep the module boundary clear.

---

## Go domain module structure

For MVPs, most work happens in a single domain module folder under `internal/`:

```
internal/{{module}}/
├── handler.go          # HTTP handlers (parse/validate/delegate/respond)
├── handler_test.go     # HTTP-level tests (httptest recorder)
├── service.go          # Business rules & orchestration (no HTTP types)
├── service_test.go     # Unit tests (mock DB/cache/interfaces)
└── queries.sql         # Raw SQL for sqlc (if using sqlc)
```

> If a module becomes large later, you may introduce subpackages, but keep “handlers thin” and preserve the service boundary.

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
    // 1) Parse + validate request
    // 2) Call service method
    // 3) Translate response/error to HTTP via httputil
}
```

**Rules:**
- Handlers parse, delegate, respond. **No business logic.**
- Validate request bodies before calling the service.
- Use `pkg/httputil` helpers for all responses.

### Service pattern

```go
// internal/{{module}}/service.go
type Service struct {
    db    *store.Queries   // sqlc-generated
    cache *redis.Client    // optional
}

// Methods contain business rules, validation, orchestration.
// No HTTP concerns (no http.Request/ResponseWriter).
// Return domain types + errors; handlers translate to HTTP status codes.
```

**Rules:**
- Never import `net/http` in service code.
- Enforce DDD invariants here (state machines, permissions checks, etc.).
- Prefer explicit method names that match use cases (UC-* from DDD).

### Query pattern (sqlc)

```sql
-- name: GetByID :one
SELECT * FROM {{table}} WHERE id = $1;

-- name: List :many
SELECT * FROM {{table}}
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: Create :one
INSERT INTO {{table}} (id, name, created_at)
VALUES ($1, $2, NOW())
RETURNING *;
```

**Rules:**
- One `queries.sql` per module (or per submodule, if large).
- Every list endpoint must be bounded and paginated.
- New query patterns should consider indexing needs.

---

## API conventions

### Path naming

- Use plural nouns: `/api/orders`, `/api/workspaces`
- Do **not** force the domain module into the URL for MVPs unless you truly have collisions.
- Keep query params consistent:
  - `page`
  - `page_size`

### Response shapes

**Success (single resource)**
```json
{
  "data": {
    "id": "uuid",
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

**Success (list + pagination)**
```json
{
  "data": [{}, {}],
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 143
  }
}
```

**Error**
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Order does not exist",
    "details": {}
  }
}
```

**Error code rules:**
- `code` is a stable, machine-readable constant (e.g., `RESOURCE_NOT_FOUND`)
- `message` is human-readable
- `details` is optional (validation errors, extra context)
- Register codes centrally (don’t invent new codes ad-hoc)

### Response helpers (example usage)

```go
httputil.JSON(w, http.StatusOK, data)
httputil.PagedJSON(w, items, page, pageSize, total)
httputil.Error(w, http.StatusNotFound, "RESOURCE_NOT_FOUND", "Resource not found")
httputil.ValidationError(w, validationErrors)
```

---

## Tests

### Handler tests (HTTP-level)

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

**Rules:**
- Table-driven tests preferred.
- Co-locate tests with code.
- Add integration tests when DB-dependent behavior changes.

---

## TypeScript frontend structure

```
web/src/features/{{module}}/
├── {{Module}}Page.tsx
├── {{Module}}List.tsx
├── {{Module}}Detail.tsx
├── {{Module}}Form.tsx
├── use{{Module}}.ts
└── components/
```

### API type imports

```typescript
import type { paths } from '@/lib/api/schema';

type CreateRequest =
  paths['/api/orders']['post']['requestBody']['content']['application/json'];

type CreateResponse =
  paths['/api/orders']['post']['responses']['201']['content']['application/json'];
```

**Rule:** never hand-write API types; import from generated schema.

### Data fetching (TanStack Query)

```typescript
export function useOrders(page: number) {
  return useQuery({
    queryKey: ['orders', page],
    queryFn: () => api.get(`/api/orders?page=${page}&page_size=20`),
  });
}
```

**UI rules:**
- Every view handles loading, error, and empty states.
- Forms: React Hook Form + Zod validation.
- UI primitives: shadcn/ui.
- Use `cn()` for conditional Tailwind classes.

---

## Code review checklist

- [ ] Does naming match the DDD glossary (no synonyms)?
- [ ] Are acceptance criteria covered by tests where practical?
- [ ] Are list endpoints paginated and bounded?
- [ ] Is `api.yaml` updated for new/changed endpoints?
- [ ] Are generated files regenerated and committed (not hand-edited)?
- [ ] Do errors follow the standard error shape and codes?
- [ ] UI: loading/empty/error states handled?
- [ ] `progress.md` updated via workflow tooling?
- [ ] New env vars added to `.env.example` + validated at startup?

---

## Environment rules

- `.env.example` documents every variable. No secrets committed.
- Missing required env var → clear startup error.
- Same variable names across local/staging/production.

## Dependency rules

- Prefer stdlib where possible (Go).
- Check `go.mod` / `package.json` before adding new deps.
- Update dependencies in dedicated `chore/` PRs.
