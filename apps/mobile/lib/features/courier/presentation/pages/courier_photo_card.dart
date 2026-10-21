import '../../../../core/localization/prime_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/widgets/prime_identity_widgets.dart';
import '../../../../core/widgets/prime_ui.dart';
class CourierPhotoCard extends StatefulWidget{
  const CourierPhotoCard({super.key,this.initialPhoto,this.onSelected});
  final String? initialPhoto;
  final ValueChanged<String>? onSelected;
  @override State<CourierPhotoCard> createState()=>_CourierPhotoCardState();
}
class _CourierPhotoCardState extends State<CourierPhotoCard>{
  bool saving=false;
  Future<void> choose() async {
    final source=await showModalBottomSheet<ImageSource>(context:context,
      isScrollControlled:true,backgroundColor:Colors.transparent,
      builder:(c)=>PrimePhotoSource(
        onCamera:()=>Navigator.pop(c,ImageSource.camera),
        onGallery:()=>Navigator.pop(c,ImageSource.gallery),
        onClose:()=>Navigator.pop(c)));
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
      final confirmed=await showDialog<bool>(context:context,
        builder:(c)=>PrimePhotoReview(photo:photo,
          onRetake:()=>Navigator.pop(c,false),onUse:()=>Navigator.pop(c,true)));
      if(confirmed!=true)return;
      if(widget.onSelected!=null){widget.onSelected!(photo);}else{
        await AppState.instance.api.request('PATCH','/couriers/profile/photo',body:{'photo':photo});
        await AppState.instance.refreshCourier();
      }
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:PrimeText('Foto selecionada com sucesso.')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:PrimeText(PrimeMessages.friendly(e))));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(animation:AppState.instance,builder:(_,__){
    final photo=widget.onSelected!=null?widget.initialPhoto:AppState.instance.courierProfile['profilePhoto']?.toString();
    return PrimePhotoProfileCard(photo:photo,registration:widget.onSelected!=null,saving:saving,onChoose:choose);
  });
}
