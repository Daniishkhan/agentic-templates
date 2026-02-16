---
name: api-contract
description: >
  Define or update API contracts in api.yaml and sync generated TypeScript types.
  Use when adding/changing endpoints, request or response shapes, pagination,
  auth requirements, or error responses.
metadata:
  short-description: Spec-first OpenAPI + TS type sync
---

# API Contract

Contract-first workflow for this repo.

## Canonical files

- `api.yaml` (source of truth)
- `web/src/lib/api/schema.d.ts` (generated)

## Procedure

1. Read `progress.md`, the relevant story in `docs/epic.md`, and existing endpoint patterns in `api.yaml`.
2. Update `api.yaml` first:
   - Path + method + `operationId`
   - Request schema
   - Response schema with required envelope
   - Auth/security definition
3. Keep response envelopes consistent:
   - Single: `{ "data": { ... } }`
   - List: `{ "data": [...], "meta": { "page", "page_size", "total" } }`
   - Error: `{ "error": { "code", "message", "details" } }`
4. For list endpoints, include pagination params (`page`, `page_size`) and bounded behavior.
5. If adding a new error code, register it in `pkg/errors/codes.go`.
6. Run `.agents/skills/api-contract/scripts/sync-types.sh`.
7. Verify generated type usage compiles in `web/`.
8. Update `progress.md` with contract changes.

## Rules

- Never implement a changed endpoint before updating `api.yaml`.
- Never hand-edit `web/src/lib/api/schema.d.ts`.
- Keep contract names stable (`operationId`, schema keys) unless a breaking change is intentional.
