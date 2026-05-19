import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/soundscape_composer.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:test/test.dart';

const int _sampleRate = 44100;
const int _blockFrames = 1024;

SoundscapeContext _context({
  SoundscapeMood mood = SoundscapeMood.focus,
  SoundscapeDaypart daypart = SoundscapeDaypart.day,
  SoundscapeWeather weather = SoundscapeWeather.clear,
  bool isDay = true,
  double temperatureCelsius = 20.0,
}) => SoundscapeContext(
  mood: mood,
  daypart: daypart,
  weather: weather,
  isDay: isDay,
  temperatureCelsius: temperatureCelsius,
);

/// Renders [blocks] blocks of [_blockFrames] frames into one interleaved
/// stereo buffer.
Float32List _renderAll(SoundscapeComposer composer, int blocks) {
  final block = Float32List(_blockFrames * 2);
  final out = Float32List(_blockFrames * 2 * blocks);
  for (var b = 0; b < blocks; b++) {
    composer.renderBlock(block, _blockFrames);
    out.setRange(b * block.length, (b + 1) * block.length, block);
  }
  return out;
}

double _rms(Float32List buffer) {
  var sum = 0.0;
  for (var i = 0; i < buffer.length; i++) {
    final v = buffer[i];
    sum += v * v;
  }
  return math.sqrt(sum / buffer.length);
}

/// Scans [buffer] without per-sample expect overhead; returns the first
/// offending index or -1.
int _firstInvalid(Float32List buffer) {
  for (var i = 0; i < buffer.length; i++) {
    final v = buffer[i];
    if (!v.isFinite || v.abs() > 1.0) {
      return i;
    }
  }
  return -1;
}

void main() {
  group('SoundscapeComposer.renderBlock', () {
    test('produces only finite samples within [-1, 1]', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      );
      final signal = _renderAll(composer, 40);
      expect(_firstInvalid(signal), -1);
    });

    test('is audible: RMS is above zero and in a sane range', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      );
      // Skip the 2 s session fade-in, then measure.
      _renderAll(composer, 120);
      final rms = _rms(_renderAll(composer, 40));
      expect(rms, greaterThan(1e-4));
      expect(rms, lessThan(0.9));
    });

    test('holds the limiter under a loud storm arrangement', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(
          mood: SoundscapeMood.relax,
          weather: SoundscapeWeather.storm,
          daypart: SoundscapeDaypart.night,
          isDay: false,
          temperatureCelsius: 4.0,
        ),
      );
      final signal = _renderAll(composer, 40);
      expect(_firstInvalid(signal), -1);
      expect(_rms(signal), greaterThan(1e-4));
    });

    test('two composers with the same context render bit-identical audio', () {
      final ctx = _context(
        mood: SoundscapeMood.relax,
        weather: SoundscapeWeather.rain,
        daypart: SoundscapeDaypart.dusk,
        temperatureCelsius: 12.5,
      );
      final a = SoundscapeComposer(sampleRate: _sampleRate, context: ctx);
      final b = SoundscapeComposer(sampleRate: _sampleRate, context: ctx);
      final signalA = _renderAll(a, 24);
      final signalB = _renderAll(b, 24);
      expect(signalA.length, equals(signalB.length));
      for (var i = 0; i < signalA.length; i++) {
        if (signalA[i] != signalB[i]) {
          fail('sample $i differs: ${signalA[i]} vs ${signalB[i]}');
        }
      }
    });

    test('identical contexts built independently share a seed and audio', () {
      final a = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(weather: SoundscapeWeather.snow),
      );
      final b = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(weather: SoundscapeWeather.snow),
      );
      expect(a.context.seed, equals(b.context.seed));
      expect(_renderAll(a, 8), orderedEquals(_renderAll(b, 8)));
    });

    test('stays finite, bounded, and smooth over a long render', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(mood: SoundscapeMood.relax),
      );
      final block = Float32List(_blockFrames * 2);
      // Past the fade-in first.
      for (var i = 0; i < 120; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      // ~60 s of audio: never invalid, never silent for long, and no
      // block-to-block RMS jumps (smoothness is the whole point).
      var previousRms = _rms(block);
      var quietBlocks = 0;
      const totalBlocks = 2500;
      for (var i = 0; i < totalBlocks; i++) {
        composer.renderBlock(block, _blockFrames);
        final invalid = _firstInvalid(block);
        if (invalid >= 0) {
          fail('invalid sample at block $i index $invalid: ${block[invalid]}');
        }
        final rms = _rms(block);
        if (rms < 1e-4) {
          quietBlocks++;
        }
        if ((rms - previousRms).abs() > 0.08) {
          fail(
            'RMS jumped ${previousRms.toStringAsFixed(4)} -> '
            '${rms.toStringAsFixed(4)} at block $i',
          );
        }
        previousRms = rms;
      }
      expect(quietBlocks, equals(0), reason: 'the bed must never fall silent');
    });
  });

  group('SoundscapeComposer.updateTune', () {
    test('the neutral tune is audibly non-existent (bit-identical)', () {
      final untouched = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      );
      final neutral = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      )..updateTune(SoundscapeTune.neutral);
      expect(_renderAll(untouched, 24), orderedEquals(_renderAll(neutral, 24)));
    });

    test('identical tune sequences render identical audio', () {
      SoundscapeComposer build() => SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(mood: SoundscapeMood.relax),
      );
      final a = build();
      final b = build();
      final tune = SoundscapeTune(energy: 0.9, brightness: 0.15);
      final signalA = <double>[];
      final signalB = <double>[];
      for (final (composer, signal) in [(a, signalA), (b, signalB)]) {
        final block = Float32List(_blockFrames * 2);
        for (var i = 0; i < 8; i++) {
          composer.renderBlock(block, _blockFrames);
        }
        composer.updateTune(tune);
        for (var i = 0; i < 16; i++) {
          composer.renderBlock(block, _blockFrames);
          signal.addAll(block);
        }
      }
      expect(signalA, orderedEquals(signalB));
    });

    test('full energy audibly thickens a focus session (pulse + arp)', () {
      SoundscapeComposer build() =>
          SoundscapeComposer(sampleRate: _sampleRate, context: _context());
      // Same seed, same block sequence; only the tune differs.
      final neutral = build();
      final energetic = build()
        ..updateTune(SoundscapeTune(energy: 1.0, brightness: 0.5));
      // Settle past the fade-in, AM ramp start, and the tune ramp.
      _renderAll(neutral, 200);
      _renderAll(energetic, 200);
      // ~24 s: long enough to catch pulse beats and arp notes.
      final neutralRms = _rms(_renderAll(neutral, 1000));
      final energeticRms = _rms(_renderAll(energetic, 1000));
      expect(
        energeticRms,
        greaterThan(neutralRms * 1.02),
        reason: 'the energy axis must add real layers, not a subtle EQ',
      );
    });

    test('an extreme tune glides in — no jump, stays finite and bounded', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      );
      final block = Float32List(_blockFrames * 2);
      // Settle past the fade-in.
      for (var i = 0; i < 150; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      final rmsBefore = _rms(block);

      composer.updateTune(SoundscapeTune(energy: 1.0, brightness: 0.0));
      composer.renderBlock(block, _blockFrames);
      expect(
        (_rms(block) - rmsBefore).abs(),
        lessThan(0.05),
        reason: 'the 1.5 s tune ramp must not jump',
      );

      // Through and past the ramp: always valid.
      for (var i = 0; i < 200; i++) {
        composer.renderBlock(block, _blockFrames);
        final invalid = _firstInvalid(block);
        if (invalid >= 0) {
          fail('invalid sample at block $i index $invalid');
        }
      }
      expect(_rms(block), greaterThan(1e-4));
    });
  });

  group('SoundscapeComposer.updateContext', () {
    test('glides levels instead of jumping at the boundary', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(
          mood: SoundscapeMood.sleep,
          weather: SoundscapeWeather.clear,
          daypart: SoundscapeDaypart.night,
          isDay: false,
        ),
      );

      final block = Float32List(_blockFrames * 2);
      // Settle well past the session fade-in.
      for (var i = 0; i < 150; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      final rmsBefore = _rms(block);

      // A big arrangement change: loud, dark, wetter.
      composer.updateContext(
        _context(
          mood: SoundscapeMood.sleep,
          weather: SoundscapeWeather.storm,
          daypart: SoundscapeDaypart.night,
          isDay: false,
          temperatureCelsius: 2.0,
        ),
      );
      composer.renderBlock(block, _blockFrames);
      final rmsAfter = _rms(block);

      // The 10-second ramp means the first block after the change barely
      // moves.
      expect((rmsAfter - rmsBefore).abs(), lessThan(0.05));
    });

    test('remains finite and within range across a context change', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(),
      );
      final block = Float32List(_blockFrames * 2);
      for (var i = 0; i < 10; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      composer.updateContext(
        _context(
          mood: SoundscapeMood.sleep,
          weather: SoundscapeWeather.fog,
          daypart: SoundscapeDaypart.night,
          isDay: false,
        ),
      );
      for (var i = 0; i < 200; i++) {
        composer.renderBlock(block, _blockFrames);
        final invalid = _firstInvalid(block);
        if (invalid >= 0) {
          fail('invalid sample at block $i index $invalid');
        }
      }
      expect(composer.context.mood, SoundscapeMood.sleep);
    });

    test('eventually reaches the new arrangement level', () {
      final composer = SoundscapeComposer(
        sampleRate: _sampleRate,
        context: _context(
          mood: SoundscapeMood.sleep,
          weather: SoundscapeWeather.clear,
          daypart: SoundscapeDaypart.night,
          isDay: false,
        ),
      );
      final block = Float32List(_blockFrames * 2);
      for (var i = 0; i < 150; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      final quietRms = _rms(block);

      composer.updateContext(
        _context(
          mood: SoundscapeMood.sleep,
          weather: SoundscapeWeather.storm,
          daypart: SoundscapeDaypart.night,
          isDay: false,
          temperatureCelsius: 2.0,
        ),
      );
      // Render well past the 10-second ramp (~430 blocks).
      for (var i = 0; i < 600; i++) {
        composer.renderBlock(block, _blockFrames);
      }
      final loudRms = _rms(block);
      expect(loudRms, greaterThan(quietRms));
    });
  });
}
