"use client";
import {useEffect,useRef} from "react";
import {X,Package,MapPin,UserRound,Bike,CreditCard,History,Trash2,Check,ArrowRight,ShieldCheck,Clock,ChevronDown,Phone,ReceiptText,Navigation} from "lucide-react";
import OrderAvailabilityEditor from "./order-availability-editor";
import "./order-operation-workspace.css";

type Row=Record<string,any>;
const money=(value:any)=>Number(value||0).toLocaleString("pt-BR",{style:"currency",currency:"BRL"});
const date=(value:any)=>value?new Date(value).toLocaleString("pt-BR",{dateStyle:"short",timeStyle:"short"}):"—";
const labels:Record<string,string>={
 PENDING:"Pendente",CONFIRMED:"Recebido",PREPARING:"Preparando",
 READY_FOR_PICKUP:"Pronto para retirada",SEARCHING_COURIER:"Buscando motoboy",
 COURIER_ASSIGNED:"Motoboy a caminho",PICKED_UP:"Coletado",
 OUT_FOR_DELIVERY:"Saiu para entrega",DELIVERED:"Entregue",CANCELED:"Cancelado",
 PAID:"Pagamento aprovado",PARTIALLY_REFUNDED:"Reembolso parcial",
 REFUNDED:"Reembolsado",FAILED:"Falha no pagamento"
};
const statuses=["PENDING","CONFIRMED","PREPARING","READY_FOR_PICKUP","CANCELED"];

export default function OrderOperationWorkspace({order,products,request,reload,onStatus,onRelease,onAudit,onDelete,close,auditBusy}:{
 order:Row;products:Row[];
 request:(path:string,method:string,body?:any)=>Promise<any>;
 reload:()=>void;onStatus:(status:string)=>void;onRelease:()=>void;
 onAudit:()=>void;onDelete:()=>void;close:()=>void;auditBusy:boolean;
}){
 const panel=useRef<HTMLElement>(null),scrollArea=useRef<HTMLDivElement>(null),closeRef=useRef(close);
 closeRef.current=close;

 useEffect(()=>{
  const previous=document.activeElement as HTMLElement|null,overflow=document.body.style.overflow;
  document.body.style.overflow="hidden";
  panel.current?.querySelector<HTMLButtonElement>(".owClose")?.focus();
  const key=(event:KeyboardEvent)=>{
   if(document.querySelector(".availabilityModalBackdrop"))return;
   if(event.key==="Escape"){event.preventDefault();closeRef.current();}
   if(event.key==="Tab"){
    const nodes=Array.from(panel.current?.querySelectorAll<HTMLElement>(
     'button:not(:disabled),a[href],input:not(:disabled),select:not(:disabled),textarea:not(:disabled),summary,[tabindex="0"]'
    )||[]).filter(node=>node.getClientRects().length);
    const first=nodes[0],last=nodes.at(-1);
    if(event.shiftKey&&document.activeElement===first){event.preventDefault();last?.focus();}
    else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first?.focus();}
   }
  };
  document.addEventListener("keydown",key);
  return ()=>{document.body.style.overflow=overflow;document.removeEventListener("keydown",key);previous?.focus();};
 },[]);

 const ready=order.paymentStatus==="PAID"&&["CONFIRMED","PREPARING","READY_FOR_PICKUP"].includes(order.status);
 const stages=["CONFIRMED","PREPARING","SEARCHING_COURIER","COURIER_ASSIGNED","OUT_FOR_DELIVERY"];
 const step=order.status==="DELIVERED"?stages.length:order.status==="READY_FOR_PICKUP"?1:order.status==="PICKED_UP"?3:stages.indexOf(order.status);
 const address=order.address||{};
 const units=(order.items||[]).reduce((total:number,item:Row)=>total+Number(item.quantity||0),0);
 const itemCount=order.items?.length||0;
 const actionHint=order.fulfillmentHold?"Aguarde a decisão do cliente sobre os itens indisponíveis.":ready?
  "Confira os produtos e libere para iniciar a busca automática.":order.status==="SEARCHING_COURIER"?
  "Despacho automático ativo. A oferta passa aos motoboys disponíveis.":order.courierId?
  "Acompanhe a entrega. As próximas etapas são feitas pelo motoboy.":"Consulte os detalhes e o histórico deste pedido.";
 const scrollTo=(id:string)=>{
  const target=panel.current?.querySelector<HTMLElement>("#"+id);
  const area=scrollArea.current;
  if(!target||!area)return;
  const top=target.getBoundingClientRect().top-area.getBoundingClientRect().top+area.scrollTop-14;
  area.scrollTo({top,behavior:window.matchMedia("(prefers-reduced-motion: reduce)").matches?"auto":"smooth"});
 };

 return <div className="orderWorkspaceBackdropV5" onMouseDown={event=>{if(event.target===event.currentTarget)close()}}>
  <section className="orderWorkspaceV5" ref={panel} role="dialog" aria-modal="true" aria-labelledby="order-workspace-title">
   <header className="owHeader">
    <div className="owMark"><Package size={24}/></div>
    <div className="owTitle">
     <span>PORTO PRIME · GESTÃO DO PEDIDO</span>
     <h2 id="order-workspace-title">Pedido #{String(order.id).slice(-8).toUpperCase()}</h2>
     <p>{date(order.createdAt)} · {order.customer?.name||"Cliente"}</p>
    </div>
    <span className={"owState state"+order.status}>{labels[order.status]||order.status}</span>
    <button className="owClose" type="button" aria-label="Fechar detalhes e voltar à lista" onClick={close}><X size={20}/></button>
   </header>

   <div className="owJourney" aria-label="Progresso do pedido">{stages.map((stage,index)=>
    <span key={stage} className={index===step?"isCurrent":index<step?"isDone":""}>
     <i>{index<step?<Check size={13}/>:index+1}</i>
     <span>{labels[stage]}</span>
    </span>
   )}</div>

   <div className="owQuickFacts" aria-label="Resumo do pedido">
    <div className="owQuickFact"><span><Package size={15}/> Produtos</span><strong>{units} {units===1?"unidade":"unidades"}</strong></div>
    <div className="owQuickFact"><span><ShieldCheck size={15}/> Pagamento</span><strong>{labels[order.paymentStatus]||order.paymentStatus||"A conferir"}</strong></div>
    <div className="owQuickFact"><span><CreditCard size={15}/> Valor do pedido</span><strong>{money(order.total)}</strong></div>
   </div>

   <nav className="owTabs" aria-label="Ir para uma seção do pedido">
    <button type="button" onClick={()=>scrollTo("ow-items")}>Produtos</button>
    <button type="button" onClick={()=>scrollTo("ow-customer")}>Cliente</button>
    <button type="button" onClick={()=>scrollTo("ow-address")}>Entrega</button>
    <button type="button" onClick={()=>scrollTo("ow-payment")}>Pagamento</button>
   </nav>

   <div className="owScroll" ref={scrollArea}>
    <div className="owLayout">
     <div className="owAside" role="complementary" aria-label="Dados do cliente e da entrega">
      <section className="owSection owCustomer" id="ow-customer">
       <header><div><span className="owEyebrow">CLIENTE</span><h3><UserRound size={17}/> Dados do cliente</h3></div></header>
       <b>{order.customer?.name||"Cliente"}</b>
       <p className="owInline"><Phone size={15}/>{order.customer?.phone||"Telefone não informado"}</p>
      </section>

      <section className="owSection owDelivery" id="ow-address">
       <header><div><span className="owEyebrow">DESTINO</span><h3><MapPin size={17}/> Endereço de entrega</h3></div></header>
       <b>{[address.street,address.number].filter(Boolean).join(", ")||"Endereço não informado"}</b>
       {address.complement&&<p>{address.complement}</p>}
       <p>{[address.neighborhood,address.city,address.state].filter(Boolean).join(" · ")}</p>
       {address.postalCode&&<p className="owInline"><Navigation size={15}/>CEP {address.postalCode}</p>}
       {address.reference&&<div className="owReference"><strong>Referência:</strong> {address.reference}</div>}
      </section>

      <section className="owSection owCourier">
       <header><div><span className="owEyebrow">LOGÍSTICA</span><h3><Bike size={18}/> Motoboy e despacho</h3></div></header>
       <b>{order.courier?.user?.name||(order.status==="SEARCHING_COURIER"?"Buscando motoboy":"Aguardando atribuição")}</b>
       {order.courier?.user?.phone&&<p>{order.courier.user.phone}</p>}
       <p>{order.routeDistanceKm?Number(order.routeDistanceKm).toFixed(1)+" km de rota":"Distância ainda não registrada"}</p>
       {order.status==="SEARCHING_COURIER"&&<div className="owDispatch"><Clock size={17}/><span>Despacho automático ativo. A oferta circula entre os motoboys disponíveis.</span></div>}
       <button type="button" className="owSecondary" disabled={auditBusy} onClick={onAudit}><History size={16}/>{auditBusy?"Consultando…":"Ver histórico da entrega"}</button>
      </section>
     </div>

     <div className="owMain">
      <section className="owSection owProducts" id="ow-items">
       <header><div><span className="owEyebrow">CONFERÊNCIA DE ESTOQUE</span><h3><Package size={18}/> Itens do pedido</h3><p>Confira os itens e informe qualquer indisponibilidade.</p></div><span className="owQuantity">{itemCount} {itemCount===1?"item":"itens"}</span></header>
       <OrderAvailabilityEditor order={order} products={products} request={request} reload={reload}/>
      </section>

      <section className="owSection owPaymentCard" id="ow-payment">
       <header><div><span className="owEyebrow">FINANCEIRO</span><h3><ReceiptText size={18}/> Detalhes do pagamento</h3></div><span className={"owPayment"+(order.paymentStatus==="PAID"?" isPaid":"")}><ShieldCheck size={14}/>{labels[order.paymentStatus]||order.paymentStatus||"A conferir"}</span></header>
       <dl className="owTotals">
        <div><dt>Produtos originais</dt><dd>{money(order.subtotal)}</dd></div>
        <div><dt>Taxa de entrega</dt><dd>{money(order.deliveryFee)}</dd></div>
        {Number(order.storeCreditUsed)>0&&<div><dt>Cartão Porto Prime utilizado</dt><dd>{money(order.storeCreditUsed)}</dd></div>}
        <div><dt>{Number(order.total)===0&&Number(order.storeCreditUsed)>0?"Pago integralmente com saldo":"Pagamento via Stripe"}</dt><dd>{money(order.total)}</dd></div>
        {Number(order.removedItemsTotal)>0&&<><div><dt>Itens removidos</dt><dd>−{money(order.removedItemsTotal)}</dd></div><div className="owAdjusted"><dt>Pagamento atualizado</dt><dd>{money(order.adjustedTotal)}</dd></div></>}
       </dl>
       <div className="owGrandTotal"><span>Valor do pedido</span><strong>{money(order.total)}</strong></div>
      </section>
      <details className="owAdminTools"><summary>Ações administrativas <ChevronDown size={16}/></summary><p>Excluir não solicita reembolso. Os registros financeiros são preservados.</p><button type="button" className="owDelete" onClick={onDelete}><Trash2 size={15}/> Excluir pedido</button></details>
     </div>
    </div>
   </div>

   <footer className="owFooter">
    <div className="owFooterNote"><b>{order.fulfillmentHold?"Aguardando a decisão do cliente":ready?"Pronto para conferência":"Acompanhamento do pedido"}</b><p>{actionHint}</p></div>
    <div className="owFooterActions">
     {statuses.includes(order.status)&&<label><span>Etapa na loja</span><select aria-label="Alterar etapa do pedido" value={order.status} onChange={event=>onStatus(event.target.value)}>{statuses.map(status=><option key={status} value={status}>{labels[status]}</option>)}</select></label>}
     {ready?<button type="button" className="owPrimary" disabled={order.fulfillmentHold} onClick={onRelease}>{order.fulfillmentHold?"Aguardando cliente":"Liberar pedido"}<ArrowRight size={18}/></button>:<button type="button" className="owSecondary" onClick={close}>Voltar aos pedidos</button>}
    </div>
   </footer>
  </section>
 </div>;
}
