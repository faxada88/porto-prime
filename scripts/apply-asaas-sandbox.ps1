$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$api = Join-Path $root 'apps/api'
if (Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue) { throw 'Pare o Nest com Ctrl+C antes de atualizar. Banco, Admin e Stripe podem continuar ligados.' }
$envPath = Join-Path $api '.env'
$envText = [IO.File]::ReadAllText($envPath)
if ($envText -notmatch '(?m)^\s*ASAAS_ENVIRONMENT\s*=\s*["'']?sandbox["'']?\s*$' -or $envText -notmatch '(?m)^\s*ASAAS_API_KEY\s*=\s*\S+') { throw 'Configure ASAAS_ENVIRONMENT=sandbox e ASAAS_API_KEY no .env da API.' }
$backup = Join-Path $env:TEMP ('porto-asaas-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backup | Out-Null
$stage = Join-Path $backup 'payload'
$zip = Join-Path $backup 'update.zip'
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/refs/heads/feat/courier-preflight-20261029/scripts/asaas-sandbox-update.zip' -UseBasicParsing -OutFile $zip
if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'fbbda2f85bc811df74be07bd27c20886b95b7cb055867a99c470562d2729c7bf') { throw 'Pacote diferente do esperado. Nenhuma alteracao aplicada.' }
Expand-Archive $zip -DestinationPath $stage
$manifest = Get-Content (Join-Path $stage 'manifest.json') -Raw | ConvertFrom-Json
function NormalizedHash([string]$path) {
  $value = [IO.File]::ReadAllText($path).Replace("`r`n", "`n").TrimStart([char]0xfeff)
  $sha = [Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($value)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
}
foreach ($item in $manifest) {
  $target = Join-Path $root $item.path
  if (Test-Path $target) {
    $hash = NormalizedHash $target
    if ($hash -ne $item.before -and $hash -ne $item.after) { throw "Arquivo local mudou: $($item.path). Nada foi substituido. Envie uma copia atual desse arquivo." }
  } elseif ($item.before) { throw "Arquivo ausente: $($item.path)" }
}
$changed = @()
Copy-Item $envPath (Join-Path $backup 'api.env')
try {
  foreach ($item in $manifest) {
    $target = Join-Path $root $item.path
    $previous = Join-Path $backup ('original/' + $item.path)
    $exists = Test-Path $target
    if ($exists) { New-Item -ItemType Directory -Force (Split-Path $previous) | Out-Null; Copy-Item $target $previous }
    $changed += @{target=$target; previous=$previous; existed=$exists}
    New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
    Copy-Item (Join-Path $stage $item.path) $target -Force
  }
  Push-Location $api
  try {
    npx prisma generate --config prisma7.config.ts
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar Prisma.' }
    npm run test -- src/wallet/asaas-payout.spec.ts src/wallet/wallet-withdrawal.spec.ts src/wallet/finance.spec.ts src/wallet/demand-credit.spec.ts
    if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes financeiros.' }
    npm run build
    if ($LASTEXITCODE -ne 0) { throw 'Falha no build da API.' }
  } finally { Pop-Location }
  Push-Location (Join-Path $root 'apps/mobile')
  try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependencias Flutter.' }
    flutter analyze --no-fatal-infos --no-fatal-warnings lib/core/state/app_state.dart lib/features/courier/presentation/pages/courier_page.dart
    if ($LASTEXITCODE -ne 0) { throw 'Falha na analise Flutter.' }
  } finally { Pop-Location }
  Push-Location $api
  try {
    npx prisma db execute --config prisma7.config.ts --file prisma/migrations/20261030_asaas_courier_payouts/migration.sql
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar a tabela de saques Asaas.' }
  } finally { Pop-Location }
  if ($envText -notmatch '(?m)^ASAAS_WEBHOOK_TOKEN=\S{32,}') {
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    $token = ([BitConverter]::ToString($bytes)).Replace('-','').ToLowerInvariant()
    $envText = [regex]::Replace($envText, '(?m)^ASAAS_WEBHOOK_TOKEN=.*\r?\n?', '')
    $envText += "`nASAAS_WEBHOOK_TOKEN=$token`n"
  }
  $envText = [regex]::Replace($envText, '(?m)^ASAAS_PAYOUTS_ENABLED=.*\r?\n?', '') + "`nASAAS_PAYOUTS_ENABLED=true`n"
  [IO.File]::WriteAllText($envPath, $envText, [Text.UTF8Encoding]::new($false))
  Write-Host "Asaas SANDBOX instalado. Backup: $backup"
  Write-Host 'Webhook: https://SEU-ENDERECO-PUBLICO/api/wallet/asaas/webhook. Token no .env: ASAAS_WEBHOOK_TOKEN.'
  Write-Host 'Configure eventos TRANSFER_* no Asaas. Dinheiro real e Stripe nao sao movimentados por esta integracao.'
} catch {
  foreach ($item in $changed) {
    if ($item.existed) { Copy-Item $item.previous $item.target -Force }
    else { Remove-Item $item.target -Force -ErrorAction SilentlyContinue }
  }
  Copy-Item (Join-Path $backup 'api.env') $envPath -Force
  Write-Host 'Arquivos restaurados. A tabela aditiva, se criada, foi preservada. Nao inicie a API antes de resolver o erro.'
  throw
}
