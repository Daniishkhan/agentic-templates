---
name: web-feature
description: >
  Build frontend features in web/src/features using generated API types.
  Use when creating pages, lists, details, forms, hooks, and client state
  with React, TanStack Query, shadcn/ui, and Zustand.
metadata:
  short-description: Build typed React UI features fast
---

# Web Feature

Ship UI features with typed contracts and reliable states.
For high-end visual exploration or redesign quality, pair this with `$frontend-design`.

## Core stack

- Generated API types from `web/src/lib/api/schema.d.ts`
- TanStack Query for server state
- Zustand for local UI state
- shadcn/ui components + Tailwind
- React Hook Form + Zod for forms

## Procedure

1. Confirm endpoint types exist in generated schema (`make generate-types` if needed).
2. Create feature folder under `web/src/features/<module>/`.
3. Implement `use<Module>.ts` hooks first:
   - `useQuery` for reads
   - `useMutation` for writes
   - clear query keys + invalidation
4. Build components with explicit states:
   - loading
   - empty
   - error
   - success
5. Add forms with RHF + Zod.
6. Use shadcn/ui primitives; compose, do not fork internals.
7. Add/adjust tests for non-trivial components.
8. Run `cd web && pnpm typecheck && pnpm test && pnpm lint`.

## Rules

- Never hand-write API request/response types.
- Avoid `any`; keep strict TypeScript.
- Keep data fetching in hooks, not directly in page components.
- Keep list views paginated and filterable.
