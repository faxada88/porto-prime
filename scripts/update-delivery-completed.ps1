param([string]$DeviceId = 'emulator-5554')
$ErrorActionPreference = 'Stop'
function Invoke-Checked {
 param([string]$Command, [string[]]$Arguments)
 & $Command @Arguments
 if ($LASTEXITCODE -ne 0) { throw "Falha em $Command. Atualizacao interrompida." }
}
$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } elseif ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
if (!(Test-Path $adb)) { throw 'ADB nao encontrado. Confira o Android SDK.' }
Invoke-Checked $adb @('-s', $DeviceId, 'get-state')
$health = Invoke-RestMethod 'http://127.0.0.1:3000/api/health' -TimeoutSec 10
if ($health.status -ne 'ok') { throw 'Inicie o Nest na porta 3000 antes de atualizar.' }
Push-Location (Join-Path $projectRoot 'apps\mobile')
try {
 Invoke-Checked flutter @('pub', 'get')
 Invoke-Checked flutter @('test', 'test/delivery_completed_view_test.dart')
 Invoke-Checked flutter @('build', 'apk', '--release', '--dart-define=API_URL=http://10.0.2.2:3000/api')
 Invoke-Checked $adb @('-s', $DeviceId, 'install', '-r', 'build\app\outputs\flutter-apk\app-release.apk')
 Invoke-Checked $adb @('-s', $DeviceId, 'shell', 'am', 'force-stop', 'com.portoprime.porto_prime')
 Invoke-Checked $adb @('-s', $DeviceId, 'shell', 'monkey', '-p', 'com.portoprime.porto_prime', '-c', 'android.intent.category.LAUNCHER', '1')
} finally { Pop-Location }
