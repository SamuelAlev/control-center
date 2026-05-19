import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/soundscape_voice.dart';

/// One sounding motif note within a [MotifVoice] pool.
class _MotifNote {
  double phase = 0.0;
  double inc = 0.0;
  int delay = 0;
  int attackPos = 0;
  int attackSamples = 1;
  double amp = 0.0;
  double ampDecay = 0.0;
  double velocity = 0.0;
  double gainL = 0.0;
  double gainR = 0.0;
  double vibratoPhase = 0.0;
  int age = 0;
  bool active = false;
}

/// Soft melodic notes — the anti-salience replacement for the FM bells.
///
/// Each note is a short harmonic series (`partialGains`, default steeply
/// weighted toward the fundamental) under a raised-cosine attack and an
/// exponential release, low-passed as a stem so no bright transient ever
/// appears. The default recipe is a bloom, not a ping; a longer partial list
/// with a quick-but-soft attack gives the plucked, piano-like presence of
/// sampled-instrument functional music while staying inside the salience
/// budget (no sub-10 ms attacks, no inharmonic clang, stem low-passed).
/// Notes are panned per event and may start mid-block (`offsetFrames`) so
/// scheduling stays sample-exact.
class MotifVoice implements SoundscapeVoice {
  /// Creates a motif voice at [sampleRate] with a stem low-pass at [cutoffHz]
  /// and the harmonic recipe [partialGains] (gains for 1f, 2f, …).
  MotifVoice(
    double sampleRate, {
    int maxVoices = 8,
    double cutoffHz = 2200.0,
    double q = 0.6,
    List<double> partialGains = const <double>[1.0, 0.32, 0.10],
    double vibratoRateHz = 0.0,
    double vibratoCents = 0.0,
  }) : _sampleRate = sampleRate,
       _partialGains = List<double>.unmodifiable(partialGains),
       _norm = 1.0 / partialGains.fold<double>(0.0, (sum, g) => sum + g.abs()),
       _vibratoInc =
           vibratoRateHz.clamp(0.0, 12.0) /
           sampleRate, // Small-angle pitch mod: 2^(c/1200) - 1 ≈ c·ln2/1200 for the few
       // cents of a musical vibrato.
       _vibratoK = vibratoCents.clamp(0.0, 25.0) * math.ln2 / 1200.0,
       _vibratoDelaySamples = (0.25 * sampleRate).round(),
       _vibratoFadeSamples = math.max(1, (0.55 * sampleRate).round()),
       _lpL = Biquad.lowPass(sampleRate, cutoffHz, q),
       _lpR = Biquad.lowPass(sampleRate, cutoffHz, q),
       _notes = List<_MotifNote>.generate(
         math.max(1, maxVoices),
         (_) => _MotifNote(),
       ) {
    if (partialGains.isEmpty) {
      throw ArgumentError('motif voice needs partials');
    }
  }

  static const double _twoPi = 2 * math.pi;

  final double _sampleRate;
  final List<double> _partialGains;
  final double _norm;

  /// Vibrato: singing pitch motion for wind colors. It fades in ~a quarter
  /// second after the onset (the way a player adds it) and the depth stays
  /// in single-digit cents — expression, never a warble.
  final double _vibratoInc;
  final double _vibratoK;
  final int _vibratoDelaySamples;
  final int _vibratoFadeSamples;

  final Biquad _lpL;
  final Biquad _lpR;
  final List<_MotifNote> _notes;

  /// Starts a note (stealing the quietest voice if the pool is full).
  ///
  /// [attackSeconds] is the raised-cosine rise, [releaseSeconds] the
  /// exponential decay time constant; [offsetFrames] delays the onset within
  /// the next rendered block.
  void noteOn({
    required double frequencyHz,
    required double velocity,
    required double pan,
    required double attackSeconds,
    required double releaseSeconds,
    int offsetFrames = 0,
  }) {
    var target = _notes[0];
    for (final note in _notes) {
      if (!note.active) {
        target = note;
        break;
      }
      if (note.amp * note.velocity < target.amp * target.velocity) {
        target = note;
      }
    }

    final angle = (pan.clamp(-1.0, 1.0) + 1.0) * 0.25 * math.pi;
    target
      ..phase = 0.0
      ..inc = frequencyHz / _sampleRate
      ..delay = math.max(0, offsetFrames)
      ..attackPos = 0
      ..attackSamples = math.max(
        1,
        (attackSeconds.clamp(0.004, 8.0) * _sampleRate).round(),
      )
      ..amp = 1.0
      ..ampDecay = math.exp(
        -1.0 / (releaseSeconds.clamp(0.2, 20.0) * _sampleRate),
      )
      ..velocity = velocity.clamp(0.0, 1.0)
      ..gainL = math.cos(angle)
      ..gainR = math.sin(angle)
      ..vibratoPhase = 0.0
      ..age = 0
      ..active = true;
  }

  /// Retunes the stem low-pass corner (the composer drives this with the
  /// tune's energy/brightness so plucks open up as the mix gets driving).
  void setCutoff(double cutoffHz, {double q = 0.6}) {
    _lpL.setLowPass(cutoffHz, q);
    _lpR.setLowPass(cutoffHz, q);
  }

  @override
  void renderAdd(Float32List outStereo, int frames, double gain) {
    final partials = _partialGains.length;
    for (var i = 0; i < frames; i++) {
      var left = 0.0;
      var right = 0.0;
      for (final note in _notes) {
        if (!note.active) {
          continue;
        }
        if (note.delay > 0) {
          note.delay--;
          continue;
        }

        double env;
        if (note.attackPos < note.attackSamples) {
          env =
              0.5 -
              0.5 * math.cos(math.pi * note.attackPos / note.attackSamples);
          note.attackPos++;
        } else {
          note.amp *= note.ampDecay;
          env = note.amp;
          if (note.amp < 1e-4) {
            note.active = false;
          }
        }

        // Harmonic series off one phase accumulator: sin(2π·k·φ) is
        // continuous across the [0, 1) wrap, so partials stay locked.
        var sum = 0.0;
        for (var k = 0; k < partials; k++) {
          sum += _partialGains[k] * math.sin(_twoPi * (k + 1) * note.phase);
        }
        final sample = sum * _norm * env * note.velocity;
        left += sample * note.gainL;
        right += sample * note.gainR;

        var inc = note.inc;
        if (_vibratoK > 0.0) {
          final ramp = note.age <= _vibratoDelaySamples
              ? 0.0
              : math.min(
                  1.0,
                  (note.age - _vibratoDelaySamples) / _vibratoFadeSamples,
                );
          if (ramp > 0.0) {
            inc *=
                1.0 + _vibratoK * ramp * math.sin(_twoPi * note.vibratoPhase);
          }
          note.vibratoPhase += _vibratoInc;
          if (note.vibratoPhase >= 1.0) {
            note.vibratoPhase -= 1.0;
          }
        }
        note.age++;
        note.phase += inc;
        if (note.phase >= 1.0) {
          note.phase -= 1.0;
        }
      }

      outStereo[2 * i] += _lpL.process(left) * gain;
      outStereo[2 * i + 1] += _lpR.process(right) * gain;
    }
  }
}
