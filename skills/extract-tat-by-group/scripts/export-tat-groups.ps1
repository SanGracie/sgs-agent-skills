# Queue TAT-by-group Invoice Disk extracts. One calendar month only.
# Prerequisite: AniTa is on INVOICE DISC GENERATION, cursor on Billing Date.
# Picks tat-sg with End, then Down-arrow to each group (Find-by-code
# misses GCU/MSU). Does not steal focus.
#
#   powershell -File export-tat-groups.ps1 -Location wheatridge -From 2026-09 -ThruDay 15
#   powershell -File export-tat-groups.ps1 -Location houston -ThisMonth
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Location,
    [string]$Groups,
    [string]$From,
    [int]$ThruDay,
    [switch]$ThisMonth,
    [string]$HostTitle,
    [int]$AfterMs = 2000,
    [int]$StartDown = 0,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$seeDir = Join-Path $scriptDir '..\..\extract-seesales\scripts'
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
$exe = Join-Path $cap 'anita-bg.exe'
$cs = Join-Path $seeDir 'anita-bg.cs'
$reader = Join-Path $seeDir 'read-anita-screen.py'
$python = 'C:\Program Files\Python311\python.exe'
New-Item -ItemType Directory -Force -Path $cap | Out-Null

$labMap = @{
    wheatridge = @{ Host = 'use-idb057'; Groups = 'FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB' }
    dayton     = @{ Host = 'use-idb059'; Groups = 'FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB' }
    orlando    = @{ Host = 'use-idb066'; Groups = 'FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB' }
    scott      = @{ Host = 'use-idb062'; Groups = 'FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB' }
    houston    = @{ Host = 'use-idb064'; Groups = 'FLD,GCA,GCS,GCU,GEN,LCMS,MET,MISC,MSA,MSS,MSU,SUB' }
}
$key = $Location.Trim().ToLowerInvariant()
$aliases = @{
    wheat = 'wheatridge'; wr = 'wheatridge'; co = 'wheatridge'; '057' = 'wheatridge'
    nj = 'dayton'; '059' = 'dayton'
    fla = 'orlando'; fl = 'orlando'; '066' = 'orlando'
    la = 'scott'; '062' = 'scott'
    tx = 'houston'; '064' = 'houston'
}
if ($aliases.ContainsKey($key)) { $key = $aliases[$key] }
if (-not $labMap.ContainsKey($key)) { throw "Location must be a lab name. Got $Location" }
if (-not $HostTitle) { $HostTitle = $labMap[$key].Host }

$groupArg = if ($Groups) { $Groups } else { $labMap[$key].Groups }
$groupList = @($groupArg.Split(',') | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ })
if ($groupList.Count -lt 1) { throw 'Pass -Groups as comma codes in list order.' }

$usNow = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Central Standard Time')
if ($ThisMonth -or -not $From) {
    $From = '{0:yyyy-MM}' -f $usNow
}
if ($From -notmatch '^(20\d{2})-(0[1-9]|1[0-2])$') {
    throw "From must be YYYY-MM (got '$From')."
}
$year = [int]$Matches[1]
$month = [int]$Matches[2]
$lastDay = [DateTime]::DaysInMonth($year, $month)
$usToday = Get-Date -Year $usNow.Year -Month $usNow.Month -Day $usNow.Day
$monthStart = Get-Date -Year $year -Month $month -Day 1
if (-not $ThruDay) {
    if ($monthStart.Year -eq $usToday.Year -and $monthStart.Month -eq $usToday.Month) {
        $ThruDay = $usToday.Day
    } else {
        $ThruDay = $lastDay
    }
}
if ($ThruDay -lt 1 -or $ThruDay -gt $lastDay) {
    throw "ThruDay $ThruDay is not in $From (1..$lastDay)."
}
$thruDate = Get-Date -Year $year -Month $month -Day $ThruDay
if ($thruDate.Date -gt $usToday.Date) {
    throw "Thru $($thruDate.ToString('dd-MMM-yyyy')) is in the future for US Central ($($usToday.ToString('yyyy-MM-dd')))."
}

$months = 'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'
$fromText = '01-{0}-{1}' -f $months[$month - 1], $year
$thruText = '{0:00}-{1}-{2}' -f $ThruDay, $months[$month - 1], $year

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$needBuild = -not (Test-Path $exe) -or ((Get-Item $cs).LastWriteTimeUtc -gt (Get-Item $exe).LastWriteTimeUtc)
if ($needBuild) {
    & $csc /nologo /target:exe /out:$exe /r:System.Drawing.dll $cs
    if ($LASTEXITCODE -ne 0) { throw 'anita-bg compile failed' }
}

function Invoke-Bg {
    $out = & $exe @args 2>&1 | ForEach-Object { "$_" }
    $out | ForEach-Object { [Console]::Out.WriteLine($_) }
    if ($out -join "`n" -match 'Disconnected') { throw "AniTa disconnected ($HostTitle)" }
}

function Read-Screen([string]$name) {
    [void](Invoke-Bg snap "$name.png" $HostTitle)
    $line = 'CLASS=empty KEYS=-'
    if (Test-Path $python) {
        $line = (& $python $reader "$name.png" 2>$null | Select-Object -Last 1)
        if (-not $line) { $line = 'CLASS=empty KEYS=-' }
    }
    [Console]::Out.WriteLine("SCREEN $name $line")
    return $line
}

function Ready-CanvasBytes([string]$name) {
    $p = Join-Path $cap ($name + '-canvas.png')
    if (Test-Path $p) { return (Get-Item $p).Length }
    return 0
}

Write-Output "PLAN loc=$key host=$HostTitle from=$fromText thru=$thruText groups=$($groupList -join ',')"
if ($WhatIf) { return }

$idx = [Math]::Max(0, $StartDown)
foreach ($grp in $groupList) {
    Write-Output "GROUP $grp downs=$idx"
    [void](Invoke-Bg chars $fromText $HostTitle)
    Start-Sleep -Milliseconds $AfterMs
    $start = Read-Screen "tat-$key-$grp-start"
    if ($start -match 'future') {
        throw "Future-date warning while setting start ${fromText} for ${grp}."
    }
    if ($start -match 'KEYS=(password|iforms|invaliduser|needaccount)') {
        throw "GROUP ${grp} start screen is not Invoice Disk. ${start}"
    }
    [void](Invoke-Bg key 9 $HostTitle)
    Start-Sleep -Milliseconds $AfterMs
    [void](Invoke-Bg chars tat-sg $HostTitle)
    Start-Sleep -Seconds 1
    [void](Invoke-Bg key 35 $HostTitle)
    Start-Sleep -Seconds 2
    for ($d = 0; $d -lt $idx; $d++) {
        [void](Invoke-Bg key 40 $HostTitle)
        Start-Sleep -Milliseconds 350
    }
    [void](Invoke-Bg key 35 $HostTitle)
    Start-Sleep -Seconds 1
    # Thru is empty after picking the group. Do not Home (jumps fields /
    # sends '$') or F4 (opens invoice Find, not the date picker).
    [void](Invoke-Bg chars $thruText $HostTitle)
    Start-Sleep -Seconds 2
    $ready = 'CLASS=empty KEYS=-'
    $bytes = 0
    for ($try = 1; $try -le 8; $try++) {
        $ready = Read-Screen "tat-$key-$grp-ready"
        $bytes = Ready-CanvasBytes "tat-$key-$grp-ready"
        if ($ready -match 'future') {
            throw "Future-date warning before End on ${grp}. Thru was ${thruText}."
        }
        if ($ready -match 'KEYS=(password|iforms|invaliduser|needaccount)') {
            throw "GROUP ${grp} ready screen is not a filled Invoice Disk. ${ready}"
        }
        if ($bytes -le 0 -or $bytes -ge 40000) { break }
        Write-Output "GROUP ${grp} ready snap still painting (${bytes} bytes) retry=${try}"
        Start-Sleep -Seconds 4
    }
    if ($bytes -gt 0 -and $bytes -lt 40000) {
        throw "GROUP ${grp} ready snap looks empty (${bytes} bytes). Did not End."
    }
    [void](Invoke-Bg key 35 $HostTitle)
    Start-Sleep -Seconds 2
    $done = Read-Screen "tat-$key-$grp-end"
    if ($done -match 'future') {
        [void](Invoke-Bg key 13 $HostTitle)
        throw ("LIMS rejected {0} (invoice date in the future, thru={1})." -f $grp, $thruText)
    }
    if ($done -match 'KEYS=(password|iforms|invaliduser|needaccount)') {
        throw "GROUP ${grp} End did not queue. ${done}"
    }
    Write-Output "GROUP ${grp} queued bytes=$bytes ${done}"
    Start-Sleep -Seconds 1
    $idx++
}

Write-Output "DONE loc=$key month=$From thru=$thruText count=$($groupList.Count)"
