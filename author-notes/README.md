# Author notes (Logan)

> Last verified: 2026-09-17

Write living context **here**, in this library. `setup-agent` copies these
files into each working repo as `CONTEXT/sgs-and-team.md` and
`CONTEXT/github.md` (library-owned). The next setup or "refresh skills"
run overwrites those copies so new agents pick up your updates.

Do **not** put passwords, tokens, or `.env` values in these files.

| File | Lands in the working repo as |
|---|---|
| `sgs-and-team.md` | `CONTEXT/sgs-and-team.md` |
| `github.md` | `CONTEXT/github.md` |
| `machine-setup.md` | `CONTEXT/machine-setup.md` |

Edit, commit, and push this folder. Techs do not need to edit the copies
in their app repos unless they are adding *project* facts — those go in
that repo's own `CONTEXT/`.
