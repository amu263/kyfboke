# Stop the project-local agentmemory server (if running).
$ErrorActionPreference = 'SilentlyContinue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projRoot  = Split-Path -Parent $scriptDir
$pidFile   = Join-Path $projRoot '.agentmemory\logs\server.pid'

if (-not (Test-Path $pidFile)) {
  Write-Host "no pidfile at $pidFile -- nothing to stop."
} else {
  $serverPid = (Get-Content $pidFile -Raw).Trim()
  Write-Host "Stopping PID $serverPid"
  Get-Process -Id $serverPid -ErrorAction SilentlyContinue | Stop-Process -Force
  Remove-Item -LiteralPath $pidFile -Force
}
# Also nuke any stragglers on our ports.
foreach ($p in 3111,3112,3113,49134) {
  $conn = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
  if ($conn) {
    Write-Host "Killing leftover on port $p (PID $($conn.OwningProcess))"
    Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue | Stop-Process -Force
  }
}
Start-Sleep -Seconds 1
foreach ($p in 3111,3112,3113,49134) {
  $busy = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
  if ($busy) { Write-Host "PORT $p still busy: PID $($busy.OwningProcess)" }
  else       { Write-Host "PORT $p free" }
}