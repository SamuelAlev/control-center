import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';

/// Broken-chord ladder scheduling — the density layer that gives focus its
/// "many notes" texture.
///
/// Focus audio carries ~40+ soft note events per minute spread
/// over several octaves. This scheduler produces that layer: it steps an eighth-note grid
/// and walks a pendulum over a ladder of the *current chord's* tones tiled across `lowMidi`–`highMidi`,
/// so every note is a chord tone and the line sweeps registers instead of
/// circling one octave. Each step is probability-gated by a live `fill`
/// parameter with metric weighting (on-beats fire first, off-beats only join
/// as fill rises), which keeps the stream predictable — arousal without
/// surprisal, per the salience literature.
///
/// Determinism: every step draws the same number of PRNG values whether or
/// not it sounds, so the event stream is a pure function of the seed and the
/// sample clock (live `fill` changes only gate audibility, exactly like the
/// motif scheduler's density). Advancing is boundary-exact, so renders are
/// independent of block size.
class ArpScheduler {
  /// Creates a scheduler stepping eighths of [beatsPerMinute] at
  /// [sampleRate], laddering chord tones between [lowMidi] and [highMidi].
  ArpScheduler(
    double sampleRate,
    SeededPrng prng, {
    required double beatsPerMinute,
    required int lowMidi,
    required int highMidi,
    int timbreCount = 1,
  }) : assert(highMidi > lowMidi, 'arp range must be ascending'),
       _prng = prng,
       _sampleRate = sampleRate,
       _stepSamples = math.max(1, (sampleRate * 30.0 / beatsPerMinute).round()),
       _lowMidi = lowMidi,
       _highMidi = highMidi,
       _timbreCount = math.max(1, timbreCount) {
    // Ease in: first step after one bar, not at t=0.
    _untilNext = _stepSamples * 8;
  }

  /// Metric accent per eighth-note position within a bar of 4 beats:
  /// downbeat, weak, mid, weak, …
  static const List<double> _accents = <double>[
    1.0, 0.55, 0.78, 0.55, 0.9, 0.55, 0.78, 0.55, //
  ];

  /// Fill multiplier per position — strong steps fire at low fill, off-beat
  /// eighths only join once fill is high (the "pattern fills up" morph).
  static const List<double> _fillWeights = <double>[
    1.6, 0.6, 1.1, 0.6, 1.35, 0.6, 1.1, 0.6, //
  ];

  /// Eighth-note steps per timbre section (4 bars of 4/4): the arp holds an
  /// instrument color for a section, then may hand over — the way the
  /// reference tracks rotate their layer instrumentation.
  static const int _timbreSectionSteps = 32;

  final SeededPrng _prng;
  final double _sampleRate;
  final int _stepSamples;
  final int _lowMidi;
  final int _highMidi;
  final int _timbreCount;

  late int _untilNext;
  int _stepIndex = 0;
  int _timbre = 0;

  List<int> _ladder = const <int>[];
  List<int> _ladderChord = const <int>[];
  int _pos = 0;
  int _direction = 1;

  /// Advances the clock by [frames], emitting the gated ladder notes that
  /// fall inside this block. [fill] in `[0, 1]` is the live step-fill
  /// probability (`0` silences the layer; the clock and PRNG stream keep
  /// running so audibility never forks determinism); [chordMidi] is the pad's
  /// current voicing, re-laddered whenever it changes.
  List<MotifEvent> advance(
    int frames, {
    required double fill,
    required List<int> chordMidi,
  }) {
    _maybeRebuildLadder(chordMidi);
    final events = <MotifEvent>[];
    var consumed = 0;
    var remaining = frames;
    while (remaining > 0) {
      if (_untilNext > remaining) {
        _untilNext -= remaining;
        break;
      }
      consumed += _untilNext;
      remaining -= _untilNext;
      _untilNext = _stepSamples;
      _fire(consumed, fill, events);
    }
    return events;
  }

  void _fire(int offsetFrames, double fill, List<MotifEvent> events) {
    final position = _stepIndex % _accents.length;
    final sectionStart = _stepIndex % _timbreSectionSteps == 0;
    _stepIndex++;

    // Fixed draw schedule (gate, velocity, jitter, stride, section timbre)
    // so the stream is invariant to the live fill value.
    final gateDraw = _prng.nextDouble();
    final velocityJitter = _prng.nextRange(0.85, 1.0);
    final jitterMs = _prng.nextRange(-9.0, 9.0);
    final stride = _prng.nextBool(0.14) ? 2 : 1;
    if (sectionStart) {
      _timbre = _prng.nextInt(_timbreCount);
    }

    if (_ladder.isEmpty) {
      return;
    }

    // Pendulum walk with occasional double-steps; edges reflect.
    _pos += _direction * stride;
    if (_pos >= _ladder.length) {
      _pos = math.max(0, _ladder.length - 2);
      _direction = -1;
    } else if (_pos < 0) {
      _pos = math.min(1, _ladder.length - 1);
      _direction = 1;
    }

    final effectiveFill = (fill * _fillWeights[position]).clamp(0.0, 0.97);
    if (fill <= 0.005 || gateDraw >= effectiveFill) {
      return;
    }

    final jitterFrames = (jitterMs / 1000.0 * _sampleRate).round();
    final onset = math.max(0, offsetFrames + jitterFrames);
    events.add(
      MotifEvent(
        offsetFrames: onset,
        frequencyHz: midiToHzD(_ladder[_pos]),
        velocity: (_accents[position] * velocityJitter).clamp(0.0, 1.0),
        // Alternate sides by grid parity — wide but orderly.
        pan:
            (position.isEven ? -1.0 : 1.0) * (0.35 + 0.45 * _accents[position]),
        timbre: _timbre,
      ),
    );
  }

  /// Rebuilds the ladder when the chord changes: every distinct pitch class
  /// of [chordMidi], tiled in octaves across the configured range.
  void _maybeRebuildLadder(List<int> chordMidi) {
    if (_sameChord(chordMidi)) {
      return;
    }
    _ladderChord = List<int>.of(chordMidi);
    final classes = <int>{for (final m in chordMidi) m % 12};
    final rungs = <int>[];
    for (final pc in classes) {
      var midi = _lowMidi + ((pc - _lowMidi) % 12 + 12) % 12;
      while (midi <= _highMidi) {
        rungs.add(midi);
        midi += 12;
      }
    }
    rungs.sort();
    _ladder = rungs;
    if (_ladder.isNotEmpty) {
      _pos = _pos.clamp(0, _ladder.length - 1);
    } else {
      _pos = 0;
    }
  }

  bool _sameChord(List<int> chordMidi) {
    if (chordMidi.length != _ladderChord.length) {
      return false;
    }
    for (var i = 0; i < chordMidi.length; i++) {
      if (chordMidi[i] != _ladderChord[i]) {
        return false;
      }
    }
    return true;
  }

  /// Local MIDI-to-Hz (kept static-free of `scale.dart` to avoid an import
  /// cycle risk; identical maths).
  static double midiToHzD(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0);
}
