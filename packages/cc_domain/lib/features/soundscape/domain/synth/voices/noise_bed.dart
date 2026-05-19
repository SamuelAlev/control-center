import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';
import 'package:cc_domain/features/soundscape/domain/synth/lfo.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/soundscape_voice.dart';

/// The ambient noise floor of a soundscape (wind, rain, hiss, rumble).
///
/// White noise from a [SeededPrng] is coloured toward pink (Paul Kellet's
/// full 7-state filter, accurate to ±0.05 dB — pink's −3 dB/octave tilt
/// matches loudness perception and masks speech without brightness) or brown
/// (a leaky integrator, −6 dB/octave, darker still for sleep) by a `color`
/// parameter in `[0, 1]`, then shaped by a per-space low-pass. The two
/// spaces draw independent noise streams so the bed is stereo-decorrelated.
///
/// The bed is never static: two seeded [DriftLfo]s wander its gain (a couple
/// of dB, "gusts") and its cutoff (fractions of an octave) on incommensurate
/// multi-second periods — slow 1/f-style drift, never periodic pulsing and
/// never anywhere near the 30–150 Hz roughness band.
class NoiseBed implements SoundscapeVoice {
  /// Creates a noise bed.
  ///
  /// [color] blends pink (0) toward brown (1); [cutoffHz] is the initial
  /// low-pass corner; [q] its resonance; [gustDepthDb] the peak gain wander.
  NoiseBed(
    SeededPrng prng,
    double sampleRate, {
    double color = 0.0,
    double cutoffHz = 8000.0,
    double q = 0.707,
    double gustDepthDb = 1.5,
  }) : _prng = prng,
       _sampleRate = sampleRate,
       _q = q,
       _color = color.clamp(0.0, 1.0),
       _baseCutoffHz = cutoffHz,
       _gustDepthDb = gustDepthDb.clamp(0.0, 6.0),
       _lpL = Biquad.lowPass(sampleRate, cutoffHz, q),
       _lpR = Biquad.lowPass(sampleRate, cutoffHz, q),
       _gainDrift = DriftLfo(sampleRate, prng, periodSeconds: 13.0),
       _cutoffDrift = DriftLfo(sampleRate, prng, periodSeconds: 19.0);

  static const double _pinkScale = 0.11;
  static const double _brownScale = 3.4;

  /// Peak cutoff wander in octaves.
  static const double _cutoffDriftOctaves = 0.3;

  final SeededPrng _prng;
  final double _sampleRate;
  final double _q;
  final Biquad _lpL;
  final Biquad _lpR;
  final DriftLfo _gainDrift;
  final DriftLfo _cutoffDrift;

  double _color;
  double _baseCutoffHz;
  double _gustDepthDb;

  // Paul Kellet 7-state pink-filter state (per space).
  final Float64List _pinkL = Float64List(7);
  final Float64List _pinkR = Float64List(7);

  // Leaky-integrator brown-noise state (per space).
  double _brownL = 0.0;
  double _brownR = 0.0;

  /// The unclamped sample rate this bed renders at.
  double get sampleRate => _sampleRate;

  /// Sets the pink/brown blend, `color` in `[0, 1]`.
  void setColor(double color) => _color = color.clamp(0.0, 1.0);

  /// Sets the low-pass corner the gust drift wanders around.
  void setCutoff(double cutoffHz) => _baseCutoffHz = cutoffHz;

  /// Sets the peak gain wander in dB (0 freezes the gusts).
  void setGustDepth(double depthDb) => _gustDepthDb = depthDb.clamp(0.0, 6.0);

  double _pink(Float64List s, double white) {
    s[0] = 0.99886 * s[0] + white * 0.0555179;
    s[1] = 0.99332 * s[1] + white * 0.0750759;
    s[2] = 0.96900 * s[2] + white * 0.1538520;
    s[3] = 0.86650 * s[3] + white * 0.3104856;
    s[4] = 0.55000 * s[4] + white * 0.5329522;
    s[5] = -0.7616 * s[5] - white * 0.0168980;
    final pink =
        (s[0] + s[1] + s[2] + s[3] + s[4] + s[5] + s[6] + white * 0.5362) *
        _pinkScale;
    s[6] = white * 0.115926;
    return pink;
  }

  @override
  void renderAdd(Float32List outStereo, int frames, double gain) {
    // Gusts: advance both drift lanes once per block and apply at block rate
    // — the drifts move over many seconds, so per-block steps are far below
    // audibility.
    final gustGain = math
        .pow(10.0, _gainDrift.next(frames) * _gustDepthDb / 20.0)
        .toDouble();
    final cutoff =
        (_baseCutoffHz *
                math.pow(2.0, _cutoffDrift.next(frames) * _cutoffDriftOctaves))
            .clamp(100.0, 16000.0)
            .toDouble();
    _lpL.setLowPass(cutoff, _q);
    _lpR.setLowPass(cutoff, _q);

    final color = _color;
    final g = gain * gustGain;
    for (var i = 0; i < frames; i++) {
      // Left space.
      final whiteL = _prng.nextRange(-1.0, 1.0);
      final pinkL = _pink(_pinkL, whiteL);
      _brownL = (_brownL + 0.02 * whiteL) / 1.02;
      final colouredL = _lpL.process(
        pinkL * (1.0 - color) + _brownL * _brownScale * color,
      );
      outStereo[2 * i] += colouredL * g;

      // Right space (independent noise stream).
      final whiteR = _prng.nextRange(-1.0, 1.0);
      final pinkR = _pink(_pinkR, whiteR);
      _brownR = (_brownR + 0.02 * whiteR) / 1.02;
      final colouredR = _lpR.process(
        pinkR * (1.0 - color) + _brownR * _brownScale * color,
      );
      outStereo[2 * i + 1] += colouredR * g;
    }
  }
}
