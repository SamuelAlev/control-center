import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/lfo.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/soundscape_voice.dart';

/// The grounding layer: a bass sine an octave below the pad root, swelling
/// very slowly.
///
/// Low register reads as calm (relaxation is inversely linear with
/// frequency) and a steady sub keeps the mix anchored while everything above
/// it drifts. Sleep mode adds a quiet fifth for a little warmth. Rendered
/// dead-center (mono) so it never wobbles the stereo image and kept out of
/// the reverb so the low end stays clean.
///
/// When the harmony's root voice walks, the composer calls [retune] and the
/// drone equal-power crossfades to the new fundamental over several seconds
/// (bank A sounding, bank B incoming — the same trick as the pad), so the
/// ground moves with the chord without a single discrete event.
class SubDrone implements SoundscapeVoice {
  /// Creates a drone at [frequencyHz]; [fifthGain] adds a perfect fifth at
  /// that relative level. [swellHz]/[swellDepth] shape the slow breath;
  /// [crossfadeSeconds] is the [retune] glide.
  SubDrone(
    double sampleRate,
    SeededPrng prng, {
    required double frequencyHz,
    double fifthGain = 0.0,
    double swellHz = 0.03,
    double swellDepth = 0.15,
    double crossfadeSeconds = 5.0,
  }) : _sampleRate = sampleRate,
       _incRootA = frequencyHz / sampleRate,
       _incFifthA = frequencyHz * 1.5 / sampleRate,
       _fifthGain = fifthGain.clamp(0.0, 1.0),
       _norm = 1.0 / (1.0 + fifthGain.clamp(0.0, 1.0)),
       _swellDepth = swellDepth.clamp(0.0, 1.0),
       _crossfadeSamples = math.max(1, (crossfadeSeconds * sampleRate).round()),
       _swell = Lfo(sampleRate, swellHz, phase: prng.nextDouble()),
       _phaseRootA = prng.nextDouble(),
       _phaseFifthA = prng.nextDouble();

  static const double _twoPi = 2 * math.pi;

  final double _sampleRate;
  final double _fifthGain;
  final double _norm;
  final double _swellDepth;
  final int _crossfadeSamples;
  final Lfo _swell;

  double _incRootA;
  double _incFifthA;
  double _phaseRootA;
  double _phaseFifthA;

  double _incRootB = 0.0;
  double _incFifthB = 0.0;
  double _phaseRootB = 0.0;
  double _phaseFifthB = 0.0;

  bool _fading = false;
  int _fadeDelay = 0;
  int _fadePos = 0;

  /// Starts an equal-power crossfade to [frequencyHz], beginning
  /// [offsetFrames] into the next rendered block. A retune during a fade
  /// completes the old fade instantly (defensive; the harmony walk moves far
  /// slower than the fade).
  void retune(double frequencyHz, {int offsetFrames = 0}) {
    if (_fading) {
      _swapBanks();
    }
    _phaseRootB = _phaseRootA;
    _phaseFifthB = _phaseFifthA;
    _incRootB = frequencyHz / _sampleRate;
    _incFifthB = frequencyHz * 1.5 / _sampleRate;
    _fading = true;
    _fadeDelay = math.max(0, offsetFrames);
    _fadePos = 0;
  }

  void _swapBanks() {
    _phaseRootA = _phaseRootB;
    _phaseFifthA = _phaseFifthB;
    _incRootA = _incRootB;
    _incFifthA = _incFifthB;
    _fading = false;
  }

  double _bank(bool a) {
    final phaseRoot = a ? _phaseRootA : _phaseRootB;
    var sample = math.sin(_twoPi * phaseRoot);
    if (_fifthGain > 0.0) {
      final phaseFifth = a ? _phaseFifthA : _phaseFifthB;
      sample += _fifthGain * math.sin(_twoPi * phaseFifth);
    }
    return sample;
  }

  void _advance(bool a) {
    if (a) {
      _phaseRootA += _incRootA;
      if (_phaseRootA >= 1.0) {
        _phaseRootA -= 1.0;
      }
      _phaseFifthA += _incFifthA;
      if (_phaseFifthA >= 1.0) {
        _phaseFifthA -= 1.0;
      }
    } else {
      _phaseRootB += _incRootB;
      if (_phaseRootB >= 1.0) {
        _phaseRootB -= 1.0;
      }
      _phaseFifthB += _incFifthB;
      if (_phaseFifthB >= 1.0) {
        _phaseFifthB -= 1.0;
      }
    }
  }

  @override
  void renderAdd(Float32List outStereo, int frames, double gain) {
    for (var i = 0; i < frames; i++) {
      double sample;
      if (_fading && _fadeDelay <= 0) {
        final x = _fadePos / _crossfadeSamples;
        sample =
            _bank(true) * math.cos(0.5 * math.pi * x) +
            _bank(false) * math.sin(0.5 * math.pi * x);
        _advance(true);
        _advance(false);
        _fadePos++;
        if (_fadePos >= _crossfadeSamples) {
          _swapBanks();
        }
      } else {
        if (_fading) {
          _fadeDelay--;
        }
        sample = _bank(true);
        _advance(true);
      }

      final amp = 1.0 - _swellDepth * (0.5 - 0.5 * _swell.next());
      final out = sample * _norm * amp * gain;
      outStereo[2 * i] += out;
      outStereo[2 * i + 1] += out;
    }
  }
}
