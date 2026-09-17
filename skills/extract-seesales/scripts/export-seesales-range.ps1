# Export one SEE SALES calendar month per file for a From/To range.
# Prerequisite: AniTa is already on the SEE SALES month list, cursor on Month.
# Does not steal focus. Confirm files on SharePoint, not Inbox.
[CmdletBinding()]
param(
    [string]$From,
    [string]$To,
    [switch]$Ytd,
    [switch]$ThisMonth,
    [string]$OnMonth,
    [int]$ExportWaitSeconds = 35,
    [int]$AfterDownMs = 1500,
    [switch]$SkipSharePoint,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..\..')).Path
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
New-Item -ItemType Directory -Force -Path $cap | Out-Null

function Import-RepoEnv([string]$path) {
    if (-not (Test-Path $path)) { return }
    Get-Content -LiteralPath $path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) { return }
        $eq = $line.IndexOf('=')
        if ($eq -lt 1) { return }
        $k = $line.Substring(0, $eq).Trim()
        $v = $line.Substring($eq + 1).Trim().Trim('"').Trim("'")
        if (-not [Environment]::GetEnvironmentVariable($k, 'Process')) {
            [Environment]::SetEnvironmentVariable($k, $v, 'Process')
        }
    }
}
Import-RepoEnv (Join-Path $repoRoot '.env')

function Parse-YearMonth([string]$value, [string]$name) {
    if (-not $value) { throw "$name is required (YYYY-MM), or use -Ytd / -ThisMonth." }
    if ($value -notmatch '^(20\d{2})-(0[1-9]|1[0-2])$') {
        throw "$name must be YYYY-MM (got '$value')."
    }
    return Get-Date -Year ([int]$Matches[1]) -Month ([int]$Matches[2]) -Day 1
}

$now = Get-Date
if ($Ytd) {
    $fromDate = Get-Date -Year $now.Year -Month 1 -Day 1
    $toDate = Get-Date -Year $now.Year -Month $now.Month -Day 1
} elseif ($ThisMonth) {
    $fromDate = Get-Date -Year $now.Year -Month $now.Month -Day 1
    $toDate = $fromDate
} else {
    $fromDate = Parse-YearMonth $From 'From'
    $toDate = Parse-YearMonth $To 'To'
}
if ($fromDate -gt $toDate) { throw "From $($fromDate.ToString('yyyy-MM')) is after To $($toDate.ToString('yyyy-MM'))." }

$onDate = if ($OnMonth) { Parse-YearMonth $OnMonth 'OnMonth' } else { Get-Date -Year $now.Year -Month $now.Month -Day 1 }

$months = New-Object System.Collections.Generic.List[datetime]
$cursor = $toDate
while ($cursor -ge $fromDate) {
    $months.Add($cursor)
    $cursor = $cursor.AddMonths(-1)
}

function MonthIndex([datetime]$d) { return ($d.Year * 12) + $d.Month }
$navSteps = (MonthIndex $onDate) - (MonthIndex $toDate)

Write-Output "PLAN months=$($months.Count) from=$($fromDate.ToString('yyyy-MM')) to=$($toDate.ToString('yyyy-MM')) on=$($onDate.ToString('yyyy-MM')) navSteps=$navSteps (Down if +, Up if -)"
Write-Output (("months " + (($months | ForEach-Object { $_.ToString('yyyy-MM') }) -join ', ')))

if ($WhatIf) { return }

function Ensure-AnitaBg {
    $exe = Join-Path $cap 'anita-bg.exe'
    $src = Join-Path $scriptDir 'anita-bg.cs'
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (-not (Test-Path $csc)) { throw "csc.exe not found at $csc" }
    $needBuild = -not (Test-Path $exe) -or ((Get-Item $src).LastWriteTimeUtc -gt (Get-Item $exe).LastWriteTimeUtc)
    if ($needBuild) {
        & $csc /nologo /target:exe /out:$exe /r:System.Drawing.dll $src
        if ($LASTEXITCODE -ne 0) { throw 'Failed to compile anita-bg.exe' }
    }
    return $exe
}

function Invoke-Anita([string]$exe) {
    $argList = $args
    $out = & $exe @argList 2>&1 | ForEach-Object { "$_" }
    $out | ForEach-Object { Write-Output $_ }
    return @{ Code = $LASTEXITCODE; Text = ($out -join "`n") }
}

$bg = Ensure-AnitaBg
$st = Invoke-Anita $bg 'status'
if ($st.Text -match 'no AniTa') { throw 'AniTa is not running. Open SEE SALES first, then rerun.' }
if ($st.Text -match 'Disconnected' -or $st.Code -eq 4) { throw 'AniTa title is Disconnected. Relogin to use-idb057, open SEE SALES, then rerun.' }

function Send-DownOrUp([int]$count) {
    if ($count -eq 0) { return }
    $vk = if ($count -gt 0) { 40 } else { 38 }
    $n = [Math]::Abs($count)
    for ($i = 0; $i -lt $n; $i++) {
        [void](Invoke-Anita $bg 'key' "$vk")
        Start-Sleep -Milliseconds $AfterDownMs
    }
}

Write-Output "NAVIGATE $navSteps steps to $($toDate.ToString('yyyy-MM'))"
Send-DownOrUp $navSteps
Start-Sleep -Milliseconds $AfterDownMs
[void](Invoke-Anita $bg 'snap' 'range-start.png')

$done = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $months.Count; $i++) {
    $m = $months[$i]
    $label = $m.ToString('yyyy-MM')
    Write-Output "EXPORT $label ($($i + 1)/$($months.Count))"
    $sent = Invoke-Anita $bg 'host' '\x1b}s2,20\r'
    if ($sent.Code -ne 0) { throw "Export send failed for $label" }

    $deadline = (Get-Date).AddSeconds($ExportWaitSeconds)
    $poll = 0
    do {
        Start-Sleep -Seconds 4
        $poll++
        $snapName = "range-$label-$poll.png"
        $pollOut = Invoke-Anita $bg 'snap' $snapName
        $stat = Invoke-Anita $bg 'status'
        if ($stat.Text -match 'Disconnected') { throw "AniTa disconnected during $label" }
        # DONE is painted on the AniTa canvas, not in the status-bar control.
        Write-Output "  wait $label poll=$poll snap=$snapName"
    } while ((Get-Date) -lt $deadline)

    if ($stat.Text -match 'Disconnected') { throw "AniTa disconnected during $label" }
    Write-Output "WAITED $label ${ExportWaitSeconds}s (confirm snap $snapName / SharePoint)"
    $done.Add($label)

    if ($i -lt $months.Count - 1) {
        Send-DownOrUp 1
    }
}

Write-Output "EXPORT_FINISHED count=$($done.Count) months=$($done -join ',')"
Write-Output "Next: confirm SharePoint EHS KPI Data/Power Automate Updates/<today>/ seesales-seesales-loganb_*.xls"

if (-not $SkipSharePoint) {
    $py = Join-Path $scriptDir 'check-sharepoint-seesales.py'
    $pythonExe = $null
    foreach ($candidate in @(
            (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
            (Get-Command py -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
            'C:\Program Files\Python311\python.exe'
        )) {
        if ($candidate -and (Test-Path $candidate)) { $pythonExe = $candidate; break }
    }
    if (Test-Path $py) {
        Write-Output 'Waiting 90s for Power Automate, then listing SharePoint...'
        Start-Sleep -Seconds 90
        if ($pythonExe) {
            & $pythonExe $py --expect $months.Count
        } else {
            Write-Output 'WARN: python not on PATH - run check-sharepoint-seesales.py yourself.'
        }
    }
}
