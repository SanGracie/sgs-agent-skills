# Report Outlook rules that touch Accutest LIMS / AniTa host mail.
# SharePoint Power Automate Updates only happens if one of them
# forwards to us.ehs.datadrop@sgs.com (not delete).
$ErrorActionPreference = 'Stop'
$ol = New-Object -ComObject Outlook.Application
$ns = $ol.GetNamespace('MAPI')
$rules = $ns.DefaultStore.GetRules()
$datadrop = if ($env:DATADROP_TO) { $env:DATADROP_TO } else { 'us.ehs.datadrop@sgs.com' }

Write-Output "PROFILE=$($ol.Session.CurrentUser.Name)"
Write-Output "DATADROP=$datadrop"
$forwardOk = $false
$deleteOn = $false
for ($i = 1; $i -le $rules.Count; $i++) {
    $r = $rules.Item($i)
    $from = ''
    try {
        if ($r.Conditions.From.Enabled) {
            $names = @()
            for ($k = 1; $k -le $r.Conditions.From.Recipients.Count; $k++) {
                $rec = $r.Conditions.From.Recipients.Item($k)
                $bit = [string]$rec.Address
                if (-not $bit) { $bit = [string]$rec.Name }
                $names += $bit
            }
            $from = $names -join ','
        }
    } catch {}
    $subj = ''
    try {
        if ($r.Conditions.Subject.Enabled) {
            $subj = [string]::Join(',', @($r.Conditions.Subject.Text))
        }
    } catch {}
    $hit = ($from -match 'idb0|seed2|Accutest.LIMS|accutest.lims|EHS.Accutest') -or
        ($subj -match 'SEE SALES|SeeSales|Invoice Disk|tat-sg|TAT') -or
        ($r.Name -match 'datadrop|LIMS|Accutest|SeeSales|TAT')
    if (-not $hit) { continue }
    $acts = @()
    for ($j = 1; $j -le $r.Actions.Count; $j++) {
        $act = $r.Actions.Item($j)
        if (-not $act.Enabled) { continue }
        $bit = "t$($act.ActionType)"
        try { if ($act.Folder) { $bit += ":$($act.Folder.Name)" } } catch {}
        try {
            if ($act.Recipients -and $act.Recipients.Count -gt 0) {
                $addr = [string]$act.Recipients.Item(1).Address
                if (-not $addr) { $addr = [string]$act.Recipients.Item(1).Name }
                $bit += ":$addr"
                if ($addr -match [regex]::Escape($datadrop) -or $addr -match 'datadrop') {
                    $forwardOk = $true
                }
            }
        } catch {}
        $acts += $bit
    }
    Write-Output ("RULE enabled=$($r.Enabled) name=$($r.Name) from=$from subj=$subj => $($acts -join '; ')")
    if ($acts -match 'Deleted|t3') {
        $deleteOn = $true
        Write-Output 'FAIL: rule still deletes. Forward to datadrop and disable Move to Deleted Items.'
    }
}
if ($forwardOk -and -not $deleteOn) {
    Write-Output "OK forward-to-datadrop is on. Files land in Power Automate Updates."
} elseif (-not $forwardOk) {
    Write-Output "MISSING forward to $datadrop. Run ensure-datadrop-rule.ps1 or files stay in Inbox."
}
