---
name: setup-agent
description: >-
  Sets up a Cursor agent workspace from sgs-agent-skills: copies LIMS
  and GitHub skills, writes a personalized .cursor/rules/workspace.mdc,
  CONTEXT docs, .gitignore, .env.example / .env, and SGS/team author-notes.
  Full (IT) track can install Python 3.13, gh, and pip requirements.
  Use when the user says help me get set up, set up cursor, set up the
  agent, create cursor rules, CONTEXT folder, onboard this repo,
  refresh skills, or install Python / .env.
---

# Setup a Cursor agent workspace

Turn the user's **working repo** into a Logan-style Cursor workspace,
filled in with **their** name and **this** repo — not a dump of
`ehscloudreporting`.

Library layout: `skills/`, `templates/`, `author-notes/`, `bootstrap/`.

Also read [full-install.md](full-install.md) on the IT track.

## Do not

- Copy `ehs_dashboard/CONTEXT/` into a different repo.
- Create more than **one** `.mdc` — only `.cursor/rules/workspace.mdc`.
- Put `.cursor/rules/` inside an app package.
- Commit `.env`, passwords, tokens, `*.trc`, or `anita.wcf`.
- Paste passwords into chat. Leave `ANITA_PASSWORD` blank in `.env`.
- Run this against `sgs-agent-skills` itself unless they asked.
- Fight Group Policy on a locked-down tech laptop. File-setup still
  runs; installs become a leftover list.

## Resolve paths

1. **Library root** — folder with `skills/`, `templates/`,
   `author-notes/`. Walk up from this `SKILL.md`. If this skill was
   copied into `.cursor/skills/setup-agent/` and those folders are
   missing, clone
   `https://github.com/logan-bishop-sgs/sgs-agent-skills` to a temp
   dir and use that.
2. **Target root** — the working git repo.
   - If the current workspace **is** `sgs-agent-skills`, ask for the
     working-repo path.
   - Otherwise the current workspace is the target.
   - Confirm `Test-Path` before writing.

## Interview

Ask or infer, then confirm:

| Field | Example |
|---|---|
| Name | Carl Santos |
| Role | Data technician, NAM EHS |
| Team | Manila / reports to Logan Bishop |
| Expertise | one line |
| What this repo is | one line |
| Primary app folder | `ehs_dashboard`, repo root, … |
| Install LIMS skills? | default **yes** for NAM EHS |
| **Track** | **full** (Logan / IT, may install software) or **light** (tech laptop) |

Default **full** if the user is Logan Bishop or they said IT / install
Python / do everything. Default **light** for data techs unless they
ask for installs. Use `AskQuestion` for track, target path, overwrite.

Refresh-only ("refresh skills", "update from sgs-agent-skills"): skip
personalization; recopy skills + author-notes + bootstrap requirements
into CONTEXT; do not wipe Developer Context in `workspace.mdc`.

## Explore the target

Read it. Do not invent folders.

- `git rev-parse --show-toplevel`, remotes, top-level listing
- Existing `.cursor/`, `CONTEXT/`, `admin/`, `.gitignore`, `.env*`
- `requirements.txt` / `pyproject.toml`

If `workspace.mdc` or `CONTEXT/INDEX.md` already exists, show what you
would change and **ask before overwrite**. Merge Developer Context.

## 1. Install skills

Copy from `<library>/skills/` → `<target>/.cursor/skills/<name>/`:

- `setup-agent`
- `github-collab`
- `extract-seesales`, `extract-tat-by-group`, `outlook-datadrop-rule`
  (skip LIMS only if they said no)

Overwrite copies that came from this library. Keep extra skills already
in the target.

## 2. Author notes → CONTEXT (library-owned)

Copy (overwrite these three; they are meant to update):

| From `<library>/author-notes/` | To `<context-dir>/` |
|---|---|
| `sgs-and-team.md` | `sgs-and-team.md` |
| `github.md` | `github.md` |
| `machine-setup.md` | `machine-setup.md` |

Do not copy `author-notes/README.md` into the app. Logan edits notes
**in this GitHub repo**, then setup/refresh ships them.

**Context dir:** `<target>/<app>/CONTEXT/` if there is a primary app
folder, else `<target>/CONTEXT/`.

## 3. .gitignore

If the target has no `.gitignore`, copy `templates/gitignore`.

If it has one, **merge** — ensure these patterns exist, do not delete
theirs:

```
.env
.env.*
!.env.example
venv/
.venv/
__pycache__/
*.trc
anita.wcf
```

## 4. .env.example and .env

- If the target **has no** `.env.example`, copy `templates/env.example`
  to `<target>/.env.example`.
- If it **has** one, append any missing keys from the template
  (`ANITA_USER`, `ANITA_PASSWORD`, `ANITA_HOST`) with comments. Do not
  strip dashboard keys.
- If `<target>/.env` is missing, copy `.env.example` → `.env`.
- Never fill password values. Tell them to edit `.env` locally (or
  User env). Confirm `.env` is gitignored (`git check-ignore -v .env`).

## 5. Rules and CONTEXT templates

Read `<library>/templates/` and substitute placeholders. Today's date
is the user_info date (`YYYY-MM-DD`).

| Template | Write to |
|---|---|
| `workspace.mdc` | `<target>/.cursor/rules/workspace.mdc` |
| `CONTEXT-INDEX.md` | `<context-dir>/INDEX.md` |
| `CONTEXT-project-overview.md` | `<context-dir>/project-overview.md` |
| `CONTEXT-conventions.md` | `<context-dir>/conventions.md` |
| `admin-plans-README.md` | `<target>/admin/plans/README.md` |
| `admin-CONTEXT-subagents.md` | `<target>/admin/CONTEXT/subagents.md` |

Placeholders: `{{TODAY}}` `{{NAME}}` `{{ROLE}}` `{{TEAM}}`
`{{EXPERTISE}}` `{{BUSINESS}}` `{{WORKSPACE_TITLE}}` `{{REPO_ONE_LINER}}`
`{{PRIMARY_APP}}` `{{CONTEXT_DIR}}` `{{CONTEXT_INDEX_PATH}}`
`{{REPO_LAYOUT}}` (from **this** explore) `{{DIAGNOSIS_LINE}}`
`{{TASK_ROWS}}` `{{WHERE_NEW_WORK_GOES}}`.

Replace every `{{...}}`. INDEX already has SGS/GitHub rows; still add
LIMS rows when those skills are installed.

Create `admin/plans/active/` and `completed/` (`.gitkeep` if tracked).
If `admin/` is gitignored, write anyway and say local-only.

## 6. Machine install (full track only)

Read [full-install.md](full-install.md). Run:

```powershell
powershell -File "<library>/bootstrap/install-machine.ps1" -TargetRoot "<target>" -LibraryRoot "<library>"
```

Recommend Python **3.13**. 3.11+ is acceptable if 3.13 cannot install.
If winget hangs on UAC, stop, keep files, list leftovers.

Light track: skip this script. List Python 3.13, `gh`, and pip as
"ask IT".

After full install, if `gh` is present and `gh auth status` fails,
offer `gh auth login --web` (human completes the browser).

## Finish

1. One rule file only: `.cursor/rules/workspace.mdc`.
2. No leftover `{{PLACEHOLDER}}`.
3. `.env` exists, is ignored, has no password you typed.
4. Tell them, plainly:
   - which folder is the agent workspace
   - start a **new** Cursor chat there
   - fill `ANITA_PASSWORD` locally if they use LIMS
   - they can say **refresh skills** later to pull new author-notes
   - GitHub: they can ask the agent to comment or open a PR (`github-collab`)
   - full vs light: what got installed vs leftovers

Do not commit unless they ask. Library updates belong in
`sgs-agent-skills`.
