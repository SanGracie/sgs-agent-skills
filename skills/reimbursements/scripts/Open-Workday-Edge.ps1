# Open SGS Workday Create Expense Report in real Edge.
# Cursor's helper window cannot finish SGS Windows sign-in (blank/black page).
# Usage: powershell -File .cursor/skills/reimbursements/scripts/Open-Workday-Edge.ps1
# After it opens, agents can attach to http://127.0.0.1:9222

$ErrorActionPreference = "Stop"

$dir = $PSScriptRoot
$envFile = $null
while ($dir) {
    $candidate = Join-Path $dir ".env"
    if (Test-Path -LiteralPath $candidate) {
        $envFile = $candidate
        break
    }
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
}

if ($envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $name = $line.Substring(0, $eq).Trim()
        $value = $line.Substring($eq + 1).Trim()
        if (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'"))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        Set-Item -Path "Env:$name" -Value $value
    }
}

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path -LiteralPath $edge)) {
    $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path -LiteralPath $edge)) {
    throw "Microsoft Edge was not found."
}

$url = $env:EXPENSE_URL
if ([string]::IsNullOrWhiteSpace($url)) {
    $url = "https://wd3.myworkday.com/sgs/d/task/2997`$728.htmld"
}

$profileName = $env:WORKDAY_EDGE_PROFILE
if ([string]::IsNullOrWhiteSpace($profileName)) {
    $profileName = "SgsWorkdayEdge"
}
$profile = Join-Path $env:LOCALAPPDATA $profileName
New-Item -ItemType Directory -Force -Path $profile | Out-Null

$alreadyOpen = $false
try {
    Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2 | Out-Null
    $alreadyOpen = $true
} catch {
    $alreadyOpen = $false
}

if (-not $alreadyOpen) {
    Start-Process -FilePath $edge -ArgumentList @(
        "--remote-debugging-port=9222",
        "--remote-allow-origins=*",
        "--user-data-dir=$profile",
        "--no-first-run",
        "--no-default-browser-check",
        $url
    )
}

$ok = $false
foreach ($i in 1..20) {
    try {
        Invoke-WebRequest -Uri "http://127.0.0.1:9222/json/version" -UseBasicParsing -TimeoutSec 2 | Out-Null
        $ok = $true
        break
    } catch {
        Start-Sleep -Milliseconds 400
    }
}

if (-not $ok) {
    throw "Edge opened but the agent could not attach. Ask the person if a company prompt is blocking it."
}

Write-Output "Edge is ready for Workday."
