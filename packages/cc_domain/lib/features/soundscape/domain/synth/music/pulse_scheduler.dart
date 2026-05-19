import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';

/// The energy layer's beat kit: a dark bass pulse, a quiet high tick, and a
/// half-time backbeat on the tempo grid, over a bar-level walking bassline.
///
/// Events are tagged by role through [MotifEvent.timbre]: `0` = bass thump,
/// `1` = tick (the shaker/hat analogue — bright, quiet, perfectly regular on
/// eighths, doubling to sixteenths near full fill), `2` = the backbeat thock
/// on beat three (the half-time skeleton of the chill-DnB-style reference
/// material). Regularity keeps the kit predictable — arousal without
/// surprisal.
///
/// "Boost"-style focus audio is carried by a beat hierarchy over a stepped bassline in the 50–90 Hz zone that
/// moves every bar or two. This scheduler emits that layer: one low
/// pentatonic-safe note per gated beat, with a per-bar velocity pattern and a
/// slow 4-bar root/low-neighbour progression. The `fill` parameter morphs the
/// pattern from "downbeats only" toward "every beat plus a trailing eighth"
/// — the density lever the tune pad's energy axis drives. The arousal levers
/// here are exactly the evidence-backed ones (steady pulse clarity, tempo,
/// accentuation), while staying salience-safe: low register, soft-enough
/// attacks, no broadband content, rates far below the 30–150 Hz roughness
/// band.
///
/// Determinism: the beat clock always runs and PRNG draws happen on a fixed
/// schedule per beat, so the stream is a pure function of the seed and the
/// sample clock; live `fill` changes only gate audibility. Advancing is
/// boundary-exact and independent of block size.
class PulseScheduler {
  /// Creates a pulse on [beatsPerMinute] at [sampleRate]. Notes voice one
  /// octave below the live harmony root passed to [advance], walking a 4-bar
  /// progression.
  PulseScheduler(
    double sampleRate,
    SeededPrng prng, {
    required double beatsPerMinute,
  }) : _prng = prng,
       _beatSamples = math.max(
         1,
         (sampleRate * 60.0 / beatsPerMinute).round(),
       ) {
    // Ease in on a bar boundary.
    _untilNext = _beatSamples * 4;
  }

  /// Velocity per beat of a 4/4 bar: down, weak, mid, weak.
  static const List<double> _barVelocities = <double>[1.0, 0.58, 0.8, 0.58];

  /// Bar-root progressions in semitone offsets from the harmony root —
  /// pentatonic-safe low neighbours (0 = root, -3 = the sixth below,
  /// -5 = the fifth below), so the bassline walks like the reference tracks
  /// while staying consonant under any pentatonic pad chord.
  static const List<List<int>> _progressions = <List<int>>[
    <int>[0, 0, 0, 0],
    <int>[0, 0, -3, -3],
    <int>[0, -5, -3, -5],
    <int>[0, 0, -5, -3],
  ];

  final SeededPrng _prng;
  final int _beatSamples;

  late int _untilNext;
  int _beatIndex = 0;
  List<int> _progression = _progressions[0];

  /// Advances the clock by [frames], emitting the pulse notes that fall in
  /// this block. [fill] in `[0, 1]` morphs the pattern density (downbeats →
  /// all beats → trailing eighths); `<= 0` keeps the layer silent while the
  /// clock and PRNG stream still run. [rootMidi] is the harmony root the
  /// bassline hangs one octave below.
  List<MotifEvent> advance(
    int frames, {
    required double fill,
    required int rootMidi,
  }) {
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
      _untilNext = _beatSamples;
      _fire(consumed, fill, rootMidi, events);
    }
    return events;
  }

  void _fire(
    int offsetFrames,
    double fill,
    int rootMidi,
    List<MotifEvent> events,
  ) {
    final beatInBar = _beatIndex % 4;
    final barIndex = (_beatIndex ~/ 4) % 4;
    final beatParity = _beatIndex.isEven;
    _beatIndex++;

    // Fixed draw schedule per beat, independent of fill.
    final velocityJitter = _prng.nextRange(0.88, 1.0);
    final ghostJitter = _prng.nextRange(0.85, 1.0);
    final tickJitter = _prng.nextRange(0.88, 1.0);
    if (beatInBar == 0 && barIndex == 0) {
      // New 4-bar phrase: pick the bassline progression for it.
      _progression = _progressions[_prng.nextInt(_progressions.length)];
    }

    final midi = rootMidi - 12 + _progression[barIndex];
    final frequencyHz = 440.0 * math.pow(2.0, (midi - 69) / 12.0).toDouble();

    // Bass thump (timbre 0). Pattern morph: downbeat from the first breath
    // of energy, beat 3 next, the weak beats after, and a trailing eighth
    // "and" only near full fill.
    final threshold = switch (beatInBar) {
      0 => 0.02,
      2 => 0.3,
      _ => 0.62,
    };
    if (fill > threshold) {
      events.add(
        MotifEvent(
          offsetFrames: offsetFrames,
          frequencyHz: frequencyHz,
          velocity: (_barVelocities[beatInBar] * velocityJitter).clamp(
            0.0,
            1.0,
          ),
          pan: 0.0,
        ),
      );
      if (beatInBar == 1 && fill > 0.88) {
        events.add(
          MotifEvent(
            offsetFrames: offsetFrames + _beatSamples ~/ 2,
            frequencyHz: frequencyHz,
            velocity: (0.4 * ghostJitter).clamp(0.0, 1.0),
            pan: 0.0,
          ),
        );
      }
    }

    // Backbeat thock (timbre 2) on beat three — the half-time skeleton.
    if (fill > 0.7 && beatInBar == 2) {
      events.add(
        MotifEvent(
          offsetFrames: offsetFrames,
          frequencyHz:
              440.0 * math.pow(2.0, (rootMidi + 12 - 69) / 12.0).toDouble(),
          velocity: (0.85 * velocityJitter).clamp(0.0, 1.0),
          pan: 0.0,
          timbre: 2,
        ),
      );
    }

    // Ticks (timbre 1): eighths from mid fill, sixteenths near full fill —
    // the fast articulation that reads as tempo.
    if (fill > 0.5) {
      final tickHz =
          440.0 * math.pow(2.0, (rootMidi + 48 - 69) / 12.0).toDouble();
      final sixteenths = fill > 0.9;
      final quarters = sixteenths ? 4 : 2;
      for (var q = 0; q < quarters; q++) {
        final onset = offsetFrames + q * _beatSamples ~/ quarters;
        events.add(
          MotifEvent(
            offsetFrames: onset,
            frequencyHz: tickHz,
            velocity: ((q == 0 ? 0.5 : 0.34) * tickJitter).clamp(0.0, 1.0),
            pan: (beatParity == q.isEven ? 1.0 : -1.0) * 0.2,
            timbre: 1,
          ),
        );
      }
    }
  }
}
