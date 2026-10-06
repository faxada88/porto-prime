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
  Timer? _timer;
  String? _lastPresentedOfferId;
  bool _offerModalOpen = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.refreshCourier();
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => AppState.instance.refreshCourier(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    final id = offer['id']?.toString();
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
      builder: (sheetContext) => _DeliveryDetailsSheet(
        order: order,
        incoming: incoming,
        onAccept: incoming
            ? () async {
                try {
                  await AppState.instance.acceptDelivery(
                    order['id'].toString(),
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
                      onLogout: state.logout,
                    ),
                    const SizedBox(height: 18),
                    _AvailabilityHero(
                      hasActiveDelivery: current != null,
                      online: state.courierOnline,
                      onChanged:
                          current == null ? state.setCourierOnline : null,
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
    required this.onLogout,
  });

  final String firstName;
  final bool online;
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
    final address = Map<String, dynamic>.from(order['address'] ?? {});
    final items = (order['items'] as List?) ?? const [];

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
            border: Border.all(color: AppColors.stroke),
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
                          'NOVA CHAMADA',
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
                    _money(order['total']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CompactInfo(
                icon: Icons.location_on_rounded,
                title:
                    '${address['street'] ?? ''}, ${address['number'] ?? ''}',
                subtitle:
                    '${address['neighborhood'] ?? ''} • ${address['city'] ?? ''}',
              ),
              const SizedBox(height: 8),
              _CompactInfo(
                icon: Icons.shopping_bag_rounded,
                title: '${items.length} ${items.length == 1 ? 'item' : 'itens'}',
                subtitle: 'Toque para ver o pedido completo',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ver chamada completa',
                      style: TextStyle(
                        color: AppColors.oceanDeep,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.oceanDeep,
                      size: 19,
                    ),
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
    this.onAdvance,
  });

  final Map<String, dynamic> order;
  final bool incoming;
  final Future<void> Function()? onAccept;
  final Future<void> Function(String status)? onAdvance;

  @override
  Widget build(BuildContext context) {
    final address = Map<String, dynamic>.from(order['address'] ?? {});
    final customer = Map<String, dynamic>.from(order['customer'] ?? {});
    final items = (order['items'] as List?) ?? const [];
    final status = order['status']?.toString() ?? 'READY_FOR_PICKUP';
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
                                  ? 'Confira antes de aceitar'
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
                  _SheetHero(
                    order: order,
                    incoming: incoming,
                  ),
                  const SizedBox(height: 12),
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
                          '${address['street'] ?? ''}, ${address['number'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${address['neighborhood'] ?? ''} • ${address['city'] ?? ''} - ${address['state'] ?? ''}',
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
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: const BoxConstraints(minWidth: 34),
                                  height: 34,
                                  alignment: Alignment.center,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Text(
                                    '${item['quantity'] ?? 0}x',
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
                                const SizedBox(width: 8),
                                Text(
                                  _money(item['total']),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: AppColors.stroke),
                        _DetailRow(
                          label: 'Valor do pedido',
                          value: _money(order['total']),
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  if (!incoming) ...[
                    const SizedBox(height: 10),
                    _DetailSection(
                      icon: Icons.timeline_rounded,
                      title: 'Progresso da entrega',
                      child: _DeliveryProgress(status: status),
                    ),
                    if (next == 'DELIVERED') ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: const Color(0xFFEFDCAF)),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entrega protegida por PIN',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Na porta, peça ao cliente o código de 4 dígitos. Sem o PIN correto o pedido não pode ser finalizado.',
                                    style: TextStyle(
                                      color: Color(0xFF846A3C),
                                      fontSize: 9.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    ? SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await onAccept?.call();
                          },
                          icon:
                              const Icon(Icons.check_circle_rounded, size: 19),
                          label: const Text('Aceitar esta entrega'),
                        ),
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

class _SheetHero extends StatelessWidget {
  const _SheetHero({
    required this.order,
    required this.incoming,
  });

  final Map<String, dynamic> order;
  final bool incoming;

  @override
  Widget build(BuildContext context) => Container(
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
                Text(
                  '#${_shortId(order['id'])}',
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
              order['customer']?['name']?.toString() ?? 'Cliente Porto Prime',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pedido pago e liberado pela operação.',
              style: TextStyle(
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
                const Text(
                  'Valor do pedido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _money(order['total']),
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
  return 'R\\$ ${number.toStringAsFixed(2).replaceAll('.', ',')}';
}
