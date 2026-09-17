# Cursor Skills

Shared [Cursor](https://cursor.com) Agent skills for SGS.

This repository is **public** so any SGS colleague with the link can open it without an invite. GitHub cannot limit a personal-account repo to `@sgs.com` only (that requires an SGS GitHub organization with internal visibility). Do not commit secrets, passwords, tokens, or VPN-only host details.

## Add a skill to Cursor

1. Copy a folder from `skills/` into your project at `.cursor/skills/<skill-name>/`.
2. Each skill must include a `SKILL.md` file.
3. Restart or reopen the Cursor chat so the agent picks it up.

## Add a skill to this repo

Open a pull request that adds `skills/<skill-name>/SKILL.md` (plus any scripts that skill needs).

## Layout

```
skills/
  <skill-name>/
    SKILL.md
    scripts/    # optional
```
