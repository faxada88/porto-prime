param(
  [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path $RepoRoot).Path
if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
  throw "Abra o repositorio Porto Prime antes de executar este instalador: $RepoRoot"
}

function U([string]$Value) {
  return [regex]::Replace($Value, '\\u([0-9a-fA-F]{4})', {
    param($m)
    [string][char][Convert]::ToInt32($m.Groups[1].Value, 16)
  })
}
function Read-RepoFile([string]$RelativePath) {
  $path = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path $path)) { throw "Arquivo obrigatorio nao encontrado: $RelativePath" }
  return [System.IO.File]::ReadAllText($path)
}
function Replace-Once([string]$Content, [string]$Old, [string]$New, [string]$Marker, [string]$Label) {
  if ($Marker -and $Content.Contains($Marker)) { return $Content }
  $crlf = ([string][char]13) + [char]10
  $lf = [string][char]10
  $newline = if ($Content.Contains($crlf)) { $crlf } else { $lf }
  $contentLf = $Content.Replace($crlf, $lf)
  $oldLf = $Old.Replace($crlf, $lf)
  $newLf = $New.Replace($crlf, $lf)
  $count = [regex]::Matches($contentLf, [regex]::Escape($oldLf)).Count
  if ($count -ne 1) { throw "Checkpoint: esperava 1 ocorrencia de '$Label', encontrei $count. Nenhum arquivo foi gravado." }
  $updated = $contentLf.Replace($oldLf, $newLf)
  if ($newline -eq $crlf) { $updated = $updated.Replace($lf, $crlf) }
  return $updated
}
function Replace-RegexOnce([string]$Content, [string]$Pattern, [string]$New, [string]$Marker, [string]$Label) {
  if ($Marker -and $Content.Contains($Marker)) { return $Content }
  $crlf = ([string][char]13) + [char]10
  $lf = [string][char]10
  $newline = if ($Content.Contains($crlf)) { $crlf } else { $lf }
  $contentLf = $Content.Replace($crlf, $lf)
  $newLf = $New.Replace($crlf, $lf)
  $regexMatches = [regex]::Matches($contentLf, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($regexMatches.Count -ne 1) { throw "Checkpoint: esperava 1 ocorrencia de '$Label', encontrei $($regexMatches.Count). Nenhum arquivo foi gravado." }
  $match = $regexMatches[0]
  $updated = $contentLf.Substring(0, $match.Index) + $newLf + $contentLf.Substring($match.Index + $match.Length)
  if ($newline -eq $crlf) { $updated = $updated.Replace($lf, $crlf) }
  return $updated
}

$paths = @(
  'apps/api/prisma/schema.prisma',
  'apps/api/src/wallet/asaas-payout.service.ts',
  'apps/api/src/wallet/asaas-payout.controller.ts',
  'apps/api/src/wallet/wallet.service.ts',
  'apps/api/src/wallet/finance.service.ts',
  'apps/api/src/wallet/wallet.module.ts',
  'apps/admin/src/app/finance-panel.tsx',
  'apps/admin/src/app/finance-workspace.css',
  'apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart',
  'apps/mobile/lib/features/courier/presentation/pages/courier_page.dart'
)
$files = @{}
foreach ($path in $paths) { $files[$path] = Read-RepoFile $path }
$originalFiles = @{}
foreach ($path in $paths) { $originalFiles[$path] = $files[$path] }

$alreadyApplied =
  $files['apps/api/src/wallet/asaas-payout.service.ts'].Contains('async approve(id: string') -and
  $files['apps/api/src/wallet/asaas-payout.controller.ts'].Contains("@Post('withdrawals/:id/approve')") -and
  $files['apps/api/src/wallet/wallet.service.ts'].Contains('providerStatus: null') -and
  $files['apps/api/src/wallet/finance.service.ts'].Contains('asaasPayout:true') -and
  $files['apps/admin/src/app/finance-panel.tsx'].Contains('Aprovar saque Pix') -and
  $files['apps/mobile/lib/features/courier/presentation/pages/courier_page.dart'].Contains('PIX APROVADO')
if ($alreadyApplied) {
  Write-Host 'O fluxo de aprovacao Asaas ja esta aplicado. Nenhum arquivo foi alterado.' -ForegroundColor Green
  return
}


if (-not $files['apps/api/prisma/schema.prisma'].Contains('model AsaasPayout')) {
  throw 'O schema local ainda nao possui model AsaasPayout. Atualizacao cancelada sem gravar arquivos.'
}
if (-not $files['apps/api/src/wallet/wallet.module.ts'].Contains('AsaasPayoutService') -or
    -not $files['apps/api/src/wallet/wallet.module.ts'].Contains('AsaasPayoutController')) {
  throw 'WalletModule ainda nao registra a integracao Asaas. Atualizacao cancelada sem gravar arquivos.'
}
if (-not (Test-Path (Join-Path $RepoRoot 'apps/api/src/generated/prisma/models/AsaasPayout.ts'))) {
  throw 'Cliente Prisma gerado sem AsaasPayout. Atualizacao cancelada sem gravar arquivos.'
}

# API Asaas: ambiente sandbox/producao e envio somente apos aprovacao.
$asaas = $files['apps/api/src/wallet/asaas-payout.service.ts']
$asaas = Replace-Once $asaas "import { BadRequestException, ConflictException, Injectable, OnModuleDestroy, OnModuleInit, UnauthorizedException } from '@nestjs/common';" "import { BadRequestException, ConflictException, Injectable, NotFoundException, OnModuleDestroy, OnModuleInit, UnauthorizedException } from '@nestjs/common';" 'NotFoundException' 'import de NotFoundException'
$oldConfig = @'
  assertConfigured() {
    if (process.env.ASAAS_ENVIRONMENT !== 'sandbox' || !process.env.ASAAS_API_KEY?.trim()) {
      throw new BadRequestException('Saques Asaas exigem chave e ambiente sandbox configurados.');
    }
  }
'@
$newConfig = U @'
  private environment() {
    const value = (process.env.ASAAS_ENVIRONMENT ?? 'sandbox').trim().toLowerCase();
    return value === 'prod' ? 'production' : value;
  }
  private baseUrl() {
    return this.environment() === 'sandbox'
      ? 'https://api-sandbox.asaas.com/v3'
      : 'https://api.asaas.com/v3';
  }
  assertConfigured() {
    if (!['sandbox', 'production'].includes(this.environment()) || !process.env.ASAAS_API_KEY?.trim()) {
      throw new BadRequestException('Saques Asaas exigem ASAAS_ENVIRONMENT sandbox/production e ASAAS_API_KEY configurada.');
    }
  }
'@
$asaas = Replace-Once $asaas $oldConfig $newConfig 'private baseUrl()' 'configuracao de ambiente Asaas'
$asaas = Replace-Once $asaas "fetch('https://api-sandbox.asaas.com/v3' + path, {" "fetch(this.baseUrl() + path, {" 'this.baseUrl() + path' 'URL dinamica sandbox/producao'
$asaas = Replace-Once $asaas 'PortoPrime-SandboxPayouts/1.0' 'PortoPrime-Payouts/1.0' 'PortoPrime-Payouts/1.0' 'User-Agent Asaas'
$asaas = Replace-Once $asaas "where: { state: 'QUEUED' }" "where: { state: 'QUEUED', providerStatus: 'ADMIN_APPROVED' }" "state: 'QUEUED', providerStatus: 'ADMIN_APPROVED'" 'fila somente com aprovacao administrativa'
$asaas = Replace-Once $asaas "where: { withdrawalId: id, state: 'QUEUED' }" "where: { withdrawalId: id, state: 'QUEUED', providerStatus: 'ADMIN_APPROVED' }" "withdrawalId: id, state: 'QUEUED', providerStatus: 'ADMIN_APPROVED'" 'bloqueio de envio sem aprovacao'
$asaas = Replace-Once $asaas "p.environment !== 'sandbox'" "p.environment !== this.environment()" "p.environment !== this.environment()" 'validacao do ambiente da transferencia'
$asaas = Replace-Once $asaas "environment: 'sandbox'" "environment: this.environment()" "environment: this.environment()" 'diagnostico com ambiente real'
$asaas = Replace-Once $asaas 'Solicitacao recusada pelo Asaas. Confira saldo, chave Pix e autorizacoes no sandbox.' 'Solicitacao recusada pelo Asaas. Confira saldo, chave Pix e autorizacoes da conta.' 'autorizacoes da conta.' 'mensagem de recusa independente do ambiente'
$asaas = Replace-Once $asaas 'Solicitacao recusada pelo Asaas. Confira saldo, chave e autorizacoes no sandbox.' 'Solicitacao recusada pelo Asaas. Confira saldo, chave e autorizacoes da conta.' 'chave e autorizacoes da conta.' 'erro de recusa independente do ambiente'

$approvalMethod = U @'
  async approve(id: string, authorization?: string) {
    const actor = await this.auth.authenticate(authorization);
    if (actor.role !== 'ADMIN') throw new UnauthorizedException();
    if (!this.enabled()) throw new BadRequestException('Saques via Asaas estao desativados.');
    this.assertConfigured();
    const environment = this.environment();
    const result = await this.db.$transaction(async (tx: any) => {
      await tx.$queryRawUnsafe('SELECT "id" FROM "Withdrawal" WHERE "id" = $1 FOR UPDATE', id);
      const withdrawal = await tx.withdrawal.findUnique({ where: { id } });
      if (!withdrawal) throw new NotFoundException('Saque nao encontrado.');
      if (!['PENDING', 'PROCESSING'].includes(withdrawal.status)) {
        throw new ConflictException('Este saque nao esta aguardando aprovacao.');
      }
      const existing = await tx.asaasPayout.findUnique({ where: { withdrawalId: id } });
      if (existing && ['DONE', 'FAILED', 'CANCELLED'].includes(existing.state)) {
        throw new ConflictException('Este saque ja foi encerrado no Asaas.');
      }
      if (existing && ['SENDING', 'SENT', 'UNKNOWN'].includes(existing.state)) {
        return { send: false };
      }
      if (existing?.transferId) return { send: false };
      const courier = await tx.courierProfile.findUnique({
        where: { id: withdrawal.courierId },
        select: { userId: true },
      });
      if (!courier) throw new NotFoundException('Motoboy nao encontrado.');

      if (existing?.providerStatus === 'ADMIN_APPROVED' && existing.state === 'QUEUED') {
        return { send: true };
      }
      if (existing) {
        await tx.asaasPayout.update({
          where: { withdrawalId: id },
          data: { environment, state: 'QUEUED', providerStatus: 'ADMIN_APPROVED', lastError: null },
        });
      } else {
        await tx.asaasPayout.create({
          data: {
            withdrawalId: id,
            requestKey: 'admin-approval:' + id,
            environment,
            state: 'QUEUED',
            providerStatus: 'ADMIN_APPROVED',
          },
        });
      }
      await tx.withdrawal.update({
        where: { id },
        data: { status: 'PROCESSING', processedAt: null },
      });
      await tx.financialAudit.create({
        data: {
          actorId: actor.id,
          actorName: actor.name ?? actor.id,
          accountUserId: courier.userId,
          action: 'ASAAS_PAYOUT_APPROVED',
          amount: withdrawal.amount,
          reason: 'Aprovacao administrativa de saque Pix via Asaas',
          withdrawalId: id,
        },
      });
      return { send: true };
    });
    if (result.send) await this.send(id);
    return this.db.asaasPayout.findUnique({ where: { withdrawalId: id } });
  }

'@
$asaas = Replace-Once $asaas '  async adminReconcile(transferId: string, authorization?: string) {' ($approvalMethod + '  async adminReconcile(transferId: string, authorization?: string) {') 'async approve(id: string' 'endpoint interno de aprovacao Asaas'
$files['apps/api/src/wallet/asaas-payout.service.ts'] = $asaas

# Endpoint autenticado para o botao Aprovar saque.
$controller = $files['apps/api/src/wallet/asaas-payout.controller.ts']
$controller = Replace-Once $controller "import { Body, Controller, Get, Headers, HttpCode, Post } from '@nestjs/common';" "import { Body, Controller, Get, Headers, HttpCode, Param, Post } from '@nestjs/common';" 'Param, Post' 'import de Param'
$controllerMethod = @'
  @Post('withdrawals/:id/approve')
  approve(@Param('id') id: string, @Headers('authorization') authorization?: string) {
    return this.payouts.approve(id, authorization);
  }
'@
$controller = Replace-Once $controller "  @Get('status')" ($controllerMethod + "  @Get('status')") "@Post('withdrawals/:id/approve')" 'rota de aprovacao Asaas'
$files['apps/api/src/wallet/asaas-payout.controller.ts'] = $controller

# Solicitacao do motoboy reserva o saldo e aguarda aprovacao.
$wallet = $files['apps/api/src/wallet/wallet.service.ts']
$wallet = Replace-Once $wallet "status: automatic ? 'PROCESSING' : 'PENDING'," "status: 'PENDING'," "state: 'AWAITING_ADMIN'" 'saque inicia aguardando aprovacao'
$oldCreatePayout = @'
      if (automatic) await (tx as any).asaasPayout.create({ data: { withdrawalId, requestKey: courier.id + ':' + requestId } });
'@
$newCreatePayout = @'
      if (automatic) await (tx as any).asaasPayout.create({ data: {
        withdrawalId,
        requestKey: courier.id + ':' + requestId,
        environment: process.env.ASAAS_ENVIRONMENT === 'production' ? 'production' : 'sandbox',
        state: 'QUEUED',
        providerStatus: null,
      } });
'@
$wallet = Replace-Once $wallet $oldCreatePayout $newCreatePayout 'providerStatus: null' 'saque aguarda aprovacao antes de entrar na fila Asaas'
$files['apps/api/src/wallet/wallet.service.ts'] = $wallet

# A central financeira recebe o estado Asaas e impede baixa manual de saque de motoboy.
$finance = $files['apps/api/src/wallet/finance.service.ts']
$oldOverview = "this.db.withdrawal.findMany({include:{courier:{select:{user:{select:selectUser}}}},orderBy:{requestedAt:'desc'},take:200}),"
$newOverview = "this.db.withdrawal.findMany({include:{courier:{select:{user:{select:selectUser}}},asaasPayout:true},orderBy:{requestedAt:'desc'},take:200}),"
$finance = Replace-Once $finance $oldOverview $newOverview 'asaasPayout:true' 'consulta do Asaas na central financeira'
$statusPattern = "const current=await withdrawals\.findUnique\(\{where:\{id\}\}\);if\(!current\)throw new NotFoundException\('[^']*'\);"
$statusInsert = U @'
const current=await withdrawals.findUnique({where:{id}});if(!current)throw new NotFoundException('Saque nao encontrado');
      if (!partner && ['PAID', 'PROCESSING'].includes(body.status)) {
        throw new ConflictException('Saques de motoboy devem ser aprovados e confirmados exclusivamente pelo Asaas.');
      }
      const asaasPayout = partner ? null : await tx.asaasPayout.findUnique({ where: { withdrawalId: id } });
      if (asaasPayout) {
        const alreadySent = asaasPayout.providerStatus === 'ADMIN_APPROVED' ||
          ['SENDING', 'SENT', 'UNKNOWN', 'DONE', 'FAILED'].includes(asaasPayout.state);
        if (body.status !== 'REJECTED' || alreadySent) {
          throw new ConflictException('Saque integrado ao Asaas: aguarde a confirmacao do provedor.');
        }
        await tx.asaasPayout.update({
          where: { withdrawalId: id },
          data: {
            state: 'CANCELLED',
            providerStatus: 'ADMIN_REJECTED',
            lastError: 'Saque rejeitado pelo administrador antes do envio ao Asaas.',
          },
        });
      }
'@
$finance = Replace-RegexOnce $finance $statusPattern $statusInsert 'Saques de motoboy devem ser aprovados' 'bloqueio de baixa manual no FinanceService'
$files['apps/api/src/wallet/finance.service.ts'] = $finance

# Painel: um clique aprova o saque; o estado final vem do Asaas.
$panel = $files['apps/admin/src/app/finance-panel.tsx']
$panel = Replace-Once $panel "const [operation,setOperation]=useState<'credit'|'withdraw'|'status'|null>(null),[form,setForm]=useState<Row>({}),[saving,setSaving]=useState(false),[formError,setFormError]=useState(''),[revision,setRevision]=useState(0);" ("const [operation,setOperation]=useState<'credit'|'withdraw'|'status'|null>(null),[form,setForm]=useState<Row>({}),[saving,setSaving]=useState(false),[formError,setFormError]=useState(''),[revision,setRevision]=useState(0);" + [Environment]::NewLine + " const [asaasBusyId,setAsaasBusyId]=useState('');") 'asaasBusyId' 'estado de envio da aprovacao Asaas'
$panelHelpers = U @'
 const asaasLabel=(w:Row)=>{
  const p=w.asaasPayout;
  if(!p)return 'Aguardando aprovacao do administrador';
  const state=String(p.state||'').toUpperCase();
  const provider=String(p.providerStatus||'').toUpperCase();
  if(state==='QUEUED'&&provider!=='ADMIN_APPROVED')return 'Aguardando aprovacao do administrador';
  if(state==='QUEUED')return 'Aprovado \u00b7 aguardando envio ao Asaas';
  if(state==='SENDING')return 'Enviando Pix ao Asaas';
  if(state==='SENT')return 'Pix enviado \u00b7 aguardando confirmacao';
  if(state==='UNKNOWN')return 'Envio sem confirmacao \u00b7 conciliacao necessaria';
  if(state==='DONE')return 'Pix aprovado e concluido';
  if(state==='FAILED')return 'Pix nao concluido pelo Asaas';
  if(state==='CANCELLED')return 'Saque cancelado';
  return provider||state||'Aguardando atualizacao do Asaas';
 };
 const approveAsaas=async(w:Row)=>{
  if(asaasBusyId)return;
  setAsaasBusyId(w.id);setError('');setNotice('');
  try{
   const result=await api('/wallet/asaas/withdrawals/'+encodeURIComponent(w.id)+'/approve',token,'POST',{});
   setRevision(n=>n+1);
   const state=String(result?.state||'').toUpperCase();
   setNotice(state==='FAILED'?'O Asaas recusou a transferencia. O valor reservado foi devolvido a carteira.':state==='DONE'?'Pix concluido e confirmado pelo Asaas.':'Aprovacao registrada. O Porto Prime esta aguardando a confirmacao do Asaas.');
  }catch(e:any){setError(displayMessage(e.message))}
  finally{setAsaasBusyId('')}
 };
 const reconcileAsaas=async(w:Row)=>{
  if(!w.asaasPayout?.transferId||asaasBusyId)return;
  setAsaasBusyId(w.id);setError('');
  try{await api('/wallet/asaas/reconcile',token,'POST',{transferId:w.asaasPayout.transferId});setRevision(n=>n+1);setNotice('Status consultado diretamente no Asaas.')}
  catch(e:any){setError(displayMessage(e.message))}
  finally{setAsaasBusyId('')}
 };
'@
$panel = Replace-Once $panel " const status=(w:Row,next:string)=>{setForm({...w,nextStatus:next,reason:'',reference:'',receiptUrl:''});setFormError('');setOperation('status')};" (" const status=(w:Row,next:string)=>{setForm({...w,nextStatus:next,reason:'',reference:'',receiptUrl:''});setFormError('');setOperation('status')};" + [Environment]::NewLine + $panelHelpers) 'const asaasLabel=' 'acoes auxiliares de aprovacao e conciliacao'
$oldActions = @'
 const actions=(w:Row)=><div className="financeRowActions">{w.status==='PENDING'&&<button onClick={()=>status(w,'PROCESSING')}>Processar</button>}{w.status==='PROCESSING'&&<button onClick={()=>status(w,'PAID')}><Check size={14}/>Confirmar pagamento</button>}{['PENDING','PROCESSING'].includes(w.status)&&<button className="secondary" onClick={()=>status(w,'REJECTED')}>Rejeitar</button>}</div>;
'@
$oldActions = $oldActions.TrimEnd([char]13, [char]10)
$newActions = U @'
 const actions=(w:Row)=>{
  if(w.kind==='COURIER'){
   const p=w.asaasPayout,state=String(p?.state||'').toUpperCase(),provider=String(p?.providerStatus||'').toUpperCase();
   const awaiting=['PENDING','PROCESSING'].includes(w.status)&&(!p||(state==='QUEUED'&&provider!=='ADMIN_APPROVED'));
   if(awaiting)return <div className="financeRowActions financeAsaasActions"><span className="financeAsaasMeta">Aguardando aprovacao do administrador</span><button type="button" disabled={asaasBusyId===w.id} onClick={()=>void approveAsaas(w)}>{asaasBusyId===w.id?'Enviando...':'Aprovar saque Pix'}</button>{w.status==='PENDING'&&<button type="button" className="secondary" onClick={()=>status(w,'REJECTED')}>Rejeitar</button>}</div>;
   return <div className="financeRowActions financeAsaasActions"><span className="financeAsaasMeta">{asaasLabel(w)}{p?.transferId?' \u00b7 ID '+p.transferId:''}{p?.lastError?' \u00b7 '+p.lastError:''}</span>{p?.transferId&&['SENT','UNKNOWN'].includes(state)&&<button type="button" className="secondary" disabled={asaasBusyId===w.id} onClick={()=>void reconcileAsaas(w)}>Sincronizar Asaas</button>}</div>;
  }
  return <div className="financeRowActions">{w.status==='PENDING'&&<button onClick={()=>status(w,'PROCESSING')}>Processar</button>}{w.status==='PROCESSING'&&<button onClick={()=>status(w,'PAID')}><Check size={14}/>Confirmar pagamento</button>}{['PENDING','PROCESSING'].includes(w.status)&&<button className="secondary" onClick={()=>status(w,'REJECTED')}>Rejeitar</button>}</div>;
 };
'@
$panel = Replace-Once $panel $oldActions $newActions 'const actions=(w:Row)=>{' 'botao Aprovar saque Pix no painel'
$files['apps/admin/src/app/finance-panel.tsx'] = $panel

$css = $files['apps/admin/src/app/finance-workspace.css']
if (-not $css.Contains('.financeAsaasActions{')) {
  $css += @'

/* Asaas Pix approval */
.financeAsaasActions{display:flex;flex-direction:column;align-items:flex-end;gap:7px;min-width:150px}
.financeAsaasMeta{display:block;max-width:270px;color:#687b75;font-size:10px;line-height:1.45;font-weight:750;text-align:right;overflow-wrap:anywhere}
.financeAsaasActions button{white-space:nowrap}
@media(max-width:760px){.financeAsaasActions{align-items:flex-start}.financeAsaasMeta{text-align:left;max-width:100%}}
'@
}
$files['apps/admin/src/app/finance-workspace.css'] = $css

# Motoboy: somente status PAID gera confirmacao visual de Pix concluido.
$feedback = $files['apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart']
$feedback = Replace-Once $feedback "const ['PENDING', 'PROCESSING', 'PAID'].contains(status)" "const ['PENDING', 'PROCESSING', 'PAID', 'REJECTED', 'CANCELED'].contains(status)" "REJECTED', 'CANCELED" 'modal reconhece saque rejeitado/cancelado'
$feedback = Replace-Once $feedback "if (_reduceMotion || !courierWithdrawalAcknowledged(widget.status)) {" "if (_reduceMotion || widget.status != 'PAID') {" "widget.status != 'PAID'" 'animacao de sucesso somente apos Pix concluido'
$oldFeedbackBuild = U @'
    final acknowledged = courierWithdrawalAcknowledged(widget.status);
    final title = switch (widget.status) {
      'PENDING' => 'Boa! Saque solicitado',
      'PROCESSING' => 'Seu saque est\u00e1 em processamento',
      'PAID' => 'Saque pago!',
      _ => 'Confira seu saque',
    };
    final label = switch (widget.status) {
      'PENDING' => 'Aguardando processamento',
      'PROCESSING' => 'Em processamento',
      'PAID' => 'Pagamento confirmado',
      _ => 'Consulte o status na carteira',
    };
    final amount = widget.amount;
'@
$newFeedbackBuild = U @'
    final paid = widget.status == 'PAID';
    final failed = widget.status == 'REJECTED' || widget.status == 'CANCELED';
    final accent = paid ? courierGreen : failed ? const Color(0xFFB34B3A) : const Color(0xFFB7791F);
    final title = switch (widget.status) {
      'PENDING' => 'Saque solicitado',
      'PROCESSING' => 'Pix em processamento',
      'PAID' => 'Pix aprovado e concluido!',
      'REJECTED' => 'Saque nao aprovado',
      'CANCELED' => 'Saque cancelado',
      _ => 'Confira seu saque',
    };
    final label = switch (widget.status) {
      'PENDING' => 'Aguardando aprovacao do administrador',
      'PROCESSING' => 'Aguardando confirmacao do Asaas',
      'PAID' => 'Transferencia confirmada pelo Asaas',
      'REJECTED' => 'Valor devolvido a carteira',
      'CANCELED' => 'Valor devolvido a carteira',
      _ => 'Consulte o status na carteira',
    };
    final message = paid
        ? 'O Asaas confirmou a transferencia Pix.'
        : failed
            ? 'O valor reservado foi devolvido a sua carteira.'
            : 'O saque foi recebido. O Pix so sera confirmado quando o Asaas concluir a transferencia.';
    final amount = widget.amount;
'@
$feedback = Replace-Once $feedback $oldFeedbackBuild $newFeedbackBuild 'final paid = widget.status' 'mensagens de status do saque no aplicativo'
$feedback = Replace-Once $feedback 'Icon(acknowledged ? Icons.check_rounded : Icons.receipt_long_rounded,' 'Icon(paid ? Icons.check_rounded : failed ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,' 'Icons.hourglass_top_rounded' 'icone nao antecipa confirmacao Pix'
$feedback = Replace-Once $feedback 'const TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w800,' 'TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w800,' '' 'valor dinamico no modal Pix'
$feedback = Replace-Once $feedback 'letterSpacing: -1, color: courierGreen)),' 'letterSpacing: -1, color: accent)),' 'letterSpacing: -1, color: accent' 'cor do valor conforme estado'
$feedback = Replace-Once $feedback 'color: const Color(0xFFEEF7F4),' 'color: paid ? const Color(0xFFEEF7F4) : failed ? const Color(0xFFFFF0ED) : const Color(0xFFFFF6E7),' 'color: paid ? const Color(0xFFEEF7F4)' 'fundo da etiqueta conforme estado'
$feedback = Replace-Once $feedback 'const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700,' 'TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w700,' '' 'texto dinamico da etiqueta Pix'
$feedback = Replace-Once $feedback 'color: courierGreen)))),' 'color: accent)))),' 'color: accent))))' 'cor da etiqueta conforme estado'
$feedback = Replace-RegexOnce $feedback "const PrimeText\('Acompanhe as atualiza[^']*', textAlign: TextAlign\.center," 'PrimeText(message, textAlign: TextAlign.center,' 'PrimeText(message, textAlign:' 'mensagem explicativa conforme status'
$files['apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart'] = $feedback

$courierPage = $files['apps/mobile/lib/features/courier/presentation/pages/courier_page.dart']
$oldStatusLabel = @'
String _withdrawalStatus(String value) => switch (value) {
      'PENDING' => 'PENDENTE',
      'PROCESSING' => 'EM PROCESSAMENTO',
      'PAID' => 'PAGO',
      'REJECTED' => 'REJEITADO',
      _ => value,
    };
'@
$newStatusLabel = U @'
String _withdrawalStatus(String value) => switch (value) {
      'PENDING' => 'AGUARDANDO APROVACAO',
      'PROCESSING' => 'PIX EM PROCESSAMENTO',
      'PAID' => 'PIX APROVADO',
      'REJECTED' => 'SAQUE REJEITADO',
      'CANCELED' => 'SAQUE CANCELADO',
      _ => value,
    };
'@
$courierPage = Replace-Once $courierPage $oldStatusLabel $newStatusLabel 'PIX APROVADO' 'rotulo Pix aprovado na carteira do motoboy'
$files['apps/mobile/lib/features/courier/presentation/pages/courier_page.dart'] = $courierPage

# Checkpoints finais: nenhum arquivo e gravado se algum trecho nao corresponder.
$requiredMarkers = @(
  @('apps/api/src/wallet/asaas-payout.service.ts', 'async approve(id: string'),
  @('apps/api/src/wallet/asaas-payout.service.ts', "providerStatus: 'ADMIN_APPROVED'"),
  @('apps/api/src/wallet/asaas-payout.controller.ts', "@Post('withdrawals/:id/approve')"),
  @('apps/api/src/wallet/wallet.service.ts', 'providerStatus: null'),
  @('apps/api/src/wallet/finance.service.ts', 'asaasPayout:true'),
  @('apps/admin/src/app/finance-panel.tsx', 'Aprovar saque Pix'),
  @('apps/mobile/lib/features/courier/presentation/widgets/courier_withdrawal_feedback.dart', 'final paid = widget.status'),
  @('apps/mobile/lib/features/courier/presentation/pages/courier_page.dart', 'PIX APROVADO')
)
foreach ($item in $requiredMarkers) {
  if (-not $files[$item[0]].Contains($item[1])) {
    throw "Checkpoint final falhou em $($item[0]). Nenhum arquivo foi gravado."
  }
}

$changedPaths = @($paths | Where-Object { $files[$_] -cne $originalFiles[$_] })
if ($changedPaths.Count -eq 0) {
  Write-Host 'Nenhuma alteracao necessaria. Nenhum arquivo foi gravado.' -ForegroundColor Green
  return
}
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $RepoRoot ('.backups/asaas-manual-approval-' + $stamp)
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
foreach ($path in $changedPaths) {
  $source = Join-Path $RepoRoot $path
  $backup = Join-Path $backupDir $path
  New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force | Out-Null
  Copy-Item $source $backup -Force
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
foreach ($path in $changedPaths) {
  [System.IO.File]::WriteAllText((Join-Path $RepoRoot $path), $files[$path], $utf8)
}

Write-Host ''
Write-Host 'Atualizacao aplicada: saque de motoboy exige aprovacao do administrador e confirmacao do Asaas.' -ForegroundColor Green
Write-Host 'Stripe e arquivos .env nao foram alterados.' -ForegroundColor Green
Write-Host ('Backup criado em: ' + $backupDir) -ForegroundColor Cyan
Write-Host 'Nenhuma transferencia Pix foi enviada durante a atualizacao.' -ForegroundColor Yellow
