param([string]$DeviceId='', [string]$AppleMerchantId=$env:STRIPE_APPLE_MERCHANT_ID)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$apiRoot=Join-Path $projectRoot 'apps\api'
$mobileRoot=Join-Path $projectRoot 'apps\mobile'
function Invoke-Checked{
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if($LASTEXITCODE -ne 0){throw "Falha em $Command. Atualizacao interrompida; consulte o erro acima."}
}
if(Get-NetTCPConnection -LocalPort 3000,3002 -State Listen -ErrorAction SilentlyContinue){
 throw 'Pare Nest e Admin com Ctrl+C nos terminais deles e execute novamente. Banco, rotas e Stripe continuam ligados.'
}
$devicesJson=& flutter devices --machine
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel consultar os dispositivos.'}
$devices=@((($devicesJson -join "`n")|ConvertFrom-Json)|Where-Object {$_.targetPlatform -like 'android*'})
if(!$DeviceId){if($devices.Count -ne 1){throw 'Deixe um Android conectado ou informe -DeviceId emulator-5554.'};$DeviceId=$devices[0].id}
if(!($devices|Where-Object {$_.id -eq $DeviceId})){throw 'Inicie o emulador antes de atualizar.'}
$sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
if(!(Test-Path $adb)){throw 'ADB nao encontrado.'}
$boot=((& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null)-join '').Trim()
if($boot -ne '1'){throw 'Aguarde a tela inicial do Android antes de continuar.'}
Push-Location $apiRoot
try{
 # Targeted additive, idempotent migration: no reset, db push or data removal.
 Invoke-Checked -Command npx -Arguments @('prisma','db','execute','--file','prisma/migrations/20261021_product_home_showcase/migration.sql')
 Invoke-Checked -Command npx -Arguments @('prisma','generate')
 Invoke-Checked -Command npm -Arguments @('test','--','src/admin/catalog-category-delete.spec.ts')
 Invoke-Checked -Command npm -Arguments @('run','build')
}finally{Pop-Location}
Push-Location (Join-Path $projectRoot 'apps\admin')
try{Invoke-Checked -Command npm -Arguments @('run','build')}finally{Pop-Location}
Push-Location $mobileRoot
try{
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings','lib/features/home/presentation/pages/home_page.dart','lib/core/widgets/product_showcase.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/reference_home_test.dart','test/light_navigation_test.dart')
 $buildArgs=@('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 if($AppleMerchantId){$buildArgs+=("--dart-define=STRIPE_APPLE_MERCHANT_ID="+$AppleMerchantId)}
 Invoke-Checked -Command flutter -Arguments $buildArgs
 $escapedApi=$apiRoot.Replace("'","''")
 $startApi="Set-Location -LiteralPath '$escapedApi'; npm run start:dev"
 $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($startApi))
 Start-Process powershell -ArgumentList @('-NoExit','-EncodedCommand',$encoded)
 $ready=$false
 for($attempt=0;$attempt -lt 90;$attempt++){
  try{$health=Invoke-RestMethod -TimeoutSec 2 'http://127.0.0.1:3000/api/health';if($health.status -eq 'ok' -and $health.database -eq 'connected'){$ready=$true;break}}catch{}
  Start-Sleep -Seconds 1
 }
 if(!$ready){throw 'Verifique o terminal do Nest. APK compilado, mas ainda nao instalado.'}
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','am','force-stop','com.portoprime.porto_prime')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')
 $adminRoot=(Join-Path $projectRoot 'apps\admin').Replace("'","''")
 $adminCommand="Set-Location -LiteralPath '$adminRoot'; `$env:API_INTERNAL_URL='http://127.0.0.1:3000/api'; npm run dev -- --hostname 0.0.0.0 --port 3002"
 $adminEncoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($adminCommand))
 Start-Process powershell -ArgumentList @('-NoExit','-EncodedCommand',$adminEncoded)
 Write-Host 'Atualizado. Admin: http://localhost:3002. Catalogo > Produto > Exibir no carrossel da pagina inicial. Marque os produtos e salve. Nenhum produto e selecionado automaticamente.'

}finally{Pop-Location}
