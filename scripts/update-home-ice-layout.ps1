param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw 'Falha na atualizacao. Consulte o erro acima.' }
Write-Host 'Home alinhada, cards mais amplos, categorias sem carrinho no topo e seletor de gelo atualizados.'

