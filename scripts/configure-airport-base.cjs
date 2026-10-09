// Resolve the mapped SBPS terminal to a drivable access road, then save the test base.
const {createRequire}=require('node:module');
const {resolve}=require('node:path');
const {readFile}=require('node:fs/promises');
const apiRequire=createRequire(resolve(__dirname,'../apps/api/package.json'));
apiRequire('dotenv').config({path:resolve(__dirname,'../apps/api/.env'),quiet:true});
const {Client}=apiRequire('pg');
(async()=>{
 const origin=JSON.parse(await readFile(resolve(__dirname,'../.routing/airport-origin.json'),'utf8'));
 const base=(process.env.ROUTING_BASE_URL||'http://127.0.0.1:5000').replace(/\/$/,'');
 const response=await fetch(`${base}/nearest/v1/driving/${origin.longitude},${origin.latitude}?number=1`,{signal:AbortSignal.timeout(12000)});
 if(!response.ok)throw new Error('O roteador local não respondeu');
 const data=await response.json(), point=data.waypoints?.[0];
 if(data.code!=='Ok'||!point||!Array.isArray(point.location)||point.location.length!==2||!point.location.every(Number.isFinite)||!Number.isFinite(point.distance)||point.distance>500)throw new Error('Não foi possível identificar o acesso viário do terminal SBPS nos dados locais');
 const [lng,lat]=point.location;
 const db=new Client({connectionString:process.env.DATABASE_URL});
 await db.connect();
 try{
  await db.query(`INSERT INTO "DeliveryPricingConfig" ("id","distributorName","distributorAddress","distributorLatitude","distributorLongitude","baseFee","includedKm","pricePerAdditionalKm","platformCommissionPercent","pricingRevision","updatedAt")
   VALUES ('default',$1,$2,$3,$4,5.50,3,2.50,0,1,NOW())
   ON CONFLICT ("id") DO UPDATE SET "distributorName"=EXCLUDED."distributorName","distributorAddress"=EXCLUDED."distributorAddress","distributorLatitude"=EXCLUDED."distributorLatitude","distributorLongitude"=EXCLUDED."distributorLongitude","pricingRevision"="DeliveryPricingConfig"."pricingRevision"+1,"updatedAt"=NOW()
   WHERE "DeliveryPricingConfig"."distributorLatitude" IS DISTINCT FROM EXCLUDED."distributorLatitude" OR "DeliveryPricingConfig"."distributorLongitude" IS DISTINCT FROM EXCLUDED."distributorLongitude" OR "DeliveryPricingConfig"."distributorName" IS DISTINCT FROM EXCLUDED."distributorName"`,['Aeroporto de Porto Seguro','Terminal de passageiros · Porto Seguro/BA · Base de teste',lat,lng]);
  console.log('Base de teste configurada: Aeroporto de Porto Seguro. Tarifas existentes preservadas.');
 }finally{await db.end();}
})().catch(error=>{console.error('Não foi possível configurar a base de teste:',error.code||error.message);process.exitCode=1;});
