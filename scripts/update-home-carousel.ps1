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
$sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
if(!(Test-Path $adb)){throw 'ADB nao encontrado no Android SDK.'}
$boot=((& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null) -join '').Trim()
if($boot -ne '1'){throw 'Aguarde a tela inicial do Android aparecer no emulador e execute novamente.'}
$packageManager=(& $adb -s $DeviceId shell pm path android 2>$null) -join ''
if($packageManager -notmatch '^package:'){throw 'Android ainda nao esta pronto para instalar aplicativos. Aguarde e tente novamente.'}
Push-Location (Join-Path $projectRoot 'apps\mobile')
try{
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings','lib/core/widgets/prime_home_carousel.dart','lib/core/widgets/prime_category_3d.dart','lib/core/widgets/prime_reference_home.dart','lib/features/home/presentation/pages/home_page.dart','test/home_carousel_test.dart','test/reference_home_test.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/home_carousel_test.dart','test/reference_home_test.dart','test/category_icons_test.dart')
 Invoke-Checked -Command flutter -Arguments @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 $sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
 $adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
 if(Test-Path $adb){Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')}
 Write-Host 'Home com carrossel automatico e categorias 3D instalada. Regras, catalogo e pagamento preservados. Catalogo, carrinho, navegacao e regras preservados. Nest, Admin, banco, rotas e Stripe continuam ligados.'
}finally{Pop-Location}
