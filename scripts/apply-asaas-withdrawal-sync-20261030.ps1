param(
  [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path
if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
  throw "Abra o repositorio Porto Prime antes de executar este instalador: $RepoRoot"
}

function Read-RepoFile([string]$RelativePath) {
  $path = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $path)) { throw "Arquivo obrigatorio nao encontrado: $RelativePath" }
  return [System.IO.File]::ReadAllText($path)
}

function Replace-Once([string]$Content, [string]$Old, [string]$New, [string]$Marker, [string]$Label) {
  # Normaliza somente durante a comparacao; preserva o final de linha original ao retornar.
  $newline = if ($Content.Contains("`r`n")) { "`r`n" } else { "`n" }
  $contentLf = $Content.Replace("`r`n", "`n")
  $oldLf = $Old.Replace("`r`n", "`n")
  $newLf = $New.Replace("`r`n", "`n")
  $markerLf = $Marker.Replace("`r`n", "`n")
  if ($contentLf.Contains($markerLf)) { return $Content }
  $count = [regex]::Matches($contentLf, [regex]::Escape($oldLf)).Count
  if ($count -ne 1) { throw "Checkpoint de seguranca: esperava 1 ocorrencia de '$Label', encontrei $count. Nenhum arquivo foi gravado." }
  $updated = $contentLf.Replace($oldLf, $newLf)
  if ($newline -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
  return $updated
}
function Replace-RegexOnce([string]$Content, [string]$Pattern, [string]$New, [string]$Marker, [string]$Label) {
  # Usa marcadores ASCII para tolerar acentos antigos corrompidos no arquivo Flutter.
  $newline = if ($Content.Contains("`r`n")) { "`r`n" } else { "`n" }
  $contentLf = $Content.Replace("`r`n", "`n")
  $newLf = $New.Replace("`r`n", "`n")
  if ($contentLf.Contains($Marker)) { return $Content }
  $matches = [regex]::Matches($contentLf, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($matches.Count -ne 1) { throw "Checkpoint de seguranca: esperava 1 ocorrencia de '$Label', encontrei $($matches.Count). Nenhum arquivo foi gravado." }
  $match = $matches[0]
  $updated = $contentLf.Substring(0, $match.Index) + $newLf + $contentLf.Substring($match.Index + $match.Length)
  if ($newline -eq "`r`n") { $updated = $updated.Replace("`n", "`r`n") }
  return $updated
}
$changes = [ordered]@{}

# API: expor o estado Asaas no historico e disparar o envio imediatamente.
$wallet = Read-RepoFile 'apps/api/src/wallet/wallet.service.ts'
$oldWithdrawals = @'
  async withdrawals(authorization?: string) {
    const courier = await this.authenticatedCourier(authorization);
    return this.prisma.withdrawal.findMany({
      where: { courierId: courier.id },
      orderBy: { requestedAt: 'desc' },
    });
  }
'@
$newWithdrawals = @'
  async withdrawals(authorization?: string) {
    const courier = await this.authenticatedCourier(authorization);
    return this.prisma.withdrawal.findMany({
      where: { courierId: courier.id },
      include: {
        asaasPayout: {
          select: {
            transferId: true,
            state: true,
            providerStatus: true,
            lastError: true,
            environment: true,
            updatedAt: true,
          },
        },
      },
      orderBy: { requestedAt: 'desc' },
    });
  }
'@
$wallet = Replace-Once $wallet $oldWithdrawals $newWithdrawals 'providerStatus: true' 'WalletService.withdrawals com estado Asaas'

$oldNotifyReturn = @'
    await this.notifyWallet(courier.id);
    return withdrawal;
  }

  async adminWithdrawals
'@
$newNotifyReturn = @'
    if (automatic) {
      void this.payouts?.send(withdrawal.id).catch(() => undefined);
    }
    await this.notifyWallet(courier.id);
    return withdrawal;
  }

  async adminWithdrawals
'@
$wallet = Replace-Once $wallet $oldNotifyReturn $newNotifyReturn 'this.payouts?.send(withdrawal.id)' 'disparo imediato do saque Asaas'
if (-not $wallet.Contains('Saque integrado ao Asaas: status atualizado')) {
  throw 'O bloqueio de alteracao manual dos saques Asaas nao foi encontrado em WalletService. Nenhum arquivo foi gravado.'
}
$changes['apps/api/src/wallet/wallet.service.ts'] = $wallet

# API: informar bloqueio do provedor sem concluir nem estornar indevidamente.
$asaas = Read-RepoFile 'apps/api/src/wallet/asaas-payout.service.ts'
$oldUnknown = @'
      await this.db.asaasPayout.updateMany({ where: { withdrawalId: id, state: 'SENDING' }, data: { state: 'UNKNOWN', lastError: 'Envio sem confirmacao. Conciliar antes de qualquer nova tentativa.' } });
'@
$newUnknown = @'
      await this.db.asaasPayout.updateMany({ where: { withdrawalId: id, state: 'SENDING' }, data: { state: 'UNKNOWN', lastError: 'Envio sem confirmacao. Conciliar antes de qualquer nova tentativa.' } });
      const pendingWithdrawal = await this.db.withdrawal.findUnique({ where: { id }, select: { courierId: true } });
      if (pendingWithdrawal?.courierId) await this.notify(pendingWithdrawal.courierId);
'@
$asaas = Replace-Once $asaas $oldUnknown $newUnknown 'pendingWithdrawal?.courierId' 'notificacao de envio sem confirmacao'

$oldBlocked = "lastError: failed ? 'Transferencia nao concluida pelo Asaas.' : null"
$newBlocked = "lastError: failed ? 'Transferencia nao concluida pelo Asaas.' : state === 'BLOCKED' ? 'Transferencia bloqueada pelo Asaas. Verifique a autorizacao no painel do provedor.' : null"
$asaas = Replace-Once $asaas $oldBlocked $newBlocked 'Verifique a autorizacao no painel do provedor' 'mensagem de bloqueio Asaas'
$asaas = Replace-Once $asaas "take: 100 }) };" "take: 500 }) };" "take: 500 }) };" "ampliar conciliacao para todos os saques ativos"
$changes['apps/api/src/wallet/asaas-payout.service.ts'] = $asaas

# ADMIN: consultar Asaas, impedir confirmacao/rejeicao manual e oferecer conciliacao segura.
$finance = Read-RepoFile 'apps/admin/src/app/finance-panel.tsx'
$oldState = ' const [overview,setOverview]=useState<Row>({rows:[],stats:{}}),[accounts,setAccounts]=useState<Row[]>([]),[accountId,setAccountId]=useState(initialAccountId),[detail,setDetail]=useState<Row|null>(null);'
$newState = $oldState + [Environment]::NewLine + ' const [asaasPayouts,setAsaasPayouts]=useState<Row[]>([]),[asaasReady,setAsaasReady]=useState(false);'
$finance = Replace-Once $finance $oldState $newState 'asaasPayouts,setAsaasPayouts' 'estado Asaas no FinancePanel'

$oldRefresh = "useEffect(()=>{let live=true; const refresh=async()=>{try{const [o,a]=await Promise.all([api('/finance/admin/overview',token),api('/finance/admin/accounts?search='+encodeURIComponent(accountQuery),token)]);if(live){setOverview(o);setAccounts(a);setError('')}}catch(e:any){if(live)setError(displayMessage(e.message))}finally{if(live)setLoading(false)}};refresh();const id=setInterval(refresh,10000);return()=>{live=false;clearInterval(id)}},[token,rows,revision,api,accountQuery]);"
$newRefresh = "useEffect(()=>{let live=true; const refresh=async()=>{try{const [o,a,p]=await Promise.all([api('/finance/admin/overview',token),api('/finance/admin/accounts?search='+encodeURIComponent(accountQuery),token),api('/wallet/asaas/status',token).then((data:any)=>({ok:true,data})).catch(()=>({ok:false,data:null}))]);if(live){setOverview(o);setAccounts(a);setAsaasReady(p.ok);setAsaasPayouts(Array.isArray(p.data?.pending)?p.data.pending:[]);setError('')}}catch(e:any){if(live)setError(displayMessage(e.message))}finally{if(live)setLoading(false)}};refresh();const id=setInterval(refresh,10000);return()=>{live=false;clearInterval(id)}},[token,rows,revision,api,accountQuery]);"
$finance = Replace-Once $finance $oldRefresh $newRefresh 'setAsaasReady(p.ok)' 'consulta periodica do Asaas'

if (-not $finance.Contains('const reconcileAsaas=')) {
  $anchor = ' const availableRows=overview.rows.filter'
  $start = $finance.IndexOf($anchor)
  if ($start -lt 0) { throw 'Nao encontrei o ponto de insercao do mapa Asaas no FinancePanel. Nenhum arquivo foi gravado.' }
  $newline = if ($finance.Contains("`r`n")) { "`r`n" } else { "`n" }
  $end = $finance.IndexOf($newline, $start)
  $helpers = @'
 const asaasFor=(id:any)=>asaasPayouts.find((p:Row)=>p.withdrawalId===id);
 const asaasLabel=(p:Row)=>{
  const provider=String(p.providerStatus||'').toUpperCase(),state=String(p.state||'').toUpperCase();
  if(state==='QUEUED')return 'Aguardando envio ao Asaas';
  if(state==='SENDING')return 'Enviando solicitacao ao Asaas';
  if(state==='UNKNOWN')return 'Envio sem confirmacao · conciliacao necessaria';
  const labels:Row={PENDING:'Pendente no Asaas',BANK_PROCESSING:'Em processamento bancario',IN_BANK_PROCESSING:'Em processamento bancario',BLOCKED:'Bloqueado no Asaas · verifique autorizacao',DONE:'Pix concluido pelo Asaas',FAILED:'Transferencia recusada pelo Asaas',CANCELLED:'Transferencia cancelada no Asaas'};
  return labels[provider]||'Aguardando confirmacao do Asaas';
 };
 const reconcileAsaas=async(transferId:string)=>{
  try{await api('/wallet/asaas/reconcile',token,'POST',{transferId});setRevision(n=>n+1);setNotice('Status consultado diretamente no Asaas.')}
  catch(e:any){setError(displayMessage(e.message))}
 };
'@
  $helpers = $helpers.Replace("`r`n", "`n").Replace("`n", $newline)
  $finance = $finance.Insert($end + $newline.Length, $helpers + $newline)
}

$oldStatus = " const status=(w:Row,next:string)=>{setForm({...w,nextStatus:next,reason:'',reference:'',receiptUrl:''});setFormError('');setOperation('status')};"
$newStatus = " const status=(w:Row,next:string)=>{if(w.asaasPayout||asaasFor(w.id)){setNotice('Saque integrado ao Asaas: acompanhe a confirmacao do provedor.');return}if(!asaasReady){setNotice('A integracao Asaas ainda nao foi consultada. Nenhuma acao manual foi liberada.');return}setForm({...w,nextStatus:next,reason:'',reference:'',receiptUrl:''});setFormError('');setOperation('status')};"
$finance = Replace-Once $finance $oldStatus $newStatus 'acompanhe a confirmacao do provedor' 'bloqueio de status manual'

$oldSubmit = "const submit=async(e:React.FormEvent)=>{e.preventDefault();if(savingRef.current)return;"
$newSubmit = "const submit=async(e:React.FormEvent)=>{e.preventDefault();if(operation==='status'&&(!asaasReady||form.asaasPayout||asaasFor(form.id))){setFormError('Saques integrados ao Asaas sao atualizados exclusivamente pela confirmacao do provedor.');return}if(savingRef.current)return;"
$finance = Replace-Once $finance $oldSubmit $newSubmit 'atualizados exclusivamente pela confirmacao' 'protecao do modal administrativo'

$oldActions = @'
 const actions=(w:Row)=><div className="financeRowActions">{w.status==='PENDING'&&<button onClick={()=>status(w,'PROCESSING')}>Processar</button>}{w.status==='PROCESSING'&&<button onClick={()=>status(w,'PAID')}><Check size={14}/>Confirmar pagamento</button>}{['PENDING','PROCESSING'].includes(w.status)&&<button className="secondary" onClick={()=>status(w,'REJECTED')}>Rejeitar</button>}</div>;
'@
$newActions = @'
 const actions=(w:Row)=>{
  const payout=w.asaasPayout||asaasFor(w.id);
  if(payout)return <div className="financeRowActions financeAsaasActions"><span className="financeAsaasMeta">{asaasLabel(payout)}{payout.updatedAt?' · Atualizado '+when(payout.updatedAt):''}{payout.transferId?' · ID '+payout.transferId:'' }{payout.lastError?' · '+payout.lastError:''}</span>{payout.transferId&&<button type="button" className="secondary" onClick={()=>void reconcileAsaas(payout.transferId)}>Sincronizar Asaas</button>}</div>;
  if(!asaasReady)return <div className="financeRowActions"><span className="financeAsaasMeta">Nao foi possivel consultar o Asaas. Acoes manuais bloqueadas por seguranca.</span></div>;
  return <div className="financeRowActions">{w.status==='PENDING'&&<button onClick={()=>status(w,'PROCESSING')}>Processar</button>}{w.status==='PROCESSING'&&<button onClick={()=>status(w,'PAID')}><Check size={14}/>Confirmar pagamento</button>}{['PENDING','PROCESSING'].includes(w.status)&&<button className="secondary" onClick={()=>status(w,'REJECTED')}>Rejeitar</button>}</div>;
 };
'@
$finance = Replace-Once $finance $oldActions $newActions 'financeAsaasActions' 'acoes administrativas de saque'

$oldList = '<div className="financeWithdrawalValue"><strong>{brl(w.amount)}</strong><Status value={w.status}/></div>{actions(w)}'
$newList = '<div className="financeWithdrawalValue"><strong>{brl(w.amount)}</strong><Status value={w.status}/>{asaasFor(w.id)&&<small className="financeAsaasMeta">{asaasLabel(asaasFor(w.id))}</small>}</div>{actions({...w,asaasPayout:asaasFor(w.id)})}'
$finance = Replace-Once $finance $oldList $newList 'asaasLabel(asaasFor(w.id))' 'status Asaas na lista de saques'

$oldDetailActions = '{actions({...w,kind:detail.user.role,user:detail.user})}'
$newDetailActions = '{actions({...w,kind:detail.user.role,user:detail.user,asaasPayout:w.asaasPayout||asaasFor(w.id)})}'
$finance = Replace-Once $finance $oldDetailActions $newDetailActions 'asaasPayout:w.asaasPayout||asaasFor(w.id)' 'status Asaas no detalhe da carteira'
$changes['apps/admin/src/app/finance-panel.tsx'] = $finance

# ADMIN: acabamento visual do status do provedor.
$financeCss = Read-RepoFile 'apps/admin/src/app/finance-workspace.css'
if (-not $financeCss.Contains('.financeAsaasActions{')) {
  $financeCss += @'

/* Asaas withdrawal status */
.financeAsaasActions{display:flex;flex-direction:column;align-items:flex-end;gap:7px;min-width:150px}
.financeAsaasMeta{display:block;max-width:260px;color:#687b75;font-size:10px;line-height:1.45;font-weight:750;text-align:right}
.financeAsaasActions button{white-space:nowrap}
.financeWithdrawalValue .financeAsaasMeta{margin-top:5px}
@media(max-width:700px){.financeAsaasActions{align-items:flex-start}.financeAsaasMeta{text-align:left;max-width:100%}}
'@
}
$changes['apps/admin/src/app/finance-workspace.css'] = $financeCss

# MOBILE: feedback neutro enquanto o Pix nao foi concluido.
$feedback = Read-RepoFile 'apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart'
$feedback = Replace-Once $feedback "const ['PENDING', 'PROCESSING', 'PAID'].contains(status)" "const ['PENDING', 'PROCESSING', 'PAID', 'REJECTED', 'CANCELED'].contains(status)" "REJECTED', 'CANCELED" 'reconhecimento dos estados finais'
$feedback = Replace-Once $feedback "if (_reduceMotion || !courierWithdrawalAcknowledged(widget.status)) {" "if (_reduceMotion || widget.status != 'PAID') {" "widget.status != 'PAID'" 'celebracao somente apos Pix concluido'
$oldBuild = @'
    final acknowledged = courierWithdrawalAcknowledged(widget.status);
    final title = switch (widget.status) {
      'PENDING' => 'Boa! Saque solicitado',
      'PROCESSING' => 'Seu saque está em processamento',
      'PAID' => 'Saque pago!',
      _ => 'Confira seu saque',
    };
    final label = switch (widget.status) {
      'PENDING' => 'Aguardando processamento',
      'PROCESSING' => 'Em processamento',
      'PAID' => 'Pagamento confirmado',
      _ => 'Consulte o status na carteira',
    };
'@
$newBuild = @'
    final paid = widget.status == 'PAID';
    final failed = widget.status == 'REJECTED' || widget.status == 'CANCELED';
    final accent = paid ? courierGreen : failed ? const Color(0xFFB34B3A) : const Color(0xFFB7791F);
    final title = switch (widget.status) {
      'PENDING' => 'Saque solicitado',
      'PROCESSING' => 'Seu saque está em processamento',
      'PAID' => 'Pix concluído!',
      'REJECTED' => 'Não foi possível concluir o saque',
      'CANCELED' => 'Saque cancelado',
      _ => 'Confira seu saque',
    };
    final label = switch (widget.status) {
      'PENDING' => 'Aguardando envio ao Asaas',
      'PROCESSING' => 'Aguardando confirmação do Pix',
      'PAID' => 'Pagamento confirmado pelo Asaas',
      'REJECTED' => 'Valor devolvido à carteira',
      'CANCELED' => 'Valor devolvido à carteira',
      _ => 'Consulte o status na carteira',
    };
    final message = paid
        ? 'O Asaas confirmou a transferência Pix.'
        : failed
            ? 'O valor reservado foi devolvido à sua carteira.'
            : 'O saque foi recebido. O pagamento só será confirmado quando o Asaas concluir o Pix.';
'@
$newBuild = $newBuild + "    final amount = widget.amount;"
$feedback = Replace-RegexOnce $feedback '    final acknowledged = courierWithdrawalAcknowledged\(widget\.status\);.*?    final amount = widget\.amount;' $newBuild 'final paid = widget.status' 'mensagens do modal de saque'
$feedback = Replace-Once $feedback "style: const TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w800," "style: TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w800," "style: TextStyle(fontSize: 34" "valor do modal com cor dinamica"
$feedback = Replace-Once $feedback "style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700," "style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700," "style: TextStyle(fontSize: 12" "etiqueta do modal com cor dinamica"
$feedback = Replace-Once $feedback 'decoration: const BoxDecoration(shape: BoxShape.circle,' 'decoration: BoxDecoration(shape: BoxShape.circle,' 'gradient: RadialGradient(colors: paid ?' 'container dinamico do modal'
$feedback = Replace-Once $feedback 'gradient: RadialGradient(colors: [Color(0xFFD2F3E9), Color(0xFFF1FAF7)]))' 'gradient: RadialGradient(colors: paid ? [const Color(0xFFD2F3E9), const Color(0xFFF1FAF7)] : failed ? [const Color(0xFFF8DCD7), const Color(0xFFFFF5F2)] : [const Color(0xFFFFE8BD), const Color(0xFFFFFAF0)]))' 'RadialGradient(colors: paid ?' 'cores do estado do saque'
$feedback = Replace-Once $feedback 'decoration: BoxDecoration(shape: BoxShape.circle, color: courierGreen,' 'decoration: BoxDecoration(shape: BoxShape.circle, color: accent,' 'color: accent,' 'icone sem falso sucesso'
$feedback = Replace-Once $feedback 'child: Icon(acknowledged ? Icons.check_rounded : Icons.receipt_long_rounded,' 'child: Icon(paid ? Icons.check_rounded : failed ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,' 'Icons.hourglass_top_rounded' 'icone por estado do Pix'
$feedback = Replace-Once $feedback 'letterSpacing: -1, color: courierGreen)),' 'letterSpacing: -1, color: accent)),' 'letterSpacing: -1, color: accent' 'valor com cor do estado'
$feedback = Replace-Once $feedback 'decoration: BoxDecoration(color: const Color(0xFFEEF7F4),' 'decoration: BoxDecoration(color: paid ? const Color(0xFFEEF7F4) : failed ? const Color(0xFFFFF0ED) : const Color(0xFFFFF6E7),' 'color: paid ? const Color(0xFFEEF7F4)' 'etiqueta por estado'
$feedback = Replace-Once $feedback 'color: courierGreen)))),' 'color: accent)))),' 'color: accent))))' 'texto da etiqueta por estado'
$feedback = Replace-RegexOnce $feedback "const PrimeText\('Acompanhe as atualiza[^']*', textAlign: TextAlign\.center," 'PrimeText(message, textAlign: TextAlign.center,' 'PrimeText(message, textAlign:' 'orientacao contextual do saque'
$feedback = Replace-RegexOnce $feedback "child: const PrimeText\('Voltar[^']*', textAlign: TextAlign\.center," "child: const PrimeText('Voltar à carteira', textAlign: TextAlign.center," "Voltar à carteira" 'texto correto do botao de retorno'
$changes['apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart'] = $feedback

# MOBILE: associar a reserva do extrato ao saque correspondente.
$courier = Read-RepoFile 'apps/mobile/lib/features/courier/presentation/pages/courier_page.dart'
$courier = Replace-Once $courier 'class _CourierPageState extends State<CourierPage> {' 'class _CourierPageState extends State<CourierPage> with WidgetsBindingObserver {' 'with WidgetsBindingObserver' 'observer de ciclo de vida'
$oldCourierInit = @'
  void initState() {
    super.initState();
    AppState.instance.addListener(_syncOfferSound);
'@
$newCourierInit = @'
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppState.instance.addListener(_syncOfferSound);
'@
$courier = Replace-Once $courier $oldCourierInit $newCourierInit 'WidgetsBinding.instance.addObserver(this)' 'atualizacao da carteira ao abrir o app'
$oldCourierDispose = @'
  @override
  void dispose() {
    AppState.instance.removeListener(_syncOfferSound);
'@
$newCourierDispose = @'
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && AppState.instance.isCourier) {
      unawaited(AppState.instance.loadWallet().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppState.instance.removeListener(_syncOfferSound);
'@
$courier = Replace-Once $courier $oldCourierDispose $newCourierDispose 'didChangeAppLifecycleState(AppLifecycleState state)' 'sincronizacao da carteira ao retornar ao app'

$newWalletLedger = @'
        ..._ledgerWidgets(ledger, withdrawals: state.withdrawals
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList()),
'@
$courier = Replace-Once $courier '        ..._ledgerWidgets(ledger),' $newWalletLedger 'withdrawals: state.withdrawals' 'ligacao do extrato ao saque'

$oldLedgerMethod = @'
  List<Widget> _ledgerWidgets(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const [
        _DriverEmpty(
          icon: AppIcons.receipt_long_rounded,
          title: 'Sem movimentações',
          subtitle:
              'Créditos, débitos, saques e estornos aparecerão no seu extrato.',
        ),
      ];
    }
    return rows.take(80).map((x) => _LedgerRow(entry: x)).toList();
  }
'@
$newLedgerMethod = @'
  List<Widget> _ledgerWidgets(List<Map<String, dynamic>> rows, {
    List<Map<String, dynamic>> withdrawals = const [],
  }) {
    if (rows.isEmpty) {
      return const [
        _DriverEmpty(
          icon: AppIcons.receipt_long_rounded,
          title: 'Sem movimentações',
          subtitle:
              'Créditos, débitos, saques e estornos aparecerão no seu extrato.',
        ),
      ];
    }
    final byId = <String, Map<String, dynamic>>{
      for (final withdrawal in withdrawals)
        if (withdrawal['id'] != null) withdrawal['id'].toString(): withdrawal,
    };
    return rows.take(80).map((entry) {
      final metadata = entry['metadata'];
      final id = metadata is Map ? metadata['withdrawalId']?.toString() : null;
      return _LedgerRow(entry: entry, withdrawal: id == null ? null : byId[id]);
    }).toList();
  }
'@
$courier = Replace-Once $courier $oldLedgerMethod $newLedgerMethod 'List<Map<String, dynamic>> withdrawals = const []' 'associacao da reserva no extrato'

$oldLedgerCtor = @'
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(entry['amount']?.toString() ?? '0') ?? 0;
    final positive = amount >= 0;
'@
$newLedgerCtor = @'
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, this.withdrawal});
  final Map<String, dynamic> entry;
  final Map<String, dynamic>? withdrawal;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(entry['amount']?.toString() ?? '0') ?? 0;
    final positive = amount >= 0;
    final rawPayout = withdrawal == null ? null : withdrawal!['asaasPayout'];
    final payout = rawPayout is Map ? Map<String, dynamic>.from(rawPayout) : null;
    final providerLabel = _asaasStatusLabel(payout);
    final title = withdrawal == null
        ? (entry['description'] ?? 'Movimentação').toString()
        : _withdrawalLedgerLabel((withdrawal!['status'] ?? '').toString());
    final subtitle = providerLabel.isEmpty
        ? _date(entry['createdAt'])
        : _date(entry['createdAt']) + ' · ' + providerLabel;
'@
$courier = Replace-Once $courier $oldLedgerCtor $newLedgerCtor 'final providerLabel = _asaasStatusLabel(payout)' 'dados do Asaas no extrato'
$courier = Replace-Once $courier "(entry['description'] ?? 'Movimentação').toString()," 'title,' 'PrimeText(title,' 'titulo dinamico da reserva'
$courier = Replace-Once $courier "_date(entry['createdAt'])," 'subtitle,' 'PrimeText(subtitle,' 'status do saque no extrato'

$oldWithdrawalRow = @'
class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.payments_rounded,
              color: AppColors.oceanDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrimeText(
                    _money(row['amount']),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: AppFontWeight.display,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PrimeText(
                    _date(row['requestedAt']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ],
              ),
            ),
          PrimeText(
            _withdrawalStatus((row['status'] ?? '').toString()),
            style: const TextStyle(
              color: AppColors.oceanDeep,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
            ),
          ),
        ],
      ),
    );
}
'@
$newWithdrawalRow = @'
class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final rawPayout = row['asaasPayout'];
    final payout = rawPayout is Map ? Map<String, dynamic>.from(rawPayout) : null;
    final providerLabel = _asaasStatusLabel(payout);
    final status = (row['status'] ?? '').toString();
    final statusColor = status == 'PAID'
        ? AppColors.oceanDeep
        : status == 'REJECTED' || status == 'CANCELED'
            ? AppColors.warning
            : AppColors.muted;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.payments_rounded,
            color: status == 'PAID' ? AppColors.oceanDeep : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimeText(
                  _money(row['amount']),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
                const SizedBox(height: 2),
                PrimeText(
                  _date(row['requestedAt']),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                  ),
                ),
                if (providerLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  PrimeText(
                    providerLabel,
                    style: TextStyle(
                      color: providerLabel.contains('Bloqueado')
                          ? AppColors.warning
                          : AppColors.muted,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PrimeText(
            _withdrawalStatus(status),
            style: TextStyle(
              color: statusColor,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
            ),
          ),
        ],
      ),
    );
  }
}
'@
$courier = Replace-Once $courier $oldWithdrawalRow $newWithdrawalRow 'providerLabel.isNotEmpty' 'cartao detalhado de saque'

$oldWithdrawalStatus = @'
String _withdrawalStatus(String value) => switch (value) {
      'PENDING' => 'PENDENTE',
      'PROCESSING' => 'PROCESSANDO',
      'PAID' => 'PAGO',
      'REJECTED' => 'REJEITADO',
      _ => value,
    };
'@
$newWithdrawalStatus = @'
String _withdrawalLedgerLabel(String value) => switch (value) {
      'PENDING' => 'Saque solicitado',
      'PROCESSING' => 'Saque em processamento',
      'PAID' => 'Pix concluído',
      'REJECTED' => 'Saque não concluído · valor devolvido',
      'CANCELED' => 'Saque cancelado · valor devolvido',
      _ => 'Movimentação de saque',
    };

String _asaasStatusLabel(Map<String, dynamic>? payout) {
  if (payout == null) return '';
  final provider = (payout['providerStatus'] ?? '').toString().toUpperCase();
  final state = (payout['state'] ?? '').toString().toUpperCase();
  final label = provider.isEmpty
      ? switch (state) {
          'QUEUED' => 'Asaas · aguardando envio',
          'SENDING' => 'Asaas · enviando solicitação',
          'UNKNOWN' => 'Asaas · envio sem confirmação',
          _ => 'Asaas · aguardando confirmação',
        }
      : switch (provider) {
          'PENDING' => 'Asaas · aguardando processamento',
          'BANK_PROCESSING' || 'IN_BANK_PROCESSING' => 'Asaas · processamento bancário',
          'BLOCKED' => 'Asaas · bloqueado, verifique a autorização',
          'DONE' => 'Asaas · Pix concluído',
          'FAILED' => 'Asaas · transferência recusada',
          'CANCELLED' => 'Asaas · transferência cancelada',
          _ => 'Asaas · ' + provider,
        };
  final lastError = (payout['lastError'] ?? '').toString();
  return lastError.isEmpty ? label : label + ' · ' + lastError;
}

String _withdrawalStatus(String value) => switch (value) {
      'PENDING' => 'SOLICITADO',
      'PROCESSING' => 'EM PROCESSAMENTO',
      'PAID' => 'PIX CONCLUÍDO',
      'REJECTED' => 'NÃO CONCLUÍDO',
      'CANCELED' => 'CANCELADO',
      _ => value,
    };
'@
$courier = Replace-Once $courier $oldWithdrawalStatus $newWithdrawalStatus 'String _asaasStatusLabel(' 'rotulos dos estados de saque'
$changes['apps/mobile/lib/features/courier/presentation/pages/courier_page.dart'] = $courier

# Validar tudo antes de gravar qualquer arquivo.
$backupRoot = Join-Path $env:TEMP ('porto-prime-asaas-withdrawal-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
foreach ($relative in $changes.Keys) {
  $target = Join-Path $RepoRoot $relative
  $backup = Join-Path $backupRoot $relative
  New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force | Out-Null
  Copy-Item -LiteralPath $target -Destination $backup -Force
}
$encoding = [System.Text.UTF8Encoding]::new($false)
foreach ($relative in $changes.Keys) {
  $target = Join-Path $RepoRoot $relative
  [System.IO.File]::WriteAllText($target, [string]$changes[$relative], $encoding)
}

Write-Host ''
Write-Host 'IMPLEMENTACAO APLICADA COM SUCESSO' -ForegroundColor Green
Write-Host ('Backup dos arquivos originais: ' + $backupRoot) -ForegroundColor Cyan
Write-Host ''
Write-Host 'Arquivos atualizados:' -ForegroundColor Cyan
foreach ($relative in $changes.Keys) { Write-Host (' - ' + $relative) }
Write-Host ''
Write-Host 'O envio Asaas passa a ser disparado imediatamente; o saque so vira PIX CONCLUIDO apos TRANSFER_DONE.' -ForegroundColor Green
Write-Host 'Saques Asaas nao exibem confirmacao/rejeicao manual no Admin; pendencias exigem acao no proprio Asaas.' -ForegroundColor Green
Write-Host 'Stripe, checkout, regras de saldo e demais fluxos permanecem intocados.' -ForegroundColor Green
