import 'dart:async';
import 'package:flutter/material.dart';

/// Scrolls naturally without asking a LayoutBuilder for intrinsic dimensions.
/// The clock is presentation-only and never changes courier availability.
class CourierWorkflowLayout extends StatefulWidget {
  const CourierWorkflowLayout({super.key, required this.header, required this.online,
    required this.accountId, required this.onRefresh, required this.waitingBuilder,
    this.controller, this.delivery, this.notice});
  final Widget header;
  final Widget? delivery, notice;
  final bool online;
  final Object? accountId;
  final ScrollController? controller;
  final Future<void> Function() onRefresh;
  final Widget Function(double availableHeight, Duration onlineTime) waitingBuilder;
  @override State<CourierWorkflowLayout> createState() => _CourierWorkflowLayoutState();
}

class _CourierWorkflowLayoutState extends State<CourierWorkflowLayout> with WidgetsBindingObserver {
  final _clock = Stopwatch();
  Timer? _clockTick;
  bool _foreground = true;
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _syncClock();
  }
  void _syncClock() {
    if (widget.online && _foreground) {
      _clock.start();
      _clockTick ??= Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _clock.stop(); _clockTick?.cancel(); _clockTick = null;
    }
  }
  @override void didUpdateWidget(covariant CourierWorkflowLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) _clock.reset();
    _syncClock();
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncClock();
    if (mounted) setState(() {});
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTick?.cancel(); _clock.stop(); super.dispose();
  }
  @override Widget build(BuildContext context) => SafeArea(bottom: false, child: RefreshIndicator(
    onRefresh: widget.onRefresh, edgeOffset: 62,
    child: CustomScrollView(controller: widget.controller,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: widget.header),
        if (widget.notice != null) SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          sliver: SliverToBoxAdapter(child: widget.notice)),
        if (widget.delivery == null)
          SliverLayoutBuilder(builder: (context, constraints) {
            final remaining = (constraints.viewportMainAxisExtent - constraints.precedingScrollExtent)
              .clamp(0.0, double.infinity).toDouble();
            return SliverToBoxAdapter(child: widget.waitingBuilder(remaining, _clock.elapsed));
          })
        else SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          sliver: SliverToBoxAdapter(child: widget.delivery)),
      ])));
}
