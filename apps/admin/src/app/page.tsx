"use client";
import CourierReviewWorkspace from './courier-review-workspace';
import RequirementList from './requirement-list';
import RequirementAnswer from './requirement-answer';
import PartnerDirectory from "./partner-directory";
import CustomerProfileWorkspace from "./customer-profile-workspace";
import CustomerDirectory from "./customer-directory";
import OrderAvailabilityEditor from "./order-availability-editor";
import OrderOperationWorkspace from "./order-operation-workspace";
import {printThermalOrders,selectThermalPrinter,thermalSupported} from "./order-thermal-printer";
import {orderDisplayNumber,canPrintCourierSlip} from "./order-display-number";
import OrderArchive, {isArchivedOrder} from "./order-archive";
import DemandControl from "./demand-control";
import CourierDirectory from "./courier-directory";
import CourierRecordEditor from "./courier-record-editor";
import DeliverySettings from "./delivery-settings";
import FinancePanel from "./finance-panel";
import SupportCenter, {SupportAlerts} from "./support-center";
import CatalogPanel from "./catalog-panel";
import { displayMessage } from "./ui-messages";
import { useEffect,useMemo,useState } from "react";
import { io } from "socket.io-client";
import {
  Activity,
  Headphones,
  ChevronDown,
  ChevronRight,
  Trash2,
  History,
  Banknote,
  Bike,
  Check,
  CircleAlert,
  CircleDollarSign,
  ClipboardList,
  CreditCard,
  CalendarDays,
  FileCheck2,
  Package,
  Printer,
  SlidersHorizontal,
  Truck,
  UserRound,
  ShoppingBag,
  Handshake,
  LayoutDashboard,
  LogOut,
  PackageSearch,
  RefreshCw,
  Search,
  Settings as SettingsIcon,
  UserCheck,
  Users,
  Wallet,
  X,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

type Row=Record<string,any>;
const requirementReasons=[
 {id:"photo_blur",title:"Foto de identificação ilegível",description:"Envie uma nova selfie ou foto de perfil, com o rosto visível, boa iluminação e sem desfoque."},
 {id:"photo_mismatch",title:"Foto de identificação não corresponde ao titular",description:"Envie uma foto atual do titular do cadastro, com o rosto totalmente visível, sem filtros ou acessórios que dificultem a identificação."},
 {id:"cnh_blur",title:"Foto da CNH ilegível",description:"Envie novamente a CNH, frente e verso, com todos os dados legíveis e sem cortes ou reflexos."},
 {id:"cnh_expired",title:"CNH vencida",description:"Envie a CNH atualizada, dentro do prazo de validade, com categoria compatível com o veículo informado."},
 {id:"cnh_category",title:"Categoria da CNH incompatível",description:"Confira a categoria da habilitação e envie o documento válido correspondente ao veículo usado nas entregas."},
 {id:"address_invalid",title:"Comprovante de residência inválido",description:"Envie um comprovante de residência legível, com data, endereço completo e identificação do titular. Explique a relação com o titular caso esteja em nome de outra pessoa."},
 {id:"address_outdated",title:"Comprovante de residência desatualizado",description:"Envie um comprovante de residência recente e confirme se o endereço corresponde ao informado no cadastro."},
 {id:"vehicle_document",title:"Documento do veículo pendente ou ilegível",description:"Envie o documento atualizado do veículo, com placa e dados do proprietário legíveis. Informe a autorização de uso caso o veículo pertença a outra pessoa."},
 {id:"plate",title:"Placa ou dados do veículo divergentes",description:"Confira a placa, marca, modelo e ano do veículo. Envie os dados corretos e um documento que permita validar essas informações."},
 {id:"pix",title:"Chave PIX inválida ou divergente",description:"Confira o tipo e a chave PIX informados. Envie uma chave válida do titular e confirme os dados para recebimento."},
 {id:"identity",title:"Dados pessoais divergentes",description:"Confira nome, CPF e data de nascimento. Informe os dados corretos e envie o documento necessário para esclarecer a divergência."},
 {id:"missing",title:"Documento ou informação não enviado",description:"Envie o documento ou informação indicado na observação abaixo para que possamos continuar a análise do cadastro."},
];
const base=()=>"/api/backend";
const realtimeOrigin=()=>{
 if(typeof window==="undefined")return "";
 const configured=process.env.NEXT_PUBLIC_API_ORIGIN;
 if(configured)return configured.replace(/\/$/,"");
 const u=new URL(window.location.href);
 if(u.hostname==="localhost"||u.hostname==="127.0.0.1")return u.protocol+"//"+u.hostname+":3000";
 const host=u.hostname.replace(/-\d+(?=\.app\.github\.dev$)/,"-3000");
 return u.protocol+"//"+host;
};
const adminDeviceId=()=>{
 if(typeof window==="undefined")return "admin-server";
 let id=localStorage.getItem("pp_admin_device_id");
 if(!id){id="admin-"+crypto.randomUUID();localStorage.setItem("pp_admin_device_id",id)}
 return id;
};
let adminRefreshPromise:Promise<string>|null=null;
async function refreshAdminSession(){
 if(adminRefreshPromise)return adminRefreshPromise;
 adminRefreshPromise=(async()=>{
  const refreshToken=typeof window!=="undefined"?localStorage.getItem("pp_admin_refresh"):"";
  if(!refreshToken)throw new Error("Sessão expirada");
  const rr=await fetch(base()+"/auth/refresh",{method:"POST",headers:{"Content-Type":"application/json","X-Device-Id":adminDeviceId(),"X-Device-Name":"Porto Prime Admin"},body:JSON.stringify({refreshToken}),cache:"no-store"});
  const rd=await rr.json().catch(()=>null);
  if(!rr.ok||!rd?.accessToken)throw new Error(Array.isArray(rd?.message)?rd.message.join(", "):rd?.message||"Sessão expirada");
  localStorage.setItem("pp_admin_token",rd.accessToken);
  if(rd.refreshToken)localStorage.setItem("pp_admin_refresh",rd.refreshToken);
  if(rd.sessionId)localStorage.setItem("pp_admin_session",rd.sessionId);
  return rd.accessToken as string;
 })().finally(()=>{adminRefreshPromise=null});
 return adminRefreshPromise;
}
async function api(path:string,token="",method="GET",body?:any,retry=true){
 let active=(typeof window!=="undefined"?localStorage.getItem("pp_admin_token")||"":"")||token;
 const send=(t:string)=>fetch(base()+path,{method,headers:{"Content-Type":"application/json","X-Device-Id":adminDeviceId(),"X-Device-Name":"Porto Prime Admin",...(t?{Authorization:"Bearer "+t}:{})},body:body===undefined?undefined:JSON.stringify(body),cache:"no-store"});
 let r=await send(active);
 if(r.status===401&&retry&&!["/auth/login","/auth/refresh"].includes(path)){
  try{active=await refreshAdminSession();r=await send(active)}catch{}
 }
 const d=await r.json().catch(()=>null);
 if(!r.ok)throw new Error(Array.isArray(d?.message)?d.message.join(", "):d?.message||"Falha na API");
 return d;
}
const customerCardRequest=(path:string,method="GET",body?:any)=>api(path,"",method,body);
const brl=(v:any)=>new Intl.NumberFormat("pt-BR",{style:"currency",currency:"BRL"}).format(Number(v||0));
const dt=(v:any)=>v?new Intl.DateTimeFormat("pt-BR",{dateStyle:"short",timeStyle:"short"}).format(new Date(v)):"—";
const statusLabel:Record<string,string>={ACTIVE:"Ativo",PENDING:"Pendente",SUSPENDED:"Suspenso",BLOCKED:"Bloqueado",PAID:"Pago",FAILED:"Falhou",REFUNDED:"Reembolsado",PARTIALLY_REFUNDED:"Reembolso parcial",CONFIRMED:"Confirmado",PREPARING:"Preparando",READY_FOR_PICKUP:"Pronto para retirada",SEARCHING_COURIER:"Procurando entregador",COURIER_ASSIGNED:"Motoboy atribuído",PICKED_UP:"Coletado",OUT_FOR_DELIVERY:"Em rota",DELIVERED:"Entregue",CANCELED:"Cancelado",APPROVED:"Aprovado",REJECTED:"Rejeitado",OPEN:"Aguardando motoboy",ANSWERED:"Respondida",RESOLVED:"Resolvida",PROCESSING:"Processando"};

export default function Home(){
 const [token,setToken]=useState(""),[email,setEmail]=useState(""),[password,setPassword]=useState(""),[name,setName]=useState("");
 const [me,setMe]=useState<Row|null>(null),[bootstrap,setBootstrap]=useState(false),[pending,setPending]=useState<Row[]>([]),[orders,setOrders]=useState<Row[]>([]),[users,setUsers]=useState<Row[]>([]),[catalog,setCatalog]=useState<Row[]>([]),[dash,setDash]=useState<Row>({}),[courierApps,setCourierApps]=useState<Row[]>([]);
 const [withdrawals,setWithdrawals]=useState<Row[]>([]),[pricing,setPricing]=useState<Row>({});
 const [partnerFinanceId,setPartnerFinanceId]=useState("");
 const [tab,setTab]=useState("Visão geral"),[error,setError]=useState(""),[busy,setBusy]=useState(false),[search,setSearch]=useState("");
 const [confirmBox,setConfirmBox]=useState<{title:string;message:string;detail?:string;confirm:string;action:()=>void}|null>(null);
 const [requirementBox,setRequirementBox]=useState<{courierId:string;name:string}|null>(null),[requirementTitle,setRequirementTitle]=useState(""),[requirementDescription,setRequirementDescription]=useState(""),[requirementError,setRequirementError]=useState("");
 const [forgot,setForgot]=useState(false),[resetToken,setResetToken]=useState(""),[newPassword,setNewPassword]=useState(""),[notice,setNotice]=useState("");
 const [lastSync,setLastSync]=useState<Date|null>(null),[activityNotice,setActivityNotice]=useState("");
 async function load(t=token){setBusy(true);setError("");try{const who=await api("/auth/me",t);if(who.role!=="ADMIN")throw new Error("Conta sem acesso administrativo");setMe(who);const [p,o,u,c,d,ca,w,pc]=await Promise.all([api("/admin/pending",t),api("/admin/orders",t),api("/admin/users?compactCouriers=true",t),api("/admin/catalog",t),api("/admin/dashboard",t),api("/admin/couriers?pending=true",t),api("/admin/withdrawals",t),api("/delivery/pricing-config",t)]);setPending(p);setOrders(o);setUsers(u);setCatalog(c);setDash(d);setCourierApps(ca);setWithdrawals(w);setPricing(pc);setLastSync(new Date());const current=localStorage.getItem("pp_admin_token")||t;if(current)setToken(current)}catch(e:any){setError(e.message);setMe(null);localStorage.removeItem("pp_admin_token");localStorage.removeItem("pp_admin_refresh");localStorage.removeItem("pp_admin_session")}finally{setBusy(false)}}
 useEffect(()=>{const t=localStorage.getItem("pp_admin_token");if(t){setToken(t);load(t);return}api("/auth/bootstrap-admin").then(d=>setBootstrap(!!d.available)).catch(()=>setBootstrap(false))},[]);
 useEffect(()=>{if(!me||!token)return;let previous={orders:orders.length,pending:pending.length};const sync=async()=>{if(document.visibilityState!=="visible")return;try{const current=localStorage.getItem("pp_admin_token")||token;const [p,o,u,c,d,ca,w,pc]=await Promise.all([api("/admin/pending",current),api("/admin/orders",current),api("/admin/users?compactCouriers=true",current),api("/admin/catalog",current),api("/admin/dashboard",current),api("/admin/couriers?pending=true",current),api("/admin/withdrawals",current),api("/delivery/pricing-config",current)]);const changes:string[]=[];if(o.length>previous.orders)changes.push((o.length-previous.orders)+" novo(s) pedido(s)");if(p.length>previous.pending)changes.push((p.length-previous.pending)+" novo(s) cadastro(s) aguardando aprovação");previous={orders:o.length,pending:p.length};setPending(p);setOrders(o);setUsers(u);setCatalog(c);setDash(d);setCourierApps(ca);setWithdrawals(w);setPricing(pc);setLastSync(new Date());const fresh=localStorage.getItem("pp_admin_token");if(fresh&&fresh!==token)setToken(fresh);if(changes.length){setActivityNotice(changes.join(" · "));setTimeout(()=>setActivityNotice(""),7000)}}catch{}};const id=window.setInterval(sync,10000);const visible=()=>{if(document.visibilityState==="visible")sync()};document.addEventListener("visibilitychange",visible);return()=>{window.clearInterval(id);document.removeEventListener("visibilitychange",visible)}},[me,token]);

 useEffect(()=>{if(!me||!token)return;let refreshTimer:ReturnType<typeof setTimeout>|null=null;const current=localStorage.getItem("pp_admin_token")||token;const socket=io(realtimeOrigin(),{transports:["websocket"],auth:{token:current},reconnection:true,reconnectionAttempts:30,reconnectionDelay:1000});const refresh=()=>{if(refreshTimer)clearTimeout(refreshTimer);refreshTimer=setTimeout(()=>{const fresh=localStorage.getItem("pp_admin_token")||token;load(fresh)},180)};["order.created","order.updated","order.admin.deleted","dispatch.offer","dispatch.offer.closed","courier.presence","wallet.updated","partner.profile.updated","courier.profile.updated","courier.demand.updated","catalog.updated","store.updated","delivery.pricing.updated","addresses.updated"].forEach(event=>socket.on(event,refresh));["order.updated","order.admin.deleted"].forEach(event=>socket.on(event,payload=>window.dispatchEvent(new CustomEvent("porto.customer.orders",{detail:payload}))));socket.on("support.updated",payload=>{window.dispatchEvent(new CustomEvent("porto.support.updated",{detail:payload}))});socket.on("partner.profile.updated",payload=>window.dispatchEvent(new CustomEvent("porto.partner.updated",{detail:payload})));socket.on("customer.profile.updated",payload=>window.dispatchEvent(new CustomEvent("porto.customer.profile",{detail:payload})));socket.on("addresses.updated",payload=>window.dispatchEvent(new CustomEvent("porto.customer.profile",{detail:payload})));socket.on("customer.credit.updated",payload=>window.dispatchEvent(new CustomEvent("porto.customer.credit",{detail:payload})));socket.on("session.revoked",()=>{localStorage.removeItem("pp_admin_token");localStorage.removeItem("pp_admin_refresh");localStorage.removeItem("pp_admin_session");location.reload()});socket.io.on("reconnect_attempt",()=>{socket.auth={token:localStorage.getItem("pp_admin_token")||token}});return()=>{if(refreshTimer)clearTimeout(refreshTimer);socket.disconnect()}},[me,token]);
 async function login(e:React.FormEvent){e.preventDefault();setBusy(true);setError("");try{const d=await api("/auth/login","","POST",{email,password});const access=d.accessToken||d.token;localStorage.setItem("pp_admin_token",access);if(d.refreshToken)localStorage.setItem("pp_admin_refresh",d.refreshToken);if(d.sessionId)localStorage.setItem("pp_admin_session",d.sessionId);setToken(access);await load(access)}catch(e:any){setError(e.message);setBusy(false)}}
 async function createAdmin(e:React.FormEvent){e.preventDefault();setBusy(true);setError("");try{await api("/auth/bootstrap-admin","","POST",{name,email,password});setBootstrap(false);await login(e)}catch(e:any){setError(e.message);setBusy(false)}}
 async function act(path:string,method="PATCH",body?:any){try{setBusy(true);setError("");const result=await api(path,token,method,body);await load();if(result?.message){setActivityNotice(result.message);setTimeout(()=>setActivityNotice(""),7000)}if(Array.isArray(result?.failed)&&result.failed.length){setError(result.failed.slice(0,4).map((x:Row)=>x.reason).join(" · "))}return result}catch(e:any){setError(e.message);setBusy(false);return null}}
 const couriers=users.filter(x=>x.role==="COURIER"), customers=users.filter(x=>x.role==="CUSTOMER"),partners=users.filter(x=>x.role==="PARTNER");
 const courierByUser=useMemo(()=>Object.fromEntries(courierApps.filter(x=>x.user?.id).map(x=>[x.user.id,x])),[courierApps]);
 const [requirementReason,setRequirementReason]=useState(""),[requirementNote,setRequirementNote]=useState("");
 const requestRequirement=(app:Row,name:string)=>{setRequirementReason("");setRequirementNote("");setRequirementTitle("");setRequirementDescription("");setRequirementError("");setRequirementBox({courierId:app.id,name})};
 const filtered=(rows:Row[])=>rows.filter(x=>JSON.stringify(x).toLowerCase().includes(search.toLowerCase()));
 if(!me)return <main className="login"><section className="brand"><div className="mark">P</div><span>PORTO PRIME</span><h1>Central de<br/>Operações</h1><p>Controle exclusivo da Porto Prime Delivery.</p><div className="security">● Ambiente administrativo protegido</div></section><section className="loginCard"><small>{forgot?"RECUPERAÇÃO SEGURA":bootstrap?"CONFIGURAÇÃO INICIAL":"ACESSO RESTRITO"}</small><h2>{forgot?"Recuperar senha":bootstrap?"Criar primeiro administrador":"Entrar no Admin"}</h2><p>{forgot?"Informe seu e-mail para iniciar a redefinição.":bootstrap?"Defina a conta principal da operação.":"Use sua conta administrativa."}</p>{forgot?<form onSubmit={async e=>{e.preventDefault();setBusy(true);setError("");try{const d=await api("/auth/forgot-password","","POST",{email});if(d.resetToken){setResetToken(d.resetToken);setNotice("Ambiente de desenvolvimento: defina sua nova senha agora.")}else setNotice("Se o e-mail estiver cadastrado, as instruções de recuperação serão enviadas.")}catch(e:any){setError(e.message)}finally{setBusy(false)}}}><label>E-mail<input type="email" value={email} onChange={e=>setEmail(e.target.value)} required/></label>{resetToken&&<label>Nova senha<input type="password" minLength={8} value={newPassword} onChange={e=>setNewPassword(e.target.value)} required/></label>}{notice&&<div className="security">{notice}</div>}{error&&<div className="error" role="alert">{displayMessage(error)}</div>}{resetToken?<button type="button" disabled={busy||newPassword.length<8} onClick={async()=>{try{setBusy(true);await api("/auth/reset-password","","POST",{token:resetToken,password:newPassword});setForgot(false);setResetToken("");setNewPassword("");setNotice("Senha alterada. Entre com sua nova senha.")}catch(e:any){setError(e.message)}finally{setBusy(false)}}}>Salvar nova senha</button>:<button disabled={busy}>{busy?"Aguarde...":"Continuar"}</button>}<button type="button" className="secondary" onClick={()=>{setForgot(false);setResetToken("");setError("")}}>Voltar ao login</button></form>:<form onSubmit={bootstrap?createAdmin:login}>{bootstrap&&<label>Nome<input value={name} onChange={e=>setName(e.target.value)} required/></label>}<label>E-mail<input type="email" value={email} onChange={e=>setEmail(e.target.value)} required/></label><label>Senha<input type="password" minLength={8} value={password} onChange={e=>setPassword(e.target.value)} required/></label>{notice&&<div className="security">{notice}</div>}{error&&<div className="error" role="alert">{displayMessage(error)}</div>}<button disabled={busy}>{busy?"Aguarde...":bootstrap?"Criar administrador e entrar":"Acessar painel"}</button>{!bootstrap&&<button type="button" className="forgotLink" onClick={()=>{setForgot(true);setError("");setNotice("")}}>Esqueci minha senha</button>}</form>}</section></main>;
 const nav: Array<[string, LucideIcon]> = [
  ["Visão geral", LayoutDashboard],
  ["Pedidos", ClipboardList],
  ["Aprovações", UserCheck],
  ["Motoboys", Bike],
  ["Clientes", Users],
  ["Parceiros", Handshake],
  ["Catálogo", PackageSearch],
  ["Pagamentos e Arquivo", CreditCard],
  ["Saques", Wallet],
  ["Suporte", Headphones],
  ["Configurações", SettingsIcon],
];
 const openCourierSupport=()=>{try{sessionStorage.setItem("pp_support_open",JSON.stringify({id:"",role:"COURIER"}))}catch{}setTab("Suporte")};
 return <div className="shell"><aside><div className="logo"><b>P</b><div><strong>PORTO PRIME</strong><span>CENTRAL DE OPERAÇÕES</span></div></div><nav aria-label="Navegação administrativa">{[{label:"OPERAÇÃO",items:nav.slice(0,4)},{label:"PESSOAS E LOJA",items:nav.slice(4,7)},{label:"GESTÃO",items:nav.slice(7)}].map(section=><div className="navGroup" key={section.label}><span className="navGroupLabel">{section.label}</span>{section.items.map(([n,NavIcon])=><button key={n} type="button" aria-current={tab===n?"page":undefined} title={n} className={tab===n?"active":""} onClick={()=>{setPartnerFinanceId("");setTab(n);setSearch("")}}><NavIcon className="navIcon" size={18} strokeWidth={1.8}/><span>{n}</span>{n==="Aprovações"&&pending.length>0&&<em>{pending.length}</em>}</button>)}</div>)}</nav><div className="admin"><span>{me.name?.[0]}</span><div><b>{me.name}</b><small>Administrador</small></div><button title="Sair" aria-label="Sair" onClick={async()=>{try{await api("/auth/logout",token,"POST")}catch{}localStorage.removeItem("pp_admin_token");localStorage.removeItem("pp_admin_refresh");localStorage.removeItem("pp_admin_session");location.reload()}}><LogOut size={16}/></button></div></aside>
 <main className="content" aria-busy={busy}><SupportAlerts onOpen={()=>setTab("Suporte")}/><header className="workspaceHeader"><div className="workspaceHeading"><small>PORTO PRIME <span aria-hidden="true">/</span> CENTRAL DE OPERAÇÕES</small><h1>{tab}</h1><p className="workspaceSubtitle">{({"Visão geral":"O essencial da operação, em um só lugar.","Pedidos":"Conferência, despacho e entregas sob controle.","Aprovações":"Analise cadastros e pendências com clareza.","Motoboys":"Disponibilidade, perfis e gestão de entregadores.","Clientes":"Consulte perfis, endereços e histórico de pedidos.","Parceiros":"Cadastros, indicações e condições comerciais.","Catálogo":"Organize a vitrine, categorias, estoque e produtos.","Pagamentos e Arquivo":"Histórico de pedidos e operações financeiras.","Saques":"Carteiras, solicitações e repasses.","Suporte":"Atendimentos centralizados por prioridade.","Configurações":"Regras e parâmetros operacionais da plataforma."} as Record<string,string>)[tab]}</p></div><div className="headActions">{tab!=="Visão geral"&&tab!=="Configurações"&&tab!=="Catálogo"&&tab!=="Saques"&&tab!=="Suporte"&&tab!=="Pagamentos e Arquivo"&&tab!=="Clientes"&&tab!=="Pedidos"&&<label className="searchBox"><Search size={16}/><input className="search" aria-label="Buscar" placeholder="Buscar na operação..." value={search} onChange={e=>setSearch(e.target.value)}/>{search&&<button type="button" aria-label="Limpar busca" onClick={()=>setSearch("")}><X size={14}/></button>}</label>}<button className="live" title="Clique para sincronizar agora" onClick={()=>load()}><RefreshCw size={14}/><span>Sincronização automática</span>{lastSync&&<small>{lastSync.toLocaleTimeString("pt-BR",{hour:"2-digit",minute:"2-digit"})}</small>}</button></div></header>{activityNotice&&<div className="activityToast" role="status"><b>Nova atividade</b><span>{activityNotice}</span></div>}{error&&<div className="error top" role="alert">{displayMessage(error)}</div>}{busy&&<div className="loading" role="status"><span className="loadingSpinner"/><span>Sincronizando dados...</span></div>}
 {tab==="Visão geral"&&<Dashboard dash={dash} orders={orders} pending={pending} withdrawals={withdrawals}/>} 
 {tab==="Pedidos"&&<Orders rows={orders.filter(o=>!isArchivedOrder(o))} act={act} ask={setConfirmBox} token={token} products={catalog.filter(c=>c.active&&!c.archived).flatMap(c=>c.products||[])}/>} 
 {tab==="Pagamentos e Arquivo"&&<OrderArchive orders={orders} request={(path,method,body)=>api(path,token,method,body)} reload={()=>load()}/>}
 {tab==="Aprovações"&&<Pending rows={filtered(pending)} act={act} courierByUser={courierByUser} requestRequirement={requestRequirement} onSupport={openCourierSupport}/>}
 {tab==="Motoboys"&&<CourierDirectory request={path=>api(path,token)} act={act} ask={setConfirmBox} requestRequirement={requestRequirement} epoch={lastSync?.getTime()||0} globalSearch={search} clearGlobalSearch={()=>setSearch("")} renderProfile={(profile,close)=><CourierAdminProfile user={profile.user} app={profile} close={close} act={act} requestRequirement={requestRequirement} onSupport={openCourierSupport}/>}/>}
 {tab==="Clientes"&&<People rows={customers} kind="Cliente" act={act} ask={setConfirmBox} courierByUser={courierByUser} requestRequirement={requestRequirement}/>}
 {tab==="Parceiros"&&<PartnerDirectory rows={partners} token={token} api={api} act={act} onFinance={id=>{setPartnerFinanceId(id);setTab("Saques")}}/>}
 {tab==="Catálogo"&&<CatalogPanel categories={catalog} pricing={pricing} act={act}/>}
 {tab==="Suporte"&&<SupportCenter request={(path,method="GET",body)=>api(path,token,method,body)}/>}
 {tab==="Saques"&&<FinancePanel rows={withdrawals} token={token} api={api} initialAccountId={partnerFinanceId}/>}
 {tab==="Configurações"&&<div className="settingsWorkspace"><DemandControl epoch={lastSync?.getTime()||0} request={(path,method="GET",body)=>api(path,token,method,body)}/><Settings me={me} dash={dash} pricing={pricing} act={act}/></div>} 
 {confirmBox&&<div className="modalBackdrop" onMouseDown={()=>setConfirmBox(null)}><section className="dangerModal" onMouseDown={e=>e.stopPropagation()}><div className="dangerIcon"><CircleAlert size={27}/></div><small>ATENÇÃO · AÇÃO IRREVERSÍVEL</small><h2>{confirmBox.title}</h2><p>{confirmBox.message}</p>{confirmBox.detail&&<div className="dangerDetail">{confirmBox.detail}</div>}<div className="dangerNotice"><b>Esta ação não poderá ser desfeita.</b><span>Confirme somente se tiver certeza de que deseja remover este registro definitivamente.</span></div><div className="modalActions"><button className="cancelBtn" onClick={()=>setConfirmBox(null)}>Cancelar</button><button className="deleteBtn" onClick={()=>{const fn=confirmBox.action;setConfirmBox(null);fn()}}>{confirmBox.confirm}</button></div></section></div>}
 {requirementBox&&<div className="modalBackdrop requirementBackdrop" onMouseDown={()=>!busy&&setRequirementBox(null)}><form className="requirementModal" onMouseDown={e=>e.stopPropagation()} onSubmit={async e=>{e.preventDefault();if(!requirementTitle.trim()||!requirementDescription.trim())return;setBusy(true);setRequirementError("");setError("");try{await api("/admin/couriers/"+requirementBox.courierId+"/requirements",token,"POST",{title:requirementTitle.trim(),description:requirementDescription.trim()+(requirementNote.trim()?"\n\nObservação do Admin: "+requirementNote.trim():"")});await load(token);setRequirementBox(null);setRequirementTitle("");setRequirementDescription("");setActivityNotice("Pendência enviada ao motoboy com sucesso");setTimeout(()=>setActivityNotice(""),7000)}catch(err:any){setRequirementError(err.message||"Não foi possível enviar a pendência");setError(err.message||"Não foi possível enviar a pendência")}finally{setBusy(false)}}}><div className="requirementModalHead"><div className="requirementModalIcon"><CircleAlert size={24}/></div><div><small>PENDÊNCIA DE CADASTRO</small><h2>Solicitar informação</h2><p>Envie uma solicitação clara para <b>{requirementBox.name}</b>. Ela ficará disponível na consulta de candidatura do motoboy.</p></div></div><div className="requirementGuide"><span>1</span><div><b>Seja específico</b><small>Informe exatamente qual documento ou dado precisa ser corrigido.</small></div></div><label>Motivo da solicitação<select autoFocus required value={requirementReason} onChange={e=>{const id=e.target.value;setRequirementReason(id);const reason=requirementReasons.find(r=>r.id===id);setRequirementTitle(reason?.title||"");setRequirementDescription(reason?.description||"")}}><option value="">Selecione uma situação</option>{requirementReasons.map(r=><option key={r.id} value={r.id}>{r.title}</option>)}<option value="custom">Outra situação · escrever solicitação</option></select></label><label>Título da pendência<input value={requirementTitle} onChange={e=>setRequirementTitle(e.target.value)} placeholder="Ex.: Foto da CNH ilegível" required maxLength={100}/></label><label>Orientação para o motoboy<textarea value={requirementDescription} onChange={e=>setRequirementDescription(e.target.value)} placeholder="Ex.: Envie uma nova foto da CNH, frente e verso, com todos os dados legíveis." required maxLength={600}/></label><label>Observação adicional · opcional<textarea value={requirementNote} onChange={e=>setRequirementNote(e.target.value)} placeholder="Detalhe o documento, a informação ou a correção necessária." maxLength={350}/></label><div className="requirementPreview"><small>O MOTOBOY RECEBERÁ</small><b>{requirementTitle||"Selecione o motivo acima"}</b><p>{requirementDescription}</p>{requirementNote&&<p><strong>Observação:</strong> {requirementNote}</p>}</div>{requirementError&&<div className="requirementError" role="alert">{displayMessage(requirementError)}</div>}<div className="modalActions"><button type="button" className="cancelBtn" disabled={busy} onClick={()=>setRequirementBox(null)}>Cancelar</button><button disabled={busy||!requirementTitle.trim()||!requirementDescription.trim()}>{busy?"Enviando...":"Enviar pendência ao motoboy"}</button></div></form></div>}
 </main></div>
}
function Card({label,value,note,icon:Icon}:{label:string,value:any,note:string,icon:LucideIcon}){return <article><div className="metricIcon"><Icon size={18} strokeWidth={2}/></div><span>{label}</span><strong>{value}</strong><small>{note}</small></article>}
function Dashboard({dash,orders,pending,withdrawals}:{dash:Row,orders:Row[],pending:Row[],withdrawals:Row[]}){
  const awaiting=orders.filter(o=>["PENDING","CONFIRMED"].includes(o.status)).length;
  const released=orders.filter(o=>["PREPARING","READY_FOR_PICKUP"].includes(o.status)).length;
  const searching=orders.filter(o=>o.status==="SEARCHING_COURIER").length;
  const active=orders.filter(o=>["COURIER_ASSIGNED","PICKED_UP","OUT_FOR_DELIVERY"].includes(o.status)).length;
  const finished=orders.filter(o=>o.status==="DELIVERED").length;
  const pendingWithdrawals=withdrawals.filter(w=>["PENDING","PROCESSING"].includes(w.status)).length;
  return <div className="overviewWorkspace">
    <section className="overviewWelcome">
      <div><span className="overviewKicker"><Activity size={14}/> VISÃO OPERACIONAL</span><h2>Acompanhe o que importa.</h2><p>Pedidos, entregas e equipe organizados para agir com rapidez.</p></div>
      <div className="overviewActive"><span className="overviewActiveDot"/><strong>{active+searching}</strong><span>operações em andamento</span></div>
    </section>
    <section className="metrics opsMetrics overviewPriority" aria-label="Indicadores principais">
      <Card icon={ClipboardList} label="Aguardando conferência" value={awaiting} note="Pedidos para analisar"/>
      <Card icon={Search} label="Buscando motoboy" value={searching} note="Despacho em andamento"/>
      <Card icon={Bike} label="Entregas ativas" value={active} note="Motoboys em operação"/>
      <Card icon={Activity} label="Motoboys online" value={dash.onlineCouriers||0} note="Disponíveis na plataforma"/>
    </section>
    <section className="grid overviewPanels">
      <Panel title="Pedidos recentes"><MiniOrders rows={orders.slice(0,6)}/></Panel>
      <Panel title="Panorama da plataforma"><div className="radar"><div className="radarIcon"><CircleDollarSign size={18}/></div><b>{dash.users||0}</b><span>usuários cadastrados</span><div className="radarIcon"><PackageSearch size={18}/></div><b>{dash.products||0}</b><span>produtos ativos</span></div></Panel>
    </section>
    <details className="overviewAdditional">
      <summary><span><LayoutDashboard size={17}/> Outros indicadores</span><span>Produção, cadastros e financeiro <ChevronDown size={16}/></span></summary>
      <div className="overviewAdditionalContent">
        <section className="metrics opsMetrics overviewSecondary" aria-label="Indicadores adicionais">
          <Card icon={PackageSearch} label="Liberados" value={released} note="Preparação / retirada"/>
          <Card icon={Check} label="Finalizados" value={finished} note="Pedidos entregues"/>
          <Card icon={UserCheck} label="Cadastros pendentes" value={pending.length} note="Precisam de análise"/>
          <Card icon={Wallet} label="Saques pendentes" value={pendingWithdrawals} note="Pendente / processamento"/>
        </section>
        <section className="metrics financeMetrics overviewFinance">
          <Card icon={Banknote} label="Receita paga" value={brl(dash.revenue)} note="Pedidos confirmados"/>
          <Card icon={ClipboardList} label="Pedidos registrados" value={dash.orders||0} note="Histórico total"/>
        </section>
      </div>
    </details>
  </div>;
}
function Panel({title,children}:{title:string,children:React.ReactNode}){return <section className="panel"><div className="panelHead"><h3>{title}</h3><span>Dados em tempo real</span></div>{children}</section>}
function Badge({v}:{v:string}){return <span className={"badge b-"+v.toLowerCase()}>{statusLabel[v]||v}</span>}
function MiniOrders({rows}:{rows:Row[]}){return <div className="rows">{rows.map(o=><div className="row" key={o.id}><div className="order">#{orderDisplayNumber(o)}</div><div className="grow"><b>{o.customer?.name}</b><span>{brl(o.total)}</span><small>{dt(o.createdAt)}</small></div><Badge v={o.status}/></div>)}</div>}
function Pending(props:{rows:Row[],act:any,courierByUser:Record<string,Row>,requestRequirement:(app:Row,name:string)=>void,onSupport:()=>void}){
 const [selected,setSelected]=useState("");
 const couriers=props.rows.filter(r=>r.role==="COURIER");
 const others=props.rows.filter(r=>r.role!=="COURIER");
 const current=couriers.find(r=>r.id===selected)||couriers[0];
 if(!couriers.length)return <PendingLegacy {...props}/>;
 return <div className="unifiedCourierQueue">{couriers.length>1&&<header className="unifiedCourierQueueHead"><div><small>CENTRAL DE ANÁLISE</small><h2>Candidaturas dos motoboys</h2><p>Documentos, respostas e decisões em um só lugar.</p></div><label>Candidato <select value={current.id} onChange={e=>setSelected(e.target.value)}>{couriers.map(c=><option value={c.id} key={c.id}>{c.name}</option>)}</select><span>{couriers.length} aguardando análise</span></label></header>}<CourierAdminProfile key={current.id} embedded user={current} app={props.courierByUser[current.id]||current.courierProfile||{}} close={()=>{}} act={props.act} requestRequirement={props.requestRequirement} onSupport={props.onSupport}/>{others.length>0&&<PendingLegacy {...props} rows={others}/>}</div>;
}
function PendingLegacy({rows,act,courierByUser,requestRequirement}:{rows:Row[],act:any,courierByUser:Record<string,Row>,requestRequirement:(app:Row,name:string)=>void}){
 const [detail,setDetail]=useState<Row|null>(null);
 const label=(key:string)=>({birthDate:"Data de nascimento",cpf:"CPF",document:"Documento",cnh:"CNH",cnhCategory:"Categoria CNH",cnhExpiry:"Validade da CNH",vehicleType:"Tipo do veículo",vehicleBrand:"Marca",vehicleModel:"Modelo",vehicleYear:"Ano",vehiclePlate:"Placa",pixKey:"Chave PIX",pixKeyType:"Tipo de chave PIX",cep:"CEP",postalCode:"CEP",street:"Rua",number:"Número",complement:"Complemento",neighborhood:"Bairro",city:"Cidade",state:"Estado",phone:"Telefone",email:"E-mail",businessName:"Estabelecimento"} as Record<string,string>)[key]||key.replace(/([A-Z])/g," $1").replace(/^./,s=>s.toUpperCase());
 const value=(v:any)=>v===null||v===undefined||v===""?"—":typeof v==="object"?JSON.stringify(v):String(v);
 if(!rows.length)return <section className="approvalEmpty"><div className="approvalEmptyIcon"><Check size={26}/></div><div><small>FILA DE ANÁLISE</small><h2>Tudo em dia por aqui.</h2><p>Nenhum cadastro está aguardando aprovação neste momento.</p></div></section>;
 return <><section className="approvalHero"><div><small>CENTRAL DE APROVAÇÕES</small><h2>Analise cada candidatura<br/>com segurança.</h2><p>Documentos, veículo e pendências reunidos em uma visão operacional limpa para decisões mais rápidas.</p></div><div className="approvalCount"><b>{rows.length}</b><span>{rows.length===1?"cadastro aguardando":"cadastros aguardando"}</span></div></section><div className="approvalGrid">{rows.map(x=>{const app=courierByUser[x.id]||x.courierProfile;const requirements:Row[]=app?.requirements||[];const unresolved=requirements.filter(r=>!r.canceledAt&&r.status!=="RESOLVED");const onboarding=x.courierProfile?.onboardingData||x.partnerProfile?.onboardingData||{};return <article className="approvalCard" key={x.id}><div className="approvalCardTop"><div className="approvalIdentity"><div className="approvalAvatar">{(x.name||"?").slice(0,1).toUpperCase()}</div><div><div className="approvalRole">{x.role==="COURIER"?"MOTOBOY":"PARCEIRO"}</div><h3>{x.name}</h3><span>Cadastrado em {dt(x.createdAt)}</span></div></div><Badge v={app?.approvalStatus||x.status}/></div><div className="approvalFacts"><div><span>Contato</span><b>{x.phone||"Não informado"}</b><small>{x.email}</small></div>{x.role==="COURIER"?<><div><span>Documento</span><b>{app?.document||onboarding.cpf||"—"}</b><small>CPF do candidato</small></div><div><span>Habilitação</span><b>{app?.cnh||onboarding.cnh||"—"}</b><small>{app?.cnhCategory?"Categoria "+app.cnhCategory:"CNH informada"}</small></div><div><span>Veículo</span><b>{[app?.vehicleBrand||onboarding.vehicleBrand,app?.vehicleModel||onboarding.vehicleModel].filter(Boolean).join(" ")||"—"}</b><small>{[app?.vehiclePlate||onboarding.vehiclePlate,app?.vehicleYear||onboarding.vehicleYear].filter(Boolean).join(" · ")||"Dados do veículo"}</small></div></>:<div><span>Estabelecimento</span><b>{x.partnerProfile?.businessName||onboarding.businessName||"—"}</b><small>{x.partnerProfile?.document||onboarding.document||"Cadastro parceiro"}</small></div>}</div>{x.role==="COURIER"&&app&&<section className={"approvalRequirements "+(unresolved.length?"hasPending":"")}><div className="approvalRequirementsHead"><div><span className="approvalDot"></span><div><b>{unresolved.length?unresolved.length+" pendência(s) em andamento":"Documentação sem pendências"}</b><small>{unresolved.length?"A aprovação fica bloqueada até a conclusão.":"Você pode solicitar informação adicional antes de aprovar."}</small></div></div><button className="secondary requirementTrigger" onClick={()=>requestRequirement(app,x.name)}>+ Solicitar pendência</button></div>{requirements.length>0&&<div className="approvalRequirementList"><RequirementList items={requirements}>{(r:Row)=><div className="approvalRequirement" key={r.id}><div><b>{r.title}</b><Badge v={r.canceledAt?"CANCELED":r.status}/></div><p>{r.description}</p>{r.response&&<div className="approvalResponse"><small>RESPOSTA RECEBIDA</small><RequirementAnswer value={r.response}/></div>}{!r.canceledAt&&r.status==="ANSWERED"&&<button onClick={()=>act("/admin/requirements/"+r.id+"/resolve","PATCH")}><Check size={14}/> Marcar como resolvida</button>}<CancelRequirement requirement={r} act={act}/></div>}</RequirementList></div>}</section>}<div className="approvalFooter"><button className="profileButton" onClick={()=>setDetail({user:x,app,onboarding})}>Ver dados completos</button><div className="approvalActions"><button className="danger" onClick={()=>act("/admin/users/"+x.id+"/reject")}>Rejeitar</button><button disabled={x.role==="COURIER"&&unresolved.length>0} title={unresolved.length?"Resolva todas as pendências antes de aprovar":""} onClick={()=>act("/admin/users/"+x.id+"/approve")}>{unresolved.length?"Aguardando pendências":"Aprovar cadastro"}</button></div></div></article>})}</div>{detail&&detail.user.role==="COURIER"?<CourierAdminProfile user={rows.find(r=>r.id===detail.user.id)||detail.user} app={courierByUser[detail.user.id]||detail.app||{}} close={()=>setDetail(null)} act={act} requestRequirement={requestRequirement}/>:detail&&<div className="modalBackdrop profileBackdrop" onMouseDown={()=>setDetail(null)}><section className="profileModal" onMouseDown={e=>e.stopPropagation()}><div className="profileModalHero"><button className="profileClose" aria-label="Fechar" onClick={()=>setDetail(null)}><X size={18}/></button><div className="profileModalAvatar">{(detail.user.name||"?").slice(0,1).toUpperCase()}</div><div><small>DOSSIÊ DE CADASTRO</small><h2>{detail.user.name}</h2><p>{detail.user.role==="COURIER"?"Candidatura para motoboy":"Cadastro de parceiro"} · {detail.user.email}</p></div><Badge v={detail.app?.approvalStatus||detail.user.status}/></div><div className="profileSummary"><div><span>Telefone</span><b>{detail.user.phone||"—"}</b></div><div><span>Cadastrado em</span><b>{dt(detail.user.createdAt)}</b></div><div><span>ID do usuário</span><b>{detail.user.id}</b></div></div>{detail.user.role==="COURIER"&&<section className="profileSection"><div className="profileSectionTitle"><span>01</span><div><b>Documentos e veículo</b><small>Dados essenciais para análise operacional</small></div></div><div className="profileDataGrid"><div><span>CPF</span><b>{detail.app?.document||detail.onboarding?.cpf||"—"}</b></div><div><span>CNH</span><b>{detail.app?.cnh||detail.onboarding?.cnh||"—"}</b></div><div><span>Categoria</span><b>{detail.app?.cnhCategory||detail.onboarding?.cnhCategory||"—"}</b></div><div><span>Veículo</span><b>{[detail.app?.vehicleBrand||detail.onboarding?.vehicleBrand,detail.app?.vehicleModel||detail.onboarding?.vehicleModel].filter(Boolean).join(" ")||"—"}</b></div><div><span>Placa</span><b>{detail.app?.vehiclePlate||detail.onboarding?.vehiclePlate||"—"}</b></div><div><span>Ano</span><b>{detail.app?.vehicleYear||detail.onboarding?.vehicleYear||"—"}</b></div></div></section>}<section className="profileSection"><div className="profileSectionTitle"><span>02</span><div><b>Informações completas</b><small>Todos os campos enviados no formulário de cadastro</small></div></div><div className="profileDataGrid full">{Object.entries(detail.onboarding||{}).filter(([k,v])=>k!=="profilePhoto"&&v!==null&&v!==undefined&&v!=="").map(([k,v])=><div key={k}><span>{label(k)}</span><b>{value(v)}</b></div>)}{Object.keys(detail.onboarding||{}).length===0&&<div className="profileNoData"><b>Nenhum dado adicional armazenado.</b><span>Os dados principais acima continuam disponíveis para análise.</span></div>}</div></section>{detail.app?.requirements?.length>0&&<section className="profileSection"><div className="profileSectionTitle"><span>03</span><div><b>Histórico de pendências</b><small>Solicitações e respostas desta candidatura</small></div></div><div className="profileHistory"><RequirementList items={detail.app.requirements}>{(r:Row)=><div key={r.id}><div><b>{r.title}</b><Badge v={r.canceledAt?"CANCELED":r.status}/></div><p>{r.description}</p>{r.response&&<RequirementAnswer value={r.response}/>}</div>}</RequirementList></div></section>}<div className="profileModalFooter"><span>PORTO PRIME · ANÁLISE ADMINISTRATIVA</span><button onClick={()=>setDetail(null)}>Concluir análise</button></div></section></div>}</>;
}

function People({rows,kind,act,ask,courierByUser,requestRequirement}:{rows:Row[],kind:string,act:any,ask:any,courierByUser:Record<string,Row>,requestRequirement:(app:Row,name:string)=>void}){
 const [selected,setSelected]=useState<Set<string>>(new Set());
 const [profileId,setProfileId]=useState<string|null>(null);
 const [courierQuery,setCourierQuery]=useState("");
 const detail=rows.find(x=>x.id===profileId);
 const detailApp=detail?(courierByUser[detail.id]||detail.courierProfile||{}):{};
 useEffect(()=>{if(!profileId)return;const close=(e:KeyboardEvent)=>{if(e.key==="Escape")setProfileId(null)};document.addEventListener("keydown",close);return()=>document.removeEventListener("keydown",close)},[profileId]);
 const visibleRows=kind==="Motoboy"?rows.filter(x=>[x.name,x.email,x.phone,courierByUser[x.id]?.document,x.courierProfile?.document].some(v=>String(v||"").toLowerCase().includes(courierQuery.trim().toLowerCase()))):rows;
 const bulkEnabled=kind==="Motoboy"||kind==="Cliente";
 useEffect(()=>{const valid=new Set(rows.map(x=>x.id));setSelected(prev=>new Set([...prev].filter(id=>valid.has(id))))},[rows]);
 const allVisible=bulkEnabled&&visibleRows.length>0&&visibleRows.every(x=>selected.has(x.id));
 const toggle=(id:string)=>setSelected(prev=>{const next=new Set(prev);next.has(id)?next.delete(id):next.add(id);return next});
 const toggleAll=()=>setSelected(prev=>{const next=new Set(prev);visibleRows.forEach(x=>allVisible?next.delete(x.id):next.add(x.id));return next});
 const selectedRows=rows.filter(x=>selected.has(x.id));
 const bulkDelete=()=>ask({
  title:"Excluir "+selectedRows.length+" "+(kind==="Motoboy"?"motoboy(s)":"cliente(s)")+"?",
  message:"Os cadastros selecionados serão removidos permanentemente da Porto Prime.",
  detail:kind==="Motoboy"?"Motoboys com entrega ativa serão preservados automaticamente. Os demais terão acesso e dados operacionais removidos.":"Clientes com histórico de pedidos serão preservados automaticamente para proteger o histórico operacional e financeiro.",
  confirm:"Excluir "+selectedRows.length+" selecionado(s)",
  action:async()=>{const result=await act("/admin/users/bulk-delete","POST",{ids:selectedRows.map(x=>x.id)});if(result)setSelected(new Set())}
 });
 if(kind==="Cliente")return <CustomerDirectory rows={rows} request={customerCardRequest} act={act} ask={ask}/>;
 return <><Panel title={kind+"s cadastrados"}>
 {kind==="Motoboy"&&<div className="orderSearchToolbar"><label className="orderNumberSearch"><Search size={18}/><input aria-label="Buscar motoboy por nome, CPF ou contato" placeholder="Buscar por nome, CPF ou contato…" value={courierQuery} onChange={e=>setCourierQuery(e.target.value)}/>{courierQuery&&<button aria-label="Limpar busca" onClick={()=>setCourierQuery("")}><X size={16}/></button>}</label><span>{visibleRows.length} motoboys encontrados</span></div>}
  {bulkEnabled&&<div className={"bulkBar "+(selected.size?"active":"")}>
   <div className="bulkSelectAll">
    <label className="checkControl"><input type="checkbox" checked={allVisible} onChange={toggleAll}/><span/></label>
    <div><b>{selected.size?selected.size+" selecionado(s)":"Seleção em massa"}</b><small>{selected.size?"Pronto para executar uma ação em lote":"Marque registros individualmente ou selecione todos os resultados visíveis"}</small></div>
   </div>
   <div className="bulkActions">
    {selected.size>0&&<button className="secondary" onClick={()=>setSelected(new Set())}>Limpar seleção</button>}
    <button className="bulkDeleteBtn" disabled={!selected.size} onClick={bulkDelete}>Excluir selecionados</button>
   </div>
  </div>}
  {kind==="Motoboy"?<div className="courierAdminGrid">{!visibleRows.length?<Empty text="Nenhum motoboy encontrado."/>:visibleRows.map(x=>{const app=courierByUser[x.id]||x.courierProfile;const unresolved=(app?.requirements||[]).filter((r:Row)=>r.status!=="RESOLVED");const isSelected=selected.has(x.id);return <article key={x.id} className={"courierAdminCard "+(isSelected?"selectedCourier":"")}><div className="courierAdminIdentity"><label className="checkControl"><input type="checkbox" aria-label={"Selecionar "+x.name} checked={isSelected} onChange={()=>toggle(x.id)}/></label><div className="courierAdminAvatar">{app?.onboardingData?.profilePhoto?<img src={app.onboardingData.profilePhoto} alt={"Foto de "+x.name}/>:((x.name||"?").slice(0,1).toUpperCase())}</div><div className="courierAdminName"><h3>{x.name}</h3><span>{app?.document||"CPF não informado"}</span></div><span className={"courierConnection "+(app?.isOnline?"online":"")}>{app?.isOnline?"Online":"Offline"}</span></div><div className="courierAdminFacts"><div><span>Contato</span><b>{x.phone||"Não informado"}</b><small>{x.email}</small></div><div><span>Veículo</span><b>{[app?.vehicleBrand,app?.vehicleModel].filter(Boolean).join(" ")||"Não informado"}</b><small>{app?.vehiclePlate||"Placa não informada"}</small></div></div><div className="courierAdminStatuses"><Badge v={app?.approvalStatus||x.status}/><Badge v={x.status}/>{unresolved.length>0&&<span className="courierPending">{unresolved.length} pendência(s)</span>}</div><div className="courierAdminPrimary"><button onClick={()=>setProfileId(x.id)}><Users size={16}/> Abrir perfil completo</button>{app&&<button className="secondary" onClick={()=>requestRequirement(app,x.name)}><ClipboardList size={16}/> Solicitar pendência</button>}</div><details className="courierAccess"><summary>Gerenciar acesso<ChevronDown size={16}/></summary><div className="actions">{x.status!=="ACTIVE"&&<button onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"ACTIVE"})}><Check size={15}/> Aprovar e ativar acesso</button>}{x.status==="ACTIVE"&&<button className="warn" onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"SUSPENDED"})}><CircleAlert size={15}/> Suspender acesso</button>}{x.status!=="BLOCKED"&&<button className="danger" onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"BLOCKED"})}><CircleAlert size={15}/> Bloquear acesso</button>}{bulkEnabled&&<button className="danger ghostDanger" onClick={()=>ask({title:"Excluir "+kind.toLowerCase()+" permanentemente?",message:"Você está prestes a remover "+x.name+" da Porto Prime.",detail:kind==="Motoboy"?"O cadastro, acesso e dados vinculados serão removidos. Motoboys com entrega ativa não podem ser excluídos.":"Clientes com histórico de pedidos são preservados para manter a integridade operacional e financeira.",confirm:"Sim, excluir "+kind.toLowerCase(),action:()=>act("/admin/users/"+x.id,"DELETE")})}><Trash2 size={15}/> Excluir cadastro</button>}</div></details></article>})}</div>:(!rows.length?<Empty text={"Nenhum "+kind.toLowerCase()+" encontrado."}/>:<div className="tableWrap bulkTable"><table><thead><tr>{bulkEnabled&&<th className="selectCol"><label className="checkControl"><input aria-label="Selecionar todos" type="checkbox" checked={allVisible} onChange={toggleAll}/><span/></label></th>}<th>Usuário</th><th>Contato</th><th>Status</th><th>{kind==="Motoboy"?"Operação":"Atividade"}</th><th>Ações</th></tr></thead><tbody>{rows.map(x=>{const app=kind==="Motoboy"?courierByUser[x.id]:null;const unresolved=(app?.requirements||[]).filter((r:Row)=>r.status!=="RESOLVED");const isSelected=selected.has(x.id);return <tr key={x.id} className={isSelected?"selectedRow":""}>{bulkEnabled&&<td className="selectCol"><label className="checkControl"><input aria-label={"Selecionar "+x.name} type="checkbox" checked={isSelected} onChange={()=>toggle(x.id)}/><span/></label></td>}<td><b>{x.name}</b><small>{dt(x.createdAt)}</small>{app&&<small>CPF {app.document||"—"} · {app.vehicleModel||"Moto não informada"}</small>}</td><td>{x.email}<small>{x.phone||"—"}</small></td><td><Badge v={app?.approvalStatus||x.status}/>{unresolved.length>0&&<small>{unresolved.length} pendência(s)</small>}</td><td>{kind==="Motoboy"?(x.courierProfile?.isOnline?"Online":"Offline"):(kind==="Cliente"?((x._count?.orders||0)+" pedidos"):(x.partnerProfile?.businessName||"—"))}</td><td><div className="actions">{kind==="Motoboy"&&app&&<button className="secondary" onClick={()=>requestRequirement(app,x.name)}>Solicitar pendência</button>}{x.status!=="ACTIVE"&&<button onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"ACTIVE"})}>Ativar</button>}{x.status==="ACTIVE"&&<button className="warn" onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"SUSPENDED"})}>Suspender</button>}{x.status!=="BLOCKED"&&<button className="danger" onClick={()=>act("/admin/users/"+x.id+"/status","PATCH",{status:"BLOCKED"})}>Bloquear</button>}{bulkEnabled&&<button className="danger ghostDanger" onClick={()=>ask({title:"Excluir "+kind.toLowerCase()+" permanentemente?",message:"Você está prestes a remover "+x.name+" da Porto Prime.",detail:kind==="Motoboy"?"O cadastro, acesso e dados vinculados serão removidos. Motoboys com entrega ativa não podem ser excluídos.":"Clientes com histórico de pedidos são preservados para manter a integridade operacional e financeira.",confirm:"Sim, excluir "+kind.toLowerCase(),action:()=>act("/admin/users/"+x.id,"DELETE")})}>Excluir</button>}</div></td></tr>})}</tbody></table></div>)}
 </Panel>{detail&&kind==="Motoboy"&&<CourierAdminProfile user={detail} app={detailApp} close={()=>setProfileId(null)} act={act} requestRequirement={requestRequirement}/>}</>
}

function CustomerAdminProfile({user,close,act,ask}:{user:Row,close:()=>void,act:any,ask:any}){
 return <CustomerProfileWorkspace user={user} close={close} act={act} ask={ask} request={customerCardRequest}/>;
}

function CancelRequirement({requirement,act}:{requirement:Row;act:(...args:any[])=>Promise<any>}) {
 const [open,setOpen]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState("");
 if(requirement.canceledAt)return <small className="requirementCanceled">Cancelada em {dt(requirement.canceledAt)} · histórico preservado</small>;
 return <><button className="secondary" onClick={()=>{setError("");setOpen(true)}}><X size={14}/> Cancelar solicitação</button>{open&&<div className="modalBackdrop" onMouseDown={()=>!busy&&setOpen(false)}><section className="requirementCancelDialog" role="dialog" aria-modal="true" aria-labelledby={"cancel-"+requirement.id} onMouseDown={e=>e.stopPropagation()}><small>REVISÃO ADMINISTRATIVA</small><h3 id={"cancel-"+requirement.id}>Cancelar esta pendência?</h3><b>{requirement.title}</b><p>A solicitação deixa de bloquear a aprovação e desaparece das pendências do motoboy. O histórico e a resposta ficam preservados.</p>{error&&<p role="alert" className="error">{error}</p>}<div className="actions"><button autoFocus disabled={busy} className="secondary" onClick={()=>setOpen(false)}>Manter solicitação</button><button disabled={busy} onClick={async()=>{setBusy(true);try{const result=await act("/admin/requirements/"+requirement.id+"/cancel","PATCH");if(!result)throw new Error("Não foi possível cancelar. Tente novamente.");setOpen(false)}catch(e){setError(displayMessage(e))}finally{setBusy(false)}}}>{busy?"Cancelando…":"Cancelar pendência"}</button></div></section></div>}</>;
}

function CourierAdminProfile({user,app,close,act,requestRequirement,embedded=false,onSupport}:{user:Row,app:Row,close:()=>void,act:any,requestRequirement:(app:Row,name:string)=>void,embedded?:boolean,onSupport?:()=>void}){
 const [finance,setFinance]=useState<Row|null>(null),[financeError,setFinanceError]=useState("");
 useEffect(()=>{let active=true;const refresh=async()=>{try{const r=await api("/admin/couriers/"+app.id+"/finance");if(active){setFinance(r);setFinanceError("")}}catch(e:any){if(active)setFinanceError(e.message)}};refresh();const timer=setInterval(refresh,10000);return()=>{active=false;clearInterval(timer)}},[app.id]);
 const onboarding=app.onboardingData||user.courierProfile?.onboardingData||{};
 const labels:Record<string,string>={name:"Nome",birthDate:"Data de nascimento",cpf:"CPF",cpfSituation:"Situação do CPF",document:"Documento",cnh:"Número da CNH",cnhCategory:"Categoria CNH",cnhExpiry:"Validade da CNH",vehicleType:"Tipo de veículo",vehicleBrand:"Marca",vehicleModel:"Modelo",vehicleYear:"Ano",vehiclePlate:"Placa",pixKey:"Chave PIX",pixKeyType:"Tipo de chave PIX",cep:"CEP",postalCode:"CEP",street:"Rua",number:"Número",complement:"Complemento",neighborhood:"Bairro",city:"Cidade",state:"Estado",phone:"Telefone",email:"E-mail",hasMotorcycle:"Possui moto"};
 const format=(v:any):string=>v===null||v===undefined||v===""?"Não informado":typeof v==="boolean"?(v?"Sim":"Não"):Array.isArray(v)?v.map(format).join(" · "):typeof v==="object"?Object.entries(v).map(([k,x])=>(labels[k]||k)+": "+format(x)).join("; "):String(v);
 const data={...onboarding,...Object.fromEntries(Object.entries(app).filter(([k,v])=>["document","cnh","cnhCategory","vehicleBrand","vehicleModel","vehicleYear","vehiclePlate","pixKey","pixKeyType"].includes(k)&&v!==null&&v!==undefined&&v!=="")),name:user.name,email:user.email,phone:user.phone};
 return <CourierReviewWorkspace embedded={embedded} user={user} app={app} close={close} request={()=>requestRequirement(app,user.name)} resolve={id=>act("/admin/requirements/"+id+"/resolve","PATCH")} approve={()=>act("/admin/users/"+user.id+"/approve","PATCH")} requestRevision={(id,title,description)=>act("/admin/requirements/"+id+"/request-revision","PATCH",{title,description})} cancel={r=><CancelRequirement requirement={r} act={act}/>} onSupport={onSupport}><CourierRecordEditor data={data} onSave={async changes=>{await api("/admin/couriers/"+app.id+"/profile","","PATCH",changes);await act("/admin/couriers/"+app.id+"/finance","GET")}}/><details className="courierRecordAux"><summary>Ganhos e histórico de saques<ChevronDown size={18}/></summary><section className="profileSection courierFinancial"><div className="profileSectionTitle"><span><Wallet size={16}/></span><div><b>Ganhos e saques</b><small>Valores registrados na carteira deste motoboy</small></div></div>{financeError&&<p className="error">{financeError}</p>}{!finance&&!financeError&&<div className="financeSkeleton" aria-label="Carregando resumo financeiro"/>}{finance&&<><div className="courierFinanceGrid"><div><span>Ganhos com entregas</span><b>{brl(finance.earningsTotal)}</b><small>{finance.deliveries} entregas concluídas</small></div><div><span>Saldo disponível</span><b>{brl(finance.availableBalance)}</b><small>{brl(finance.pendingWithdrawalTotal)} em saques pendentes</small></div><div><span>Saques pagos</span><b>{brl(finance.paidWithdrawalTotal)}</b><small>{finance.paidWithdrawalCount} saques realizados</small></div></div><h4>Histórico de solicitações</h4><div className="courierWithdrawalList">{finance.withdrawals.map((w:Row)=><article key={w.id}><div><b>{brl(w.amount)}</b><small>{dt(w.requestedAt)}</small><span>{w.pixKeyType} · {w.pixKey}</span>{w.processedAt&&<small>Processado em {dt(w.processedAt)}</small>}</div><Badge v={w.status}/></article>)}{!finance.withdrawals.length&&<p className="courierProfileEmpty">Nenhum saque solicitado.</p>}</div></>}</section></details><section className="profileSection courierProfileAccess"><div className="profileSectionTitle"><span><UserCheck size={16}/></span><div><b>Gerenciar acesso</b><small>Status atual: {statusLabel[user.status]||user.status}</small></div></div><div className="actions">{user.status!=="ACTIVE"&&<button onClick={()=>act("/admin/users/"+user.id+"/status","PATCH",{status:"ACTIVE"})}><Check size={16}/> Aprovar e ativar acesso</button>}{user.status==="ACTIVE"&&<button className="warn" onClick={()=>act("/admin/users/"+user.id+"/status","PATCH",{status:"SUSPENDED"})}><CircleAlert size={16}/> Suspender acesso</button>}{user.status!=="BLOCKED"&&<button className="danger" onClick={()=>act("/admin/users/"+user.id+"/status","PATCH",{status:"BLOCKED"})}><CircleAlert size={16}/> Bloquear acesso</button>}</div></section></CourierReviewWorkspace>;
}


function Orders({rows,act,ask,token,products}:{rows:Row[],act:any,ask:any,token:string,products:Row[]}){
 const [viewId,setViewId]=useState<string|null>(null);
 const [orderFilter,setOrderFilter]=useState("ALL");
 const [dateScope,setDateScope]=useState("ALL");
 const [paymentScope,setPaymentScope]=useState("ALL");
 const [expandedFilters,setExpandedFilters]=useState(false);
 const [sortBy,setSortBy]=useState("RECENT");
 const [audit,setAudit]=useState<{order:Row;events:Row[]}|null>(null);
 const [auditBusy,setAuditBusy]=useState(false),[auditError,setAuditError]=useState("");
 const [selected,setSelected]=useState<Set<string>>(new Set());
 const [orderQuery,setOrderQuery]=useState("");
 const [visibleLimit,setVisibleLimit]=useState(20);
 const [supportsSerial,setSupportsSerial]=useState(false);
 useEffect(()=>{setSupportsSerial(thermalSupported())},[]);
 const [thermalPaper,setThermalPaper]=useState<58|80>(80);
 const [thermalBaud,setThermalBaud]=useState<9600|19200|115200>(9600);
 const [thermalBusy,setThermalBusy]=useState(false);
 const [thermalSelected,setThermalSelected]=useState(false);
 const [thermalMessage,setThermalMessage]=useState("");
 const [thermalError,setThermalError]=useState("");
 const printSlips=async(requested:Row[])=>{
  const printable=requested.filter(canPrintCourierSlip);
  if(!printable.length||thermalBusy)return;
  setThermalBusy(true);setThermalError("");setThermalMessage("");
  try{
   await printThermalOrders(printable,thermalPaper,thermalBaud);
   setThermalSelected(true);
   setThermalMessage(printable.length===1?"Comanda enviada para a impressora térmica.":"Comandas enviadas para a impressora térmica.");
  }catch(e){setThermalError(e instanceof Error?e.message:"Não foi possível conectar à impressora térmica.");}
  finally{setThermalBusy(false);}
 };
 const connectThermal=async()=>{
  setThermalError("");setThermalMessage("");
  try{await selectThermalPrinter();setThermalSelected(true);setThermalMessage("Impressora térmica selecionada. A comanda pode ser enviada agora.");}
  catch(e){setThermalError(e instanceof Error?e.message:"Não foi possível selecionar a impressora térmica.");}
 };
 const normalizedQuery=orderQuery.trim().replace(/^#/,"").toLowerCase();
 const matchesStatus=(o:Row,filter:string)=>filter==="ALL"||
  (filter==="REVIEW"&&["CONFIRMED","PREPARING","READY_FOR_PICKUP"].includes(o.status))||
  (filter==="DISPATCH"&&o.status==="SEARCHING_COURIER")||
  (filter==="DELIVERY"&&["COURIER_ASSIGNED","PICKED_UP","OUT_FOR_DELIVERY"].includes(o.status))||
  (filter==="HOLD"&&Boolean(o.fulfillmentHold))||
  (filter==="DELIVERED"&&o.status==="DELIVERED")||
  (filter==="CANCELED"&&o.status==="CANCELED");
 const now=new Date();
 const inDateScope=(o:Row)=>{
  if(dateScope==="ALL")return true;
  const created=new Date(o.createdAt);
  if(Number.isNaN(created.getTime()))return false;
  if(dateScope==="TODAY")return created.toDateString()===now.toDateString();
  return created.getTime()>=now.getTime()-(dateScope==="WEEK"?7:30)*86400000;
 };
 const dateRows=rows.filter(inDateScope);
 const filteredRows=dateRows.filter(o=>matchesStatus(o,orderFilter)&&
  (paymentScope==="ALL"||(paymentScope==="PAID"?o.paymentStatus==="PAID":o.paymentStatus!=="PAID"))&&
  [o.id,orderDisplayNumber(o),o.customer?.name,o.customer?.phone].some(v=>String(v||"").toLowerCase().includes(normalizedQuery)))
  .sort((a,b)=>{
   if(sortBy==="VALUE")return Number(b.total||0)-Number(a.total||0);
   const timeA=Date.parse(String(a.createdAt||""))||0,timeB=Date.parse(String(b.createdAt||""))||0;
   return sortBy==="OLDEST"?timeA-timeB:timeB-timeA;
  });
 const visibleRows=filteredRows.slice(0,visibleLimit);
 const allVisible=visibleRows.length>0&&visibleRows.every(x=>selected.has(x.id));
 const toggle=(id:string)=>setSelected(prev=>{const next=new Set(prev);next.has(id)?next.delete(id):next.size<100&&next.add(id);return next});
 const toggleAll=()=>setSelected(prev=>{const next=new Set(prev);visibleRows.forEach(x=>allVisible?next.delete(x.id):next.size<100&&next.add(x.id));return next});
 const selectedRows=rows.filter(x=>selected.has(x.id));
 const bulkDelete=()=>ask({
  title:"Excluir "+selectedRows.length+" pedido(s)?",
  message:"Os pedidos selecionados serão excluídos da visualização do painel.",
  detail:"Remove o pedido do painel e da área do cliente, interrompendo seu despacho. Preserva os registros financeiros e não solicita estorno.",
  confirm:"Excluir "+selectedRows.length+" pedido(s)",
  action:async()=>{const result=await act("/admin/orders/bulk-delete","POST",{ids:selectedRows.map(x=>x.id)});if(result)setSelected(new Set())}
 });
 const openAudit=async(o:Row)=>{setAuditBusy(true);setAuditError("");try{const events=await api("/admin/orders/"+o.id+"/audit",token);setAudit({order:o,events})}catch(e:any){setAuditError(displayMessage(e.message))}finally{setAuditBusy(false)}};
 const activeView=rows.find(o=>o.id===viewId);
 const deleteOrder=(o:Row)=>{setViewId(null);ask({title:"Excluir este pedido?",message:"O pedido #"+orderDisplayNumber(o)+" será removido do Admin e da área do cliente.",detail:"A operação será interrompida. Os registros financeiros são preservados; esta ação não solicita estorno.",confirm:"Excluir pedido",action:()=>act("/admin/orders/"+o.id,"DELETE")})};
 const newestPrintable=rows.find(canPrintCourierSlip);
 const filters=[["ALL","Todos"],["REVIEW","Conferência"],["DISPATCH","Buscando motoboy"],["DELIVERY","Em entrega"],["HOLD","Aguardando cliente"],["DELIVERED","Entregues"],["CANCELED","Cancelados"]];
 const highlights=[
  {key:"ALL",name:"Todos os pedidos",description:"Ver todos os pedidos",Icon:Package},
  {key:"REVIEW",name:"Conferência",description:"Aguardando conferência",Icon:FileCheck2},
  {key:"DISPATCH",name:"Buscando motoboy",description:"Procurando entregador",Icon:Bike},
  {key:"DELIVERY",name:"Em entrega",description:"A caminho do cliente",Icon:Truck},
  {key:"HOLD",name:"Aguardando cliente",description:"Aguardando confirmação",Icon:UserRound},
 ];
 const initials=(name:string)=>name.trim().split(/\s+/).filter(Boolean).slice(0,2).map(part=>part[0].toUpperCase()).join("")||"PP";
 const shortDate=(input:any)=>{
  const date=new Date(input);
  return Number.isNaN(date.getTime())?"—":date.toLocaleString("pt-BR",{day:"2-digit",month:"2-digit",hour:"2-digit",minute:"2-digit"});
 };
 const orderUnits=(o:Row)=>(o.items||[]).reduce((n:number,item:Row)=>n+Number(item.quantity||0),0);
 return <>
  <div className="orderOperationsV5 ppOrders2026">
   <section className="poCanvas" aria-label="Central de pedidos">
    <div className="poHero">
     <div className="poHeroIdentity"><div className="poHeroIcon"><Package size={29} strokeWidth={1.8}/></div><div><h2>Central de pedidos</h2><p>Acompanhe os pagamentos, confira produtos e libere o despacho em poucos cliques.</p></div></div>
     <div className="poRealtime"><span><i/>Dados em tempo real</span><small>Sincronização automática do painel</small></div>
    </div>
    {auditError&&<div className="error" role="alert">{auditError}</div>}
    <div className="poThermalControl">
      <div><Printer size={19}/><span><strong>Impressora térmica ESC/POS</strong><small>{thermalSelected?"Impressora selecionada":"USB serial ou Bluetooth SPP, porta COM."}</small></span></div>
      <label>Bobina <select value={thermalPaper} onChange={e=>setThermalPaper(Number(e.target.value)===58?58:80)} aria-label="Largura da bobina térmica"><option value={80}>80 mm</option><option value={58}>58 mm</option></select></label>
      <label>Porta COM <select value={thermalBaud} onChange={e=>{const value=Number(e.target.value);setThermalBaud(value===115200?115200:value===19200?19200:9600);}} aria-label="Velocidade da impressora térmica"><option value={9600}>9600</option><option value={19200}>19200</option><option value={115200}>115200</option></select></label>
      <button type="button" onClick={()=>void connectThermal()} disabled={thermalBusy||!supportsSerial}>Conectar térmica</button>
    </div>
    {thermalError&&<div className="poThermalError" role="alert">{thermalError}</div>}
    {thermalMessage&&!thermalError&&<div className="poThermalSuccess" role="status">{thermalMessage}</div>}
    {!supportsSerial&&<div className="poThermalError" role="status">Impressão ESC/POS disponível no Chrome/Edge via localhost ou HTTPS. Impressoras comuns não são selecionadas.</div>
    {newestPrintable&&<div className="poSlipReady" role="status">
      <span className="poSlipIcon"><Printer size={21}/></span>
      <div><strong>Comanda pronta para impressão</strong><small>Pedido #{orderDisplayNumber(newestPrintable)} · Confira e entregue ao motoboy.</small></div>
      <button type="button" disabled={thermalBusy} onClick={()=>void printSlips([newestPrintable])}><Printer size={16}/> Imprimir na térmica</button>
    </div>}
    <div className="poMetrics" aria-label="Visão geral dos pedidos">
     {highlights.map(({key,name,description,Icon},index)=><button key={key} type="button" className={"poMetric poMetric"+index+(orderFilter===key?" isActive":"")} aria-pressed={orderFilter===key} onClick={()=>{setOrderFilter(key);setVisibleLimit(20)}}>
      <span className="poMetricIcon"><Icon size={23} strokeWidth={1.9}/></span>
      <span className="poMetricContent"><span className="poMetricName">{name}</span><strong>{dateRows.filter(o=>matchesStatus(o,key)).length}</strong><span className="poMetricDescription">{orderFilter===key?"Visualizando esta etapa":description}</span></span>
     </button>)}
    </div>
    <div className="poToolbar">
     <label className="poSearch"><Search size={19}/><input aria-label="Buscar pedido, cliente ou telefone" placeholder="Buscar pedido, cliente, telefone ou código…" value={orderQuery} onChange={e=>{setOrderQuery(e.target.value);setVisibleLimit(20)}}/>{orderQuery&&<button type="button" aria-label="Limpar busca" onClick={()=>{setOrderQuery("");setVisibleLimit(20)}}><X size={16}/></button>}</label>
     <label className="poToolbarSelect poDate"><CalendarDays size={17}/><select aria-label="Filtrar por período" value={dateScope} onChange={e=>{setDateScope(e.target.value);setVisibleLimit(20)}}><option value="ALL">Todas as datas</option><option value="TODAY">Hoje</option><option value="WEEK">Últimos 7 dias</option><option value="MONTH">Últimos 30 dias</option></select></label>
     <label className="poToolbarSelect poSorting"><span className="poSortSymbol">↕</span><select aria-label="Ordenar pedidos" value={sortBy} onChange={e=>{setSortBy(e.target.value);setVisibleLimit(20)}}><option value="RECENT">Mais recentes</option><option value="OLDEST">Mais antigos</option><option value="VALUE">Maior valor</option></select></label>
     <button className={"poFilterToggle"+(expandedFilters?" isActive":"")} type="button" aria-expanded={expandedFilters} aria-controls="po-advanced-filters" onClick={()=>setExpandedFilters(open=>!open)}><SlidersHorizontal size={17}/>Filtros</button>
    </div>
    {expandedFilters&&<div className="poAdvanced" id="po-advanced-filters"><label><span>Situação do pagamento</span><select value={paymentScope} onChange={e=>{setPaymentScope(e.target.value);setVisibleLimit(20)}} aria-label="Filtrar situação do pagamento"><option value="ALL">Todos os pagamentos</option><option value="PAID">Pagamentos aprovados</option><option value="PENDING">Outras situações</option></select></label><button type="button" onClick={()=>{setOrderQuery("");setOrderFilter("ALL");setDateScope("ALL");setSortBy("RECENT");setPaymentScope("ALL");setVisibleLimit(20)}}>Limpar filtros</button></div>}
    <div className="poFilterLine"><div className="poPills" aria-label="Filtrar etapa operacional">{filters.map(([value,label])=><button type="button" key={value} aria-pressed={orderFilter===value} onClick={()=>{setOrderFilter(value);setVisibleLimit(20)}}>{label}</button>)}</div><span className="poResults" role="status">{filteredRows.length} {filteredRows.length===1?"pedido encontrado":"pedidos encontrados"}</span></div>
    <div className={"poBulk"+(selected.size?" isSelected":"")}>
     <label className="poBulkSelect"><span className="checkControl"><input aria-label="Selecionar todos os pedidos exibidos" type="checkbox" checked={allVisible} onChange={toggleAll}/><span/></span><span>{selected.size} {selected.size===1?"pedido selecionado":"pedidos selecionados"}</span></label>
     <div className="poBulkActions">{selected.size>0&&<button className="poClearSelection" type="button" onClick={()=>setSelected(new Set())}>Limpar seleção</button>}<button className="poDelete" type="button" disabled={!selected.size} onClick={bulkDelete}><Trash2 size={15}/>Excluir selecionados</button><button className="poPrint" type="button" disabled={thermalBusy||!selectedRows.some(canPrintCourierSlip)} onClick={()=>void printSlips(selectedRows)}><Printer size={17}/>Imprimir selecionadas</button></div>
    </div>
    <div className="poTableScroll" role="region" aria-label="Lista de pedidos" tabIndex={0}>
     <div className="poTable">
      <div className="poTableHead" aria-hidden="true"><span></span><span>Pedido</span><span>Cliente</span><span>Itens</span><span>Pagamento</span><span>Status</span><span>Motoboy</span><span>Horário</span><span>Ações</span></div>
      {visibleRows.map(o=>{
       const customerName=String(o.customer?.name||"Cliente");
       const courierName=String(o.courier?.user?.name||o.courier?.name||"");
       const orderId=orderDisplayNumber(o);
       const paid=o.paymentStatus==="PAID";
       return <article className={"poRow"+(selected.has(o.id)?" isSelected":"")+(viewId===o.id?" isViewing":"")} key={o.id}>
        <label className="checkControl poRowCheck"><input type="checkbox" aria-label={"Selecionar pedido "+orderId} checked={selected.has(o.id)} disabled={selected.size>=100&&!selected.has(o.id)} onChange={()=>toggle(o.id)}/><span/></label>
        <div className="poOrder"><button type="button" onClick={()=>setViewId(o.id)} aria-label={"Abrir pedido "+orderId}>#{orderId}</button><small>{o.createdAt?new Date(o.createdAt).toLocaleDateString("pt-BR"):"—"}</small></div>
        <div className="poPerson"><span className="poAvatar">{initials(customerName)}</span><span><strong title={customerName}>{customerName}</strong><small>{o.customer?.phone||"Telefone não informado"}</small></span></div>
        <div className="poProducts"><div><strong>{orderUnits(o)} {orderUnits(o)===1?"item":"itens"}</strong>{o.subtotal!=null&&<small>{brl(o.subtotal)}</small>}</div><div className="poProductIcons" aria-hidden="true">{(o.items||[]).slice(0,3).map((item:Row,index:number)=><span key={item.id||index} title={String(item.product?.name||item.name||"Produto")}><ShoppingBag size={13}/></span>)}</div></div>
        <div className="poPayment"><span className={"poPaymentBadge"+(paid?" isPaid":o.paymentStatus==="REFUNDED"?" isRefunded":" isPending")}><CreditCard size={14}/>{paid?"Pago online":o.paymentStatus==="REFUNDED"?"Reembolsado":o.paymentStatus==="PARTIALLY_REFUNDED"?"Reembolso parcial":"Pendente"}</span><small>{paid?"Pagamento confirmado":"Verificar pagamento"}</small></div>
        <div className="poStatus"><Badge v={o.status}/><small>{o.fulfillmentHold?"Aguardando confirmação do cliente":o.status==="SEARCHING_COURIER"?"Procurando na região":o.status==="CONFIRMED"?"Conferir produtos":o.status==="DELIVERED"?"Entrega concluída":"Acompanhamento da operação"}</small></div>
        <div className="poCourier">{courierName?<><span className="poAvatar poCourierAvatar">{initials(courierName)}</span><span><strong title={courierName}>{courierName}</strong><small>Motoboy atribuído</small></span></>:<span className="poCourierEmpty"><strong>—</strong><small>{o.status==="SEARCHING_COURIER"?"Buscando…":"Aguardando"}</small></span>}</div>
        <div className="poTime"><strong>{shortDate(o.createdAt)}</strong><small>{brl(o.total)}</small></div>
        <div className="poActionGroup">
          <button type="button" className="poPrintSingle" disabled={thermalBusy||!canPrintCourierSlip(o)} title={"Imprimir comanda do pedido #"+orderId} aria-label={"Imprimir comanda do pedido "+orderId} onClick={()=>void printSlips([o])}><Printer size={16}/></button>
          <button type="button" className="poOpen" onClick={()=>setViewId(o.id)} aria-label={"Ver detalhes do pedido "+orderId}>Ver detalhes<ChevronRight size={15}/></button>
         </div>
       </article>;
      })}
      {!filteredRows.length&&<div className="poEmpty" role="status"><div className="poEmptyIcon"><PackageSearch size={27}/></div><h3>{normalizedQuery||orderFilter!=="ALL"||dateScope!=="ALL"||paymentScope!=="ALL"?"Nenhum pedido para estes filtros":"Tudo pronto para receber pedidos"}</h3><p>{normalizedQuery||orderFilter!=="ALL"||dateScope!=="ALL"||paymentScope!=="ALL"?"Experimente alterar a busca, a data ou a situação selecionada.":"Os pedidos aparecerão aqui automaticamente assim que forem registrados."}</p>{(normalizedQuery||orderFilter!=="ALL"||dateScope!=="ALL"||paymentScope!=="ALL")&&<button type="button" onClick={()=>{setOrderQuery("");setOrderFilter("ALL");setDateScope("ALL");setPaymentScope("ALL");setVisibleLimit(20)}}>Mostrar todos os pedidos</button>}</div>}
     </div>
    </div>
    {visibleRows.length<filteredRows.length&&<div className="poLoadMore"><span>Exibindo {visibleRows.length} de {filteredRows.length}</span><button type="button" onClick={()=>setVisibleLimit(n=>n+20)}>Mostrar mais 20 pedidos<ChevronDown size={16}/></button></div>}
   </section>
  </div>
  {activeView&&<OrderOperationWorkspace key={activeView.id} order={activeView} products={products} request={(path,method,body)=>api(path,token,method,body)} reload={()=>{void act("/admin/orders","GET")}} onStatus={status=>{void act("/admin/orders/"+activeView.id+"/status","PATCH",{status})}} onRelease={()=>{void act("/admin/orders/"+activeView.id+"/release")}} onAudit={()=>{setViewId(null);void openAudit(activeView)}} onPrint={()=>void printSlips([activeView])} onDelete={()=>deleteOrder(activeView)} close={()=>setViewId(null)} auditBusy={auditBusy}/>}
  {audit&&<div className="modalBackdrop profileBackdrop" onMouseDown={()=>setAudit(null)}><section className="profileModal auditModal" onMouseDown={e=>e.stopPropagation()}><div className="profileModalHero"><button className="profileClose" aria-label="Fechar" onClick={()=>setAudit(null)}><X size={18}/></button><div className="profileModalAvatar">#</div><div><small>HISTÓRICO DA ENTREGA</small><h2>Pedido #{orderDisplayNumber(audit.order)}</h2><p>Acompanhe cada etapa, da liberação à conclusão.</p></div><Badge v={audit.order.status}/></div><div className="profileSection"><div className="profileHistory">{audit.events.length?audit.events.map((e:Row)=><div key={e.id}><div><b>{dispatchEventLabel(e.type)}</b><span>{dt(e.createdAt)}</span></div>{e.courierId&&<p>Motoboy: {e.courierId}</p>}{e.offerId&&<p>Oferta: {e.offerId}</p>}{e.payload&&<strong>{JSON.stringify(e.payload)}</strong>}</div>):<div className="none">Nenhum evento registrado para este pedido.</div>}</div></div><div className="profileModalFooter"><span>PORTO PRIME · ACOMPANHAMENTO</span><button onClick={()=>setAudit(null)}>Fechar</button></div></section></div>}
 </>;
}

const dispatchEventLabel=(v:string)=>({ADMIN_RELEASED:"Admin liberou o pedido",SEARCH_STARTED:"Busca por motoboy iniciada",OFFER_CREATED:"Oferta enviada",OFFER_DECLINED:"Oferta recusada",OFFER_EXPIRED:"Oferta expirada",OFFER_CANCELED:"Oferta cancelada",OFFER_ACCEPTED:"Motoboy aceitou",COURIER_PICKED_UP:"Pedido coletado",OUT_FOR_DELIVERY:"Saiu para entrega",DELIVERED:"Entrega concluída",WALLET_CREDITED:"Carteira creditada"} as Record<string,string>)[v]||v;


function Settings({pricing,act}:{me:Row,dash:Row,pricing:Row,act:any}){return <DeliverySettings pricing={pricing} act={act}/>}
function Empty({text}:{text:string}){return <div className="none" role="status"><div className="emptyIcon"><PackageSearch size={26} aria-hidden="true"/></div><strong>Tudo organizado por aqui</strong><p>{text}</p></div>}


