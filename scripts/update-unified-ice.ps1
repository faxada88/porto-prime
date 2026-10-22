param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw 'Falha na atualizacao. Consulte o erro acima.' }
Write-Host 'Gelos atualizados: uma unica escolha de tipo, peso e quantidade, um total e um botao para adicionar.'

