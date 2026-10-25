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
import '../../../../core/widgets/prime_ui.dart';

const courierGreen = Color(0xFF008654);
const courierInk = Color(0xFF102A33);
const courierTileUrl = String.fromEnvironment('MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

double courierDashboardMapHeight(BuildContext context) {
  if (MediaQuery.textScalerOf(context).scale(14) > 19) return 270;
  return MediaQuery.sizeOf(context).width < 350 ? 250 : 230;
}

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
    required this.unreadCount, required this.onNotifications, required this.onLogout,
    required this.onRoute, required this.onChanged, this.order});
  final bool online, active;
  final int unreadCount;
  final Map<String, dynamic>? order;
  final VoidCallback onNotifications, onRoute;
  final VoidCallback? onLogout;
  final Future<void> Function(bool)? onChanged;
  @override State<CourierDashboardMap> createState() => _CourierDashboardMapState();
}

class _CourierDashboardMapState extends State<CourierDashboardMap> with WidgetsBindingObserver {
  final _map = MapController();
  Timer? _trackingTimer;
  LatLng? _position, _origin, _target;
  List<LatLng> _route = [];
  bool _ready = false, _locating = false, _changing = false, _fetching = false;
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
    Material(color: const Color(0xDF102B36), shape: const CircleBorder(),
      child: IconButton(onPressed: onTap, tooltip: translateLabel(label),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: busy ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(icon, color: Colors.white, size: 21)));

  @override Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    final expandedText = MediaQuery.textScalerOf(context).scale(14) > 19;
    final height = courierDashboardMapHeight(context) + inset;
    final center = _position ?? _target ?? const LatLng(-16.4386, -39.0808);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: SizedBox(height: height, child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Color(0xFF0B2B3C)),
      FlutterMap(mapController: _map,
        options: MapOptions(initialCenter: center, initialZoom: 12.6,
          onMapReady: () => _ready = true,
          onPositionChanged: (_, gesture) { if (gesture) _following = false; }),
        children: [
          ColorFiltered(colorFilter: const ColorFilter.matrix([
            .2126,.7152,.0722,0,0, .2126,.7152,.0722,0,0,
            .2126,.7152,.0722,0,0, 0,0,0,1,0,
          ]), child: TileLayer(urlTemplate: courierTileUrl,
            userAgentPackageName: 'com.portoprime.porto_prime')),
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
          stops: [0, .35, .65, 1], colors: [Color(0xE6102B36), Color(0x55102B36),
            Color(0x33102B36), Color(0xDA102B36)]))))),
      Positioned(top: inset + 12, left: 20, right: 16, child: Row(children: [
        const Expanded(child: _CourierWordmark()),
        const SizedBox(width: 10),
        Badge(isLabelVisible: widget.unreadCount > 0,
          label: Text(widget.unreadCount > 9 ? '9+' : widget.unreadCount.toString()),
          child: _control(AppIcons.bell, 'Atualizações', widget.onNotifications)),
        const SizedBox(width: 8),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 144),
          child: TextButton(onPressed: widget.onLogout,
            style: TextButton.styleFrom(foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const PrimeText('Sair', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))),
      ])),
      Positioned(top: inset + (expandedText ? 110 : 74), right: 16,
        child: _control(Icons.my_location_rounded, 'Localizar minha posição',
          _locating ? null : _locate, busy: _locating)),
      Positioned(left: 8, bottom: 3, child: InkWell(
        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
        child: const Padding(padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text('© OpenStreetMap', style: TextStyle(color: Colors.white70, fontSize: 9))))),
    ]))),

      // Natural height keeps long translations and larger text clear of the map controls.
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: CourierAvailabilityControl(online: widget.online, active: widget.active,
          changing: _changing,
          onTap: widget.active ? widget.onRoute : widget.onChanged == null ? null : _toggle)),
    ]);
  }
}

/// A single touch target owns availability; there are no secondary power buttons.
class CourierAvailabilityControl extends StatelessWidget {
  const CourierAvailabilityControl({super.key, required this.online, required this.active,
    required this.changing, required this.onTap});
  final bool online, active, changing;
  final VoidCallback? onTap;
  @override Widget build(BuildContext context) {
    final enabled = !changing && onTap != null;
    final label = active ? 'Ver detalhes da rota' : online ? 'Ficar offline' : 'Ficar online';
    return Semantics(button: true, toggled: active ? null : online, enabled: enabled,
      label: translateLabel(label),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(22),
        child: InkWell(onTap: enabled ? onTap : null, borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: online
                ? const [Color(0xFF008654), Color(0xFF006C50)]
                : const [Color(0xFF173D48), Color(0xFF102B36)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
              boxShadow: const [BoxShadow(color: Color(0x23102B36), blurRadius: 18, offset: Offset(0, 5))]),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle),
                child: Icon(active ? AppIcons.route : AppIcons.power, color: Colors.white, size: 23)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                  PrimeText(changing ? 'Aguarde um instante' : active ? 'Entrega em andamento'
                    : online ? 'Você está online' : 'Ficar online',
                    style: const TextStyle(fontSize: 15, height: 1.25,
                      color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  PrimeText(active ? 'Ver detalhes da rota' : online
                    ? 'Toque para ficar offline' : 'Receber novas entregas',
                    style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFFDAEEE7))),
                ])),
              const SizedBox(width: 10),
              if (changing) const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else Icon(active ? AppIcons.chevronRight : online ? AppIcons.checkCircle : AppIcons.arrowRight,
                size: 21, color: Colors.white),
            ]),
          ))));
  }
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
