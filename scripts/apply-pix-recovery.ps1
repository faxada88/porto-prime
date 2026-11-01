param([string]$ProjectRoot='C:\Users\conta\porto-prime-github')
$ErrorActionPreference='Stop'
foreach($port in @(3000)) {
  if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
    throw "Pare o Nest com Ctrl+C antes de executar. Porta $port ainda ocupada; nada foi alterado."
  }
}
$backup=Join-Path $env:TEMP ('porto-pix-sync-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
Invoke-WebRequest 'https://raw.githubusercontent.com/faxada88/porto-prime/725155a838c2ed794353016435462d17af7c9fff/scripts/payloads/pix-recovery.json' -UseBasicParsing -OutFile (Join-Path $backup 'manifest.json')
$items=ConvertFrom-Json ([IO.File]::ReadAllText((Join-Path $backup 'manifest.json'),[Text.Encoding]::UTF8))
function HashText([string]$value) {
  $sha=[Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($value)))).Replace('-','').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
$prepared=@()
foreach($item in $items) {
  $path=Join-Path $ProjectRoot $item.path
  $exists=Test-Path $path
  $old=if($exists){[IO.File]::ReadAllText($path).Replace("`r`n","`n")}else{''}
  if($exists -and (HashText $old) -eq $item.after) { continue }
  if($null -eq $item.before) {
    if($exists) { throw "Arquivo novo ja existe com outro conteudo: $($item.path). Nada alterado." }
    $new=[string]$item.content
  } else {
    if(!$exists -or (HashText $old) -ne $item.before) { throw "Arquivo diferente do ZIP analisado: $($item.path). Nada alterado." }
    $new=$old
    foreach($edit in $item.edits) {
      $start=[int]$edit.start
      $length=([string]$edit.old).Length
      if($new.Substring($start,$length) -cne [string]$edit.old) { throw 'Trecho divergente. Nada alterado.' }
      $new=$new.Remove($start,$length).Insert($start,[string]$edit.new)
    }
  }
  if((HashText $new) -ne $item.after) { throw 'Falha de integridade. Nada alterado.' }
  $saved=Join-Path $backup $item.path
  New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null
  if($exists){Copy-Item $path $saved}
  $prepared+=@{path=$path; saved=$saved; existed=$exists; content=$new}
}
try {
  foreach($p in $prepared) {
    New-Item -ItemType Directory -Path (Split-Path $p.path) -Force | Out-Null
    [IO.File]::WriteAllText($p.path,$p.content,(New-Object Text.UTF8Encoding($false)))
  }
  Push-Location (Join-Path $ProjectRoot 'apps\api')
  try {
    npm test -- src/wallet/asaas-recovery.spec.ts src/wallet/asaas-sync.spec.ts src/wallet/asaas-payout.spec.ts src/wallet/asaas-authorization.spec.ts src/wallet/wallet-withdrawal.spec.ts src/wallet/finance.spec.ts src/wallet/demand-credit.spec.ts
    if($LASTEXITCODE -ne 0){throw 'Testes da carteira falharam.'}
    npm run build
    if($LASTEXITCODE -ne 0){throw 'Build da API falhou.'}
  } finally {Pop-Location}
} catch {
  foreach($p in $prepared) {
    if($p.existed){Copy-Item $p.saved $p.path -Force}
    elseif(Test-Path $p.path){Remove-Item $p.path -Force}
  }
  throw "Arquivos restaurados. $($_.Exception.Message)"
}
Write-Host "Correcao instalada. Backup: $backup"
Write-Host "O Nest conciliara automaticamente saques sem ID com mais de 2 minutos."
Write-Host "HTTP 409 sem transferencia vinculada: saldo devolvido uma unica vez."
Push-Location (Join-Path $ProjectRoot 'apps\api')
try {
  npm run start:dev
  if($LASTEXITCODE -ne 0){throw 'Nest nao iniciou. Envie o erro acima.'}
} finally {Pop-Location}
