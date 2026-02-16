---
name: project-code-reviewer
description: >
  Expert code review for this Go + TypeScript template repository. Use when
  asked to review a PR, branch, commit, or local diff for bugs, regressions,
  security risks, schema/API drift, generated-file mistakes, and missing tests
  against AGENTS.md and docs/conventions.md rules.
metadata:
  short-description: Find regressions and contract drift
---

# Project Code Review Protocol

Review changes with a findings-first mindset. Prioritize defects, regressions,
security, and contract/data integrity over style.

## Review Workflow

1. Identify the review scope.
   - Use `git status --short`, `git diff --name-only`, `git diff --stat`, and scoped `git diff`.
   - Group files by risk: contract, migration/data, backend logic, frontend behavior, shared utilities.

2. Load project rules before judging changes.
   - Read `AGENTS.md`.
   - Read `docs/conventions.md`.
   - Read `progress.md` if present. If missing, record as a process gap.

3. Validate contract and generated artifacts.
   - Require `api.yaml` updates for added/changed endpoints.
   - Require `web/src/lib/api/schema.d.ts` regen after `api.yaml` changes.
   - Require migration + `schema.sql` + sqlc output updates for schema/query changes.
   - Flag any hand edits in generated files:
     - `schema.sql`
     - `web/src/lib/api/schema.d.ts`
     - `internal/store/*.go`

4. Check data and query safety.
   - Require pagination on list endpoints (`page`, `page_size`; bounded queries).
   - Flag N+1 queries, missing limits, or absent indexes for new query patterns.
   - Require two-step approach for destructive schema changes.
   - Verify up/down migration safety for state transitions and rollbacks.

5. Check architecture boundaries.
   - Keep handlers thin: parse/validate/delegate/respond only.
   - Keep business logic in `service.go`; no `net/http` in services.
   - Use `pkg/httputil` response helpers; avoid manual response writing.
   - Keep `web/` isolated from Go internals and direct DB access.

6. Check API behavior and errors.
   - Enforce response shapes:
     - Success: `{ "data": ... }`
     - List: `{ "data": [...], "meta": {...} }`
     - Error: `{ "error": { "code", "message", "details" } }`
   - Require error codes to be registered in `pkg/errors/codes.go`.
   - Verify auth/access-control behavior is preserved.

7. Check test coverage and verification.
   - For new endpoint changes, expect handler happy path + error cases.
   - For business logic changes, expect service tests.
   - For bug fixes, expect a regression test.
   - For UI changes, require loading/empty/error states.
   - If available, run targeted checks first, then broader checks (`make test`, `make lint`, `make validate`) when risk is high.

## Severity Model

- `Critical`: Data loss/corruption, auth bypass, major outage risk, broken core journey.
- `High`: Behavioral bug, schema/contract drift, missing required validation, high-probability regression.
- `Medium`: Reliability/performance/test gap that can ship only with explicit risk acceptance.
- `Low`: Maintainability/readability issue with low immediate impact.

## Output Format

Report findings first, ordered by severity.

For each finding, include:
1. Severity
2. Title
3. File reference (`path:line`)
4. Why it matters
5. Suggested fix

After findings, include:
1. Open questions or assumptions
2. Brief change summary
3. Residual risk/testing gaps

If no findings exist, state that explicitly and still include residual risks or missing verification.

## Project-Specific Red Flags

- Endpoint behavior changed without `api.yaml` updates.
- Generated artifacts changed inconsistently or appear hand-edited.
- New list API without pagination bounds.
- Service layer importing HTTP concerns.
- Use of `interface{}` in Go or `any` in TypeScript without clear justification.
- Missing error/loading/empty states in UI flows.
- Missing `progress.md` updates for completed stories or deviations (`DEV-XXX`).
