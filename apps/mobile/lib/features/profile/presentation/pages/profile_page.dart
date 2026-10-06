import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/state/app_state.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import 'registration_page.dart';

class ProfilePage extends StatelessWidget{const ProfilePage({super.key});@override Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__)=>AppState.instance.loggedIn?const _Account():const _Guest());}

class _Guest extends StatefulWidget {
  const _Guest();
  @override
  State<_Guest> createState() => _GuestState();
}

class _GuestState extends State<_Guest> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _rise = Tween<Offset>(begin: const Offset(0, .045), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        Text('Seu espaço', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => _accountMenu(context),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15211F), Color(0xFF29403B)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: AppColors.mint,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.oceanDeep,
                    size: 31,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, seja bem-vindo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Entre para viver a experiência completa',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _OldQuick(
                'Pedidos',
                Icons.receipt_long_rounded,
                () => _accountMenu(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OldQuick(
                'Endereços',
                Icons.near_me_rounded,
                () => _accountMenu(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OldQuick(
                'Favoritos',
                Icons.favorite_rounded,
                () => _accountMenu(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Sua conta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        _OldMenu(
          'Pagamentos',
          Icons.credit_card_rounded,
          'Carteiras e cartões',
          () => _accountMenu(context),
        ),
        _OldMenu(
          'Notificações',
          Icons.notifications_none_rounded,
          'Escolha o que receber',
          () => _simpleMessage(
            context,
            'Notificações',
            'Entre na sua conta para configurar as notificações.',
          ),
        ),
        _OldMenu(
          'Ajuda',
          Icons.support_agent_rounded,
          'Fale com a Porto Prime',
          () => _support(context),
        ),
        _OldMenu(
          'Privacidade',
          Icons.shield_outlined,
          'Seus dados e segurança',
          () => _simpleMessage(
            context,
            'Privacidade',
            'Seus dados são usados para sua conta, pedidos e entregas.',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(23),
          ),
          child: const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: AppColors.sun),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Feito para dias de sol, noites longas e brindes em Porto Seguro.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OldQuick extends StatelessWidget {
  const _OldQuick(this.label, this.icon, this.tap);
  final String label;
  final IconData icon;
  final VoidCallback tap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(21),
    child: Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE9ECE7)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.oceanDeep, size: 24),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _OldMenu extends StatelessWidget {
  const _OldMenu(this.title, this.icon, this.subtitle, this.tap);
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback tap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.oceanDeep, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

Future<void> _accountMenu(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _Sheet(
      title: 'Sua Porto Prime',
      subtitle: 'Entre ou escolha o tipo de conta que deseja criar.',
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _auth(context);
            },
            child: const Text('Entrar na minha conta'),
          ),
        ),
        const SizedBox(height: 10),
        _Role(
          'Cliente',
          'Peça, pague e acompanhe sua entrega.',
          Icons.shopping_bag_outlined,
          AppColors.sand,
          () {
            Navigator.pop(ctx);
            _register(context, 'CUSTOMER');
          },
        ),
        _Role(
          'Motoboy',
          'Faça sua candidatura para realizar entregas.',
          Icons.delivery_dining_outlined,
          AppColors.mint,
          () {
            Navigator.pop(ctx);
            _register(context, 'COURIER');
          },
        ),
        _Role(
          'Parceiro',
          'Divulgue a Porto Prime e acompanhe sua parceria.',
          Icons.storefront_outlined,
          AppColors.lavender,
          () {
            Navigator.pop(ctx);
            _register(context, 'PARTNER');
          },
        ),
      ],
    ),
  );
}

void _simpleMessage(BuildContext context, String title, String message) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

class _PrimeMark extends StatelessWidget {
  const _PrimeMark();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.turquoise]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 19)),
      const SizedBox(width: 10),
      const Text('PORTO PRIME', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.8)),
    ],
  );
}

class _Role extends StatelessWidget{const _Role(this.a,this.b,this.i,this.c,this.tap);final String a,b;final IconData i;final Color c;final VoidCallback tap;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),child:GestureDetector(behavior:HitTestBehavior.opaque,onTap:tap,child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(24),border:Border.all(color:AppColors.stroke)),child:Row(children:[Container(width:54,height:54,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(18)),child:Icon(i,color:AppColors.ink,size:25)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800,letterSpacing:-.2)),const SizedBox(height:3),Text(b,style:const TextStyle(fontSize:10,height:1.35,color:AppColors.muted,fontWeight:FontWeight.w600))])),const Icon(Icons.arrow_forward_rounded,size:18,color:AppColors.muted)]))));}

Future<void> _auth(BuildContext context)async{final e=TextEditingController(),p=TextEditingController();await showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>_Sheet(title:'Entrar na Porto Prime',children:[
 _field(e,'E-mail',Icons.mail_outline_rounded,type:TextInputType.emailAddress),_field(p,'Senha',Icons.lock_outline_rounded,secret:true),_submit(ctx,'Entrar',()async{await AppState.instance.login(e.text,p.text);if(ctx.mounted)Navigator.pop(ctx);}),TextButton(onPressed:(){Navigator.pop(ctx);_passwordRecovery(context);},child:const Text('Esqueci minha senha'))
]));}

Future<void> _register(BuildContext context,String role) async {
  await Navigator.of(context).push(_primeRoute(RegistrationPage(role: role)));
}

Widget _field(TextEditingController c,String label,IconData i,{bool secret=false,TextInputType? type})=>Padding(padding:const EdgeInsets.only(bottom:11),child:TextField(controller:c,obscureText:secret,keyboardType:type,style:const TextStyle(fontSize:16),decoration:InputDecoration(labelText:label,prefixIcon:Icon(i,color:AppColors.oceanDeep),filled:true,fillColor:AppColors.canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(17),borderSide:BorderSide.none))));
Widget _submit(BuildContext ctx,String label,Future<void> Function() go)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__)=>Column(children:[if(AppState.instance.error!=null)Padding(padding:const EdgeInsets.only(bottom:9),child:Text(AppState.instance.error!,style:const TextStyle(color:Colors.red,fontSize:11))),SizedBox(width:double.infinity,height:54,child:FilledButton(onPressed:AppState.instance.loading?null:()async{try{await go();}catch(_){}},style:FilledButton.styleFrom(backgroundColor:AppColors.oceanDeep),child:AppState.instance.loading?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):Text(label,style:const TextStyle(fontWeight:FontWeight.w900))))]));

class _Sheet extends StatelessWidget{const _Sheet({required this.title,this.subtitle,required this.children});final String title;final String? subtitle;final List<Widget> children;@override Widget build(BuildContext context)=>Container(padding:EdgeInsets.fromLTRB(20,12,20,24+MediaQuery.viewInsetsOf(context).bottom),decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(34))),child:SafeArea(top:false,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Center(child:Container(width:42,height:4,margin:const EdgeInsets.only(bottom:16),decoration:BoxDecoration(color:const Color(0xFFD8DDDA),borderRadius:BorderRadius.circular(20)))),Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:23,fontWeight:FontWeight.w900,letterSpacing:-.5))),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded))]),if(subtitle!=null)...[Text(subtitle!,style:const TextStyle(color:AppColors.muted,fontSize:11)),const SizedBox(height:15)]else const SizedBox(height:10),...children]))));}

class _Account extends StatelessWidget{const _Account();@override Widget build(BuildContext context){final s=AppState.instance,u=s.user!,pending=u['status']=='PENDING';return SafeArea(bottom:false,child:ListView(padding:const EdgeInsets.fromLTRB(20,22,20,120),children:[
 Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Sua conta',style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:5),const Text('Tudo da Porto Prime em um só lugar.',style:TextStyle(color:AppColors.muted,fontWeight:FontWeight.w600))])),Container(width:46,height:46,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.notifications_none_rounded,color:AppColors.oceanDeep))]),const SizedBox(height:22),Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF12211E),Color(0xFF173B35)]),borderRadius:BorderRadius.circular(30),boxShadow:const [BoxShadow(color:Color(0x18000000),blurRadius:24,offset:Offset(0,12))]),child:Column(children:[Row(children:[Container(width:62,height:62,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(22)),child:const Icon(Icons.person_rounded,size:31,color:AppColors.oceanDeep)),const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(u['name']??'',style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w900,letterSpacing:-.3)),const SizedBox(height:3),Text(u['email']??'',style:const TextStyle(color:Colors.white60,fontSize:12,fontWeight:FontWeight.w600))])),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.10),borderRadius:BorderRadius.circular(12)),child:const Text('PRIME',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900,letterSpacing:1.2)))]),const SizedBox(height:18),Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:11),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.07),borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.verified_rounded,color:Color(0xFFFFC65C),size:18),SizedBox(width:9),Expanded(child:Text('Conta verificada • Porto Seguro',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700))),Icon(Icons.chevron_right_rounded,color:Colors.white54,size:18)]))])),
 if(pending)...[const SizedBox(height:14),Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(21)),child:const Row(children:[Icon(Icons.hourglass_top_rounded,color:AppColors.coral),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Cadastro em análise',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Você poderá acessar a área operacional após aprovação do administrador.',style:TextStyle(fontSize:10,color:AppColors.muted))]))]))],
 if(s.isCustomer)...[const SizedBox(height:25),const Text('Minha Porto Prime',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,letterSpacing:-.3)),const SizedBox(height:11),Material(color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(25),side:const BorderSide(color:Color(0xFFE9ECE8))),clipBehavior:Clip.antiAlias,child:Column(children:[_line('Meus pedidos','Acompanhe e consulte seu histórico',Icons.receipt_long_rounded,()=>_orders(context)),const Divider(height:1,indent:68,endIndent:18),_line('Endereços','Gerencie seus locais de entrega',Icons.location_on_rounded,()=>_addresses(context)),const Divider(height:1,indent:68,endIndent:18),_line('Ajuda e suporte','Central de atendimento Porto Prime',Icons.support_agent_rounded,()=>_support(context))]))],
 const SizedBox(height:24),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(24)),child:const Row(children:[Icon(Icons.bolt_rounded,color:AppColors.oceanDeep),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Entrega do seu jeito',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Rápida, gelada e acompanhada em tempo real.',style:TextStyle(fontSize:10,color:AppColors.muted,fontWeight:FontWeight.w600))]))])),const SizedBox(height:18),SizedBox(height:52,child:OutlinedButton.icon(style:OutlinedButton.styleFrom(foregroundColor:AppColors.oceanDeep,side:const BorderSide(color:Color(0xFFCAD3CF)),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),onPressed:()=>s.logout(),icon:const Icon(Icons.logout_rounded,size:20),label:const Text('Sair da conta',style:TextStyle(fontWeight:FontWeight.w800)))),
]));}}

Widget _line(String a,String b,IconData i,VoidCallback tap)=>ListTile(onTap:tap,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:7),leading:Container(width:40,height:40,decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(13)),child:Icon(i,color:AppColors.oceanDeep,size:21)),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:14)),subtitle:Padding(padding:const EdgeInsets.only(top:2),child:Text(b,style:const TextStyle(color:AppColors.muted,fontSize:9,fontWeight:FontWeight.w600))),trailing:const Icon(Icons.chevron_right_rounded,color:AppColors.muted,size:21));

void _passwordRecovery(BuildContext context) {
  final email = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _Sheet(
      title: 'Recuperar senha',
      subtitle: 'Informe o e-mail cadastrado na Porto Prime.',
      children: [
        _field(email, 'E-mail', Icons.mail_outline_rounded, type: TextInputType.emailAddress),
        _submit(ctx, 'Continuar', () async {
          final r = await AppState.instance.forgotPassword(email.text);
          if (ctx.mounted) {
            Navigator.pop(ctx);
            final message = r['resetToken'] != null
                ? 'Solicitação criada. Use o token de desenvolvimento para redefinir sua senha.'
                : 'Se o e-mail estiver cadastrado, enviaremos as instruções.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        }),
      ],
    ),
  );
}

void _orders(BuildContext context){Navigator.of(context).push(_primeRoute(const OrdersPage()));}

Route<T> _primeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 300),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  pageBuilder: (_, animation, __) => page,
  transitionsBuilder: (_, animation, __, child) {
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(.035, 0), end: Offset.zero).animate(fade);
    return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
  },
);
void _addresses(BuildContext context){showModalBottomSheet(context:context,isScrollControlled:true,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('Endereços',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:10),Expanded(child:ListView(children:AppState.instance.addresses.map((a)=>ListTile(leading:const Icon(Icons.location_on_outlined),title:Text((a['street']??'')+', '+(a['number']??'')),subtitle:Text(a['neighborhood']??''))).toList())),FilledButton(onPressed:()=>_newAddress(c),child:const Text('Adicionar endereço'))]))));}
void _newAddress(BuildContext context){final st=TextEditingController(),no=TextEditingController(),ne=TextEditingController(),cep=TextEditingController();showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('Novo endereço'),content:SingleChildScrollView(child:Column(children:[_field(st,'Rua',Icons.route),_field(no,'Número',Icons.numbers),_field(ne,'Bairro',Icons.map_outlined),_field(cep,'CEP',Icons.local_post_office_outlined)])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:()async{try{await AppState.instance.addAddress({'street':st.text,'number':no.text,'neighborhood':ne.text,'city':'Porto Seguro','state':'BA','postalCode':cep.text,'isDefault':true});if(c.mounted)Navigator.pop(c);}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(e.toString())));}},child:const Text('Salvar'))]));}

void _support(BuildContext context){showModalBottomSheet(context:context,builder:(c)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Como podemos ajudar?',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:5),const Text('Escolha o assunto. O histórico do seu pedido fica disponível em Meus pedidos.',style:TextStyle(color:AppColors.muted,fontSize:11)),const SizedBox(height:15),_supportLine(Icons.receipt_long_rounded,'Problema com um pedido'),_supportLine(Icons.payments_outlined,'Pagamento ou cobrança'),_supportLine(Icons.person_outline_rounded,'Minha conta'),_supportLine(Icons.info_outline_rounded,'Dúvidas sobre a Porto Prime'),const SizedBox(height:8)]))));}
Widget _supportLine(IconData i,String text)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Material(color:AppColors.canvas,borderRadius:BorderRadius.circular(17),clipBehavior:Clip.antiAlias,child:ListTile(leading:Icon(i,color:AppColors.oceanDeep),title:Text(text,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),trailing:const Icon(Icons.chevron_right_rounded,size:18))));
