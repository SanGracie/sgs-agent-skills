---
name: reimbursements
description: >-
  Create and complete SGS expense reports in Workday. Covers corporate
  card charges and out-of-pocket reimbursement, receipts, memos, and
  foreign-currency amounts. Use when the user mentions expenses,
  expense reports, Workday expenses, corporate card, receipts,
  reimbursement, or filing a report in Workday.
---

# Workday expense reports (SGS)

**Talk to the user** with `.cursor/library-notes/voice.md`. Do the
report yourself. Leave a **draft**. They submit.

Do this in **Edge**, not Cursor’s helper window. See [login.md](login.md).

Personal facts (name, memo style, cost center, receipts folder) live
in **this working folder’s** notes (`CONTEXT/` or `context/`), not
in this skill. Do not invent amounts, vendors, cost centers, or policy.

## Start here

1. Open Workday in Edge:

   ```powershell
   powershell -File .cursor/skills/reimbursements/scripts/Open-Workday-Edge.ps1
   ```

2. Sign in if needed. If asked to remember this device, tick the box and Submit.
3. Left menu (hamburger) → expand **Personal** if it is collapsed → **Expenses Hub** → **Create Expense Report**.
4. Header: fill **Memo** only unless they said otherwise. Leave Company / date / accounting company as Workday filled them. Click **OK**.
5. On Expense Lines: **Add**.
   - Corporate card → **Credit Card Transactions**
   - They paid themselves → **New Expense**, then turn off **Paid with Corporate Card**
6. On the line: expense type, receipt, date that matches the charge or receipt, memo, amount.
7. Click **Done** on the line so they can review. **Do not click Submit.**

## What to guess vs ask

| Field | Rule |
|-------|------|
| Memo | Guess a short business reason from the merchant, date, and anything they said. Ask if it could be personal, client-sensitive, or unclear. |
| Expense type | Guess from the merchant and receipt (meal, hotel, taxi, flight). Ask if two types could both fit. |
| Date | Card charge date, or the receipt date if there is no card charge. |
| Amount / merchant | Never guess. Use the card charge or receipt. |
| Cost center / extra coding | Leave Workday defaults unless their notes say otherwise. Ask if Workday requires a field you have not seen before. |

## Corporate card (usual path)

The charge is already on the corporate card, so it **shows up right away** on the first Create Expense Report screen.

1. Find the matching charge in the credit card list.
2. Select that charge only (not extra unrelated charges unless they asked).
3. Continue (OK).
4. Open that expense line.
5. Attach the receipt to **that line**.
6. Choose expense type. Add or tidy the line memo.
7. Confirm amount and date still match the receipt.

Never create a second line for the same card charge (that looks like they want to be paid back for something the card already paid).

## Out of pocket (they paid themselves)

Use this path when they say the spend was personal / out of pocket, or no card charge appears.

1. Do not select a corporate-card charge for it.
2. Add a **new expense**.
3. Workday ticks **Paid with Corporate Card** by default. **Turn that off** before Done. If it stays on, every line shows a red error (“clear the Paid with Corporate Card check box”) and reimbursement can stay too low. Check `data-automationcheckboxchecked` — do not guess from a missing tick mark.
4. Date, amount, and merchant come from the receipt. Attach the receipt. Choose type. Write memo.

If one PDF has several photos, make **one line per receipt**, not one line for the whole file.

## Line fields that must be filled

- **Expense item:** search does **not** work. Open the prompt → **By Alphabetical Order** → scroll the list itself (not the page) and click. For meals, jump near scroll position 1980 for `US_MEALS (SELF, SGS EMP.)TIPS`. Click only when that row is in the middle of the screen, not under the header.
- **Memo:** required. Type it in the Memo box, press Tab, then Done.
- **Amount:** never invent. Foreign currency: see below.

## Foreign currency

Do **not** leave the line in local money (for example COP). Workday can convert on screen, but **Reimbursement stays 0.00** until the line is saved in **USD**. Put the USD amount Workday showed; write the local total in the memo.

A leftover “meal over $100” warning can stick even when Submit is still allowed — leave it.

## Receipts

Inbox is the receipts folder in **this working folder**. Prefer PDF, JPG, or PNG. Track each file in a log there. Never file the same receipt twice. Move to a done folder only after they say it is submitted. If the folder is already named `reciepts/`, do not rename it.

## Workday gotchas (confirmed)

- Cursor’s helper window **cannot** finish SGS Windows sign-in (blank/black at `sso.sgs.net`). Stay in Edge. Do not try to copy cookies into Cursor’s window.
- Never press **Escape** — it closes the report.
- Never click the **X** in the top-right of a line — that closes the line or the whole report.
- Close only the **Errors / Page Error** pop-up before Done. Do not click the report Close button.
- After a line is filled, click **Done** (orange, bottom of the line). Errors do not clear until the line is saved.

## After the report is filled

Tell them, in everyday words:

- What you put on the report (memo, each line: date, merchant, type, amount)
- That it is a **draft** (they submit)
- Anything you guessed

Then write what worked in their notes (`CONTEXT/work-log.md` or `context/workflows.md`) and add memo/type examples to [examples.md](examples.md) if a new pattern showed up.

## Stop and ask

- Sign-in or extra security check needs them
- Charge does not appear and they said it was on the card
- Receipt is missing or does not match the amount
- Workday shows an error, extra required field, or personal-expense flag
- You would have to invent a cost center, project, or guest name
