import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/motorcycle_catalog.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, required this.role});
  final String role;
  @override State<RegistrationPage> createState()=>_RegistrationPageState();
}
class _RegistrationPageState extends State<RegistrationPage> {
  final forms=List.generate(6, (_)=>GlobalKey<FormState>()); int step=0; bool accepted=false,obscure=true;
  final Map<String,String?> remoteError={};
  final Map<String,bool> checking={};
  final Map<String,int> validationTicket={};
  final Map<String,Timer> remoteDebounce={};
  String? verifiedCpfIdentity;
  String? cpfSituation;
  GlobalKey<FormState> get form=>forms[step];
  final Map<String,TextEditingController> c={};
  TextEditingController ctl(String k)=>c.putIfAbsent(k,()=>TextEditingController());
  bool get customer=>widget.role=='CUSTOMER'; bool get courier=>widget.role=='COURIER';
  String get title=>customer?'Cliente':courier?'Motoboy':'Parceiro';
  List<List<_F>> get groups=>courier ? courierGroups : commonGroups;
  List<List<_F>> get commonGroups=>[
    [const _F('name','Nome completo',AppIcons.person_outline_rounded),const _F('birthDate','Data de nascimento',AppIcons.cake_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date),const _F('phone','Celular / WhatsApp',AppIcons.phone_outlined,keyboard:TextInputType.phone,format:_Format.phone)],
    if(!customer)[const _F('businessName','Nome do estabelecimento',AppIcons.storefront_outlined),const _F('legalName','Razão social',AppIcons.business_outlined),const _F('cnpj','CNPJ / documento',AppIcons.badge_outlined,keyboard:TextInputType.number,format:_Format.cnpj),const _F('businessType','Tipo de estabelecimento',AppIcons.category_outlined,hint:'Hotel, pousada, receptivo...')]
    else [const _F('cep','CEP',AppIcons.local_post_office_outlined,keyboard:TextInputType.number,format:_Format.cep),const _F('street','Rua / avenida',AppIcons.route_outlined),const _F('number','Número',AppIcons.numbers_outlined),const _F('neighborhood','Bairro',AppIcons.map_outlined),const _F('complement','Complemento',AppIcons.home_work_outlined,required:false)],
    [const _F('email','E-mail',AppIcons.mail_outline_rounded,keyboard:TextInputType.emailAddress),const _F('password','Crie uma senha',AppIcons.lock_outline_rounded,secret:true,hint:'Mínimo de 8 caracteres'),if(courier)const _F('pixKey','Chave PIX para recebimentos',AppIcons.account_balance_wallet_outlined,required:false),if(!customer&&!courier)const _F('contactRole','Seu cargo / função',AppIcons.work_outline_rounded,required:false)],
  ];
  List<List<_F>> get courierGroups=>[
    [const _F('cpf','CPF',AppIcons.badge_outlined,keyboard:TextInputType.number,format:_Format.cpf),const _F('birthDate','Data de nascimento',AppIcons.cake_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date),const _F('name','Nome na Receita Federal',AppIcons.person_outline_rounded)],
    [const _F('phone','Celular / WhatsApp',AppIcons.phone_outlined,keyboard:TextInputType.phone,format:_Format.phone),const _F('cep','CEP',AppIcons.local_post_office_outlined,keyboard:TextInputType.number,format:_Format.cep),const _F('street','Rua / avenida',AppIcons.route_outlined),const _F('number','Número',AppIcons.numbers_outlined),const _F('neighborhood','Bairro',AppIcons.map_outlined),const _F('city','Cidade',AppIcons.location_city_outlined),const _F('state','UF',AppIcons.map_outlined)],
    [const _F('cnh','Número de registro da CNH',AppIcons.credit_card_outlined),const _F('cnhCategory','Categoria da CNH',AppIcons.fact_check_outlined),const _F('cnhExpiry','Validade da CNH',AppIcons.event_available_outlined,hint:'DD/MM/AAAA',keyboard:TextInputType.number,format:_Format.date)],
    [const _F('vehicleType','Tipo de veículo',AppIcons.commute_rounded),const _F('vehicleBrand','Marca',AppIcons.two_wheeler_outlined),const _F('vehicleModel','Modelo',AppIcons.two_wheeler_outlined),const _F('vehicleYear','Ano',AppIcons.calendar_today_outlined,keyboard:TextInputType.number),const _F('vehiclePlate','Placa',AppIcons.pin_outlined,format:_Format.plate)],
    [const _F('email','E-mail',AppIcons.mail_outline_rounded,keyboard:TextInputType.emailAddress),const _F('password','Crie uma senha',AppIcons.lock_outline_rounded,secret:true,hint:'8+ caracteres, maiúscula, minúscula e número'),const _F('confirmPassword','Confirme sua senha',AppIcons.lock_reset_rounded,secret:true),const _F('pixKeyType','Tipo de chave PIX',AppIcons.account_balance_wallet_outlined,required:false),const _F('pixKey','Chave PIX para recebimentos',AppIcons.account_balance_wallet_outlined,required:false)],
    [],
  ];
  @override
  void dispose() {
    for (final timer in remoteDebounce.values) {
      timer.cancel();
    }
    for (final x in c.values) {
      x.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final total = groups.length;
    final accent = customer
        ? AppColors.ocean
        : courier
            ? const Color(0xFFB77818)
            : AppColors.violet600;
    final soft = customer
        ? AppColors.mint
        : courier
            ? AppColors.sand
            : AppColors.lavender;
    final roleIcon = customer
        ? AppIcons.shopping_bag_rounded
        : courier
            ? AppIcons.two_wheeler_rounded
            : AppIcons.storefront_rounded;
    final stepIcons = courier
        ? const [
            AppIcons.person_rounded,
            AppIcons.location_on_rounded,
            AppIcons.badge_rounded,
            AppIcons.two_wheeler_rounded,
            AppIcons.shield_rounded,
            AppIcons.fact_check_rounded,
          ]
        : [
            AppIcons.person_rounded,
            customer ? AppIcons.location_on_rounded : AppIcons.storefront_rounded,
            AppIcons.shield_rounded,
          ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.stroke),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: step == 0 ? 'Fechar' : 'Voltar',
                        onPressed: () => step == 0
                            ? Navigator.pop(context)
                            : setState(() => step--),
                        icon: Icon(
                          step == 0
                              ? AppIcons.close_rounded
                              : AppIcons.arrow_back_rounded,
                        ),
                      ),
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(roleIcon, color: accent, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conta de $title',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: AppFontWeight.display,
                                letterSpacing: -.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Etapa ${step + 1} de $total',
                              style: const TextStyle(
                                fontSize: AppFontSize.caption,
                                color: AppColors.muted,
                                fontWeight: AppFontWeight.strong,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: soft,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: Text(
                          customer
                              ? 'CLIENTE'
                              : courier
                                  ? 'MOTOBOY'
                                  : 'PARCEIRO',
                          style: TextStyle(
                            color: accent,
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.display,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: List.generate(
                      total,
                      (index) => Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 5 : 3,
                            right: index == total - 1 ? 5 : 3,
                          ),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                height: 5,
                                decoration: BoxDecoration(
                                  color: index <= step ? accent : AppColors.stroke,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              const SizedBox(height: 7),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: index == step
                                      ? soft
                                      : index < step
                                          ? AppColors.mint
                                          : AppColors.canvas,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  index < step
                                      ? AppIcons.check_rounded
                                      : stepIcons[index],
                                  size: 15,
                                  color: index <= step
                                      ? (index < step
                                          ? AppColors.oceanDeep
                                          : accent)
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.035, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(step),
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [soft, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: accent.withValues(alpha: .12),
                            ),
                          ),
                          child: Icon(
                            stepIcons[step],
                            color: accent,
                            size: 27,
                          ),
                        ),
                        const SizedBox(height: 17),
                        Text(
                          heading(),
                          style: const TextStyle(
                            fontSize: 29,
                            height: 1.02,
                            fontWeight: AppFontWeight.display,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          sub(),
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: AppColors.muted,
                            fontWeight: AppFontWeight.medium,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 17, 16, 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.stroke),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            children: [
                              ...groups[step].map(field),
                              if (courier && step == 0) _cpfVerificationStatus(),
                              if (courier &&
                                  step == 3 &&
                                  ctl('vehicleBrand').text == 'Outra marca')
                                field(
                                  const _F(
                                    'customVehicleBrand',
                                    'Informe a marca',
                                    AppIcons.edit_rounded,
                                  ),
                                ),
                              if (courier &&
                                  step == 3 &&
                                  ctl('vehicleModel').text == 'Outro modelo')
                                field(
                                  const _F(
                                    'customVehicleModel',
                                    'Informe o modelo',
                                    AppIcons.edit_rounded,
                                  ),
                                ),
                              if (courier &&
                                  step == groups.length - 1)
                                reviewCard(),
                            ],
                          ),
                        ),
                        if (step == total - 1) ...[
                          const SizedBox(height: 14),
                          Material(
                            color: accepted
                                ? AppColors.mint
                                : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => accepted = !accepted),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: accepted
                                        ? AppColors.mintStrong
                                        : AppColors.stroke,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 25,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: accepted
                                            ? AppColors.oceanDeep
                                            : AppColors.canvas,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: accepted
                                              ? AppColors.oceanDeep
                                              : AppColors.stroke,
                                        ),
                                      ),
                                      child: accepted
                                          ? const Icon(
                                              AppIcons.check_rounded,
                                              color: Colors.white,
                                              size: 17,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 11),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Confirmação dos dados',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: AppFontWeight.display,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Confirmo que as informações são verdadeiras e aceito os termos e a política de privacidade.',
                                            style: TextStyle(
                                              fontSize: AppFontSize.caption,
                                              height: 1.45,
                                              color: AppColors.muted,
                                              fontWeight: AppFontWeight.medium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.canvas,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: AppState.instance.loading ? null : next,
                    icon: AppState.instance.loading
                        ? const SizedBox.shrink()
                        : Icon(
                            step == total - 1
                                ? AppIcons.verified_user_rounded
                                : AppIcons.arrow_forward_rounded,
                            size: 20,
                          ),
                    label: AppState.instance.loading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            step == total - 1
                                ? (courier
                                    ? 'Enviar cadastro para análise'
                                    : 'Criar minha conta')
                                : 'Continuar',
                            style: const TextStyle(
                              fontWeight: AppFontWeight.display,
                            ),
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
  Widget reviewCard() {
    final sections = <Map<String, dynamic>>[
      {'title':'Dados pessoais','icon':AppIcons.person_rounded,'step':0,'rows':[
        ['Nome completo',ctl('name').text],['CPF',ctl('cpf').text],['Data de nascimento',ctl('birthDate').text],
      ]},
      {'title':'Contato e endereço','icon':AppIcons.location_on_rounded,'step':1,'rows':[
        ['Celular / WhatsApp',ctl('phone').text],['CEP',ctl('cep').text],
        ['Endereço','${ctl('street').text}, ${ctl('number').text}'],
        ['Bairro',ctl('neighborhood').text],['Cidade / UF','${ctl('city').text} / ${ctl('state').text}'],
      ]},
      {'title':'Habilitação','icon':AppIcons.badge_rounded,'step':2,'rows':[
        ['Registro CNH',ctl('cnh').text],['Categoria',ctl('cnhCategory').text],['Validade',ctl('cnhExpiry').text],
      ]},
      {'title':'Veículo de entrega','icon':AppIcons.two_wheeler_rounded,'step':3,'rows':[
        ['Tipo',ctl('vehicleType').text],
        ['Marca',ctl('vehicleBrand').text=='Outra marca'?ctl('customVehicleBrand').text:ctl('vehicleBrand').text],
        ['Modelo',ctl('vehicleModel').text=='Outro modelo'?ctl('customVehicleModel').text:ctl('vehicleModel').text],
        ['Ano',ctl('vehicleYear').text],['Placa',ctl('vehiclePlate').text],
      ]},
      {'title':'Conta e recebimentos','icon':AppIcons.shield_rounded,'step':4,'rows':[
        ['E-mail',ctl('email').text],['Senha','••••••••'],['Chave PIX',ctl('pixKey').text.isEmpty?'Não informada':ctl('pixKey').text],
      ]},
    ];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(
        width:double.infinity,padding:const EdgeInsets.all(18),margin:const EdgeInsets.only(bottom:14),
        decoration:BoxDecoration(
          gradient:const LinearGradient(colors:[AppColors.mint,Color(0xFFF4FBF8)]),
          borderRadius:BorderRadius.circular(AppRadius.lg),border:Border.all(color:AppColors.mintStrong),
        ),
        child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(AppIcons.verified_user_rounded,color:AppColors.oceanDeep,size:27),SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Confira tudo antes de enviar',style:TextStyle(fontSize:16,fontWeight:AppFontWeight.display)),
            SizedBox(height:4),
            Text('Revise seus dados pessoais, CNH, veículo e contato. Se encontrar algo errado, toque em Editar e volte exatamente à etapa correspondente.',style:TextStyle(fontSize:10.5,height:1.45,color:AppColors.muted,fontWeight:AppFontWeight.medium)),
          ])),
        ]),
      ),
      ...sections.map((section)=>Container(
        margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.fromLTRB(15,14,15,12),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:AppColors.stroke)),
        child:Column(children:[
          Row(children:[
            Container(width:38,height:38,decoration:BoxDecoration(color:AppColors.canvas,borderRadius:BorderRadius.circular(AppRadius.sm)),child:Icon(section['icon'] as IconData,color:AppColors.oceanDeep,size:20)),
            const SizedBox(width:10),Expanded(child:Text(section['title'] as String,style:const TextStyle(fontSize:13.5,fontWeight:AppFontWeight.display))),
            TextButton.icon(
              onPressed:()=>setState(()=>step=section['step'] as int),
              icon:const Icon(AppIcons.edit_rounded,size:15),label:const Text('Editar'),
              style:TextButton.styleFrom(foregroundColor:AppColors.oceanDeep,textStyle:const TextStyle(fontSize:11,fontWeight:AppFontWeight.display)),
            ),
          ]),
          const SizedBox(height:6),
          ...(section['rows'] as List).map((raw){
            final row=raw as List<String>;return Padding(
              padding:const EdgeInsets.symmetric(vertical:6),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Expanded(flex:4,child:Text(row[0],style:const TextStyle(fontSize:9.5,color:AppColors.muted,fontWeight:AppFontWeight.strong))),
                const SizedBox(width:10),
                Expanded(flex:6,child:Text(row[1].isEmpty?'Não informado':row[1],textAlign:TextAlign.right,style:const TextStyle(fontSize:10.5,height:1.3,fontWeight:AppFontWeight.display))),
              ]),
            );
          }),
        ]),
      )),
      Container(
        padding:const EdgeInsets.all(15),margin:const EdgeInsets.only(bottom:18),
        decoration:BoxDecoration(color:AppColors.sand,borderRadius:BorderRadius.circular(AppRadius.md)),
        child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(AppIcons.manage_search_rounded,color:AppColors.coral,size:22),SizedBox(width:10),
          Expanded(child:Text('Depois do envio, o cadastro ficará em análise. A equipe Porto Prime verificará as informações antes de liberar o acesso operacional.',style:TextStyle(fontSize:10.5,height:1.45,color:AppColors.ink,fontWeight:AppFontWeight.strong))),
        ]),
      ),
    ]);
  }
  Widget field(_F f) {
    if (courier && const ['cnhCategory','vehicleType','vehicleBrand','vehicleModel','state','pixKeyType'].contains(f.key)) return choiceField(f);
    final accent = customer
        ? AppColors.ocean
        : courier
            ? const Color(0xFFB77818)
            : AppColors.violet600;
    final soft = customer
        ? AppColors.mint
        : courier
            ? AppColors.sand
            : AppColors.lavender;
    return Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      controller: ctl(f.key),
      readOnly: courier && f.key == 'name',
      keyboardType: f.keyboard,
      inputFormatters: _formatters(f.format),
      obscureText: f.secret && obscure,
      textCapitalization: f.keyboard == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (value) {
        if (!(courier && f.key == 'cpf')) _queueRemoteCheck(f.key, value);
        if (courier && (f.key == 'cpf' || f.key == 'birthDate')) _queueCpfLookup();
        if (courier && f.key == 'cep') _lookupCep(value);
      },
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
        if (courier && f.key == 'cpf' && (remoteError['cpfLookup']?.isNotEmpty ?? false)) return remoteError['cpfLookup'];
        if (f.key == 'cnpj' && digits.length != 14) return 'CNPJ incompleto';
        if (f.key == 'cep' && digits.length != 8) return 'CEP incompleto';
        final remote = remoteError[f.key];
        if (remote != null && remote.isNotEmpty) return remote;
        if (f.key == 'birthDate' && digits.length != 8) {
          return 'Informe a data completa';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: f.label,
        hintText: courier && f.key == 'name' ? 'Preenchido após a consulta do CPF' : f.hint,
        errorMaxLines: 6,
        filled: true,
        fillColor: AppColors.canvas,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(f.icon, color: accent, size: 20),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 62, minHeight: 58),
        suffixIcon: (checking[f.key] == true || (courier && f.key == 'cpf' && checking['cpfLookup'] == true)) ? const Padding(padding: EdgeInsets.all(16),child:SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))) : remoteError[f.key] == '' ? const Icon(AppIcons.check_circle_rounded,color:AppColors.success) : f.secret
            ? IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? AppIcons.visibility_outlined
                      : AppIcons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
    ),
  );
  }

  Widget choiceField(_F f) {
    final accent = customer
        ? AppColors.ocean
        : courier
            ? const Color(0xFFB77818)
            : AppColors.violet600;
    final soft = customer
        ? AppColors.mint
        : courier
            ? AppColors.sand
            : AppColors.lavender;
    List<String> options;
    if (f.key == 'pixKeyType') {
      options = const ['CPF','CNPJ','E-mail','Celular','Aleatória'];
    } else if (f.key == 'state') {
      options = const ['AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'];
    } else if (f.key == 'cnhCategory') {
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
      borderRadius:BorderRadius.circular(AppRadius.md),onTap:()=>openPicker(f,options),
      child:InputDecorator(decoration:InputDecoration(labelText:f.label,filled:true,fillColor:AppColors.canvas,
        prefixIcon:Padding(
          padding:const EdgeInsets.all(11),
          child:Container(
            width:38,height:38,
            decoration:BoxDecoration(color:soft,borderRadius:BorderRadius.circular(AppRadius.sm)),
            child:Icon(f.icon,color:accent,size:20),
          ),
        ),
        prefixIconConstraints:const BoxConstraints(minWidth:62,minHeight:58),
        suffixIcon:Icon(AppIcons.unfold_more_rounded,color:accent,size:20),
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(AppRadius.md),borderSide:const BorderSide(color:AppColors.stroke)),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(AppRadius.md),borderSide:BorderSide.none)),
        child:Text(value.isEmpty?'Toque para selecionar':value,style:TextStyle(fontWeight:AppFontWeight.display,fontSize:12,color:value.isEmpty?AppColors.muted:AppColors.ink))),
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
          Row(children:[Expanded(child:Text(f.label,style:const TextStyle(fontSize:21,fontWeight:AppFontWeight.display))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(AppIcons.close_rounded))]),
          TextField(controller:search,onChanged:(q)=>setSheet(()=>filtered=options.where((x)=>x.toLowerCase().contains(q.toLowerCase())).toList()),
            decoration:InputDecoration(hintText:'Pesquisar',prefixIcon:const Icon(AppIcons.search_rounded),filled:true,fillColor:AppColors.canvas,border:OutlineInputBorder(borderRadius:BorderRadius.circular(AppRadius.md),borderSide:BorderSide.none))),
          const SizedBox(height:10),
          Expanded(child:ListView.separated(itemCount:filtered.length,separatorBuilder:(_,_)=>const Divider(height:1,color:AppColors.stroke),
            itemBuilder:(ctx,i){final x=filtered[i],selected=ctl(f.key).text==x;return ListTile(title:Text(x,style:TextStyle(fontWeight:selected?AppFontWeight.display:AppFontWeight.strong)),trailing:selected?const Icon(AppIcons.check_circle_rounded,color:AppColors.success):null,onTap:()=>Navigator.pop(ctx,x));})),
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

  Future<void> _lookupCep(String value) async {
    final digits=value.replaceAll(RegExp(r'\D'),'');
    if(digits.length!=8)return;
    final ticket=(validationTicket['cepLookup']??0)+1;
    validationTicket['cepLookup']=ticket;
    setState(()=>checking['cep']=true);
    try {
      final result=await AppState.instance.lookupPostalCode(digits);
      if(!mounted||validationTicket['cepLookup']!=ticket)return;
      if(result['valid']==true){
        setState((){
          checking['cep']=false;
          remoteError['cep']='';
          ctl('street').text=(result['street']??'').toString();
          ctl('neighborhood').text=(result['neighborhood']??'').toString();
          ctl('city').text=(result['city']??'Porto Seguro').toString();
          ctl('state').text=(result['state']??'BA').toString();
        });
      } else {
        final reason=result['reason'];
        setState((){
          checking['cep']=false;
          remoteError['cep']=reason=='OUTSIDE_SERVICE_AREA'
              ? 'Atendemos motoboys somente na região de Porto Seguro'
              : reason=='LOOKUP_UNAVAILABLE'
                  ? 'Não foi possível consultar o CEP agora'
                  : 'CEP não encontrado';
          ctl('street').clear(); ctl('neighborhood').clear(); ctl('city').clear(); ctl('state').clear();
        });
      }
      form.currentState?.validate();
    } catch (_) {
      if(mounted&&validationTicket['cepLookup']==ticket){
        setState((){
          checking['cep']=false;
          remoteError['cep']='Não foi possível consultar o CEP agora';
        });
      }
    }
  }

  String get _cpfIdentity => '${ctl('cpf').text.replaceAll(RegExp(r'\D'), '')}:${ctl('birthDate').text.replaceAll(RegExp(r'\D'), '')}';

  Widget _cpfVerificationStatus() {
    final waiting = checking['cpfLookup'] == true;
    final error = remoteError['cpfLookup'];
    final regular = verifiedCpfIdentity == _cpfIdentity && cpfSituation == 'REGULAR';
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          waiting ? 'Consultando a Receita Federal…'
              : cpfSituation != null ? 'Situação cadastral: $cpfSituation'
              : 'Informe CPF e data de nascimento para consultar a Receita Federal.',
          style: TextStyle(color: regular ? AppColors.success : AppColors.muted, height: 1.5),
        ),
        if (!waiting && (error?.isNotEmpty ?? false))
          TextButton.icon(
            onPressed: _queueCpfLookup,
            icon: const Icon(AppIcons.manage_search_rounded, size: 18),
            label: const Text('Consultar novamente'),
          ),
      ]),
    );
  }

  void _queueCpfLookup() {
    remoteDebounce['cpfLookup']?.cancel();
    final ticket = (validationTicket['cpfLookup'] ?? 0) + 1;
    validationTicket['cpfLookup'] = ticket;
    final cpf = ctl('cpf').text.replaceAll(RegExp(r'\D'), '');
    final birthDate = ctl('birthDate').text;
    final identity = _cpfIdentity;
    final ready = cpf.length == 11 && birthDate.replaceAll(RegExp(r'\D'), '').length == 8;
    setState(() {
      verifiedCpfIdentity = null;
      cpfSituation = null;
      ctl('name').clear();
      checking['cpfLookup'] = ready;
      remoteError.remove('cpfLookup');
      remoteError.remove('cpf');
    });
    if (!ready) return;
    remoteDebounce['cpfLookup'] = Timer(const Duration(milliseconds: 650), () async {
      try {
        final result = await AppState.instance.lookupCourierCpf(cpf, birthDate);
        if (!mounted || validationTicket['cpfLookup'] != ticket || _cpfIdentity != identity) return;
        final situation = (result['situation'] ?? '').toString();
        final regular = result['regular'] == true && situation == 'REGULAR';
        setState(() {
          checking['cpfLookup'] = false;
          cpfSituation = situation;
          ctl('name').text = (result['name'] ?? '').toString();
          verifiedCpfIdentity = regular ? identity : null;
          remoteError['cpfLookup'] = regular ? ''
              : 'CPF com situação cadastral $situation. Entre em contato com a Receita Federal para regularizar seu CPF antes de continuar.';
          remoteError['cpf'] = regular ? '' : null;
        });
        form.currentState?.validate();
      } catch (e) {
        if (!mounted || validationTicket['cpfLookup'] != ticket || _cpfIdentity != identity) return;
        setState(() {
          checking['cpfLookup'] = false;
          final message = e.toString().replaceFirst('Exception: ', '');
          remoteError['cpfLookup'] = message.startsWith('Confira ') || message.startsWith('Informe ') || message.startsWith('CPF ') || message.startsWith('Este CPF ') || message.startsWith('Muitas consultas.') || message.startsWith('Consulta temporariamente')
              ? message : 'Não foi possível consultar a Receita Federal agora. Tente novamente mais tarde.';
        });
        form.currentState?.validate();
      }
    });
  }

  void _queueRemoteCheck(String key, String value) {
    final field = key == 'cpf'
        ? 'cpf'
        : key == 'cnpj'
            ? 'cnpj'
            : key == 'email'
                ? 'email'
                : key == 'phone'
                    ? 'phone'
                    : null;
    if (field == null) return;

    remoteDebounce[key]?.cancel();
    final ticket = (validationTicket[key] ?? 0) + 1;
    validationTicket[key] = ticket;

    final trimmed = value.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    final ready = switch (field) {
      'cpf' => digits.length == 11,
      'cnpj' => digits.length == 14,
      'phone' => digits.length == 11,
      'email' => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed),
      _ => false,
    };

    if (!ready) {
      final hadVisualState =
          checking[key] == true || remoteError.containsKey(key);
      checking[key] = false;
      remoteError.remove(key);
      if (hadVisualState && mounted) {
        setState(() {});
      }
      return;
    }

    final needsVisualUpdate =
        checking[key] != true || remoteError.containsKey(key);
    checking[key] = true;
    remoteError.remove(key);
    if (needsVisualUpdate && mounted) {
      setState(() {});
    }

    remoteDebounce[key] = Timer(const Duration(milliseconds: 650), () async {
      if (!mounted || validationTicket[key] != ticket) return;
      try {
        final result =
            await AppState.instance.checkAvailability(field, trimmed);
        if (!mounted || validationTicket[key] != ticket) return;

        final message = result['valid'] != true
            ? (field == 'cpf'
                ? 'CPF inválido'
                : field == 'cnpj'
                    ? 'CNPJ inválido'
                    : field == 'email'
                        ? 'E-mail inválido'
                        : 'Telefone inválido')
            : result['available'] == true
                ? ''
                : (field == 'cpf'
                    ? 'Este CPF já possui cadastro'
                    : field == 'cnpj'
                        ? 'Este CNPJ já possui cadastro'
                        : field == 'email'
                            ? 'Este e-mail já está cadastrado'
                            : 'Este telefone já está cadastrado');

        setState(() {
          checking[key] = false;
          remoteError[key] = message;
        });
        form.currentState?.validate();
      } catch (_) {
        if (!mounted || validationTicket[key] != ticket) return;
        setState(() {
          checking[key] = false;
          remoteError[key] = 'Não foi possível verificar agora';
        });
      }
    });
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
    if (courier && (verifiedCpfIdentity != _cpfIdentity || cpfSituation != 'REGULAR')) {
      await _showInfo('Verificação do CPF',
        checking['cpfLookup'] == true ? 'Aguarde a consulta à Receita Federal.'
            : remoteError['cpfLookup'] ?? 'Informe CPF e data de nascimento e conclua a consulta antes de continuar.',
        AppIcons.shield_outlined);
      return;
    }
    if (!(form.currentState?.validate() ?? false)) return;
    if(checking.values.any((v)=>v)){await _showInfo('Verificando dados','Aguarde a conclusão das validações antes de continuar.',AppIcons.hourglass_top_rounded);return;}
    if(remoteError.values.any((v)=>v?.isNotEmpty ?? false))return;
    if(courier&&step==3&&(ctl('vehicleType').text.isEmpty||ctl('vehicleBrand').text.isEmpty||ctl('vehicleModel').text.isEmpty)){await _showInfo('Complete o veículo','Selecione tipo, marca e modelo antes de continuar.',AppIcons.two_wheeler_rounded);return;}
    if (step < groups.length - 1) {
      setState(() => step++);
      return;
    }
    if (!accepted) {
      await _showInfo(
        'Confirme para continuar',
        'Para proteger sua conta, confirme que os dados são verdadeiros e que você aceita os termos e a política de privacidade.',
        AppIcons.shield_outlined,
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
        document: customer ? null : (courier ? data['cpf'] : data['cnpj']),
        businessName:
            !customer && !courier ? data['businessName'] : null,
        profileData: {...data, if (courier) 'cpfSituation': cpfSituation}..remove('password')..remove('confirmPassword'),
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
          AppIcons.verified_rounded,
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: AppColors.oceanDeep, size: 31),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: AppFontWeight.display,
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
                  fontWeight: AppFontWeight.medium,
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
                    style: TextStyle(fontWeight: AppFontWeight.display),
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
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
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  AppIcons.priority_high_rounded,
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
                  fontWeight: AppFontWeight.display,
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
                  fontWeight: AppFontWeight.medium,
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
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: const Text(
                    'Corrigir meus dados',
                    style: TextStyle(fontWeight: AppFontWeight.display),
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
                    fontWeight: AppFontWeight.display,
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
