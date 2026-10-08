import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
class CourierPortrait extends StatelessWidget{
  const CourierPortrait({super.key,required this.photo,this.size=64});
  final String? photo;
  final double size;
  @override Widget build(BuildContext context){
    Widget fallback=Icon(AppIcons.user,size:size*.44,color:AppColors.ocean700);
    Widget image=fallback;
    try{if(photo!=null&&photo!.startsWith('data:image/')&&photo!.length<83000){image=Image.memory(base64Decode(photo!.split(',').last),width:size,height:size,fit:BoxFit.cover,cacheWidth:512,errorBuilder:(_,__,___)=>fallback);}}catch(_){}
    return Semantics(label:photo==null?'Foto do motoboy ainda não adicionada':'Foto de perfil do motoboy',image:true,child:Container(width:size,height:size,decoration:BoxDecoration(color:AppColors.ocean100,shape:BoxShape.circle,border:Border.all(color:Colors.white,width:3),boxShadow:AppShadows.soft),child:ClipOval(child:image)));
  }
}
