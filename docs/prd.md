---
id: DOC-PRD
type: prd
schema_version: 1
project_name: "[Project Name]"
status: draft # draft | in_review | approved
owner: "[PM/Founder]"
last_updated: "YYYY-MM-DD"
source_onepager: "docs/onepager.md"
next_step: "After approval: complete docs/ddd.md, then translate into docs/epic.md"
---

# PRD: [Project Name]

> Purpose: the full product spec (“what and for whom”), not implementation.
> This should be stable enough that engineering can translate it into stories.

## 1) Overview

**What we’re building (1–2 sentences):**
- [...]

**Who it’s for:**
- Primary users: [...]
- Secondary users: [...]

**Desired outcome:**
- User outcome: [...]
- Business outcome: [...]

### Goals
1. [...]
2. [...]
3. [...]

### Non-goals (explicitly not solving now)
- [...]
- [...]

### Success metrics

| Metric | Definition | Target |
|---|---|---:|
| [...] | [...] | [...] |
| [...] | [...] | [...] |

## 2) Glossary (top terms)

> Keep this short here. The authoritative glossary lives in `docs/ddd.md` (Ubiquitous Language).
| Term | Meaning in this product |
|---|---|
| [...] | [...] |
| [...] | [...] |

## 3) Users & problems

### Personas

**Persona A: [Role/name]**
- Primary goal: [...]
- Pain points: [...]
- Environment constraints (mobile-only, time pressure, compliance): [...]

**Persona B (optional): [Role/name]**
- Primary goal: [...]
- Pain points: [...]

### Key user needs (ranked)
1. [...]
2. [...]
3. [...]

## 4) User journeys

### Journey J1 — Primary flow (happy path)
1. [Step → user-visible result]
2. [Step → user-visible result]
3. [Step → user-visible result]

**User outcome:** [...]
**Business outcome:** [...]

### Journey J2 — Common exception / edge case
1. [...]
2. [...]

**Desired handling:** [...]

### Journey J3 — Admin / setup (if relevant)
1. [...]
2. [...]

## 5) Requirements

> Use stable IDs so we can trace PRD → stories in `docs/epic.md`.

### Functional requirements (FR)

| ID | Requirement (observable behavior) | Priority | Notes |
|---|---|---|---|
| FR-1 | [Users can …] | must | |
| FR-2 | [System will …] | must | |
| FR-3 | [When X happens, Y occurs …] | should | |
| FR-4 | [...] | could | |

### Roles & permissions (if relevant)

| Capability | Role A | Role B | Role C |
|---|---:|---:|---:|
| [Do thing] | ✅/❌ | ✅/❌ | ✅/❌ |
| [Do admin thing] | ✅/❌ | ✅/❌ | ✅/❌ |

### Non-functional requirements (NFR)

| ID | Requirement | Target / constraint | Notes |
|---|---|---|---|
| NFR-1 | Security: [authn/authz expectation] | [e.g., role-based] | |
| NFR-2 | Privacy: [data handling expectation] | [e.g., PII minimized] | |
| NFR-3 | Reliability: [availability] | [e.g., best effort MVP] | |
| NFR-4 | Performance: [latency] | [e.g., p95 < 300ms for reads] | |
| NFR-5 | Accessibility: [standard] | [e.g., WCAG 2.1 AA] | |

## 6) UX, content, and accessibility

- Information architecture: [...]
- Key screens/pages: [...]
- Empty states required: [...]
- Error states required: [...]
- Accessibility requirements: [...]

## 7) Data & integrations (conceptual)

> This is not a DB schema. It’s what data exists and where it comes from.

### Data we create/store
- [Record type] — purpose, retention expectation
- [Record type] — purpose, retention expectation

### Data we read from other systems (if any)
- [System] — [data], [sync mode], [owner]

### Data lifecycle requirements
- Export: [yes/no, format]
- Deletion: [who can delete, what happens]
- Audit/history: [what actions must be auditable]

## 8) Analytics & measurement

### Event naming convention
- Use `snake_case` event names and property keys.
- Each event includes: `actor_id` (if known), `source` (screen), `timestamp`.

### Event dictionary

| Event | When it fires | Properties | Success signal |
|---|---|---|---|
| `[...]` | [...] | [...] | [...] |
| `[...]` | [...] | [...] | [...] |

### Key funnels
- Funnel F1: [...]
- Funnel F2: [...]

## 9) Rollout, training, and support

- Target launch group: [...]
- Rollout plan: [...]
- Training required: [...]
- Support & escalation: [...]

## 10) Risks, assumptions, dependencies

### Risks

| Risk | Impact | Mitigation |
|---|---|---|
| [...] | [...] | [...] |
| [...] | [...] | [...] |

### Assumptions
- [...]
- [...]

### Dependencies
- [...]
- [...]

## 11) Open questions

- [Question]
- [Question]

## 12) Definition of Done (product-level)

- [ ] MVP journeys work end-to-end (J1 + key edge case)
- [ ] Must-have FRs delivered (FR “must” rows)
- [ ] Instrumentation plan implemented or explicitly deferred with owner/date
- [ ] Stakeholders sign off on MVP scope
