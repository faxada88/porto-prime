$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$nl = [Environment]::NewLine
$branch = "feat/courier-preflight-20261029"
$raw = "https://raw.githubusercontent.com/faxada88/porto-prime/refs/heads/$branch"

$reg = Join-Path $root "apps\mobile\lib\features\profile\presentation\pages\registration_page.dart"
$pre = Join-Path $root "apps\mobile\lib\features\profile\presentation\pages\courier_preflight_page.dart"
$att = Join-Path $root "apps\mobile\lib\features\profile\presentation\pages\courier_certificate_attachment.dart"
$pub = Join-Path $root "apps\mobile\pubspec.yaml"
$lock = Join-Path $root "apps\mobile\pubspec.lock"
$mod = Join-Path $root "apps\api\src\auth\auth.module.ts"
$ctrl = Join-Path $root "apps\api\src\auth\courier-certificate.controller.ts"
$storage = Join-Path $root "apps\api\src\auth\courier-certificate-storage.ts"

$files = @($reg,$pre,$att,$pub,$lock,$mod,$ctrl,$storage)
$backup = Join-Path $env:TEMP ("porto-prime-cert-v3-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$exists = @{}

function SafeName([string]$p) {
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($p)).Replace("/","_").Replace("+","-")
}
function Save([string]$p) {
  $exists[$p] = Test-Path $p
  if ($exists[$p]) { Copy-Item $p (Join-Path $backup (SafeName $p)) -Force }
}
function Restore-All {
  foreach ($p in $files) {
    if ($exists[$p]) {
      Copy-Item (Join-Path $backup (SafeName $p)) $p -Force
    } elseif (Test-Path $p) {
      Remove-Item $p -Force
    }
  }
}
function WriteUtf8([string]$p,[string]$t) {
  [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false))
}

foreach ($p in $files) { Save $p }

try {
  if (!(Test-Path $reg)) { throw "registration_page.dart nao encontrado" }
  if (!(Test-Path $mod)) { throw "auth.module.ts nao encontrado" }

  Invoke-WebRequest "$raw/apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart" -UseBasicParsing -OutFile $pre
  Invoke-WebRequest "$raw/apps/mobile/lib/features/profile/presentation/pages/courier_certificate_attachment.dart" -UseBasicParsing -OutFile $att
  Invoke-WebRequest "$raw/apps/api/src/auth/courier-certificate.controller.ts" -UseBasicParsing -OutFile $ctrl
  Invoke-WebRequest "$raw/apps/api/src/auth/courier-certificate-storage.ts" -UseBasicParsing -OutFile $storage

  # registration_page.dart: somente insercoes pontuais
  $c = [IO.File]::ReadAllText($reg)

  if (!$c.Contains("import 'courier_certificate_attachment.dart';")) {
    $anchor = "import 'courier_preflight_page.dart';"
    if (!$c.Contains($anchor)) { throw "Import courier_preflight_page.dart nao encontrado" }
    $c = $c.Replace($anchor,$anchor + $nl + "import 'courier_certificate_attachment.dart';")
  }

  if (!$c.Contains("CourierCertificateSelection? criminalRecordCertificate;")) {
    $rx = [regex]::new("bool\s+courierPreflightComplete\s*=\s*false\s*;")
    $m = $rx.Match($c)
    if (!$m.Success) { throw "Estado courierPreflightComplete nao encontrado" }
    $c = $c.Substring(0,$m.Index+$m.Length) + $nl + "  CourierCertificateSelection? criminalRecordCertificate;" + $c.Substring($m.Index+$m.Length)
  }

  if (!$c.Contains("CourierCertificateAttachment(")) {
    $marker = "...groups[step].map(field),"
    $idx = $c.IndexOf($marker)
    if ($idx -lt 0) { throw "Lista de campos do formulario nao encontrada" }
    $lineStart = $c.LastIndexOf($nl,$idx)
    if ($lineStart -lt 0) { $lineStart = 0 } else { $lineStart += $nl.Length }
    $indent = $c.Substring($lineStart,$idx-$lineStart)
    $block = $indent + "if (courier && step == 3)" + $nl +
      $indent + "  CourierCertificateAttachment(" + $nl +
      $indent + "    value: criminalRecordCertificate," + $nl +
      $indent + "    onChanged: (value) => setState(() => criminalRecordCertificate = value)," + $nl +
      $indent + "  )," + $nl
    $c = $c.Insert($lineStart,$block)
  }

  if (!$c.Contains("'Anexe sua certidão'")) {
    $anchor = "Future<void> next() async {"
    $idx = $c.IndexOf($anchor)
    if ($idx -lt 0) { throw "Metodo next() nao encontrado" }
    $insertAt = $idx + $anchor.Length
    $block = $nl +
      "    if (courier && step == 3 && criminalRecordCertificate == null) {" + $nl +
      "      await _showInfo(" + $nl +
      "        'Anexe sua certidão'," + $nl +
      "        'Selecione a certidão de antecedentes criminais em PDF antes de continuar.'," + $nl +
      "        AppIcons.shield_outlined," + $nl +
      "      );" + $nl +
      "      return;" + $nl +
      "    }"
    $c = $c.Insert($insertAt,$block)
  }

  if (!$c.Contains("data['criminalRecordUploadToken']")) {
    $anchor = "final data = <String, dynamic>{"
    $idx = $c.IndexOf($anchor)
    if ($idx -lt 0) { throw "Mapa data do cadastro nao encontrado" }
    $close = $c.IndexOf("};",$idx)
    if ($close -lt 0) { throw "Final do mapa data nao encontrado" }
    $insertAt = $close + 2
    $block = $nl +
      "    if (courier) {" + $nl +
      "      data['criminalRecordUploadToken'] = criminalRecordCertificate?.uploadToken;" + $nl +
      "      data['criminalRecordFileName'] = criminalRecordCertificate?.fileName;" + $nl +
      "      data['criminalRecordFileSize'] = criminalRecordCertificate?.size;" + $nl +
      "    }"
    $c = $c.Insert($insertAt,$block)
  }

  WriteUtf8 $reg $c

  # auth.module.ts: registra controller isolado, sem tocar no AuthService
  $m = [IO.File]::ReadAllText($mod)
  if (!$m.Contains("CourierCertificateController")) {
    $anchor = "import { AuthController } from './auth.controller.js';"
    if (!$m.Contains($anchor)) { throw "Import AuthController nao encontrado" }
    $m = $m.Replace($anchor,$anchor + $nl + "import { CourierCertificateController } from './courier-certificate.controller.js';")

    if ($m.Contains("controllers: [AuthController],")) {
      $m = $m.Replace("controllers: [AuthController],","controllers: [AuthController, CourierCertificateController],")
    } else {
      throw "Lista controllers do AuthModule nao encontrada"
    }

    WriteUtf8 $mod $m
  }

  Push-Location (Join-Path $root "apps\mobile")
  try {
    if (!(Select-String -Path "pubspec.yaml" -Pattern "^\s*file_picker:" -Quiet)) {
      flutter pub add file_picker
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

  Push-Location (Join-Path $root "apps\api")
  try {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Build da API falhou" }
  } finally {
    Pop-Location
  }

  Write-Host ""
  Write-Host "ATUALIZACAO OK" -ForegroundColor Green
  Write-Host "Marcar todos / Desmarcar todos ativado." -ForegroundColor Green
  Write-Host "Anexo PDF da certidao ativado na etapa do veiculo." -ForegroundColor Green
  Write-Host "PDF salvo em armazenamento privado e token gravado no profileData." -ForegroundColor Green
  Write-Host "AuthService, Cliente e Parceiro nao foram alterados." -ForegroundColor Green
} catch {
  Restore-All
  Write-Host ""
  Write-Host "FALHA: tudo foi restaurado automaticamente." -ForegroundColor Red
  throw
} finally {
  Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
}
