# Subagents

> Last verified: {{TODAY}}

Delegate by default. Subagents get clean context windows. Cheap models do
mechanical work; the parent orchestrates and reviews.

## When to fan out

- A plan with 2+ independent stages
- A repo-wide audit or sweep
- A multi-file refactor with disjoint file sets
- Test / CI triage
- Broad exploration

## Rules

- **One writer per file.** Never put two agents on the same file.
- **Verify claims.** Subagents invent paths. Confirm with `Test-Path` or `git ls-files` before acting.
- **Do not delegate:** commits, deploys, secrets, or edits that are 1–2 tool calls.

## What a subagent prompt must contain

- The exact files or glob it may touch
- The outcome that counts as done
- What it must not do (secrets, extra files, drive-by refactors)
- Which docs to read first (`CONTEXT/INDEX.md`, then the one INDEX names)

## Model tiers

Orchestrate and review on the expensive model. Delegate exploration, sweeps,
mechanical edits, and self-contained plan files to `cursor-grok-4.6-high-fast`.
Step up only when a stage needs real reasoning.
