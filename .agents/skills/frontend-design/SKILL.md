---
name: frontend-design
description: >
  Design and implement distinctive, production-grade frontend interfaces for
  this project. Use when the user asks for UI polish, visual redesign, new
  pages/components with strong aesthetics, or better interaction quality.
metadata:
  short-description: High-quality UI design for this React stack
---

# Frontend Design

Use this skill for visual direction and polished UI implementation.

This skill is additive to `$web-feature`:
- Use `$web-feature` for feature/data wiring and contract-safe implementation.
- Use `$frontend-design` when visual quality, layout language, typography, or motion needs elevation.

## Project stack constraints

- React + Vite in `web/`
- Tailwind v4 + shadcn/ui primitives
- Scaffold baseline theme: `modern-minimal` tokens in `web/src/index.css`
- Zustand for local UI state
- TanStack Query for server state
- Generated API types only from `web/src/lib/api/schema.d.ts`

## Design workflow

1. Define a clear visual direction first:
   - purpose
   - audience
   - tone (minimal, editorial, playful, utilitarian, etc.)
   - one memorable design decision
2. Build a design token base with CSS variables:
   - color roles
   - spacing scale
   - radius/shadow
   - type scale
3. Implement layout and hierarchy:
   - avoid generic boilerplate compositions
   - prioritize intentional spacing and rhythm
   - keep responsive behavior explicit (mobile + desktop)
4. Add motion with restraint and meaning:
   - page-load choreography
   - hover/focus/transition states
   - avoid noisy animation spam
5. Verify feature-state coverage:
   - loading
   - empty
   - error
   - success

## Hard rules

- Do not break project architecture boundaries from `AGENTS.md`.
- Do not hand-write API types.
- Do not use `any` in TypeScript without explicit justification.
- Preserve accessibility: semantic HTML, visible focus states, color contrast, keyboard flow.
- Prefer composition of shadcn/ui primitives over custom one-off component internals.

## Anti-patterns to avoid

- Generic “AI-looking” layouts and color schemes.
- Defaulting every page to the same hero-card structure.
- Overusing a single trendy font/style across unrelated pages.
- Flat, single-color backgrounds without depth when the context needs stronger visual hierarchy.

## Done criteria

- Visual direction is identifiable and intentional.
- UI is production-ready, responsive, and accessible.
- Typecheck/lint/tests pass for changed frontend scope.
