---
id: EPIC-BACKLOG
type: epic-backlog
schema_version: 2
status: active
owner: "[Tech Lead]"
last_updated: "YYYY-MM-DD"
sources:
  onepager: docs/onepager.md
  prd: docs/prd.md
  ddd: docs/ddd.md
---

# Feature Backlog (Epic): [Project Name]

> Purpose: the single execution backlog source of truth.
> This file is **what we build** (stories + acceptance criteria + contract intent), not deep implementation detail.
>
> References:
> - Product intent: `docs/onepager.md`, `docs/prd.md`
> - Domain language: `docs/ddd.md`
> - Engineering patterns: `docs/conventions.md`
> Execution log: `progress.md`

## How to use this file

- Update the **Story Index** first for status/ownership/dependencies.
- Each story section must be outcome-focused with testable acceptance criteria.
- If you add engineering notes, keep them implementation-agnostic (no file-path micromanagement). Patterns live in `docs/conventions.md`.

## Status model

- `backlog` → `ready` → `in-progress` → `done`
- `blocked` may be used from `ready` or `in-progress`

### Definition of Ready (story-level)

A story can move to `ready` when:
- Acceptance criteria are specific and testable
- Dependencies are set
- It references relevant PRD requirements (`FR-*` / `NFR-*`) and DDD concepts (module/aggregate)
- API/UX intent is clear enough to implement without guessing

### Definition of Done (story-level)

A story is `done` when:
- Acceptance criteria are met
- Key errors/edge cases are handled
- Changes are validated (lint/test/validate as appropriate)
- `progress.md` is updated via workflow tooling

## Story Index (machine-readable, update first)

<!-- STORY_INDEX_START -->
```yaml
stories:
  - id: US-000
    title: Foundation — local dev environment works end-to-end
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: []

  - id: US-001
    title: Foundation — database workflow + schema baseline
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: [US-000]

  - id: US-002
    title: Foundation — CI pipeline gates main
    epic: EPIC-00
    status: backlog
    owner: unassigned
    depends_on: [US-000]
```
<!-- STORY_INDEX_END -->

## Issue naming

| Type | Format | Example |
|---|---|---|
| Epic | `EPIC-XX Name` | `EPIC-01 Billing` |
| Story | `US-XXX Outcome-focused title` | `US-010 Create an Order` |
| Task (optional) | `TSK-XXXX Step` | `TSK-0101 Add validation errors` |

## Labels (optional)

- Phase: `mvp`, `phase2`, `future`
- Layer: `backend`, `frontend`, `infra`, `qa`
- Concern: project-specific (`auth`, `analytics`, `realtime`, etc.)

## Story template (copy for new stories)

~~~markdown
## US-XXX Story title (outcome-focused)

**Story Meta**
```yaml
id: US-XXX
status: backlog
priority: medium
owner: unassigned
depends_on: []
module: "[module-name]"           # from docs/ddd.md (Domain Module)
aggregate: "[AggregateName]"      # from docs/ddd.md (if applicable)
reqs: ["FR-1", "NFR-2"]           # from docs/prd.md
phase: mvp
risk: low                         # low | medium | high (drives validation)
```

**Persona:** Who benefits
**Outcome:** One sentence describing what becomes possible.

**Acceptance Criteria**
- [ ] Specific observable behavior #1
- [ ] Specific observable behavior #2
- [ ] Error/edge case behavior

**Contract intent (optional, but recommended)**
- Primary UI surface: [...]
- Primary API intent: `METHOD /api/resource` (if applicable)
- Key request fields: [...]
- Key response fields: [...]
- Expected error cases: [...]

**Analytics (if applicable)**
- Event(s): [...]

**Notes / Open questions**
- [...]

**Engineering checklist (optional)**
- [ ] Data changes needed? (yes/no)
- [ ] Contract changes needed? (yes/no)
- [ ] UI changes needed? (yes/no)
- [ ] Tests needed? (unit/handler/integration/e2e)
~~~

---

# EPIC-00 Foundation (required for any MVP)

> Goal: a contributor can run, test, and ship safely.

## US-000 Foundation — local dev environment works end-to-end

**Story Meta**
```yaml
id: US-000
status: backlog
priority: high
owner: unassigned
depends_on: []
module: foundation
aggregate: "-"
reqs: []
phase: mvp
risk: medium
```

**Persona:** Developer (human or agent)
**Outcome:** Any contributor can run the full stack locally with predictable commands.

**Acceptance Criteria**
- [ ] Local infra starts cleanly (DB + cache + any required services)
- [ ] The API server starts locally without manual surgery
- [ ] The web app starts locally and can call the API
- [ ] A health check exists and returns “ok”
- [ ] A new contributor can follow README steps successfully

**Contract intent (optional)**
- Health endpoint exists (e.g., `GET /api/health`) returning an “ok” payload

**Engineering checklist (optional)**
- [ ] Standard make targets exist for local run + lint + test + validate
- [ ] `.env.example` documents required environment variables

## US-001 Foundation — database workflow + schema baseline

**Story Meta**
```yaml
id: US-001
status: backlog
priority: high
owner: unassigned
depends_on: [US-000]
module: foundation
aggregate: "-"
reqs: []
phase: mvp
risk: high
```

**Persona:** Developer
**Outcome:** DB changes are repeatable and safe (migrations, schema snapshot, typed queries).

**Acceptance Criteria**
- [ ] A fresh DB can be created and migrated from zero reliably
- [ ] There is an initial schema baseline for the MVP
- [ ] Rollback strategy exists (at least for development)
- [ ] Seed data (if needed) is deterministic

## US-002 Foundation — CI pipeline gates main

**Story Meta**
```yaml
id: US-002
status: backlog
priority: medium
owner: unassigned
depends_on: [US-000]
module: foundation
aggregate: "-"
reqs: ["NFR-3"]
phase: mvp
risk: medium
```

**Persona:** Developer
**Outcome:** PRs are gated by automated checks before merge.

**Acceptance Criteria**
- [ ] CI runs on every PR to main
- [ ] Lint + tests + validation run in CI
- [ ] Integration tests can run with required services
- [ ] Merge is blocked when CI fails

---

# EPIC-01 [Domain Module Name] (MVP)

> Why: [one sentence describing why this module exists.]

## US-0XX [Story title]

**Story Meta**
```yaml
id: US-0XX
status: backlog
priority: medium
owner: unassigned
depends_on: []
module: "[module-name]"
aggregate: "[AggregateName]"
reqs: ["FR-1"]
phase: mvp
risk: low
```

**Persona:** [Role]
**Outcome:** [What becomes possible]

**Acceptance Criteria**
- [ ] [Specific testable behavior]
- [ ] [Error case]
- [ ] [Access/control case]

**Contract intent**
- Primary UI surface: [...]
- Primary API intent: [...]
- Expected error cases: [...]

**Analytics**
- Event(s): [...]

**Notes / Open questions**
- [...]

**Engineering checklist (optional)**
- [ ] Data changes needed? (yes/no)
- [ ] Contract changes needed? (yes/no)
- [ ] UI changes needed? (yes/no)
- [ ] Tests needed? (unit/handler/integration/e2e)
