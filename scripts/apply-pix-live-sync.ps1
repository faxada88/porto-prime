param([string]$ProjectRoot='C:\Users\conta\porto-prime-github',[string]$DeviceId='emulator-5554',[int]$AdminPort=3002)
$ErrorActionPreference='Stop'
foreach($port in @(3000,$AdminPort)) {
  if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
    throw "Pare o Nest e o Admin com Ctrl+C antes de executar. Porta $port ainda ocupada; nada foi alterado."
  }
}
$backup=Join-Path $env:TEMP ('porto-pix-sync-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/738867967d03c59ef9733fe2d4fd4843e3d878b2/scripts/pix-live-sync/manifest.json' -UseBasicParsing -OutFile (Join-Path $backup 'manifest.json')
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
  Push-Location (Join-Path $ProjectRoot 'apps\api')
  try {
    npm test -- src/wallet/asaas-sync.spec.ts src/wallet/asaas-payout.spec.ts src/wallet/asaas-authorization.spec.ts src/wallet/wallet-withdrawal.spec.ts src/wallet/finance.spec.ts src/wallet/demand-credit.spec.ts
    if($LASTEXITCODE -ne 0){throw 'Testes da API falharam.'}
    npm run build
    if($LASTEXITCODE -ne 0){throw 'Build da API falhou.'}
  } finally {Pop-Location}
  Push-Location (Join-Path $ProjectRoot 'apps\admin')
  try {
    $env:API_INTERNAL_URL='http://127.0.0.1:3000/api'
    npm run build
    if($LASTEXITCODE -ne 0){throw 'Build do Admin falhou.'}
  } finally {Pop-Location}
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
Write-Host "Sincronizacao instalada. Backup: $backup"
$api=Join-Path $ProjectRoot 'apps\api'
$admin=Join-Path $ProjectRoot 'apps\admin'
Start-Process powershell -WorkingDirectory $api -ArgumentList '-NoExit','-Command','npm run start:dev'
Start-Process powershell -WorkingDirectory $admin -ArgumentList '-NoExit','-Command',("npm run dev -- -p "+$AdminPort)
Push-Location (Join-Path $ProjectRoot 'apps\mobile')
try {
  flutter run --release -d $DeviceId --dart-define=API_URL=http://10.0.2.2:3000/api
  if($LASTEXITCODE -ne 0){throw 'Flutter nao iniciou. A atualizacao esta instalada; envie o erro acima.'}
} finally {Pop-Location}
