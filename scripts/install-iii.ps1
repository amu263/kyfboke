# Downloads iii engine v0.11.2 into the project's .agentmemory\bin\.
# This is the Windows workaround the agentmemory server prints when auto-install fails.
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projRoot  = Split-Path -Parent $scriptDir
$binDir    = Join-Path $projRoot '.agentmemory\bin'

if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }

$version   = '0.11.2'
$url       = "https://github.com/iii-hq/iii/releases/download/iii/v$version/iii-x86_64-pc-windows-msvc.zip"
$zipPath   = Join-Path $env:TEMP "iii-v$version.zip"

if (-not (Test-Path (Join-Path $binDir 'iii.exe'))) {
  Write-Host "Downloading $url -> $zipPath"
  (New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
  Write-Host "Extracting to $binDir"
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $binDir)
  Remove-Item -LiteralPath $zipPath -Force
} else {
  Write-Host "iii.exe already present at $binDir\iii.exe"
}

Write-Host "Verifying:"
& (Join-Path $binDir 'iii.exe') --version