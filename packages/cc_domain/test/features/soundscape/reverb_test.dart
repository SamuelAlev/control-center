import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/reverb.dart';
import 'package:test/test.dart';

const int _sampleRate = 48000;
const int _block = 1024;

/// Feeds one unit impulse into [reverb] and returns [seconds] of wet output.
Float32List _impulseResponse(Reverb reverb, {required double seconds}) {
  final frames = (seconds * _sampleRate).round();
  final out = Float32List(frames * 2);
  final send = Float32List(_block * 2);
  var offset = 0;
  var first = true;
  while (offset < frames) {
    final n = offset + _block <= frames ? _block : frames - offset;
    for (var i = 0; i < n * 2; i++) {
      send[i] = 0.0;
    }
    if (first) {
      send[0] = 1.0;
      send[1] = 1.0;
      first = false;
    }
    final view = Float32List.sublistView(out, offset * 2, (offset + n) * 2);
    reverb.processAdd(send, view, n, 1.0);
    offset += n;
  }
  return out;
}

double _energy(Float32List stereo, double fromSecond, double toSecond) {
  final from = (fromSecond * _sampleRate).round() * 2;
  final to = (toSecond * _sampleRate).round() * 2;
  var sum = 0.0;
  for (var i = from; i < to && i < stereo.length; i++) {
    sum += stereo[i] * stereo[i];
  }
  return sum;
}

void main() {
  group('Reverb (Dattorro plate)', () {
    test('produces a finite, decaying, non-empty tail', () {
      final reverb = Reverb(_sampleRate.toDouble())
        ..setDecay(0.5)
        ..setDamp(0.3)
        ..setPreDelayMs(25.0)
        ..setWetHighPassHz(300.0);
      final ir = _impulseResponse(reverb, seconds: 4.0);

      for (var i = 0; i < ir.length; i++) {
        if (!ir[i].isFinite) {
          fail('non-finite sample at $i');
        }
      }
      final early = _energy(ir, 0.0, 1.0);
      final late = _energy(ir, 3.0, 4.0);
      expect(early, greaterThan(0.0), reason: 'tail must exist');
      expect(late, lessThan(early), reason: 'tail must decay');
    });

    test('longer decay setting yields a longer tail', () {
      final short = Reverb(_sampleRate.toDouble())..setDecay(0.1);
      final long = Reverb(_sampleRate.toDouble())..setDecay(0.9);
      final shortIr = _impulseResponse(short, seconds: 4.0);
      final longIr = _impulseResponse(long, seconds: 4.0);

      final shortRatio =
          _energy(shortIr, 2.0, 4.0) / _energy(shortIr, 0.0, 0.5);
      final longRatio = _energy(longIr, 2.0, 4.0) / _energy(longIr, 0.0, 0.5);
      expect(longRatio, greaterThan(shortRatio));
    });

    test('a high decay stays bounded (no runaway feedback)', () {
      final reverb = Reverb(_sampleRate.toDouble())
        ..setDecay(1.0)
        ..setDamp(0.0);
      // Sustained input for 8 s, then check the output never explodes.
      final send = Float32List(_block * 2);
      final out = Float32List(_block * 2);
      var peak = 0.0;
      final blocks = (8.0 * _sampleRate / _block).round();
      for (var b = 0; b < blocks; b++) {
        for (var i = 0; i < _block; i++) {
          send[2 * i] = 0.1;
          send[2 * i + 1] = 0.1;
        }
        for (var i = 0; i < _block * 2; i++) {
          out[i] = 0.0;
        }
        reverb.processAdd(send, out, _block, 1.0);
        for (var i = 0; i < _block * 2; i++) {
          final v = out[i].abs();
          if (v > peak) {
            peak = v;
          }
          if (!out[i].isFinite) {
            fail('non-finite at block $b');
          }
        }
      }
      expect(peak, lessThan(20.0), reason: 'tank must not run away');
    });

    test('zero wet adds nothing', () {
      final reverb = Reverb(_sampleRate.toDouble());
      final send = Float32List(_block * 2)..fillRange(0, _block * 2, 0.5);
      final out = Float32List(_block * 2);
      reverb.processAdd(send, out, _block, 0.0);
      for (var i = 0; i < out.length; i++) {
        expect(out[i], equals(0.0));
      }
    });

    test('stereo output channels are decorrelated', () {
      final reverb = Reverb(_sampleRate.toDouble())..setDecay(0.7);
      final ir = _impulseResponse(reverb, seconds: 2.0);
      var dot = 0.0;
      var normL = 0.0;
      var normR = 0.0;
      for (var i = 0; i < ir.length ~/ 2; i++) {
        final l = ir[2 * i];
        final r = ir[2 * i + 1];
        dot += l * r;
        normL += l * l;
        normR += r * r;
      }
      expect(normL, greaterThan(0.0));
      expect(normR, greaterThan(0.0));
      final correlation =
          dot / math.sqrt((normL * normR).clamp(1e-12, double.infinity));
      // Normalized cross-correlation well below 1 => genuinely different taps.
      expect(correlation.abs(), lessThan(0.5));
    });
  });
}
