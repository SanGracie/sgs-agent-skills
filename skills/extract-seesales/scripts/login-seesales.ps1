# Headerless login to SEE SALES month list. No focus steal. No F11.
# Password only at Password: / Enter password:. Leaves the form on Month.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$HostName,
    [Parameter(Mandatory = $true)][string]$Label,
    [string]$InvoiceKey = 'i'
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..\..')).Path
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
$launch = Join-Path $scriptDir 'launch-anita-hidden.ps1'
$exe = Join-Path $cap 'anita-bg.exe'
$cs = Join-Path $scriptDir 'anita-bg.cs'
$reader = Join-Path $scriptDir 'read-anita-screen.py'
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

function Invoke-Bg {
    $out = & $exe @args 2>&1 | ForEach-Object { "$_" }
    $out | ForEach-Object { Write-Output $_ }
    if ($out -join "`n" -match 'Disconnected') { throw "AniTa disconnected ($HostName)" }
    return @{ Code = $LASTEXITCODE; Text = ($out -join "`n") }
}

function Read-Screen([string]$name) {
    [void](Invoke-Bg snap "$name.png" $HostName)
    $line = 'CLASS=empty KEYS=-'
    if (Test-Path $python) {
        $line = (& $python $reader "$name.png" 2>$null | Select-Object -Last 1)
        if (-not $line) { $line = 'CLASS=empty KEYS=-' }
    }
    Write-Output "SCREEN $name $line"
    return $line
}

function Get-Title {
    $p = Get-Process Anita -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -match [regex]::Escape($HostName) } |
        Select-Object -First 1
    if ($p) { return $p.MainWindowTitle }
    return ''
}

Get-Process Anita -ErrorAction SilentlyContinue | Where-Object {
    $_.MainWindowTitle -match [regex]::Escape($HostName)
} | Stop-Process
Start-Sleep -Seconds 2

& $launch -HostName $HostName -Label $Label
$deadline = (Get-Date).AddSeconds(45)
do {
    Start-Sleep -Seconds 2
    $title = Get-Title
    Write-Output "WAIT title=$title"
} while ((Get-Date) -lt $deadline -and ($title -match 'Connecting|Disconnected|auto-login' -or -not $title))
if ($title -match 'Disconnected' -or -not $title) { throw "AniTa did not connect ($HostName)" }

function Wait-Form([string]$name, [int]$seconds) {
    $deadline = (Get-Date).AddSeconds($seconds)
    $n = 0
    $line = 'CLASS=empty KEYS=-'
    do {
        Start-Sleep -Seconds 2
        $n++
        $line = Read-Screen "$name-$n"
        if ($line -match 'CLASS=form') { return $line }
    } while ((Get-Date) -lt $deadline)
    return $line
}

# AutoLogin usually lands on Password:. Do not send Enter first —
# Enter on Password: submits an empty password.
Start-Sleep -Seconds 8
[void](Read-Screen "$Label-login")
Write-Output 'TYPE linux password'
[void](Invoke-Bg type env:ANITA_PASSWORD enter $HostName)
$scr = Wait-Form "$Label-after-linux" 12
if ($scr -match 'CLASS=text') {
    Write-Output 'TYPE y for REMOVE? (text screen only; never on IFORMS form)'
    [void](Invoke-Bg type y enter $HostName)
    $scr = Wait-Form "$Label-after-remove" 16
}
if ($scr -notmatch 'CLASS=form') {
    throw "Did not reach IFORMS after linux login ($HostName)"
}
if ($scr -notmatch 'KEYS=(menu|seesales)') {
    Write-Output 'TYPE IFORMS password'
    [void](Invoke-Bg type env:ANITA_PASSWORD enter $HostName)
    Start-Sleep -Seconds 6
    $scr = Read-Screen "$Label-menu"
}

Write-Output "OPEN Invoice hotkey=$InvoiceKey then See Sales"
[void](Invoke-Bg type $InvoiceKey $HostName)
Start-Sleep -Seconds 3
[void](Invoke-Bg key 13 $HostName)
Start-Sleep -Seconds 6
[void](Read-Screen "$Label-seesales")

$st = Invoke-Bg status $HostName
if ($st.Text -match 'Disconnected') { throw "AniTa disconnected after See Sales ($HostName)" }
Write-Output "PARK $HostName after IFORMS (never during Password:)"
[void](Invoke-Bg park $HostName)
Write-Output "LOGIN_OK $HostName $Label on SEE SALES month list"
