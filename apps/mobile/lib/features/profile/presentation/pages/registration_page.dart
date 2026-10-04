import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/motorcycle_catalog.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, required this.role});
  final String role;
  @override State<RegistrationPage> createState()=>_RegistrationPageState();
}
class _RegistrationPageState extends State<RegistrationPage> {
  final forms=List.generate(6, (_)=>GlobalKey<FormState>()); int step=0; bool accepted=false,obscure=true;
  final Map<String,String?> remoteError={}; final Map<String,bool> checking={}; final Map<String,int> validationTicket={};
  GlobalKey<FormState> get form=>forms[step];
  final Map<String,TextEditingController> c={};
  TextEditingController ctl(String k)=>c.putIfAbsent(k,()=>TextEditingController());
  bool get customer=>widget.role=='CUSTOMER'; bool get courier=>widget.role=='COURIER';
  String get title=>customer?'Cliente':courier?'Motoboy':'Parceiro';
  List<List<_F>> get groups=>courier ? courierGroups : commonGroups;
  List<List<_F>> get commonGroups=>[
    [const _F('name','Nome completo',Icons.person_outline_rounded),const _F('cpf','CPF',Icons.badge_outlined,keyboard:TextInputType.number,format:_Format.cpf),const _F('birthDate','Data de nascimento',Icons.cake_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date),const _F('phone','Celular / WhatsApp',Icons.phone_outlined,keyboard:TextInputType.phone,format:_Format.phone)],
    if(!customer)[const _F('businessName','Nome do estabelecimento',Icons.storefront_outlined),const _F('legalName','Razão social',Icons.business_outlined),const _F('cnpj','CNPJ / documento',Icons.badge_outlined,keyboard:TextInputType.number,format:_Format.cnpj),const _F('businessType','Tipo de estabelecimento',Icons.category_outlined,hint:'Hotel, pousada, receptivo...')]
    else [const _F('cep','CEP',Icons.local_post_office_outlined,keyboard:TextInputType.number,format:_Format.cep),const _F('street','Rua / avenida',Icons.route_outlined),const _F('number','Número',Icons.numbers_outlined),const _F('neighborhood','Bairro',Icons.map_outlined),const _F('complement','Complemento',Icons.home_work_outlined,required:false)],
    [const _F('email','E-mail',Icons.mail_outline_rounded,keyboard:TextInputType.emailAddress),const _F('password','Crie uma senha',Icons.lock_outline_rounded,secret:true,hint:'Mínimo de 8 caracteres'),if(courier)const _F('pixKey','Chave PIX para recebimentos',Icons.account_balance_wallet_outlined,required:false),if(!customer&&!courier)const _F('contactRole','Seu cargo / função',Icons.work_outline_rounded,required:false)],
  ];
  List<List<_F>> get courierGroups=>[
    [const _F('name','Nome completo',Icons.person_outline_rounded),const _F('cpf','CPF',Icons.badge_outlined,keyboard:TextInputType.number,format:_Format.cpf),const _F('birthDate','Data de nascimento',Icons.cake_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date)],
    [const _F('phone','Celular / WhatsApp',Icons.phone_outlined,keyboard:TextInputType.phone,format:_Format.phone),const _F('cep','CEP',Icons.local_post_office_outlined,keyboard:TextInputType.number,format:_Format.cep),const _F('street','Rua / avenida',Icons.route_outlined),const _F('number','Número',Icons.numbers_outlined),const _F('neighborhood','Bairro',Icons.map_outlined),const _F('city','Cidade',Icons.location_city_outlined),const _F('state','UF',Icons.map_outlined)],
    [const _F('cnh','Número de registro da CNH',Icons.credit_card_outlined),const _F('cnhCategory','Categoria da CNH',Icons.fact_check_outlined),const _F('cnhExpiry','Validade da CNH',Icons.event_available_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date)],
    [const _F('vehicleType','Tipo de veículo',Icons.commute_rounded),const _F('vehicleBrand','Marca',Icons.two_wheeler_outlined),const _F('vehicleModel','Modelo',Icons.two_wheeler_outlined),const _F('vehicleYear','Ano',Icons.calendar_today_outlined,keyboard:TextInputType.number),const _F('vehiclePlate','Placa',Icons.pin_outlined,format:_Format.plate)],
    [const _F('email','E-mail',Icons.mail_outline_rounded,keyboard:TextInputType.emailAddress),const _F('password','Crie uma senha',Icons.lock_outline_rounded,secret:true,hint:'8+ caracteres, maiúscula, minúscula e número'),const _F('confirmPassword','Confirme sua senha',Icons.lock_reset_rounded,secret:true),const _F('pixKey','Chave PIX para recebimentos',Icons.account_balance_wallet_outlined,required:false)],
    [],
  ];
  @override void dispose(){for(final x in c.values)x.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final total = groups.length;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => step == 0 ? Navigator.pop(context) : setState(() => step--),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conta de $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Etapa ${step + 1} de $total', style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: customer ? AppColors.mint : courier ? AppColors.sand : AppColors.lavender,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(customer ? 'CLIENTE' : courier ? 'MOTOBOY' : 'PARCEIRO', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .7)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: (step + 1) / total, minHeight: 5, backgroundColor: AppColors.stroke, color: AppColors.primary),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(.04, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(step),
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.stroke),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: step == 0 ? AppColors.mint : step == 1 ? AppColors.sand : AppColors.lavender,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(step == 0 ? Icons.person_rounded : step == 1 ? (customer ? Icons.location_on_rounded : courier ? Icons.two_wheeler_rounded : Icons.store_rounded) : Icons.shield_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(height: 18),
                        Text(heading(), style: const TextStyle(fontSize: 27, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                        const SizedBox(height: 8),
                        Text(sub(), style: const TextStyle(fontSize: 11.5, height: 1.5, color: AppColors.muted, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 24),
                        ...groups[step].map(field),
                        if(courier && step==3 && ctl('vehicleBrand').text=='Outra marca') field(const _F('customVehicleBrand','Informe a marca',Icons.edit_rounded)),
                        if(courier && step==3 && ctl('vehicleModel').text=='Outro modelo') field(const _F('customVehicleModel','Informe o modelo',Icons.edit_rounded)),
                        if(courier && step==groups.length-1) reviewCard(),
                        if (step == total - 1) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => setState(() => accepted = !accepted),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: accepted ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: accepted ? AppColors.primary : AppColors.stroke),
                                  ),
                                  child: accepted ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text('Confirmo que os dados informados são verdadeiros e aceito os termos e a política de privacidade.', style: TextStyle(fontSize: 10, height: 1.45, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: AppState.instance.loading ? null : next,
                    child: AppState.instance.loading
                        ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(step == total - 1 ? 'Criar minha conta' : 'Continuar'),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 19),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String heading() {
    if(!courier) return step==0?'Conte um pouco\nsobre você':step==1?(customer?'Onde vamos\nentregar?':'Sobre o seu\nnegócio'):'Seu acesso\nPorto Prime';
    return const ['Dados pessoais','Contato e endereço','Sua CNH','Seu veículo','Segurança','Revise seu cadastro'][step];
  }
  String sub() {
    if(!courier) return step==0?'Precisamos dos seus dados básicos para criar um perfil seguro.':step==1?(customer?'Cadastre seu endereço principal. Você poderá adicionar outros depois.':'Dados usados pela nossa equipe para analisar e aprovar sua parceria.'):'Finalize seu acesso com segurança.';
    return const ['Identificação necessária para manter sua conta segura.','Contato e endereço usados na operação.','Dados reais da habilitação para análise administrativa.','Informe o veículo que será usado nas entregas.','Proteja seu acesso e configure os dados essenciais.','Confira antes de enviar. O acesso operacional depende da aprovação.'][step];
  }
  Widget reviewCard()=>Container(padding:const EdgeInsets.all(16),margin:const EdgeInsets.only(bottom:18),
    decoration:BoxDecoration(color:AppColors.mint,borderRadius:BorderRadius.circular(20)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Row(children:[Icon(Icons.fact_check_rounded,color:AppColors.primary),SizedBox(width:9),Text('Pronto para análise',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900))]),
      const SizedBox(height:10),
      Text('${ctl('name').text} • ${ctl('vehicleType').text} • ${ctl('vehiclePlate').text}',style:const TextStyle(color:AppColors.muted,fontWeight:FontWeight.w700)),
      const SizedBox(height:8),
      const Text('Após o envio, o cadastro ficará pendente até a aprovação administrativa.',style:TextStyle(fontSize:11,height:1.45,color:AppColors.muted,fontWeight:FontWeight.w600)),
    ]));
  Widget field(_F f) {
    if (courier && const ['cnhCategory','vehicleType','vehicleBrand','vehicleModel'].contains(f.key)) return choiceField(f);
    return Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: ctl(f.key),
      keyboardType: f.keyboard,
      inputFormatters: _formatters(f.format),
      obscureText: f.secret && obscure,
      textCapitalization: f.keyboard == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) { setState(() {}); _checkRemote(f.key,value); },
      validator: (v) {
        final value = v?.trim() ?? '';
        if (f.required && value.isEmpty) return 'Preencha este campo';
        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (f.key == 'email' &&
            value.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
          return 'Informe um e-mail válido';
        }
        if (f.key == 'password' && (value.length < 8 || !RegExp(r'[A-Z]').hasMatch(value) || !RegExp(r'[a-z]').hasMatch(value) || !RegExp(r'[0-9]').hasMatch(value))) return 'Use 8+ caracteres, maiúscula, minúscula e número';
        if (f.key == 'confirmPassword' && value != ctl('password').text) return 'As senhas não coincidem';
        if (f.key == 'phone' && digits.length != 11) {
          return 'Informe um celular com DDD';
        }
        if (f.key == 'cpf' && digits.length != 11) return 'CPF incompleto';
        if (f.key == 'cnpj' && digits.length != 14) return 'CNPJ incompleto';
        if (f.key == 'cep' && digits.length != 8) return 'CEP incompleto';
        if (remoteError[f.key] != null) return remoteError[f.key];
        if (f.key == 'birthDate' && digits.length != 8) {
          return 'Informe a data completa';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: f.label,
        hintText: f.hint,
        filled: true,
        fillColor: AppColors.canvas,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(f.icon, color: AppColors.primary, size: 20),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 62, minHeight: 58),
        suffixIcon: checking[f.key] == true ? const Padding(padding: EdgeInsets.all(16),child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))) : remoteError[f.key] == '' ? const Icon(Icons.check_circle_rounded,color:AppColors.success) : f.secret
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    ),
  );
  }

  Widget choiceField(_F f) {
    List<String> options;
    if (f.key == 'cnhCategory') {
      options = const ['A','B','AB','C','AC','D','AD','E','AE'];
    } else if (f.key == 'vehicleType') {
      options = const ['Moto','Carro','Utilitário','Outro'];
    } else if (f.key == 'vehicleBrand') {
      options = ctl('vehicleType').text == 'Moto' ? MotorcycleCatalog.brandOptions : const ['Outra marca'];
    } else {
      options = ctl('vehicleType').text == 'Moto' ? MotorcycleCatalog.modelsFor(ctl('vehicleBrand').text) : const ['Outro modelo'];
    }
    final value=ctl(f.key).text;
    return Padding(padding:const EdgeInsets.only(bottom:13),child:InkWell(
      borderRadius:BorderRadius.circular(18),onTap:()=>openPicker(f,options),
      child:InputDecorator(decoration:InputDecoration(labelText:f.label,filled:true,fillColor:AppColors.canvas,
        prefixIcon:Icon(f.icon,color:AppColors.primary),suffixIcon:const Icon(Icons.keyboard_arrow_down_rounded),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:const BorderSide(color:AppColors.stroke)),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none)),
        child:Text(value.isEmpty?'Toque para selecionar':value,style:TextStyle(fontWeight:FontWeight.w700,color:value.isEmpty?AppColors.muted:AppColors.ink))),
    ));
  }

  Future<void> openPicker(_F f,List<String> options) async {
    final search=TextEditingController();
    var filtered=List<String>.from(options);
    final picked=await showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
      builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet)=>Container(
        height:MediaQuery.sizeOf(ctx).height*.72,padding:const EdgeInsets.fromLTRB(20,16,20,20),
        decoration:const BoxDecoration(color:Colors.white,borderRadius:BorderRadius.vertical(top:Radius.circular(30))),
        child:Column(children:[
          Container(width:42,height:4,decoration:BoxDecoration(color:AppColors.stroke,borderRadius:BorderRadius.circular(8))),
          const SizedBox(height:18),
          Row(children:[Expanded(child:Text(f.label,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close_rounded))]),
          TextField(controller:search,onChanged:(q)=>setSheet(()=>filtered=options.where((x)=>x.toLowerCase().contains(q.toLowerCase())).toList()),
            decoration:InputDecoration(hintText:'Pesquisar',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:AppColors.canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))),
          const SizedBox(height:10),
          Expanded(child:ListView.separated(itemCount:filtered.length,separatorBuilder:(_,__)=>const Divider(height:1,color:AppColors.stroke),
            itemBuilder:(ctx,i){final x=filtered[i],selected=ctl(f.key).text==x;return ListTile(title:Text(x,style:TextStyle(fontWeight:selected?FontWeight.w900:FontWeight.w700)),trailing:selected?const Icon(Icons.check_circle_rounded,color:AppColors.success):null,onTap:()=>Navigator.pop(ctx,x));})),
        ]),
      )));
    search.dispose();
    if(picked==null||!mounted)return;
    setState((){
      ctl(f.key).text=picked;
      if(f.key=='vehicleType'){ctl('vehicleBrand').clear();ctl('vehicleModel').clear();}
      if(f.key=='vehicleBrand')ctl('vehicleModel').clear();
    });
  }

  Future<void> _checkRemote(String key,String value) async {
    final field = key == 'cpf' ? 'cpf' : key == 'cnpj' ? 'cnpj' : key == 'email' ? 'email' : key == 'phone' ? 'phone' : null;
    if (field == null || value.trim().isEmpty) return;
    final ticket=(validationTicket[key]??0)+1; validationTicket[key]=ticket;
    await Future<void>.delayed(const Duration(milliseconds:550));
    if (!mounted || validationTicket[key]!=ticket) return;
    setState(()=>checking[key]=true);
    try {
      final result=await AppState.instance.checkAvailability(field,value);
      if (!mounted || validationTicket[key]!=ticket) return;
      setState(() { checking[key]=false; remoteError[key]=result['valid']!=true ? (field=='cpf'?'CPF inválido':field=='cnpj'?'CNPJ inválido':field=='email'?'E-mail inválido':'Telefone inválido') : result['available']==true ? '' : (field=='cpf'?'Este CPF já possui cadastro':field=='cnpj'?'Este CNPJ já possui cadastro':field=='email'?'Este e-mail já está cadastrado':'Este telefone já está cadastrado'); });
      form.currentState?.validate();
    } catch (_) {
      if (mounted && validationTicket[key]==ticket) setState(() { checking[key]=false; remoteError[key]='Não foi possível verificar agora'; });
    }
  }

  List<TextInputFormatter>? _formatters(_Format format) {
    switch (format) {
      case _Format.none:
        return null;
      case _Format.cpf:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
          _MaskFormatter('###.###.###-##'),
        ];
      case _Format.cnpj:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(14),
          _MaskFormatter('##.###.###/####-##'),
        ];
      case _Format.phone:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
          _MaskFormatter('(##) #####-####'),
        ];
      case _Format.cep:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
          _MaskFormatter('#####-###'),
        ];
      case _Format.date:
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
          _MaskFormatter('##/##/####'),
        ];
      case _Format.plate:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(7),
          _UpperFormatter(),
        ];
    }
  }

  Future<void> next() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if(checking.values.any((v)=>v)){await _showInfo('Verificando dados','Aguarde a conclusão das validações antes de continuar.',Icons.hourglass_top_rounded);return;}
    if(remoteError.values.any((v)=>v!=null&&v!.isNotEmpty))return;
    if(courier&&step==3&&(ctl('vehicleType').text.isEmpty||ctl('vehicleBrand').text.isEmpty||ctl('vehicleModel').text.isEmpty)){await _showInfo('Complete o veículo','Selecione tipo, marca e modelo antes de continuar.',Icons.two_wheeler_rounded);return;}
    if (step < groups.length - 1) {
      setState(() => step++);
      return;
    }
    if (!accepted) {
      await _showInfo(
        'Confirme para continuar',
        'Para proteger sua conta, confirme que os dados são verdadeiros e que você aceita os termos e a política de privacidade.',
        Icons.shield_outlined,
      );
      return;
    }

    final data = <String, dynamic>{
      for (final e in c.entries) e.key: e.value.text.trim(),
    };

    try {
      await AppState.instance.register(
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        password: data['password'] ?? '',
        role: widget.role,
        document: courier
            ? data['cpf']
            : customer
                ? data['cpf']
                : data['cnpj'],
        businessName:
            !customer && !courier ? data['businessName'] : null,
        profileData: {...data}..remove('password')..remove('confirmPassword'),
      );
      if (!mounted) return;

      if (customer) {
        if ((data['street'] ?? '').toString().isNotEmpty) {
          try {
            await AppState.instance.addAddress({
              'label': 'Casa',
              'street': data['street'],
              'number': data['number'],
              'complement': data['complement'],
              'neighborhood': data['neighborhood'],
              'city': 'Porto Seguro',
              'state': 'BA',
              'postalCode': data['cep'],
              'isDefault': true,
            });
          } catch (_) {}
        }
        if (mounted) Navigator.of(context).pop();
      } else {
        await _showInfo(
          'Cadastro enviado',
          'Recebemos seu cadastro de $title. Agora nossa equipe fará a análise. Assim que for aprovado, seu acesso operacional será liberado.',
          Icons.verified_rounded,
        );
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await _showRegistrationError(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _showInfo(
    String title,
    String message,
    IconData icon,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Icon(icon, color: AppColors.oceanDeep, size: 31),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(d),
                  child: const Text(
                    'Entendi',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRegistrationError(String raw) async {
    final lower = raw.toLowerCase();
    final phone = lower.contains('celular') ||
        lower.contains('telefone') ||
        lower.contains('whatsapp') ||
        lower.contains('phone');
    final email = lower.contains('e-mail') || lower.contains('email');
    final duplicate = lower.contains('cadastrad') ||
        lower.contains('unique') ||
        lower.contains('duplic');

    final dialogTitle = phone && duplicate
        ? 'Telefone já cadastrado'
        : email && duplicate
            ? 'E-mail já cadastrado'
            : 'Não foi possível criar sua conta';
    final message = phone && duplicate
        ? 'Este número já está vinculado a uma conta Porto Prime. Use outro celular ou entre com a conta existente.'
        : email && duplicate
            ? 'Este e-mail já está vinculado a uma conta Porto Prime. Use outro endereço ou entre com a conta existente.'
            : raw;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.priority_high_rounded,
                  color: AppColors.coral,
                  size: 31,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                dialogTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(d),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Corrigir meus dados',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.pop(d);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Já tenho uma conta',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Format { none, cpf, cnpj, phone, cep, date, plate }

class _F {
  const _F(
    this.key,
    this.label,
    this.icon, {
    this.hint,
    this.keyboard,
    this.secret = false,
    this.required = true,
    this.format = _Format.none,
  });

  final String key;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboard;
  final bool secret;
  final bool required;
  final _Format format;
}

class _MaskFormatter extends TextInputFormatter {
  _MaskFormatter(this.mask);
  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final out = StringBuffer();
    var i = 0;
    for (var m = 0; m < mask.length && i < digits.length; m++) {
      if (mask[m] == '#') {
        out.write(digits[i++]);
      } else {
        out.write(mask[m]);
      }
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _UpperFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
