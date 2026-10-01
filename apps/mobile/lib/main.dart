import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_page.dart';
void main()=>runApp(const PortoPrimeApp());
class PortoPrimeApp extends StatelessWidget{const PortoPrimeApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Porto Prime',theme:AppTheme.light,home:const SplashPage());}