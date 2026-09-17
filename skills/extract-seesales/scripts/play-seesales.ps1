# Launch AniTa replaying the last SEE SALES recording. Clicks Select settings OK.
# Does not embed credentials. Requires a .trc that does not end in hangup.
$ErrorActionPreference = 'Stop'
$exe = 'C:\Program Files (x86)\AniTa\Anita.exe'
$hostIp = $env:ANITA_HOST
if (-not $hostIp) { $hostIp = '10.149.0.5' }
$cap = Join-Path $env:LOCALAPPDATA 'Temp\anita-capture'
New-Item -ItemType Directory -Force -Path $cap | Out-Null
$trc = Join-Path $cap 'seesales-export-snapshot.trc'
$live = Join-Path $cap 'seesales-export.trc'
if ((Test-Path $live) -and (-not (Test-Path $trc) -or (Get-Item $live).Length -ge (Get-Item $trc -ErrorAction SilentlyContinue).Length)) {
    Copy-Item $live $trc -Force -ErrorAction SilentlyContinue
}
if (-not (Test-Path $trc)) { throw "No recording at $trc. Cut one (skill section C)." }

$before = @(Get-Process Anita -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -ArgumentList '/c', "/host:$hostIp", "/play:$trc"
Start-Sleep -Seconds 3
$p = Get-Process Anita | Where-Object { $before -notcontains $_.Id } | Select-Object -First 1
if (-not $p) { throw 'AniTa play process did not start.' }

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class SeeSalesPlay {
  public delegate bool EnumWindowsProc(IntPtr h, IntPtr l);
  public delegate bool EnumChildProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumChildProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint id);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
}
"@
$dlg = [IntPtr]::Zero
[SeeSalesPlay]::EnumWindows({
    param($h, $l)
    $id = [uint32]0
    [void][SeeSalesPlay]::GetWindowThreadProcessId($h, [ref]$id)
    if ([int]$id -eq $p.Id -and [SeeSalesPlay]::IsWindowVisible($h)) {
        $t = New-Object System.Text.StringBuilder 256
        [void][SeeSalesPlay]::GetWindowText($h, $t, 256)
        if ($t.ToString() -eq 'Select settings') { $script:dlg = $h }
    }
    $true
}, [IntPtr]::Zero)
if ($dlg -ne [IntPtr]::Zero) {
    $ok = [IntPtr]::Zero
    [SeeSalesPlay]::EnumChildWindows($dlg, {
        param($h, $l)
        $t = New-Object System.Text.StringBuilder 128
        [void][SeeSalesPlay]::GetWindowText($h, $t, 128)
        if ($t.ToString() -eq 'OK') { $script:ok = $h }
        $true
    }, [IntPtr]::Zero)
    [void][SeeSalesPlay]::SetForegroundWindow($dlg)
    Start-Sleep -Milliseconds 200
    if ($ok -ne [IntPtr]::Zero) {
        [void][SeeSalesPlay]::SendMessage($ok, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
    }
}
Start-Sleep -Seconds 8
$p.Refresh()
Write-Output "PID=$($p.Id) title=$($p.MainWindowTitle) trc=$trc"
if ($p.MainWindowTitle -match 'Disconnected') {
    Write-Output 'WARN: session disconnected — recut recording and stop before hangup.'
    exit 2
}
