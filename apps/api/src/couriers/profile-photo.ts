import { BadRequestException } from '@nestjs/common';
export function validateProfilePhoto(raw: unknown): string {
  const invalid = () => new BadRequestException('Escolha uma foto JPEG ou PNG de até 60 KB e 1024 × 1024 pixels.');
  if (typeof raw !== 'string' || raw.length > 83000) throw invalid();
  const match = /^data:image\/(jpeg|png);base64,([A-Za-z0-9+/]+={0,2})$/.exec(raw);
  if (!match) throw invalid();
  const data = Buffer.from(match[2], 'base64');
  if (data.length < 24 || data.length > 60*1024 || data.toString('base64') !== match[2]) throw invalid();
  let width=0,height=0;
  if (match[1] === 'png') {
    if (!data.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])) || data.toString('ascii',12,16)!=='IHDR' || data.length<33 || data.toString('ascii',data.length-8,data.length-4)!=='IEND') throw invalid();
    width=data.readUInt32BE(16);height=data.readUInt32BE(20);
  } else {
    if (data[0]!==255 || data[1]!==216 || data[data.length-2]!==255 || data[data.length-1]!==217) throw invalid();
    let position=2;
    while(position+4<data.length){
      if(data[position++]!==255) break;
      while(data[position]===255)position++;
      const marker=data[position++];
      if(marker===218||marker===217)break;
      if(position+2>data.length)break;
      const length=data.readUInt16BE(position);
      if(length<2||position+length>data.length)break;
      if([192,193,194].includes(marker)&&length>=8){height=data.readUInt16BE(position+3);width=data.readUInt16BE(position+5);break;}
      position+=length;
    }
  }
  if(width<1||height<1||width>1024||height>1024)throw invalid();
  return `data:image/${match[1]};base64,${data.toString('base64')}`;
}
