# Report SeeSales-related Outlook rules and recent matching mail.
$ErrorActionPreference = 'Stop'
$ol = New-Object -ComObject Outlook.Application
$ns = $ol.GetNamespace('MAPI')
$rules = $ns.DefaultStore.GetRules()
$datadrop = if ($env:DATADROP_TO) { $env:DATADROP_TO } else { 'us.ehs.datadrop@sgs.com' }

Write-Output "PROFILE=$($ol.Session.CurrentUser.Name)"
Write-Output "DATADROP=$datadrop"
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
    $acts = @()
    for ($j = 1; $j -le $r.Actions.Count; $j++) {
        $act = $r.Actions.Item($j)
        if (-not $act.Enabled) { continue }
        $bit = "t$($act.ActionType)"
        try { if ($act.Folder) { $bit += ":$($act.Folder.Name)" } } catch {}
        try {
            if ($act.Recipients -and $act.Recipients.Count -gt 0) {
                $bit += ":$($act.Recipients.Item(1).Address)"
            }
        } catch {}
        $acts += $bit
    }
    $line = "RULE enabled=$($r.Enabled) from=$from => $($acts -join '; ')"
    Write-Output $line
    if ($acts -match 'Deleted') {
        Write-Output 'FAIL: rule still deletes. Forward to datadrop and disable Move to Deleted Items.'
    }
}

function Show-Folder($folder, $label) {
    $items = $folder.Items
    $items.Sort('[ReceivedTime]', $true)
    Write-Output "=== $label newest $($items.Count) (scan 30) ==="
    $n = [Math]::Min(30, $items.Count)
    for ($i = 1; $i -le $n; $i++) {
        $it = $items.Item($i)
        $from = ''
        try { $from = [string]$it.SenderEmailAddress } catch {}
        if ("$from $($it.Subject)" -notmatch 'SeeSales|SEE SALES|seed2|idb057|Accutest.LIMS') { continue }
        Write-Output ("{0:yyyy-MM-dd HH:mm} | {1} | {2}" -f $it.ReceivedTime, $from, $it.Subject)
    }
}
Show-Folder ($ns.GetDefaultFolder(6)) 'Inbox'
Show-Folder ($ns.GetDefaultFolder(3)) 'Deleted'
