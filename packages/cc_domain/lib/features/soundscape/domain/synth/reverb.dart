import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/features/soundscape/domain/synth/biquad.dart';

/// A plain circular delay whose length equals its buffer size.
class _DelayLine {
  _DelayLine(int length) : _buffer = Float32List(length < 1 ? 1 : length);

  final Float32List _buffer;
  int _index = 0;

  /// Writes [x] and returns the sample from `length` samples ago.
  double process(double x) {
    final out = _buffer[_index];
    _buffer[_index] = x;
    _index++;
    if (_index >= _buffer.length) {
      _index = 0;
    }
    return out.toDouble();
  }

  /// The sample written [k] samples ago (`0 <= k < length`).
  double tap(int k) {
    var i = _index - 1 - k;
    if (i < 0) {
      i += _buffer.length;
    }
    return _buffer[i].toDouble();
  }
}

/// A Schroeder allpass diffuser with a tappable internal delay node.
class _Allpass {
  _Allpass(int length, this.gain)
    : _buffer = Float32List(length < 1 ? 1 : length);

  final Float32List _buffer;
  double gain;
  int _index = 0;

  double process(double x) {
    final buffered = _buffer[_index].toDouble();
    final out = buffered - gain * x;
    _buffer[_index] = x + gain * out;
    _index++;
    if (_index >= _buffer.length) {
      _index = 0;
    }
    return out;
  }

  /// The internal delay-node sample written [k] samples ago.
  double tap(int k) {
    var i = _index - 1 - k;
    if (i < 0) {
      i += _buffer.length;
    }
    return _buffer[i].toDouble();
  }
}

/// An allpass whose delay length is slowly modulated (fractional read).
///
/// Dattorro modulates the two tank allpasses by a handful of samples at
/// sub-Hz rates specifically to break up the static modes that make long
/// tails ring metallically — the single most effective anti-metallic tool.
class _ModulatedAllpass {
  _ModulatedAllpass(
    this._baseLength,
    this.gain,
    this._excursion,
    double sampleRate,
    double lfoHz,
  ) : _buffer = Float32List(_baseLength + _excursion.ceil() + 4),
      _lfoInc = lfoHz / sampleRate;

  final int _baseLength;
  final double _excursion;
  final Float32List _buffer;
  final double _lfoInc;
  double gain;
  int _index = 0;
  double _lfoPhase = 0.0;

  double process(double x) {
    // Excursion in [0, _excursion], swept by a slow sine.
    final exc = _excursion * (0.5 + 0.5 * math.sin(2 * math.pi * _lfoPhase));
    _lfoPhase += _lfoInc;
    if (_lfoPhase >= 1.0) {
      _lfoPhase -= 1.0;
    }

    final readPos = _index - (_baseLength + exc);
    final len = _buffer.length;
    var i0 = readPos.floor();
    final frac = readPos - i0;
    var i1 = i0 + 1;
    i0 %= len;
    if (i0 < 0) {
      i0 += len;
    }
    i1 %= len;
    if (i1 < 0) {
      i1 += len;
    }
    final buffered = _buffer[i0] * (1.0 - frac) + _buffer[i1] * frac;

    final out = buffered - gain * x;
    _buffer[_index] = x + gain * out;
    _index++;
    if (_index >= len) {
      _index = 0;
    }
    return out;
  }
}

/// Dattorro's 1997 plate reverb — the reference lush-ambient-tail-at-low-CPU
/// design, replacing the old Freeverb.
///
/// Topology: pre-delay → input bandwidth low-pass → four series input
/// diffusers → a figure-8 two-half tank (modulated allpass → long delay →
/// damping one-pole → decay → allpass → long delay per half, cross-fed).
/// Stereo comes for free from the paper's fixed table of seven output taps
/// per channel drawn from both tank halves. All delay lengths are the
/// original 29,761 Hz tunings rescaled to the render rate. A high-pass on the
/// wet keeps the tail out of the low end (mud) and the modulated tank
/// allpasses keep 10 s+ tails from ringing metallically.
class Reverb {
  /// Creates a plate for the given [sampleRate].
  Reverb(double sampleRate)
    : _sampleRate = sampleRate,
      _wetHpL = Biquad.highPass(sampleRate, 300.0, 0.707),
      _wetHpR = Biquad.highPass(sampleRate, 300.0, 0.707) {
    final s = sampleRate / _referenceRate;
    int sc(int n) => math.max(1, (n * s).round());

    _preDelayLine = _DelayLine(math.max(2, (0.12 * sampleRate).round()));
    _preDelaySamples = sc(300);

    _inputApfs = <_Allpass>[
      _Allpass(sc(142), 0.75),
      _Allpass(sc(107), 0.75),
      _Allpass(sc(379), 0.625),
      _Allpass(sc(277), 0.625),
    ];

    final excursion = 12.0 * s;
    _modApfL = _ModulatedAllpass(
      sc(672),
      _decayDiffusion1,
      excursion,
      sampleRate,
      0.55,
    );
    _modApfR = _ModulatedAllpass(
      sc(908),
      _decayDiffusion1,
      excursion,
      sampleRate,
      0.74,
    );
    _delayL1 = _DelayLine(sc(4453));
    _delayL2 = _DelayLine(sc(3720));
    _delayR1 = _DelayLine(sc(4217));
    _delayR2 = _DelayLine(sc(3163));
    _apfL2 = _Allpass(sc(1800), 0.5);
    _apfR2 = _Allpass(sc(2656), 0.5);

    // The paper's stereo output-tap table, rescaled.
    _tapsL = <int>[
      sc(266),
      sc(2974),
      sc(1913),
      sc(1996),
      sc(1990),
      sc(187),
      sc(1066),
    ];
    _tapsR = <int>[
      sc(353),
      sc(3627),
      sc(1228),
      sc(2673),
      sc(2111),
      sc(335),
      sc(121),
    ];

    setDecay(0.7);
  }

  /// The paper's reference sample rate for all delay tunings.
  static const double _referenceRate = 29761.0;

  static const double _decayDiffusion1 = 0.70;

  /// One-pole coefficient of the input bandwidth low-pass.
  static const double _bandwidth = 0.9;

  final double _sampleRate;
  final Biquad _wetHpL;
  final Biquad _wetHpR;

  late final _DelayLine _preDelayLine;
  late final List<_Allpass> _inputApfs;
  late final _ModulatedAllpass _modApfL;
  late final _ModulatedAllpass _modApfR;
  late final _DelayLine _delayL1;
  late final _DelayLine _delayL2;
  late final _DelayLine _delayR1;
  late final _DelayLine _delayR2;
  late final _Allpass _apfL2;
  late final _Allpass _apfR2;
  late final List<int> _tapsL;
  late final List<int> _tapsR;

  int _preDelaySamples = 1;
  double _decay = 0.7;
  double _damp = 0.3;

  double _bandwidthState = 0.0;
  double _dampStateL = 0.0;
  double _dampStateR = 0.0;
  double _feedbackL = 0.0;
  double _feedbackR = 0.0;
  double _wetHpHz = 300.0;

  /// Sets the tail length; [decay] in `[0, 1]` maps to a tank gain of
  /// 0.35–0.90 (a few seconds to a long ambient wash).
  void setDecay(double decay) {
    _decay = 0.35 + 0.55 * decay.clamp(0.0, 1.0);
    final diffusion2 = (_decay + 0.15).clamp(0.25, 0.5);
    _apfL2.gain = diffusion2;
    _apfR2.gain = diffusion2;
  }

  /// Sets the high-frequency damping of the tail, [damp] in `[0, 1]`.
  void setDamp(double damp) => _damp = damp.clamp(0.0, 1.0);

  /// Sets the pre-delay in milliseconds (clamped to the buffer).
  void setPreDelayMs(double ms) {
    final samples = (ms.clamp(0.0, 110.0) / 1000.0 * _sampleRate).round();
    _preDelaySamples = samples.clamp(1, (0.12 * _sampleRate).round() - 1);
  }

  /// Sets the wet high-pass corner (keeps the tail out of the low end).
  void setWetHighPassHz(double hz) {
    final clamped = hz.clamp(20.0, 1000.0).toDouble();
    if ((clamped - _wetHpHz).abs() < 0.5) {
      return;
    }
    _wetHpHz = clamped;
    _wetHpL.setHighPass(clamped, 0.707);
    _wetHpR.setHighPass(clamped, 0.707);
  }

  /// Reverberates [frames] frames of the interleaved [send] bus and adds the
  /// wet tail into [out] at [wet] gain.
  void processAdd(Float32List send, Float32List out, int frames, double wet) {
    if (wet <= 0.0) {
      return;
    }
    final decay = _decay;
    final damp = _damp;
    for (var i = 0; i < frames; i++) {
      final x = (send[2 * i] + send[2 * i + 1]) * 0.5;

      _preDelayLine.process(x);
      final pre = _preDelayLine.tap(_preDelaySamples);
      _bandwidthState += _bandwidth * (pre - _bandwidthState);

      var v = _bandwidthState;
      for (final apf in _inputApfs) {
        v = apf.process(v);
      }

      // Left tank half (fed by the right half's output).
      final tL = _modApfL.process(v + decay * _feedbackR);
      final d1L = _delayL1.process(tL);
      _dampStateL = d1L * (1.0 - damp) + _dampStateL * damp;
      final a2L = _apfL2.process(_dampStateL * decay);
      _feedbackL = _delayL2.process(a2L);

      // Right tank half (fed by the left half's output).
      final tR = _modApfR.process(v + decay * _feedbackL);
      final d1R = _delayR1.process(tR);
      _dampStateR = d1R * (1.0 - damp) + _dampStateR * damp;
      final a2R = _apfR2.process(_dampStateR * decay);
      _feedbackR = _delayR2.process(a2R);

      final yL =
          0.6 *
          (_delayR1.tap(_tapsL[0]) +
              _delayR1.tap(_tapsL[1]) -
              _apfR2.tap(_tapsL[2]) +
              _delayR2.tap(_tapsL[3]) -
              _delayL1.tap(_tapsL[4]) -
              _apfL2.tap(_tapsL[5]) -
              _delayL2.tap(_tapsL[6]));
      final yR =
          0.6 *
          (_delayL1.tap(_tapsR[0]) +
              _delayL1.tap(_tapsR[1]) -
              _apfL2.tap(_tapsR[2]) +
              _delayL2.tap(_tapsR[3]) -
              _delayR1.tap(_tapsR[4]) -
              _apfR2.tap(_tapsR[5]) -
              _delayR2.tap(_tapsR[6]));

      out[2 * i] += _wetHpL.process(yL) * wet;
      out[2 * i + 1] += _wetHpR.process(yR) * wet;
    }
  }
}
