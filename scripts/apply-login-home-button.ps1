$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$file = Join-Path $root 'apps/mobile/lib/features/profile/presentation/pages/profile_page.dart'
$backup = Join-Path $env:TEMP ('porto-login-' + [guid]::NewGuid().ToString('N') + '.dart')
Copy-Item $file $backup
try {
  $code = [IO.File]::ReadAllText($file)
  if (!$code.Contains('porto-login-back-home')) {
    $rx = [regex]::new('(?s)(Future<void>\s+_auth\(BuildContext context\).*?builder:\s*\(ctx\)\s*=>\s*_PrimeSheet\(\s*children:\s*\[)')
    if ($rx.Matches($code).Count -ne 1) { throw 'Estrutura do login diferente. Arquivo preservado; envie o profile_page.dart para adaptar.' }
    $insert = @'

        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('porto-login-back-home'),
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              Navigator.of(ctx).pop();
              AppNav.instance.home();
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
            label: const Text('Voltar ao início'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF073E43),
              minimumSize: const Size(48, 48),
            ),
          ),
        ),

'@
    $match = $rx.Match($code)
    $code = $code.Insert($match.Index + $match.Length, $insert)
    if (!$code.Contains("import '../../../../core/navigation/app_nav.dart';")) {
      $code = "import '../../../../core/navigation/app_nav.dart';`n" + $code
    }
    [IO.File]::WriteAllText($file, $code, [Text.UTF8Encoding]::new($false))
  }
  Push-Location (Join-Path $root 'apps/mobile')
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependencias.' }
    flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/profile/presentation/pages/profile_page.dart
    if ($LASTEXITCODE -ne 0) { throw 'Falha na analise Flutter.' }
  } finally { Pop-Location }
  Write-Host "Botao de retorno instalado. Backup: $backup"
} catch {
  Copy-Item $backup $file -Force
  throw
}
