# Standalone MCP stdio shim invoked by opencode (and other MCP clients).
# Boots the agentmemory server if it's not already up, then execs `agentmemory mcp`
# so the stdio pipe is connected directly to opencode.
#
# This is the Windows workaround for the missing `agentmemory connect` automation.

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projRoot  = Split-Path -Parent $scriptDir
$binDir    = Join-Path $projRoot '.agentmemory\bin'

# Make sure the server is alive before serving MCP. If it's not, start it.
$busy = Get-NetTCPConnection -LocalPort 3111 -State Listen -ErrorAction SilentlyContinue
if (-not $busy) {
  Write-Host "[agentmemory_mcp] server not running, starting it..."
  & (Join-Path $scriptDir 'start-server.ps1') | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Error "[agentmemory_mcp] failed to start server"
    exit 1
  }
}

$env:CI = '1'
$env:AGENTMEMORY_HOME = $projRoot
$env:PATH = "$binDir;$env:PATH"

# Hand off stdio to agentmemory mcp. This is a long-running process.
& agentmemory mcp