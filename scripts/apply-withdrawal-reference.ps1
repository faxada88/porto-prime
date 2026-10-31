param([string]$ProjectRoot='C:\Users\conta\porto-prime-github')
$ErrorActionPreference='Stop'
$mobile=Join-Path $ProjectRoot 'apps\mobile'
$page=Join-Path $mobile 'lib\features\courier\presentation\pages\courier_page.dart'
$code=[IO.File]::ReadAllText($page)
if (!$code.Contains('CourierWithdrawalRequestPanel(') -or !$code.Contains('CourierWithdrawalFeedback(')) {
  throw 'Esta pasta ainda nao usa os componentes separados. Envie o caminho do projeto atual; nenhum arquivo foi alterado.'
}
$folder=Join-Path $mobile 'lib\features\courier\presentation\widgets'
$backup=Join-Path $env:TEMP ('porto-modais-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
$files=@('courier_withdrawal_request.dart','courier_withdrawal_feedback.dart')
foreach($file in $files) {
  $target=Join-Path $folder $file
  if (!(Test-Path $target)) { throw "Componente ausente: $file. Nenhuma alteracao aplicada." }
  Copy-Item $target (Join-Path $backup $file)
  Invoke-WebRequest ("https://raw.githubusercontent.com/faxada88/porto-prime/ee8d980b34bf765a5f6d6c2462cdb8437ea7c7c3/scripts/withdrawal-reference/"+$file) -UseBasicParsing -OutFile (Join-Path $backup ($file+'.new'))
}
Push-Location $mobile
try {
  foreach($file in $files) { Copy-Item (Join-Path $backup ($file+'.new')) (Join-Path $folder $file) -Force }
  flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/courier/presentation/widgets/courier_withdrawal_request.dart lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart lib/features/courier/presentation/pages/courier_page.dart
  if($LASTEXITCODE -ne 0) { throw 'Analise Flutter falhou.' }
  Write-Host "Modais atualizados. Backup: $backup"
} catch {
  foreach($file in $files) { Copy-Item (Join-Path $backup $file) (Join-Path $folder $file) -Force }
  throw
} finally { Pop-Location }
