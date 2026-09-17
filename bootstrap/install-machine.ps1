#Requires -Version 5.1
<#
.SYNOPSIS
  Full-track machine setup for SGS agent skills (IT / Logan).

.DESCRIPTION
  Installs Python 3.13 (user-scope winget when possible), GitHub CLI,
  and pip packages from this library plus the target repo if present.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRoot,
    [string]$LibraryRoot = ""
)

$ErrorActionPreference = 'Stop'
if (-not $LibraryRoot) {
    $LibraryRoot = Split-Path -Parent $PSScriptRoot
}
$LibraryRoot = (Resolve-Path $LibraryRoot).Path
$TargetRoot = (Resolve-Path $TargetRoot).Path
$libReq = Join-Path $LibraryRoot "bootstrap\requirements.txt"

function Test-Cmd([string]$Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PythonExe {
    foreach ($c in @('py', 'python3', 'python')) {
        if (Test-Cmd $c) { return $c }
    }
    return $null
}

function Get-PythonVersion([string]$Exe) {
    try {
        if ($Exe -eq 'py') {
            return ((& py -3 -c "import sys; print('%s.%s' % (sys.version_info.major, sys.version_info.minor))") | Out-String).Trim()
        }
        return ((& $Exe -c "import sys; print('%s.%s' % (sys.version_info.major, sys.version_info.minor))") | Out-String).Trim()
    } catch {
        return $null
    }
}

function Invoke-Pip {
    param([string[]]$PipArgs)
    $py = Get-PythonExe
    if ($py -eq 'py') {
        & py -3 -m pip @PipArgs
    } else {
        & $py -m pip @PipArgs
    }
    if ($LASTEXITCODE -ne 0) { throw "pip failed: $PipArgs" }
}

Write-Host "Library: $LibraryRoot"
Write-Host "Target:  $TargetRoot"

$py = Get-PythonExe
$ver = $null
if ($py) { $ver = Get-PythonVersion $py }
$pyLabel = if ($py) { $py } else { 'none' }
Write-Host "Python now: $pyLabel $ver"

$installPy = $false
if (-not $ver) {
    $installPy = $true
} else {
    try {
        if ([version]$ver -lt [version]'3.13') { $installPy = $true }
    } catch {
        $installPy = $true
    }
}

if ($installPy) {
    if (Test-Cmd 'winget') {
        Write-Host "Installing Python.Python.3.13 (user scope)..."
        winget install --id Python.Python.3.13 -e --scope user --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        $py = Get-PythonExe
        $ver = $null
        if ($py) { $ver = Get-PythonVersion $py }
        $pyLabel = if ($py) { $py } else { 'none' }
        Write-Host "Python after install: $pyLabel $ver"
    } else {
        Write-Warning "winget not found. Install Python 3.13 by hand: https://www.python.org/downloads/"
    }
}

if (-not (Get-PythonExe)) {
    throw "Python is still missing. Keep the file setup and have IT install Python 3.13."
}

Write-Host "Upgrading pip..."
Invoke-Pip -PipArgs @('install', '--upgrade', 'pip')

if (Test-Path $libReq) {
    Write-Host "Installing library requirements: $libReq"
    Invoke-Pip -PipArgs @('install', '-r', $libReq)
}

$targetReq = Join-Path $TargetRoot 'requirements.txt'
$appReq = Join-Path $TargetRoot 'ehs_dashboard\requirements.txt'
if (Test-Path $targetReq) {
    Write-Host "Installing target requirements: $targetReq"
    Invoke-Pip -PipArgs @('install', '-r', $targetReq)
} elseif (Test-Path $appReq) {
    Write-Host "Installing ehs_dashboard requirements: $appReq"
    Invoke-Pip -PipArgs @('install', '-r', $appReq)
}

if (-not (Test-Cmd 'gh')) {
    $portable = Join-Path $env:LOCALAPPDATA 'GitHubCLI\bin\gh.exe'
    if (Test-Path $portable) {
        $env:Path = "$(Split-Path $portable);$env:Path"
    } elseif (Test-Cmd 'winget') {
        Write-Host "Installing GitHub CLI..."
        winget install --id GitHub.cli -e --scope user --accept-package-agreements --accept-source-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'User') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    } else {
        Write-Warning "gh not installed. GitHub comments/PRs need GitHub CLI."
    }
}

if (Test-Cmd 'gh') {
    Write-Host "gh: $((gh --version | Select-Object -First 1))"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    gh auth status
    $authCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($authCode -ne 0) {
        Write-Warning "gh is installed but not logged in. Run: gh auth login --web"
    }
} else {
    Write-Warning "gh still missing from PATH. Open a new terminal after install."
}

Write-Host "Machine install finished."
