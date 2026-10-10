"use client";
import {useEffect,useRef,useState} from 'react';
import {Zap} from 'lucide-react';
import {displayMessage} from './ui-messages';
type Signal={enabled:boolean;revision:number;updatedAt:string|null};
export default function DemandControl({request,epoch}:{request:(path:string,method?:string,body?:unknown)=>Promise<Signal>;epoch:number}){
 const [signal,setSignal]=useState<Signal|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const latest=useRef(-1),writing=useRef(false);
 function apply(data:Signal){if(typeof data.enabled!=='boolean'||!Number.isInteger(data.revision)||data.revision<latest.current)return;latest.current=data.revision;setSignal(data);}
 useEffect(()=>{let active=true;if(!writing.current)request('/admin/operations/demand').then(data=>{if(active){apply(data);setError('')}}).catch(e=>{if(active)setError(displayMessage(e))});return()=>{active=false};
 // The epoch follows the existing authenticated admin synchronization.
 // eslint-disable-next-line react-hooks/exhaustive-deps
 },[epoch]);
 async function toggle(){if(!signal||writing.current)return;writing.current=true;setBusy(true);setError('');try{apply(await request('/admin/operations/demand','PATCH',{enabled:!signal.enabled}))}catch(e){setError(displayMessage(e))}finally{writing.current=false;setBusy(false)}}
 return <div className={'demandControl '+(signal?.enabled?'isDemand':'')}><button type="button" role="switch" aria-checked={signal?.enabled??false} disabled={busy||!signal} onClick={toggle} aria-describedby="demand-control-caption"><Zap size={17}/><span><b>Alta demanda</b><small>{busy?'Atualizando…':!signal?'Consultando…':signal.enabled?'Aviso ativo para motoboys':'Ativar aviso para motoboys'}</small></span><i aria-hidden="true"><i/></i></button><span id="demand-control-caption" className="sr-only">Aviso operacional, sem alterar valores ou distribuição das entregas.</span>{error&&<small className="demandControlError" role="alert">{error}</small>}</div>;
}
