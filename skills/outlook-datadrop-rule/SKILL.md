---
name: outlook-datadrop-rule
description: >-
  Creates or checks the Outlook rule that forwards Accutest LIMS mail
  (SEE SALES, Invoice Disk TAT, closed/WIP discs) to
  us.ehs.datadrop@sgs.com so Power Automate lands attachments in
  SharePoint Power Automate Updates. Use when the user says set up
  the outlook rule, forward to datadrop, files not on SharePoint,
  or emails stay in Inbox.
---

# Outlook → datadrop → SharePoint

AniTa emails Logan's mailbox. Those files show up in SharePoint
**only if** an Outlook rule **forwards** the message to
`us.ehs.datadrop@sgs.com`. Power Automate on that mailbox drops the
attachment into the dated folder. No rule (or a delete rule) means
Inbox-only — nothing at this link:

https://sgs.sharepoint.com/sites/reg-nam-fin-teamsite/NAMFINBIUploads/LIMSBISynergy/EHS%20KPI%20Data/Forms/AllItems.aspx?id=%2Fsites%2Freg%2Dnam%2Dfin%2Dteamsite%2FNAMFINBIUploads%2FLIMSBISynergy%2FEHS%20KPI%20Data%2FPower%20Automate%20Updates&sortField=Modified&isAscending=false&viewid=a9210459%2D53f5%2D49c8%2Daeb9%2D25717d7b12d9

Same drop as daily `la-closed` / WIP discs:
`EHS KPI Data/Power Automate Updates/<YYYY-MM-DD>/`.

The agent **can and should** set this rule up. Do not tell Logan to
do it by hand first. Run the script on this PC with Outlook open.

```powershell
# See what LIMS rules do today
powershell -File .cursor/skills/outlook-datadrop-rule/scripts/check-datadrop-rule.ps1

# Create or fix: Forward to us.ehs.datadrop@sgs.com, never delete
powershell -File .cursor/skills/outlook-datadrop-rule/scripts/ensure-datadrop-rule.ps1
```

Override the recipient with `DATADROP_TO` if needed. After Save,
re-run the checker. Confirm a new extract in that SharePoint folder
(PA lags a few minutes), not Inbox.

## Rule

| | |
|---|---|
| When | From Accutest LIMS / `ehs.accutest.lims@sgs.com` / `seed2@use-idb0XX.amr.global.sgs.com` |
| Do | **Forward** to `us.ehs.datadrop@sgs.com` |
| Do not | Move to Deleted Items |

A Move-to-`Inbox\SeeSales` rule can stay for filing. It does **not**
replace the forward. SharePoint only happens on datadrop.

Outlook COM has resolved Forward to the wrong mailbox before. The
ensure script adds the address and ResolveAll, then the checker
prints the recipient. If it is not `us.ehs.datadrop@sgs.com`, fix
the rule in Outlook (File → Manage Rules) and re-check. Do not
re-enable delete.

Covers SEE SALES (`.cursor/skills/extract-seesales/`) and TAT by
group (`.cursor/skills/extract-tat-by-group/`).
