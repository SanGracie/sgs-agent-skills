---
name: github-collab
description: >-
  Comment on GitHub pull requests and issues with the GitHub CLI (gh).
  Use when the user asks to comment on a GitHub PR, open a GitHub issue
  on their app repo, or check PR status. Not for Cursor skill bugs —
  those use report-skill-issue (dashboard Report Feedback).
---

# GitHub comments, issues, PRs

Prefer `gh`. Do not scrape the website. Auth: `gh auth status`. If not
logged in, `gh auth login --web` and wait for the human.

Read `.cursor/library-notes/github.md` for NAM EHS (ADO vs GitHub)
and the hard rule: **do not change** `logan-bishop-sgs/sgs-agent-skills`.
Techs keep notes in **their** `CONTEXT/` and `work-log.md`. Skill
problems: `.cursor/skills/report-skill-issue/SKILL.md` (dashboard
Feedback). File a GitHub **issue** only for GitHub-hosted app repos,
never to change this library's skills.

## Comments

```powershell
gh issue comment <n> --body "..."
gh pr comment <n> --body "..."
```

`--repo owner/name` when the current folder is not that git repo.

Write like a teammate. No secrets. Timezone-label any timestamps.

## File a request / bug

```powershell
gh issue create --title "..." --body "..."
```

Include: what they wanted, what happened, repo/path, and that this is
NAM EHS if relevant.

## Pull requests

Only after they asked. Follow the user's committing-changes / PR rules
(no force-push to main, no secrets).

```powershell
gh pr create --title "..." --body "..."
```

Body: summary + test plan. Return the PR URL.

## Status

```powershell
gh pr view
gh pr checks
gh issue list
```

## Do not

- Edit, commit, or push `logan-bishop-sgs/sgs-agent-skills` (unless the
  user is Logan and explicitly asked to update the library)
- `git push --force` to `main` / `master`
- Merge or close unless they asked
- Change collaborators, visibility, or org settings
- Attach this library as a remote on an Azure DevOps app repo
