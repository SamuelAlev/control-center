import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';
import 'package:cc_domain/features/soundscape/domain/synth/lfo.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:cc_domain/features/soundscape/domain/synth/voices/soundscape_voice.dart';

/// One chord tone of the pad: a 3-osc detuned unison that can equal-power
/// crossfade to a new frequency (bank A = sounding, bank B = incoming).
class _PadNote {
  _PadNote(int oscCount)
    : phasesA = Float64List(oscCount),
      incsA = Float64List(oscCount),
      phasesB = Float64List(oscCount),
      incsB = Float64List(oscCount),
      panLs = Float64List(oscCount),
      panRs = Float64List(oscCount);

  final Float64List phasesA;
  final Float64List incsA;
  final Float64List phasesB;
  final Float64List incsB;

  /// Per-oscillator equal-power pan gains (the unison fans out around the
  /// note's stereo position, decorrelating the channels).
  final Float64List panLs;
  final Float64List panRs;

  bool fading = false;
  int fadeDelay = 0;
  int fadePos = 0;
  int fadeLen = 1;

  /// Per-block interpolated wander gain.
  double gainNow = 1.0;
  double gainStep = 0.0;
}

/// The slow, breathing, harmonically mobile pad — the tonal body of a
/// soundscape.
///
/// Each chord tone is a three-oscillator detuned unison, panned across
/// the stereo field. Each oscillator renders a short harmonic series
/// (`partialGains`, default a pure sine) under the stem low-pass, so a chord
/// tone can read as a rich voice — a ladder of harmonics on the spectrogram —
/// instead of a single spectral line. Harmony never changes as a block chord: the composer
/// retunes ONE note at a time ([retuneVoice]) and the note equal-power
/// crossfades from its old pitch to the new one over many seconds — the
/// "entirely diatonic meandering" that keeps ambient harmony alive without a
/// single discrete event. On top, every note's gain wanders a couple of dB on
/// its own incommensurate-period [DriftLfo] (the myNoise "Animate" trick), a
/// very slow breathing LFO swells the whole pad and a per-channel low-pass
/// sets the (glidable) brightness.
class PadVoice implements SoundscapeVoice {
  /// Creates a pad playing [initialFrequencies].
  ///
  /// [detuneCents] is the unison spread (kept small so beating stays slow and
  /// pleasant); [crossfadeSeconds] is the retune glide; [spread] the stereo
  /// width; [breathDepth]/[breathHz] the whole-pad swell.
  PadVoice(
    double sampleRate,
    SeededPrng prng, {
    required List<double> initialFrequencies,
    double detuneCents = 6.0,
    double cutoffHz = 1200.0,
    double q = 0.6,
    double spread = 0.6,
    double breathDepth = 0.1,
    double breathHz = 0.05,
    double crossfadeSeconds = 10.0,
    List<double> partialGains = const <double>[1.0],
    double innerSpread = 0.0,
  }) : _sampleRate = sampleRate,
       _noteCount = initialFrequencies.length,
       _breathDepth = breathDepth.clamp(0.0, 1.0),
       _crossfadeSamples = math.max(1, (crossfadeSeconds * sampleRate).round()),
       _partialGains = List<double>.unmodifiable(partialGains),
       _partialNorm =
           1.0 / partialGains.fold<double>(0.0, (sum, g) => sum + g.abs()),
       _lpL = Biquad.lowPass(sampleRate, cutoffHz, q),
       _lpR = Biquad.lowPass(sampleRate, cutoffHz, q),
       _breath = Lfo(sampleRate, breathHz, phase: prng.nextDouble()) {
    if (initialFrequencies.isEmpty) {
      throw ArgumentError('pad needs at least one note');
    }
    if (partialGains.isEmpty) {
      throw ArgumentError('pad needs at least one partial');
    }
    final detuneRatio = math.pow(2.0, detuneCents / 1200.0).toDouble();
    _unisonOffsets = <double>[1.0 / detuneRatio, 1.0, detuneRatio];

    _notes = List<_PadNote>.generate(
      _noteCount,
      (_) => _PadNote(_unisonOffsets.length),
    );
    for (var n = 0; n < _noteCount; n++) {
      final note = _notes[n];
      for (var u = 0; u < _unisonOffsets.length; u++) {
        note.phasesA[u] = prng.nextDouble();
        note.incsA[u] = initialFrequencies[n] * _unisonOffsets[u] / sampleRate;
      }
      // Equal-power pan spread across the stereo field, with the detuned
      // unison fanned out around each note's position (flat osc left, center
      // osc in place, sharp osc right) — different frequencies per channel
      // decorrelate left from right, which is where ambience width lives.
      final position = _noteCount == 1
          ? 0.0
          : ((n / (_noteCount - 1)) - 0.5) * 2.0 * spread;
      for (var u = 0; u < _unisonOffsets.length; u++) {
        final fan = _unisonOffsets.length == 1
            ? 0.0
            : ((u / (_unisonOffsets.length - 1)) - 0.5) *
                  2.0 *
                  innerSpread.clamp(0.0, 1.0);
        final angle =
            ((position + fan).clamp(-1.0, 1.0) + 1.0) * 0.25 * math.pi;
        note.panLs[u] = math.cos(angle);
        note.panRs[u] = math.sin(angle);
      }
    }

    // One wander lane per note at staggered, incommensurate periods so the
    // pad's internal balance never repeats.
    const wanderPeriods = <double>[29.0, 47.0, 61.0, 83.0, 103.0, 127.0];
    _wander = List<DriftLfo>.generate(
      _noteCount,
      (n) => DriftLfo(
        sampleRate,
        prng,
        periodSeconds: wanderPeriods[n % wanderPeriods.length],
      ),
    );
  }

  /// Gain wander depth in dB (peak deviation).
  static const double _wanderDb = 1.25;

  static const double _twoPi = 2 * math.pi;

  final double _sampleRate;
  final int _noteCount;
  final double _breathDepth;
  final int _crossfadeSamples;
  final List<double> _partialGains;
  final double _partialNorm;
  final Biquad _lpL;
  final Biquad _lpR;
  final Lfo _breath;

  late final List<double> _unisonOffsets;
  late final List<_PadNote> _notes;
  late final List<DriftLfo> _wander;

  /// The number of chord tones this pad renders.
  int get noteCount => _noteCount;

  /// One oscillator's output at [phase]: the configured harmonic series.
  /// `sin(2π·k·φ)` is continuous across the `[0, 1)` phase wrap, so partials
  /// share the fundamental's phase accumulator.
  double _oscillate(double phase) {
    var sum = 0.0;
    for (var k = 0; k < _partialGains.length; k++) {
      sum += _partialGains[k] * math.sin(_twoPi * (k + 1) * phase);
    }
    return sum * _partialNorm;
  }

  /// Starts an equal-power crossfade of note [voice] to [frequencyHz],
  /// beginning [offsetFrames] into the next rendered block.
  void retuneVoice(int voice, double frequencyHz, {int offsetFrames = 0}) {
    if (voice < 0 || voice >= _noteCount) {
      return;
    }
    final note = _notes[voice];
    if (note.fading) {
      // Defensive: a retune during a fade completes the old fade instantly.
      _swapBanks(note);
    }
    for (var u = 0; u < _unisonOffsets.length; u++) {
      note.phasesB[u] = note.phasesA[u];
      note.incsB[u] = frequencyHz * _unisonOffsets[u] / _sampleRate;
    }
    note
      ..fading = true
      ..fadeDelay = math.max(0, offsetFrames)
      ..fadePos = 0
      ..fadeLen = _crossfadeSamples;
  }

  void _swapBanks(_PadNote note) {
    for (var u = 0; u < _unisonOffsets.length; u++) {
      note.phasesA[u] = note.phasesB[u];
      note.incsA[u] = note.incsB[u];
    }
    note.fading = false;
  }

  /// Retunes the per-channel low-pass corner to [cutoffHz] with [q].
  void setCutoff(double cutoffHz, {double q = 0.6}) {
    _lpL.setLowPass(cutoffHz, q);
    _lpR.setLowPass(cutoffHz, q);
  }

  @override
  void renderAdd(Float32List outStereo, int frames, double gain) {
    // Advance each note's wander lane once per block and spread the gain
    // change linearly across the block so it never steps.
    for (var n = 0; n < _noteCount; n++) {
      final target = math
          .pow(10.0, _wander[n].next(frames) * _wanderDb / 20.0)
          .toDouble();
      _notes[n].gainStep = (target - _notes[n].gainNow) / frames;
    }

    final norm = 1.0 / (_noteCount * _unisonOffsets.length);
    for (var i = 0; i < frames; i++) {
      var accL = 0.0;
      var accR = 0.0;
      for (var n = 0; n < _noteCount; n++) {
        final note = _notes[n];
        note.gainNow += note.gainStep;

        double fadeA = 1.0;
        double fadeB = 0.0;
        var advanceB = false;
        if (note.fading && note.fadeDelay <= 0) {
          final x = note.fadePos / note.fadeLen;
          fadeA = math.cos(0.5 * math.pi * x);
          fadeB = math.sin(0.5 * math.pi * x);
          advanceB = true;
          note.fadePos++;
        } else if (note.fading) {
          note.fadeDelay--;
        }

        for (var u = 0; u < 3; u++) {
          var sample = fadeA * _oscillate(note.phasesA[u]);
          note.phasesA[u] += note.incsA[u];
          if (note.phasesA[u] >= 1.0) {
            note.phasesA[u] -= 1.0;
          }
          if (advanceB) {
            sample += fadeB * _oscillate(note.phasesB[u]);
            note.phasesB[u] += note.incsB[u];
            if (note.phasesB[u] >= 1.0) {
              note.phasesB[u] -= 1.0;
            }
          }
          sample *= note.gainNow;
          accL += sample * note.panLs[u];
          accR += sample * note.panRs[u];
        }

        if (advanceB && note.fadePos >= note.fadeLen) {
          _swapBanks(note);
        }
      }

      accL = _lpL.process(accL * norm);
      accR = _lpR.process(accR * norm);
      final amp = 1.0 - _breathDepth * (0.5 - 0.5 * _breath.next());
      outStereo[2 * i] += accL * amp * gain;
      outStereo[2 * i + 1] += accR * amp * gain;
    }
  }
}
