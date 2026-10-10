import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

AudioPlayer? _player;
Future<File>? _soundFile;
int _generation=0;

/// Original four-note bell, generated once locally. No network audio assets.
Uint8List _deliveryBell() {
  const rate=22050;
  const frames=33075;
  final data=ByteData(44+frames*2);
  void text(int at,String value){for(var i=0;i<value.length;i++){data.setUint8(at+i,value.codeUnitAt(i));}}
  text(0,'RIFF');data.setUint32(4,36+frames*2,Endian.little);text(8,'WAVE');text(12,'fmt ');
  data.setUint32(16,16,Endian.little);data.setUint16(20,1,Endian.little);data.setUint16(22,1,Endian.little);
  data.setUint32(24,rate,Endian.little);data.setUint32(28,rate*2,Endian.little);data.setUint16(32,2,Endian.little);data.setUint16(34,16,Endian.little);
  text(36,'data');data.setUint32(40,frames*2,Endian.little);
  const starts=[0.0,.16,.32,.68];
  const notes=[659.25,830.61,987.77,1318.51];
  for(var frame=0;frame<frames;frame++){
    final t=frame/rate;
    var sample=0.0;
    for(var note=0;note<notes.length;note++){
      final age=t-starts[note];
      if(age<0||age>.65)continue;
      final envelope=math.min(1.0,age/.012)*math.exp(-age*7.5)*math.min(1.0,(.65-age)/.025);
      sample+=envelope*(math.sin(2*math.pi*notes[note]*age)+.22*math.sin(4*math.pi*notes[note]*age))*.21;
    }
    data.setInt16(44+frame*2,(sample.clamp(-.9,.9)*32767).round(),Endian.little);
  }
  return data.buffer.asUint8List();
}
Future<File> _prepare() async {
  final directory=await Directory.systemTemp.createTemp('porto-prime-chime-');
  final file=File('${directory.path}/delivery.wav');
  await file.writeAsBytes(_deliveryBell(),flush:true);
  return file;
}
Future<void> playDeliveryOfferSound() async {
  final generation=_generation;
  try {
    final file=await (_soundFile??=_prepare());
    if(generation!=_generation)return;
    final player=_player??=AudioPlayer();
    await player.play(DeviceFileSource(file.path),volume:.85);
    if(generation!=_generation){await player.stop();return;}
    await HapticFeedback.mediumImpact();
  }catch(_){/* Audio must never delay or reject an offer. */}
}
Future<void> stopDeliveryOfferSound() async {
  _generation++;
  try{await _player?.stop();}catch(_){}
}
