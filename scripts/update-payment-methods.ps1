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
if(Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue){
 throw 'Pare somente o Nest com Ctrl+C no terminal dele e execute novamente. Banco, rotas, Admin e Stripe continuam ligados.'
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
 Invoke-Checked -Command npx -Arguments @('prisma','db','execute','--file','prisma/migrations/20261021_stripe_boleto_method/migration.sql')
 Invoke-Checked -Command npx -Arguments @('prisma','generate')
 Invoke-Checked -Command npm -Arguments @('test','--','src/payments')
 Invoke-Checked -Command npm -Arguments @('run','build')
}finally{Pop-Location}
Push-Location $mobileRoot
try{
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings','lib/features/checkout/presentation/widgets/native_payment_modals.dart','lib/features/checkout/presentation/pages/stripe_checkout_page.dart','lib/features/checkout/presentation/pages/stripe_web_element_web.dart','lib/features/checkout/presentation/widgets/prime_payment_experience.dart','test/payment_experience_test.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/native_payment_modals_test.dart','test/payment_experience_test.dart','test/reference_home_test.dart','test/prime_brand_banner_test.dart')
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
 Write-Host 'Checkout atualizado. Pix, cartoes, boleto e carteiras elegiveis sao exibidos pelo Stripe. Pagamento dentro do app: modal Stripe para cartoes/carteiras/boleto e modal Pix com Copia e Cola. Banco, rotas, Admin e Stripe devem continuar ligados.'
}finally{Pop-Location}
