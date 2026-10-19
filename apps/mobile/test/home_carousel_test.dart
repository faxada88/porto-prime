import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_home_carousel.dart';

void main(){
 for(final width in [320.0,390.0,768.0]){
  for(final scale in [1.0,1.5,2.0]){
   testWidgets('Every banner fits width=$width text=$scale',(tester)async{
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=Size(width,1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale),disableAnimations:true),child:child!),home:Scaffold(body:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(18),child:PrimeHomeCarousel(onExplore:(){}))))));
    await tester.pump();
    final controller=tester.widget<PageView>(find.byType(PageView)).controller!;
    for(var page=300;page<303;page++){
     controller.jumpToPage(page);
     await tester.pump();
     expect(tester.takeException(),isNull,reason:'Slide $page at $width / $scale');
     expect(find.text('Explorar catálogo').hitTestable(),findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
   });
  }
 }

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
