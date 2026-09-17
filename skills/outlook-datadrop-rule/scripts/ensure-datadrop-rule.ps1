# Create or fix the Outlook receive rule that forwards Accutest LIMS
# mail to us.ehs.datadrop@sgs.com. That forward is what lands files in
# SharePoint Power Automate Updates. Never enables delete.
[CmdletBinding()]
param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$datadrop = if ($env:DATADROP_TO) { $env:DATADROP_TO } else { 'us.ehs.datadrop@sgs.com' }
$ruleName = 'Forward Accutest LIMS to datadrop'
$ol = New-Object -ComObject Outlook.Application
$ns = $ol.GetNamespace('MAPI')
$rules = $ns.DefaultStore.GetRules()

function Test-LimsRule($r) {
    if ($r.Name -eq $ruleName) { return $true }
    $from = ''
    try {
        if ($r.Conditions.From.Enabled) {
            for ($k = 1; $k -le $r.Conditions.From.Recipients.Count; $k++) {
                $from += [string]$r.Conditions.From.Recipients.Item($k).Address
                $from += [string]$r.Conditions.From.Recipients.Item($k).Name
            }
        }
    } catch {}
    return ($from -match 'idb0|seed2|Accutest.LIMS|accutest.lims|EHS.Accutest')
}

function Disable-Delete($r) {
    try {
        if ($r.Actions.Delete.Enabled) {
            $r.Actions.Delete.Enabled = $false
            Write-Output "OFF delete on $($r.Name)"
        }
    } catch {}
}

function Enable-Forward($r) {
    $fwd = $r.Actions.Forward
    $fwd.Enabled = $true
    $found = $false
    try {
        for ($k = 1; $k -le $fwd.Recipients.Count; $k++) {
            $addr = [string]$fwd.Recipients.Item($k).Address
            if ($addr -match 'datadrop') { $found = $true }
        }
    } catch {}
    if (-not $found) {
        [void]$fwd.Recipients.Add($datadrop)
        [void]$fwd.Recipients.ResolveAll()
        Write-Output "ADD forward $($r.Name) -> $datadrop"
    } else {
        Write-Output "KEEP forward $($r.Name)"
    }
}

$target = $null
for ($i = 1; $i -le $rules.Count; $i++) {
    $r = $rules.Item($i)
    if ($r.Name -eq $ruleName) { $target = $r; break }
}

if (-not $target) {
    if ($WhatIf) {
        Write-Output "WHATIF would create rule '$ruleName' forward $datadrop"
    } else {
        $target = $rules.Create($ruleName, 0)
        $target.Conditions.From.Enabled = $true
        foreach ($addr in @(
                'ehs.accutest.lims@sgs.com',
                'seed2@use-idb057.amr.global.sgs.com',
                'seed2@use-idb059.amr.global.sgs.com',
                'seed2@use-idb066.amr.global.sgs.com',
                'seed2@use-idb062.amr.global.sgs.com',
                'seed2@use-idb064.amr.global.sgs.com'
            )) {
            [void]$target.Conditions.From.Recipients.Add($addr)
        }
        [void]$target.Conditions.From.Recipients.ResolveAll()
        Write-Output "CREATE $ruleName"
    }
}

if ($target -and -not $WhatIf) {
    $target.Enabled = $true
    Disable-Delete $target
    Enable-Forward $target
}

for ($i = 1; $i -le $rules.Count; $i++) {
    $r = $rules.Item($i)
    if ($r -eq $target) { continue }
    if (-not (Test-LimsRule $r)) { continue }
    if ($WhatIf) {
        Write-Output "WHATIF would disable delete on $($r.Name)"
        continue
    }
    Disable-Delete $r
}

if (-not $WhatIf) {
    $rules.Save()
    Write-Output "SAVED rules. Recheck with check-datadrop-rule.ps1"
}
Write-Output "DATADROP=$datadrop"
