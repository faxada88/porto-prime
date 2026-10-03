import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/state/app_state.dart';

class ProfilePage extends StatelessWidget{const ProfilePage({super.key});@override Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__)=>AppState.instance.loggedIn?const _Account():const _Guest());}

class _Guest extends StatelessWidget{const _Guest();@override Widget build(BuildContext context)=>SafeArea(bottom:false,child:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,120),children:[
 Text('Tudo seu.\\nDo seu jeito.',style:Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize:35,height:.98,letterSpacing:-1.4)),const SizedBox(height:10),const Text('Entre para acompanhar pedidos ou escolha como quer fazer parte da Porto Prime.',style:TextStyle(color:AppColors.muted,fontSize:13,height:1.4,fontWeight:FontWeight.w600)),const SizedBox(height:24),
 Container(padding:const EdgeInsets.all(21),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF15302B),Color(0xFF08786D)]),borderRadius:BorderRadius.circular(28)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:Colors.white.withValues(alpha:.12),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.person_rounded,color:Colors.white,size:26)),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.10),borderRadius:BorderRadius.circular(12)),child:const Text('JÁ SOU PRIME',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:.8)))]),const SizedBox(height:20),const Text('Bem-vindo de volta',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.4)),const SizedBox(height:5),const Text('Pedidos, endereços e sua conta em um só lugar.',style:TextStyle(color:Colors.white70,fontSize:12)),
  const SizedBox(height:17),SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:AppColors.oceanDeep,padding:const EdgeInsets.all(15)),onPressed:()=>_auth(context),child:const Text('Entrar na minha conta',style:TextStyle(fontWeight:FontWeight.w900)))),
 ])),const SizedBox(height:28),const Text('Comece por aqui',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900,letterSpacing:-.4)),const SizedBox(height:4),const Text('Escolha o perfil que combina com você.',style:TextStyle(fontSize:11,color:AppColors.muted,fontWeight:FontWeight.w600)),const SizedBox(height:13),
 _Role('Cliente','Peça bebidas geladas e acompanhe tudo pelo app.',Icons.shopping_bag_rounded,AppColors.sand,()=>_register(context,'CUSTOMER')),
 _Role('Motoboy','Receba corridas e gerencie sua rotina de entregas.',Icons.delivery_dining_rounded,AppColors.mint,()=>_register(context,'COURIER')),
 _Role('Parceiro','Conecte seus hóspedes à conveniência Porto Prime.',Icons.apartment_rounded,const Color(0xFFFFE1DB),()=>_register(context,'PARTNER')),
]));}

class _Role extends StatelessWidget{const _Role(this.a,this.b,this.i,this.c,this.tap);final String a,b;final IconData i;final Color c;final VoidCallback tap;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(onTap:tap,borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:const Color(0xFFE8EBE6)),boxShadow:const [BoxShadow(color:Color(0x08000000),blurRadius:14,offset:Offset(0,6))]),child:Row(children:[Container(width:58,height:58,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(19)),child:Icon(i,color:AppColors.ink,size:27)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900,letterSpacing:-.2)),const SizedBox(height:3),Text(b,style:const TextStyle(fontSize:10,height:1.35,color:AppColors.muted,fontWeight:FontWeight.w600))])),const Icon(Icons.arrow_forward_rounded,size:19)]))));}

Future<void> _auth(BuildContext context)async{final e=TextEditingController(),p=TextEditingController();await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>_Sheet(title:'Entrar na Porto Prime',children:[
 _field(e,'E-mail',Icons.mail_outline_rounded,type:TextInputType.emailAddress),_field(p,'Senha',Icons.lock_outline_rounded,secret:true),_submit(ctx,'Entrar',()async{await AppState.instance.login(e.text,p.text);if(ctx.mounted)Navigator.pop(ctx);})
]));}

Future<void> _register(BuildContext context,String role)async{final n=TextEditingController(),e=TextEditingController(),ph=TextEditingController(),p=TextEditingController(),doc=TextEditingController(),biz=TextEditingController();final label=role=='CUSTOMER'?'Cliente':role=='COURIER'?'Motoboy':'Parceiro';await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>_Sheet(title:'Criar conta de '+label,subtitle:role=='CUSTOMER'?'Peça, acompanhe entregas e salve seus endereços. Sua conta fica ativa na hora.':'Preencha seus dados com atenção. Seu cadastro será enviado para aprovação.',children:[
 _field(n,'Nome completo',Icons.person_outline_rounded),if(role=='PARTNER')_field(biz,'Nome do estabelecimento',Icons.storefront_rounded),_field(e,'E-mail',Icons.mail_outline_rounded,type:TextInputType.emailAddress),_field(ph,'Telefone',Icons.phone_outlined,type:TextInputType.phone),if(role!='CUSTOMER')_field(doc,role=='COURIER'?'CPF / documento':'CNPJ / documento',Icons.badge_outlined),_field(p,'Senha (mínimo 8 caracteres)',Icons.lock_outline_rounded,secret:true),
 _submit(ctx,'Criar conta',()async{await AppState.instance.register({'name':n.text,'email':e.text,'phone':ph.text,'password':p.text,'role':role,if(role!='CUSTOMER')'document':doc.text,if(role=='PARTNER')'businessName':biz.text});if(ctx.mounted)Navigator.pop(ctx);})
]));}

Widget _field(TextEditingController c,String label,IconData i,{bool secret=false,TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:11),child:TextField(controller:c,obscureText:secret,keyboardType:type,style:const TextStyle(fontSize:16),decoration:InputDecoration(labelText:label,prefixIcon:Icon(i,color:AppColors.oceanDeep),filled:true,fillColor:AppColors.canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(17),borderSide:BorderSide.none))));
Widget _submit(BuildContext ctx,String label,Future<void> Function() go)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__)=>Column(children:[if(AppState.instance.error!=null)Padding(padding:const EdgeInsets.only(bottom:9),child:Text(AppState.instance.error!,style:const TextStyle(color:Colors.red,fontSize:11))),SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:AppState.instance.loading?null:()async{try{await go();}catch(_){}},style:FilledButton.styleFrom(backgroundColor:AppColors.oceanDeep),child:AppState.instance.loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(label,style:const TextStyle(fontWeight:FontWeight.w900))))]));

class _Sheet extends StatelessWidget{const _Sheet({required this.title,this.subtitle,required this.children});final String title;final String? subtitle;final List<Widget> children;@override Widget build(BuildContext context)=>Container(padding:EdgeInsets.fromLTRB(20,12,20,24+MediaQuery.viewInsetsOf(context).bottom),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(34))),child:SafeArea(top:false,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Center(child:Container(width:42,height:4,margin:const EdgeInsets.only(bottom:16),decoration:BoxDecoration(color:const Color(0xFFD8DDDA),borderRadius:BorderRadius.circular(20)))),Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.5))),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded))]),if(subtitle!=null)...[Text(subtitle!,style:const TextStyle(color:AppColors.muted,fontSize:11)),const SizedBox(height:15)]else const SizedBox(height:10),...children]))));}

class _Account extends StatelessWidget{const _Account();@override Widget build(BuildContext context){final s=AppState.instance,u=s.user!,pending=u['status']=='PENDING';return SafeArea(bottom:false,child:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,120),children:[
 Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Sua conta',style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:5),const Text('Tudo da Porto Prime em um só lugar.',style:TextStyle(color:AppColors.muted,fontWeight:FontWeight.w600))])),Container(width:46,height:46,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.notifications_none_rounded,color:AppColors.oceanDeep))]),const SizedBox(height:22),Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF12211E),Color(0xFF173B35)]),borderRadius:BorderRadius.circular(30),boxShadow:const [BoxShadow(color:Color(0x18000000),blurRadius:24,offset:Offset(0,12))]),child:Column(children:[Row(children:[Container(width:62,height:62,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(22)),child:const Icon(Icons.person_rounded,size:31,color:AppColors.oceanDeep)),const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(u['name']??'',style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900,letterSpacing:-.3)),const SizedBox(height:3),Text(u['email']??'',style:const TextStyle(color:Colors.white60,fontSize:12,fontWeight:FontWeight.w600))])),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.10),borderRadius:BorderRadius.circular(12)),child:const Text('PRIME',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.2)))]),const SizedBox(height:18),Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.07),borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.verified_rounded,color:Color(0xFFFFC65C),size:18),SizedBox(width:9),Expanded(child:Text('Conta verificada • Porto Seguro',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700))),Icon(Icons.chevron_right_rounded,color:Colors.white54,size:18)]))])),
 if(pending)...[const SizedBox(height:14),Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(21)),child:const Row(children:[Icon(Icons.hourglass_top_rounded,color:AppColors.coral),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Cadastro em análise',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Você poderá acessar a área operacional após aprovação do administrador.',style:TextStyle(fontSize:10,color:AppColors.muted))]))]))],
 if(s.isCustomer)...[const SizedBox(height:25),const Text('Minha Porto Prime',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,letterSpacing:-.3)),const SizedBox(height:11),Material(color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(25),side:const BorderSide(color:Color(0xFFE9ECE8))),clipBehavior:Clip.antiAlias,child:Column(children:[_line('Meus pedidos','Acompanhe e consulte seu histórico',Icons.receipt_long_rounded,()=>_orders(context)),const Divider(height:1,indent:68,endIndent:18),_line('Endereços','Gerencie seus locais de entrega',Icons.location_on_rounded,()=>_addresses(context)),const Divider(height:1,indent:68,endIndent:18),_line('Pagamentos','Status e pagamentos dos seus pedidos',Icons.credit_card_rounded,()=>_payments(context)),const Divider(height:1,indent:68,endIndent:18),_line('Ajuda e suporte','Central de atendimento Porto Prime',Icons.support_agent_rounded,()=>_support(context))]))],
 const SizedBox(height:24),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(24)),child:const Row(children:[Icon(Icons.bolt_rounded,color:AppColors.oceanDeep),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Entrega do seu jeito',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Rápida, gelada e acompanhada em tempo real.',style:TextStyle(fontSize:10,color:AppColors.muted,fontWeight:FontWeight.w600))]))])),const SizedBox(height:18),SizedBox(height:52,child:OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:AppColors.oceanDeep,side:const BorderSide(color:Color(0xFFCAD3CF)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),onPressed:()=>s.logout(),icon:const Icon(Icons.logout_rounded,size:20),label:const Text('Sair da conta',style:TextStyle(fontWeight:FontWeight.w800)))),
]));}}

Widget _line(String a,String b,IconData i,VoidCallback tap)=>ListTile(onTap:tap,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),leading:Container(width:40,height:40,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(13)),child:Icon(i,color:AppColors.oceanDeep,size:21)),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14)),subtitle:Padding(padding:const EdgeInsets.only(top:2),child:Text(b,style:const TextStyle(color:AppColors.muted,fontSize:9,fontWeight:FontWeight.w600))),trailing:const Icon(Icons.chevron_right_rounded,color:AppColors.muted,size:21));

void _orders(BuildContext context){showModalBottomSheet(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:AppState.instance.orders.isEmpty?const Center(child:Text('Você ainda não tem pedidos.')):ListView(children:[const Text('Meus pedidos',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:15),...AppState.instance.orders.map((o)=>ListTile(title:Text('Pedido '+o['id'].toString().substring(0,8)),subtitle:Text(o['status'].toString()),trailing:Text('R\$ '+o['total'].toString())))]))));}
void _addresses(BuildContext context){showModalBottomSheet(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('Endereços',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),Expanded(child:ListView(children:AppState.instance.addresses.map((a)=>ListTile(leading:const Icon(Icons.location_on_outlined),title:Text((a['street']??'')+', '+(a['number']??'')),subtitle:Text(a['neighborhood']??''))).toList())),FilledButton(onPressed:()=>_newAddress(c),child:const Text('Adicionar endereço'))]))));}
void _newAddress(BuildContext context){final st=TextEditingController(),no=TextEditingController(),ne=TextEditingController(),cep=TextEditingController();showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Novo endereço'),content:SingleChildScrollView(child:Column(children:[_field(st,'Rua',Icons.route),_field(no,'Número',Icons.numbers),_field(ne,'Bairro',Icons.map_outlined),_field(cep,'CEP',Icons.local_post_office_outlined)])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:()async{try{await AppState.instance.addAddress({'street':st.text,'number':no.text,'neighborhood':ne.text,'city':'Porto Seguro','state':'BA','postalCode':cep.text,'isDefault':true});if(c.mounted)Navigator.pop(c);}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('Salvar'))]));}


void _payments(BuildContext context) {
  final orders = AppState.instance.orders;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagamentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Acompanhe o status financeiro dos seus pedidos.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 14),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('Nenhum pagamento por aqui ainda.'))
                  : ListView.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        final paid = o['paymentStatus'] == 'PAID';
                        final id = o['id'].toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: paid ? AppColors.mint : AppColors.sand,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              paid ? Icons.check_rounded : Icons.schedule_rounded,
                              color: AppColors.oceanDeep,
                            ),
                          ),
                          title: Text(
                            'Pedido ${id.length > 8 ? id.substring(0, 8) : id}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          subtitle: Text(
                            paid ? 'Pagamento confirmado' : 'Pagamento pendente',
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: Text(
                            'R\$ ${o['total']}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _support(BuildContext context){showModalBottomSheet(context:context,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Como podemos ajudar?',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Escolha o assunto. O histórico do seu pedido fica disponível em Meus pedidos.',style:TextStyle(color:AppColors.muted,fontSize:11)),const SizedBox(height:15),_supportLine(Icons.receipt_long_rounded,'Problema com um pedido'),_supportLine(Icons.payments_outlined,'Pagamento ou cobrança'),_supportLine(Icons.person_outline_rounded,'Minha conta'),_supportLine(Icons.info_outline_rounded,'Dúvidas sobre a Porto Prime'),const SizedBox(height:8)]))));}
Widget _supportLine(IconData i,String text)=>Container(margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:AppColors.canvas,borderRadius:BorderRadius.circular(17)),child:ListTile(leading:Icon(i,color:AppColors.oceanDeep),title:Text(text,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),trailing:const Icon(Icons.chevron_right_rounded,size:18)));
