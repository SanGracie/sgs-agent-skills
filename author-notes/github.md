# GitHub — comments, issues, pull requests

> Last verified: 2026-09-17

Library-owned. Agents **may** use GitHub on the user's behalf when the
work is a GitHub repo (this skills library, or any repo they open that
has a `github.com` remote).

Use the GitHub CLI (`gh`). Skill: `.cursor/skills/github-collab/SKILL.md`.

## What you may do without extra permission

- Read issues, PRs, checks, and file contents.
- Comment on an issue or PR the user is talking about.
- Open a **draft or ready** PR after they asked to create one.
- Open an issue if they asked to file a request / bug / follow-up.

## What you must ask first

- Anything that merges, closes, or deletes.
- Force-push, rewriting `main`/`master`.
- Changing org/repo settings, collaborators, or visibility.
- Moving an Azure DevOps app onto GitHub.

## NAM EHS split

| Host | What lives there |
|---|---|
| Azure DevOps `SGS-NAM-Dev` | `ehs_dashboard`, V3, most production apps |
| GitHub `logan-bishop-sgs/sgs-agent-skills` | Cursor skills, setup, author-notes |

Do not add this skills library as a second remote on an ADO repo.

## Account

Prefer the SGS GitHub user (`logan-bishop-sgs` for Logan). Techs should
`gh auth login` with their own SGS-linked GitHub account. `gh` is not
always installed — full setup (IT) installs it; light setup tells them
to ask IT.
