// Temporary audition renderer: writes focus-mood WAVs at three tune-energy
// points so the soundscape can be inspected/analyzed offline.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/soundscape_composer.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';

const int sampleRate = 44100;
const int seconds = 180;
const int blockFrames = 1024;

void main(List<String> args) {
  final outDir = args.isNotEmpty ? args[0] : '.';
  final cases = <String, double>{
    'focus_mellow': 0.0,
    'focus_neutral': 0.5,
    'focus_energetic': 1.0,
  };
  for (final entry in cases.entries) {
    final composer = SoundscapeComposer(
      sampleRate: sampleRate,
      context: const SoundscapeContext(
        mood: SoundscapeMood.focus,
        daypart: SoundscapeDaypart.day,
        weather: SoundscapeWeather.clear,
        isDay: true,
        temperatureCelsius: 20.0,
      ),
    )..updateTune(SoundscapeTune(energy: entry.value, brightness: 0.5));

    const totalFrames = sampleRate * seconds;
    final pcm = Int16List(totalFrames * 2);
    final block = Float32List(blockFrames * 2);
    var written = 0;
    while (written < totalFrames) {
      final frames = (totalFrames - written).clamp(0, blockFrames);
      composer.renderBlock(block, frames);
      for (var i = 0; i < frames * 2; i++) {
        pcm[written * 2 + i] = (block[i] * 32767.0).round().clamp(
          -32768,
          32767,
        );
      }
      written += frames;
    }

    final path = '$outDir/${entry.key}.wav';
    File(path).writeAsBytesSync(_wav(pcm, sampleRate));
    print('wrote $path');
  }
}

Uint8List _wav(Int16List pcm, int sampleRate) {
  final dataBytes = pcm.length * 2;
  final header = ByteData(44);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 2, Endian.little); // stereo
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 4, Endian.little);
  header.setUint16(32, 4, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, dataBytes, Endian.little);

  final bytes = Uint8List(44 + dataBytes);
  bytes.setRange(0, 44, header.buffer.asUint8List());
  bytes.setRange(44, bytes.length, pcm.buffer.asUint8List());
  return bytes;
}
