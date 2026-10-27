param([int]$Port = 3002)
$ErrorActionPreference = 'Stop'
$adminRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'apps\admin'
$known = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'node.exe' -and $_.CommandLine -and $_.CommandLine.IndexOf($adminRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
foreach ($process in $known) {
 if (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) {
  try { & taskkill.exe /PID $process.ProcessId /T /F }
  catch { if (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) { throw } }
 }
}
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw "Pare o Admin que ocupa a porta $Port e execute novamente." }
Push-Location $adminRoot
try {
 npm install --include=dev --no-audit --no-fund
 if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependencias do Admin.' }
 $env:API_INTERNAL_URL = 'http://127.0.0.1:3000/api'
 npm run build
 if ($LASTEXITCODE -ne 0) { throw 'Falha no build do Admin.' }
 Write-Host "Admin: http://localhost:$Port - mantenha este terminal aberto."
 npm run start -- --hostname 0.0.0.0 --port $Port
} finally { Pop-Location }
