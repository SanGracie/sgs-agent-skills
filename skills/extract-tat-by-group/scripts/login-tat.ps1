# Headerless login to Invoice Disc Generation. No focus steal.
# Same login as SEE SALES through ACCULIMS Main Menu, then Invoice
# and Down to Invoice Disk (See Sales is first).
# Reuses a live host (Invoice Disk, menu, or IFORMS password).
# Retries snaps through a brief post-password disconnect.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HostName,
    [Parameter(Mandatory = $true)][string]$Label,
    [string]$InvoiceKey = 'i',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$seeDir = Join-Path $scriptDir '..\..\extract-seesales\scripts'
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..\..')).Path
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
$launch = Join-Path $seeDir 'launch-anita-hidden.ps1'
$exe = Join-Path $cap 'anita-bg.exe'
$cs = Join-Path $seeDir 'anita-bg.cs'
$reader = Join-Path $seeDir 'read-anita-screen.py'
$python = 'C:\Program Files\Python311\python.exe'

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
if (-not [Environment]::GetEnvironmentVariable('ANITA_PASSWORD', 'Process')) {
    throw 'ANITA_PASSWORD is empty. Load repo .env or set the process env.'
}

$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$needBuild = -not (Test-Path $exe) -or ((Get-Item $cs).LastWriteTimeUtc -gt (Get-Item $exe).LastWriteTimeUtc)
if ($needBuild) {
    & $csc /nologo /target:exe /out:$exe /r:System.Drawing.dll $cs
    if ($LASTEXITCODE -ne 0) { throw 'anita-bg compile failed' }
}

function Get-Title {
    $p = Get-Process Anita -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -match [regex]::Escape($HostName) } |
        Select-Object -First 1
    if ($p) { return $p.MainWindowTitle }
    return ''
}

function Invoke-Bg {
    $last = ''
    for ($try = 1; $try -le 5; $try++) {
        $out = & $exe @args 2>&1 | ForEach-Object { "$_" }
        $last = $out -join "`n"
        if ($last -notmatch 'Disconnected') {
            $out | ForEach-Object { [Console]::Out.WriteLine($_) }
            return @{ Code = $LASTEXITCODE; Text = $last }
        }
        $title = Get-Title
        [Console]::Out.WriteLine("RETRY snap/status try=$try disconnected title=$title")
        if ($title -match 'Disconnected' -and $try -ge 3) { break }
        Start-Sleep -Seconds 3
    }
    $last -split "`n" | ForEach-Object { Write-Output $_ }
    throw "AniTa disconnected ($HostName)"
}

function Read-Screen([string]$name) {
    [void](Invoke-Bg snap "$name.png" $HostName)
    $line = 'CLASS=empty KEYS=-'
    if (Test-Path $python) {
        $line = (& $python $reader "$name.png" 2>$null | Select-Object -Last 1)
        if (-not $line) { $line = 'CLASS=empty KEYS=-' }
    }
    [Console]::Out.WriteLine("SCREEN $name $line")
    return $line
}

function Wait-Form([string]$name, [int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    $n = 0
    $line = 'CLASS=empty KEYS=-'
    do {
        Start-Sleep -Seconds 2
        $n++
        $line = Read-Screen "$name-$n"
        if ($line -match 'CLASS=form' -or $line -match 'CLASS=logon') { return $line }
        if ($line -match 'KEYS=remove' -or $line -match 'CLASS=text') { return $line }
    } while ((Get-Date) -lt $deadline)
    return $line
}

function Send-IformsPassword([string]$tag) {
    Write-Output 'TYPE IFORMS password'
    [void](Invoke-Bg type env:ANITA_PASSWORD enter $HostName)
    Start-Sleep -Seconds 8
    $scr = Read-Screen "$tag-after-iforms"
    if ($scr -match 'KEYS=remove' -or $scr -match 'CLASS=text') {
        Write-Output 'TYPE y for REMOVE? (text screen only; never on IFORMS form)'
        [void](Invoke-Bg type y enter $HostName)
        $scr = Wait-Form "$tag-after-remove" 20
    }
    return $scr
}

function Open-InvoiceDisk([string]$scr) {
    if ($scr -match 'CLASS=logon' -or $scr -match 'KEYS=(password|iforms|invaliduser)') {
        $scr = Send-IformsPassword "$Label-open"
    }
    $menuWait = (Get-Date).AddSeconds(20)
    while ($scr -match 'CLASS=logon|KEYS=password' -and (Get-Date) -lt $menuWait) {
        Start-Sleep -Seconds 2
        $scr = Read-Screen "$Label-menu-wait"
    }
    if ($scr -match 'CLASS=logon' -or ($scr -match 'KEYS=(password|iforms)' -and $scr -notmatch 'KEYS=(menu|seesales|invoicedisk)')) {
        throw "Still on IFORMS Log On ($HostName). Not sending Invoice keys."
    }
    if ($scr -notmatch 'CLASS=form') {
        throw "Did not reach ACCULIMS Main Menu ($HostName). Not sending Invoice keys."
    }
    if ($scr -match 'KEYS=invoicedisk') {
        Write-Output "ALREADY on Invoice Disk"
        return
    }
    Write-Output "OPEN Invoice hotkey=$InvoiceKey then Down to Invoice Disk"
    [void](Invoke-Bg type $InvoiceKey $HostName)
    Start-Sleep -Seconds 3
    [void](Invoke-Bg key 40 $HostName)
    Start-Sleep -Seconds 1
    [void](Invoke-Bg key 13 $HostName)
    Start-Sleep -Seconds 6
    $disk = Read-Screen "$Label-invoicedisk"
    if ($disk -match 'KEYS=(password|iforms)' -and $disk -notmatch 'KEYS=invoicedisk') {
        throw "Invoice Disk open landed on IFORMS Log On ($HostName)."
    }
    # OCR often misses "invoice disc" on the blue form. CLASS=form
    # after Invoice keys is enough; export will overwrite the date.
}

function Connect-Fresh {
    Get-Process Anita -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -match [regex]::Escape($HostName)
    } | Stop-Process
    Start-Sleep -Seconds 4

    & $launch -HostName $HostName -Label $Label
    $deadline = (Get-Date).AddSeconds(45)
    do {
        Start-Sleep -Seconds 2
        $title = Get-Title
        Write-Output "WAIT title=$title"
    } while ((Get-Date) -lt $deadline -and ($title -match 'Connecting|Disconnected|auto-login' -or -not $title))
    if ($title -match 'Disconnected' -or -not $title) { throw "AniTa did not connect ($HostName)" }

    Start-Sleep -Seconds 8
    $scr = Read-Screen "$Label-login"
    if ($scr -match 'CLASS=logon' -or $scr -match 'KEYS=password' -or $scr -match 'KEYS=iforms') {
        $scr = Send-IformsPassword "$Label-login"
    } elseif ($scr -notmatch 'CLASS=form') {
        Write-Output 'TYPE linux password'
        [void](Invoke-Bg type env:ANITA_PASSWORD enter $HostName)
        $scr = Wait-Form "$Label-after-linux" 20
    }
    if ($scr -match 'KEYS=remove' -or $scr -match 'CLASS=text') {
        Write-Output 'TYPE y for REMOVE? (text screen only; never on IFORMS form)'
        [void](Invoke-Bg type y enter $HostName)
        $scr = Wait-Form "$Label-after-remove" 20
    }
    if ($scr -notmatch 'CLASS=form') {
        throw "Did not reach IFORMS after linux login ($HostName)"
    }
    if ($scr -match 'KEYS=password' -or $scr -notmatch 'KEYS=(menu|seesales|invoicedisk)') {
        $scr = Send-IformsPassword $Label
    }
    Open-InvoiceDisk $scr
}

$title = Get-Title
if (-not $Force -and $title -and $title -notmatch 'Disconnected|Connecting|auto-login') {
    Write-Output "REUSE title=$title"
    $scr = Read-Screen "$Label-reuse"
    if ($scr -match 'CLASS=logon' -or $scr -match 'KEYS=(password|iforms|invaliduser)') {
        $scr = Send-IformsPassword "$Label-reuse"
        Open-InvoiceDisk $scr
    } elseif ($scr -match 'KEYS=invoicedisk' -and $scr -notmatch 'KEYS=needaccount') {
        Write-Output "REUSE Invoice Disk"
    } elseif ($scr -match 'KEYS=(menu|seesales)') {
        Open-InvoiceDisk $scr
    } else {
        Write-Output 'REUSE skipped (dirty or unknown form), relaunch'
        Connect-Fresh
    }
} else {
    if ($Force) { Write-Output 'FORCE fresh login' }
    Connect-Fresh
}

$st = Invoke-Bg status $HostName
if ($st.Text -match 'Disconnected') { throw "AniTa disconnected after Invoice Disk ($HostName)" }
Write-Output "PARK $HostName after IFORMS (never during Password:)"
[void](Invoke-Bg park $HostName)
Write-Output "LOGIN_OK $HostName $Label on Invoice Disk"
