'use client';

import { useEffect, useRef, useState } from 'react';
import { Archive, Check, ImageIcon, Package, Pencil, Plus, Search, Store, X } from 'lucide-react';

type Row = Record<string, any>;
const money = (value: any) => Number(value || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
const emptyProduct = (categoryId = '') => ({ categoryId, name: '', description: '', imageUrl: '', price: '', stock: 0, active: true });

export default function CatalogPanel({ categories, pricing, act }: { categories: Row[], pricing: Row, act: (path: string, method: string, body: Row) => Promise<any> }) {
  const [view, setView] = useState<'products' | 'categories'>('products');
  const [store, setStore] = useState<Row>(pricing);
  useEffect(() => { setStore(current => !current.updatedAt || !pricing.updatedAt || new Date(pricing.updatedAt).getTime() >= new Date(current.updatedAt).getTime() ? pricing : current); }, [pricing]);
  const [query, setQuery] = useState(''), [category, setCategory] = useState('all'), [filter, setFilter] = useState('all');
  const [limit, setLimit] = useState(24), [editor, setEditor] = useState<'product' | 'category' | 'store' | null>(null);
  const [form, setForm] = useState<Row>({}), [saving, setSaving] = useState(false), [notice, setNotice] = useState('');
  const [confirm, setConfirm] = useState<{ path: string, name: string, archived: boolean } | null>(null);
  const previousFocus = useRef<HTMLElement | null>(null), modal = useRef<HTMLElement | null>(null);
  const all = categories.flatMap(c => (c.products || []).map((p: Row) => ({ ...p, category: c })));
  const visible = all.filter(p => (category === 'all' || p.categoryId === category) && `${p.name} ${p.description || ''} ${p.category.name}`.toLocaleLowerCase('pt-BR').includes(query.toLocaleLowerCase('pt-BR')) && (filter === 'archived' ? p.archived || p.category.archived : !p.archived && !p.category.archived && (filter === 'all' || (filter === 'available' ? p.active && p.stock > 0 && p.category.active : filter === 'stock' ? p.stock <= 0 : !p.active || !p.category.active))));
  const live = all.filter(p => !p.archived && !p.category.archived);
  useEffect(() => { setLimit(24); }, [query, category, filter]);
  useEffect(() => {
    if (!editor && !confirm) return;
    previousFocus.current = document.activeElement as HTMLElement;
    const before = document.body.style.overflow; document.body.style.overflow = 'hidden';
    const id = requestAnimationFrame(() => modal.current?.querySelector<HTMLElement>('input, button')?.focus());
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !saving) { setEditor(null); setConfirm(null); }
      if (e.key === 'Tab') {
        const nodes = Array.from(modal.current?.querySelectorAll<HTMLElement>('button:not(:disabled),input:not(:disabled),select:not(:disabled),textarea:not(:disabled)') || []);
        const first = nodes[0], last = nodes[nodes.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last?.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first?.focus(); }
      }
    };
    document.addEventListener('keydown', key);
    return () => { cancelAnimationFrame(id); document.body.style.overflow = before; document.removeEventListener('keydown', key); previousFocus.current?.focus(); };
  }, [editor, confirm, saving]);
  const change = (key: string, value: any) => setForm(f => ({ ...f, [key]: value }));
  const open = (kind: 'product' | 'category' | 'store', data: Row) => { setForm({ ...data }); setNotice(''); setEditor(kind); };
  const mutate = async (path: string, body: Row, success: string, method = 'PATCH') => {
    if (saving) return null; setSaving(true); setNotice('');
    try { const result = await act(path, method, body); if (result) setNotice(success); return result; }
    finally { setSaving(false); }
  };
  const save = async (e: React.FormEvent) => {
    e.preventDefault(); const id = form.id;
    const path = editor === 'store' ? '/admin/store' : `/admin/${editor === 'product' ? 'products' : 'categories'}${id ? '/' + id : ''}`;
    const body = editor === 'product' ? { name: form.name, categoryId: form.categoryId, description: form.description || '', imageUrl: form.imageUrl || '', price: Number(form.price), stock: Number(form.stock), active: form.active } : editor === 'category' ? { name: form.name, imageUrl: form.imageUrl || '', position: Number(form.position || 0), active: form.active } : { storeOpen: form.storeOpen, storeMessage: form.storeMessage };
    const result = await mutate(path, body, 'Alteração salva e enviada ao app.', id || editor === 'store' ? 'PATCH' : 'POST');
    if (result) { if (editor === 'store') setStore(result); setEditor(null); }
  };
  const close = () => { if (!saving) { setEditor(null); setConfirm(null); } };
  const field = (key: string, label: string, type = 'text', props: Row = {}) => <label>{label}<input type={type} value={form[key] ?? ''} onChange={e => change(key, e.target.value)} {...props}/></label>;
  const archive = (path: string, item: Row) => setConfirm({ path, name: item.name, archived: !item.archived });
  return <div className="primeCatalog">
    <section className="catalogControlBar">
      <div><small>PORTO PRIME · VITRINE</small><h2>Gestão da vitrine</h2><p>Produtos bem apresentados. Operação sob controle.</p></div>
      <div className="catalogStoreControls"><span className={`catalogStorePill ${store.storeOpen === false ? 'closed' : ''}`} role="status"><i/>{typeof store.storeOpen !== 'boolean' ? 'Verificando loja…' : store.storeOpen === false ? 'Loja fechada' : 'Loja aberta'}</span><button disabled={saving || typeof store.storeOpen !== 'boolean'} onClick={async () => { const result=await mutate('/admin/store', { storeOpen: store.storeOpen === false }, store.storeOpen === false ? 'Loja aberta. Novos pedidos liberados.' : 'Loja fechada. Novos pedidos bloqueados.'); if(result) setStore(result); }}>{saving ? 'Salvando…' : store.storeOpen === false ? 'Abrir loja' : 'Fechar loja'}</button><button className="secondary" aria-label="Editar aviso da loja" onClick={() => open('store', { ...store, storeOpen: store.storeOpen !== false, storeMessage: store.storeMessage || 'Voltaremos em breve. Sua sacola continua salva.' })}><Pencil size={16}/></button></div>
    </section>
    {store.storeOpen === false && <div className="catalogClosedNotice"><Store size={18}/><span><strong>Novos pedidos pausados.</strong> {store.storeMessage} Pedidos já em andamento continuam normalmente.</span></div>}
    {notice && <p className="catalogNotice" role="status"><Check size={16}/>{notice}</p>}
    <section className="catalogFlatPanel">
      <div className="catalogFlatTop"><div className="catalogViewTabs" role="group" aria-label="Área do catálogo"><button aria-pressed={view==='products'} className={view==='products'?'selected':''} onClick={()=>setView('products')}>Produtos <span>{live.length}</span></button><button aria-pressed={view==='categories'} className={view==='categories'?'selected':''} onClick={()=>setView('categories')}>Categorias <span>{categories.filter(c=>!c.archived).length}</span></button></div><button onClick={()=>view==='products'?open('product',emptyProduct(categories.find(c=>!c.archived)?.id)):open('category',{name:'',imageUrl:'',position:categories.length,active:true})}><Plus size={16}/>{view==='products'?'Novo produto':'Nova categoria'}</button></div>
      {view==='products' ? <><div className="catalogFilters"><label className="catalogSearch"><Search size={18}/><input aria-label="Buscar produtos" placeholder="Buscar produto pelo nome…" value={query} onChange={e=>setQuery(e.target.value)}/></label><select aria-label="Categoria" value={category} onChange={e=>setCategory(e.target.value)}><option value="all">Todas as categorias</option>{categories.map(c=><option key={c.id} value={c.id}>{c.name}{c.archived?' (arquivada)':''}</option>)}</select><select aria-label="Disponibilidade" value={filter} onChange={e=>setFilter(e.target.value)}><option value="all">Todos os produtos</option><option value="available">Disponíveis</option><option value="unavailable">Indisponíveis</option><option value="stock">Sem estoque</option><option value="archived">Arquivados</option></select></div>
      <div className="catalogListSummary"><span>{visible.length} produtos encontrados</span><span>Preço · Estoque · Disponibilidade</span></div><div className="catalogCleanList">{visible.slice(0,limit).map(p=><article key={p.id} className="catalogCleanRow"><div className="catalogCleanIdentity"><div className="catalogCleanImage">{p.imageUrl?<img loading="lazy" decoding="async" src={p.imageUrl} alt=""/>:<ImageIcon size={23}/>}</div><div><h3>{p.name}</h3><span>{p.category.name}</span></div></div><div className="catalogCleanPrice"><small>Preço</small><strong>{money(p.price)}</strong></div><div className="catalogCleanStock"><small>Estoque</small><strong>{p.stock} un.</strong></div><span className={`catalogCleanBadge ${p.archived||p.category.archived||!p.active||!p.category.active||p.stock<=0?'paused':''}`}>{p.archived||p.category.archived?'Arquivado':!p.active||!p.category.active?'Indisponível':p.stock<=0?'Sem estoque':'Disponível'}</span><button className="secondary" aria-label={`Editar ${p.name}`} onClick={()=>open('product',p)}><Pencil size={15}/><span>Editar</span></button></article>)}</div>{!visible.length&&<div className="catalogEmpty"><Package size={34}/><h3>Nenhum produto encontrado</h3><p>Ajuste os filtros ou adicione um produto à vitrine.</p></div>}{visible.length>limit&&<button className="catalogMore secondary" onClick={()=>setLimit(n=>n+24)}>Mostrar mais produtos</button>}</> : <><p className="catalogCategoryIntro">Organize a ordem e a disponibilidade das categorias. A edição abre apenas a categoria selecionada.</p><div className="catalogCleanList">{categories.map(c=><article key={c.id} className="catalogCleanRow category"><div className="catalogCleanIdentity"><div className="catalogCleanImage"><Package size={22}/></div><div><h3>{c.name}</h3><span>{(c.products||[]).filter((p:Row)=>!p.archived).length} produtos · Ordem {c.position}</span></div></div><span className={`catalogCleanBadge ${c.archived||!c.active?'paused':''}`}>{c.archived?'Arquivada':c.active?'Ativa':'Pausada'}</span><button className="secondary" aria-label={`Editar categoria ${c.name}`} onClick={()=>open('category',c)}><Pencil size={15}/>Editar</button></article>)}</div>{!categories.length&&<div className="catalogEmpty"><Package size={34}/><h3>Comece com uma categoria</h3><p>Crie as categorias que organizarão seus produtos no app.</p></div>}</>}
    </section>
    {(editor || confirm) && <div className="catalogModalBackdrop" onMouseDown={e => { if (e.target === e.currentTarget) close(); }}><section ref={modal} className="catalogEditor" role="dialog" aria-modal="true" aria-labelledby="catalog-editor-title"><header><div><small>{confirm ? 'ORGANIZAR CATÁLOGO' : 'PUBLICAÇÃO NO APP'}</small><h2 id="catalog-editor-title">{confirm ? `${confirm.archived ? 'Arquivar' : 'Restaurar'} registro` : editor === 'store' ? 'Aviso da loja' : `${form.id ? 'Editar' : 'Criar'} ${editor === 'product' ? 'produto' : 'categoria'}`}</h2></div><button type="button" className="secondary" aria-label="Fechar" disabled={saving} onClick={close}><X size={19}/></button></header>
    {confirm ? <><p><strong>{confirm.name}</strong></p><p>{confirm.archived ? 'O registro sai da vitrine. Produtos, pedidos e histórico ficam preservados; você pode restaurá-lo depois.' : 'O registro volta ao catálogo com sua disponibilidade e estoque anteriores. Categorias pausadas continuam ocultas no app.'}</p><div className="catalogEditorActions"><button className="secondary" disabled={saving} onClick={close}>Cancelar</button><button disabled={saving} onClick={async () => { if (await mutate(confirm.path, { archived: confirm.archived }, 'Catálogo atualizado.')) setConfirm(null); }}>{saving ? 'Salvando…' : confirm.archived ? 'Arquivar' : 'Restaurar'}</button></div></> : <form onSubmit={save}><div className="catalogEditorFields">
    {editor === 'store' ? <><p className="catalogFormNote">{form.storeOpen ? 'Clientes poderão finalizar novos pedidos novamente.' : 'A vitrine continua acessível. Novos pedidos ficam bloqueados; pagamentos e entregas já iniciados continuam normalmente.'}</p><label className="full">Mensagem exibida quando a loja estiver fechada<textarea maxLength={240} required value={form.storeMessage || ''} onChange={e => change('storeMessage', e.target.value)}/></label></> : <>{field('name', editor === 'product' ? 'Nome do produto' : 'Nome da categoria', 'text', { required: true, maxLength: editor === 'product' ? 160 : 100 })}{editor === 'product' ? <><label>Categoria<select required value={form.categoryId || ''} onChange={e => change('categoryId', e.target.value)}><option value="">Selecione</option>{categories.filter(c => !c.archived || c.id === form.categoryId).map(c => <option key={c.id} value={c.id} disabled={c.archived}>{c.name}</option>)}</select></label>{field('price', 'Preço (R$)', 'number', { min: 0, max: 99999999.99, step: '.01', required: true })}{field('stock', 'Quantidade em estoque', 'number', { min: 0, max: 2147483647, step: 1, required: true })}<label className="full">Descrição<textarea maxLength={2000} value={form.description || ''} onChange={e => change('description', e.target.value)}/></label></> : field('position', 'Ordem de exibição', 'number', { min: 0, step: 1, required: true })}<label className="full">Imagem do seu catálogo · URL HTTPS<input type="url" pattern="https://.*" maxLength={2048} value={form.imageUrl || ''} onChange={e => change('imageUrl', e.target.value)} placeholder="https://…"/><small>Use uma imagem própria já hospedada. Deixe vazio para remover.</small></label>{form.imageUrl && <div className="catalogImagePreview full"><img src={form.imageUrl} alt="Prévia da imagem"/></div>}<label className="catalogCheckbox full"><input type="checkbox" checked={form.active === true} onChange={e => change('active', e.target.checked)}/><span>{editor === 'product' ? 'Disponível para venda quando houver estoque e categoria ativa' : 'Categoria visível no app'}</span></label></>}
    </div><div className="catalogEditorActions">{form.id && editor !== 'store' && <button type="button" className="secondary catalogArchiveAction" disabled={saving} onClick={()=>{ const item={...form}; const path='/admin/'+(editor==='product'?'products':'categories')+'/'+form.id; setEditor(null); archive(path,item); }}><Archive size={16}/>{form.archived?'Restaurar':'Arquivar'}</button>}<button type="button" className="secondary" onClick={close} disabled={saving}>Cancelar</button><button disabled={saving}>{saving ? 'Salvando…' : 'Salvar alterações'}</button></div></form>}
    </section></div>}
  </div>;
}
