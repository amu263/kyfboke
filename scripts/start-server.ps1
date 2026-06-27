# Start agentmemory server (project-local).
# Loads iii.exe from .agentmemory\bin onto PATH so the engine auto-start works on Windows.
# Writes PID to .agentmemory\logs\server.pid, logs to .agentmemory\logs\server.log.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projRoot  = Split-Path -Parent $scriptDir
$binDir    = Join-Path $projRoot '.agentmemory\bin'
$dataDir   = Join-Path $projRoot '.agentmemory\data'
$logsDir   = Join-Path $projRoot '.agentmemory\logs'
$pidFile   = Join-Path $logsDir 'server.pid'
$logFile   = Join-Path $logsDir 'server.log'
$errFile   = Join-Path $logsDir 'server.err'

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
if (-not (Test-Path $binDir\iii.exe)) {
  throw "iii.exe not found at $binDir\iii.exe. Run scripts\install-iii.ps1 first."
}

# Fail fast if something already holds our port.
$busy = Get-NetTCPConnection -LocalPort 3111 -State Listen -ErrorAction SilentlyContinue
if ($busy) {
  Write-Host "PORT 3111 already in use by PID $($busy.OwningProcess). Run scripts\stop-server.ps1 first."
  exit 1
}

$env:CI = '1'
# Keep ALL state under the project, not ~/.agentmemory.
$env:AGENTMEMORY_HOME = $projRoot
# So agentmemory can spawn iii.exe (Windows path issue auto-install doesn't handle).
$env:PATH = "$binDir;$env:PATH"

$agentmemoryShim = (Get-Command agentmemory -ErrorAction SilentlyContinue).Source
if (-not $agentmemoryShim) {
  throw "agentmemory not found on PATH. Run: npm install -g @agentmemory/agentmemory"
}

Write-Host "Starting agentmemory (project-local)"
Write-Host "  shim   : $agentmemoryShim"
Write-Host "  iii    : $binDir\iii.exe"
Write-Host "  data   : $dataDir"
Write-Host "  logs   : $logFile"

$p = Start-Process -FilePath "powershell.exe" `
  -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","$agentmemoryShim") `
  -RedirectStandardOutput $logFile `
  -RedirectStandardError  $errFile `
  -PassThru `
  -WindowStyle Hidden `
  -WorkingDirectory $projRoot

Set-Content -LiteralPath $pidFile -Value $p.Id
Write-Host "  pid    : $($p.Id)"
Write-Host "Waiting for livez on :3111 ..."

$ok = $false
for ($i=1; $i -le 20; $i++) {
  Start-Sleep -Seconds 1
  try {
    $r = Invoke-WebRequest -Uri "http://localhost:3111/agentmemory/livez" -UseBasicParsing -TimeoutSec 3
    if ($r.StatusCode -eq 200) { $ok = $true; break }
  } catch { }
}
if ($ok) {
  Write-Host "agentmemory LIVE after $i s. Viewer: http://localhost:3113"
  exit 0
} else {
  Write-Host "agentmemory did not become live. Check $errFile"
  exit 1
}