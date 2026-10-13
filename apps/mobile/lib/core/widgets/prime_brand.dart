import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';

/// Porto Prime vector identity. Decorative only, never consumes pointer events.
class PrimeBrandMark extends StatelessWidget {
 const PrimeBrandMark({super.key,this.size=42,this.dark=false});
 final double size;final bool dark;
 @override Widget build(BuildContext context)=>ExcludeSemantics(child:Container(width:size,height:size,decoration:BoxDecoration(color:dark?AppColors.ocean900:AppColors.sun500,borderRadius:BorderRadius.circular(size*.32)),child:CustomPaint(painter:_BrandMarkPainter(dark?Colors.white:AppColors.ocean900))));
}
class _BrandMarkPainter extends CustomPainter {
 const _BrandMarkPainter(this.color);final Color color;
 @override void paint(Canvas canvas,Size size){final stroke=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=size.width*.065..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;final p=Path()..moveTo(size.width*.34,size.height*.66)..lineTo(size.width*.34,size.height*.24)..lineTo(size.width*.56,size.height*.24)..cubicTo(size.width*.78,size.height*.24,size.width*.78,size.height*.49,size.width*.56,size.height*.49)..lineTo(size.width*.34,size.height*.49);canvas.drawPath(p,stroke);final wave=Path()..moveTo(size.width*.22,size.height*.76)..cubicTo(size.width*.39,size.height*.63,size.width*.57,size.height*.86,size.width*.78,size.height*.70);canvas.drawPath(wave,stroke);}
 @override bool shouldRepaint(covariant _BrandMarkPainter old)=>old.color!=color;
}
class PrimeCoastArtwork extends StatelessWidget {
 const PrimeCoastArtwork({super.key});
 @override Widget build(BuildContext context)=>const ExcludeSemantics(child:IgnorePointer(child:CustomPaint(painter:_CoastPainter())));
}
class _CoastPainter extends CustomPainter {
 const _CoastPainter();
 @override void paint(Canvas canvas,Size size){
  canvas.drawCircle(Offset(size.width*.90,size.height*.08),size.shortestSide*.27,Paint()..color=AppColors.sun500.withValues(alpha:.96));
  for(var i=0;i<6;i++){final path=Path()..moveTo(size.width*.53,size.height*(.16+i*.11));path.cubicTo(size.width*.75,size.height*(-.12+i*.13),size.width*.62,size.height*(.70+i*.04),size.width*1.06,size.height*(.60+i*.09));canvas.drawPath(path,Paint()..style=PaintingStyle.stroke..strokeWidth=(i==0?24:1.2)..color=(i==0?AppColors.ocean500.withValues(alpha:.18):Colors.white.withValues(alpha:.13)));}
  for(var i=0;i<3;i++){canvas.drawCircle(Offset(size.width*(.82+i*.06),size.height*.83),2.2,Paint()..color=Colors.white.withValues(alpha:.3));}
 }
 @override bool shouldRepaint(covariant _CoastPainter old)=>false;
}
class PrimeEditorialHeader extends StatelessWidget {
 const PrimeEditorialHeader({super.key,required this.title,required this.subtitle,required this.icon,this.eyebrow='PORTO PRIME'});
 final String title,subtitle,eyebrow;final IconData icon;
 @override
 Widget build(BuildContext context) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
  decoration: BoxDecoration(color: AppColors.surface,
   borderRadius: BorderRadius.circular(AppRadius.xl),
   border: Border.all(color: AppColors.stroke)),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
   Container(width: 48, height: 48,
    decoration: BoxDecoration(color: AppColors.ocean900,
     borderRadius: BorderRadius.circular(16)),
    child: Icon(icon, color: AppColors.sun500, size: 24)),
   const SizedBox(width: 14),
   Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(eyebrow, style: const TextStyle(color: AppColors.ocean700,
     fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
    const SizedBox(height: 7),
    Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
     fontSize: 24, height: 1.15, letterSpacing: -.7)),
    const SizedBox(height: 8),
    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
   ])),
  ]),
 );
}
class PrimePageIntro extends StatelessWidget {
 const PrimePageIntro({super.key,required this.title,required this.subtitle,required this.icon,this.label='PORTO PRIME'});
 final String title,subtitle,label;final IconData icon;
 @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontSize:10,color:AppColors.ocean700,fontWeight:FontWeight.w800,letterSpacing:1.2)),const SizedBox(height:7),Text(title,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize:26,height:1.2,letterSpacing:-.8)),const SizedBox(height:8),Text(subtitle,style:const TextStyle(fontSize:13,color:AppColors.muted,height:1.6))])),const SizedBox(width:16),Container(width:48,height:48,decoration:BoxDecoration(color:AppColors.sand100,borderRadius:BorderRadius.circular(16)),child:Icon(icon,size:23,color:AppColors.ocean900))]));
}

class PrimeBalancePanel extends StatelessWidget {
 const PrimeBalancePanel({super.key,required this.label,required this.value,required this.note,required this.icon,this.footer});
 final String label,value,note;final IconData icon;final Widget? footer;
 @override Widget build(BuildContext context)=>Container(width:double.infinity,padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:AppColors.ocean900,borderRadius:BorderRadius.circular(AppRadius.xl)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(fontSize:10,letterSpacing:1.1,fontWeight:FontWeight.w800,color:AppColors.ocean300))),Container(width:38,height:38,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.1),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:AppColors.sun500,size:20))]),const SizedBox(height:12),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(value,style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1))),const SizedBox(height:9),Text(note,style:const TextStyle(color:Colors.white70,fontSize:12,height:1.6)),if(footer!=null)...[const SizedBox(height:20),footer!]]));
}
class PrimePaymentCard extends StatelessWidget {
 const PrimePaymentCard({super.key,required this.name,required this.code,required this.balance,this.loading=false,this.onCopy});
 final String name,code,balance;final bool loading;final VoidCallback? onCopy;
 @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(28),child:ColoredBox(color:AppColors.ocean900,child:Stack(children:[const Positioned.fill(child:PrimeCoastArtwork()),Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const PrimeBrandMark(size:36),const SizedBox(width:11),const Expanded(child:Text('PORTO PRIME',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,letterSpacing:1.4,fontSize:13))),Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:AppColors.sun500,borderRadius:BorderRadius.circular(7)),child:const Text('SEU SALDO',style:TextStyle(color:AppColors.ocean900,fontSize:8,fontWeight:FontWeight.w800,letterSpacing:.7)))]),const SizedBox(height:28),const Text('Disponível para suas próximas compras',style:TextStyle(color:Colors.white70,fontSize:11)),const SizedBox(height:8),if(loading)const LinearProgressIndicator()else FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(balance,style:const TextStyle(color:Colors.white,fontSize:36,fontWeight:FontWeight.w800,letterSpacing:-1))),const SizedBox(height:27),Wrap(spacing:10,crossAxisAlignment:WrapCrossAlignment.center,children:[Text(code.isEmpty?'Atualizando seu cartão…':code,style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w700,letterSpacing:1.5)),if(onCopy!=null)IconButton(tooltip:'Copiar código do cartão',onPressed:onCopy,icon:const Icon(AppIcons.copy,color:Colors.white70,size:18))]),Text(name,style:const TextStyle(color:Colors.white70,fontSize:12))]))])));
}
