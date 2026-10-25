param([string]$DeviceId = '', [string]$AppleMerchantId = $env:STRIPE_APPLE_MERCHANT_ID, [switch]$CleanBuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
function Invoke-Checked {
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if($LASTEXITCODE -ne 0){throw "Falha em $Command. O aplicativo atual nao foi substituido."}
}
$devicesJson = & flutter devices --machine
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel consultar os dispositivos.'}
$devices = @((($devicesJson -join [Environment]::NewLine) | ConvertFrom-Json) |
 Where-Object {$_.targetPlatform -like 'android*'})
if(!$DeviceId){
 if($devices.Count -ne 1){throw 'Deixe um Android conectado ou informe -DeviceId emulator-5554.'}
 $DeviceId = $devices[0].id
}
if(!($devices | Where-Object {$_.id -eq $DeviceId})){throw 'Inicie o emulador e aguarde a tela inicial do Android.'}
$sdkRoot = if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
if(!(Test-Path $adb)){throw 'ADB nao encontrado no Android SDK.'}
function Assert-AndroidReady {
 $boot = ((& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null) -join '').Trim()
 if($boot -ne '1'){throw 'Aguarde o Android terminar de iniciar antes de instalar.'}
 $packageManager = (& $adb -s $DeviceId shell pm path android 2>$null) -join ''
 if($packageManager -notmatch '^package:'){throw 'O Android ainda nao esta pronto para instalar aplicativos.'}
}
Assert-AndroidReady
Push-Location (Join-Path $projectRoot 'apps\mobile')
try {
 if($CleanBuild){Invoke-Checked -Command flutter -Arguments @('clean')}
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings',
  'lib/features/courier/presentation/pages/courier_page.dart',
  'lib/features/courier/presentation/pages/courier_operations_dashboard.dart',
  'lib/features/courier/presentation/pages/courier_demand_notice.dart',
  'lib/core/tracking/courier_tracking_notice.dart',
  'lib/features/courier/presentation/widgets/courier_dashboard_map.dart',
  'lib/features/courier/presentation/widgets/courier_dashboard_header.dart',
  'lib/features/courier/presentation/widgets/courier_delivery_surface.dart',
  'lib/features/courier/presentation/widgets/courier_workflow_layout.dart',
  'lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart',
  'lib/features/courier/presentation/widgets/courier_assigned_delivery.dart',
  'lib/features/courier/presentation/widgets/incoming_delivery_offer_sheet.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/delivery_offer_sheet_test.dart','test/courier_workflow_test.dart','test/courier_feedback_test.dart')
 $buildArgs = @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 if($AppleMerchantId){$buildArgs += '--dart-define=STRIPE_APPLE_MERCHANT_ID=' + $AppleMerchantId}
 Invoke-Checked -Command flutter -Arguments $buildArgs
 Assert-AndroidReady
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','am','force-stop','com.portoprime.porto_prime')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')
 Write-Host 'Painel atualizado: entrega em um unico card, cabecalho compacto e acoes claras de rota, contato e conclusao.'
 Write-Host 'Nest, banco, Admin, rotas e Stripe podem continuar ligados. Dados e sessao do aplicativo preservados.'
} finally { Pop-Location }
