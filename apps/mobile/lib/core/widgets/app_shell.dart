import 'dart:async';
import '../../features/support/presentation/pages/delivery_chat_page.dart';
import 'package:flutter/material.dart';
import 'customer_demand_notice.dart';
import 'active_order_shortcut.dart';

import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/courier/presentation/pages/courier_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const pages = [
    HomePage(),
    CategoriesPage(),
    CartPage(),
    ProfilePage(),
  ];

  Timer? _orderSync;
  bool _syncingOrder = false;
  int _chatEpoch=0;
  bool _openingChat=false;
  @override
  void initState() {
    super.initState();
    _orderSync = Timer.periodic(const Duration(seconds: 12), (_) async {
      final state = AppState.instance;
      if (_syncingOrder || !state.isCustomer || AppNav.instance.observer.top?.isFirst == false) return;
      _syncingOrder = true;
      try { await Future.wait([state.loadActiveOrder(), state.loadOrders()]); } catch (_) {} finally { _syncingOrder = false; }
    });
    AppNav.instance.index.addListener(_changed);
    AppState.instance.addListener(_incomingChat);
    WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)_incomingChat();});
  }

  @override
  void dispose() {
    AppNav.instance.index.removeListener(_changed);
    AppState.instance.removeListener(_incomingChat);
    _orderSync?.cancel();
    super.dispose();
  }

  void _changed() => setState(() {});
  void _incomingChat() {
    final app=AppState.instance;
    if(!mounted||_openingChat||_chatEpoch==app.deliveryChatEpoch)return;
    _chatEpoch=app.deliveryChatEpoch;
    final notice=app.incomingDeliveryChat;
    if(!app.loggedIn||notice==null||notice['recipientId']!=(app.user?['id'])||!(app.isCustomer||app.isCourier))return;
    final id=notice['orderId'].toString();
    final name='/delivery-chat/$id';
    if(AppNav.instance.observer.currentName==name)return;
    _openingChat=true;
    final recipient=app.user?['id'];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Recheck current assignment before bringing the private conversation to the front.
        final result=await app.api.request('GET','/support/orders/${Uri.encodeComponent(id)}/delivery');
        if(!mounted||(app.user?['id'])!=recipient||result['canSend']!=true||AppNav.instance.observer.currentName==name)return;
        final navigator=AppNav.instance.rootNavigatorKey.currentState;
        if(navigator!=null)unawaited(navigator.push<void>(MaterialPageRoute<void>(settings:RouteSettings(name:name),builder:(_)=>DeliveryChatPage(orderId:id))).then((_){}));
      }catch(_){/* History remains available from the delivery page if offline. */}
      finally{_openingChat=false;if(mounted)_incomingChat();}
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppState.instance,
    builder: (_, __) {
      final state = AppState.instance;
      if (state.isCourier) return const CourierPage();

      final index = AppNav.instance.index.value;
      final liveOrder = index == 2 ? null : customerLiveOrder(state);

      return Scaffold(
        // The cart has a fixed checkout action; reserve the navigation height.
        extendBody: index != 2 && liveOrder == null,
        body: Column(children:[if(state.publicHighDemand) const CustomerDemandNotice(),Expanded(child:Stack(children:[
          Positioned.fill(child:Padding(padding:EdgeInsets.only(bottom:liveOrder == null ? 0 : 98),child:IndexedStack(index:index,children:pages))),
          if(liveOrder != null) Positioned(left:14,right:14,bottom:12,child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:ActiveOrderShortcut(order:liveOrder)))),
        ]))]),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: AppControl.navHeight,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.floating,
            ),
            child: Row(
              children: [
                _item(
                  value: 0,
                  icon: AppIcons.home,
                  label: 'Início',
                  current: index,
                ),
                _item(
                  value: 1,
                  icon: AppIcons.search,
                  label: 'Buscar',
                  current: index,
                ),
                _item(
                  value: 2,
                  icon: AppIcons.bag,
                  label: 'Carrinho',
                  current: index,
                  badgeCount: state.cartCount,
                ),
                _item(
                  value: 3,
                  icon: AppIcons.user,
                  label: 'Perfil',
                  current: index,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _item({
    required int value,
    required IconData icon,
    required String label,
    required int current,
    int badgeCount = 0,
  }) {
    final selected = current == value;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => AppNav.instance.go(value),
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.standard),
            curve: AppMotion.curve,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.ocean50 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.ocean100 : Colors.transparent,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.resolve(context, AppMotion.standard),
                      curve: AppMotion.curve,
                      width: 42,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.ocean100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: AppIconSize.md,
                        color: selected ? AppColors.ocean700 : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? AppColors.ocean700 : AppColors.muted,
                        fontSize: AppFontSize.caption,
                        letterSpacing: .05,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 3,
                    right: 8,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.coral600,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

