import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';

/// The waveform an [Lfo] produces.
enum LfoShape {
  /// A smooth sine wave.
  sine,

  /// A linear triangle wave.
  triangle,
}

/// A low-frequency oscillator producing values in `[-1, 1]`.
///
/// Used for slow, sub-audio modulation (pad breathing, macro intensity arcs).
/// It owns a phase accumulator so it stays continuous across render blocks.
class Lfo {
  /// Creates an oscillator at [freqHz] for the given [sampleRate].
  ///
  /// [phase] is the initial phase in `[0, 1)`; [shape] selects the waveform.
  Lfo(
    double sampleRate,
    double freqHz, {
    double phase = 0.0,
    LfoShape shape = LfoShape.sine,
  }) : _increment = freqHz / sampleRate,
       _phase = phase % 1.0,
       _shape = shape;

  final double _increment;
  final LfoShape _shape;
  double _phase;

  /// Advances the oscillator one sample and returns its value in `[-1, 1]`.
  double next() {
    final value = _shape == LfoShape.triangle
        ? 4.0 * (_phase < 0.5 ? _phase : 1.0 - _phase) - 1.0
        : math.sin(2 * math.pi * _phase);
    _phase += _increment;
    if (_phase >= 1.0) {
      _phase -= 1.0;
    }
    return value;
  }

  /// Advances the oscillator by [samples] samples and returns the value at the
  /// new position. Cheaper than calling [next] in a loop when only the
  /// block-rate value is needed.
  double nextBy(int samples) {
    _phase = (_phase + _increment * samples) % 1.0;
    return _shape == LfoShape.triangle
        ? 4.0 * (_phase < 0.5 ? _phase : 1.0 - _phase) - 1.0
        : math.sin(2 * math.pi * _phase);
  }
}

/// A seeded, non-cycling "organic LFO": stepped random targets smoothed by a
/// one-pole slew, the classic sample-and-hold-plus-lag control signal.
///
/// Every `periodSeconds` (± jitter) it draws a fresh target in `[-1, 1]` from
/// its [SeededPrng] and glides toward it with a time constant of roughly a
/// third of the period, producing smooth, band-limited wander that never
/// audibly repeats. Give each destination its own drift with an
/// incommensurate period (17 s, 41 s, 73 s, …) so the composite parameter
/// state never re-aligns — the Eno tape-loop trick applied to modulation.
///
/// Advancing is exact per sample count (segment boundaries are honoured
/// mid-block), so renders are independent of the block partitioning.
class DriftLfo {
  /// Creates a drift source stepping every [periodSeconds] (±[jitter] as a
  /// fraction of the period) at [sampleRate].
  DriftLfo(
    double sampleRate,
    SeededPrng prng, {
    required double periodSeconds,
    double jitter = 0.3,
  }) : _sampleRate = sampleRate,
       _prng = prng,
       _periodSeconds = periodSeconds,
       _jitter = jitter.clamp(0.0, 0.9),
       _k = math.exp(-3.0 / (periodSeconds * sampleRate)) {
    _value = _prng.nextRange(-0.5, 0.5);
    _target = _prng.nextRange(-1.0, 1.0);
    _untilNext = _drawPeriodSamples();
  }

  final double _sampleRate;
  final SeededPrng _prng;
  final double _periodSeconds;
  final double _jitter;

  /// Per-sample one-pole coefficient for a time constant of `period / 3`.
  final double _k;

  late double _value;
  late double _target;
  late int _untilNext;

  int _drawPeriodSamples() {
    final scale = 1.0 + _jitter * _prng.nextRange(-1.0, 1.0);
    return math.max(1, (_periodSeconds * scale * _sampleRate).round());
  }

  /// The current value in `[-1, 1]`, without advancing.
  double get value => _value;

  /// Advances by [samples] samples and returns the new value in `[-1, 1]`.
  double next(int samples) {
    var remaining = samples;
    while (remaining > 0) {
      final run = remaining < _untilNext ? remaining : _untilNext;
      _value = _target + (_value - _target) * math.pow(_k, run);
      _untilNext -= run;
      remaining -= run;
      if (_untilNext <= 0) {
        _target = _prng.nextRange(-1.0, 1.0);
        _untilNext = _drawPeriodSamples();
      }
    }
    return _value;
  }
}

/// Linearly ramps a value toward a target over a fixed number of samples.
///
/// Context changes (weather, daypart, mood) set new targets on the synth
/// parameters through a [ParamRamp] so the sound glides instead of jumping.
class ParamRamp {
  /// Creates a ramp already settled at [initial].
  ParamRamp(double initial) : _current = initial, _target = initial;

  double _current;
  double _target;
  double _step = 0.0;
  int _remaining = 0;

  /// The current value, without advancing.
  double get value => _current;

  /// The value this ramp is heading toward.
  double get target => _target;

  /// Whether the ramp has reached its target.
  bool get isSettled => _remaining <= 0;

  /// Begins ramping toward [target] over [samples] samples.
  ///
  /// A non-positive [samples] jumps immediately.
  void setTarget(double target, int samples) {
    _target = target;
    if (samples <= 0) {
      _current = target;
      _step = 0.0;
      _remaining = 0;
      return;
    }
    _step = (target - _current) / samples;
    _remaining = samples;
  }

  /// Advances one sample and returns the new current value.
  double next() => advanceBy(1);

  /// Advances by [samples] samples in O(1) and returns the new current value.
  ///
  /// Exactly equivalent to calling [next] [samples] times.
  double advanceBy(int samples) {
    if (_remaining > 0) {
      final n = samples < _remaining ? samples : _remaining;
      _current += _step * n;
      _remaining -= n;
      if (_remaining == 0) {
        _current = _target;
      }
    }
    return _current;
  }
}
