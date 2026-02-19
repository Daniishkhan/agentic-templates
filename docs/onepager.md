---
id: DOC-ONEPAGER
type: onepager
schema_version: 1
project_name: "[Project Name]"
status: draft # draft | in_review | approved
owner: "[PM/Founder]"
last_updated: "YYYY-MM-DD"
next_step: "If approved: expand into docs/prd.md"
---

# One-Pager: [Project Name] (MVP)

> Purpose: a single-page decision doc to decide whether to build the MVP.
> If approved, this becomes `docs/prd.md`.

## Decision request

- Decision needed: **Build | Hold | Kill**
- Decision deadline: `YYYY-MM-DD`
- Reviewers: [Names]
- MVP timebox (optional): [e.g., 2–4 weeks]

## 1) The problem

**Current situation (2–4 sentences):**
- [Describe the current workflow/system and where it breaks.]

**Who feels the pain:**
- Primary user: [Role]
- Secondary user: [Role]
- Buyer (if different): [Role/org]

**Impact today (quantify when possible):**
- Time: [e.g., 2 hrs/day/user]
- Errors: [e.g., 5% of cases]
- Revenue/churn/risk: [e.g., lost deals, compliance risk]

## 2) Why now

- [Trigger: market shift, regulation, technology, internal change]
- [Why the status quo is getting worse / more expensive]
- [Why we can win now]

## 3) Proposed solution (MVP)

**In one sentence:** Build **[Product]** so **[User]** can **[Job]** without **[Pain]**.

**How it works (high-level):**
1. [User action → system response]
2. [User action → system response]
3. [User action → system response]

**Guardrails (explicit “we will not” statements):**
- We will not: [out-of-scope behavior that prevents feature creep]
- We will not: [another]

## 4) MVP scope

**Must ship (MVP capabilities):**
- [ ] [Capability 1]
- [ ] [Capability 2]
- [ ] [Capability 3]

**Explicitly out of scope (for MVP):**
- [ ] [Not now 1]
- [ ] [Not now 2]

## 5) Success metrics

| Metric | What it measures | Baseline | Target |
|---|---|---:|---:|
| [Metric 1] | [Definition] | [x] | [y] |
| [Metric 2] | [Definition] | [x] | [y] |
| [Metric 3] | [Definition] | [x] | [y] |

**Qualitative success signal (optional):**
- [“Users say X without prompting”]

## 6) Risks, assumptions, dependencies

**Risks (top 3):**
1. [Risk] → mitigation: [Plan]
2. [Risk] → mitigation: [Plan]
3. [Risk] → mitigation: [Plan]

**Assumptions (what we’re betting on):**
- [Assumption]
- [Assumption]

**Dependencies:**
- [Data source / vendor / internal team / approval]

## 7) MVP demo script (optional but useful)

> A 2–3 minute “what we’ll show on launch day”.

1. [Persona] signs in / lands on [page]
2. They [do primary action]
3. System [shows result]
4. They handle one common edge case: [edge case]
5. Done: [what “complete” looks like]

## 8) Next steps

- [ ] If approved: write `docs/prd.md`
- [ ] After PRD approval: write `docs/ddd.md` (domain model + language)
- [ ] Translate PRD + DDD into `docs/epic.md` (stories + acceptance criteria)
