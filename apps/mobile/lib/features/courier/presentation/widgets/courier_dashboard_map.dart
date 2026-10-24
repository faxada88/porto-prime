import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/prime_localization.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/tracking/courier_route_tracker.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/courier_portrait.dart';
import '../../../../core/widgets/prime_ui.dart';

const courierGreen = Color(0xFF008654);
const courierInk = Color(0xFF102A33);
const courierTileUrl = String.fromEnvironment('MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

LatLng? courierMapPoint(dynamic value) {
  if (value is! Map) return null;
  final lat = double.tryParse((value['latitude'] ?? '').toString());
  final lng = double.tryParse((value['longitude'] ?? '').toString());
  if (lat == null || lng == null || !lat.isFinite || !lng.isFinite ||
      lat.abs() > 90 || lng.abs() > 180) return null;
  return LatLng(lat, lng);
}

/// The dashboard reads existing tracking snapshots. It never starts route sharing.
class CourierDashboardMap extends StatefulWidget {
  const CourierDashboardMap({super.key, required this.online, required this.active,
    required this.photo, required this.unreadCount, required this.onNotifications,
    required this.onProfile, required this.onRoute, required this.onChanged, this.order});
  final bool online, active;
  final String? photo;
  final int unreadCount;
  final Map<String, dynamic>? order;
  final VoidCallback onNotifications, onProfile, onRoute;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierDashboardMap> createState() => _CourierDashboardMapState();
}

class _CourierDashboardMapState extends State<CourierDashboardMap> with WidgetsBindingObserver {
  final _map = MapController();
  Timer? _trackingTimer;
  LatLng? _position, _origin, _target;
  List<LatLng> _route = [];
  bool _ready = false, _dark = true, _locating = false, _changing = false, _fetching = false;
  bool _following = true, _foreground = true;
  String? _snapshotOrderId;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _target = courierMapPoint(widget.order?['address']);
    _refreshTracking();
    _trackingTimer = Timer.periodic(const Duration(seconds: 12), (_) => _refreshTracking());
  }
  @override void didUpdateWidget(covariant CourierDashboardMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order?['id'] != widget.order?['id'] ||
        oldWidget.order?['status'] != widget.order?['status']) {
      _snapshotOrderId = null;
      _route = [];
      _origin = null;
      _target = courierMapPoint(widget.order?['address']);
      _refreshTracking();
    }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refreshTracking();
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingTimer?.cancel();
    _map.dispose();
    super.dispose();
  }
  Future<void> _refreshTracking() async {
    if (_fetching || !_foreground || liveRouteMode(widget.order) == null) return;
    final id = widget.order?['id']?.toString();
    if (id == null) return;
    final session = ApiClient.instance.sessionId;
    _fetching = true;
    try {
      final result = await ApiClient.instance.request('GET', '/orders/' + id + '/tracking',
        timeout: const Duration(seconds: 8));
      if (!mounted || widget.order?['id']?.toString() != id ||
          ApiClient.instance.sessionId != session || result is! Map || result['active'] != true) return;
      final line = <LatLng>[];
      final raw = result['route'];
      if (raw is Map && raw['coordinates'] is List) {
        for (final pair in raw['coordinates']) {
          if (pair is List && pair.length >= 2) {
            final point = courierMapPoint({'latitude': pair[1], 'longitude': pair[0]});
            if (point != null) line.add(point);
          }
        }
      }
      final position = courierMapPoint(result['point']);
      setState(() {
        _snapshotOrderId = id;
        if (position != null) _position = position;
        _origin = courierMapPoint(result['origin']);
        _target = courierMapPoint(result['target']) ?? _target;
        _route = line;
      });
      if (_ready && _following && position != null) _map.move(position, _map.camera.zoom);
    } catch (_) {
      // Offers, availability and delivery actions remain usable without map tiles or routing.
    } finally {
      _fetching = false;
    }
  }
  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: PrimeText(text)));
  }
  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _message('Ative o GPS para localizar sua posição.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _message('Permita a localização para centralizar o mapa.');
        return;
      }
      // One foreground read, only after tapping the location button; no heartbeat upload.
      final position = await Geolocator.getCurrentPosition(locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)));
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() { _position = point; _following = true; });
      if (_ready) _map.move(point, 14);
    } catch (_) {
      _message('Localização indisponível. Tente novamente.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }
  Future<void> _toggle() async {
    if (_changing || widget.onChanged == null) return;
    setState(() => _changing = true);
    try { await widget.onChanged!(!widget.online); }
    catch (error) { _message(PrimeMessages.friendly(error)); }
    finally { if (mounted) setState(() => _changing = false); }
  }
  Widget _control(IconData icon, String label, VoidCallback? onTap, {bool busy = false}) =>
    Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Material(color: const Color(0xE608202B), shape: const CircleBorder(),
        child: IconButton(onPressed: onTap, tooltip: translateLabel(label),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: busy ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, color: Colors.white, size: 22))));

  @override Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final narrow = MediaQuery.sizeOf(context).width < 350;
    final height = (expandedText ? 480.0 : narrow ? 400.0 : 320.0) + inset;
    final center = _position ?? _target ?? const LatLng(-16.4386, -39.0808);
    Widget tiles = TileLayer(urlTemplate: courierTileUrl,
      userAgentPackageName: 'com.portoprime.porto_prime');
    if (_dark) {
      tiles = ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFF16465D), BlendMode.color),
        child: ColorFiltered(colorFilter: const ColorFilter.matrix([
          -1,0,0,0,255, 0,-1,0,0,255, 0,0,-1,0,255, 0,0,0,1,0,
        ]), child: tiles));
    }
    final status = widget.active ? 'Entrega em andamento'
      : widget.online ? 'Você está online' : 'Você está offline';
    return SizedBox(height: height, child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF0B2B3C)),
      FlutterMap(mapController: _map,
        options: MapOptions(initialCenter: center, initialZoom: 12.6,
          onMapReady: () => _ready = true,
          onPositionChanged: (_, gesture) { if (gesture) _following = false; }),
        children: [
          tiles,
          if (_route.length > 1 && _snapshotOrderId == widget.order?['id']?.toString())
            PolylineLayer(polylines: [Polyline(points: _route,
              color: const Color(0xFF24B5FF), strokeWidth: 5)]),
          MarkerLayer(markers: [
            if (_origin != null) Marker(point: _origin!, width: 32, height: 32,
              child: const _MapPin(icon: AppIcons.store, color: courierGreen)),
            if (_target != null) Marker(point: _target!, width: 32, height: 32,
              child: const _MapPin(icon: AppIcons.mapPin, color: Color(0xFFEC5260))),
            if (_position != null) Marker(point: _position!, width: 68, height: 68,
              child: Container(decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF159FFF).withValues(alpha: .22)),
                alignment: Alignment.center, child: Container(width: 20, height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: const Color(0xFF159FFF), border: Border.all(color: Colors.white, width: 3))))),
          ]),
        ]),
      const Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0, .28, .65, 1], colors: [Color(0xD908202B), Color(0x2208202B),
            Colors.transparent, Color(0xCC08202B)]))))),
      Positioned(top: inset + 12, left: 20, right: 16, child: Row(children: [
        const Expanded(child: _CourierWordmark()),
        const SizedBox(width: 8),
        Badge(isLabelVisible: widget.unreadCount > 0,
          label: Text(widget.unreadCount > 9 ? '9+' : widget.unreadCount.toString()),
          child: _control(AppIcons.bell, 'Atualizações', widget.onNotifications)),
        const SizedBox(width: 10),
        Semantics(button: true, label: translateLabel('Meu perfil'),
          child: InkWell(onTap: widget.onProfile, borderRadius: BorderRadius.circular(30),
            child: Stack(children: [
              CourierPortrait(photo: widget.photo, size: 44),
              Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: widget.online ? const Color(0xFF00D77D) : const Color(0xFF81959E),
                  border: Border.all(color: const Color(0xFF0A2530), width: 2)))),
            ]))),
      ])),
      if (!expandedText) Positioned(top: inset + 84, left: 20, child: Material(
        color: const Color(0xED071D25), borderRadius: BorderRadius.circular(18),
        child: InkWell(onTap: widget.active ? widget.onRoute : _toggle,
          borderRadius: BorderRadius.circular(18),
          child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 32, height: 36, decoration: BoxDecoration(
              color: widget.online ? const Color(0xFF005A43) : const Color(0xFF2A424A),
              borderRadius: BorderRadius.circular(11)),
              child: Icon(AppIcons.radar, size: 21,
                color: widget.online ? const Color(0xFF00DD88) : Colors.white70)),
            const SizedBox(width: 9),
            SizedBox(width: expandedText ? 160 : 104,
              child: PrimeText(status, maxLines: 3, style: const TextStyle(color: Colors.white,
                fontSize: 13, height: 1.3, fontWeight: FontWeight.w700))),
            const SizedBox(width: 4), const Icon(AppIcons.chevronRight, size: 18, color: Colors.white),
          ]))))),
      Positioned(top: inset + 74, right: 14, child: Column(children: [
        _control(Icons.my_location_rounded, 'Localizar minha posição',
          _locating ? null : _locate, busy: _locating),
        _control(AppIcons.layers, _dark ? 'Mapa claro' : 'Mapa escuro',
          () => setState(() => _dark = !_dark)),
        _control(AppIcons.navigation, 'Ver rota atual', widget.onRoute),
      ])),
      Positioned(left: 20, right: 20, bottom: 25,
        child: _AvailabilityBar(online: widget.online, active: widget.active,
          changing: _changing, onTap: widget.active ? widget.onRoute : _toggle)),
      Positioned(left: 8, bottom: 3, child: InkWell(
        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
        child: const Padding(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text('© OpenStreetMap', style: TextStyle(color: Colors.white70, fontSize: 9))))),
    ]));
  }
}

class _AvailabilityBar extends StatelessWidget {
  const _AvailabilityBar({required this.online, required this.active,
    required this.changing, required this.onTap});
  final bool online, active, changing;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(
    color: const Color(0xF0071D25), borderRadius: BorderRadius.circular(24),
    child: Padding(padding: const EdgeInsets.all(6), child: LayoutBuilder(builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      final status = Padding(padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(children: [
          Icon(active ? AppIcons.route : AppIcons.power, size: 28, color: Colors.white),
          const SizedBox(width: 12), Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              PrimeText(active ? 'Entrega em andamento' : online ? 'Você está online' : 'Você está offline',
                style: const TextStyle(fontSize: 14, height: 1.25,
                  color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              PrimeText(active ? 'Ver detalhes da rota' : online ? 'Recebendo entregas' : 'Conecte-se para receber',
                style: const TextStyle(fontSize: 11, height: 1.3, color: Color(0xFFB8F2D8))),
            ])),
        ]));
      final action = TextButton(onPressed: changing ? null : onTap,
        style: TextButton.styleFrom(foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF263B40), minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Color(0xFF50646B)))),
        child: changing ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : PrimeText(active ? 'Ver rota' : online ? 'Ficar offline' : 'Ficar online',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)));
      final statusPanel = DecoratedBox(decoration: BoxDecoration(
        gradient: LinearGradient(colors: online
          ? const [Color(0xFF00854F), Color(0xFF007F50)]
          : const [Color(0xFF38545C), Color(0xFF203D46)]),
        borderRadius: BorderRadius.circular(20)), child: status);
      return large || box.maxWidth < 310
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            statusPanel, const SizedBox(height: 6), action])
        : Row(children: [Expanded(child: statusPanel), const SizedBox(width: 10), action]);
    })));
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3)),
    child: Icon(icon, color: Colors.white, size: 16));
}

class _CourierWordmark extends StatelessWidget {
  const _CourierWordmark();
  @override Widget build(BuildContext context) => Row(children: [
    const SizedBox(width: 30, height: 32, child: CustomPaint(painter: _CrownPainter())),
    const SizedBox(width: 8),
    const Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'PORTO ', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'PRIME', style: TextStyle(color: Color(0xFFF6B33A))),
        ]), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: .2)),
        SizedBox(height: 2),
        Text('D E L I V E R Y', style: TextStyle(color: Colors.white60, fontSize: 7, letterSpacing: 1.8)),
      ]))),
  ]);
}
class _CrownPainter extends CustomPainter {
  const _CrownPainter();
  @override void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 30, size.height / 32);
    final crown = Path()..moveTo(2, 10)..lineTo(8, 15)..lineTo(15, 2)
      ..lineTo(22, 15)..lineTo(28, 10)..lineTo(25, 24)..lineTo(5, 24)..close();
    canvas.drawPath(crown, Paint()..shader = const LinearGradient(
      colors: [Color(0xFFFFDB77), Color(0xFFF0A71D)]).createShader(const Rect.fromLTWH(0, 0, 30, 28)));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 26, 20, 3),
      const Radius.circular(1.5)), Paint()..color = const Color(0xFFEFA92C));
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _CrownPainter oldDelegate) => false;
}
