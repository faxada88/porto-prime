import type { ReactNode } from 'react';
import './requirement-review.css';

type Requirement = { id?: string; status?: string; canceledAt?: unknown; [key: string]: any };
export default function RequirementList({ items, children }: { items: Requirement[]; children: (item: Requirement) => ReactNode }) {
  const closed = items.filter(r => r.canceledAt || r.status === 'RESOLVED');
  const active = items.filter(r => !r.canceledAt && r.status !== 'RESOLVED')
    .sort((a, b) => Number(b.status === 'ANSWERED') - Number(a.status === 'ANSWERED'));
  const answered = active.filter(r => r.status === 'ANSWERED').length;
  return <div className="requirementReview">
    {active.length > 0 && <div className="requirementReviewSummary"><strong>{answered ? `${answered} resposta${answered > 1 ? 's' : ''} para analisar` : 'Aguardando o motoboy'}</strong><span>{answered ? 'Confira o envio e conclua a análise abaixo.' : 'As respostas aparecerão aqui assim que forem enviadas.'}</span></div>}
    {active.map(r => <section className="requirementReviewItem" key={r.id}>{children(r)}</section>)}
    {closed.length > 0 && <details className="requirementReviewHistory"><summary>Histórico de solicitações <span>{closed.length}</span></summary>{closed.map(r => <section className="requirementReviewItem" key={r.id}>{children(r)}</section>)}</details>}
  </div>;
}
