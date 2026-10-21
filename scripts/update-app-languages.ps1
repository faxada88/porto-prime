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
# This container generates bundled interface dictionaries only. It receives no customer data.
Invoke-Checked -Command docker -Arguments @('info','--format','{{.ServerVersion}}')
$translatorName='porto-prime-ui-translator'
$existingContainers=@(& docker container ls --all --format '{{.Names}}')
if($LASTEXITCODE -ne 0){throw 'Nao foi possivel listar os containers. Confirme que o Docker Desktop esta aberto.'}
if($existingContainers -contains $translatorName){
 Invoke-Checked -Command docker -Arguments @('start',$translatorName)
}else{
 Invoke-Checked -Command docker -Arguments @('run','-d','--name',$translatorName,'-p','127.0.0.1:5040:5000','-e','LT_LOAD_ONLY=pt,en,es','-v','porto-prime-ui-translation-models:/home/libretranslate/.local:rw','libretranslate/libretranslate:latest')
}
Write-Host 'Preparando os idiomas da interface. Na primeira vez o Docker baixa os modelos; acompanhe em docker logs porto-prime-ui-translator.'
try {
 $deadline=(Get-Date).AddMinutes(35)
 $ready=$false
 while((Get-Date) -lt $deadline){
  try{$languages=Invoke-RestMethod 'http://127.0.0.1:5040/languages' -TimeoutSec 8; if(@($languages|Where-Object {$_.code -eq 'pt'}).Count -gt 0){$ready=$true;break}}catch{}
  $running=& docker inspect --format '{{.State.Running}}' $translatorName
  if($running -ne 'true'){throw 'Tradutor parou. Consulte docker logs porto-prime-ui-translator.'}
  Start-Sleep -Seconds 5
 }
 if(!$ready){throw 'Modelos de idioma ainda indisponiveis. Consulte docker logs porto-prime-ui-translator.'}
 Invoke-Checked -Command node -Arguments @((Join-Path $PSScriptRoot 'prepare-app-languages.mjs'))
} finally {
 & docker stop $translatorName | Out-Null
}
Push-Location (Join-Path $projectRoot 'apps\mobile')
try{
 Invoke-Checked -Command flutter -Arguments @('pub','get')
 Invoke-Checked -Command flutter -Arguments @('build','apk','--release','--dart-define=API_URL=http://10.0.2.2:3000/api')
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'install','-r','build\app\outputs\flutter-apk\app-release.apk')
 $sdkRoot=if($env:ANDROID_SDK_ROOT){$env:ANDROID_SDK_ROOT}elseif($env:ANDROID_HOME){$env:ANDROID_HOME}else{Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
 $adb=Join-Path $sdkRoot 'platform-tools\adb.exe'
 Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','am','force-stop','com.portoprime.porto_prime')
 if(Test-Path $adb){Invoke-Checked -Command $adb -Arguments @('-s',$DeviceId,'shell','monkey','-p','com.portoprime.porto_prime','-c','android.intent.category.LAUNCHER','1')}
 Write-Host 'App instalado: seletor PT/ES/EN ao lado do sino. Idioma salvo. Banco, API, Admin, rotas e Stripe continuam ligados. Produtos e telefones nao foram alterados.'
}finally{Pop-Location}
