import 'package:flutter/material.dart';
import '../../features/orders/presentation/pages/order_tracking_page.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

Map<String, dynamic>? customerLiveOrder(AppState state) {
  if (!state.isCustomer) return null;
  final candidates = [if (state.activeOrder != null) state.activeOrder!, ...state.orders.whereType<Map>().map((o) => Map<String, dynamic>.from(o))];
  for (final order in candidates) {
    if (order['adminDeletedAt'] == null && order['cancellation'] == null && !['CANCELED', 'DELIVERED'].contains(order['status']) && ['PAID', 'PARTIALLY_REFUNDED'].contains(order['paymentStatus'])) return order;
  }
  return null;
}
class ActiveOrderShortcut extends StatelessWidget {
  const ActiveOrderShortcut({super.key, required this.order});
  final Map<String, dynamic> order;
  @override
  Widget build(BuildContext context) {
    final status = order['status'];
    final label = switch (status) {
      'SEARCHING_COURIER' => 'Encontrando seu entregador',
      'COURIER_ASSIGNED' => 'Entregador a caminho da retirada',
      'PICKED_UP' || 'OUT_FOR_DELIVERY' => 'Seu pedido está a caminho',
      'PREPARING' => 'Estamos preparando seu pedido',
      _ => 'Seu pedido está confirmado',
    };
    final id = order['id'].toString();
    return Semantics(button: true, label: '$label. Abrir acompanhamento do pedido.', child: Material(
      color: AppColors.ocean900, elevation: 10, shadowColor: AppColors.midnight.withValues(alpha: .22), borderRadius: BorderRadius.circular(AppRadius.lg), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute(settings: RouteSettings(name: '/order-tracking/$id'), builder: (_) => OrderTrackingPage(orderId: id))), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Icon(status == 'SEARCHING_COURIER' ? AppIcons.search : AppIcons.bike, size: 24, color: Colors.white)),
        const SizedBox(width: 12), Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PEDIDO EM ANDAMENTO', style: TextStyle(color: Color(0xFF9FFFE7), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ])), const SizedBox(width: 10), const Icon(AppIcons.chevronRight, color: Colors.white, size: 20),
      ]))),
    ));
  }
}

