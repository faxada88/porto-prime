param([string]$DeviceId = '')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if($LASTEXITCODE -ne 0){throw 'Falha na atualizacao do aplicativo.'}
Write-Host 'Categorias reorganizadas. Banner sem botao de catalogo; carrossel do Admin preservado.'
