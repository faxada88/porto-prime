param([string]$ProjectRoot='C:\Users\conta\porto-prime-github',[string]$DeviceId='emulator-5554')
$ErrorActionPreference='Stop'
$backup=Join-Path $env:TEMP ('porto-pix-sync-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/53f6dfdc3ca5c7350da56f11c93fd0863f0d3b22/scripts/payloads/pix-reference-modal.json' -UseBasicParsing -OutFile (Join-Path $backup 'manifest.json')
$items=ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $backup 'manifest.json'),[Text.Encoding]::UTF8))
function HashText([string]$value) {
  $sha=[Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($value)))).Replace('-','').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
$prepared=@()
foreach($item in $items) {
  $path=Join-Path $ProjectRoot $item.path
  $exists=Test-Path $path
  $old=if($exists){[IO.File]::ReadAllText($path).Replace("`r`n","`n")}else{''}
  if($exists -and (HashText $old) -eq $item.after) { continue }
  if($null -eq $item.before) {
    if($exists) { throw "Arquivo novo ja existe com outro conteudo: $($item.path). Nada alterado." }
    $new=[string]$item.content
  } else {
    if(!$exists -or (HashText $old) -ne $item.before) { throw "Arquivo diferente do ZIP analisado: $($item.path). Nada alterado." }
    $new=$old
    foreach($edit in $item.edits) {
      $start=[int]$edit.start
      $length=([string]$edit.old).Length
      if($new.Substring($start,$length) -cne [string]$edit.old) { throw 'Trecho divergente. Nada alterado.' }
      $new=$new.Remove($start,$length).Insert($start,[string]$edit.new)
    }
  }
  if((HashText $new) -ne $item.after) { throw 'Falha de integridade. Nada alterado.' }
  $saved=Join-Path $backup $item.path
  New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null
  if($exists){Copy-Item $path $saved}
  $prepared+=@{path=$path; saved=$saved; existed=$exists; content=$new}
}
try {
  foreach($p in $prepared) {
    New-Item -ItemType Directory -Path (Split-Path $p.path) -Force | Out-Null
    [IO.File]::WriteAllText($p.path,$p.content,(New-Object Text.UTF8Encoding($false)))
  }
  Push-Location (Join-Path $ProjectRoot 'apps\mobile')
  try {
    flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/courier/presentation/pages/courier_page.dart lib/features/courier/presentation/widgets/courier_wallet_live.dart lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart test/courier_pix_sync_test.dart
    if($LASTEXITCODE -ne 0){throw 'Analise Flutter falhou.'}
    flutter test test/courier_pix_sync_test.dart
    if($LASTEXITCODE -ne 0){throw 'Testes Flutter falharam.'}
  } finally {Pop-Location}
} catch {
  foreach($p in $prepared) {
    if($p.existed){Copy-Item $p.saved $p.path -Force}
    elseif(Test-Path $p.path){Remove-Item $p.path -Force}
  }
  throw "Arquivos restaurados. $($_.Exception.Message)"
}
Write-Host "Modal instalado. Backup: $backup"
Push-Location (Join-Path $ProjectRoot 'apps\mobile')
try {
  flutter run --release -d $DeviceId --dart-define=API_URL=http://10.0.2.2:3000/api
  if($LASTEXITCODE -ne 0){throw 'Flutter nao iniciou. A atualizacao esta instalada; envie o erro acima.'}
} finally {Pop-Location}
