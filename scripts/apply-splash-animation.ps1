$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = 'https://raw.githubusercontent.com/faxada88/porto-prime/refs/heads/feat/courier-preflight-20261029'
$splash = Join-Path $root 'apps\mobile\lib\features\splash\presentation\pages\splash_page.dart'
$widget = Join-Path $root 'apps\mobile\lib\features\splash\presentation\pages\prime_launch_animation.dart'
$pub = Join-Path $root 'apps\mobile\pubspec.yaml'
$icon = Join-Path $root 'apps\mobile\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'
if (!(Test-Path $icon)) { throw 'Icone original nao encontrado. Nenhuma alteracao aplicada.' }
$backup = Join-Path $env:TEMP ('porto-splash-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item $splash "$backup\splash.dart"
Copy-Item $pub "$backup\pubspec.yaml"
$hadWidget = Test-Path $widget
if ($hadWidget) { Copy-Item $widget "$backup\animation.dart" }
try {
  $code = [IO.File]::ReadAllText($splash)
  if (!$code.Contains('=> const PrimeLaunchAnimation();')) {
    # Replace only the method declaration; retain its existing body untouched.
    # This supports both => expressions and { return ...; } implementations.
    $pattern = '\bWidget\s+build\s*\(\s*BuildContext\s+(\w+)\s*\)'
    $rx = [regex]::new($pattern)
    if ($rx.Matches($code).Count -ne 1 -or $code.Contains('_portoPreviousSplashBuild')) {
      throw 'Nao foi possivel identificar um unico build da splash. Arquivos preservados.'
    }
    $code = $rx.Replace($code, 'Widget build(BuildContext context) => const PrimeLaunchAnimation();' + "`n`n  " + 'Widget _portoPreviousSplashBuild(BuildContext $1)', 1)
    if (!$code.Contains("import 'prime_launch_animation.dart';")) {
      $code = "import 'prime_launch_animation.dart';`n" + $code
    }
  }
  $yaml = [IO.File]::ReadAllText($pub)
  $asset = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'
  if (!$yaml.Contains($asset)) {
    $rx = [regex]::new('(?m)^  assets:\s*$')
    if (!$rx.IsMatch($yaml)) { throw 'Secao flutter/assets nao encontrada. Nada sera substituido.' }
    $yaml = $rx.Replace($yaml, "  assets:`n    - $asset", 1)
  }
  Invoke-WebRequest "$source/apps/mobile/lib/features/splash/presentation/pages/prime_launch_animation.dart" -UseBasicParsing -OutFile $widget
  [IO.File]::WriteAllText($splash, $code, [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($pub, $yaml, [Text.UTF8Encoding]::new($false))
  Push-Location (Join-Path $root 'apps\mobile')
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependencias.' }
    flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/splash/presentation/pages/prime_launch_animation.dart lib/features/splash/presentation/pages/splash_page.dart
    if ($LASTEXITCODE -ne 0) { throw 'Falha na validacao da splash.' }
  } finally { Pop-Location }
  Write-Host "Splash atualizada. Backup: $backup"
} catch {
  Copy-Item "$backup\splash.dart" $splash -Force
  Copy-Item "$backup\pubspec.yaml" $pub -Force
  if ($hadWidget) { Copy-Item "$backup\animation.dart" $widget -Force }
  elseif (Test-Path $widget) { Remove-Item $widget }
  throw
}

