param([string]$DeviceId = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$apiRoot = Join-Path $projectRoot 'apps\api'
$mobileRoot = Join-Path $projectRoot 'apps\mobile'
function Invoke-Checked {
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if ($LASTEXITCODE -ne 0) { throw "Falha em $Command. Atualizacao interrompida; consulte o erro acima." }
}
if (Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue) {
 throw 'Pare somente o Nest com Ctrl+C no terminal dele e execute novamente. Banco, rotas e Stripe devem continuar ligados.'
}
$devicesJson = & flutter devices --machine
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar os dispositivos Flutter.' }
$devices = @((($devicesJson -join "`n") | ConvertFrom-Json) | Where-Object { $_.targetPlatform -like 'android*' })
if (!$DeviceId) {
 if ($devices.Count -ne 1) { throw 'Deixe apenas um Android conectado ou execute com -DeviceId emulator-5554.' }
 $DeviceId = $devices[0].id
}
if (!($devices | Where-Object { $_.id -eq $DeviceId })) { throw 'Inicie o emulador Android antes de atualizar.' }
Push-Location $apiRoot
try {
 Invoke-Checked -Command npm -Arguments @('test','--','src/orders/delivery-tracking.service.spec.ts')
 Invoke-Checked -Command npm -Arguments @('run','build')
} finally { Pop-Location }
Push-Location $mobileRoot
try {
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('analyze','--no-fatal-infos','--no-fatal-warnings','lib/core/tracking','lib/features/orders/presentation/widgets/live_delivery_map.dart','lib/core/state/app_state.dart','lib/features/orders/presentation/pages/order_tracking_page.dart','lib/features/courier/presentation/pages/courier_page.dart')
 Invoke-Checked -Command flutter -Arguments @('test','test/live_tracking_test.dart')
 Invoke-Checked -Command flutter -Arguments @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 $escapedApi = $apiRoot.Replace("'", "''")
 $startApi = "Set-Location -LiteralPath '$escapedApi'; npm run start:dev"
 $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($startApi))
 Start-Process powershell -ArgumentList @('-NoExit','-EncodedCommand',$encoded)
 $ready = $false
 for ($attempt=0; $attempt -lt 90; $attempt++) {
  try { $health=Invoke-RestMethod -TimeoutSec 2 'http://127.0.0.1:3000/api/health'; if($health.status -eq 'ok' -and $health.database -eq 'connected'){$ready=$true;break} } catch { }
  Start-Sleep -Seconds 1
 }
 if(!$ready){throw 'Nest nao respondeu. Verifique o novo terminal da API; o APK foi compilado, mas nao foi instalado.'}
 Invoke-Checked -Command flutter -Arguments @('install','--release','-d',$DeviceId)
 $sdkRoot = if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
 $adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
 if(Test-Path $adb){Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')}
 Write-Host 'Rastreamento instalado. Ao iniciar a rota, permita localizacao e mantenha o GPS ligado. Cliente acompanha em Acompanhar pedido.'
} finally { Pop-Location }
