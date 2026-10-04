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
            _item(2,Symbols.shopping_bag_rounded,'Sacola',index,badge:AppState.instance.cartCount),
            _item(3,Symbols.person_rounded,'Perfil',index),
          ])),
        ),
      ),
    );
  }

  Widget _item(int value,IconData icon,String label,int current,{int badge=0}) {
    final selected=current==value;
    return Expanded(child:InkWell(
      onTap:()=>AppNav.instance.go(value),borderRadius:BorderRadius.circular(21),
      child:AnimatedContainer(duration:const Duration(milliseconds:240),curve:Curves.easeOutCubic,decoration:BoxDecoration(color:selected?AppColors.peach:Colors.transparent,borderRadius:BorderRadius.circular(21)),
        child:Stack(clipBehavior:Clip.none,alignment:Alignment.center,children:[
          Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(icon,size:22,color:selected?AppColors.primary:AppColors.muted),
            const SizedBox(height:3),
            Text(label,style:TextStyle(fontSize:10,fontWeight:FontWeight.w800,color:selected?AppColors.primary:AppColors.muted)),
          ]),
          if(badge>0) Positioned(top:3,right:12,child:Container(constraints:const BoxConstraints(minWidth:18,minHeight:18),padding:const EdgeInsets.symmetric(horizontal:5),decoration:BoxDecoration(color:AppColors.orange,borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white,width:2)),alignment:Alignment.center,child:Text(badge>9?'9+':'$badge',style:const TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w900)))),
        ]),
      ),
    ));
  }
}
