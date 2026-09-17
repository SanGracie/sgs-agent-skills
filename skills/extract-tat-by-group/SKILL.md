---
name: extract-tat-by-group
description: >-
  Extracts Accutest TAT by service group from AniTa Invoice Disk
  (tat-sg.idx1) and emails the file. Use when the user says extract TAT
  by group, pull tat-sg, invoice disk TAT, or run AniTa TAT by group.
---

# Extract TAT by group

**Talk to the user** with `.cursor/library-notes/voice.md`: short, no
engineering words. Do the work. Ask only lab + months. When done: "TAT
by group for Houston this month is done. It should show on SharePoint
soon." This script is for you, not for them to run.

Run this on a Windows PC with AniTa installed. **One Export is
one calendar month.** September is only September — not YTD. A range
that spans months blends averages.

The form is **Invoice Disc Generation**, not SEE SALES. It is fully
keyboard-driven. Reuse `extract-seesales` `anita-bg.exe` (no focus steal).
One AniTa window per lab; keys go to that host title only.
`-Lab all` (or a comma list) runs the labs in parallel. Use
`-Sequential` only if you need one host at a time.

## Hands-off (login + walk)

```powershell
# Current US-Central month, thru = US today (LIMS rejects a future thru)
powershell -File .cursor/skills/extract-tat-by-group/scripts/run-tat-extract.ps1 -Lab houston -ThisMonth

# Closed month (thru = last day)
powershell -File .cursor/skills/extract-tat-by-group/scripts/run-tat-extract.ps1 -Lab scott -From 2026-08

# Partial month
powershell -File .cursor/skills/extract-tat-by-group/scripts/run-tat-extract.ps1 -Lab dayton,orlando,houston -From 2026-09 -ThruDay 15

# All five labs, one AniTa window each (parallel)
powershell -File .cursor/skills/extract-tat-by-group/scripts/run-tat-extract.ps1 -Lab all -ThisMonth
```

`login-tat.ps1` uses the same Linux/IFORMS login as SEE SALES, then
Invoice (`i` / `I`) → Down → Enter for Invoice Disk (See Sales is
first on that submenu). It reuses a live host (Invoice Disk, menu,
or IFORMS password) instead of killing it. IFORMS Log On is
`CLASS=logon` (dark-blue, little white) — never send Invoice keys
there. `-Force` kills the host and logs in fresh. It waits for `CLASS=form`
after the password and **refuses Invoice keys if `KEYS=password`**.
Snaps retry through a brief post-password disconnect. The all-labs
runner retries login once. `-Force` kills the host and logs in fresh
(use after a dirty form or password dump). Two failed IFORMS logons
hang the session.
Type the password only at `Password:` / `Enter password:`. Park only
after IFORMS.

## Already on the Invoice Disk form

Cursor must be on **Billing Date**, and that date must be the **1st
of the month** (`01-SEP-2026`) before you Tab into Find.

```powershell
powershell -File .cursor/skills/extract-tat-by-group/scripts/export-tat-groups.ps1 -Location scott -ThisMonth
powershell -File .cursor/skills/extract-tat-by-group/scripts/export-tat-groups.ps1 -Location scott -From 2026-08
# Resume after a partial walk: -Groups is the remaining codes,
# -StartDown is that first code's Down count (GCS = 2, not the full list)
powershell -File .cursor/skills/extract-tat-by-group/scripts/export-tat-groups.ps1 -Location dayton -From 2026-08 -StartDown 2 -Groups GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB
```

Labs: `wheatridge`, `dayton`, `orlando`, `scott`, `houston` (or
`057`/`059`/`066`/`062`/`064`). Invoice Disk group list is the same
12 on every lab (verified 2026-09-16, `1 of 12`):

`FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB`

Walk with **Down then End**. Find-by-code returns `1 of 0` for GCU
and MSU. End (VK 35) picks the format after typing `tat-sg` — status
says "Press End to pick." Tab+Enter after `tat-sg` can dump keys
into the date field.

If a ready snap is under 40000 bytes the form is still painting
(Dayton GEN false-aborted at 14820). Wait and `-StartDown` from that
group. Compare thru to US-Central `.Date`, not time-of-day.

## Keyboard path

Do **not** Tab until Billing Date is the 1st.

1. Invoice → Invoice Disk. Cursor lands on Billing Date.
2. Confirm start is `01-MMM-YYYY` (first of the month). After End,
   LIMS can leave the start date on the thru day — retype the 1st
   before every group. Do not Tab until it is the 1st.
3. **Tab** → Find Disc Format (`1 of ~1260`).
4. Type **`tat-sg`** (chars, not VK — hyphen is Insert if you use `type`).
5. **End** (VK 35) → Service Group list (`1 of 12`).
6. Down-arrow to the group, then **End**. Do not Find GCU/MSU by code.
7. Thru field is **empty**. Type the last **US-Central** day of that
   month with **chars** (`31-AUG-2026`, or `15-SEP-2026` while Central
   is still the 15th). See **Billing dates** below if thru is already
   filled or F4 looks tempting.
8. **End** (VK 35) queues the job. Status becomes
   `Transaction complete - 1 record posted and committed.` Form
   resets to Billing Date. Always overwrite start back to the 1st.
9. Repeat 3–8 for each group. LIMS emails Logan. The file reaches
   SharePoint **only if** Outlook forwards that mail to
   `us.ehs.datadrop@sgs.com` (see **Outlook / datadrop** below).

| Lab | Host | Invoice key | SharePoint slug |
|---|---|---|---|
| Wheat Ridge | `use-idb057` | `i` | `co` |
| Dayton | `use-idb059` | `i` | `nj` |
| Orlando | `use-idb066` | `i` | `fla` |
| Scott | `use-idb062` | `I` | `la` |
| Houston | `use-idb064` | `I` | `tx` |

GCU files land as `gcv`, MSU as `msv`. Ignore leftover Scott
`15-sep-26_15-sep-26`, Wheat Ridge / Dayton GCA
`01-aug-26_11-sep-26`, and Houston `31-aug-26_31-aug-26`.

```
Billing Date     01-SEP-2026  thru  15-SEP-2026
Disc Format      tat-sg.idx1
Account          all
Account MATCH    Inv#
Service Group    FLD
```

Confirm:

```powershell
python .cursor/skills/extract-tat-by-group/scripts/check-sharepoint-tat.py --date 2026-09-16 --range 01-sep-26_15-sep-26 --expect 60
python .cursor/skills/extract-tat-by-group/scripts/check-sharepoint-tat.py --date 2026-09-16 --range 01-aug-26_31-aug-26 --expect 60
```

Both ranges landed **12/12 × 5 labs** in `Power Automate Updates/2026-09-16/`
(verified 2026-09-16). Wheat Ridge / Dayton August were the late pair.

## Outlook / datadrop

Without a **forward-to-datadrop** Outlook rule, TAT files stay in
Inbox and never appear on SharePoint. The agent can set that rule
up — `.cursor/skills/outlook-datadrop-rule/`
(`ensure-datadrop-rule.ps1`). Forward to `us.ehs.datadrop@sgs.com`,
never delete. Then Power Automate drops the attachment here:

https://sgs.sharepoint.com/sites/reg-nam-fin-teamsite/NAMFINBIUploads/LIMSBISynergy/EHS%20KPI%20Data/Forms/AllItems.aspx?id=%2Fsites%2Freg%2Dnam%2Dfin%2Dteamsite%2FNAMFINBIUploads%2FLIMSBISynergy%2FEHS%20KPI%20Data%2FPower%20Automate%20Updates&sortField=Modified&isAscending=false&viewid=a9210459%2D53f5%2D49c8%2Daeb9%2D25717d7b12d9

`EHS KPI Data/Power Automate Updates/<YYYY-MM-DD>/` as
`{loc}-tat-{group}-{dd-mmm-yy}_{dd-mmm-yy}_*.xls`. Same drop as
daily `la-closed` / WIP discs. Confirm there, not Inbox.

## Date rules

- Start **must** be the 1st. Changing other fields first is what
  leaves a stale mid-month start.
- Thru must be **the same month** and **not in the future** for the
  LIMS host (US Central). A future thru paints
  `WARNING: Invoice date is in the future.` Acknowledge with Enter —
  the form resets and that group did **not** queue.
- Logan's PC is UTC+8. After ~13:00 PHT, US Central is still
  yesterday. Use Central "today", not the laptop clock.
- Do not queue Jan–Sep as one range. That is the "too many averages"
  case.

## Billing dates (verified 2026-09-16)

You **can** change start and thru. The field just has two states,
and the keys that look like they edit a date often do something else.

**Empty thru (happy path).** After Down+End on a group, status is
`Enter ending invoice date for DATE RANGE` and thru is a blank box.
`chars 31-AUG-2026` fills it. This is what `export-tat-groups.ps1`
does. September 1–15 and the August walks after a clean group-pick
used this path.

**`<FULL>` thru (dirty form).** If the form already copied start into
thru (`01-AUG-2026 thru 01-AUG-2026`), status is
`Cursor is at beginning of field value` plus `<FULL>`. Insert and
`chars` are ignored. This is what blocked Wheat Ridge / Dayton
August until the form was reset. Do not End while thru still equals
the 1st on a closed month.

How to change a filled date:

1. Prefer cancel / re-pick the group so thru is empty, then type.
2. If you must edit in place: cursor must already be **in that date
   field**. **F4** (VK 115) then opens the calendar — header
   `August 2026` / `September 2026`, help
   `Day: Right, Left` / `Week: Down, Up` / `Month: PgDn, PgUp` /
   `Accept: End, Enter` / `Cancel: F3`. Right past the last day
   wraps to the 1st of the next month. Snap and confirm
   `31-AUG-2026` (or the intended day) before End on the form.
3. **F4 after a fresh group-pick is invoice Find**, not the calendar
   (`Find: N of M`, `Press End to pick. F3 to cancel.`). End on that
   list wrote `11-SEP-2026` into thru and queued a cross-month GCA.
   Cancel Find with F3 (VK 114). Ignore the leftover SharePoint
   files `co-tat-gca-01-aug-26_11-sep-26_*` and
   `nj-tat-gca-01-aug-26_11-sep-26_*`.

What does **not** clear a `<FULL>` thru:

- Backspace at the start of the field (nothing before the cursor).
- Insert then type (still `<FULL>`).
- Home then type. Home leaves the field. Before 2026-09-16, `key 36`
  also sent WM_CHAR `$` and garbled start (`1A1-SG31-AE`).
- Delete from the start. One Delete dropped the last digit
  (`01-AUG-2026` → `01-AUG-202`); further Deletes did nothing.
  Year `202` fails with `End date may not be before start date.`
  Type `6` to restore `2026` if you do this by accident.

**End is Commit, not "go to end of field."** VK 35 picks a Find row,
accepts the calendar, and queues the disc. Sending End on an
incomplete thru validates it.

**`anita-bg key` CHAR skip** (shared driver
`.cursor/skills/extract-seesales/scripts/anita-bg.cs`): `key` used
to send WM_CHAR with the VK code. That typed junk —
Home `$`, Insert `-`, Delete `.`, Left `%`, PageUp `!`.
`Key()` now skips CHAR for Backspace (8), PageUp/PageDown (33–34),
Home/arrows (36–40), Insert (45), Delete (46). End (35) still sends
CHAR; IFORMS uses it as Commit. The export script rebuilds
`anita-bg.exe` when the `.cs` is newer. Hyphens in dates still go
through `chars`, never `type` / `key 45`.

**Resume:** `-StartDown` is the Down count for the **first** code in
`-Groups`. Do not pass the full 12-group list with `-StartDown 1` —
that labels FLD but Downs to GCA and walks the last group off the
list. Example: remaining from GCS is
`-StartDown 2 -Groups GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB`.

**OCR:** Invoice Disk (small white dialog) and the main menu (olive
box) can read as `CLASS=logon`. Do not send Invoice keys unless
`KEYS=password` / `iforms`. Do not require `KEYS=invoicedisk` to
believe the form is open. Confirm dates from the filename on
SharePoint (`01-aug-26_31-aug-26`); the AniTa `3` in `31` often
OCRs as `0`.

## Issues we hit (2026-09-16)

### Login / dirty session

The first Wheat Ridge + Dayton August walk never emailed. OCR treated
IFORMS **Log On** (dark blue, little white, `CLASS=logon`) as Invoice
Disk and typed `01-AUG-2026` / `tat-sg` / Invoice keys into login.
Wheat Ridge landed on a password prompt. Dayton's date became
`SDIT9977100E` and LIMS said `You must select an account`
(`KEYS=needaccount`). A retry then typed the password into the
**user ID** field (`sDyt9977`) — two `logon denied`. Stop there.
A third failed IFORMS logon hangs the session.

Recover by killing that host only, then Linux `Password:` →
`REMOVE?` `y` → Tab → IFORMS password **once**, at
`Password:` / `Enter password:` only → Invoice `i` / `I` → Down →
Enter. `-Force` on `login-tat.ps1` is the scripted form of that.
Do not type Invoice keys while `KEYS=password` / `iforms` /
`invaliduser`. `login-tat.ps1` waits for `CLASS=form` and refuses
those keys; it still cannot trust `CLASS=logon` alone because the
main menu (olive ACCULIMS box) and Invoice Disk (white dialog) OCR
the same way.

Park only after IFORMS. `anita-bg park` during `login:` / `Password:`
drops the telnet. One AniTa window per host title (`use-idb0XX`).

### Parallel runner

`-Lab all` is one child PowerShell per lab. Quote `-File` —
`Start-Process` splits on the space in `OneDrive - SGS` and the
child never starts. Stagger launches a few seconds; a leftover
sequential Wheat Ridge job logged into Dayton and collided with the
parallel Dayton walk. Child `ExitCode` can be null — treat
`DONE loc=<lab>` in that lab's log as 0
(`run-tat-extract.ps1`). `$scr = Read-Screen` used to swallow
`Write-Output`; login/export log with `[Console]::Out.WriteLine`.

### Walk / dates

- Thru after US-Central today (`30-SEP`, `16-SEP` while Central was
  still the 15th) paints `WARNING: Invoice date is in the future.`
  Enter acknowledges; that group did **not** queue. Compare thru to
  Central `.Date`, not the laptop clock (UTC+8).
- After End, start can stick on the thru day. Retype the 1st before
  every group. Do not Tab until it is the 1st.
- Tab+Enter after `tat-sg` dumps keys into the date field. End picks
  the format (`Press End to pick.`).
- Find-by-code is `1 of 0` for GCU and MSU. Down then End. Files land
  as `gcv` / `msv`.
- Dayton GEN ready snap was 14820 bytes (form still painting) and
  false-aborted. Retry until the canvas is ≥ 40000 bytes, then
  `-StartDown` from that group.
- A ready snap that looks like `01-AUG` thru `01-AUG` is often OCR
  reading `31` as `01`. Believe the SharePoint filename.

### SharePoint / leftover files

Files skip Inbox **when the datadrop forward rule is on**. They land
in `EHS KPI Data/Power Automate Updates/<YYYY-MM-DD>/` as
`{loc}-tat-{group}-{dd-mmm-yy}_{dd-mmm-yy}_*.xls`. The Graph list
timed out once (sgs.sharepoint.com ~15s) — rerun
`check-sharepoint-tat.py`. If AniTa queued but SharePoint is empty,
run `.cursor/skills/outlook-datadrop-rule/` — do not assume Inbox
is the destination. Ignore:

- Scott one-day `15-sep-26_15-sep-26` from the first walk
- Wheat Ridge / Dayton GCA `01-aug-26_11-sep-26` (Find-list End)
- Houston `tx-tat-sub-31-aug-26_31-aug-26_*` (start stuck on thru)

## Do not

- Span more than one calendar month on Billing Date.
- End with a thru date after US-Central today.
- End while thru still equals the start date on a closed month.
- Home or F4 to "clear" thru after picking a group (Home leaves the
  field; F4 is invoice Find). F4 is the calendar only while already
  editing a filled date field.
- Use SendKeys / SendInput / `SetForegroundWindow`.
- `BM_CLICK` Commit — End is the keyboard commit.
- Type Invoice keys while still on IFORMS Log On.
- Retry IFORMS password after two `logon denied` — the third hangs
  the session. Kill the host and walk Linux → REMOVE? → IFORMS once.
- Unquoted `-File` on a path with `OneDrive - SGS` (child never starts).
- Treat this as the V3 `tat_by_group` weekly ETL. That table is a
  different pipeline. This extract emails a `tat-sg` file.
- Expect SharePoint without a forward-to-`us.ehs.datadrop@sgs.com`
  Outlook rule. Inbox is not the drop.

## Done when

- [ ] Each requested group showed `Transaction complete` (no future-date warning)
- [ ] Outlook rule forwards Accutest LIMS to `us.ehs.datadrop@sgs.com`
      (not delete). Agent can create it via `outlook-datadrop-rule`.
- [ ] That day's `Power Automate Updates` folder has one
      `{loc}-tat-{group}-01-…` file per group (not Inbox)
- [ ] Billing Date was `01-MMM-YYYY` thru a same-month non-future day
- [ ] No password or `.trc` staged for git
