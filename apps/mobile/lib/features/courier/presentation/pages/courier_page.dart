import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';

class CourierPage extends StatefulWidget {
  const CourierPage({super.key});

  @override
  State<CourierPage> createState() => _CourierPageState();
}

class _CourierPageState extends State<CourierPage> {
  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  String? _lastPresentedOfferId;
  bool _offerModalOpen = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      try {
        await AppState.instance.refreshCourier();
        await AppState.instance.loadWallet();
        await AppState.instance.heartbeatCourier();
      } catch (_) {}
    });
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) async {
        try {
          await AppState.instance.heartbeatCourier();
        } catch (_) {}
      },
    );
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        try {
          await AppState.instance.refreshCourier();
        } catch (_) {}
      },
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _presentIncomingOfferIfNeeded(
    BuildContext context,
    AppState state,
  ) {
    if (_offerModalOpen ||
        state.courierDelivery != null ||
        !state.courierOnline ||
        state.courierOffers.isEmpty) {
      return;
    }

    final offer = Map<String, dynamic>.from(state.courierOffers.first);
    final id =
        offer['offerId']?.toString() ?? offer['orderId']?.toString();
    if (id == null || id == _lastPresentedOfferId) return;

    _lastPresentedOfferId = id;
    _offerModalOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showDeliverySheet(
        context,
        order: offer,
        incoming: true,
      );
      _offerModalOpen = false;
    });
  }

  Future<void> _showDeliverySheet(
    BuildContext context, {
    required Map<String, dynamic> order,
    required bool incoming,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .58),
      isDismissible: !incoming,
      enableDrag: !incoming,
      builder: (sheetContext) => _DeliveryDetailsSheet(
        order: order,
        incoming: incoming,
        onAccept: incoming
            ? () async {
                try {
                  await AppState.instance.acceptDelivery(
                    (incoming ? order['orderId'] : order['id']).toString(),
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              }
            : null,
        onReject: incoming
            ? () async {
                try {
                  await AppState.instance.rejectDelivery(
                    order['orderId'].toString(),
                  );
                } finally {
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                }
              }
            : null,
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
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
      ),
    );
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
              borderRadius: BorderRadius.circular(30),
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
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: AppColors.mintStrong),
                  ),
                  child: const Icon(
                    Icons.pin_rounded,
                    color: AppColors.oceanDeep,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Confirme com o cliente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.55,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Peça ao cliente o PIN de 4 dígitos exibido no acompanhamento do pedido. A entrega só será concluída com o código correto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: pin,
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
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8C1BD),
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.canvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(19),
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.coralStrong,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: AppColors.coralStrong,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
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
                        child: const Text('Cancelar'),
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
                                  if (context.mounted) {
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
                            : const Icon(Icons.verified_rounded, size: 18),
                        label: loading
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirmar entrega'),
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
    await AppState.instance.loadWallet();
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
      builder: (_) => _DriverSectionSheet(
        section: section,
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
    final controller = TextEditingController();
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(29),
              boxShadow: AppShadows.elevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solicitar saque',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Disponível: ' +
                      _money(
                        AppState.instance
                            .walletSummary['availableBalance'],
                      ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.peach,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.coralStrong,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'A solicitação ficará pendente até processamento. O app não simula transferência bancária.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.3,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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
                        child: const Text('Cancelar'),
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
                                  await AppState.instance
                                      .requestWithdrawal(amount);
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
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
                            : const Text('Solicitar'),
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

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: AppState.instance,
        builder: (_, __) {
          final state = AppState.instance;
          final current = state.courierDelivery == null
              ? null
              : Map<String, dynamic>.from(state.courierDelivery!);
          final offers = state.courierOffers
              .map((x) => Map<String, dynamic>.from(x))
              .toList();
          final first = (state.user?['name'] ?? 'Motoboy')
              .toString()
              .split(' ')
              .first;

          _presentIncomingOfferIfNeeded(context, state);

          return Scaffold(
            backgroundColor: AppColors.canvas,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: state.refreshCourier,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                  children: [
                    _DriverHeader(
                      firstName: first,
                      online: state.courierOnline,
                      onMenu: () => _openDriverMenu(context),
                      onLogout: state.logout,
                    ),
                    const SizedBox(height: 18),
                    _AvailabilityHero(
                      hasActiveDelivery: current != null,
                      online: state.courierOnline,
                      onChanged:
                          current == null ? state.setCourierOnline : null,
                    ),
                    const SizedBox(height: 12),
                    _CourierSnapshot(
                      summary: state.walletSummary,
                      presence: state.courierPresenceStatus,
                    ),
                    if (current != null) ...[
                      const SizedBox(height: 22),
                      const _SectionTitle(
                        eyebrow: 'MISSÃO ATUAL',
                        title: 'Entrega em andamento',
                        subtitle:
                            'Uma rota por vez. Todos os detalhes ficam reunidos aqui.',
                      ),
                      const SizedBox(height: 12),
                      _ActiveDeliveryCard(
                        order: current,
                        onOpen: () => _showDeliverySheet(
                          context,
                          order: current,
                          incoming: false,
                        ),
                        onPrimaryAction: () async {
                          final next =
                              _nextStatus(current['status']?.toString());
                          if (next == null) return;
                          if (next == 'DELIVERED') {
                            await _confirmDeliveryWithPin(
                              context,
                              current['id'].toString(),
                            );
                          } else {
                            try {
                              await state.advanceDelivery(
                                current['id'].toString(),
                                next,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 22),
                      _SectionTitle(
                        eyebrow: 'RADAR DE ENTREGAS',
                        title: state.courierOnline
                            ? 'Chamadas disponíveis'
                            : 'Entre online para receber',
                        subtitle: state.courierOnline
                            ? 'Novos pedidos liberados aparecem automaticamente.'
                            : 'Quando estiver pronto para rodar, ative sua disponibilidade.',
                      ),
                      const SizedBox(height: 12),
                      if (!state.courierOnline)
                        const _DriverEmpty(
                          icon: Icons.power_settings_new_rounded,
                          title: 'Você está offline',
                          subtitle:
                              'Ative o modo online acima para começar a receber chamadas de entrega.',
                        )
                      else if (offers.isEmpty)
                        const _DriverEmpty(
                          icon: Icons.radar_rounded,
                          title: 'Radar ativo',
                          subtitle:
                              'Estamos procurando pedidos liberados pela operação. Assim que uma entrega chegar, você verá a chamada na tela.',
                        )
                      else
                        ...offers.map(
                          (offer) => Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _OfferCard(
                              order: offer,
                              onTap: () => _showDeliverySheet(
                                context,
                                order: offer,
                                incoming: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({
    required this.firstName,
    required this.online,
    required this.onMenu,
    required this.onLogout,
  });

  final String firstName;
  final bool online;
  final VoidCallback onMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 51,
            height: 51,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: AppColors.oceanDeep,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PORTO PRIME DRIVER',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.45,
                    color: AppColors.ocean,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Olá, $firstName',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: online ? AppColors.mint : const Color(0xFFF0F2F0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: online ? AppColors.success : AppColors.muted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  online ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color:
                        online ? AppColors.oceanDeep : AppColors.muted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Menu do motoboy',
            onPressed: onMenu,
            icon: const Icon(Icons.grid_view_rounded, size: 20),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
        ],
      );
}

class _AvailabilityHero extends StatelessWidget {
  const _AvailabilityHero({
    required this.hasActiveDelivery,
    required this.online,
    required this.onChanged,
  });

  final bool hasActiveDelivery;
  final bool online;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF102923),
              Color(0xFF075C51),
              Color(0xFF0A7B6D),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.oceanDeep.withValues(alpha: .22),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 59,
              height: 59,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
              child: Icon(
                hasActiveDelivery
                    ? Icons.route_rounded
                    : online
                        ? Icons.radar_rounded
                        : Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActiveDelivery
                        ? 'Entrega ativa'
                        : online
                            ? 'Radar ligado'
                            : 'Pronto para rodar?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasActiveDelivery
                        ? 'Finalize esta rota antes de aceitar outra.'
                        : online
                            ? 'Você receberá novas chamadas automaticamente.'
                            : 'Ative o modo online quando estiver disponível.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasActiveDelivery)
              Switch.adaptive(
                value: online,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.turquoise,
              ),
          ],
        ),
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
          Text(
            eyebrow,
            style: const TextStyle(
              color: AppColors.ocean,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFF0DBB4)),
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFA26A14),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOVA OFERTA',
                          style: TextStyle(
                            color: Color(0xFFA26A14),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Entrega disponível',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _money(order['deliveryFee']),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CompactInfo(
                icon: Icons.location_on_rounded,
                title: (dropoff['neighborhood'] ?? 'Região de entrega')
                    .toString(),
                subtitle: (dropoff['city'] ?? 'Porto Seguro').toString(),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _CompactMetric(
                      icon: Icons.route_rounded,
                      text: distance == null
                          ? 'Rota calculando'
                          : distance.toStringAsFixed(1) + ' km',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactMetric(
                      icon: Icons.schedule_rounded,
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
                    child: Text(
                      'Toque para decidir',
                      style: TextStyle(
                        color: AppColors.oceanDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.oceanDeep, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
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
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seconds <= 8 ? AppColors.peach : AppColors.sand,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          seconds.toString() + 's',
          style: TextStyle(
            color: seconds <= 8
                ? AppColors.coralStrong
                : const Color(0xFF936417),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
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
        borderRadius: BorderRadius.circular(27),
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
              Text(
                '#${_shortId(order['id'])}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            order['customer']?['name']?.toString() ?? 'Cliente Porto Prime',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 11),
          _CompactInfo(
            icon: Icons.location_on_rounded,
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
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('Ver detalhes'),
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: 9),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onPrimaryAction,
                    icon: Icon(_nextIcon(next), size: 18),
                    label: Text(_nextLabel(next)),
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
    final items = incoming ? const [] : ((order['items'] as List?) ?? const []);
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
                      color: const Color(0xFFD4DCD8),
                      borderRadius: BorderRadius.circular(20),
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
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(
                          incoming
                              ? Icons.notifications_active_rounded
                              : Icons.route_rounded,
                          color: incoming
                              ? const Color(0xFFA26A14)
                              : AppColors.oceanDeep,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incoming
                                  ? 'NOVA ENTREGA'
                                  : 'ENTREGA EM ANDAMENTO',
                              style: TextStyle(
                                color: incoming
                                    ? const Color(0xFFA26A14)
                                    : AppColors.ocean,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incoming
                                  ? 'Confira a oferta antes de decidir'
                                  : 'Sua rota atual',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!incoming)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                children: [
                  _SheetHero(order: order, incoming: incoming),
                  const SizedBox(height: 12),
                  if (incoming) ...[
                    _DetailSection(
                      icon: Icons.storefront_rounded,
                      title: 'Retirada',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (pickup['name'] ?? 'Porto Prime').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (pickup['region'] ?? 'Base Porto Prime').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: Icons.location_on_rounded,
                      title: 'Região de entrega',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (dropoff['neighborhood'] ?? 'Região informada')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (dropoff['city'] ?? 'Porto Seguro').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
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
                            icon: Icons.route_rounded,
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
                            icon: Icons.schedule_rounded,
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
                      icon: Icons.shopping_bag_rounded,
                      text: (order['itemCount'] ?? 0).toString() +
                          ' item(ns) no pedido',
                    ),
                    const SizedBox(height: 12),
                    const _PrivacyOfferNotice(),
                  ] else ...[
                    _DetailSection(
                      icon: Icons.person_rounded,
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
                      icon: Icons.location_on_rounded,
                      title: 'Destino',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (address['street'] ?? '').toString() +
                                ', ' +
                                (address['number'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (address['neighborhood'] ?? '').toString() +
                                ' • ' +
                                (address['city'] ?? '').toString() +
                                ' - ' +
                                (address['state'] ?? '').toString(),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if ((address['complement'] ?? '')
                              .toString()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              address['complement'].toString(),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: Icons.shopping_bag_rounded,
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
                                      child: Text(
                                        (item['quantity'] ?? 0).toString() +
                                            'x',
                                        style: const TextStyle(
                                          color: AppColors.oceanDeep,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item['productName']?.toString() ??
                                            'Produto',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.35,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(item['total']),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
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
                      icon: Icons.timeline_rounded,
                      title: 'Progresso da entrega',
                      child: _DeliveryProgress(status: status),
                    ),
                    if (next == 'DELIVERED') ...[
                      const SizedBox(height: 10),
                      const _PinNotice(),
                    ],
                  ],
                ],
              ),
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
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await onReject?.call();
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('RECUSAR'),
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
                                Icons.check_circle_rounded,
                                size: 19,
                              ),
                              label: const Text('ACEITAR ENTREGA'),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fechar'),
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
                                label: Text(_nextLabel(next)),
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
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_rounded,
              color: AppColors.oceanDeep,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nome, telefone, rua, número e itens detalhados são liberados somente depois que você aceitar a entrega.',
                style: TextStyle(
                  color: AppColors.oceanDeep,
                  fontSize: 9.3,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEFDCAF)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.pin_rounded,
              color: Color(0xFF9A6818),
              size: 21,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Na porta, peça ao cliente o PIN de 4 dígitos. Sem o código correto o pedido não pode ser finalizado.',
                style: TextStyle(
                  color: Color(0xFF846A3C),
                  fontSize: 9.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
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
        incoming ? order['deliveryFee'] : order['total'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF112C27), Color(0xFF08675C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
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
                Text(
                  '#' + _shortId(id),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            customerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            incoming
                ? 'Veja somente os dados necessários para decidir.'
                : 'Pedido aceito e vinculado ao seu perfil.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                color: Color(0xFF93F2D9),
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                incoming ? 'Taxa da entrega' : 'Valor do pedido',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _money(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(23),
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
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.oceanDeep,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
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
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.oceanDeep, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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
      ('COURIER_ASSIGNED', 'Aceita', Icons.check_rounded),
      ('PICKED_UP', 'Coletada', Icons.inventory_2_rounded),
      ('OUT_FOR_DELIVERY', 'Em rota', Icons.route_rounded),
      ('DELIVERED', 'Entregue', Icons.home_rounded),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i <= currentIndex
                          ? AppColors.oceanDeep
                          : AppColors.stroke,
                    ),
                  ),
                  child: Icon(
                    i < currentIndex ? Icons.check_rounded : stages[i].$3,
                    color:
                        i <= currentIndex ? Colors.white : AppColors.muted,
                    size: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  stages[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i <= currentIndex
                        ? AppColors.ink
                        : AppColors.muted,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w800,
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
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          _statusLabel(status),
          style: TextStyle(
            color: dark ? Colors.white : _statusColor(status),
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
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
        childAspectRatio: 1.7,
        children: [
          _SnapshotCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Saldo disponível',
            value: _money(summary['availableBalance']),
          ),
          _SnapshotCard(
            icon: Icons.trending_up_rounded,
            label: 'Ganhos hoje',
            value: _money(summary['earningsToday']),
          ),
          _SnapshotCard(
            icon: Icons.check_circle_rounded,
            label: 'Entregas hoje',
            value: (summary['deliveriesToday'] ?? 0).toString(),
          ),
          _SnapshotCard(
            icon: Icons.calendar_view_week_rounded,
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.oceanDeep,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _DriverMenuSheet extends StatelessWidget {
  const _DriverMenuSheet({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('home', 'Início', Icons.home_rounded),
      ('deliveries', 'Entregas', Icons.delivery_dining_rounded),
      ('earnings', 'Ganhos', Icons.trending_up_rounded),
      ('wallet', 'Carteira', Icons.account_balance_wallet_rounded),
      ('withdrawals', 'Saques', Icons.payments_rounded),
      ('history', 'Histórico', Icons.history_rounded),
      ('profile', 'Perfil', Icons.person_rounded),
      ('vehicle', 'Veículo / Documentos', Icons.two_wheeler_rounded),
      ('settings', 'Configurações', Icons.settings_rounded),
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
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 17),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PORTO PRIME DRIVER',
                        style: TextStyle(
                          color: AppColors.ocean,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Central do motoboy',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.dashboard_customize_rounded,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item.$3,
                        color: AppColors.oceanDeep,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
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
  });

  final String section;
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
        'deliveries' => Icons.delivery_dining_rounded,
        'earnings' => Icons.trending_up_rounded,
        'wallet' => Icons.account_balance_wallet_rounded,
        'withdrawals' => Icons.payments_rounded,
        'history' => Icons.history_rounded,
        'profile' => Icons.person_rounded,
        'vehicle' => Icons.two_wheeler_rounded,
        'settings' => Icons.settings_rounded,
        _ => Icons.home_rounded,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            color: AppColors.oceanDeep,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 5, 18, 24),
                      children: _content(context, state),
                    ),
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
          .where((x) => x['type'] == 'DELIVERY_CREDIT')
          .toList();
      return [
        _FinanceHero(
          eyebrow: 'GANHOS DE HOJE',
          value: _money(summary['earningsToday']),
          subtitle: 'Semana: ' + _money(summary['earningsWeek']),
          icon: Icons.trending_up_rounded,
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
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: FilledButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.payments_rounded),
            label: const Text('Solicitar saque'),
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
          icon: Icons.payments_rounded,
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: FilledButton.icon(
            onPressed: onWithdraw,
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Nova solicitação'),
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _DriverEmpty(
            icon: Icons.account_balance_rounded,
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
        _DataPanel(
          title: 'Conta',
          icon: Icons.person_rounded,
          rows: [
            ('Nome', (user['name'] ?? '—').toString()),
            ('E-mail', (user['email'] ?? '—').toString()),
            ('Telefone', (user['phone'] ?? '—').toString()),
            ('Perfil', 'Motoboy'),
          ],
        ),
      ];
    }

    if (section == 'vehicle') {
      final p = state.courierProfile;
      return [
        _DataPanel(
          title: 'Documentos',
          icon: Icons.badge_rounded,
          rows: [
            ('CPF', (p['document'] ?? '—').toString()),
            ('CNH', (p['cnh'] ?? '—').toString()),
            ('Categoria', (p['cnhCategory'] ?? '—').toString()),
          ],
        ),
        const SizedBox(height: 10),
        _DataPanel(
          title: 'Veículo',
          icon: Icons.two_wheeler_rounded,
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
          icon: Icons.radar_rounded,
          custom: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: state.courierOnline,
            onChanged: state.courierDelivery == null
                ? state.setCourierOnline
                : null,
            title: const Text(
              'Receber novas ofertas',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              state.courierPresenceStatus.replaceAll('_', ' '),
              style: const TextStyle(
                fontSize: 9,
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
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair deste dispositivo'),
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
          icon: Icons.receipt_long_rounded,
          title: 'Sem movimentações',
          subtitle:
              'Créditos, débitos, saques e estornos aparecerão neste ledger.',
        ),
      ];
    }
    return rows.take(80).map((x) => _LedgerRow(entry: x)).toList();
  }

  List<Widget> _historyWidgets(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return const [
        _DriverEmpty(
          icon: Icons.history_rounded,
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF102923), Color(0xFF087568)],
          ),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: Color(0xFF91E8D5),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: positive
                ? AppColors.oceanDeep
                : const Color(0xFF966619),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry['description'] ?? 'Movimentação').toString(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _date(entry['createdAt']),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            (positive ? '+ ' : '- ') + _money(amount.abs()),
            style: TextStyle(
              color: positive
                  ? AppColors.oceanDeep
                  : const Color(0xFF966619),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.payments_rounded,
              color: AppColors.oceanDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money(row['amount']),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _date(row['requestedAt']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            _withdrawalStatus((row['status'] ?? '').toString()),
            style: const TextStyle(
              color: AppColors.oceanDeep,
              fontSize: 8,
              fontWeight: FontWeight.w900,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            Icon(
              order['status'] == 'DELIVERED'
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: order['status'] == 'DELIVERED'
                  ? AppColors.oceanDeep
                  : AppColors.coralStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrega #' + _shortId(order['id']),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _date(order['deliveredAt'] ?? order['updatedAt']),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _money(order['deliveryFee']),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
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
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.oceanDeep, size: 20),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
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
                        child: Text(
                          row.$1,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.$2,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
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
      'PROCESSING' => 'PROCESSANDO',
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
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Container(
              width: 63,
              height: 63,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(icon, color: AppColors.oceanDeep, size: 29),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
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
      'PICKED_UP' => Icons.inventory_2_rounded,
      'OUT_FOR_DELIVERY' => Icons.route_rounded,
      'DELIVERED' => Icons.pin_rounded,
      _ => Icons.arrow_forward_rounded,
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
      'OUT_FOR_DELIVERY' => const Color(0xFF356D8D),
      'PICKED_UP' => const Color(0xFF9A6818),
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
