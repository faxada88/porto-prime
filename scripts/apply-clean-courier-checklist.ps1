$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$relative = 'apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart'
$target = Join-Path $root $relative
$backup = Join-Path $env:TEMP ('porto-checklist-' + [guid]::NewGuid().ToString('N') + '.dart')
Copy-Item $target $backup
try {
  $url = 'https://raw.githubusercontent.com/faxada88/porto-prime/refs/heads/feat/courier-preflight-20261029/' + $relative
  $download = (Invoke-WebRequest $url -UseBasicParsing).Content
  $original = [IO.File]::ReadAllText($target)
  $oldMarker = $original.IndexOf('  Widget _progressHero()')
  if ($oldMarker -lt 0) { $oldMarker = $original.IndexOf('  Widget _checkRow(') }
  $newMarker = $download.IndexOf('  Widget _checkRow(')
  if ($oldMarker -lt 0 -or $newMarker -lt 0) { throw 'Checklist local diferente. Nenhuma alteracao aplicada.' }
  $before = $original.Substring(0, $oldMarker).Replace("`r`n", "`n").Trim()
  $expected = $download.Substring(0, $newMarker).Replace("`r`n", "`n").Trim()
  if ($before -ne $expected) { throw 'A logica local do checklist mudou. Arquivo preservado para revisao.' }
  [IO.File]::WriteAllText($target, $original.Substring(0, $oldMarker) + $download.Substring($newMarker), [Text.UTF8Encoding]::new($false))
  Push-Location (Join-Path $root 'apps/mobile')
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependencias.' }
    flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/profile/presentation/pages/courier_preflight_page.dart
    if ($LASTEXITCODE -ne 0) { throw 'Falha na analise Flutter.' }
  } finally { Pop-Location }
  Write-Host "Checklist atualizado. Backup: $backup"
} catch {
  Copy-Item $backup $target -Force
  throw
}
