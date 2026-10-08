// Aggregate paid, unassigned orders. Never expose customers, order IDs or exact addresses.
export function buildDemandZones(orders: Array<{ address?: { neighborhood?: string | null; latitude?: unknown; longitude?: unknown } | null }>) {
  const zones = new Map<string, { name: string; count: number; latitude: number | null; longitude: number | null }>();
  for (const order of orders) {
    const address = order.address;
    const name = address?.neighborhood?.trim() || 'Bairro não informado';
    const lat = address?.latitude == null ? NaN : Number(address.latitude);
    const lng = address?.longitude == null ? NaN : Number(address.longitude);
    const valid = Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat)<=90 && Math.abs(lng)<=180;
    // Coarse grid (~1 km); location is an operational zone, not a delivery destination.
    const latitude = valid ? Math.round(lat*100)/100 : null;
    const longitude = valid ? Math.round(lng*100)/100 : null;
    const key = `${name.toLocaleLowerCase('pt-BR')}:${latitude}:${longitude}`;
    const zone = zones.get(key) || { name, count: 0, latitude, longitude };
    zone.count++; zones.set(key, zone);
  }
  return [...zones.values()].sort((a,b)=>b.count-a.count || a.name.localeCompare(b.name)).map(z=>({...z, level:z.count>=3?'HIGH':z.count>=2?'MEDIUM':'LOW'}));
}
