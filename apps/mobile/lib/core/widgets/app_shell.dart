import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
class AppShell extends StatefulWidget{const AppShell({super.key});@override State<AppShell> createState()=>_AppShellState();}
class _AppShellState extends State<AppShell>{
 int index=0;static const pages=[HomePage(),CategoriesPage(),CartPage(),ProfilePage()];
 @override Widget build(BuildContext context)=>ListenableBuilder(listenable:AppState.instance,builder:(context,_)=>Scaffold(body:IndexedStack(index:index,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(v)=>setState(()=>index=v),destinations:[
 const NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Início'),
 const NavigationDestination(icon:Icon(Icons.grid_view_rounded),label:'Categorias'),
 NavigationDestination(icon:Badge(isLabelVisible:AppState.instance.cartCount>0,label:Text(AppState.instance.cartCount.toString()),child:const Icon(Icons.shopping_bag_outlined)),selectedIcon:const Icon(Icons.shopping_bag_rounded),label:'Carrinho'),
 const NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded),label:'Perfil'),
 ])));
}
