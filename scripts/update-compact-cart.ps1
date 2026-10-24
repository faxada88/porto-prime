param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw 'Falha na atualizacao. Consulte o erro acima.' }
Write-Host 'Carrinho atualizado: lista compacta, produtos alinhados, quantidade ao lado do valor e subtotal visivel.'
