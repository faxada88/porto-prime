import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../navigation/app_nav.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const pages = [HomePage(), CategoriesPage(), CartPage(), ProfilePage()];
  @override void initState(){super.initState();AppNav.instance.index.addListener(_changed);}
  @override void dispose(){AppNav.instance.index.removeListener(_changed);super.dispose();}
  void _changed()=>setState((){});

  @override Widget build(BuildContext context) {
    final index=AppNav.instance.index.value;
    return Scaffold(
      extendBody:true,
      body:IndexedStack(index:index,children:pages),
      bottomNavigationBar:SafeArea(
        minimum:const EdgeInsets.fromLTRB(16,0,16,10),
        child:Container(
          height:74,padding:const EdgeInsets.all(7),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(28),border:Border.all(color:AppColors.stroke),boxShadow:AppShadows.elevated),
          child:AnimatedBuilder(animation:AppState.instance,builder:(_,__)=>Row(children:[
            _item(0,Symbols.home_rounded,'Início',index),
            _item(1,Symbols.explore_rounded,'Descobrir',index),
            _item(2,Symbols.shopping_cart_rounded,'Carrinho',index,badge:AppState.instance.cartCount),
            _item(3,Symbols.person_rounded,'Perfil',index),
          ])),
        ),
      ),
    );
  }

  Widget _item(int value,IconData icon,String label,int current,{int badge=0}) {
    final selected=current==value;
    return Expanded(child:GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:()=>AppNav.instance.go(value),
      child:AnimatedContainer(duration:const Duration(milliseconds:240),curve:Curves.easeOutCubic,decoration:BoxDecoration(color:selected?AppColors.peach:Colors.transparent,borderRadius:BorderRadius.circular(21)),
        child:Stack(clipBehavior:Clip.none,alignment:Alignment.center,children:[
          Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(icon,size:22,color:selected?AppColors.primary:AppColors.muted),
            const SizedBox(height:3),
            Text(label,style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:selected?AppColors.primary:AppColors.muted)),
          ]),
          if(badge>0) Positioned(top:1,right:10,child:AnimatedSwitcher(duration:const Duration(milliseconds:260),transitionBuilder:(child,animation)=>ScaleTransition(scale:CurvedAnimation(parent:animation,curve:Curves.easeOutBack),child:child),child:Container(key:ValueKey(badge),constraints:const BoxConstraints(minWidth:19,minHeight:19),padding:const EdgeInsets.symmetric(horizontal:5),decoration:BoxDecoration(color:AppColors.orange,borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white,width:2),boxShadow:const [BoxShadow(color:Color(0x22000000),blurRadius:7,offset:Offset(0,3))]),alignment:Alignment.center,child:Text(badge>9?'9+':'$badge',style:const TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w900))))),
        ]),
      ),
    ));
  }
}
