param([string]$ProjectRoot='C:\Users\conta\porto-prime-github')
$ErrorActionPreference='Stop'
$mobile=Join-Path $ProjectRoot 'apps\mobile'
$page=Join-Path $mobile 'lib\features\courier\presentation\pages\courier_page.dart'
$widget=Join-Path $mobile 'lib\features\courier\presentation\widgets\courier_withdrawal_request.dart'
$backup=Join-Path $env:TEMP ('porto-carteira-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
$base='https://raw.githubusercontent.com/faxada88/porto-prime/4514e3144ef15f1354eb7ca034e4818781022b48/scripts/unified-wallet/'
Invoke-WebRequest ($base+'patches.json') -UseBasicParsing -OutFile (Join-Path $backup 'patches.json')
Invoke-WebRequest ($base+'request.dart') -UseBasicParsing -OutFile (Join-Path $backup 'request.dart')
$code=[IO.File]::ReadAllText($page).Replace("`r`n","`n")
$patches=ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $backup 'patches.json'),[Text.Encoding]::UTF8))
foreach($pair in $patches) {
  $before=[string]$pair[0]
  $after=[string]$pair[1]
  if($code.Contains($after)) { continue }
  if([regex]::Matches($code,[regex]::Escape($before)).Count -ne 1) { throw 'Versao local diferente. Nenhum arquivo alterado.' }
  $code=$code.Replace($before,$after)
}
Copy-Item $page (Join-Path $backup 'page.bak')
Copy-Item $widget (Join-Path $backup 'widget.bak')
Push-Location $mobile
try {
  [IO.File]::WriteAllText($page,$code,(New-Object Text.UTF8Encoding($false)))
  Copy-Item (Join-Path $backup 'request.dart') $widget -Force
  flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/courier/presentation/pages/courier_page.dart lib/features/courier/presentation/widgets/courier_withdrawal_request.dart
  if($LASTEXITCODE -ne 0) { throw 'Analise Flutter falhou.' }
  Write-Host "Carteira unificada. Backup: $backup"
} catch {
  Copy-Item (Join-Path $backup 'page.bak') $page -Force
  Copy-Item (Join-Path $backup 'widget.bak') $widget -Force
  throw
} finally { Pop-Location }
