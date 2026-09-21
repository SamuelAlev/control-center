// Temporary audition renderer: writes focus-mood WAVs at three tune-energy
// points, plus Rise at the two mix points the plan asks to listen to.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/soundscape_composer.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';

const int sampleRate = 44100;
const int seconds = 180;
const int blockFrames = 1024;

class _Case {
  const _Case(this.name, this.mood, this.energy);
  final String name;
  final SoundscapeMood mood;
  final double energy;
}

void main(List<String> args) {
  final outDir = args.isNotEmpty ? args[0] : '.';
  const cases = <_Case>[
    _Case('focus_mellow', SoundscapeMood.focus, 0.0),
    _Case('focus_neutral', SoundscapeMood.focus, 0.5),
    _Case('focus_energetic', SoundscapeMood.focus, 1.0),
    _Case('rise_neutral', SoundscapeMood.rise, 0.5),
    _Case('rise_energetic', SoundscapeMood.rise, 1.0),
  ];
  for (final entry in cases) {
    final composer = SoundscapeComposer(
      sampleRate: sampleRate,
      context: SoundscapeContext(
        mood: entry.mood,
        daypart: SoundscapeDaypart.day,
        weather: SoundscapeWeather.clear,
        isDay: true,
        temperatureCelsius: 20.0,
      ),
    )..updateTune(SoundscapeTune(energy: entry.energy, brightness: 0.5));

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

    final path = '$outDir/${entry.name}.wav';
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
