---
id: DOC-DDD
type: ddd
schema_version: 1
project_name: "[Project Name]"
status: draft # draft | in_review | approved
owner: "[Tech Lead + Domain Expert]"
last_updated: "YYYY-MM-DD"
source_prd: "docs/prd.md"
next_step: "After approval: translate into docs/epic.md (stories referencing this language)"
---

# Domain Model (DDD): [Project Name]

> Purpose: establish shared language + domain structure that stays consistent across PRD, epic, UI copy, APIs, and code.
> This is *domain-first*. Avoid implementation detail; focus on meaning, rules, and boundaries.

## Working rules

- **No synonyms:** if two words mean the same thing, pick one and delete the other.
- **Names are contracts:** once a term is chosen here, it should be reused everywhere.
- **Start simple:** for an MVP, it’s OK to have a single domain module and no events. Add complexity only when it buys clarity.

## 1) Ubiquitous Language (authoritative glossary)

<!-- DOMAIN_TERMS_START -->
| Term | Definition (plain English) | Example | Not to be confused with |
|---|---|---|---|
| `[Term]` | [definition] | [example] | [confusion] |
| `[Term]` | [definition] | [example] | [confusion] |
| `[Term]` | [definition] | [example] | [confusion] |
<!-- DOMAIN_TERMS_END -->

## 2) Domain Modules (bounded contexts for MVP)

> Use “Domain Module” as the practical MVP unit: a boundary where language and rules are consistent.
> A project may start with 1 module and grow later.

<!-- CONTEXTS_START -->
### Domain Module: [module-name]

```yaml
module: [module-name]          # short, lowercase, no spaces (e.g., billing, workspace, orders)
responsibility: "[one sentence]"
primary_actors: ["Persona A", "Persona B"]
owned_aggregates: ["AggregateA", "AggregateB"]
external_dependencies: ["None" | "SystemX"]
```

**Notes**
- What this module owns (and must stay consistent about): [...]
- What it explicitly does NOT own: [...]
<!-- CONTEXTS_END -->

### Module interactions (optional)

> Only fill this if you truly have multiple modules in the MVP.
| Upstream module | Downstream module | Interaction | Notes |
|---|---|---|---|
| [...] | [...] | API call | [...] |
| [...] | [...] | Event | [...] |

## 3) Aggregates, entities, and invariants

> An aggregate is the unit of consistency. Invariants must always hold when you change the aggregate.

<!-- AGGREGATES_START -->
### Aggregate: [AggregateName]

```yaml
aggregate: [AggregateName]              # PascalCase (e.g., Workspace, Invoice, Order)
module: [module-name]
root_entity: [RootEntityName]
lifecycle: "[state] -> [state] -> [state]"
```

**What it represents (1 sentence):**
- [...]

**Entities inside the aggregate (if any):**
- `[Entity]` — [meaning]

**Value objects (no identity, compared by value):**
- `[ValueObject]` — fields: [...]

**Key fields on the root:**
| Field | Meaning | Required | Notes |
|---|---|---:|---|
| `id` | unique identifier | yes | |
| `[field]` | [...] | yes/no | |
| `status` | lifecycle state | yes | allowed transitions: [...] |

**Invariants (must always be true):**
- [Invariant #1 — testable]
- [Invariant #2 — testable]

**Failure modes / violations:**
- If [violation], the system should: [error message / handling]

---
<!-- AGGREGATES_END -->

## 4) Use-case catalog (commands + queries)

> This is the bridge between PRD journeys and epic stories.
> Commands change state; Queries return information.

| ID | Use case | Type | Primary actor | Primary aggregate | Preconditions | Success outcome | Errors / edge cases |
|---|---|---|---|---|---|---|---|
| UC-1 | [...] | Command | [...] | [...] | [...] | [...] | [...] |
| UC-2 | [...] | Query | [...] | [...] | [...] | [...] | [...] |

## 5) Domain events (optional)

> Use events when something “happened” that other parts of the system care about.
> For MVPs, you can leave this empty unless you truly need async workflows/audit integrations.

| Event | Triggered when | Produced by (module/aggregate) | Consumed by | Payload (conceptual) |
|---|---|---|---|---|
| `[EventName]` | [...] | [...] | [...] | [...] |

## 6) Cross-aggregate rules and policies

> Rules that span aggregates or require orchestration.

| Policy / rule | Plain-English description | Enforced by (module) | What happens on violation |
|---|---|---|---|
| [...] | [...] | [...] | [...] |

## 7) Permissions model (domain-level)

> Keep this at the “who is allowed to do what” level (not auth implementation).

| Action / capability | Allowed roles/personas | Notes |
|---|---|---|
| [...] | [...] | [...] |

## 8) Data semantics & audit expectations

- Identifiers: [what must be globally unique?]
- Time: [what timestamps matter?]
- Audit: [which actions must be auditable?]
- Compliance: [any constraints?]

## 9) Open questions / TBD

- [Question]
- [Question]

## Checklist before writing the Epic

- [ ] Every noun used in PRD journeys appears in the Ubiquitous Language (or is explicitly out of scope)
- [ ] Each “must” functional requirement in PRD has at least one use case (UC-*)
- [ ] Each aggregate lists invariants that can be tested
- [ ] Lifecycle/status transitions are defined for any stateful aggregate
- [ ] Permissions are clear for core actions
- [ ] The team agrees on module + aggregate names (no synonyms)
