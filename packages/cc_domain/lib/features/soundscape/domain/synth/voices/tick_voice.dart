import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/soundscape_voice.dart';

/// One sounding tick within a [TickVoice] pool.
class _Tick {
  int delay = 0;
  int attackPos = 0;
  int attackSamples = 1;
  double amp = 0.0;
  double decay = 0.0;
  double velocity = 0.0;
  double gainL = 0.0;
  double gainR = 0.0;
  bool active = false;
}

/// The closed-hat analogue: short gated bursts of band-shaped noise.
///
/// A tonal ping at hat register reads as an alarm bell — percussion up there
/// must be NOISE. This voice runs a continuous seeded white-noise pair
/// (independent per channel, drawn every sample whether or not a tick is
/// sounding, so renders stay block-size independent), shapes it into the
/// 4.5–9.5 kHz band and opens a short raised-cosine/exponential envelope on
/// each [noteOn]. The result is a quiet "tss", not a pitch — matching the
/// hat/shaker content measured in the reference energy tracks.
class TickVoice implements SoundscapeVoice {
  /// Creates a tick voice at [sampleRate], band-shaped between [highPassHz]
  /// and [lowPassHz].
  TickVoice(
    SeededPrng prng,
    double sampleRate, {
    double highPassHz = 4500.0,
    double lowPassHz = 9500.0,
    int maxTicks = 4,
  }) : _prng = prng,
       _sampleRate = sampleRate,
       _hpL = Biquad.highPass(sampleRate, highPassHz, 0.707),
       _hpR = Biquad.highPass(sampleRate, highPassHz, 0.707),
       _lpL = Biquad.lowPass(sampleRate, lowPassHz, 0.707),
       _lpR = Biquad.lowPass(sampleRate, lowPassHz, 0.707),
       _ticks = List<_Tick>.generate(math.max(1, maxTicks), (_) => _Tick());

  final SeededPrng _prng;
  final double _sampleRate;
  final Biquad _hpL;
  final Biquad _hpR;
  final Biquad _lpL;
  final Biquad _lpR;
  final List<_Tick> _ticks;

  /// Starts a tick (stealing the quietest slot if the pool is full).
  void noteOn({
    required double velocity,
    required double pan,
    double attackSeconds = 0.0015,
    double releaseSeconds = 0.05,
    int offsetFrames = 0,
  }) {
    var target = _ticks[0];
    for (final tick in _ticks) {
      if (!tick.active) {
        target = tick;
        break;
      }
      if (tick.amp * tick.velocity < target.amp * target.velocity) {
        target = tick;
      }
    }

    final angle = (pan.clamp(-1.0, 1.0) + 1.0) * 0.25 * math.pi;
    target
      ..delay = math.max(0, offsetFrames)
      ..attackPos = 0
      ..attackSamples = math.max(
        1,
        (attackSeconds.clamp(0.0005, 0.05) * _sampleRate).round(),
      )
      ..amp = 1.0
      ..decay = math.exp(-1.0 / (releaseSeconds.clamp(0.01, 1.0) * _sampleRate))
      ..velocity = velocity.clamp(0.0, 1.0)
      ..gainL = math.cos(angle)
      ..gainR = math.sin(angle)
      ..active = true;
  }

  @override
  void renderAdd(Float32List outStereo, int frames, double gain) {
    for (var i = 0; i < frames; i++) {
      // Noise streams advance unconditionally: the draw schedule (and hence
      // every later sample) is independent of tick activity and block size.
      final whiteL = _prng.nextRange(-1.0, 1.0);
      final whiteR = _prng.nextRange(-1.0, 1.0);

      var envL = 0.0;
      var envR = 0.0;
      for (final tick in _ticks) {
        if (!tick.active) {
          continue;
        }
        if (tick.delay > 0) {
          tick.delay--;
          continue;
        }
        double env;
        if (tick.attackPos < tick.attackSamples) {
          env =
              0.5 -
              0.5 * math.cos(math.pi * tick.attackPos / tick.attackSamples);
          tick.attackPos++;
        } else {
          tick.amp *= tick.decay;
          env = tick.amp;
          if (tick.amp < 1e-3) {
            tick.active = false;
          }
        }
        envL += env * tick.velocity * tick.gainL;
        envR += env * tick.velocity * tick.gainR;
      }

      final shapedL = _lpL.process(_hpL.process(whiteL));
      final shapedR = _lpR.process(_hpR.process(whiteR));
      outStereo[2 * i] += shapedL * envL * gain;
      outStereo[2 * i + 1] += shapedR * envR * gain;
    }
  }
}
