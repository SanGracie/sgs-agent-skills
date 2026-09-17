# Hands-off TAT-by-group Invoice Disk extract.
# Multiple labs = one AniTa window each, keys targeted by host title.
#
#   powershell -File run-tat-extract.ps1 -Lab all -From 2026-08
#   powershell -File run-tat-extract.ps1 -Lab dayton,orlando,houston -From 2026-09 -ThruDay 15
#   powershell -File run-tat-extract.ps1 -Lab all -ThisMonth -Sequential
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Lab,
    [string]$From,
    [int]$ThruDay,
    [switch]$ThisMonth,
    [string]$Groups,
    [switch]$WhatIf,
    [switch]$Sequential,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$login = Join-Path $scriptDir 'login-tat.ps1'
$export = Join-Path $scriptDir 'export-tat-groups.ps1'
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
New-Item -ItemType Directory -Force -Path $cap | Out-Null

$labOrder = @('wheatridge', 'dayton', 'orlando', 'scott', 'houston')
$labMap = @{
    wheatridge = @{ Host = 'use-idb057'; Invoice = 'i' }
    dayton     = @{ Host = 'use-idb059'; Invoice = 'i' }
    orlando    = @{ Host = 'use-idb066'; Invoice = 'i' }
    scott      = @{ Host = 'use-idb062'; Invoice = 'I' }
    houston    = @{ Host = 'use-idb064'; Invoice = 'I' }
}
$aliases = @{
    wheat = 'wheatridge'; wr = 'wheatridge'; co = 'wheatridge'; '057' = 'wheatridge'
    nj = 'dayton'; '059' = 'dayton'
    fla = 'orlando'; fl = 'orlando'; '066' = 'orlando'
    la = 'scott'; '062' = 'scott'
    tx = 'houston'; '064' = 'houston'
}

function Resolve-LabName([string]$raw) {
    $key = $raw.Trim().ToLowerInvariant()
    if ($aliases.ContainsKey($key)) { $key = $aliases[$key] }
    if (-not $labMap.ContainsKey($key)) {
        throw "Lab must be wheatridge, dayton, orlando, scott, houston, or all. Got $raw"
    }
    return $key
}

$tokens = @($Lab.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$resolved = New-Object System.Collections.Generic.List[string]
foreach ($token in $tokens) {
    $key = $token.Trim().ToLowerInvariant()
    if ($key -eq 'all' -or $key -eq '*') {
        foreach ($name in $labOrder) {
            if (-not $resolved.Contains($name)) { $resolved.Add($name) }
        }
        continue
    }
    $name = Resolve-LabName $token
    if (-not $resolved.Contains($name)) { $resolved.Add($name) }
}

$hasRange = [bool]($ThisMonth -or $From)
if (-not $hasRange) { $ThisMonth = $true }

Write-Output ("PLAN labs=" + ($resolved -join ',') + " parallel=" + (-not $Sequential -and $resolved.Count -gt 1))

if (-not $Sequential -and $resolved.Count -gt 1) {
    $self = $MyInvocation.MyCommand.Path
    $jobs = New-Object System.Collections.Generic.List[object]
    $n = 0
    foreach ($loc in $resolved) {
        $arg = "-NoProfile -File `"$self`" -Lab $loc"
        if ($From) { $arg += " -From $From" }
        if ($ThruDay) { $arg += " -ThruDay $ThruDay" }
        if ($ThisMonth) { $arg += " -ThisMonth" }
        if ($Groups) { $arg += " -Groups $Groups" }
        if ($WhatIf) { $arg += " -WhatIf" }
        if ($Force) { $arg += " -Force" }
        $log = Join-Path $cap ("run-tat-" + $loc + ".log")
        $err = Join-Path $cap ("run-tat-" + $loc + ".err")
        Write-Output "START $loc log=$log"
        if (-not $WhatIf) {
            $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $arg -RedirectStandardOutput $log -RedirectStandardError $err -PassThru -WindowStyle Hidden
            $jobs.Add([pscustomobject]@{ Lab = $loc; Proc = $p; Log = $log; Err = $err })
        }
        $n++
        if ($n -lt $resolved.Count) { Start-Sleep -Seconds 6 }
    }
    $failed = New-Object System.Collections.Generic.List[string]
    foreach ($job in $jobs) {
        $job.Proc.WaitForExit()
        $job.Proc.Refresh()
        $code = $job.Proc.ExitCode
        $logText = ''
        if (Test-Path $job.Log) { $logText = Get-Content -LiteralPath $job.Log -Raw }
        if ($null -eq $code) {
            $code = if ($logText -match "DONE loc=$($job.Lab)") { 0 } else { 1 }
        }
        Write-Output ("---- " + $job.Lab + " exit=" + $code + " ----")
        if ($logText) { Write-Output $logText.TrimEnd() }
        if (Test-Path $job.Err) {
            $errText = Get-Content -LiteralPath $job.Err -Raw
            if ($errText) { Write-Output $errText }
        }
        if ($code -ne 0) { $failed.Add($job.Lab) }
    }
    if ($failed.Count -gt 0) {
        throw ("FAILED labs=" + ($failed -join ','))
    }
    Write-Output ("DONE labs=" + ($resolved -join ','))
    return
}

foreach ($loc in $resolved) {
    $info = $labMap[$loc]
    Write-Output "LOGIN $loc $($info.Host)"
    if ($WhatIf) { continue }
    $logged = $false
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        try {
            $loginSplat = @{ HostName = $info.Host; Label = $loc; InvoiceKey = $info.Invoice }
            if ($Force) { $loginSplat.Force = $true }
            & $login @loginSplat
            if ($LASTEXITCODE -eq 0) { $logged = $true; break }
            throw "login-tat exit $LASTEXITCODE"
        } catch {
            Write-Output "LOGIN $loc attempt=$attempt failed: $($_.Exception.Message)"
            if ($attempt -ge 2) { throw }
            Start-Sleep -Seconds 8
        }
    }
    if (-not $logged) { throw "login-tat failed for $loc" }
    $splat = @{ Location = $loc; HostTitle = $info.Host }
    if ($Groups) { $splat.Groups = $Groups }
    if ($ThisMonth) { $splat.ThisMonth = $true }
    else {
        if ($From) { $splat.From = $From }
        if ($ThruDay) { $splat.ThruDay = $ThruDay }
    }
    & $export @splat
    if ($LASTEXITCODE -ne 0) { throw "export-tat-groups failed for $loc" }
}

Write-Output ("DONE labs=" + ($resolved -join ','))
