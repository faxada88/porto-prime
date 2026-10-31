param([string]$ProjectRoot='C:\Users\conta\porto-prime-github')
$ErrorActionPreference='Stop'
$mobile=Join-Path $ProjectRoot 'apps\mobile'
$page=Join-Path $mobile 'lib\features\courier\presentation\pages\courier_page.dart'
$original=[IO.File]::ReadAllText($page)
$code=$original.Replace("`r`n","`n")
$oldPrefix=@'
PopScope(canPop: !loading, child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.elevated,
              ),
              child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PrimeText(
                    'Solicitar saque',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: AppFontWeight.display,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  PrimeText(
                    'Disponível: ' +
                        _money(
                          AppState.instance
                              .walletSummary['availableBalance'],
                        ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.strong,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(scrollPadding: const EdgeInsets.all(80), controller: controller,
                    enabled: !loading,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const PrimeInputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      prefixIcon: Icon(AppIcons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(isExpanded: true, itemHeight: null, 
                    initialValue: pixType,
                    decoration: const PrimeInputDecoration(labelText: 'Tipo de chave PIX'),
                    items: const [DropdownMenuItem(value:'CPF',child:PrimeText('CPF')),DropdownMenuItem(value:'CNPJ',child:PrimeText('CNPJ')),DropdownMenuItem(value:'EMAIL',child:PrimeText('E-mail')),DropdownMenuItem(value:'PHONE',child:PrimeText('Celular')),DropdownMenuItem(value:'RANDOM',child:PrimeText('Aleatória'))],
                    onChanged: loading ? null : (value) => setDialogState(() => pixType = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(scrollPadding: const EdgeInsets.all(80), controller: pixController, enabled: !loading, decoration: const PrimeInputDecoration(labelText: 'Chave PIX de recebimento', helperText: 'Confira a chave antes de solicitar o saque.')),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.peach,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: PrimeText(PrimeMessages.friendly(error!),
                        style: const TextStyle(
                          color: AppColors.coralStrong,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.strong,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const PrimeText(
                    'Sua solicitação de saque ficará pendente até o processamento.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                      height: 1.4,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const PrimeText('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : 
'@
$oldSuffix=@'
},
                          child: loading
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const PrimeText('Solicitar'),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
'@
$newPrefix=@'
PopScope(canPop: !loading, child: CourierWithdrawalRequestPanel(
            availableBalance: double.tryParse(AppState.instance.walletSummary['availableBalance']?.toString() ?? '') ?? 0,
            amountController: controller,
            pixController: pixController,
            pixType: pixType,
            onPixTypeChanged: (value) => setDialogState(() => pixType = value),
            loading: loading,
            error: error == null ? null : PrimeMessages.friendly(error!),
            onCancel: () => Navigator.pop(dialogContext),
            onSubmit: 
'@
if (!$code.Contains('CourierWithdrawalRequestPanel(')) {
  if ([regex]::Matches($code,[regex]::Escape($oldPrefix)).Count -ne 1 -or [regex]::Matches($code,[regex]::Escape($oldSuffix)).Count -ne 1) {
    throw 'O formulario local difere da versao conhecida. Nenhum arquivo alterado. Envie courier_page.dart para adaptar com seguranca.'
  }
  $code=$code.Replace($oldPrefix,$newPrefix).Replace($oldSuffix,"},`n          )),")
  $import="import '../widgets/courier_withdrawal_request.dart';"
  if (!$code.Contains($import)) { $code=$import+"`n"+$code }
}
if (!$code.Contains('CourierWithdrawalFeedback(')) { throw 'Confirmacao de saque ausente. Nenhum arquivo alterado.' }
$folder=Join-Path $mobile 'lib\features\courier\presentation\widgets'
$backup=Join-Path $env:TEMP ('porto-modais-v2-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $backup | Out-Null
Copy-Item $page (Join-Path $backup 'courier_page.dart')
$files=@('courier_withdrawal_request.dart','courier_withdrawal_feedback.dart')
$existing=@{}
foreach($file in $files) {
  $target=Join-Path $folder $file
  $existing[$file]=Test-Path $target
  if($existing[$file]) { Copy-Item $target (Join-Path $backup $file) }
  Invoke-WebRequest ("https://raw.githubusercontent.com/faxada88/porto-prime/ee8d980b34bf765a5f6d6c2462cdb8437ea7c7c3/scripts/withdrawal-reference/"+$file) -UseBasicParsing -OutFile (Join-Path $backup ($file+'.new'))
}
Push-Location $mobile
try {
  [IO.File]::WriteAllText($page,$code,(New-Object Text.UTF8Encoding($false)))
  foreach($file in $files) { Copy-Item (Join-Path $backup ($file+'.new')) (Join-Path $folder $file) -Force }
  flutter analyze --no-fatal-infos --no-fatal-warnings lib/features/courier/presentation/widgets/courier_withdrawal_request.dart lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart lib/features/courier/presentation/pages/courier_page.dart
  if($LASTEXITCODE -ne 0) { throw 'Analise Flutter falhou.' }
  Write-Host "Modais atualizados. Backup: $backup"
} catch {
  Copy-Item (Join-Path $backup 'courier_page.dart') $page -Force
  foreach($file in $files) {
    $target=Join-Path $folder $file
    if($existing[$file]) { Copy-Item (Join-Path $backup $file) $target -Force }
    elseif(Test-Path $target) { Remove-Item $target -Force }
  }
  throw
} finally { Pop-Location }
