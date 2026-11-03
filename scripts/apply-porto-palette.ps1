param([string]$ProjectRoot='C:\Users\conta\porto-prime-github',[string]$DeviceId='emulator-5554')
$ErrorActionPreference='Stop'
Get-Command node -ErrorAction Stop | Out-Null
Get-Command flutter -ErrorAction Stop | Out-Null
$backup=Join-Path $env:LOCALAPPDATA ('PortoPrimeBackups\paleta-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup -Force | Out-Null
$patch=Join-Path $backup 'apply-palette.mjs'
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/92bd44ea2436c6adc5cb5ebc13e1e7fd71c0e453/scripts/apply-palette.mjs' -UseBasicParsing -OutFile $patch
if((Get-FileHash $patch -Algorithm SHA256).Hash.ToLowerInvariant() -ne '08f119849efbabd13470efcb00d2a8d3f006a3c98fd2447feffafc57ff0dc60e'){throw 'Falha na integridade do instalador. Nenhum arquivo alterado.'}
try {
 node $patch $ProjectRoot $backup
 if($LASTEXITCODE -ne 0){throw 'Nao foi possivel aplicar a paleta.'}
 Push-Location (Join-Path $ProjectRoot 'apps\mobile')
 try {
  flutter analyze --no-fatal-infos --no-fatal-warnings lib/core/theme/app_theme.dart
  if($LASTEXITCODE -ne 0){throw 'Validacao do tema falhou.'}
 } finally {Pop-Location}
} catch {
 $failure=$_.Exception.Message
 $list=Join-Path $backup 'files.json'
 if(Test-Path $list){foreach($relative in (Get-Content $list -Raw | ConvertFrom-Json)){Copy-Item (Join-Path $backup $relative) (Join-Path $ProjectRoot $relative) -Force}}
 throw "Atualizacao interrompida e cores anteriores restauradas. $failure Backup: $backup"
}
Write-Host "Paleta Porto Prime instalada. Backup: $backup"
Push-Location (Join-Path $ProjectRoot 'apps\mobile')
try {
 flutter run --release -d $DeviceId --dart-define=API_URL=http://10.0.2.2:3000/api
 if($LASTEXITCODE -ne 0){throw 'A paleta foi instalada, mas o app nao iniciou. Envie o erro acima.'}
} finally {Pop-Location}
