import { describe,it,expect } from 'vitest';
import { buildDemandZones } from './courier-radar.js';
describe('Operational demand zones',()=>{
 it('returns no invented hotspots for an empty operation',()=>expect(buildDemandZones([])).toEqual([]));
 it('groups counts into coarse cells and highlights actual high demand',()=>{
   const orders=Array.from({length:3},()=>({address:{neighborhood:' Centro ',latitude:-16.4431,longitude:-39.0642}}));
   expect(buildDemandZones(orders)).toEqual([{name:'Centro',count:3,latitude:-16.44,longitude:-39.06,level:'HIGH'}]);
 });
 it('keeps neighborhoods with no coordinates visible without placing fake markers',()=>{
   expect(buildDemandZones([{address:{neighborhood:'Bairro',latitude:null,longitude:null}}])).toEqual([{name:'Bairro',count:1,latitude:null,longitude:null,level:'LOW'}]);
 });
 it('does not expose order identifiers or personal address fields',()=>{
   const result=buildDemandZones([{id:'private',address:{street:'Private street',number:'10',neighborhood:'Centro',latitude:100,longitude:20}} as any]);
   expect(result[0]).not.toHaveProperty('id');expect(result[0]).not.toHaveProperty('street');expect(result[0].latitude).toBeNull();
 });
});
