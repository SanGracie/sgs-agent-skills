# Agent Docs Index — start here

> Last verified: {{TODAY}}

This is the routing map for AI agents working in `{{PRIMARY_APP}}`. Find your task in the
first table, read the listed docs **before** editing code, then check the per-doc trust
tier in the inventory below.

## Source of truth

- **Code wins over every doc.** Where a declarative table exists in code, the doc
  points at it instead of copying it.
- **Domain owners settle conflicts:** `conventions.md` owns cross-cutting gotchas.
  Add named owners here as the repo grows (route map, auth, background jobs).
- **`CONTEXT/QA/**` and `*.archived.md` are dated snapshots and are never
  authoritative.**

Tiers:

- **A** — verified against code on this doc's own `Last verified` stamp.
- **B** — written from code but unverified since (check row numbers, file names, TTLs before relying on them).
- **C / archived** — historical or known-stale; do not trust.

Companion docs: [`project-overview.md`](project-overview.md) and
[`conventions.md`](conventions.md).

## Task → docs

| If your task touches… | Read first |
|---|---|
| Anything (orientation) | `project-overview.md`, then `conventions.md` |
{{TASK_ROWS}}

## Doc inventory & trust tiers

| Doc | Purpose | Tier |
|---|---|---|
| `project-overview.md` | What this repo is, layout, who owns what | **A** |
| `conventions.md` | Cross-cutting gotchas agents keep re-learning | **A** |
| `INDEX.md` | This routing map | **A** |
