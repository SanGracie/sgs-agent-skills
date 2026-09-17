# File AniTa / LIMS SeeSales mail out of Inbox into Inbox\SeeSales.
# Updates the two LIMS Background Process rules to Move there (not Deleted).
# Does not delete. SharePoint / datadrop is a separate path.
[CmdletBinding()]
param(
    [switch]$WhatIf,
    [switch]$SkipRules
)

$ErrorActionPreference = 'Stop'
$ol = New-Object -ComObject Outlook.Application
$ns = $ol.GetNamespace('MAPI')
$inbox = $ns.GetDefaultFolder(6)

function Get-SeeSalesFolder {
    try { return $inbox.Folders.Item('SeeSales') } catch {}
    if ($WhatIf) {
        Write-Output 'WHATIF would create Inbox\\SeeSales'
        return $null
    }
    try { return $inbox.Folders.Add('SeeSales') } catch {
        throw "Cannot create Inbox\\SeeSales (Outlook may be offline): $($_.Exception.Message)"
    }
}

$dest = Get-SeeSalesFolder
if ($dest) { Write-Output "FOLDER $($dest.FolderPath)" }

if (-not $SkipRules) {
    $rules = $null
    try { $rules = $ns.DefaultStore.GetRules() } catch {
        Write-Output "WARN rules unavailable (Outlook may be offline): $($_.Exception.Message)"
    }
    $changed = 0
    if (-not $rules) { $SkipRules = $true }
}
if (-not $SkipRules) {
    for ($i = 1; $i -le $rules.Count; $i++) {
        $r = $rules.Item($i)
        $from = ''
        try {
            if ($r.Conditions.From.Enabled) {
                $from = [string]$r.Conditions.From.Recipients.Item(1).Name
                if (-not $from) { $from = [string]$r.Conditions.From.Recipients.Item(1).Address }
            }
        } catch {}
        if ($from -notmatch 'idb057|seed2|Accutest.LIMS|accutest.lims') { continue }
        Write-Output "RULE $($r.Name) from=$from"
        if ($WhatIf) { continue }
        $r.Actions.Delete.Enabled = $false
        try { $r.Actions.Flag.Enabled = $false } catch {}
        if ($dest) {
            $r.Actions.MoveToFolder.Folder = $dest
            $r.Actions.MoveToFolder.Enabled = $true
        }
        $r.Actions.Stop.Enabled = $true
        $changed++
    }
    if (-not $WhatIf -and $changed -gt 0) {
        $rules.Save()
        Write-Output "RULES saved move-to-SeeSales count=$changed"
    }
}

$filters = @(
    "@SQL=""urn:schemas:httpmail:subject"" LIKE '%SEESALES%'",
    "@SQL=""urn:schemas:httpmail:subject"" LIKE '%SeeSales%'",
    "@SQL=""urn:schemas:httpmail:fromemail"" LIKE '%accutest.lims%'",
    "@SQL=""urn:schemas:httpmail:fromemail"" LIKE '%idb057%'",
    "@SQL=""urn:schemas:httpmail:fromemail"" LIKE '%seed2%'"
)
$ids = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($filter in $filters) {
    try {
        $set = $inbox.Items.Restrict($filter)
        for ($i = 1; $i -le $set.Count; $i++) {
            [void]$ids.Add([string]$set.Item($i).EntryID)
        }
    } catch {
        Write-Output "WARN restrict failed: $($_.Exception.Message)"
    }
}
Write-Output "MATCH $($ids.Count) Inbox items"
if ($WhatIf -or -not $dest) { return }

$moved = 0
$failed = 0
foreach ($id in @($ids)) {
    try {
        $item = $ns.GetItemFromID($id)
        [void]$item.Move($dest)
        $moved++
    } catch {
        $failed++
        Write-Output "WARN move failed: $($_.Exception.Message)"
    }
}
Write-Output "MOVED $moved FAILED $failed INBOX_NOW=$($inbox.Items.Count)"
