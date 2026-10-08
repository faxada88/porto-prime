import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/courier_portrait.dart';
import '../../../../core/widgets/prime_ui.dart';
class CourierPhotoCard extends StatefulWidget{
  const CourierPhotoCard({super.key});
  @override State<CourierPhotoCard> createState()=>_CourierPhotoCardState();
}
class _CourierPhotoCardState extends State<CourierPhotoCard>{
  bool saving=false;
  Future<void> choose() async {
    final source=await showModalBottomSheet<ImageSource>(context:context,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[const SizedBox(height:14),const Text('Sua foto de perfil',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),ListTile(leading:const Icon(AppIcons.user),title:const Text('Tirar uma selfie'),onTap:()=>Navigator.pop(c,ImageSource.camera)),ListTile(leading:const Icon(AppIcons.grid_view_rounded),title:const Text('Escolher da galeria'),onTap:()=>Navigator.pop(c,ImageSource.gallery)),const SizedBox(height:10)])));
    if(source==null||!mounted)return;
    setState(()=>saving=true);
    try{
      final file=await ImagePicker().pickImage(source:source,preferredCameraDevice:CameraDevice.front,maxWidth:320,maxHeight:320,imageQuality:55,requestFullMetadata:false);
      if(file==null)return;
      final bytes=await file.readAsBytes();
      if(bytes.length>60*1024)throw Exception('A foto precisa ter até 60 KB. Escolha uma imagem menor.');
      final jpeg=bytes.length>2&&bytes[0]==255&&bytes[1]==216;
      final png=bytes.length>8&&bytes[0]==137&&bytes[1]==80;
      if(!jpeg&&!png)throw Exception('Escolha uma foto JPEG ou PNG.');
      final photo='data:image/${jpeg?'jpeg':'png'};base64,${base64Encode(bytes)}';
      if(!mounted)return;
      final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Usar esta foto?'),content:Column(mainAxisSize:MainAxisSize.min,children:[CourierPortrait(photo:photo,size:150),const SizedBox(height:16),const Text('Use uma foto sua, com o rosto visível. O cliente verá esta imagem na entrega.',textAlign:TextAlign.center)]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Escolher outra')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Salvar foto'))]));
      if(confirmed!=true)return;
      await AppState.instance.api.request('PATCH','/couriers/profile/photo',body:{'photo':photo});
      await AppState.instance.refreshCourier();
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Foto de perfil atualizada.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(PrimeMessages.friendly(e))));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__){final photo=AppState.instance.courierProfile['profilePhoto']?.toString();return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,border:Border.all(color:photo==null?AppColors.sun200:AppColors.stroke),borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[CourierPortrait(photo:photo),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(photo==null?'Adicione sua foto':'Seu rosto, sua entrega',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(photo==null?'Obrigatória para ficar online.':'Esta é a foto mostrada ao cliente.',style:const TextStyle(fontSize:12,color:AppColors.muted,height:1.4))]))]),const SizedBox(height:14),const Text('Escolha uma selfie ou foto da galeria com seu rosto visível.',style:TextStyle(fontSize:12,color:AppColors.muted)),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:choose,icon:saving?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(AppIcons.user,size:18),label:Text(saving?'Preparando foto…':photo==null?'Adicionar minha foto':'Alterar foto')))]));});
}
