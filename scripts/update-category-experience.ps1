param([string]$DeviceId = '')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if($LASTEXITCODE -ne 0){throw 'Falha na atualizacao das categorias.'}
Write-Host 'Todas as categorias atualizadas: banner contextual, busca, filtros, ordenacao e cards com os dados reais do catalogo.'
