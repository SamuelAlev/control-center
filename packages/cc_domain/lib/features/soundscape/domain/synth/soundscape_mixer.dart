import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/reverb.dart';

/// The master bus of a soundscape: shared plate reverb, DC blocker, session
/// fade-in, and a soft-clip safety.
///
/// The composer sums its stems into a dry buffer and a separate reverb-send
/// buffer (so the tail is built from the *unmodulated* stems and never
/// pumps); the mixer adds the wet plate on top, removes any DC the synthesis
/// chain accumulated, fades the whole mix in over the first two seconds of a
/// session (a stream must surface, never start), and finally runs a `tanh`
/// soft-clip so no sample leaves `[-1, 1]`. The limiter is near-linear at low
/// level, so the quiet ambient body is untouched.
class SoundscapeMixer {
  /// Creates a mixer with its own reverb for the given [sampleRate].
  SoundscapeMixer(double sampleRate)
    : _reverb = Reverb(sampleRate),
      _fadeInSamples = math.max(1, (_fadeInSeconds * sampleRate).round()),
      _dcR = 1.0 - 2.0 * math.pi * _dcCornerHz / sampleRate;

  /// Session fade-in length.
  static const double _fadeInSeconds = 2.0;

  /// DC-blocker corner frequency.
  static const double _dcCornerHz = 5.0;

  final Reverb _reverb;
  final int _fadeInSamples;
  final double _dcR;

  double _wet = 0.3;
  int _samplesDone = 0;

  double _dcX1L = 0.0;
  double _dcY1L = 0.0;
  double _dcX1R = 0.0;
  double _dcY1R = 0.0;

  /// Sets the reverb wet mix, [wet] in `[0, 1]`.
  void setReverbWet(double wet) => _wet = wet.clamp(0.0, 1.0);

  /// Sets the reverb tail length, [decay] in `[0, 1]`.
  void setReverbDecay(double decay) => _reverb.setDecay(decay);

  /// Sets the reverb high-frequency damping, [damp] in `[0, 1]`.
  void setReverbDamp(double damp) => _reverb.setDamp(damp);

  /// Sets the reverb pre-delay in milliseconds.
  void setPreDelayMs(double ms) => _reverb.setPreDelayMs(ms);

  /// Sets the wet high-pass corner in Hz (keeps the tail out of the mud).
  void setWetHighPassHz(double hz) => _reverb.setWetHighPassHz(hz);

  /// Adds the reverberated [reverbSend] onto [stereo], then applies the DC
  /// blocker, session fade-in, and limiter in place. After this call every
  /// sample is finite and within `[-1, 1]`.
  void masterProcess(Float32List stereo, Float32List reverbSend, int frames) {
    _reverb.processAdd(reverbSend, stereo, frames, _wet);

    for (var i = 0; i < frames; i++) {
      var l = stereo[2 * i].toDouble();
      var r = stereo[2 * i + 1].toDouble();

      // DC blocker: y[n] = x[n] - x[n-1] + R*y[n-1].
      final yL = l - _dcX1L + _dcR * _dcY1L;
      _dcX1L = l;
      _dcY1L = yL;
      l = yL;
      final yR = r - _dcX1R + _dcR * _dcY1R;
      _dcX1R = r;
      _dcY1R = yR;
      r = yR;

      if (_samplesDone < _fadeInSamples) {
        final fade =
            0.5 - 0.5 * math.cos(math.pi * _samplesDone / _fadeInSamples);
        l *= fade;
        r *= fade;
        _samplesDone++;
      }

      stereo[2 * i] = _softClip(l);
      stereo[2 * i + 1] = _softClip(r);
    }
  }

  /// A bounded `tanh` soft-clip. Output is strictly within `[-1, 1]`.
  static double _softClip(double x) {
    if (x > 15.0) {
      return 1.0;
    }
    if (x < -15.0) {
      return -1.0;
    }
    final e2 = math.exp(2.0 * x);
    return (e2 - 1.0) / (e2 + 1.0);
  }
}
