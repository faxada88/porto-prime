import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/navigation/app_nav.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prime_ui.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([
        AppState.instance.loadOrders(),
        AppState.instance.loadActiveOrder(),
      ]);
    } catch (_) {}
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? get order {
    for (final value in AppState.instance.orders) {
      final current = Map<String, dynamic>.from(value);
      if (current['id'].toString() == widget.orderId) return current;
    }
    final active = AppState.instance.activeOrder;
    return active?['id'].toString() == widget.orderId ? active : null;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final current = order;
      if (current == null) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(leading: Navigator.of(context).canPop() ? const PrimeBackButton() : null),
          body: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                PrimeSkeleton(height: 190, radius: AppRadius.xl),
                SizedBox(height: 16),
                PrimeSkeleton(height: 380, radius: AppRadius.lg),
              ],
            ),
          ),
        );
      }

      final status = current['status'].toString();
      final step = _step(status);
      final courier = current['courier'];
      final items = (current['items'] as List?) ?? const [];
      final address = current['address'];

      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          leading: Navigator.of(context).canPop() ? const PrimeBackButton() : null,
          title: const Text('Acompanhar pedido'),
          actions: [
            IconButton(
              tooltip: 'Início',
              onPressed: AppNav.instance.home,
              icon: const Icon(AppIcons.home),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
              children: [
                _Hero(order: current, status: status, id: widget.orderId),
                const SizedBox(height: 16),
                _Journey(status: status, step: step),
                if (courier != null) ...[
                  const SizedBox(height: 16),
                  _Courier(courier: courier),
                ],
                if (courier != null &&
                    status != 'DELIVERED' &&
                    status != 'CANCELED' &&
                    (current['deliveryPin'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DeliveryPin(pin: current['deliveryPin'].toString()),
                ],
                if (status == 'DELIVERED') ...[
                  const SizedBox(height: 16),
                  const _PinConfirmed(),
                ],
                const SizedBox(height: 16),
                _Section(
                  title: 'Seu pedido',
                  icon: AppIcons.bag,
                  child: Column(
                    children: [
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.ocean50,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  item['quantity'].toString() + 'x',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: AppColors.ocean800,
                                        fontWeight: AppFontWeight.display,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  (item['productName'] ?? 'Produto').toString(),
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Text(
                                _money(item['total']),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: AppFontWeight.display,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _value('Subtotal', current['subtotal']),
                      _value('Entrega', current['deliveryFee']),
                      const SizedBox(height: 7),
                      _value('Total', current['total'], strong: true),
                    ],
                  ),
                ),
                if (address != null) ...[
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Entrega',
                    icon: AppIcons.mapPin,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (address['street'] ?? '').toString() +
                              ', ' +
                              (address['number'] ?? '').toString(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          (address['neighborhood'] ?? '').toString() +
                              ' • ' +
                              (address['city'] ?? '').toString() +
                              ' - ' +
                              (address['state'] ?? '').toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if ((address['complement'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              address['complement'].toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _Section(
                  title: 'Pagamento e identificação',
                  icon: AppIcons.shield,
                  child: Column(
                    children: [
                      _info(
                        'Pedido',
                        '#' +
                            widget.orderId
                                .substring(
                                  0,
                                  widget.orderId.length < 8
                                      ? widget.orderId.length
                                      : 8,
                                )
                                .toUpperCase(),
                      ),
                      _info(
                        'Pagamento',
                        current['paymentStatus'] == 'PAID'
                            ? 'Aprovado'
                            : current['paymentStatus'].toString(),
                      ),
                      _info(
                        'Forma',
                        current['paymentMethod'] == 'CARD'
                            ? 'Cartão • Stripe'
                            : (current['paymentMethod'] ?? '—').toString(),
                      ),
                      _info('Criado em', _date(current['createdAt'])),
                      if (current['deliveredAt'] != null)
                        _info('Entregue em', _date(current['deliveredAt'])),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: AppNav.instance.home,
                  icon: const Icon(AppIcons.home, size: 18),
                  label: const Text('Voltar para o início'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.order, required this.status, required this.id});

  final dynamic order;
  final String status;
  final String id;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.ocean900, AppColors.ocean700],
      ),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      boxShadow: AppShadows.elevated,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PrimeStatusPill(
              label: status == 'DELIVERED'
                  ? 'PEDIDO CONCLUÍDO'
                  : 'ACOMPANHAMENTO AO VIVO',
              tone: PrimeStatusTone.success,
            ),
            const Spacer(),
            Text(
              '#' +
                  id.substring(0, id.length < 8 ? id.length : 8).toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          _title(status),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: 27,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle(status),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFFD4ECE7)),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Icon(AppIcons.creditCard, color: Color(0xFF9FFFE7), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order['paymentStatus'] == 'PAID'
                    ? 'Pagamento aprovado'
                    : 'Pagamento ' + order['paymentStatus'].toString(),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
            Text(
              _money(order['total']),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: AppFontWeight.display,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Journey extends StatelessWidget {
  const _Journey({required this.status, required this.step});

  final String status;
  final int step;

  @override
  Widget build(BuildContext context) {
    const stages = [
      (
        'Pagamento aprovado',
        'Cobrança confirmada pelo Stripe.',
        AppIcons.creditCard,
      ),
      (
        'Pedido recebido',
        'A Porto Prime recebeu seu pedido.',
        AppIcons.receipt,
      ),
      (
        'Pedido confirmado',
        'A distribuidora confere disponibilidade e libera os itens.',
        AppIcons.store,
      ),
      ('Preparando', 'Seus produtos estão sendo separados.', AppIcons.package),
      (
        'Procurando entregador',
        'Buscando automaticamente um motoboy online e disponível.',
        AppIcons.search,
      ),
      (
        'Motoboy a caminho da retirada',
        'Entregador encontrado e conectado ao pedido.',
        AppIcons.bike,
      ),
      ('Saiu para entrega', 'Seu pedido está a caminho.', AppIcons.route),
      ('Entregue', 'Pedido concluído.', AppIcons.home),
    ];

    return _Section(
      title: 'Jornada do pedido',
      icon: AppIcons.route,
      child: Column(
        children: [
          for (var i = 0; i < stages.length; i++)
            _Stage(
              icon: stages[i].$3,
              title: stages[i].$1,
              subtitle: stages[i].$2,
              done: i <= step,
              current: i == step,
              last: i == stages.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              _TimelineDot(
                icon: done && !current ? AppIcons.check : icon,
                active: done,
                current: current,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: done ? AppColors.ocean700 : AppColors.stroke,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: last ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: done ? AppColors.ink : AppColors.muted,
                    fontWeight: AppFontWeight.display,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TimelineDot extends StatefulWidget {
  const _TimelineDot({
    required this.icon,
    required this.active,
    required this.current,
  });

  final IconData icon;
  final bool active;
  final bool current;

  @override
  State<_TimelineDot> createState() => _TimelineDotState();
}

class _TimelineDotState extends State<_TimelineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.current) controller.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.of(context)) {
      controller.stop();
    } else if (widget.current && !controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _TimelineDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current &&
        !MediaQuery.disableAnimationsOf(context) &&
        !controller.isAnimating) {
      controller.repeat(reverse: true);
    } else if (!widget.current && controller.isAnimating) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: widget.active ? AppColors.ocean800 : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: widget.active ? AppColors.ocean800 : AppColors.stroke,
        ),
        boxShadow: widget.current
            ? [
                BoxShadow(
                  color: AppColors.ocean600.withValues(
                    alpha: .12 + controller.value * .12,
                  ),
                  blurRadius: 8 + controller.value * 10,
                  spreadRadius: controller.value * 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        widget.icon,
        color: widget.active ? Colors.white : AppColors.subtle,
        size: 18,
      ),
    ),
  );
}

class _DeliveryPin extends StatelessWidget {
  const _DeliveryPin({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    final digits = pin.split('').join('  ');

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sand100, AppColors.sand50],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.sun200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  AppIcons.lock,
                  color: AppColors.warning,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN DE ENTREGA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Seu código de confirmação',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              digits,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 29,
                letterSpacing: 5,
                fontWeight: AppFontWeight.display,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(AppIcons.shield, color: AppColors.warning, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Informe este PIN ao motoboy somente quando estiver com o pedido em mãos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF7D6841),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinConfirmed extends StatelessWidget {
  const _PinConfirmed();

  @override
  Widget build(BuildContext context) => PrimeSurface(
    background: AppColors.ocean50,
    borderColor: AppColors.ocean100,
    child: Row(
      children: [
        const Icon(AppIcons.shield, color: AppColors.ocean800, size: 23),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrega confirmada com segurança',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 3),
              Text(
                'O PIN foi validado pelo motoboy no momento da entrega.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Courier extends StatelessWidget {
  const _Courier({required this.courier});

  final dynamic courier;

  @override
  Widget build(BuildContext context) => PrimeSurface(
    background: AppColors.ocean50,
    borderColor: AppColors.ocean100,
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(AppIcons.bike, color: AppColors.ocean800, size: 25),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEU MOTOBOY',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 3),
              Text(
                (courier['user']?['name'] ?? 'Motoboy Porto Prime').toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (courier['user']?['phone'] != null)
                Text(
                  courier['user']['phone'].toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const PrimeStatusPill(label: 'EM ROTA', tone: PrimeStatusTone.success),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => PrimeSurface(
    padding: const EdgeInsets.all(19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.ocean50,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: AppColors.ocean800),
            ),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 17),
        child,
      ],
    ),
  );
}

Widget _value(String label, dynamic value, {bool strong = false}) => Padding(
  padding: const EdgeInsets.only(top: 7),
  child: Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: strong ? 13 : 10,
            color: strong ? AppColors.ink : AppColors.muted,
            fontWeight: strong ? AppFontWeight.display : AppFontWeight.medium,
          ),
        ),
      ),
      Text(
        _money(value),
        style: TextStyle(
          fontSize: strong ? 16 : 11,
          fontWeight: AppFontWeight.display,
        ),
      ),
    ],
  ),
);

Widget _info(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: AppFontWeight.medium,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: AppFontWeight.display,
          ),
        ),
      ),
    ],
  ),
);

String _money(dynamic value) {
  final number = double.tryParse(value.toString()) ?? 0;
  return 'R\$ ' + number.toStringAsFixed(2).replaceAll('.', ',');
}

String _date(dynamic value) {
  if (value == null) return '—';
  final date = DateTime.tryParse(value.toString())?.toLocal();
  if (date == null) return value.toString();
  String two(int number) => number.toString().padLeft(2, '0');
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

int _step(String status) => switch (status) {
  'PENDING' => 1,
  'CONFIRMED' => 2,
  'PREPARING' => 3,
  'READY_FOR_PICKUP' => 4,
  'SEARCHING_COURIER' => 4,
  'COURIER_ASSIGNED' => 5,
  'PICKED_UP' => 5,
  'OUT_FOR_DELIVERY' => 6,
  'DELIVERED' => 7,
  'CANCELED' => 1,
  _ => 1,
};

String _title(String status) => switch (status) {
  'PENDING' => 'Pedido recebido.',
  'CONFIRMED' => 'Pedido confirmado.',
  'PREPARING' => 'Estamos preparando.',
  'READY_FOR_PICKUP' => 'Pronto para coleta.',
  'SEARCHING_COURIER' => 'Procurando entregador.',
  'COURIER_ASSIGNED' => 'Motoboy encontrado.',
  'PICKED_UP' => 'Pedido coletado.',
  'OUT_FOR_DELIVERY' => 'Está chegando!',
  'DELIVERED' => 'Pedido entregue.',
  'CANCELED' => 'Pedido cancelado.',
  _ => 'Pedido recebido.',
};

String _subtitle(String status) => switch (status) {
  'PENDING' => 'Recebemos o pedido e aguardamos a confirmação do pagamento.',
  'CONFIRMED' =>
    'Pagamento aprovado. A distribuidora está conferindo e liberando os itens.',
  'PREPARING' => 'Seus produtos estão sendo separados com cuidado.',
  'READY_FOR_PICKUP' => 'Tudo pronto para iniciar o despacho.',
  'SEARCHING_COURIER' =>
    'O sistema está oferecendo a entrega automaticamente aos motoboys online e disponíveis.',
  'COURIER_ASSIGNED' => 'Um motoboy aceitou e seguirá para a retirada.',
  'PICKED_UP' => 'Seu pedido já está com o motoboy.',
  'OUT_FOR_DELIVERY' => 'O motoboy está levando seu pedido até você.',
  'DELIVERED' => 'Tudo certo. O histórico completo continua disponível aqui.',
  'CANCELED' => 'Este pedido não seguirá para entrega.',
  _ => 'Acompanhe as próximas etapas por aqui.',
};
