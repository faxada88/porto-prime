import '../widgets/courier_review_success.dart';
import '../widgets/courier_account_status.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/tracking/courier_route_tracker.dart';
import '../../../../core/tracking/courier_tracking_notice.dart';
import '../../../../core/widgets/prime_brand.dart';
import '../widgets/delivery_return_page.dart';
import '../../../support/presentation/pages/delivery_chat_page.dart';
import '../../../support/presentation/pages/support_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/courier_dashboard_map.dart' show courierGreen, courierInk;
import '../widgets/courier_dashboard_header.dart';
import '../widgets/courier_assigned_delivery.dart';
import '../widgets/courier_workflow_layout.dart';
import '../widgets/courier_withdrawal_feedback.dart';
import '../widgets/incoming_delivery_offer_sheet.dart';
import 'courier_operations_dashboard.dart';
import 'courier_demand_notice.dart';
import 'courier_photo_card.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/notifications/delivery_offer_sound.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({super.key});

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  int _refreshTicks=0;
  bool _navBusy = false;
  bool _advancing = false;
  bool _offerActionBusy = false;
  int _navIndex = 0;
  bool _updatesOpen = false;
  bool _logoutDialogOpen = false;
  bool _withdrawalDialogOpen = false;
  bool _signingOut = false;
  bool _accountWasRestricted = false;
  String? _approvalWelcomeUser;
  final Set<String> _readUpdateIds = {};
  final _operationsScroll = ScrollController();
  String? _lastPresentedOfferId;
  bool _offerModalOpen = false;
  bool _deliverySheetActive=false;
  String? _soundingOfferId;

  void _syncOfferSound() {
    final state=AppState.instance;
    final restricted = state.courierRestricted;
    if (restricted && !_accountWasRestricted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && AppState.instance.courierRestricted) {
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
      });
    }
    if (_accountWasRestricted && !restricted && state.isCourier) _approvalWelcomeUser = state.user?['id']?.toString();
    if (restricted || !state.isCourier) _approvalWelcomeUser = null;
    _accountWasRestricted = restricted;
    if(_soundingOfferId==null)return;
    final stillAvailable=state.courierOffers.any((offer)=>(offer['offerId']??offer['orderId']).toString()==_soundingOfferId);
    if(!state.isCourier||!state.courierOnline||state.courierDelivery!=null||!stillAvailable){stopDeliveryOfferSound();_soundingOfferId=null;}
  }

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_syncOfferSound);
    unawaited(_loadReadUpdates());
    Future<void>(() async {
      try {
        await AppState.instance.heartbeatCourier();
        await AppState.instance.refreshCourierOperations();
        unawaited(AppState.instance.refreshCourier().catchError((_) {}));
      } catch (_) {}
    });
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        try {
          await AppState.instance.heartbeatCourier();
        } catch (_) {}
      },
    );
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final state=AppState.instance;
        // Socket is the primary path; polling only recovers missed events.
        if(state.realtime.connected && ++_refreshTicks%3!=0)return;
        try {
          await state.refreshCourier();
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_syncOfferSound);
    stopDeliveryOfferSound();
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    _operationsScroll.dispose();
    super.dispose();
  }

  void _presentIncomingOfferIfNeeded(BuildContext context, AppState state) {
    if (_logoutDialogOpen || _signingOut || _offerModalOpen || state.courierDelivery != null || !state.courierOnline ||
        state.courierOffers.isEmpty) return;
    final offer = Map<String, dynamic>.from(state.courierOffers.first);
    final id = (offer['offerId'] ?? offer['orderId'])?.toString();
    final expiry = DateTime.tryParse(offer['expiresAt']?.toString() ?? '');
    if (id == null || id == _lastPresentedOfferId || expiry == null ||
        !expiry.isAfter(DateTime.now())) return;
    _lastPresentedOfferId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !state.isCourier || !state.courierOnline ||
          state.courierDelivery != null ||
          !state.courierOffers.any((o) => (o['offerId'] ?? o['orderId']).toString() == id)) return;
      _soundingOfferId = id;
      startDeliveryOfferSound(expiry);
      HapticFeedback.heavyImpact();
      // On Home, the same guarded offer component is inline and directly actionable.
      // While another section is open, retain the existing interrupting offer sheet.
      if (ModalRoute.of(context)?.isCurrent == false) {
        _offerModalOpen = true;
        try { await _showDeliverySheet(context, order: offer, incoming: true); }
        finally { _offerModalOpen = false; }
      } else if (_operationsScroll.hasClients) {
        const offset = 0.0;
        if (MediaQuery.disableAnimationsOf(context)) {
          _operationsScroll.jumpTo(offset);
        } else {
          await _operationsScroll.animateTo(offset,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
        }
      }
    });
  }

  Future<void> _showDeliverySheet(
    BuildContext context, {
    required Map<String, dynamic> order,
    required bool incoming,
  }) async {
    if(_deliverySheetActive)return;
    _deliverySheetActive=true;
    if(incoming){
      _soundingOfferId=(order['offerId']??order['orderId']).toString();
      final expiry=DateTime.tryParse(order['expiresAt']?.toString()??'');
      if(expiry!=null)startDeliveryOfferSound(expiry);
    }
    try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .58),
      isDismissible: !incoming,
      enableDrag: !incoming,
      builder: (sheetContext) => incoming ? IncomingDeliveryOfferSheet(
        order:order,
        updates:AppState.instance,
        isAvailable:()=>AppState.instance.courierOffers.any((offer)=>offer['offerId']?.toString()==order['offerId']?.toString()),
        onAccept:()=>AppState.instance.acceptDelivery(order['orderId'].toString()),
        onReject:()=>AppState.instance.rejectDelivery(order['orderId'].toString()),
      ) : _DeliveryDetailsSheet(
        order: order,
        incoming: incoming,
        onAccept: null,
        onReject: null,
        onAdvance: incoming
            ? null
            : (status) async {
                if (status == 'DELIVERED') {
                  await _confirmDeliveryWithPin(
                    sheetContext,
                    order['id'].toString(),
                  );
                  return;
                }

                try {
                  await AppState.instance.advanceDelivery(
                    order['id'].toString(),
                    status,
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: PrimeText(PrimeMessages.friendly(e)),
                      ),
                    );
                  }
                }
              },
      ),
    );
    } finally {
      _deliverySheetActive=false;
      if(incoming){stopDeliveryOfferSound();_soundingOfferId=null;}
    }
  }

  Future<void> _confirmDeliveryWithPin(
    BuildContext context,
    String orderId,
  ) async {
    final pin = TextEditingController();
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !loading,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
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
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.mint, Color(0xFFF6FBF9)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.mintStrong),
                  ),
                  child: const Icon(
                    AppIcons.pin_rounded,
                    color: AppColors.oceanDeep,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 17),
                const PrimeText(
                  'Confirme com o cliente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: AppFontWeight.display,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 8),
                const PrimeText(
                  'Peça ao cliente o PIN de 4 dígitos exibido no acompanhamento do pedido. A entrega só será concluída com o código correto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                    height: 1.5,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(scrollPadding: const EdgeInsets.all(80), controller: pin,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight: AppFontWeight.display,
                  ),
                  decoration: PrimeInputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8C1BD),
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          AppIcons.error_outline_rounded,
                          color: AppColors.coralStrong,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimeText(PrimeMessages.friendly(error!),
                            style: const TextStyle(
                              color: AppColors.coralStrong,
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.strong,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: const PrimeText('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                if (pin.text.length != 4) {
                                  setDialogState(
                                    () => error =
                                        'Digite os 4 dígitos informados pelo cliente.',
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  loading = true;
                                  error = null;
                                });

                                try {
                                  await AppState.instance.advanceDelivery(
                                    orderId,
                                    'DELIVERED',
                                    pin: pin.text,
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                  if (context.mounted && Navigator.of(context).canPop()) {
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    setDialogState(() {
                                      error = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                      loading = false;
                                    });
                                  }
                                }
                              },
                        icon: loading
                            ? const SizedBox.shrink()
                            : const Icon(AppIcons.verified_rounded, size: 18),
                        label: loading
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const PrimeText('Confirmar entrega'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    pin.dispose();
  }

  Future<void> _openDriverMenu(BuildContext context) async {
    try { await AppState.instance.loadWallet(); } catch (_) {}
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (menuContext) => _DriverMenuSheet(
        onSelect: (section) {
          Navigator.pop(menuContext);
          Future<void>.delayed(
            const Duration(milliseconds: 120),
            () {
              if (mounted) _openDriverSection(context, section);
            },
          );
        },
      ),
    );
  }

  Future<void> _openDriverSection(
    BuildContext context,
    String section,
  ) async {
    if (section == 'home') return;
    try {
      await Future.wait([
        AppState.instance.refreshCourier(),
        AppState.instance.loadWallet(),
      ]);
    } catch (_) {}
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .50),
      builder: (sectionContext) => _DriverSectionSheet(
        section: section,
        onMenu: () {
          Navigator.pop(sectionContext);
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _openDriverMenu(context);
          });
        },
        onLogout: () {
          Navigator.pop(sectionContext);
          Future<void>.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _confirmLogout();
          });
        },
        onWithdraw: () => _requestWithdrawal(context),
        onOpenDelivery: (order) => _showDeliverySheet(
          context,
          order: order,
          incoming: false,
        ),
      ),
    );
  }

  Future<void> _requestWithdrawal(BuildContext context) async {
    if (_withdrawalDialogOpen) return;
    _withdrawalDialogOpen = true;
    final accountId = AppState.instance.user?['id'];
    final controller = TextEditingController();
    final pixController = TextEditingController(text: AppState.instance.walletSummary['pixKey']?.toString() ?? '');
    final savedType = AppState.instance.walletSummary['pixKeyType']?.toString();
    String? pixType = const ['CPF','CNPJ','EMAIL','PHONE','RANDOM'].contains(savedType) ? savedType : null;
    String? error;
    bool loading = false;

    try {
      final receipt = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .55),
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => PopScope(canPop: !loading, child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.elevated,
              ),
              child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PrimeText(
                    'Solicitar saque',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: AppFontWeight.display,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  PrimeText(
                    'Disponível: ' +
                        _money(
                          AppState.instance
                              .walletSummary['availableBalance'],
                        ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.strong,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(scrollPadding: const EdgeInsets.all(80), controller: controller,
                    enabled: !loading,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const PrimeInputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                      prefixIcon: Icon(AppIcons.payments_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(isExpanded: true, itemHeight: null, 
                    initialValue: pixType,
                    decoration: const PrimeInputDecoration(labelText: 'Tipo de chave PIX'),
                    items: const [DropdownMenuItem(value:'CPF',child:PrimeText('CPF')),DropdownMenuItem(value:'CNPJ',child:PrimeText('CNPJ')),DropdownMenuItem(value:'EMAIL',child:PrimeText('E-mail')),DropdownMenuItem(value:'PHONE',child:PrimeText('Celular')),DropdownMenuItem(value:'RANDOM',child:PrimeText('Aleatória'))],
                    onChanged: loading ? null : (value) => setDialogState(() => pixType = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(scrollPadding: const EdgeInsets.all(80), controller: pixController, enabled: !loading, decoration: const PrimeInputDecoration(labelText: 'Chave PIX de recebimento', helperText: 'Confira a chave antes de solicitar o saque.')),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.peach,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: PrimeText(PrimeMessages.friendly(error!),
                        style: const TextStyle(
                          color: AppColors.coralStrong,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.strong,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const PrimeText(
                    'Sua solicitação de saque ficará pendente até o processamento.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                      height: 1.4,
                      fontWeight: AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const PrimeText('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final raw = controller.text
                                      .replaceAll(',', '.')
                                      .trim();
                                  final amount = double.tryParse(raw);
                                  if (amount == null || amount <= 0) {
                                    setDialogState(
                                      () => error = 'Informe um valor válido.',
                                    );
                                    return;
                                  }
                                  setDialogState(() {
                                    loading = true;
                                    error = null;
                                  });
                                  try {
                                    final created = await AppState.instance
                                        .requestWithdrawal(amount, pixKey: pixController.text.trim(), pixKeyType: pixType);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext, created);
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() {
                                        loading = false;
                                        error = e
                                            .toString()
                                            .replaceFirst('Exception: ', '');
                                      });
                                    }
                                  }
                                },
                          child: loading
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const PrimeText('Solicitar'),
                        ),
                      ),
                    ],
                  ),
                ],
              )),
            ),
          )),
        ),
      );
      if (!mounted || !context.mounted || receipt == null ||
          AppState.instance.user?['id'] != accountId || !AppState.instance.isCourier) return;
      final status = receipt['status']?.toString() ?? '';
      if (!courierWithdrawalAcknowledged(status)) return;
      await showDialog<void>(context: context,
        barrierColor: Colors.black.withValues(alpha: .35),
        builder: (_) => CourierWithdrawalFeedback(status: status,
          amount: double.tryParse(receipt['amount']?.toString() ?? '')));
    } finally {
      controller.dispose();
      pixController.dispose();
      _withdrawalDialogOpen = false;
    }
  }

  Future<void> _loadReadUpdates() async {
    final account = AppState.instance.user?['id']?.toString();
    if (account == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('courier-dashboard-read-' + account) ?? [];
      if (mounted && AppState.instance.user?['id']?.toString() == account) {
        setState(() => _readUpdateIds.addAll(saved));
      }
    } catch (_) {}
  }

  Future<void> _saveReadUpdates() async {
    final account = AppState.instance.user?['id']?.toString();
    if (account == null) return;
    final ids = _readUpdateIds.toList().reversed.take(200).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('courier-dashboard-read-' + account, ids);
    } catch (_) {}
  }

  void _scrollHome() {
    HapticFeedback.selectionClick();
    if (!_operationsScroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _operationsScroll.jumpTo(0);
    } else {
      _operationsScroll.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  Future<void> _dashboardSection(int index, String section) async {
    if (_signingOut || _navBusy || _advancing || (_offerActionBusy && AppState.instance.courierDelivery == null)) return;
    setState(() { _navBusy = true; _navIndex = index; });
    try { await _openDriverSection(context, section); }
    catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
    } finally {
      if (mounted) setState(() { _navBusy = false; _navIndex = 0; });
    }
  }

  Future<void> _dashboardDeliveries() async {
    final current = AppState.instance.courierDelivery;
    if (current == null) { await _dashboardSection(1, 'deliveries'); return; }
    if (_signingOut || _navBusy || _advancing || (_offerActionBusy && AppState.instance.courierDelivery == null)) return;
    setState(() { _navBusy = true; _navIndex = 1; });
    try { await _showDeliverySheet(context, order: Map<String, dynamic>.from(current), incoming: false); }
    finally { if (mounted) setState(() { _navBusy = false; _navIndex = 0; }); }
  }

  Future<void> _advanceCurrent(Map<String, dynamic> current) async {
    if (_advancing) return;
    final next = _nextStatus(current['status']?.toString());
    if (next == null) return;
    setState(() => _advancing = true);
    try {
      if (next == 'DELIVERED') {
        await _confirmDeliveryWithPin(context, current['id'].toString());
      } else {
        await AppState.instance.advanceDelivery(current['id'].toString(), next);
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
    } finally { if (mounted) setState(() => _advancing = false); }
  }

  Future<void> _refreshDashboard() async {
    try { await AppState.instance.refreshCourier(); }
    catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
    }
  }

  void _offerResolved() {
    stopDeliveryOfferSound(); _soundingOfferId = null;
    if (mounted) setState(() {});
    unawaited(AppState.instance.refreshCourierOperations().catchError((_) {}));
  }

  List<CourierDashboardUpdate> _dashboardUpdates(AppState state) {
    final rows = <CourierDashboardUpdate>[];
    for (final raw in state.courierOffers.whereType<Map>()) {
      final offer = Map<String, dynamic>.from(raw);
      final expiry = DateTime.tryParse(offer['expiresAt']?.toString() ?? '');
      if (expiry == null || !expiry.isAfter(DateTime.now())) continue;
      rows.add(CourierDashboardUpdate(
        id: 'offer:' + (offer['offerId'] ?? offer['orderId']).toString(),
        title: 'Nova entrega', detail: _money(offer['courierEarnings'] ?? offer['deliveryFee']),
        icon: AppIcons.bike,
        onTap: () => _showDeliverySheet(context, order: offer, incoming: true)));
    }
    final current = state.courierDelivery;
    if (current != null) {
      rows.add(CourierDashboardUpdate(
        id: 'delivery:' + current['id'].toString() + ':' + current['status'].toString(),
        title: 'Entrega em andamento', detail: _statusLabel(current['status']?.toString() ?? ''),
        icon: AppIcons.route, onTap: _dashboardDeliveries));
    }
    final entries = state.walletLedger.isEmpty ? state.walletSummary['recentEntries'] : state.walletLedger;
    if (entries is List) {
      for (final raw in entries.whereType<Map>().take(6)) {
        if (raw['id'] == null) continue;
        final amount = double.tryParse(raw['amount']?.toString() ?? '') ?? 0;
        rows.add(CourierDashboardUpdate(
          id: 'wallet:' + raw['id'].toString(),
          title: amount > 0 ? 'Crédito recebido' : 'Movimentação na carteira',
          detail: _money(amount) + ' • ' + (raw['description'] ?? 'Carteira').toString(),
          icon: AppIcons.wallet, onTap: () => _dashboardSection(2, 'wallet')));
      }
    }
    for (final raw in state.withdrawals.whereType<Map>().take(4)) {
      if (raw['id'] == null) continue;
      rows.add(CourierDashboardUpdate(
        id: 'withdrawal:' + raw['id'].toString() + ':' + raw['status'].toString(),
        title: 'Saque atualizado',
        detail: _money(raw['amount']) + ' • ' + _withdrawalStatus(raw['status']?.toString() ?? ''),
        icon: AppIcons.money, onTap: () => _dashboardSection(2, 'withdrawals')));
    }
    return rows;
  }

  Future<void> _openUpdates() async {
    if (_signingOut || _updatesOpen || (_offerActionBusy && AppState.instance.courierDelivery == null)) return;
    _updatesOpen = true;
    unawaited(AppState.instance.refreshCourier().catchError((_) {}));
    if (!mounted) { _updatesOpen = false; return; }
    try {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, setSheetState) =>
        AnimatedBuilder(animation: AppState.instance, builder: (_, __) {
          final rows = _dashboardUpdates(AppState.instance);
          return CourierUpdatesSheet(rows: rows, readIds: _readUpdateIds,
            onReadAll: () {
              setState(() => _readUpdateIds.addAll(rows.map((r) => r.id)));
              setSheetState(() {});
              unawaited(_saveReadUpdates());
            },
            onSelect: (row) {
              setState(() => _readUpdateIds.add(row.id));
              unawaited(_saveReadUpdates());
              Navigator.pop(sheetContext);
              Future<void>.delayed(const Duration(milliseconds: 150), () {
                if (mounted) row.onTap();
              });
            });
        })));
    } finally { _updatesOpen = false; }
  }

  Future<void> _confirmLogout() async {
    if (_logoutDialogOpen || _signingOut || _navBusy || _advancing || _offerActionBusy) return;
    final state = AppState.instance;
    final account = state.user?['id'];
    _logoutDialogOpen = true;
    try {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(AppIcons.logout, color: courierGreen, size: 29),
        title: const PrimeText('Sair da conta?'),
        content: PrimeText(liveRouteMode(state.courierDelivery) != null
          ? 'Você está em uma rota. Ao sair, o envio da localização será pausado até você entrar novamente.'
          : 'Você poderá entrar novamente quando quiser.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const PrimeText('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: courierGreen),
            child: const PrimeText('Sair da conta')),
        ],
      ));
      if (!mounted || confirmed != true || state.user?['id'] != account) return;
      setState(() => _signingOut = true);
      // Reuse the current-device logout; other accounts and sessions are untouched.
      await state.logout();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: PrimeText(PrimeMessages.friendly(error))));
    } finally {
      _logoutDialogOpen = false;
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final state = AppState.instance;
      if (state.courierRestricted) return const CourierAccountStatus();
      if (_approvalWelcomeUser != null && _approvalWelcomeUser == state.user?['id']?.toString()) {
        return CourierReviewSuccess(approved: true, onOnline: () { if (mounted) setState(() => _approvalWelcomeUser = null); });
      }
      final current = state.courierDelivery == null ? null
        : Map<String, dynamic>.from(state.courierDelivery!);
      if (current?['cancellation'] is Map &&
          ['REQUIRED', 'IN_TRANSIT', 'ARRIVED'].contains(current!['cancellation']['returnStatus'])) {
        return DeliveryReturnPage(order: current);
      }
      final offers = state.courierOffers.whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .where((x) => DateTime.tryParse(x['expiresAt']?.toString() ?? '')?.isAfter(DateTime.now()) == true)
        .toList();
      final updates = _dashboardUpdates(state);
      _presentIncomingOfferIfNeeded(context, state);
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: const Color(0xFFF5F9FA),
          systemNavigationBarColor: const Color(0xFFF5F9FA), systemNavigationBarIconBrightness: Brightness.dark),
        child: Scaffold(backgroundColor: const Color(0xFFF5F9FA),
          bottomNavigationBar: Center(heightFactor: 1, child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CourierOperationsNav(index: _navIndex, online: state.courierOnline,
              active: current != null, busy: _signingOut || _navBusy || _advancing || (_offerActionBusy && current == null),
              onHome: _scrollHome, onAction: _dashboardDeliveries,
              onWallet: () => _dashboardSection(2, 'wallet'),
              onHistory: () => _dashboardSection(3, 'history'),
              onProfile: () => _dashboardSection(4, 'profile')))),
          body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
            child: CourierWorkflowLayout(
              controller: _operationsScroll, online: state.courierOnline,
              accountId: state.user?['id'], onRefresh: _refreshDashboard,
              header: CourierDashboardHeader(
                name: (state.user?['name'] ?? 'Motoboy').toString(),
                photo: state.courierProfile['profilePhoto']?.toString(),
                onProfile: () => _dashboardSection(4, 'profile'),
                online: state.courierOnline, active: current != null,
                waiting: current == null && offers.isEmpty,
                receivingOffer: current == null && state.courierOnline && offers.isNotEmpty,
                unreadCount: updates.where((r) => !_readUpdateIds.contains(r.id)).length,
                onNotifications: _openUpdates,
                onLogout: _signingOut || _navBusy || _advancing || _offerActionBusy ? null : _confirmLogout,
                onRoute: _dashboardDeliveries,
                onChanged: current == null && !_offerActionBusy && !_signingOut ? state.setCourierOnline : null),
              notice: state.courierHighDemand ? CourierDemandNotice(
                online: state.courierOnline, bonusAmount: state.courierDemandBonus, compact: true) : null,
              waitingBuilder: (available, onlineTime) => CourierWaitingPanel(
                online: state.courierOnline, summary: state.walletSummary,
                minimumHeight: available, onlineTime: onlineTime,
                onEarnings: () => _dashboardSection(2, 'earnings'),
                onDeliveries: () => _dashboardSection(1, 'deliveries')),
              delivery: current != null ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (liveRouteMode(current) != null) const CourierTrackingNotice(hideWhenSharing: true),
                CourierAssignedDelivery(order: current, busy: _advancing,
                  primaryLabel: _nextStatus(current['status']?.toString()) == null
                    ? 'Ver detalhes' : _nextLabel(_nextStatus(current['status']?.toString())!),
                  primaryIcon: _nextStatus(current['status']?.toString()) == null
                    ? AppIcons.list : _nextIcon(_nextStatus(current['status']?.toString())!),
                  onDetails: _dashboardDeliveries,
                  onAdvance: _nextStatus(current['status']?.toString()) == null
                    ? _dashboardDeliveries : () => _advanceCurrent(current)),
              ]) : state.courierOnline && offers.isNotEmpty ? IncomingDeliveryOfferSheet(
                key: ValueKey(offers.first['offerId'] ?? offers.first['orderId']),
                order: offers.first, embedded: true, updates: state,
                isAvailable: () => state.courierOffers.any((o) =>
                  o['offerId']?.toString() == offers.first['offerId']?.toString()),
                onResolved: _offerResolved,
                onBusyChanged: (busy) { if (mounted) setState(() => _offerActionBusy = busy); },
                onAccept: () => state.acceptDelivery(offers.first['orderId'].toString()),
                onReject: () => state.rejectDelivery(offers.first['orderId'].toString())) : null,
            ))),
        ));
    },
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimeText(
            eyebrow,
            style: const TextStyle(
              color: AppColors.ocean,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          PrimeText(
            title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.05,
              fontWeight: AppFontWeight.display,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 5),
          PrimeText(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: AppFontSize.caption,
              height: 1.4,
              fontWeight: AppFontWeight.medium,
            ),
          ),
        ],
      );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.order,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dropoff =
        Map<String, dynamic>.from(order['dropoff'] ?? const {});
    final distance = double.tryParse(
      order['routeDistanceKm']?.toString() ?? '',
    );
    final duration = order['routeDurationMinutes'];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.sun200),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      AppIcons.bolt_rounded,
                      color: Color(0xFFA26A14),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PrimeText(
                          'NOVA OFERTA',
                          style: TextStyle(
                            color: Color(0xFFA26A14),
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.display,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 3),
                        PrimeText(
                          'Entrega disponível',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: AppFontWeight.display,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PrimeText(
                    _money(order['courierEarnings'] ?? ((double.tryParse(order['deliveryFee'].toString())??0)+(order['demandSurchargeIncluded']==true?0:(double.tryParse((order['courierDemandBonus']??order['demandBonus']??0).toString())??0)))),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: AppFontWeight.display,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CompactInfo(
                icon: AppIcons.location_on_rounded,
                title: (dropoff['neighborhood'] ?? 'Região de entrega')
                    .toString(),
                subtitle: (dropoff['city'] ?? 'Porto Seguro').toString(),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetric(
                      icon: AppIcons.route_rounded,
                      text: distance == null
                          ? 'Rota calculando'
                          : distance.toStringAsFixed(1) + ' km',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetric(
                      icon: AppIcons.schedule_rounded,
                      text: duration == null
                          ? 'Tempo estimado —'
                          : duration.toString() + ' min',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: PrimeText(
                      'Toque para decidir',
                      style: TextStyle(
                        color: AppColors.oceanDeep,
                        fontSize: AppFontSize.caption,
                        fontWeight: AppFontWeight.display,
                      ),
                    ),
                  ),
                  _OfferCountdown(
                    expiresAt: order['expiresAt'],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.oceanDeep, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: PrimeText(
                text,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display,
                ),
              ),
            ),
          ],
        ),
      );
}

class _OfferCountdown extends StatefulWidget {
  const _OfferCountdown({
    required this.expiresAt,
    this.autoClose = false,
  });
  final dynamic expiresAt;
  final bool autoClose;

  @override
  State<_OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<_OfferCountdown> {
  Timer? timer;
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    _tick();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final expiry = DateTime.tryParse(widget.expiresAt?.toString() ?? '');
    final next = expiry == null
        ? 0
        : expiry.difference(DateTime.now()).inSeconds.clamp(0, 999);
    if (!mounted) return;
    setState(() => seconds = next);
    if (next <= 0 && widget.autoClose) {
      timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 8;
    final progress = (seconds.clamp(0, 30) / 30).toDouble();
    final foreground =
        urgent ? AppColors.coral600 : AppColors.ocean700;
    final background =
        urgent ? AppColors.coral100 : AppColors.ocean50;

    return Semantics(
      label: translateLabel( 'Tempo restante da oferta: ' + seconds.toString() + ' segundos'),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: foreground,
                backgroundColor: foreground.withValues(alpha: .12),
              ),
            ),
            PrimeText(
              seconds.toString() + 's',
              style: TextStyle(
                color: foreground,
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.display,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  const _ActiveDeliveryCard({
    required this.order,
    required this.onOpen,
    required this.onPrimaryAction,
  });

  final Map<String, dynamic> order;
  final VoidCallback onOpen;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final address = Map<String, dynamic>.from(order['address'] ?? {});
    final status = order['status']?.toString() ?? '';
    final next = _nextStatus(status);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusMark(status: status),
              const Spacer(),
              PrimeText(
                '#${_shortId(order['id'])}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          PrimeText(
            order['customer']?['name']?.toString() ?? 'Cliente Porto Prime',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: AppFontWeight.display,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 11),
          _CompactInfo(
            icon: AppIcons.location_on_rounded,
            title:
                '${address['street'] ?? ''}, ${address['number'] ?? ''}',
            subtitle:
                '${address['neighborhood'] ?? ''} • ${address['city'] ?? ''}',
          ),
          const SizedBox(height: 15),
          _DeliveryProgress(status: status),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(AppIcons.receipt_long_rounded, size: 18),
                  label: const PrimeText('Ver detalhes'),
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: 9),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onPrimaryAction,
                    icon: Icon(_nextIcon(next), size: 18),
                    label: PrimeText(_nextLabel(next)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetailsSheet extends StatelessWidget {
  const _DeliveryDetailsSheet({
    required this.order,
    required this.incoming,
    this.onAccept,
    this.onReject,
    this.onAdvance,
  });

  final Map<String, dynamic> order;
  final bool incoming;
  final Future<void> Function()? onAccept;
  final Future<void> Function()? onReject;
  final Future<void> Function(String status)? onAdvance;

  @override
  Widget build(BuildContext context) {
    final address = incoming
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(order['address'] ?? {});
    final customer = incoming
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(order['customer'] ?? {});
    final pickup =
        Map<String, dynamic>.from(order['pickup'] ?? const {});
    final dropoff =
        Map<String, dynamic>.from(order['dropoff'] ?? const {});
    final items = incoming ? const [] : ((order['items'] as List?) ?? const []).where((item)=>!['REFUND_PROCESSING','REFUNDED','VOUCHERED'].contains(item['availabilityStatus'])).toList();
    final status = incoming
        ? 'READY_FOR_PICKUP'
        : order['status']?.toString() ?? 'COURIER_ASSIGNED';
    final next = incoming ? null : _nextStatus(status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 14, 11),
              child: Column(
                children: [
                  Container(
                    width: 43,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.strokeStrong,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: incoming ? AppColors.sand : AppColors.mint,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          incoming
                              ? AppIcons.notifications_active_rounded
                              : AppIcons.route_rounded,
                          color: incoming
                              ? AppColors.warning
                              : AppColors.oceanDeep,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PrimeText(
                              incoming
                                  ? 'NOVA ENTREGA'
                                  : 'ENTREGA EM ANDAMENTO',
                              style: TextStyle(
                                color: incoming
                                    ? AppColors.warning
                                    : AppColors.ocean,
                                fontSize: AppFontSize.caption,
                                fontWeight: AppFontWeight.display,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            PrimeText(
                              incoming
                                  ? 'Confira a oferta antes de decidir'
                                  : 'Sua rota atual',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: AppFontWeight.display,
                                letterSpacing: -.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!incoming)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(AppIcons.close_rounded),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: PrimePageViewport(child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                children: [
                  _SheetHero(order: order, incoming: incoming),
                  const SizedBox(height: 12),
                  if (incoming) ...[
                    _DetailSection(
                      icon: AppIcons.storefront_rounded,
                      title: 'Retirada',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PrimeText(
                            (pickup['name'] ?? 'Porto Prime').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: AppFontWeight.display,
                            ),
                          ),
                          const SizedBox(height: 4),
                          PrimeText(
                            (pickup['region'] ?? 'Base Porto Prime').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: AppIcons.location_on_rounded,
                      title: 'Região de entrega',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PrimeText(
                            (dropoff['neighborhood'] ?? 'Região informada')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: AppFontWeight.display,
                            ),
                          ),
                          const SizedBox(height: 4),
                          PrimeText(
                            (dropoff['city'] ?? 'Porto Seguro').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactMetric(
                            icon: AppIcons.route_rounded,
                            text: order['routeDistanceKm'] == null
                                ? 'Distância —'
                                : double.tryParse(
                                          order['routeDistanceKm'].toString(),
                                        )?.toStringAsFixed(1) ==
                                        null
                                    ? 'Distância —'
                                    : double.parse(
                                              order['routeDistanceKm']
                                                  .toString(),
                                            ).toStringAsFixed(1) +
                                        ' km',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactMetric(
                            icon: AppIcons.schedule_rounded,
                            text: order['routeDurationMinutes'] == null
                                ? 'Percurso —'
                                : order['routeDurationMinutes'].toString() +
                                    ' min',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _CompactMetric(
                      icon: AppIcons.shopping_bag_rounded,
                      text: (order['itemCount'] ?? 0).toString() +
                          ' item(ns) no pedido',
                    ),
                    const SizedBox(height: 12),
                    const _PrivacyOfferNotice(),
                  ] else ...[
                    _DetailSection(
                      icon: AppIcons.person_rounded,
                      title: 'Cliente',
                      child: Column(
                        children: [
                          _DetailRow(
                            label: 'Nome',
                            value: customer['name']?.toString() ?? '—',
                          ),
                          _DetailRow(
                            label: 'Telefone',
                            value: customer['phone']?.toString() ?? '—',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: AppIcons.location_on_rounded,
                      title: 'Destino',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PrimeText(
                            (address['street'] ?? '').toString() +
                                ', ' +
                                (address['number'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: AppFontWeight.display,
                            ),
                          ),
                          const SizedBox(height: 4),
                          PrimeText(
                            (address['neighborhood'] ?? '').toString() +
                                ' • ' +
                                (address['city'] ?? '').toString() +
                                ' - ' +
                                (address['state'] ?? '').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: AppFontSize.caption,
                              height: 1.4,
                              fontWeight: AppFontWeight.medium,
                            ),
                          ),
                          if ((address['complement'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            PrimeText(
                              address['complement'].toString(),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: AppFontSize.caption,
                                fontWeight: AppFontWeight.medium,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: AppIcons.shopping_bag_rounded,
                      title: 'Itens do pedido',
                      child: Column(
                        children: [
                          ...items.map(
                            (raw) {
                              final item =
                                  Map<String, dynamic>.from(raw as Map);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 34),
                                      height: 34,
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.mint,
                                        borderRadius:
                                            BorderRadius.circular(11),
                                      ),
                                      child: PrimeText(
                                        (item['quantity'] ?? 0).toString() +
                                            'x',
                                        style: const TextStyle(
                                          color: AppColors.oceanDeep,
                                          fontSize: AppFontSize.caption,
                                          fontWeight: AppFontWeight.display,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: PrimeText(
                                        item['productName']?.toString() ??
                                            'Produto',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.35,
                                          fontWeight: AppFontWeight.display,
                                        ),
                                      ),
                                    ),
                                    PrimeText(
                                      _money(item['total']),
                                      style: const TextStyle(
                                        fontSize: AppFontSize.caption,
                                        fontWeight: AppFontWeight.display,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: AppIcons.timeline_rounded,
                      title: 'Progresso da entrega',
                      child: _DeliveryProgress(status: status),
                    ),
                    if (next == 'DELIVERED') ...[
                      const SizedBox(height: 10),
                      const _PinNotice(),
                    ],
                  ],
                ],
              )),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: AppColors.stroke),
                ),
              ),
              child: SafeArea(
                top: false,
                child: incoming
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                              ),
                              onPressed: () async {
                                await onReject?.call();
                              },
                              child: const PrimeText('RECUSAR'),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () async {
                                await onAccept?.call();
                              },
                              icon: const Icon(
                                AppIcons.check_circle_rounded,
                                size: 19,
                              ),
                              label: const PrimeText('ACEITAR ENTREGA'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const PrimeText('Fechar'),
                            ),
                          ),
                          if (next != null) ...[
                            const SizedBox(width: 9),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await onAdvance?.call(next);
                                },
                                icon: Icon(_nextIcon(next), size: 18),
                                label: PrimeText(_nextLabel(next)),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyOfferNotice extends StatelessWidget {
  const _PrivacyOfferNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.privacy_tip_rounded,
              color: AppColors.oceanDeep,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: PrimeText(
                'Nome, telefone, rua, número e itens detalhados são liberados somente depois que você aceitar a entrega.',
                style: TextStyle(
                  color: AppColors.oceanDeep,
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                  fontWeight: AppFontWeight.strong,
                ),
              ),
            ),
          ],
        ),
      );
}

class _PinNotice extends StatelessWidget {
  const _PinNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.sun200),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.pin_rounded,
              color: Color(0xFF9A6818),
              size: 21,
            ),
            SizedBox(width: 10),
            Expanded(
              child: PrimeText(
                'Na porta, peça ao cliente o PIN de 4 dígitos. Sem o código correto o pedido não pode ser finalizado.',
                style: TextStyle(
                  color: Color(0xFF846A3C),
                  fontSize: AppFontSize.caption,
                  height: 1.4,
                  fontWeight: AppFontWeight.strong,
                ),
              ),
            ),
          ],
        ),
      );
}

class _SheetHero extends StatelessWidget {
  const _SheetHero({
    required this.order,
    required this.incoming,
  });

  final Map<String, dynamic> order;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final id = incoming ? order['orderId'] : order['id'];
    final customerName = incoming
        ? 'Oferta protegida'
        : order['customer']?['name']?.toString() ?? 'Cliente Porto Prime';
    final amount =
        incoming ? (order['courierEarnings'] ?? order['deliveryFee']) : order['total'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF112C27), Color(0xFF08675C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusMark(
                status: incoming
                    ? 'READY_FOR_PICKUP'
                    : order['status']?.toString() ?? '',
                dark: true,
              ),
              const Spacer(),
              if (incoming)
                _OfferCountdown(
                  expiresAt: order['expiresAt'],
                  autoClose: true,
                )
              else
                PrimeText(
                  '#' + _shortId(id),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                    letterSpacing: .7,
                  ),
                ),
            ],
          ),
          if (!incoming) ...[
            const SizedBox(height:12),
            TextButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(settings:RouteSettings(name:'/delivery-chat/$id'),builder:(_)=>DeliveryChatPage(orderId:id.toString()))),icon:const Icon(AppIcons.mail,color:Colors.white,size:18),label:const PrimeText('Conversar com cliente',style:TextStyle(color:Colors.white))),
          ],
          const SizedBox(height: 17),
          PrimeText(
            customerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: AppFontWeight.display,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          PrimeText(
            incoming
                ? 'Veja somente os dados necessários para decidir.'
                : 'Pedido aceito e vinculado ao seu perfil.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.medium,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                AppIcons.payments_rounded,
                color: Color(0xFF93F2D9),
                size: 18,
              ),
              const SizedBox(width: 7),
              PrimeText(
                incoming ? 'Ganhos da entrega' : 'Valor do pedido',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.strong,
                ),
              ),
              const Spacer(),
              PrimeText(
                _money(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: AppFontWeight.display,
                ),
              ),
            ],
          ),
          if(incoming && (double.tryParse((order['demandBonus']??0).toString())??0)>0) ...[
            const SizedBox(height:10),
            PrimeText('Inclui ${_money(order['demandBonus'])} de bônus garantido nesta oferta.',style:const TextStyle(color:Color(0xFF93F2D9),fontSize:12,fontWeight:FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.oceanDeep,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                PrimeText(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: PrimeText(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.strong,
                ),
              ),
            ),
            Expanded(
              child: PrimeText(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.display,
                ),
              ),
            ),
          ],
        ),
      );
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.oceanDeep, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimeText(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
                const SizedBox(height: 2),
                PrimeText(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                    height: 1.35,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('COURIER_ASSIGNED', 'Aceita', AppIcons.check_rounded),
      ('PICKED_UP', 'Coletada', AppIcons.inventory_2_rounded),
      ('OUT_FOR_DELIVERY', 'Em rota', AppIcons.route_rounded),
      ('DELIVERED', 'Entregue', AppIcons.home_rounded),
    ];

    final currentIndex = switch (status) {
      'COURIER_ASSIGNED' => 0,
      'PICKED_UP' => 1,
      'OUT_FOR_DELIVERY' => 2,
      'DELIVERED' => 3,
      _ => 0,
    };

    return Row(
      children: [
        for (var i = 0; i < stages.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: i <= currentIndex
                        ? AppColors.oceanDeep
                        : AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: i <= currentIndex
                          ? AppColors.oceanDeep
                          : AppColors.stroke,
                    ),
                  ),
                  child: Icon(
                    i < currentIndex ? AppIcons.check_rounded : stages[i].$3,
                    color:
                        i <= currentIndex ? Colors.white : AppColors.muted,
                    size: 17,
                  ),
                ),
                const SizedBox(height: 5),
                PrimeText(
                  stages[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i <= currentIndex
                        ? AppColors.ink
                        : AppColors.muted,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
              ],
            ),
          ),
          if (i < stages.length - 1)
            Container(
              width: 18,
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              color: i < currentIndex
                  ? AppColors.oceanDeep
                  : AppColors.stroke,
            ),
        ],
      ],
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({
    required this.status,
    this.dark = false,
  });

  final String status;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: .10)
              : _statusBackground(status),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: PrimeText(
          _statusLabel(status),
          style: TextStyle(
            color: dark ? Colors.white : _statusColor(status),
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.display,
            letterSpacing: .65,
          ),
        ),
      );
}

class _CourierSnapshot extends StatelessWidget {
  const _CourierSnapshot({
    required this.summary,
    required this.presence,
  });

  final Map<String, dynamic> summary;
  final String presence;

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 9,
        crossAxisSpacing: 9,
        mainAxisExtent: AppResponsive.metricHeight(context),
        children: [
          _SnapshotCard(
            icon: AppIcons.account_balance_wallet_rounded,
            label: 'Saldo disponível',
            value: _money(summary['availableBalance']),
          ),
          _SnapshotCard(
            icon: AppIcons.trending_up_rounded,
            label: 'Ganhos hoje',
            value: _money(summary['earningsToday']),
          ),
          _SnapshotCard(
            icon: AppIcons.check_circle_rounded,
            label: 'Entregas hoje',
            value: (summary['deliveriesToday'] ?? 0).toString(),
          ),
          _SnapshotCard(
            icon: AppIcons.calendar_view_week_rounded,
            label: 'Entregas semana',
            value: (summary['deliveriesWeek'] ?? 0).toString(),
          ),
        ],
      );
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => PrimeMetricCard(icon: icon, label: label, value: value);
}

class _DriverMenuSheet extends StatelessWidget {
  const _DriverMenuSheet({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('home', 'Início', AppIcons.home_rounded),
      ('deliveries', 'Entregas', AppIcons.delivery_dining_rounded),
      ('earnings', 'Ganhos', AppIcons.trending_up_rounded),
      ('wallet', 'Carteira', AppIcons.account_balance_wallet_rounded),
      ('withdrawals', 'Saques', AppIcons.payments_rounded),
      ('history', 'Histórico', AppIcons.history_rounded),
      ('profile', 'Perfil', AppIcons.person_rounded),
      ('vehicle', 'Veículo / Documentos', AppIcons.two_wheeler_rounded),
      ('settings', 'Configurações', AppIcons.settings_rounded),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 43,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stroke,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: 17),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PrimeText(
                        'PORTO PRIME DRIVER',
                        style: TextStyle(
                          color: AppColors.ocean,
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.display,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      PrimeText(
                        'Central do motoboy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: AppFontWeight.display,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.dashboard_customize_rounded,
                  color: AppColors.oceanDeep,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.stroke),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ListTile(
                    onTap: () => onSelect(item.$1),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    leading: Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        item.$3,
                        color: AppColors.oceanDeep,
                        size: 20,
                      ),
                    ),
                    title: PrimeText(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: AppFontWeight.display,
                      ),
                    ),
                    trailing: const Icon(
                      AppIcons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverSectionSheet extends StatelessWidget {
  const _DriverSectionSheet({
    required this.section,
    required this.onWithdraw,
    required this.onOpenDelivery,
    this.onMenu,
    this.onLogout,
  });

  final String section;
  final VoidCallback? onMenu, onLogout;
  final VoidCallback onWithdraw;
  final ValueChanged<Map<String, dynamic>> onOpenDelivery;

  String get title => switch (section) {
        'deliveries' => 'Entregas',
        'earnings' => 'Ganhos',
        'wallet' => 'Carteira',
        'withdrawals' => 'Saques',
        'history' => 'Histórico',
        'profile' => 'Perfil',
        'vehicle' => 'Veículo / Documentos',
        'settings' => 'Configurações',
        _ => 'Início',
      };

  IconData get icon => switch (section) {
        'deliveries' => AppIcons.delivery_dining_rounded,
        'earnings' => AppIcons.trending_up_rounded,
        'wallet' => AppIcons.account_balance_wallet_rounded,
        'withdrawals' => AppIcons.payments_rounded,
        'history' => AppIcons.history_rounded,
        'profile' => AppIcons.person_rounded,
        'vehicle' => AppIcons.two_wheeler_rounded,
        'settings' => AppIcons.settings_rounded,
        _ => AppIcons.home_rounded,
      };

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppState.instance,
        builder: (_, __) {
          final state = AppState.instance;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .93,
            ),
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 12, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.oceanDeep,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: PrimeText(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: AppFontWeight.display,
                              letterSpacing: -.4,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(AppIcons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PrimePageViewport(child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
                      children: _content(context, state),
                    )),
                  ),
                ],
              ),
            ),
          );
        },
      );

  List<Widget> _content(BuildContext context, AppState state) {
    final summary = state.walletSummary;

    if (section == 'earnings') {
      final credits = state.walletLedger
          .map((x) => Map<String, dynamic>.from(x as Map))
          .where((x) => x['type'] == 'DELIVERY_CREDIT' ||
              (x['type'] == 'ADJUSTMENT_CREDIT' && x['metadata'] is Map &&
                  x['metadata']['kind'] == 'ORDER_CANCELLATION'))
          .toList();
      return [
        _FinanceHero(
          eyebrow: 'GANHOS DE HOJE',
          value: _money(summary['earningsToday']),
          subtitle: 'Semana: ' + _money(summary['earningsWeek']),
          icon: AppIcons.trending_up_rounded,
        ),
        const SizedBox(height: 16),
        ..._ledgerWidgets(credits),
      ];
    }

    if (section == 'wallet') {
      final ledger = state.walletLedger
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      return [
        _FinanceHero(
          eyebrow: 'SALDO DISPONÍVEL',
          value: _money(summary['availableBalance']),
          subtitle: 'Saldo total: ' + _money(summary['totalBalance']),
          icon: AppIcons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisExtent: AppResponsive.metricHeight(context),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            _SnapshotCard(icon: AppIcons.money, label: 'Ganhos hoje',
              value: _money(summary['earningsToday'])),
            _SnapshotCard(icon: AppIcons.calendar, label: 'Ganhos na semana',
              value: _money(summary['earningsWeek'])),
          ],
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: FilledButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(AppIcons.payments_rounded),
            label: const PrimeText('Solicitar saque'),
          ),
        ),
        const SizedBox(height: 16),
        ..._ledgerWidgets(ledger),
      ];
    }

    if (section == 'withdrawals') {
      final rows = state.withdrawals
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
      return [
        _FinanceHero(
          eyebrow: 'DISPONÍVEL PARA SAQUE',
          value: _money(summary['availableBalance']),
          subtitle: 'Em processamento: ' +
              _money(summary['pendingWithdrawals']),
          icon: AppIcons.payments_rounded,
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: FilledButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(AppIcons.add_card_rounded),
            label: const PrimeText('Nova solicitação'),
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _DriverEmpty(
            icon: AppIcons.account_balance_rounded,
            title: 'Nenhum saque solicitado',
            subtitle:
                'Solicitações aparecerão aqui como pendente, processamento, pago ou rejeitado.',
          )
        else
          ...rows.map((row) => _WithdrawalRow(row: row)),
      ];
    }

    if (section == 'profile') {
      final user = state.user ?? {};
      return [
        if (onMenu != null) ...[
          OutlinedButton.icon(onPressed: onMenu, icon: const Icon(AppIcons.settings, size: 19),
            label: const PrimeText('Mais opções da conta')),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const SupportPage())),icon:const Icon(AppIcons.help,size:19),label:const PrimeText('Ajuda e suporte')),
        const SizedBox(height:16),
        const CourierPhotoCard(),
        const SizedBox(height:14),
        _DataPanel(
          title: 'Conta',
          icon: AppIcons.person_rounded,
          rows: [
            ('Nome', (user['name'] ?? '—').toString()),
            ('E-mail', (user['email'] ?? '—').toString()),
            ('Telefone', (user['phone'] ?? '—').toString()),
            ('Perfil', 'Motoboy'),
          ],
        ),
        if (onLogout != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(onPressed: onLogout, icon: const Icon(AppIcons.logout, size: 19),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger,
              minimumSize: const Size(44, 48)),
            label: const PrimeText('Sair da conta')),
        ],
      ];
    }

    if (section == 'vehicle') {
      final p = state.courierProfile;
      return [
        _DataPanel(
          title: 'Documentos',
          icon: AppIcons.badge_rounded,
          rows: [
            ('CPF', (p['document'] ?? '—').toString()),
            ('CNH', (p['cnh'] ?? '—').toString()),
            ('Categoria', (p['cnhCategory'] ?? '—').toString()),
          ],
        ),
        const SizedBox(height: 10),
        _DataPanel(
          title: 'Veículo',
          icon: AppIcons.two_wheeler_rounded,
          rows: [
            ('Marca', (p['vehicleBrand'] ?? '—').toString()),
            ('Modelo', (p['vehicleModel'] ?? '—').toString()),
            ('Placa', (p['vehiclePlate'] ?? '—').toString()),
            ('Ano', (p['vehicleYear'] ?? '—').toString()),
          ],
        ),
      ];
    }

    if (section == 'settings') {
      return [
        _DataPanel(
          title: 'Disponibilidade',
          icon: AppIcons.radar_rounded,
          custom: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.courierOnline,
            onChanged: state.courierDelivery == null
                ? state.setCourierOnline
                : null,
            title: const PrimeText(
              'Receber novas ofertas',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: AppFontWeight.display,
              ),
            ),
            subtitle: PrimeText(
              state.courierPresenceStatus.replaceAll('_', ' '),
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: OutlinedButton.icon(
            onPressed: state.logout,
            icon: const Icon(AppIcons.logout_rounded),
            label: const PrimeText('Sair deste dispositivo'),
          ),
        ),
      ];
    }

    final history = state.courierHistory
        .map((x) => Map<String, dynamic>.from(x as Map))
        .toList();

    if (section == 'deliveries') {
      return [
        if (state.courierDelivery != null) ...[
          const _SectionTitle(
            eyebrow: 'AGORA',
            title: 'Entrega atual',
            subtitle: 'Pedido vinculado exclusivamente ao seu perfil.',
          ),
          const SizedBox(height: 10),
          _ActiveDeliveryCard(
            order: Map<String, dynamic>.from(state.courierDelivery!),
            onOpen: () => onOpenDelivery(
              Map<String, dynamic>.from(state.courierDelivery!),
            ),
            onPrimaryAction: () => onOpenDelivery(
              Map<String, dynamic>.from(state.courierDelivery!),
            ),
          ),
          const SizedBox(height: 18),
        ],
        const _SectionTitle(
          eyebrow: 'HISTÓRICO',
          title: 'Últimas entregas',
          subtitle: 'Registros reais da sua operação.',
        ),
        const SizedBox(height: 10),
        ..._historyWidgets(history),
      ];
    }

    return [
      const _SectionTitle(
        eyebrow: 'HISTÓRICO',
        title: 'Entregas realizadas',
        subtitle: 'Todos os pedidos concluídos ou encerrados.',
      ),
      const SizedBox(height: 10),
      ..._historyWidgets(history),
    ];
  }

  List<Widget> _ledgerWidgets(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const [
        _DriverEmpty(
          icon: AppIcons.receipt_long_rounded,
          title: 'Sem movimentações',
          subtitle:
              'Créditos, débitos, saques e estornos aparecerão no seu extrato.',
        ),
      ];
    }
    return rows.take(80).map((x) => _LedgerRow(entry: x)).toList();
  }

  List<Widget> _historyWidgets(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const [
        _DriverEmpty(
          icon: AppIcons.history_rounded,
          title: 'Histórico vazio',
          subtitle: 'Entregas finalizadas aparecerão aqui.',
        ),
      ];
    }
    return rows.take(80).map((x) => _HistoryRow(order: x)).toList();
  }
}

class _FinanceHero extends StatelessWidget {
  const _FinanceHero({
    required this.eyebrow,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context)=>PrimeBalancePanel(label:eyebrow,value:value,note:subtitle,icon:icon);
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(entry['amount']?.toString() ?? '0') ?? 0;
    final positive = amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(
            positive ? AppIcons.south_west_rounded : AppIcons.north_east_rounded,
            color: positive
                ? AppColors.oceanDeep
                : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrimeText(
                  (entry['description'] ?? 'Movimentação').toString(),
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
                const SizedBox(height: 2),
                PrimeText(
                  _date(entry['createdAt']),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
          PrimeText(
            (positive ? '+ ' : '- ') + _money(amount.abs()),
            style: TextStyle(
              color: positive
                  ? AppColors.oceanDeep
                  : AppColors.warning,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            const Icon(
              AppIcons.payments_rounded,
              color: AppColors.oceanDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrimeText(
                    _money(row['amount']),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: AppFontWeight.display,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PrimeText(
                    _date(row['requestedAt']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ],
              ),
            ),
          PrimeText(
            _withdrawalStatus((row['status'] ?? '').toString()),
            style: const TextStyle(
              color: AppColors.oceanDeep,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.display,
            ),
          ),
        ],
      ),
    );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(
              order['status'] == 'DELIVERED'
                  ? AppIcons.check_circle_rounded
                  : AppIcons.cancel_rounded,
              color: order['status'] == 'DELIVERED'
                  ? AppColors.oceanDeep
                  : AppColors.coralStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PrimeText(
                    'Entrega #' + _shortId(order['id']),
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: AppFontWeight.display,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PrimeText(
                    _date(order['deliveredAt'] ?? order['updatedAt']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
                ],
              ),
            ),
            PrimeText(
              _money(order['courierEarnings'] ?? ((double.tryParse(order['deliveryFee'].toString())??0)+(order['demandSurchargeIncluded']==true?0:(double.tryParse((order['courierDemandBonus']??order['demandBonus']??0).toString())??0)))),
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                fontWeight: AppFontWeight.display,
              ),
            ),
          ],
        ),
      );
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.title,
    required this.icon,
    this.rows = const [],
    this.custom,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;
  final Widget? custom;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.oceanDeep, size: 20),
                const SizedBox(width: 9),
                PrimeText(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (custom != null)
              custom!
            else
              ...rows.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: PrimeText(
                          row.$1,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.strong,
                          ),
                        ),
                      ),
                      Expanded(
                        child: PrimeText(
                          row.$2,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.display,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  String two(int n) => n.toString().padLeft(2, '0');
  return two(date.day) +
      '/' +
      two(date.month) +
      '/' +
      date.year.toString() +
      ' • ' +
      two(date.hour) +
      ':' +
      two(date.minute);
}

String _withdrawalStatus(String value) => switch (value) {
      'PENDING' => 'PENDENTE',
      'PROCESSING' => 'EM PROCESSAMENTO',
      'PAID' => 'PAGO',
      'REJECTED' => 'REJEITADO',
      _ => value,
    };

class _DriverEmpty extends StatelessWidget {
  const _DriverEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(26, 31, 26, 31),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Container(
              width: 63,
              height: 63,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.oceanDeep, size: 29),
            ),
            const SizedBox(height: 15),
            PrimeText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: AppFontWeight.display,
              ),
            ),
            const SizedBox(height: 6),
            PrimeText(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: AppFontSize.caption,
                height: 1.5,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ],
        ),
      );
}

String? _nextStatus(String? status) => switch (status) {
      'COURIER_ASSIGNED' => 'PICKED_UP',
      'PICKED_UP' => 'OUT_FOR_DELIVERY',
      'OUT_FOR_DELIVERY' => 'DELIVERED',
      _ => null,
    };

String _nextLabel(String status) => switch (status) {
      'PICKED_UP' => 'Confirmar coleta',
      'OUT_FOR_DELIVERY' => 'Iniciar rota',
      'DELIVERED' => 'Concluir com PIN',
      _ => 'Continuar',
    };

IconData _nextIcon(String status) => switch (status) {
      'PICKED_UP' => AppIcons.inventory_2_rounded,
      'OUT_FOR_DELIVERY' => AppIcons.route_rounded,
      'DELIVERED' => AppIcons.pin_rounded,
      _ => AppIcons.arrow_forward_rounded,
    };

String _statusLabel(String status) => switch (status) {
      'READY_FOR_PICKUP' => 'PRONTA PARA COLETA',
      'COURIER_ASSIGNED' => 'ACEITA',
      'PICKED_UP' => 'COLETADA',
      'OUT_FOR_DELIVERY' => 'EM ROTA',
      'DELIVERED' => 'ENTREGUE',
      _ => status.replaceAll('_', ' '),
    };

Color _statusBackground(String status) => switch (status) {
      'OUT_FOR_DELIVERY' => AppColors.sky,
      'DELIVERED' => AppColors.mint,
      'PICKED_UP' => AppColors.sand,
      _ => AppColors.mint,
    };

Color _statusColor(String status) => switch (status) {
      'OUT_FOR_DELIVERY' => AppColors.sky700,
      'PICKED_UP' => AppColors.warning,
      _ => AppColors.oceanDeep,
    };

String _shortId(dynamic value) {
  final id = value?.toString() ?? '';
  if (id.length <= 8) return id.toUpperCase();
  return id.substring(id.length - 8).toUpperCase();
}

String _money(dynamic value) {
  final number = double.tryParse(value?.toString() ?? '') ?? 0;
  return 'R\$ ${number.toStringAsFixed(2).replaceAll('.', ',')}';
}


