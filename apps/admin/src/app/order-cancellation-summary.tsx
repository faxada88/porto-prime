"use client";
import {useState} from "react";
import {RotateCcw,ShieldCheck} from "lucide-react";
import {displayMessage} from "./ui-messages";
export default function OrderCancellationSummary({record,request,reload}:{record:Record<string,any>;request:(path:string,method:string,body?:any)=>Promise<any>;reload:()=>void}){
 const [busy,setBusy]=useState(false),[error,setError]=useState("");const money=(v:any)=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
 return <section className="cancellationRecord"><h4><ShieldCheck size={16}/> Cancelamento do cliente</h4><p>{record.reason} · {record.status==='COMPLETED'?'Devolução concluída':record.status==='REVIEW'?'Verificação necessária':'Devolução em processamento'}</p><dl><div><dt>Valor retido / repasse ao entregador</dt><dd>{money(record.fee)}</dd></div><div><dt>Devolução pelo pagamento original</dt><dd>{money(record.cashRefund)}</dd></div><div><dt>Saldo devolvido ao Cartão Porto Prime</dt><dd>{money(record.creditRefund)}</dd></div></dl>{record.stripeRefundId&&<small>Referência do reembolso: {record.stripeRefundId}</small>}{record.lastError&&<p role="status">{record.lastError}</p>}{error&&<p role="alert">{error}</p>}{record.status!=='COMPLETED'&&<button disabled={busy} onClick={async()=>{setBusy(true);setError('');try{await request(`/admin/cancellations/${record.id}/retry`,'POST');reload()}catch(e){setError(displayMessage(e instanceof Error?e.message:'Não foi possível verificar agora'))}finally{setBusy(false)}}}><RotateCcw size={14}/>{busy?'Verificando…':'Verificar devolução'}</button>}</section>;
}
