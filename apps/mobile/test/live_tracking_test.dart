import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/tracking/courier_route_tracker.dart';
void main(){
 test('GPS eligibility follows confirmed route state only',(){
  for(final status in ['PENDING','CONFIRMED','COURIER_ASSIGNED','PICKED_UP','DELIVERED']){
   expect(liveRouteMode({'id':'order','status':status}),isNull);
  }
  expect(liveRouteMode({'id':'order','status':'OUT_FOR_DELIVERY'}),'DELIVERY');
  expect(liveRouteMode({'status':'CANCELED','cancellation':{'returnStatus':'REQUIRED'}}),'RETURN');
  expect(liveRouteMode({'status':'CANCELED','cancellation':{'returnStatus':'COMPLETED'}}),isNull);
  expect(liveRouteMode({'status':'OUT_FOR_DELIVERY','adminDeletedAt':'now'}),isNull);
 });
 test('tracking feed delivers updates without mutating order state',()async{
  final next=DeliveryLocationFeed.instance.stream.first;
  DeliveryLocationFeed.instance.receive({'orderId':'one','active':true,'point':{'latitude':-16.4,'longitude':-39.0}});
  expect((await next)['orderId'],'one');
 });
}
