---
name: fix-bug
description: >
  Fix a bug. Use when the user reports a bug, error message, failing test,
  unexpected behavior, or regression.
metadata:
  short-description: Reproduce and fix regressions safely
---

# Bug Fix Protocol

## Procedure

1. **Understand** — Read the error/test/repro steps. Check `progress.md` for known deviations or debt in this area.

2. **Read** — Handler + service + queries for the affected module. `api.yaml` for expected contract. `schema.sql` if data-related. Existing tests for coverage gaps.

3. **Write failing test FIRST** — Reproduce the bug in a test. Confirm it fails. This becomes the regression test.
   - Handler bug → case in `handler_test.go`
   - Service bug → case in `service_test.go`
   - Frontend bug → case in `Component.test.tsx` or Playwright

4. **Fix** — Minimal change only. No bundled refactoring. No renames. No cleanup.
   - If fix requires API contract change → update `api.yaml` first
   - If fix requires schema change → new migration (never edit existing)

5. **Verify** — Regression test passes. `make test` (no other breakage). `make lint`. `make validate`.

6. **Track** — If caused by a spec deviation, document in `progress.md`. If fix is a workaround, log in "Known debt".

## Rules

- Always write the failing test before the fix
- Minimal changes — don't bundle refactoring with bug fixes
- One bug, one fix, one PR
