import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';

/// A raised-cosine gain `g(t) = 1 − d/2 + (d/2)·cos(2πf·t)` (so gain stays in
/// `[1−d, 1]`) is applied to ONLY the 200 Hz–1 kHz band of the sustained
/// stems — the exact window of the peer-reviewed study (Woods et al.,
/// Communications Biology 2024), which keeps the pulse warm and out of both
/// the sub and the bright top. The band split is subtraction-exact
/// (`low + mid + high == input` at unity), both channels share one modulator
/// phase (this is NOT binaural — identical envelopes in both ears entrain far
/// more strongly) and the rate is an integer multiple of the mood's beat so
/// it reads as musical tremolo. Depth ramps in from silence over the first
/// ~90 s of a session so the modulation never *starts* — it surfaces.
///
/// Rates per mood: focus 16 Hz (beta, the validated sweet spot), relax 10 Hz
/// (alpha), sleep 0.8 Hz (the slow-oscillation stimulation rate). All far
/// outside the 30–150 Hz roughness band.
class AmModulator {
  /// Creates a modulator at [rateHz] for [sampleRate], ramping depth in over
  /// [rampSeconds].
  AmModulator(
    double sampleRate, {
    required double rateHz,
    double rampSeconds = 90.0,
  }) : _phaseInc = rateHz / sampleRate,
       _rampSamples = math.max(1, (rampSeconds * sampleRate).round()),
       _lowL = Biquad.lowPass(sampleRate, _lowSplitHz, _splitQ),
       _lowR = Biquad.lowPass(sampleRate, _lowSplitHz, _splitQ),
       _midL = Biquad.lowPass(sampleRate, _highSplitHz, _splitQ),
       _midR = Biquad.lowPass(sampleRate, _highSplitHz, _splitQ);

  /// Band edges of the modulated window (Woods et al. 2024).
  static const double _lowSplitHz = 200.0;
  static const double _highSplitHz = 1000.0;
  static const double _splitQ = 0.707;

  static const double _twoPi = 2 * math.pi;

  final double _phaseInc;
  final int _rampSamples;
  final Biquad _lowL;
  final Biquad _lowR;
  final Biquad _midL;
  final Biquad _midR;

  double _phase = 0.0;
  int _samplesDone = 0;

  /// Modulates [stereo] in place. [depth] is the current (already ramped)
  /// target depth in `[0, 1]`; the session ramp-in is applied on top.
  void processInPlace(Float32List stereo, int frames, double depth) {
    final d = depth.clamp(0.0, 0.9);
    for (var i = 0; i < frames; i++) {
      final ramp = _samplesDone < _rampSamples
          ? _samplesDone / _rampSamples
          : 1.0;
      _samplesDone++;
      final effective = d * ramp;
      final g =
          1.0 - effective * 0.5 + effective * 0.5 * math.cos(_twoPi * _phase);
      _phase += _phaseInc;
      if (_phase >= 1.0) {
        _phase -= 1.0;
      }

      final xL = stereo[2 * i].toDouble();
      final lowL = _lowL.process(xL);
      final midAllL = _midL.process(xL);
      stereo[2 * i] = lowL + g * (midAllL - lowL) + (xL - midAllL);

      final xR = stereo[2 * i + 1].toDouble();
      final lowR = _lowR.process(xR);
      final midAllR = _midR.process(xR);
      stereo[2 * i + 1] = lowR + g * (midAllR - lowR) + (xR - midAllR);
    }
  }
}
