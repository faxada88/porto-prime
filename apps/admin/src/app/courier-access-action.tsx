"use client";
import { useState } from 'react';

export default function CourierAccessAction({ label, onSubmit }: {
  label: string; onSubmit: (reason: string) => Promise<unknown>;
}) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  return <>
    <button className="warn" onClick={() => setOpen(true)}>{label}</button>
    {open && <div className="modalBackdrop"><section role="dialog" aria-modal="true" aria-label={`${label} conta`} style={{background:'white',borderRadius:24,padding:24,width:'min(520px, calc(100vw - 32px))',maxHeight:'90dvh',overflowY:'auto',color:'#073E43'}}>
      <h2>{label} conta</h2><p>Informe o motivo e como o motoboy pode regularizar a situação. Ele verá esta orientação na própria conta.</p>
      <label>Motivo da restrição<textarea autoFocus maxLength={2000} rows={5} value={reason} disabled={busy} onChange={e=>setReason(e.target.value)} style={{width:'100%',marginTop:8}}/></label>
      {error && <p role="alert">{error}</p>}
      <div style={{display:'flex',gap:12,flexWrap:'wrap',marginTop:16}}>
        <button className="secondary" disabled={busy} onClick={()=>setOpen(false)}>Voltar</button>
        <button disabled={busy || reason.trim().length < 3} onClick={async()=>{
          setBusy(true);setError('');
          try { const result=await onSubmit(reason.trim()); if(result){setOpen(false);setReason('');}else setError('Não foi possível salvar. Tente novamente.'); }
          catch { setError('Não foi possível salvar. Tente novamente.'); }
          finally {setBusy(false);}
        }}>{busy?'Salvando…':`Confirmar ${label.toLowerCase()}`}</button>
      </div>
    </section></div>}
  </>;
}
