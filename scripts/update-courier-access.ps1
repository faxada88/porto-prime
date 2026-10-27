param([string]$DeviceId = 'emulator-5554', [int]$AdminPort = 3002, [string]$AppleMerchantId = $env:STRIPE_APPLE_MERCHANT_ID)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
function Invoke-Checked {
 param([string]$Command,[string[]]$Arguments)
 & $Command @Arguments
 if ($LASTEXITCODE -ne 0) { throw "Falha em $Command. Consulte o erro acima." }
}
$devicesJson = & flutter devices --machine
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar o Flutter.' }
$devices = @(($devicesJson -join [Environment]::NewLine) | ConvertFrom-Json)
if (!($devices | Where-Object { $_.id -eq $DeviceId -and $_.targetPlatform -like 'android*' })) {
 throw 'Abra o emulador Android e aguarde sua inicializacao antes de executar novamente.'
}
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (!(Test-Path $adb)) { throw 'ADB nao encontrado.' }
$boot = ((& $adb -s $DeviceId shell getprop sys.boot_completed) -join '').Trim()
if ($boot -ne '1') { throw 'Aguarde a tela inicial do Android e execute novamente.' }

# Stop only Node processes whose command line identifies this checkout's API/Admin.
# Database, routing, Stripe and other applications are never targeted.
$apiRoot = Join-Path $projectRoot 'apps\api'
$adminRoot = Join-Path $projectRoot 'apps\admin'
$known = @(Get-CimInstance Win32_Process | Where-Object {
 $_.Name -eq 'node.exe' -and $_.CommandLine -and
 ($_.CommandLine.Contains($apiRoot) -or $_.CommandLine.Contains($adminRoot))
})
foreach ($process in $known) {
 if (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) {
  try { & taskkill.exe /PID $process.ProcessId /T /F }
  catch { if (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) { throw } }
 }
}
foreach ($port in @(3000, $AdminPort)) {
 if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
  throw "A porta $port ainda esta ocupada por um processo nao identificado com seguranca. Pare o Nest/Admin no terminal dele e execute novamente."
 }
}

Push-Location $apiRoot
try {
 Invoke-Checked npm @('install','--include=dev','--no-audit','--no-fund')
 Invoke-Checked npx @('prisma','generate','--config','prisma7.config.ts')
 Invoke-Checked npm @('run','build')
 Invoke-Checked npm @('test')
} finally { Pop-Location }

Push-Location $adminRoot
try {
 Invoke-Checked npm @('install','--include=dev','--no-audit','--no-fund')
 $env:API_INTERNAL_URL = 'http://127.0.0.1:3000/api'
 Invoke-Checked npm @('run','build')
} finally { Pop-Location }

Push-Location (Join-Path $projectRoot 'apps\mobile')
try {
 Invoke-Checked flutter @('pub','get')
 Invoke-Checked flutter @('analyze','--no-fatal-infos','--no-fatal-warnings',
  'lib/core/state/app_state.dart','lib/core/realtime/realtime_client.dart',
  'lib/features/courier/presentation/pages/courier_page.dart',
  'lib/features/courier/presentation/widgets/courier_account_status.dart',
  'test/courier_account_status_test.dart')
 Invoke-Checked flutter @('test','test/courier_account_status_test.dart',
  'test/courier_workflow_test.dart','test/courier_availability_test.dart','test/delivery_offer_sheet_test.dart')
 $buildArgs = @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 if ($AppleMerchantId) { $buildArgs += '--dart-define=STRIPE_APPLE_MERCHANT_ID=' + $AppleMerchantId }
 Invoke-Checked flutter $buildArgs

 $apiQuoted = $apiRoot.Replace("'", "''")
 $adminQuoted = $adminRoot.Replace("'", "''")
 $apiCommand = "Set-Location -LiteralPath '$apiQuoted'; Remove-Item Env:DATABASE_URL -ErrorAction SilentlyContinue; npm run start:dev"
 $adminCommand = "Set-Location -LiteralPath '$adminQuoted'; `$env:API_INTERNAL_URL='http://127.0.0.1:3000/api'; npm run start -- --hostname 0.0.0.0 --port $AdminPort"
 Start-Process powershell -ArgumentList @('-NoProfile','-NoExit','-Command',$apiCommand)
 Start-Process powershell -ArgumentList @('-NoProfile','-NoExit','-Command',$adminCommand)
 $ready = $false
 $deadline = (Get-Date).AddSeconds(90)
 while ((Get-Date) -lt $deadline) {
  try { $null = Invoke-RestMethod 'http://127.0.0.1:3000/api/health' -TimeoutSec 3; $ready = $true; break }
  catch { Start-Sleep -Seconds 2 }
 }
 if (!$ready) { throw 'O Nest nao ficou pronto. Consulte a nova janela da API; o aplicativo instalado foi preservado.' }
 Invoke-Checked $adb @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 Invoke-Checked $adb @('-s',$DeviceId,'shell','am','force-stop','com.portoprime.porto_prime')
 Invoke-Checked $adb @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')
 Write-Host "Atualizacao instalada. Admin: http://localhost:$AdminPort . Aguarde o Nest concluir a inicializacao na nova janela."
} finally { Pop-Location }
