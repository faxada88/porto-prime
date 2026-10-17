param([string]$DeviceId = '')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
function Invoke-Checked {
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if($LASTEXITCODE -ne 0){throw "Falha em $Command. O aplicativo atual nao foi substituido."}
}
$devicesJson=& flutter devices --machine
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel consultar os dispositivos.'}
$devices=@((($devicesJson -join "`n")|ConvertFrom-Json)|Where-Object {$_.targetPlatform -like 'android*'})
if(!$DeviceId){if($devices.Count -ne 1){throw 'Deixe um Android conectado ou informe -DeviceId emulator-5554.'};$DeviceId=$devices[0].id}
if(!($devices|Where-Object {$_.id -eq $DeviceId})){throw 'Inicie o emulador antes de atualizar.'}
Push-Location (Join-Path $projectRoot 'apps\mobile')
try{
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings','lib/features/checkout/presentation/widgets/prime_payment_experience.dart','lib/features/checkout/presentation/pages/stripe_checkout_page.dart','test/payment_experience_test.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/payment_experience_test.dart')
 Invoke-Checked -Command flutter -Arguments @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 Invoke-Checked -Command flutter -Arguments @('install','--release','-d',$DeviceId)
 $sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
 $adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
 if(Test-Path $adb){Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')}
 Write-Host 'Experiencia de pagamento atualizada. Formulario Stripe, regras e confirmacao preservados. Nest, Admin, banco, rotas e Stripe continuam ligados.'
}finally{Pop-Location}
