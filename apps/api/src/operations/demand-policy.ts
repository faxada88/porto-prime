export const DEMAND_THRESHOLD = 10;
export const waitingOrders = {
 paymentStatus: 'PAID', courierId: null,
 status: {in: ['PENDING','CONFIRMED','PREPARING','READY_FOR_PICKUP','SEARCHING_COURIER']},
};
export function demandEnabled(mode:string, waiting:number) {
 return mode==='MANUAL_ON' || (mode==='AUTO' && waiting>=DEMAND_THRESHOLD);
}
export async function offeredDemandBonus(tx:any):Promise<number> {
 const row=await tx.courierDemandSignal.findUnique({where:{id:'default'}});
 const mode=row?.mode??'AUTO';
 const waiting=mode==='AUTO'?await tx.order.count({where:waitingOrders}):0;
 return demandEnabled(mode,waiting)?Number(row?.bonusAmount??2.5):0;
}
