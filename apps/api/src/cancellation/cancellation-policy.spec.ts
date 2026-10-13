import {describe,it,expect} from 'vitest';
import {cancellationAmounts} from './cancellation-policy.js';
const now=new Date('2026-10-13T12:00:00Z');
function order(age:number,extra:any={}){return {paidAt:new Date(now.getTime()-age),createdAt:new Date(now.getTime()-age),total:61,deliveryFee:16,storeCreditUsed:0,refundedTotal:0,items:[{total:45}],...extra};}
describe('Cancelamento em centavos',()=>{
 it.each([0,119999,120000])('sem custo até dois minutos, mesmo com aceite (%s)',age=>expect(cancellationAmounts(order(age),true,now)).toEqual({fee:0,cashRefund:61,creditRefund:0}));
 it('cobra exatamente metade da entrega após a janela',()=>expect(cancellationAmounts(order(120001),true,now)).toEqual({fee:8,cashRefund:53,creditRefund:0}));
 it('sem aceite não cobra taxa mesmo após a janela',()=>expect(cancellationAmounts(order(999999),false,now)).toEqual({fee:0,cashRefund:61,creditRefund:0}));
 it('preserva pagamento misto e não devolve valores duas vezes',()=>expect(cancellationAmounts(order(999999,{total:11,storeCreditUsed:50,items:[{total:45,storeCreditShare:45}]}),true,now)).toEqual({fee:8,cashRefund:3,creditRefund:50}));
 it('compra integral com saldo retém taxa e devolve o restante ao cartão',()=>expect(cancellationAmounts(order(999999,{total:0,storeCreditUsed:61,items:[{total:45,storeCreditShare:45}]}),true,now)).toEqual({fee:8,cashRefund:0,creditRefund:53}));
 it('exclui dinheiro convertido em voucher de item indisponível',()=>expect(cancellationAmounts(order(999999,{total:56,storeCreditUsed:5,creditedTotal:20,items:[{total:20,storeCreditShare:5,creditAmount:20,availabilityStatus:'VOUCHERED'},{total:25,storeCreditShare:0}]}),true,now)).toEqual({fee:8,cashRefund:33,creditRefund:0}));
 it('exclui valores já reservados para estorno de item em andamento',()=>expect(cancellationAmounts(order(999999,{total:56,storeCreditUsed:5,items:[{total:20,storeCreditShare:5,creditAmount:5,refundAmount:15,availabilityStatus:'REFUND_PROCESSING'},{total:25}]}),true,now)).toEqual({fee:8,cashRefund:33,creditRefund:0}));
 it('arredonda a metade em centavos e nunca devolve negativo',()=>expect(cancellationAmounts(order(999999,{total:10,deliveryFee:5.51}),true,now)).toEqual({fee:2.76,cashRefund:7.24,creditRefund:0}));
});
