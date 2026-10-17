import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../network/api_client.dart';

String? liveRouteMode(Map<String,dynamic>? order) {
  if(order==null||order['adminDeletedAt']!=null)return null;
  if(order['status']=='CANCELED')return ['REQUIRED','IN_TRANSIT','ARRIVED'].contains(order['cancellation']?['returnStatus'])?'RETURN':null;
  return order['status']=='OUT_FOR_DELIVERY'?'DELIVERY':null;
}

/// Separate GPS transport. It never changes order, dispatch, presence or wallet state.
class CourierRouteTracker extends ChangeNotifier with WidgetsBindingObserver {
  CourierRouteTracker._(){WidgetsBinding.instance.addObserver(this);}
  static final instance=CourierRouteTracker._();
  StreamSubscription<Position>? _subscription;
  Timer? _heartbeat;
  Map<String,dynamic>? _order;
  String? _orderId,_sessionId;
  Position? _latest;
  bool _starting=false,_sending=false;
  int _generation=0;
  DateTime? _lastAttempt;
  String message='Localização disponível ao iniciar a rota';
  bool sharing=false;
  void _status(String value,{bool active=false}){message=value;sharing=active;notifyListeners();}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&_order!=null)unawaited(sync(_order));}
  Future<void> stop() async {
    _generation++;_order=null;_orderId=null;_sessionId=null;_latest=null;_heartbeat?.cancel();_heartbeat=null;
    final old=_subscription;_subscription=null;await old?.cancel();
    _status('Compartilhamento encerrado');
  }
  Future<void> sync(Map<String,dynamic>? order,{bool requestPermission=false}) async {
    if(liveRouteMode(order)==null){if(_order!=null||_orderId!=null||_starting)await stop();return;}
    _order=order;
    final id=order!['id'].toString(),session=ApiClient.instance.sessionId;
    if(_orderId!=null&&(_orderId!=id||_sessionId!=session))await stop();
    _order=order;
    if(_subscription!=null||_starting)return;
    if(!requestPermission&&_lastAttempt!=null&&DateTime.now().difference(_lastAttempt!).inSeconds<20)return;
    _lastAttempt=DateTime.now();_starting=true;
    final generation=_generation;
    try {
      if(!await Geolocator.isLocationServiceEnabled()){_status('Ative o GPS para compartilhar a rota');return;}
      var permission=await Geolocator.checkPermission();
      if(requestPermission&&permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever){_status('Permita a localização para o cliente acompanhar');return;}
      if(generation!=_generation||ApiClient.instance.token==null)return;
      _orderId=id;_sessionId=session;
      final LocationSettings settings;
      if(!kIsWeb&&defaultTargetPlatform==TargetPlatform.android){
        settings=AndroidSettings(accuracy:LocationAccuracy.high,distanceFilter:5,intervalDuration:const Duration(seconds:5),
          foregroundNotificationConfig:const ForegroundNotificationConfig(notificationTitle:'Porto Prime • Rota em andamento',notificationText:'Sua localização está sendo compartilhada durante esta entrega.',notificationChannelName:'Rota Porto Prime',setOngoing:true,enableWakeLock:true));
      }else if(!kIsWeb&&defaultTargetPlatform==TargetPlatform.iOS){
        settings=AppleSettings(accuracy:LocationAccuracy.high,distanceFilter:5,activityType:ActivityType.automotiveNavigation,pauseLocationUpdatesAutomatically:false,showBackgroundLocationIndicator:true,allowBackgroundLocationUpdates:true);
      }else{settings=const LocationSettings(accuracy:LocationAccuracy.high,distanceFilter:5);}
      _status('Buscando sinal GPS…');
      _subscription=Geolocator.getPositionStream(locationSettings:settings).listen((position){
        if(generation!=_generation)return;_latest=position;unawaited(_send());
      },onError:(Object error){if(generation==_generation){final old=_subscription;_subscription=null;unawaited(old?.cancel());_heartbeat?.cancel();_status('Sinal GPS indisponível. Sua entrega continua ativa.');}});
      _heartbeat=Timer.periodic(const Duration(seconds:6),(_)=>unawaited(_send()));
    }catch(_){if(generation==_generation)_status('Não foi possível iniciar o GPS. Tente novamente.');}
    finally{_starting=false;}
  }
  Future<void> retry() async {final order=_order;if(order==null)return;await stop();await sync(order,requestPermission:true);}
  Future<void> _send() async {
    if(_sending||_orderId==null)return;
    final api=ApiClient.instance;
    if(api.token==null||api.sessionId!=_sessionId){await stop();return;}
    _sending=true;final generation=_generation,id=_orderId!;
    try{
      // This read also stops collection after remote completion/cancellation,
      // even while the courier screen is in the background.
      final state=await api.request('GET','/orders/$id/tracking',timeout:const Duration(seconds:10));
      if(generation!=_generation)return;
      if(state['active']!=true){await stop();return;}
      var p=_latest;
      if(p==null||DateTime.now().difference(p.timestamp).inSeconds>20){
        p=await Geolocator.getCurrentPosition(locationSettings:const LocationSettings(accuracy:LocationAccuracy.high,timeLimit:Duration(seconds:10)));
        if(generation!=_generation)return;_latest=p;
      }
      if(DateTime.now().difference(p.timestamp).inSeconds>45){_status('Aguardando uma posição GPS recente');return;}
      if(p.accuracy>100){_status('Melhorando a precisão do GPS…');return;}
      final result=await api.request('POST','/orders/$id/tracking/location',body:{'latitude':p.latitude,'longitude':p.longitude,'accuracy':p.accuracy,'heading':p.heading,'capturedAt':p.timestamp.toUtc().toIso8601String()},timeout:const Duration(seconds:10));
      if(generation!=_generation)return;
      if(result['active']!=true){await stop();return;}
      _status(state['mode']=='RETURN'?'Retorno compartilhado com a Porto Prime':'Cliente acompanhando sua localização',active:true);
    }catch(error){
      final text=error.toString();
      if(text.contains('Entrega não encontrada')||text.contains('Entrega não atribuída')||text.contains('Acompanhamento não permitido')){await stop();return;}
      if(generation==_generation)_status('Sem conexão com o rastreamento. Tentando reconectar…');
    }
    finally{_sending=false;}
  }
}

class DeliveryLocationFeed {
  DeliveryLocationFeed._();
  static final instance=DeliveryLocationFeed._();
  final _events=StreamController<Map<String,dynamic>>.broadcast();
  Stream<Map<String,dynamic>> get stream=>_events.stream;
  void receive(dynamic payload){if(payload is Map)_events.add(Map<String,dynamic>.from(payload));}
}
