---
name: web-feature
description: >
  Build a frontend feature in web/src/features/. Use when asked to create
  a page, form, list view, detail view, or any frontend UI work.
metadata:
  short-description: Build typed frontend features in React
---

# Frontend Feature

> Full code patterns with examples: `docs/conventions.md` (TypeScript section).

## Feature layout

```
web/src/features/<module>/
├── <Module>Page.tsx        # Route-level page
├── <Module>List.tsx        # List/table with pagination
├── <Module>Detail.tsx      # Single resource view
├── <Module>Form.tsx        # Create/edit form (React Hook Form + Zod)
├── use<Module>.ts          # TanStack Query hooks (all data fetching)
└── components/             # Feature-specific sub-components (optional)
```

Not every feature needs every file. Simple features: `Page.tsx` + `use<Module>.ts`.

## Procedure

1. Verify types exist in `web/src/lib/api/schema.d.ts`. If not → update `api.yaml` first → `make generate-types`.

2. Write data hooks in `use<Module>.ts`:
   - `useQuery` for reads, `useMutation` for writes
   - Structured query keys: `['resources', { page, status }]`
   - Invalidate queries on mutation success

3. Build page components using generated types + shadcn/ui from `ui/`.

4. Handle **all three states** in every data-fetching view:
   - **Loading** — skeleton or spinner
   - **Error** — message + retry button
   - **Empty** — message + CTA

5. Forms: React Hook Form + Zod schema validation.

6. Pagination on every list view.

## Rules

- **NEVER** hand-write API types. Import from `schema.d.ts`.
- **ALL** data fetching through TanStack Query hooks. No raw `fetch`.
- **ALL** views handle loading, error, and empty states.
- No `any` types. TypeScript strict mode is on.
- shadcn/ui for primitives — extend via composition, never modify internals.
