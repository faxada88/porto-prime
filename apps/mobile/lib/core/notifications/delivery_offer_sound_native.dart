import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

AudioPlayer? _player;
Future<File>? _soundFile;
int _generation=0;

/// Original Porto Prime alert: six carefully voiced bell tones with a
/// short ascending motif and a soft resolving tail. Synthesised locally.
Uint8List _deliveryBell() {
  const rate = 22050;
  const frames = rate * 2;
  final data = ByteData(44 + frames * 2);
  void text(int at, String value) {
    for (var i = 0; i < value.length; i++) {
      data.setUint8(at + i, value.codeUnitAt(i));
    }
  }
  text(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  text(8, 'WAVE'); text(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  text(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);

  const starts = [0.0, .14, .30, .47, .76, 1.03];
  const notes = [659.25, 830.61, 987.77, 1318.51, 1174.66, 987.77];
  const strengths = [.19, .18, .17, .23, .16, .13];
  for (var frame = 0; frame < frames; frame++) {
    final t = frame / rate;
    var sample = 0.0;
    for (var note = 0; note < notes.length; note++) {
      final age = t - starts[note];
      if (age < 0 || age > .85) continue;
      final attack = math.min(1.0, age / .014);
      final fade = math.exp(-age * (note == 3 ? 4.5 : 6.1));
      final release = math.min(1.0, (.85 - age) / .09);
      final phi = 2 * math.pi * notes[note] * age;
      final bell = math.sin(phi) +
          .19 * math.sin(phi * 2.0) +
          .08 * math.sin(phi * 2.997);
      sample += bell * attack * fade * release * strengths[note];
    }
    // Gentle soft limiter: audible without digital clipping.
    final limited = sample / (1.0 + sample.abs() * .55);
    data.setInt16(44 + frame * 2,
        (limited.clamp(-.95, .95) * 32767).round(), Endian.little);
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
    await player.play(DeviceFileSource(file.path),volume:1.0);
    if(generation!=_generation){await player.stop();return;}
    await HapticFeedback.heavyImpact();
  }catch(_){/* Audio must never delay or reject an offer. */}
}
Future<void> stopDeliveryOfferSound() async {
  _generation++;
  try{await _player?.stop();}catch(_){}
}
