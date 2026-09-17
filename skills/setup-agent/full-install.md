# Full / IT machine install

Read this when the user is Logan, IT, or said they can install software.
Light-track techs skip it.

Also read `author-notes/machine-setup.md`.

## Run

From the **library** root (folder that contains `bootstrap/` and `skills/`):

```powershell
powershell -File bootstrap/install-machine.ps1 -TargetRoot "<target-repo>" -LibraryRoot "<library-root>"
```

`-LibraryRoot` defaults to the parent of `bootstrap/`.

If the script hits UAC / winget hang: stop waiting, keep file setup,
list leftovers (Python 3.13, `gh`, pip).

## After install

- `python --version` should be 3.13.x (3.11+ ok).
- `gh auth status` — if logged out, start `gh auth login --web`.
- Confirm `.env` exists in the target and is gitignored. Do not fill
  `ANITA_PASSWORD` from chat.
