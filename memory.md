# Memory

> Durable AI lessons learned from major incidents only.
> Do not log every warning. Capture high-signal failures that changed implementation behavior.

## When to write a lesson

- Repeated bug/regression (same class appears more than once)
- Production-like runtime failure or critical local blocker
- Wrong implementation pattern that required rework
- Contract/schema misunderstanding that caused drift

## Entry format

Use one section per lesson:

```markdown
## LESSON-<timestamp> [short title]
- incident: INC-YYYYMMDD-HHMMSS
- story: US-XXX
- severity: major|critical
- signal: [what failed]
- root_cause: [why it failed]
- correction: [what fixed it]
- prevention_rule: [actionable rule to avoid repeat]
- checks: [specific command/check to run]
- evidence: incident_id=INC-..., db=logs/learning.db[, snapshot=logs/snapshots/INC-...log]
- added_on: YYYY-MM-DD
```
