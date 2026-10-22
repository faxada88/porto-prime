param([switch]$StartApi)
# Reuse the existing data volume and credentials; only change/synchronize the host port.
$ErrorActionPreference='Stop'
& node (Join-Path $PSScriptRoot 'repair-local-db-port.mjs')
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel concluir a sincronizacao. Consulte a mensagem acima.'}
if($StartApi){
 $apiPath=Join-Path (Split-Path -Parent $PSScriptRoot) 'apps\api'
 $previousDatabaseUrl=[Environment]::GetEnvironmentVariable('DATABASE_URL','Process')
 try{
  # This child PowerShell session must load apps/api/.env, not an inherited stale URL.
  [Environment]::SetEnvironmentVariable('DATABASE_URL',$null,'Process')
  Push-Location $apiPath
  try{ & npm run start:dev }finally{ Pop-Location }
 }finally{
  [Environment]::SetEnvironmentVariable('DATABASE_URL',$previousDatabaseUrl,'Process')
 }
}
