---
name: project-scaffold
description: >
  Scaffold a new project repository from this template using the skill-local
  script .agents/skills/project-scaffold/scripts/bootstrap.sh.
  Use when the user asks to bootstrap a repo, initialize project structure,
  or run the local setup workflow for a new project.
metadata:
  short-description: Bootstrap a new repo with project-scaffold
---

# Project Scaffolding

Use this skill to bootstrap a new repository from this template.
The scaffold includes modern frontend defaults (Tailwind v4, shadcn/ui, modern-minimal theme baseline, Zustand, forms/validation, testing) and practical backend defaults (chi + CORS, pgx, Redis, validator, JWT).
It also seeds a minimal failure-learning loop (`logs/learning.db` + `memory.md` + `scripts/incident-learn.sh`).

## Canonical source

- Script: `.agents/skills/project-scaffold/scripts/bootstrap.sh`
- Reference guide: `.agents/skills/project-scaffold/references/bootstrap.md`

Always treat `.agents/skills/project-scaffold/scripts/bootstrap.sh` as the source of truth for scaffolding behavior.

## Procedure

1. Confirm inputs: `<project_name>` and `<github_org>`.
2. Run from template repo root:
   - `chmod +x .agents/skills/project-scaffold/scripts/bootstrap.sh`
   - `./.agents/skills/project-scaffold/scripts/bootstrap.sh <project_name> <github_org>`
3. Move into the generated project directory.
4. Complete bootstrap verification:
   - `make dev-infra`
   - `make migrate`
   - `make schema-dump`
   - `make generate`
   - `make lint`
   - `make test`
   - `make validate`

## Rules

- Do not manually recreate scaffolded files when the script can generate them.
- If scaffold output needs changes, update `.agents/skills/project-scaffold/scripts/bootstrap.sh` first, then update the reference guide.
- Keep this skill and the script in sync.
