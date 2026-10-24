param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if ($LASTEXITCODE -ne 0) { throw 'Falha na atualizacao. Consulte o erro acima.' }
Write-Host 'Menu de visitante sem Pedidos, banner sem botao de ofertas, Continuar comprando no carrinho e retorno por seta atualizados.'

