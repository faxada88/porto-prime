"use client";
import {useState} from "react";
import {Check, ChevronDown, ClipboardList, Pencil, Save, Upload, X} from "lucide-react";
import {displayMessage} from "./ui-messages";
type Row=Record<string,any>;
const groups=[
 {title:"Identidade e contato",hint:"Dados pessoais e acesso à conta",keys:["name","cpf","birthDate","email","phone"]},
 {title:"Habilitação",hint:"Registro, categoria e validade",keys:["cnh","cnhCategory","cnhExpiry"]},
 {title:"Veículo",hint:"Informações utilizadas na operação",keys:["hasMotorcycle","vehicleType","vehicleBrand","vehicleModel","vehicleYear","vehiclePlate"]},
 {title:"Endereço",hint:"Local informado no cadastro",keys:["cep","street","number","complement","neighborhood","city","state"]},
 {title:"Recebimentos",hint:"Chave PIX usada nas solicitações de saque",keys:["pixKeyType","pixKey"]},
];
const labels:Record<string,string>={name:"Nome completo",cpf:"CPF",birthDate:"Data de nascimento",email:"E-mail",phone:"Celular / WhatsApp",cnh:"Número da CNH",cnhCategory:"Categoria da CNH",cnhExpiry:"Validade da CNH",hasMotorcycle:"Possui moto",vehicleType:"Tipo de veículo",vehicleBrand:"Marca",vehicleModel:"Modelo",vehicleYear:"Ano",vehiclePlate:"Placa",cep:"CEP",street:"Rua / avenida",number:"Número",complement:"Complemento",neighborhood:"Bairro",city:"Cidade",state:"UF",pixKeyType:"Tipo de chave PIX",pixKey:"Chave PIX"};
const options:Record<string,string[]>={cnhCategory:['A','B','AB','C','D','E','AC','AD','AE'],vehicleType:['Moto','Bicicleta','Carro','Van','Caminhão'],pixKeyType:['CPF','CNPJ','EMAIL','PHONE','RANDOM']};
const text=(v:any):string=>v==null||v===""?"Não informado":typeof v==='boolean'?(v?'Sim':'Não'):typeof v==='object'?JSON.stringify(v,null,2):String(v);
const editable=groups.flatMap(g=>g.keys);
async function compressedPhoto(file:File){
 if(!['image/jpeg','image/png'].includes(file.type)||file.size>12*1024*1024)throw new Error('Escolha uma foto JPEG ou PNG de até 12 MB.');
 const url=URL.createObjectURL(file);
 try{
  const image=new Image();image.src=url;await image.decode();
  const scale=Math.min(1,512/Math.max(image.naturalWidth,image.naturalHeight));
  const canvas=document.createElement('canvas');canvas.width=Math.max(1,Math.round(image.naturalWidth*scale));canvas.height=Math.max(1,Math.round(image.naturalHeight*scale));
  const context=canvas.getContext('2d');if(!context)throw new Error('Não foi possível preparar a foto');context.fillStyle='#fff';context.fillRect(0,0,canvas.width,canvas.height);context.drawImage(image,0,0,canvas.width,canvas.height);
  for(const quality of [.85,.7,.55,.4]){const result=canvas.toDataURL('image/jpeg',quality);if(result.length<81000)return result;}
  throw new Error('A foto ficou muito grande. Escolha uma imagem mais simples.');
 }finally{URL.revokeObjectURL(url);}
}
export default function CourierRecordEditor({data,onSave}:{data:Row,onSave:(changes:Row)=>Promise<void>}){
 const [editing,setEditing]=useState(false),[draft,setDraft]=useState<Row>({}),[original,setOriginal]=useState<Row>({}),[originalExtra,setOriginalExtra]=useState<Row>({}),[extraDraft,setExtraDraft]=useState<Row>({}),[busy,setBusy]=useState(false),[photoBusy,setPhotoBusy]=useState(false),[error,setError]=useState(''),[notice,setNotice]=useState('');
 const extras=Object.keys(data).filter(k=>!editable.includes(k)&&!['profilePhoto','document','postalCode'].includes(k)&&!/(password|senha|token|secret|cpf|status|role|verified|approval|commission|balance|earnings|online|session|permission)/i.test(k));
 const baseline=(k:string)=>k==='cpf'?(data.cpf||data.document||''):k==='cep'?(data.cep||data.postalCode||''):(data[k]??'');
 const begin=()=>{setOriginal(Object.fromEntries(editable.map(k=>[k,baseline(k)])));setOriginalExtra(Object.fromEntries(extras.map(k=>[k,typeof data[k]==='object'?JSON.stringify(data[k],null,2):String(data[k]??'')])));setDraft({...Object.fromEntries(editable.map(k=>[k,baseline(k)])),profilePhoto:data.profilePhoto||''});setExtraDraft(Object.fromEntries(extras.map(k=>[k,typeof data[k]==='object'?JSON.stringify(data[k],null,2):String(data[k]??'')])));setError('');setNotice('');setEditing(true)};
 const save=async(e:React.FormEvent)=>{
  e.preventDefault();if(busy||photoBusy)return;setBusy(true);setError('');
  try{
   const changes:Row={};for(const k of editable)if(String(draft[k]??'')!==String(original[k]??''))changes[k]=k==='hasMotorcycle'?draft[k]===true||draft[k]==='true':draft[k];
   if('cep' in changes)changes.postalCode=changes.cep;
   if(draft.profilePhoto!==String(data.profilePhoto||''))changes.profilePhoto=draft.profilePhoto;
   const extraData:Row={};for(const k of extras){const previous=originalExtra[k];if(extraDraft[k]!==previous){let value:any=extraDraft[k];if(typeof data[k]==='object')value=JSON.parse(value);else if(typeof data[k]==='boolean'){if(!['true','false'].includes(value))throw new Error('Use true ou false no campo '+k);value=value==='true';}else if(typeof data[k]==='number'){if(!String(value).trim()||!Number.isFinite(Number(value)))throw new Error('Valor inválido no campo '+k);value=Number(value);}extraData[k]=value;}}
   if(Object.keys(extraData).length)changes.extraData=extraData;
   if(Object.keys(changes).length)await onSave(changes);
   setEditing(false);setNotice('Cadastro atualizado e sincronizado.');
  }catch(e){setError(displayMessage(e));}finally{setBusy(false)}
 };
 const field=(k:string)=><label key={k}><span>{labels[k]||k}</span>{editing?(k==='hasMotorcycle'?<select disabled={busy} value={String(draft[k])} onChange={e=>setDraft(d=>({...d,[k]:e.target.value==='true'}))}><option value="">Não informado</option><option value="true">Sim</option><option value="false">Não</option></select>:options[k]?<select disabled={busy} value={draft[k]} onChange={e=>setDraft(d=>({...d,[k]:e.target.value}))}><option value="">Selecione</option>{Array.from(new Set([...options[k],...(draft[k]?[String(draft[k])]:[])])).map(v=><option key={v}>{v}</option>)}</select>:<input disabled={busy} value={draft[k]} type={k==='email'?'email':'text'} autoComplete="off" maxLength={250} onChange={e=>setDraft(d=>({...d,[k]:e.target.value}))}/>):<b>{text(baseline(k))}</b>}</label>;
 return <section className="courierRecord"><div className="courierRecordHeading"><div><span className="courierRecordEyebrow">FICHA CADASTRAL</span><h3>Conheça cada detalhe.</h3><p>Dados organizados por etapa do cadastro.</p></div>{!editing&&<button className="secondary" onClick={begin}><Pencil size={16}/> Editar cadastro completo</button>}</div>{notice&&<p className="courierRecordSuccess" role="status"><Check size={16}/>{notice}</p>}<form onSubmit={save}><div className="courierRecordPhoto">{(editing?draft.profilePhoto:data.profilePhoto)?<img src={editing?draft.profilePhoto:data.profilePhoto} alt="Foto do motoboy"/>:<div className="courierRecordPhotoEmpty">Sem foto</div>}<div><b>Foto de identificação</b><p>Exibida no perfil e no acompanhamento da entrega.</p>{editing&&<label className="courierPhotoUpload"><Upload size={16}/>{photoBusy?'Preparando foto…':'Substituir foto'}<input type="file" accept="image/jpeg,image/png" disabled={busy||photoBusy} onChange={async e=>{const file=e.target.files?.[0];e.target.value='';if(!file)return;setPhotoBusy(true);setError('');try{const photo=await compressedPhoto(file);setDraft(d=>({...d,profilePhoto:photo}))}catch(err){setError(displayMessage(err))}finally{setPhotoBusy(false)}}}/></label>}</div></div>{editing&&<p className="courierIdentityHint">Alterações de CPF ou nascimento são verificadas novamente na Receita pela integração existente. O nome oficial e a situação cadastral são atualizados nessa verificação.</p>}{groups.map((g,i)=><details className="courierRecordGroup" key={g.title} open={editing||i===0||undefined}><summary><span className="courierRecordNumber">{String(i+1).padStart(2,'0')}</span><div><b>{g.title}</b><small>{g.hint}</small></div><ChevronDown size={18}/></summary><div className="courierRecordFields">{g.keys.map(field)}{i===0&&<label><span>Situação cadastral do CPF · verificação</span><b>{text(data.cpfSituation)}</b></label>}</div></details>)}{extras.length>0&&<details className="courierRecordGroup" open={editing||undefined}><summary><ClipboardList size={20}/><div><b>Informações adicionais</b><small>Outros campos preenchidos no formulário</small></div><ChevronDown size={18}/></summary><div className="courierRecordFields">{extras.map(k=><label key={k}><span>{k.replace(/([A-Z])/g,' $1')}</span>{editing?<textarea disabled={busy} value={extraDraft[k]} rows={typeof data[k]==='object'?5:2} maxLength={10000} onChange={e=>setExtraDraft(d=>({...d,[k]:e.target.value}))}/>:<b>{text(data[k])}</b>}</label>)}</div></details>}{error&&<p className="error" role="alert">{error}</p>}{editing&&<div className="courierRecordSave"><span>As mudanças são enviadas ao aplicativo após salvar.</span><button type="button" className="secondary" disabled={busy||photoBusy} onClick={()=>{setEditing(false);setError('')}}><X size={16}/> Cancelar</button><button disabled={busy||photoBusy}><Save size={16}/>{busy?'Salvando…':'Salvar cadastro'}</button></div>}</form></section>;
}
