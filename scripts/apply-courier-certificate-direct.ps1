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
$svc = Join-Path $root "apps\api\src\auth\auth.service.ts"
$mod = Join-Path $root "apps\api\src\auth\auth.module.ts"
$ctrl = Join-Path $root "apps\api\src\auth\courier-certificate.controller.ts"
$storage = Join-Path $root "apps\api\src\auth\courier-certificate-storage.ts"

$files = @($reg,$pre,$att,$pub,$lock,$svc,$mod,$ctrl,$storage)
$backup = Join-Path $env:TEMP ("porto-prime-cert-direct-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$exists = @{}

function SafeName([string]$p) {
  return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($p)).Replace("/","_").Replace("+","-")
}
function Backup([string]$p) {
  $exists[$p] = Test-Path $p
  if ($exists[$p]) { Copy-Item $p (Join-Path $backup (SafeName $p)) -Force }
}
function Restore-All {
  foreach ($p in $files) {
    if ($exists[$p]) { Copy-Item (Join-Path $backup (SafeName $p)) $p -Force }
    elseif (Test-Path $p) { Remove-Item $p -Force }
  }
}
function WriteUtf8([string]$p,[string]$t) {
  [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false))
}

foreach ($p in $files) { Backup $p }

try {
  if (!(Test-Path $reg)) { throw "registration_page.dart nao encontrado" }
  if (!(Test-Path $svc)) { throw "auth.service.ts nao encontrado" }
  if (!(Test-Path $mod)) { throw "auth.module.ts nao encontrado" }

  Invoke-WebRequest "$raw/apps/mobile/lib/features/profile/presentation/pages/courier_preflight_page.dart" -UseBasicParsing -OutFile $pre
  Invoke-WebRequest "$raw/apps/mobile/lib/features/profile/presentation/pages/courier_certificate_attachment.dart" -UseBasicParsing -OutFile $att
  Invoke-WebRequest "$raw/apps/api/src/auth/courier-certificate.controller.ts" -UseBasicParsing -OutFile $ctrl
  Invoke-WebRequest "$raw/apps/api/src/auth/courier-certificate-storage.ts" -UseBasicParsing -OutFile $storage

  $c = [IO.File]::ReadAllText($reg)

  if (!$c.Contains("import 'courier_certificate_attachment.dart';")) {
    $anchor = "import 'courier_preflight_page.dart';"
    if (!$c.Contains($anchor)) { throw "Import do pre-checklist nao encontrado" }
    $c = $c.Replace($anchor,$anchor + $nl + "import 'courier_certificate_attachment.dart';")
  }

  if (!$c.Contains("CourierCertificateSelection? criminalRecordCertificate;")) {
    $rx = [regex]::new("bool\s+courierPreflightComplete\s*=\s*false\s*;")
    $m = $rx.Match($c)
    if (!$m.Success) { throw "Estado do pre-checklist nao encontrado" }
    $c = $c.Substring(0,$m.Index+$m.Length) + $nl + "  CourierCertificateSelection? criminalRecordCertificate;" + $c.Substring($m.Index+$m.Length)
  }

  if (!$c.Contains("CourierCertificateAttachment(")) {
    $marker = "...groups[step].map(field),"
    $idx = $c.IndexOf($marker)
    if ($idx -lt 0) { throw "Lista de campos do formulario nao encontrada" }
    $start = $c.LastIndexOf($nl,$idx)
    if ($start -lt 0) { $start = 0 } else { $start += $nl.Length }
    $indent = $c.Substring($start,$idx-$start)
    $block = $indent + "if (courier && step == 3)" + $nl +
      $indent + "  CourierCertificateAttachment(" + $nl +
      $indent + "    value: criminalRecordCertificate," + $nl +
      $indent + "    onChanged: (value) => setState(() => criminalRecordCertificate = value)," + $nl +
      $indent + "  )," + $nl
    $c = $c.Insert($start,$block)
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
    $block = $nl + "    if (courier) {" + $nl +
      "      data['criminalRecordUploadToken'] =" + $nl +
      "          criminalRecordCertificate?.uploadToken;" + $nl +
      "    }"
    $c = $c.Insert($insertAt,$block)
  }

  WriteUtf8 $reg $c

  $c = [IO.File]::ReadAllText($mod)
  if (!$c.Contains("CourierCertificateController")) {
    $anchor = "import { AuthController } from './auth.controller.js';"
    if (!$c.Contains($anchor)) { throw "Import AuthController nao encontrado" }
    $c = $c.Replace($anchor,$anchor + $nl + "import { CourierCertificateController } from './courier-certificate.controller.js';")
    $c = $c.Replace("controllers: [AuthController]","controllers: [AuthController, CourierCertificateController]")
    WriteUtf8 $mod $c
  }

  $c = [IO.File]::ReadAllText($svc)
  if (!$c.Contains("courier-certificate-storage")) {
    $anchor = "import { RegisterDto } from './dto/register.dto.js';"
    if (!$c.Contains($anchor)) { throw "Import RegisterDto nao encontrado" }
    $c = $c.Replace($anchor,$anchor + $nl + "import { CourierCertificateStorage } from './courier-certificate-storage.js';")
  }

  if (!$c.Contains("profileData['criminalRecordCertificate']")) {
    $register = $c.IndexOf("async register(")
    $forgot = $c.IndexOf("async forgotPassword",$register)
    if ($register -lt 0 -or $forgot -lt 0) { throw "Metodo register do backend nao encontrado" }
    $part = $c.Substring($register,$forgot-$register)

    $rx = [regex]::new("const\s+onboardingData\s*=\s*data\.profileData\s*\?\s*\(data\.profileData\s+as\s+Prisma\.InputJsonObject\)\s*:\s*undefined\s*;")
    $m = $rx.Match($part)
    if (!$m.Success) { throw "Bloco onboardingData nao encontrado" }

    $replacement = "const profileData: Record<string, unknown> = data.profileData" + $nl +
      "      ? { ...data.profileData }" + $nl +
      "      : {};" + $nl + $nl +
      "    let certificateFile:" + $nl +
      "      | Awaited<ReturnType<typeof CourierCertificateStorage.consume>>" + $nl +
      "      | null = null;" + $nl + $nl +
      "    if (data.role === UserRole.COURIER) {" + $nl +
      "      const uploadToken = profileData['criminalRecordUploadToken'];" + $nl +
      "      if (!uploadToken) {" + $nl +
      "        throw new BadRequestException(" + $nl +
      "          'Anexe a certidão de antecedentes criminais em PDF'," + $nl +
      "        );" + $nl +
      "      }" + $nl +
      "      certificateFile = await CourierCertificateStorage.consume(uploadToken);" + $nl +
      "      delete profileData['criminalRecordUploadToken'];" + $nl +
      "      profileData['criminalRecordCertificate'] = certificateFile.metadata;" + $nl +
      "    }" + $nl + $nl +
      "    const onboardingData =" + $nl +
      "      Object.keys(profileData).length > 0" + $nl +
      "        ? (profileData as Prisma.InputJsonObject)" + $nl +
      "        : undefined;"

    $part = $part.Substring(0,$m.Index) + $replacement + $part.Substring($m.Index+$m.Length)

    $rxCreate = [regex]::new("const\s+user\s*=\s*await\s+this\.prisma\.user\.create\(\{")
    $m = $rxCreate.Match($part)
    if (!$m.Success) { throw "Criacao do usuario nao encontrada" }
    $part = $part.Substring(0,$m.Index) + "let user;" + $nl + "    try {" + $nl + "      user = await this.prisma.user.create({" + $part.Substring($m.Index+$m.Length)

    $ret = $part.LastIndexOf("return this.publicUser(user);")
    if ($ret -lt 0) { throw "Retorno do cadastro nao encontrado" }
    $close = $part.LastIndexOf("});",$ret)
    if ($close -lt 0) { throw "Fechamento da criacao do usuario nao encontrado" }
    $catch = "});" + $nl +
      "    } catch (error) {" + $nl +
      "      await CourierCertificateStorage.rollback(certificateFile?.absolutePath);" + $nl +
      "      throw error;" + $nl +
      "    }"
    $part = $part.Substring(0,$close) + $catch + $part.Substring($close+3)

    $c = $c.Substring(0,$register) + $part + $c.Substring($forgot)
  }

  WriteUtf8 $svc $c

  Push-Location (Join-Path $root "apps\mobile")
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
  Write-Host "Cliente e Parceiro preservados." -ForegroundColor Green
} catch {
  Restore-All
  Write-Host ""
  Write-Host "FALHA: tudo foi restaurado automaticamente." -ForegroundColor Red
  throw
} finally {
  Remove-Item $backup -Recurse -Force -ErrorAction SilentlyContinue
}
