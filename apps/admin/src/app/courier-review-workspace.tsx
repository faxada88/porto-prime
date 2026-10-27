'use client';

import { useState, type FormEvent, type ReactNode } from 'react';
import {
 ArrowLeft, Check, FileText, Clock3, Phone, Mail, Bike, ShieldCheck,
 Expand, X, Plus, ClipboardList, AlertTriangle, MapPin, Headphones,
 MessageCircle, BadgeCheck, ChevronDown, Send, RefreshCw,
 History, ImageIcon
} from 'lucide-react';
import RequirementList from './requirement-list';
import './courier-review-workspace.css';

type RecordData = Record<string, any>;
const date = (value: unknown) => {
 if (!value) return '—';
 const d = new Date(String(value));
 return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString('pt-BR', {
  day:'2-digit', month:'2-digit', year:'numeric', hour:'2-digit', minute:'2-digit'
 });
};
const initials = (name: unknown) => String(name || 'PP').trim().split(/\s+/).slice(0, 2).map(s => s[0]?.toUpperCase()).join('');
const validImage = (value: unknown) =>
 typeof value === 'string' && /^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/]+=*$/.test(value);
const revisionReasons = [
 {value:'illegible',label:'Foto ou documento ilegível',title:'Documento enviado está ilegível',detail:'A foto enviada não permite conferir as informações. Envie uma nova imagem nítida, com boa iluminação, todos os dados visíveis e sem reflexos.'},
 {value:'mismatch',label:'Foto não corresponde ao titular',title:'Foto de identificação não corresponde ao titular',detail:'A foto enviada não corresponde ao titular do cadastro. Envie uma foto atual do seu próprio documento, com o rosto e os dados claramente visíveis.'},
 {value:'expired',label:'Documento vencido ou inválido',title:'Documento vencido ou inválido',detail:'O documento informado não atende aos requisitos de validade. Envie uma versão atualizada e válida, com todos os dados legíveis.'},
 {value:'category',label:'Categoria da CNH incompatível',title:'Categoria da CNH incompatível',detail:'A categoria da CNH enviada não corresponde ao veículo informado. Confira a habilitação e envie um documento válido e compatível com a moto usada nas entregas.'},
 {value:'incomplete',label:'Dados ou páginas faltando',title:'Documentação incompleta',detail:'Não recebemos todas as informações necessárias para conferir o cadastro. Reenvie o documento completo, incluindo frente e verso quando aplicável.'},
 {value:'custom',label:'Outro motivo',title:'',detail:''}
];

function Answer({value}:{value:string}) {
 const [expanded,setExpanded]=useState(false);
 let answerText=value,photo='';
 try {
  const parsed=JSON.parse(value);
  if(typeof parsed?.text==='string')answerText=parsed.text;
  if(validImage(parsed?.documentPhoto))photo=parsed.documentPhoto;
 }catch { /* An older answer may be plain text. */ }
 return <div className="crAnswer">
  <div className="crResponse">
   <div className="crAnswerHeading"><MessageCircle size={16}/><h4>Resposta do motoboy</h4></div>
   <div className="crResponseText"><p>{answerText||'Nenhuma mensagem informada.'}</p></div>
   {photo?<button className="crAttachedDocument" type="button" onClick={()=>setExpanded(true)}>
    <img src={photo} alt="Miniatura do documento enviado pelo motoboy"/><span><ImageIcon size={15}/> Documento anexado<small>Ampliar para conferir</small></span><Expand size={15}/>
   </button>:<p className="crResponseNoPhoto"><ImageIcon size={15}/> Nenhuma foto anexada à resposta</p>}
  </div>
  {expanded&&photo&&<div className="crPreview" role="dialog" aria-modal="true" aria-label="Documento enviado pelo motoboy" onMouseDown={()=>setExpanded(false)} onKeyDown={e=>{if(e.key==='Escape')setExpanded(false)}}>
   <button type="button" autoFocus aria-label="Fechar foto do documento" onClick={()=>setExpanded(false)}><X size={20}/></button>
   <img src={photo} alt="Documento enviado pelo motoboy ampliado" onMouseDown={e=>e.stopPropagation()}/>
  </div>}
 </div>;
}

export default function CourierReviewWorkspace({
 user,app,close,request,resolve,requestRevision,cancel,children,embedded=false,onSupport
}:{
 user:RecordData;app:RecordData;close:()=>void;request:()=>void;
 resolve:(id:string)=>Promise<unknown>;requestRevision:(id:string,title:string,description:string)=>Promise<unknown>;
 cancel:(item:RecordData)=>ReactNode;children:ReactNode;embedded?:boolean;onSupport?:()=>void;
}){
 const [busy,setBusy]=useState<string|null>(null),[error,setError]=useState('');
 const [revision,setRevision]=useState<RecordData|null>(null);
 const [reason,setReason]=useState(''),[revisionTitle,setRevisionTitle]=useState(''),[revisionDescription,setRevisionDescription]=useState('');
 const requirements:RecordData[]=app.requirements||[];
 const active=requirements.filter(r=>!r.canceledAt&&r.status!=='RESOLVED');
 const answered=active.filter(r=>r.status==='ANSWERED');
 const resolved=requirements.filter(r=>!r.canceledAt&&r.status==='RESOLVED');
 const sortedActive=[...active].sort((a,b)=>Number(b.status==='ANSWERED')-Number(a.status==='ANSWERED'));
 const focus=sortedActive[0]||null;
 const data={...(app.onboardingData||user.courierProfile?.onboardingData||{}),...app};
 const approved=user.status==='ACTIVE'&&app.approvalStatus==='APPROVED';
 const blocked=user.status==='BLOCKED'||user.status==='SUSPENDED';
 const status=approved?'Conta liberada':user.status==='BLOCKED'?'Bloqueada':user.status==='SUSPENDED'?'Suspensa':'Pendente';
 const portrait=validImage(data.profilePhoto)?data.profilePhoto as string:'';
 const address=[data.city,data.state].filter(Boolean).join(' - ');
 const updatedAt=focus?.respondedAt||focus?.answeredAt||focus?.requestedAt||focus?.createdAt||user.createdAt;
 const history=[...requirements].sort((a,b)=>(new Date(b.requestedAt||b.createdAt||0).getTime()||0)-(new Date(a.requestedAt||a.createdAt||0).getTime()||0));

 async function finish(id:string) {
  if(busy)return;
  setBusy(id);setError('');
  try{const result=await resolve(id);if(result===null)throw new Error('Não foi possível concluir a pendência.');}
  catch(e){setError(e instanceof Error?e.message:'Não foi possível concluir a pendência.');}
  finally{setBusy(null);}
 }
 function openRevision(item:RecordData){
  if(busy)return;
  setRevision(item);setReason('');setRevisionTitle(String(item.title||''));setRevisionDescription('');setError('');
 }
 async function submitRevision(e:FormEvent) {
  e.preventDefault();
  if(!revision||busy||!revisionTitle.trim()||!revisionDescription.trim())return;
  setBusy('revision');setError('');
  try {
   const result=await requestRevision(String(revision.id),revisionTitle.trim(),revisionDescription.trim());
   if(result===null)throw new Error('Não foi possível solicitar o documento corrigido.');
   setRevision(null);
  }catch(e){setError(e instanceof Error?e.message:'Não foi possível enviar a solicitação.');}
  finally{setBusy(null);}
 }

 return <div className={embedded?'crEmbedded crReview2026':'crBackdrop crReview2026'}>
  <section className="crWorkspace" role={embedded?'region':'dialog'} aria-modal={embedded?undefined:true} aria-labelledby="crTitle">
   <header className="crHeader">
    {!embedded&&<button type="button" className="crBack" onClick={close}><ArrowLeft size={17}/> Voltar</button>}
    <div className="crHeaderTitle"><h2 id="crTitle">Análise de documentação</h2><p>Motoboys <ChevronDown size={12} className="crBreadcrumbArrow"/> {user.name||'Candidatura'}</p></div>
    <div className="crSyncHeader"><span className="crSyncCircle"/><strong>Atualizações automáticas</strong><small>Última atividade: {date(updatedAt)}</small></div>
    <span className={'crStatus crTopStatus '+(approved?'approved':blocked?'blocked':'')}><span className="crStatusDot"/>{active.length?'Pendências':status}</span>
   </header>
   <div className="crColumns">
    <section className="crIdentity" aria-label="Dados cadastrais do motoboy">
     <div className="crPortrait">{portrait?<img src={portrait} alt={'Foto do motoboy '+user.name}/>:<span>{initials(user.name)}</span>}</div>
     <span className={'crIdentityStatus'+(approved?' isApproved':'')}><span/> {status}</span>
     <h3>{user.name||'Motoboy'}</h3>
     <ul className="crContactDetails">
      <li><Phone size={16}/><span>{user.phone||'Telefone não informado'}</span></li>
      <li><Mail size={16}/><span title={user.email}>{user.email||'E-mail não informado'}</span></li>
      <li><BadgeCheck size={16}/><span>CPF {data.document||data.cpf||'não informado'}</span></li>
      {address&&<li><MapPin size={16}/><span>{address}</span></li>}
     </ul>
     <div className="crProfileDivider"/>
     <div className="crFact"><span className="crFactIcon"><Bike size={20}/></span><div><small>Moto informada</small><strong>{[data.vehicleBrand,data.vehicleModel].filter(Boolean).join(' ')||'Não informada'}</strong><small>Placa: {data.vehiclePlate||'—'}</small></div></div>
     <div className="crFact"><span className="crFactIcon"><FileText size={20}/></span><div><small>CNH</small><strong>{data.cnh||'Não informada'}</strong><small>Categoria: {data.cnhCategory||'—'}</small></div></div>
     <div className="crIdentityFoot"><ShieldCheck size={16}/> Dados conforme o cadastro do motoboy.</div>
     {onSupport&&<button type="button" className="crProfileSupport" onClick={onSupport}><Headphones size={15}/> Abrir central de suporte</button>}
    </section>

    <main className="crMain">
     <div className="crSteps" aria-label="Progresso da documentação">
      {['Cadastro','Documentos','Aprovação','Conta liberada'].map((label,i)=>{
       const done=approved||i===0,now=!approved&&i===1;
       return <div key={label} className={done?'done':now?'current':''}><span className="crStepIcon">{done?<Check size={16}/>:i===1?<ClipboardList size={16}/>:<ShieldCheck size={16}/>}</span><b>{label}</b><small>{done?'Concluído':now?'Em análise':'Pendente'}</small></div>;
      })}
     </div>

     <div className={'crNotice'+(active.length?'':' isClear')}>
      <span className="crNoticeSymbol">{active.length?<AlertTriangle size={22}/>:<CheckCircle2 size={22}/>}</span>
      <div><strong>{active.length?active.length+' pendência'+(active.length>1?'s':'')+' em andamento':'Sem pendências em aberto'}</strong><p>{answered.length?'Resposta recebida. Confira o documento e registre sua decisão.':active.length?'Aguardando o motoboy responder à solicitação.':'Documentação sem pendências ativas.'}</p></div>
      <button type="button" className="crRequestTop" onClick={request}><Plus size={15}/> Nova pendência</button>
     </div>
     {error&&!revision&&<p role="alert" className="crError"><AlertTriangle size={16}/>{error}</p>}

     <RequirementList items={requirements}>{r=><div className="crReviewItem">
      <div className="crRequirementHeader">
       <span className="crFileIcon"><FileText size={23}/></span>
       <div className="crRequirementTitle"><small className="crRequirementEyebrow">PENDÊNCIA DE DOCUMENTAÇÃO</small><h3>{r.title}</h3><p>{r.description}</p></div>
       <div className="crRequirementMeta"><span className={'crStatus crReqStatus '+(r.canceledAt?'canceled':r.status==='ANSWERED'?'answered':r.status==='RESOLVED'?'resolved':'awaiting')}>{r.canceledAt?'Cancelada':r.status==='RESOLVED'?'Resolvida':r.status==='ANSWERED'?'Respondida':'Aguardando motoboy'}</span><small>{date(r.respondedAt||r.answeredAt||r.requestedAt||r.createdAt)}</small></div>
      </div>
      <div className="crReviewDecisionGrid">
       {r.response?<Answer value={String(r.response)}/>:<div className="crPendingResponse"><MessageCircle size={18}/><strong>Resposta do motoboy</strong><div className="crPendingResponseBody"><Clock3 size={26}/><span>O motoboy ainda não enviou o documento solicitado.</span></div></div>}
       <div className="crDecision">
        <h4>Decisão do administrador</h4>
        {!r.canceledAt&&r.status==='ANSWERED'?<button className="crResolve" type="button" disabled={!!busy} onClick={()=>{if(r.id)void finish(String(r.id));}}><Check size={19}/><span><b>{busy===r.id?'Registrando…':'Aceitar resposta'}</b><small>Documento válido e pendência resolvida</small></span></button>:<div className="crDecisionWaiting"><Clock3 size={17}/>{r.canceledAt?'Solicitação encerrada':r.status==='RESOLVED'?'Pendência resolvida':'Aguardando envio para liberar a aprovação'}</div>}
        {!r.canceledAt&&r.status!=='RESOLVED'&&<button className="crAskAgain" type="button" disabled={!!busy} onClick={()=>openRevision(r)}><RefreshCw size={17}/><span><b>Solicitar novo documento</b><small>Revisar esta pendência e pedir correção</small></span></button>}
        <div className="crCancelSlot">{cancel(r)}</div>
       </div>
      </div>
      <details className="crItemHistory"><summary><History size={17}/> Histórico desta pendência <ChevronDown size={16}/></summary><div className="crItemHistoryBody"><p>Solicitada em {date(r.requestedAt||r.createdAt)}</p>{r.response&&<p>Resposta enviada pelo motoboy{r.respondedAt||r.answeredAt?' em '+date(r.respondedAt||r.answeredAt):''}</p>}{r.canceledAt&&<p>Solicitação encerrada em {date(r.canceledAt)}</p>}{r.resolvedAt&&!r.canceledAt&&<p>Resolvida em {date(r.resolvedAt)}</p>}</div></details>
     </div>}</RequirementList>
     {!requirements.length&&<div className="crNoRequirements"><ShieldCheck size={28}/><strong>Nenhuma pendência registrada</strong><p>O cadastro pode ser conferido ou você pode solicitar um documento.</p></div>}
     <details className="crGeneralHistory"><summary><History size={18}/> Histórico de solicitações <span>{requirements.length} registros</span><ChevronDown size={17}/></summary>
      <div className="crGeneralHistoryContent">
       <div><span className="crHistoryDot"/><b>Cadastro realizado</b><small>{date(user.createdAt)}</small></div>
       {history.map(r=><details className="crArchiveDetail" key={r.id}>
        <summary><span className="crHistoryDot"/><b>{r.title}</b><small>{r.canceledAt?'Solicitação encerrada':r.status==='RESOLVED'?'Pendência resolvida':r.status==='ANSWERED'?'Resposta recebida':'Aguardando documento'} · {date(r.canceledAt||r.resolvedAt||r.answeredAt||r.requestedAt||r.createdAt)}</small>{r.response&&<span className="crArchiveView">Ver resposta <ChevronDown size={13}/></span>}</summary>
        <div className="crArchiveBody"><p>{r.description}</p>{r.response&&<Answer value={String(r.response)}/>}</div>
       </details>)}
      </div>
     </details>
     <details className="crManagement"><summary><ClipboardList size={17}/> Dados cadastrais, ganhos e gerenciamento de acesso <ChevronDown size={17}/></summary><div className="crManagementBody">{children}</div></details>
    </main>


   </div>
  </section>

  {revision&&<div className="crRevisionBackdrop" onMouseDown={()=>!busy&&setRevision(null)}>
   <form className="crRevisionModal" role="dialog" aria-modal="true" aria-labelledby="crRevisionTitle" onMouseDown={e=>e.stopPropagation()} onSubmit={e=>void submitRevision(e)}>
    <header><div className="crRevisionIcon"><RefreshCw size={22}/></div><div><small>REVISÃO DE DOCUMENTAÇÃO</small><h3 id="crRevisionTitle">Solicitar um novo documento</h3><p>A pendência anterior será preservada no histórico. O motoboy receberá a nova orientação sem precisar reenviar o CPF.</p></div><button type="button" aria-label="Fechar" disabled={!!busy} onClick={()=>setRevision(null)}><X size={19}/></button></header>
    <label>O que precisa ser corrigido?<select autoFocus required value={reason} onChange={e=>{const v=e.target.value;const found=revisionReasons.find(item=>item.value===v);setReason(v);setRevisionTitle(found?.title||String(revision.title||''));setRevisionDescription(found?.detail||'');}}><option value="">Selecione o motivo</option>{revisionReasons.map(item=><option key={item.value} value={item.value}>{item.label}</option>)}</select></label>
    <label>Título da nova solicitação<input required maxLength={100} value={revisionTitle} onChange={e=>setRevisionTitle(e.target.value)} placeholder="Ex.: Foto do documento ilegível"/></label>
    <label>Orientação que o motoboy verá<textarea rows={4} required maxLength={950} value={revisionDescription} onChange={e=>setRevisionDescription(e.target.value)} placeholder="Descreva exatamente qual foto ou informação precisa ser enviada novamente."/></label>
    <div className="crRevisionPreview"><small>PRÉVIA DA MENSAGEM NO APP</small><strong>{revisionTitle||'Nova solicitação de documento'}</strong><p>{revisionDescription||'As orientações aparecerão aqui.'}</p></div>
    {error&&<p role="alert" className="crError"><AlertTriangle size={16}/>{error}</p>}
    <footer><button type="button" disabled={!!busy} onClick={()=>setRevision(null)}>Voltar</button><button type="submit" disabled={!!busy||!reason||!revisionTitle.trim()||!revisionDescription.trim()}><Send size={16}/>{busy==='revision'?'Enviando…':'Enviar solicitação ao motoboy'}</button></footer>
   </form>
  </div>}
 </div>;
}
