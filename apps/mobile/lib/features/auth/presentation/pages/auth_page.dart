import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class AuthPage extends StatefulWidget { const AuthPage({super.key}); @override State<AuthPage> createState()=>_AuthPageState(); }
class _AuthPageState extends State<AuthPage> {
 bool register=false,busy=false; String role='CUSTOMER'; String? error;
 final name=TextEditingController(),email=TextEditingController(),password=TextEditingController(),phone=TextEditingController(),business=TextEditingController(),document=TextEditingController();
 Future<void> submit() async {setState(()=>{busy=true,error=null});try{if(register){await AppState.instance.register(name:name.text,email:email.text,password:password.text,phone:phone.text,role:role,businessName:business.text,document:document.text);if(role!='CUSTOMER'&&mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Cadastro enviado. Sua conta ficará disponível após aprovação.')));}}else{await AppState.instance.login(email.text,password.text);}if(mounted)Navigator.pop(context);}catch(e){setState(()=>error=e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:AppColors.canvas,appBar:AppBar(backgroundColor:Colors.transparent,title:Text(register?'Criar sua conta':'Entrar na Porto Prime')),body:ListView(padding:const EdgeInsets.all(22),children:[
 Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.primaryDark,AppColors.primary]),borderRadius:BorderRadius.circular(30)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('PORTO PRIME',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,letterSpacing:1)),SizedBox(height:8),Text('Bebidas, praia e conveniência.\nTudo no seu ritmo.',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900,height:1.1))])),
 const SizedBox(height:20),
 if(register)...[
 TextField(controller:name,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'Nome completo',prefixIcon:Icon(Icons.person_outline_rounded))),const SizedBox(height:12),
 TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Telefone',prefixIcon:Icon(Icons.phone_outlined))),const SizedBox(height:16),
 const Text('Como você vai usar a Porto Prime?',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:9),
 Wrap(spacing:8,children:[for(final r in const [('CUSTOMER','Cliente'),('COURIER','Motoboy'),('PARTNER','Parceiro')])ChoiceChip(label:Text(r.$2),selected:role==r.$1,onSelected:(_)=>setState(()=>role=r.$1))]),const SizedBox(height:12),
 if(role=='PARTNER')... [TextField(controller:business,decoration:const InputDecoration(labelText:'Nome do estabelecimento',prefixIcon:Icon(Icons.storefront_outlined))),const SizedBox(height:12)],
 if(role!='CUSTOMER')... [TextField(controller:document,decoration:InputDecoration(labelText:role=='COURIER'?'Documento do motoboy':'CPF/CNPJ do parceiro',prefixIcon:const Icon(Icons.badge_outlined))),const SizedBox(height:12)],
 ],
 TextField(controller:email,keyboardType:TextInputType.emailAddress,autocorrect:false,decoration:const InputDecoration(labelText:'E-mail',prefixIcon:Icon(Icons.mail_outline_rounded))),const SizedBox(height:12),
 TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Senha',prefixIcon:Icon(Icons.lock_outline_rounded))),if(error!=null)...[const SizedBox(height:12),Text(error!,style:const TextStyle(color:Colors.red,fontWeight:FontWeight.w600))],const SizedBox(height:18),
 FilledButton(onPressed:busy?null:submit,style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(56)),child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(register?'Criar conta':'Entrar',style:const TextStyle(fontWeight:FontWeight.w900))),
 TextButton(onPressed:busy?null:()=>setState(()=>register=!register),child:Text(register?'Já tenho conta • Entrar':'Ainda não tenho conta • Cadastrar')),
 ]));
}
