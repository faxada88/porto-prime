param([string]$DeviceId = '')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'update-tropical-account.ps1') -DeviceId $DeviceId
if($LASTEXITCODE -ne 0){throw 'Falha na atualizacao da Home.'}
Write-Host 'Home atualizada conforme a referencia: cabecalho sem marca, categorias, banner horizontal, vitrine e menu flutuante.'
