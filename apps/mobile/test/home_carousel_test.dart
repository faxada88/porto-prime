import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_home_carousel.dart';

void main(){
 testWidgets('Carousel advances automatically, pauses and delegates catalogue action',(tester)async{
  var taps=0;
  await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:Scaffold(body:PrimeHomeCarousel(onExplore:()=>taps++))));
  await tester.pump();
  final controller=tester.widget<PageView>(find.byType(PageView)).controller!;
  expect(controller.page,300);
  await tester.pump(const Duration(seconds:5));await tester.pump(const Duration(milliseconds:600));
  expect(controller.page,closeTo(301,.01));
  await tester.tap(find.byTooltip('Pausar banners'));await tester.pump();
  final page=controller.page;
  await tester.pump(const Duration(seconds:7));expect(controller.page,page);
  await tester.tap(find.text('Explorar catálogo').hitTestable().first);expect(taps,1);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });
 testWidgets('Reduced motion disables automatic slide animations',(tester)async{
  await tester.pumpWidget(MaterialApp(builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(disableAnimations:true),child:child!),home:Scaffold(body:PrimeHomeCarousel(onExplore:(){}))));
  await tester.pump();final controller=tester.widget<PageView>(find.byType(PageView)).controller!;
  await tester.pump(const Duration(seconds:12));expect(controller.page,300);
  expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
