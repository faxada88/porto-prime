'use client';

import {useEffect, useId, useRef, useState} from 'react';
import {Check, ChevronDown, Search} from 'lucide-react';
import {CATEGORY_ICONS, categoryIcon} from './category-icons';

export default function CategoryIconPicker({value, onChange}: {
  value: string; onChange: (key: string) => void;
}) {
  const [open, setOpen] = useState(false), [query, setQuery] = useState('');
  const root=useRef<HTMLDivElement>(null), trigger=useRef<HTMLButtonElement>(null), search=useRef<HTMLInputElement>(null);
  const id=useId();
  const selected=CATEGORY_ICONS.find(icon=>icon.key===value);
  const SelectedIcon=categoryIcon(value).Icon;
  const normalize=(text:string)=>text.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
  const options=CATEGORY_ICONS.filter(icon=>normalize(icon.label+' '+icon.terms.join(' ')).includes(normalize(query)));
  useEffect(()=>{
    if(!open)return;
    const frame=requestAnimationFrame(()=>search.current?.focus());
    const outside=(event:PointerEvent)=>{if(!root.current?.contains(event.target as Node))setOpen(false);};
    document.addEventListener('pointerdown',outside);
    return()=>{cancelAnimationFrame(frame);document.removeEventListener('pointerdown',outside);};
  },[open]);
  const choose=(key:string)=>{onChange(key);setOpen(false);setQuery('');trigger.current?.focus();};
  return <div ref={root} className="primeIconPicker" onKeyDown={event=>{
    if(event.key==='Escape'&&open){event.preventDefault();event.stopPropagation();setOpen(false);trigger.current?.focus();}
  }}>
    <span id={id+'-label'} className="primeIconPickerLabel">Ícone da categoria no aplicativo</span>
    <button ref={trigger} type="button" className="primeIconPickerTrigger" aria-labelledby={id+'-label '+id+'-value'} aria-haspopup="listbox" aria-expanded={open} aria-controls={id+'-options'} onClick={()=>setOpen(current=>!current)} onKeyDown={event=>{if(event.key==='ArrowDown'){event.preventDefault();setOpen(true);}}}>
      <span className="primeIconPickerGlyph" style={{background:selected?.background,color:selected?.foreground}}><SelectedIcon size={25} strokeWidth={1.7}/></span>
      <span id={id+'-value'}>{selected?.label||'Escolha o desenho da categoria'}</span><ChevronDown size={18}/>
    </button>
    <small>Você escolhe o desenho. O aplicativo usa esta opção mesmo que o nome da categoria seja diferente.</small>
    {open&&<div className="primeIconPickerPopup">
      <label className="primeIconPickerSearch"><Search size={17}/><input ref={search} value={query} onChange={event=>setQuery(event.target.value)} aria-label="Pesquisar ícones" placeholder="Buscar: carne, frutas, fitness…" onKeyDown={event=>{
        if(event.key==='ArrowDown'){event.preventDefault();root.current?.querySelector<HTMLButtonElement>('[role="option"]')?.focus();}
        if(event.key==='Enter'){event.preventDefault();if(options.length===1)choose(options[0].key);}
      }}/></label>
      <div id={id+'-options'} role="listbox" aria-labelledby={id+'-label'} className="primeIconPickerOptions" onKeyDown={event=>{
        const items=Array.from(root.current?.querySelectorAll<HTMLButtonElement>('[role="option"]')||[]);
        const current=items.indexOf(document.activeElement as HTMLButtonElement);
        if(['ArrowDown','ArrowUp','Home','End'].includes(event.key)){
          event.preventDefault();const next=event.key==='Home'?0:event.key==='End'?items.length-1:event.key==='ArrowDown'?(current+1)%items.length:(current-1+items.length)%items.length;items[next]?.focus();
        }
      }}>
        {options.map(option=>{const Icon=option.Icon;return <button key={option.key} type="button" role="option" aria-selected={option.key===value} className={option.key===value?'selected':''} onClick={()=>choose(option.key)}>
          <span className="primeIconPickerGlyph" style={{background:option.background,color:option.foreground}}><Icon size={25} strokeWidth={1.7}/></span><span>{option.label}</span>{option.key===value&&<Check size={17}/>}
        </button>})}
      </div>
      {!options.length&&<p className="primeIconPickerEmpty">Nenhum ícone encontrado. Tente outro termo.</p>}
    </div>}
  </div>;
}
