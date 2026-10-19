import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porto_prime/core/theme/app_theme.dart';
import 'package:porto_prime/core/widgets/prime_brand_banner.dart';

void main(){
 for(final width in [320.0,390.0,768.0]){
  for(final scale in [1.0,1.5,2.0]){
   testWidgets('Brand artwork fits $width / $scale and keeps catalogue action',(tester)async{
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=Size(width,1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened=0;
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,builder:(context,child)=>MediaQuery(
     data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:child!),
     home:Scaffold(body:SingleChildScrollView(child:Padding(padding:const EdgeInsets.all(18),
      child:PrimeBrandBanner(onExplore:()=>opened++))))));
    expect(find.byType(PageView),findsNothing);
    final image=tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,PrimeBrandBanner.asset);
    expect(image.fit,BoxFit.contain);
    expect(tester.getSize(find.byType(AspectRatio)).width,closeTo(width-36>560?560:width-36,.001));
    expect(tester.getSize(find.byType(AspectRatio)).aspectRatio,closeTo(2/3,.001));
    await tester.ensureVisible(find.text('Explorar catálogo'));
    await tester.tap(find.text('Explorar catálogo'));
    expect(opened,1);
    expect(tester.takeException(),isNull);
   });
  }
 }
}
