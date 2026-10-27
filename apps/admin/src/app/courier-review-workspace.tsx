'use client';

import { useState, type ReactNode } from 'react';
import {
 ArrowLeft, Check, FileText, Clock3, Phone, Mail, Bike, ShieldCheck,
 Expand, X, Plus, ClipboardList, AlertTriangle, MapPin, Headphones,
 MessageCircle, UserRound, BadgeCheck, CalendarDays, ChevronDown, Search, Send
} from 'lucide-react';
import RequirementList from './requirement-list';
import './courier-review-workspace.css';

type RecordData = Record<string, any>;

const date = (value: unknown) => {
 if (!value) return '—';
 const parsed = new Date(String(value));
 return Number.isNaN(parsed.getTime()) ? '—' : parsed.toLocaleString('pt-BR', {
  day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
 });
};
const initials = (name: unknown) => String(name || 'PP').trim().split(/\s+/).slice(0, 2).map(s => s[0]?.toUpperCase()).join('');
const validImage = (value: unknown) =>
 typeof value === 'string' && /^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/]+=*$/.test(value);

function Answer({ value }: { value: string }) {
 const [expanded, setExpanded] = useState(false);
 let answerText = value, photo = '';
 try {
  const parsed = JSON.parse(value);
  if (typeof parsed?.text === 'string') answerText = parsed.text;
  if (validImage(parsed?.documentPhoto)) photo = parsed.documentPhoto;
 } catch { /* Older responses can be plain text. */ }

 return <div className="crAnswer">
  <div className="crDocument">
   <div className="crAnswerHeading"><FileText size={17}/><h4>Documento enviado pelo candidato</h4></div>
   {photo
    ? <><div className="crDocumentPreview"><img src={photo} alt="Documento enviado pelo motoboy para análise"/></div><button type="button" className="crPreviewButton" onClick={() => setExpanded(true)}><Expand size={15}/> Visualizar em tela cheia</button></>
    : <div className="crNoDocument"><FileText size={30}/><strong>Sem documento anexado</strong><span>O candidato enviou apenas uma resposta em texto.</span></div>}
  </div>
  <div className="crResponse">
   <div className="crAnswerHeading"><MessageCircle size={17}/><h4>Resposta do candidato</h4></div>
   <p>{answerText || 'Nenhuma mensagem informada.'}</p>
   <span className="crResponseCaption"><Check size={13}/> Resposta registrada no sistema</span>
  </div>
  {expanded && photo && <div className="crPreview" role="dialog" aria-modal="true" aria-label="Visualização do documento" onMouseDown={() => setExpanded(false)} onKeyDown={e => { if (e.key === 'Escape') setExpanded(false); }}>
   <button type="button" autoFocus onClick={() => setExpanded(false)} aria-label="Fechar documento"><X size={21}/></button>
   <img src={photo} alt="Documento ampliado enviado pelo motoboy" onMouseDown={e => e.stopPropagation()}/>
  </div>}
 </div>;
}

export default function CourierReviewWorkspace({
 user, app, close, request, resolve, cancel, children, embedded = false, onSupport
}: {
 embedded?: boolean; user: RecordData; app: RecordData; close: () => void; request: () => void;
 resolve: (id: string) => Promise<unknown>; cancel: (item: RecordData) => ReactNode;
 children: ReactNode; onSupport?: () => void;
}) {
 const [busy, setBusy] = useState<string | null>(null);
 const [error, setError] = useState('');
 const requirements: RecordData[] = app.requirements || [];
 const open = requirements.filter(r => !r.canceledAt && r.status !== 'RESOLVED');
 const answered = open.filter(r => r.status === 'ANSWERED');
 const resolved = requirements.filter(r => !r.canceledAt && r.status === 'RESOLVED');
 const data = { ...(app.onboardingData || user.courierProfile?.onboardingData || {}), ...app };
 const approved = user.status === 'ACTIVE' && app.approvalStatus === 'APPROVED';
 const blocked = user.status === 'BLOCKED' || user.status === 'SUSPENDED';
 const status = approved ? 'Conta liberada' : user.status === 'BLOCKED' ? 'Bloqueada' : user.status === 'SUSPENDED' ? 'Suspensa' : 'Pendente';
 const photo = validImage(data.profilePhoto) ? data.profilePhoto as string : '';
 const address = [data.city, data.state].filter(Boolean).join(' - ');
 const hasActive = open.length > 0;
 const latest = [...requirements].sort((a, b) => {
  const ta = new Date(a.respondedAt || a.answeredAt || a.requestedAt || a.createdAt || 0).getTime() || 0;
  const tb = new Date(b.respondedAt || b.answeredAt || b.requestedAt || b.createdAt || 0).getTime() || 0;
  return tb - ta;
 });

 async function finish(id: string) {
  if (busy) return;
  setBusy(id); setError('');
  try { await resolve(id); }
  catch (e) { setError(e instanceof Error ? e.message : 'Não foi possível concluir. Tente novamente.'); }
  finally { setBusy(null); }
 }

 return <div className={embedded ? 'crEmbedded' : 'crBackdrop'}>
  <section className="crWorkspace" role={embedded ? 'region' : 'dialog'} aria-modal={embedded ? undefined : true} aria-labelledby="crTitle">
   <header className="crHeader">
    {!embedded && <button type="button" className="crBack" onClick={close}><ArrowLeft size={16}/> Voltar</button>}
    <div className="crHeaderTitle"><span className="crEyebrow">PORTO PRIME / REVISÃO CADASTRAL</span><h2 id="crTitle">Candidatura do Motoboy</h2><p>Analise e gerencie os documentos e informações do candidato.</p></div>
    <div className="crRegistered"><span>Cadastrado em</span><strong>{date(user.createdAt)}</strong></div>
    <span className={'crStatus crTopStatus ' + (approved ? 'approved' : blocked ? 'blocked' : '')}><span className="crStatusDot"/>{hasActive ? 'Pendências' : status}</span>
   </header>

   <div className="crColumns">
    <div className="crIdentity" aria-label="Perfil do motoboy">
     <div className="crPortrait">{photo ? <img src={photo} alt={'Foto do motoboy ' + user.name}/> : <span>{initials(user.name)}</span>}</div>
     <h3>{user.name || 'Motoboy'}</h3>
     <span className={'crIdentityStatus' + (approved ? ' isApproved' : '')}><span/> {status}</span>
     <ul className="crContactDetails">
      <li><Phone size={16}/><span>{user.phone || 'Telefone não informado'}</span></li>
      <li><Mail size={16}/><span title={user.email}>{user.email || 'E-mail não informado'}</span></li>
      <li><BadgeCheck size={16}/><span>CPF {data.document || data.cpf || 'não informado'}</span></li>
      {address && <li><MapPin size={16}/><span>{address}</span></li>}
     </ul>
     <div className="crProfileDivider"/>
     <div className="crFact"><span className="crFactIcon"><Bike size={20}/></span><div><small>Moto informada</small><strong>{[data.vehicleBrand, data.vehicleModel].filter(Boolean).join(' ') || 'Não informada'}</strong><small>Placa: {data.vehiclePlate || '—'}</small></div></div>
     <div className="crFact"><span className="crFactIcon"><FileText size={20}/></span><div><small>CNH</small><strong>{data.cnh || 'Não informada'}</strong></div></div>
     <div className="crFact"><span className="crFactIcon"><ShieldCheck size={20}/></span><div><small>Categoria informada</small><strong>{data.cnhCategory || '—'}</strong></div></div>
     <div className="crIdentityFoot"><ShieldCheck size={16}/><span>Dados exibidos conforme o cadastro do motoboy.</span></div>
    </div>

    <div className="crMain">
     <div className="crSteps" aria-label="Etapas de análise cadastral">
      {['Cadastro', 'Análise de documentos', 'Aprovação', 'Conta liberada'].map((label, i) => {
       const done = approved || i === 0;
       const current = !approved && i === 1;
       return <div key={label} className={done ? 'done' : current ? 'current' : ''}>
        <span className="crStepIcon">{done ? <Check size={16}/> : i === 1 ? <ClipboardList size={16}/> : i === 2 ? <ShieldCheck size={16}/> : <BadgeCheck size={16}/>}</span>
        <b>{label}</b><small>{done ? 'Concluído' : current ? 'Em andamento' : 'Pendente'}</small>
       </div>;
      })}
     </div>

     <div className={'crNotice' + (hasActive ? '' : ' isClear')}>
      <span className="crNoticeSymbol">{hasActive ? <AlertTriangle size={21}/> : <Check size={22}/>}</span>
      <div><strong>{open.length ? open.length + ' pendência' + (open.length > 1 ? 's' : '') + ' em andamento' : 'Nenhuma pendência em aberto'}</strong>
       <p>{answered.length ? 'O candidato já enviou uma resposta. Revise o documento e defina a situação.' : hasActive ? 'Aguardando o envio das informações solicitadas.' : 'Todas as pendências registradas foram concluídas ou canceladas.'}</p>
      </div>
      <button type="button" className="crRequestTop" onClick={request}><Plus size={15}/> Solicitar pendência</button>
     </div>
     {error && <p role="alert" className="crError"><AlertTriangle size={16}/>{error}</p>}

     <RequirementList items={requirements}>{r =>
      <article className="crRequirement">
       <div className="crRequirementHeader">
        <span className="crFileIcon"><FileText size={23}/></span>
        <div className="crRequirementTitle"><h3>{r.title}</h3><p>{r.description}</p></div>
        <div className="crRequirementMeta"><span className={'crStatus crReqStatus ' + (r.canceledAt ? 'canceled' : r.status === 'ANSWERED' ? 'answered' : r.status === 'RESOLVED' ? 'resolved' : 'awaiting')}>{r.canceledAt ? 'Cancelada' : r.status === 'RESOLVED' ? 'Resolvida' : r.status === 'ANSWERED' ? 'Respondida' : 'Aguardando resposta'}</span><small>{date(r.respondedAt || r.answeredAt || r.requestedAt || r.createdAt)}</small></div>
       </div>
       {r.response && <Answer value={String(r.response)}/>}
       {!r.response && !r.canceledAt && r.status !== 'RESOLVED' && <div className="crWaiting"><Clock3 size={16}/> Aguardando o motoboy enviar a documentação solicitada.</div>}
       <div className="crActions">
        {!r.canceledAt && r.status === 'ANSWERED' && <button type="button" className="crResolve" disabled={!!busy} onClick={() => { if (r.id) void finish(r.id); }}><span className="crActionIcon"><Check size={20}/></span><span><b>{busy === r.id ? 'Salvando…' : 'Marcar como resolvida'}</b><small>Documento e resposta conferidos</small></span></button>}
        {!r.canceledAt && r.status !== 'RESOLVED' && <button type="button" className="crAskAgain" onClick={request}><span className="crActionIcon"><Plus size={19}/></span><span><b>Solicitar novo documento</b><small>É necessário um ajuste</small></span></button>}
        <div className="crCancelSlot">{cancel(r)}</div>
       </div>
       <details className="crItemHistory"><summary><Clock3 size={17}/> Histórico desta pendência <ChevronDown size={16}/></summary><div className="crItemHistoryBody"><p>Solicitada em {date(r.requestedAt || r.createdAt)}</p>{r.response && <p>Resposta recebida{r.respondedAt || r.answeredAt ? ' em ' + date(r.respondedAt || r.answeredAt) : ''}</p>}{r.canceledAt && <p>Cancelada em {date(r.canceledAt)}</p>}{r.resolvedAt && <p>Resolvida em {date(r.resolvedAt)}</p>}</div></details>
      </article>
     }</RequirementList>
     {!requirements.length && <div className="crNoRequirements"><ShieldCheck size={27}/><strong>Nenhuma pendência registrada</strong><p>Você pode revisar os dados cadastrais ou solicitar um documento adicional.</p></div>}
     <details className="crManagement"><summary><ClipboardList size={17}/> Dados cadastrais, ganhos e gerenciamento de acesso <ChevronDown size={17}/></summary><div className="crManagementBody">{children}</div></details>
    </div>

    <div className="crAside" aria-label="Resumo e histórico">
     <section className="crAsideCard">
      <h3>Resumo da análise</h3>
      <dl className="crSummaryList">
       <div><dt><ClipboardList size={17}/> Total de pendências</dt><dd className="crCounter amber">{open.length}</dd></div>
       <div><dt><ShieldCheck size={17}/> Pendências resolvidas</dt><dd className="crCounter green">{resolved.length}</dd></div>
       <div><dt><FileText size={17}/> Aguardando análise</dt><dd className="crCounter blue">{answered.length}</dd></div>
      </dl>
      {open.length > 0 && <p className="crHint"><Clock3 size={19}/><span>A candidatura fica bloqueada para aprovação até a conclusão das pendências.</span></p>}
     </section>

     <section className="crAsideCard">
      <h3>Histórico geral</h3>
      <ol className="crTimeline">
       <li className="crTimelineStart"><strong>Cadastro realizado</strong><small>{date(user.createdAt)}</small></li>
       {latest.map(r => <li key={r.id} className={r.canceledAt ? 'isCancelled' : r.status === 'RESOLVED' ? 'isResolved' : r.status === 'ANSWERED' ? 'isAnswered' : ''}>
        <strong>{r.title}</strong><small>{r.canceledAt ? 'Solicitação cancelada' : r.status === 'RESOLVED' ? 'Pendência resolvida' : r.status === 'ANSWERED' ? 'Resposta recebida' : 'Solicitação enviada'}</small><small>{date(r.canceledAt || r.resolvedAt || r.respondedAt || r.answeredAt || r.requestedAt || r.createdAt)}</small>
       </li>)}
      </ol>
     </section>

     <section className="crAsideCard crContact">
      <span className="crSupportIcon"><Headphones size={22}/></span>
      <div><h3>Falar com o candidato</h3><p>Acesse a central de suporte para localizar uma conversa do motoboy e responder.</p></div>
      {onSupport ? <button type="button" className="crSupportButton" onClick={onSupport}><MessageCircle size={16}/> Abrir suporte <Send size={15}/></button>
       : <a className="crSupportButton" href={user.email ? 'mailto:' + encodeURIComponent(String(user.email)) : undefined} aria-disabled={!user.email}><Mail size={16}/> Contatar por e-mail</a>}
     </section>
    </div>
   </div>
  </section>
 </div>;
}
