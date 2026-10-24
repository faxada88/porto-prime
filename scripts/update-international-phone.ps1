param([string]$DeviceId='', [string]$AppleMerchantId=$env:STRIPE_APPLE_MERCHANT_ID)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$apiRoot=Join-Path $projectRoot 'apps\api'
$mobileRoot=Join-Path $projectRoot 'apps\mobile'
function Invoke-Checked {
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if($LASTEXITCODE -ne 0){throw "Falha em $Command. Atualizacao interrompida; consulte o erro acima."}
}
if(Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue){
 throw 'Pare somente o Nest com Ctrl+C no terminal dele e execute novamente. Banco, rotas, Admin e Stripe continuam ligados.'
}
$devicesJson=& flutter devices --machine
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel consultar os dispositivos.'}
$devices=@((($devicesJson -join [Environment]::NewLine)|ConvertFrom-Json)|Where-Object {$_.targetPlatform -like 'android*'})
if(!$DeviceId){if($devices.Count -ne 1){throw 'Deixe um Android conectado ou informe -DeviceId emulator-5554.'};$DeviceId=$devices[0].id}
if(!($devices|Where-Object {$_.id -eq $DeviceId})){throw 'Inicie o emulador antes de atualizar.'}
$sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
$adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
if(!(Test-Path $adb)){throw 'ADB nao encontrado.'}
$boot=((& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null)-join '').Trim()
if($boot -ne '1'){throw 'Aguarde a tela inicial do Android antes de continuar.'}
Push-Location $apiRoot
try {
 Invoke-Checked -Command npm -Arguments @('install','--ignore-scripts','--no-audit','--no-fund')
 Invoke-Checked -Command npm -Arguments @('test','--','src/auth/international-phone.spec.ts')
 Invoke-Checked -Command npm -Arguments @('run','build')
} finally { Pop-Location }
Push-Location $mobileRoot
try {
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings',
  'lib/core/phone/international_phone.dart','lib/core/widgets/international_phone_field.dart',
  'lib/features/profile/presentation/pages/registration_page.dart','lib/main.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/international_phone_test.dart')
 $buildArgs=@('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 if($AppleMerchantId){$buildArgs+=("--dart-define=STRIPE_APPLE_MERCHANT_ID="+$AppleMerchantId)}
 Invoke-Checked -Command flutter -Arguments $buildArgs
 $escapedApi=$apiRoot.Replace("'","''")
 $startApi="Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue; Set-Location -LiteralPath '$escapedApi'; npm run start:dev"
 $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($startApi))
 Start-Process powershell -ArgumentList @('-NoExit','-EncodedCommand',$encoded)
 $ready=$false
 for($attempt=0;$attempt -lt 90;$attempt++){
  try{$health=Invoke-RestMethod -TimeoutSec 2 'http://127.0.0.1:3000/api/health';if($health.status -eq 'ok' -and $health.database -eq 'connected'){$ready=$true;break}}catch{}
  Start-Sleep -Seconds 1
 }
 if(!$ready){throw 'Verifique o terminal do Nest. APK compilado, mas ainda nao instalado.'}
 $boot=((& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null)-join '').Trim()
 if($boot -ne '1'){throw 'O emulador desconectou durante a compilacao. Reabra o Android antes de repetir.'}
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','am','force-stop','com.portoprime.porto_prime')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')
 Write-Host 'Telefones internacionais instalados: bandeiras, busca de paises e codigos, validacao e cadastro sincronizados. Nest reiniciado.'
} finally { Pop-Location }

