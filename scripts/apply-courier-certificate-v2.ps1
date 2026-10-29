$ErrorActionPreference = "Stop"
$nl = [Environment]::NewLine
$root = Split-Path -Parent $PSScriptRoot
$branch = "feat/courier-preflight-20261029"
$baseCommit = "e7b0c17f430ed4d3f1941603372be7c5a0ed12cc"
$remoteRef = "origin/$branch"
$raw = "https://raw.githubusercontent.com/faxada88/porto-prime/refs/heads/$branch"

Set-Location $root
git fetch origin $branch
if ($LASTEXITCODE -ne 0) { throw "Falha ao atualizar a branch de instalacao" }

$paths = @(
  "apps/mobile/lib/features/profile/presentation/pages/registration_page.dart",
  "apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart",
  "apps/mobile/lib/features/profile/presentation/pages/courier_certificate_attachment.dart",
  "apps/mobile/pubspec.yaml",
  "apps/mobile/pubspec.lock",
  "apps/api/src/auth/auth.controller.ts",
  "apps/api/src/auth/auth.service.ts",
  "apps/api/src/auth/courier-certificate-storage.ts"
)

$backupDir = Join-Path $env:TEMP ("porto-prime-cert-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$existed = @{}

foreach ($path in $paths) {
  $full = Join-Path $root $path
  $existed[$path] = Test-Path $full
  if ($existed[$path]) {
    $safe = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($path)).Replace("/", "_")
    Copy-Item $full (Join-Path $backupDir $safe) -Force
  }
}

function Restore-All {
  foreach ($path in $paths) {
    $full = Join-Path $root $path
    if ($existed[$path]) {
      $safe = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($path)).Replace("/", "_")
      Copy-Item (Join-Path $backupDir $safe) $full -Force
    } elseif (Test-Path $full) {
      Remove-Item $full -Force
    }
  }
}

function Write-Utf8([string]$path, [string]$text) {
  [IO.File]::WriteAllText($path, $text, [Text.UTF8Encoding]::new($false))
}

function Git-Text([string]$spec) {
  $lines = @(& git show $spec)
  if ($LASTEXITCODE -ne 0) { throw "Nao foi possivel ler $spec" }
  return ($lines -join $nl) + $nl
}

function Merge-File([string]$path) {
  $local = Join-Path $root $path
  if (!(Test-Path $local)) { throw "Arquivo local nao encontrado: $path" }

  $baseTmp = Join-Path $backupDir "base.tmp"
  $newTmp = Join-Path $backupDir "new.tmp"

  Write-Utf8 $baseTmp (Git-Text ($baseCommit + ":" + $path))
  Write-Utf8 $newTmp (Git-Text ($remoteRef + ":" + $path))

  $mergedLines = @(& git merge-file -p -- $local $baseTmp $newTmp)
  $code = $LASTEXITCODE
  $merged = ($mergedLines -join $nl) + $nl

  if ($code -ne 0) {
    throw "Conflito ao atualizar $path. Nenhuma alteracao sera mantida."
  }

  Write-Utf8 $local $merged
}

try {
  Merge-File "apps/mobile/lib/features/profile/presentation/pages/registration_page.dart"
  Merge-File "apps/api/src/auth/auth.controller.ts"
  Merge-File "apps/api/src/auth/auth.service.ts"

  Invoke-WebRequest ($raw + "/apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart") -UseBasicParsing -OutFile (Join-Path $root "apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart")
  Invoke-WebRequest ($raw + "/apps/mobile/lib/features/profile/presentation/pages/courier_certificate_attachment.dart") -UseBasicParsing -OutFile (Join-Path $root "apps/mobile/lib/features/profile/presentation/pages/courier_certificate_attachment.dart")
  Invoke-WebRequest ($raw + "/apps/api/src/auth/courier-certificate-storage.ts") -UseBasicParsing -OutFile (Join-Path $root "apps/api/src/auth/courier-certificate-storage.ts")

  Push-Location (Join-Path $root "apps/mobile")
  try {
    if (!(Select-String -Path "pubspec.yaml" -Pattern "^\s*file_picker:" -Quiet)) {
      flutter pub add file_picker:^13.3.0
      if ($LASTEXITCODE -ne 0) { throw "Falha ao adicionar file_picker" }
    } else {
      flutter pub get
      if ($LASTEXITCODE -ne 0) { throw "flutter pub get falhou" }
    }

    flutter analyze --no-fatal-infos --no-fatal-warnings "lib/features/profile/presentation/pages/registration_page.dart" "lib/features/profile/presentation/pages/courier_preflight_page.dart" "lib/features/profile/presentation/pages/courier_certificate_attachment.dart"
    if ($LASTEXITCODE -ne 0) { throw "Flutter analyze falhou" }
  } finally {
    Pop-Location
  }

  Push-Location (Join-Path $root "apps/api")
  try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Build da API falhou" }
  } finally {
    Pop-Location
  }

  Write-Host ""
  Write-Host "ATUALIZACAO CONCLUIDA" -ForegroundColor Green
  Write-Host "Checklist: Marcar todos / Desmarcar todos" -ForegroundColor Green
  Write-Host "Formulario: anexo obrigatorio da certidao em PDF no meio do fluxo" -ForegroundColor Green
  Write-Host "Arquivo: somente PDF, maximo 5 MB, armazenamento privado" -ForegroundColor Green
  Write-Host "Cliente e Parceiro: sem alteracoes" -ForegroundColor Green
  Write-Host ""
  git status --short -- $paths
} catch {
  Restore-All
  throw
} finally {
  Remove-Item $backupDir -Recurse -Force -ErrorAction SilentlyContinue
}
