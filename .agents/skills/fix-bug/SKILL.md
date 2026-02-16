---
name: fix-bug
description: >
  Diagnose and fix regressions across contract, backend, database, or frontend.
  Use when tests fail, behavior diverges from spec, or users report unexpected
  errors.
metadata:
  short-description: Reproduce, fix, and verify regressions
---

# Fix Bug

Apply focused fixes with regression protection.

## Procedure

1. Reproduce the issue from error report, test output, or repro steps.
2. Add a failing test first (handler/service/frontend as appropriate).
3. Implement minimal fix (no bundled refactors).
4. If fix touches contract or schema, follow `$api-contract` / `$db-migration` workflows.
5. Run targeted tests, then `make test`, `make lint`, `make validate`.
6. Update `progress.md` with root cause and fix summary.

## Rules

- One bug, one fix scope.
- Keep changes surgical.
- Ship with regression coverage.
