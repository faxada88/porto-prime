# Reuse the existing data volume and credentials; only change the host port.
$ErrorActionPreference='Stop'
& node (Join-Path $PSScriptRoot 'repair-local-db-port.mjs')
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel concluir a troca da porta. Consulte a mensagem acima.'}
