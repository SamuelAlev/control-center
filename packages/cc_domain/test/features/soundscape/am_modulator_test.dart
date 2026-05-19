import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/am_modulator.dart';
import 'package:test/test.dart';

const int _sampleRate = 48000;

/// Renders [seconds] of a [frequencyHz] sine through [am] at [depth] and
/// returns the interleaved output.
Float32List _modulatedSine(
  AmModulator am, {
  required double frequencyHz,
  required double depth,
  required double seconds,
}) {
  final frames = (seconds * _sampleRate).round();
  final buf = Float32List(frames * 2);
  const block = 1024;
  var offset = 0;
  var phase = 0.0;
  final inc = frequencyHz / _sampleRate;
  while (offset < frames) {
    final n = math.min(block, frames - offset);
    for (var i = 0; i < n; i++) {
      final s = 0.5 * math.sin(2 * math.pi * phase);
      phase += inc;
      buf[2 * (offset + i)] = s;
      buf[2 * (offset + i) + 1] = s;
    }
    final view = Float32List.sublistView(buf, offset * 2, (offset + n) * 2);
    am.processInPlace(view, n, depth);
    offset += n;
  }
  return buf;
}

/// Short-window RMS envelope of the left channel from [fromSecond] on.
///
/// [window] must span an exact multiple of the carrier period (else the RMS
/// ripples at the carrier rate and masquerades as modulation) while staying
/// well below the AM period so the modulation itself resolves.
List<double> _envelope(
  Float32List stereo, {
  required double fromSecond,
  required int window,
}) {
  final start = (fromSecond * _sampleRate).round();
  final frames = stereo.length ~/ 2;
  final env = <double>[];
  for (var f = start; f + window <= frames; f += window) {
    var sum = 0.0;
    for (var i = f; i < f + window; i++) {
      final v = stereo[2 * i];
      sum += v * v;
    }
    env.add(math.sqrt(sum / window));
  }
  return env;
}

/// Exactly two 500 Hz carrier cycles at 48 kHz — 4 ms, 15.6 windows per
/// 16 Hz AM cycle.
const int _window500Hz = 192;

/// Exactly one 60 Hz carrier cycle at 48 kHz.
const int _window60Hz = 800;

void main() {
  group('AmModulator', () {
    test(
      'zero depth reconstructs the input exactly (band split is lossless)',
      () {
        final am = AmModulator(_sampleRate.toDouble(), rateHz: 16.0);
        final out = _modulatedSine(
          am,
          frequencyHz: 500.0,
          depth: 0.0,
          seconds: 0.5,
        );
        // Compare to a raw sine rendered the same way.
        var phase = 0.0;
        const inc = 500.0 / _sampleRate;
        for (var i = 0; i < out.length ~/ 2; i++) {
          final expected = 0.5 * math.sin(2 * math.pi * phase);
          phase += inc;
          expect(
            (out[2 * i] - expected).abs(),
            lessThan(1e-4),
            reason: 'sample $i drifted',
          );
        }
      },
    );

    test('modulates a mid-band tone at the configured rate and depth', () {
      final am = AmModulator(
        _sampleRate.toDouble(),
        rateHz: 16.0,
        rampSeconds: 0.5,
      );
      final out = _modulatedSine(
        am,
        frequencyHz: 500.0,
        depth: 0.4,
        seconds: 3.0,
      );
      // Past the ramp, the envelope must visibly pump...
      final env = _envelope(out, fromSecond: 2.0, window: _window500Hz);
      final maxEnv = env.reduce(math.max);
      final minEnv = env.reduce(math.min);
      expect(
        maxEnv / minEnv,
        greaterThan(1.2),
        reason: 'modulation not audible in the envelope',
      );
      // ...at ~16 Hz: count envelope minima per second.
      var dips = 0;
      final threshold = minEnv + 0.25 * (maxEnv - minEnv);
      var below = false;
      for (final value in env) {
        if (!below && value < threshold) {
          below = true;
          dips++;
        } else if (below && value > threshold) {
          below = false;
        }
      }
      final seconds = env.length * _window500Hz / _sampleRate;
      expect(dips / seconds, closeTo(16.0, 2.0));
    });

    test('leaves an out-of-band low tone essentially untouched', () {
      final am = AmModulator(
        _sampleRate.toDouble(),
        rateHz: 16.0,
        rampSeconds: 0.5,
      );
      final out = _modulatedSine(
        am,
        frequencyHz: 60.0,
        depth: 0.4,
        seconds: 3.0,
      );
      final env = _envelope(out, fromSecond: 2.0, window: _window60Hz);
      final maxEnv = env.reduce(math.max);
      final minEnv = env.reduce(math.min);
      // 60 Hz sits in the unmodulated low band; only the small residual from
      // the band-split skirts may wobble the envelope.
      expect(maxEnv / math.max(minEnv, 1e-9), lessThan(1.15));
    });

    test('ramps the depth in from silence', () {
      final am = AmModulator(
        _sampleRate.toDouble(),
        rateHz: 16.0,
        rampSeconds: 2.0,
      );
      final out = _modulatedSine(
        am,
        frequencyHz: 500.0,
        depth: 0.4,
        seconds: 3.0,
      );
      double swing(List<double> env) =>
          env.reduce(math.max) / math.max(env.reduce(math.min), 1e-9);
      final early = _envelope(
        out,
        fromSecond: 0.0,
        window: _window500Hz,
      ).take((0.3 * _sampleRate / _window500Hz).round()).toList();
      final late = _envelope(out, fromSecond: 2.5, window: _window500Hz);
      expect(
        swing(early),
        lessThan(1.1),
        reason: 'modulation must start imperceptible',
      );
      expect(
        swing(late),
        greaterThan(1.2),
        reason: 'modulation must reach its target',
      );
    });
  });
}
