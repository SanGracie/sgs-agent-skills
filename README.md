# SGS Agent Skills

Shared [Cursor](https://cursor.com) Agent skills and workspace setup for SGS NAM EHS.

Repo: https://github.com/logan-bishop-sgs/sgs-agent-skills

Public so any SGS colleague with the link can open it. **Do not commit secrets.**

## Help me get set up

Clone/open this repo in Cursor and say:

> help me get set up

Give the path to **your working repo** (dashboard, V3, a new project).

- **Full track** (Logan / IT): Python **3.13**, GitHub CLI, pip, `.env`, `.gitignore`, skills, personalized Cursor rules, CONTEXT, SGS/team notes.
- **Light track** (data tech laptop): files only. Installs become a list for IT if the machine is locked down.

Then start a **new chat** in the working repo.

Later: **refresh skills** recopies skills + author-notes without wiping your name in `workspace.mdc`.

## Author notes (Logan)

Edit [`author-notes/`](author-notes/README.md) in **this** repo. Setup copies them into each project as `CONTEXT/sgs-and-team.md`, `github.md`, and `machine-setup.md`, so every new agent learns who we are, how GitHub comments/PRs work, and how machines get Python / `.env`.

## Skills

| Skill | When |
|---|---|
| `setup-agent` | "help me get set up", refresh skills, Python / `.env` |
| `github-collab` | comment on a PR, file a GitHub issue, open a PR |
| `extract-seesales` | Accutest SEE SALES → SharePoint |
| `extract-tat-by-group` | Accutest TAT by service group |
| `outlook-datadrop-rule` | Outlook → `us.ehs.datadrop@sgs.com` |

LIMS skills need AniTa, VPN, and `ANITA_PASSWORD` in `.env` or User env (never git).

## Layout

```
author-notes/     # Logan writes here; setup ships copies
bootstrap/        # install-machine.ps1 + requirements.txt
skills/
templates/        # .gitignore, .env.example, rules, CONTEXT
```
