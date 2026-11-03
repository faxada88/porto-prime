import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(process.argv[2]??'.');
const backup=path.resolve(process.argv[3]??'palette-backup');
const lib=path.join(root,'apps/mobile/lib');
if(!fs.existsSync(lib))throw Error('Pasta apps/mobile/lib nao encontrada.');
const themeValues={ocean900:'062F36',ocean800:'00434D',ocean700:'005563',ocean600:'006B73',ocean500:'16858B',ocean300:'A6D6D2',ocean100:'E2F2EE',ocean50:'F0F8F5',sun500:'F6C64F',sun200:'FCECC4',sand100:'FBF2DF',sand50:'FFFCF5',coral600:'B63C40',coral100:'FBECEE',lavender100:'E2F2EE',violet600:'005563',sky100:'E2F2EE',sky700:'005563',ink:'102F35',inkSoft:'3C585D',muted:'587178',subtle:'758A8D',canvas:'F5F8F6',surface:'FFFFFF',surfaceSoft:'FAFCFA',surfaceMuted:'ECF2EF',surfaceSun:'FFFAEF',surfaceOcean:'EDF7F3',stroke:'DCE7E2',strokeStrong:'B9D2CB',success:'16724F',warning:'8C600C',orange:'B97519',mintStrong:'C7E6DA',electric:'A6D6D2'};
const rgb=s=>[0,2,4].map(i=>parseInt(s.slice(i,i+2),16)/255);
const lum=s=>rgb(s).map(x=>x<=.04045?x/12.92:((x+.055)/1.055)**2.4).reduce((v,x,i)=>v+x*[.2126,.7152,.0722][i],0);
const cool=['062F36','00434D','005563','006B73','16858B','4E9495','75AEAA','A6D6D2','C7E6DA','DCE7E2','E2F2EE','EDF7F3','F0F8F5','F5F8F6','FAFCFA'];
const neutral=['102F35','3C585D','587178','758A8D','A7B8B2','C9D7D0','DCE7E2','ECF2EF','F5F8F6','FAFCFA'];
const targetSet=new Set([...cool,...neutral,...Object.values(themeValues),'145C40','25895C','54A779','97CEAF','CDEAD8','E7F5EC','F2FAF5','D7A02C']);
function nearest(source,choices){const l=lum(source);return choices.reduce((a,b)=>Math.abs(lum(a)-l)<=Math.abs(lum(b)-l)?a:b);}
function recolor(hex){
 const alpha=hex.slice(0,2),s=hex.slice(2).toUpperCase();
 if(targetSet.has(s)||['FFFFFF','000000'].includes(s))return hex;
 const [r,g,b]=rgb(s);const max=Math.max(r,g,b),min=Math.min(r,g,b),delta=max-min;
 if(delta<.055){return alpha+nearest(s,neutral);}
 let h=delta===0?0:max===r?((g-b)/delta)%6:max===g?(b-r)/delta+2:(r-g)/delta+4;h=(h*60+360)%360;
 // Blue/purple/teal decorative variants converge on the logo's teal family.
 if(h>=155&&h<=300)return alpha+nearest(s,cool);
 // Green remains a success family, with readable dark and pale surface variants.
 if(h>=75&&h<155)return alpha+nearest(s,['145C40','16724F','25895C','54A779','97CEAF','CDEAD8','E7F5EC','F2FAF5']);
 if(h>=35&&h<=65)return alpha+nearest(s,['8C600C','B97519','D7A02C','F6C64F','FCECC4','FBF2DF','FFFAEF','FFFCF5']);
 // Reds and orange warning variants retain their semantic meaning.
 return hex;
}
// Lex only Dart code: never replace a color-shaped string, comment or URL.
function editColors(src,mapper){let out='',i=0;
 while(i<src.length){
  if(src.startsWith('//',i)){let end=src.indexOf('\n',i);if(end<0)end=src.length;out+=src.slice(i,end);i=end;continue;}
  if(src.startsWith('/*',i)){let end=i+2,depth=1;while(end<src.length&&depth){if(src.startsWith('/*',end)){depth++;end+=2;}else if(src.startsWith('*/',end)){depth--;end+=2;}else end++;}out+=src.slice(i,end);i=end;continue;}
  if(src[i]==='"'||src[i]==="'"){const q=src[i];const triple=src.startsWith(q.repeat(3),i);const raw=i>0&&src[i-1]==='r'&&(i<2||!/[\w$]/.test(src[i-2]));const delim=triple?q.repeat(3):q;let end=i+delim.length;while(end<src.length){if(!raw&&src[end]==='\\'){end+=2;continue;}if(src.startsWith(delim,end)){end+=delim.length;break;}end++;}out+=src.slice(i,end);i=end;continue;}
  const match=src.slice(i).match(/^Color\s*\(\s*0x([\da-fA-F]{8})\s*\)/);
  if(match&&(i===0||!/[\w$]/.test(src[i-1]))){out+=match[0].replace(match[1],mapper(match[1].toUpperCase()));i+=match[0].length;continue;}
  out+=src[i++];
 }
 return out;
}
const files=[];
function scan(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,entry.name);if(entry.isDirectory())scan(p);else if(entry.isFile()&&entry.name.endsWith('.dart'))files.push(p);}}
scan(lib);
const changes=[];
for(const file of files){
 const rel=path.relative(root,file).replaceAll('\\','/');
 const original=fs.readFileSync(file,'utf8');let updated=editColors(original,recolor);
 if(rel.endsWith('/core/theme/app_theme.dart')){
  const start=updated.indexOf('class AppColors');const end=updated.indexOf('class AppSpacing',start);
  if(start<0||end<0)throw Error('Tema diferente do esperado. Nenhum arquivo alterado.');
  let block=updated.slice(start,end);
  for(const [name,hex] of Object.entries(themeValues)){
   const re=new RegExp('(static\\s+const\\s+'+name+'\\s*=\\s*Color\\s*\\(\\s*0x)[0-9a-fA-F]{8}(\\s*\\))');
   if(!re.test(block))throw Error('Token de tema diferente: '+name+'. Nenhum arquivo alterado.');
   block=block.replace(re,(_,a,b)=>a+'FF'+hex+b);
  }
  updated=updated.slice(0,start)+block+updated.slice(end);
 }
 // Mechanical proof: every non-color byte remains identical, including all handlers.
 if(editColors(original,()=> '00000000')!==editColors(updated,()=> '00000000'))throw Error('Alteracao fora das cores detectada: '+rel);
 if(updated!==original)changes.push({file,rel,original,updated});
}
if(!files.some(f=>f.endsWith(path.join('core','theme','app_theme.dart'))))throw Error('Tema principal nao encontrado.');
fs.mkdirSync(backup,{recursive:true});
for(const c of changes){const dest=path.join(backup,c.rel);fs.mkdirSync(path.dirname(dest),{recursive:true});fs.copyFileSync(c.file,dest);}
fs.writeFileSync(path.join(backup,'files.json'),JSON.stringify(changes.map(c=>c.rel)));
try{for(const c of changes)fs.writeFileSync(c.file,c.updated,'utf8');}catch(e){for(const c of changes)fs.copyFileSync(path.join(backup,c.rel),c.file);throw e;}
console.log(`Paleta Porto Prime aplicada em ${changes.length} arquivos. Somente valores de Color foram alterados.`);
console.log(`Backup: ${backup}`);
