param([string]$ProjectRoot='C:\Users\conta\porto-prime-github',[string]$DeviceId='emulator-5554',[int]$AdminPort=3002)
$ErrorActionPreference='Stop'
foreach($port in @(3000,$AdminPort)) {
  if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) { throw "Pare o Nest e o Admin com Ctrl+C antes de instalar. A porta $port esta em uso." }
}
foreach($command in @('node','npm.cmd','npx.cmd','flutter')) { Get-Command $command -ErrorAction Stop | Out-Null }
if(!(Test-Path (Join-Path $ProjectRoot 'apps\api\.env'))) { throw 'Arquivo apps\api\.env nao encontrado. Nenhum arquivo alterado.' }
$backup=Join-Path $env:LOCALAPPDATA ('PortoPrimeBackups\indicacoes-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup -Force | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/8fc6d9a10ac9a51f0f18eb20133a1f0245311ede/scripts/payloads/courier-referrals.json' -UseBasicParsing -OutFile (Join-Path $backup 'manifest.json')
$items=ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $backup 'manifest.json'),[Text.Encoding]::UTF8))
function HashText([string]$value) {
 $sha=[Security.Cryptography.SHA256]::Create()
 try {return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($value)))).Replace('-','').ToLowerInvariant()} finally {$sha.Dispose()}
}
$prepared=@()
foreach($item in $items) {
 $path=Join-Path $ProjectRoot $item.path
 $exists=Test-Path $path
 $old=if($exists){[IO.File]::ReadAllText($path).Replace("`r`n","`n")}else{''}
 if($exists -and (HashText $old) -eq $item.after){continue}
 if($null -eq $item.before){
  if($exists){throw "Arquivo novo com conteudo diferente: $($item.path). Nada alterado."}
  $new=[string]$item.content
 }else{
  if(!$exists -or (HashText $old) -ne $item.before){throw "Arquivo diferente do ZIP recebido: $($item.path). Nada alterado. Envie essa mensagem."}
  $new=$old
  foreach($edit in $item.edits){$start=[int]$edit.start;$length=([string]$edit.old).Length;if($new.Substring($start,$length) -cne [string]$edit.old){throw 'Trecho divergente. Nada alterado.'};$new=$new.Remove($start,$length).Insert($start,[string]$edit.new)}
 }
 if((HashText $new) -ne $item.after){throw 'Falha de integridade. Nada alterado.'}
 $saved=Join-Path $backup $item.path
 New-Item -ItemType Directory (Split-Path $saved) -Force | Out-Null
 if($exists){Copy-Item $path $saved}
 $prepared+=@{path=$path;saved=$saved;existed=$exists;content=$new}
}
$locks=@()
foreach($relative in @('apps\api\package-lock.json','apps\mobile\pubspec.lock')){
 $path=Join-Path $ProjectRoot $relative;$saved=Join-Path $backup $relative;$exists=Test-Path $path
 New-Item -ItemType Directory (Split-Path $saved) -Force | Out-Null
 if($exists){Copy-Item $path $saved}
 $locks+=@{path=$path;saved=$saved;existed=$exists}
}
try{
 foreach($p in $prepared){New-Item -ItemType Directory (Split-Path $p.path) -Force | Out-Null;[IO.File]::WriteAllText($p.path,$p.content,(New-Object Text.UTF8Encoding($false)))}
 Push-Location (Join-Path $ProjectRoot 'apps\api')
 try{
  npm.cmd install --ignore-scripts
  if($LASTEXITCODE -ne 0){throw 'Falha ao instalar a dependencia de testes da campanha.'}
  npx.cmd prisma validate
  if($LASTEXITCODE -ne 0){throw 'Schema Prisma invalido.'}
  npx.cmd prisma generate
  if($LASTEXITCODE -ne 0){throw 'Falha ao gerar Prisma.'}
  npm.cmd test -- src/referrals/referral.spec.ts
  if($LASTEXITCODE -ne 0){throw 'Testes da campanha falharam.'}
  npm.cmd run build
  if($LASTEXITCODE -ne 0){throw 'Build do Nest falhou.'}
 }finally{Pop-Location}
 Push-Location (Join-Path $ProjectRoot 'apps\admin')
 try{npm.cmd run build;if($LASTEXITCODE -ne 0){throw 'Build do Admin falhou.'}}finally{Pop-Location}
 Push-Location (Join-Path $ProjectRoot 'apps\mobile')
 try{
  flutter pub get
  if($LASTEXITCODE -ne 0){throw 'Dependencias Flutter falharam.'}
  flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/referrals lib/features/profile/presentation/pages/registration_page.dart lib/features/courier/presentation/pages/courier_page.dart lib/main.dart test/courier_referral_test.dart
  if($LASTEXITCODE -ne 0){throw 'Analise Flutter falhou.'}
  flutter test test/courier_referral_test.dart
  if($LASTEXITCODE -ne 0){throw 'Testes Flutter falharam.'}
 }finally{Pop-Location}
 Push-Location (Join-Path $ProjectRoot 'apps\api')
 try{
  node --env-file=.env prisma/install-referrals.mjs
  if($LASTEXITCODE -ne 0){throw 'Migracao das indicacoes falhou. Verifique se o PostgreSQL Docker esta rodando.'}
 }finally{Pop-Location}
}catch{
 $failure=$_.Exception.Message
 foreach($p in ($prepared + $locks)){if($p.existed){Copy-Item $p.saved $p.path -Force}elseif(Test-Path $p.path){Remove-Item $p.path -Force}}
 Push-Location (Join-Path $ProjectRoot 'apps\api')
 try{npm.cmd install --ignore-scripts;npx.cmd prisma generate}finally{Pop-Location}
 Push-Location (Join-Path $ProjectRoot 'apps\mobile')
 try{flutter pub get}finally{Pop-Location}
 throw "Instalacao interrompida; fontes e lockfiles restaurados. Nenhuma tabela ou saldo existente foi apagado. $failure Backup: $backup"
}
Write-Host "Indique & Ganhe instalado. Backup: $backup"
Write-Host 'No Admin > Indique & Ganhe, configure a URL HTTPS publica da API (inclua /api) para compartilhar links.'
$apiPath=(Join-Path $ProjectRoot 'apps\api').Replace("'","''")
$adminPath=(Join-Path $ProjectRoot 'apps\admin').Replace("'","''")
$apiCommand="Set-Location '$apiPath'; npm.cmd run start:dev"
$adminCommand="Set-Location '$adminPath'; `$env:API_INTERNAL_URL='http://127.0.0.1:3000/api'; npm.cmd run dev -- -p $AdminPort"
Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($apiCommand)))
Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-NoExit','-EncodedCommand',[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($adminCommand)))
Push-Location (Join-Path $ProjectRoot 'apps\mobile')
try{flutter run --release -d $DeviceId --dart-define=API_URL=http://10.0.2.2:3000/api;if($LASTEXITCODE -ne 0){throw 'Atualizacao instalada, mas o Flutter nao iniciou. Envie o erro acima.'}}finally{Pop-Location}
