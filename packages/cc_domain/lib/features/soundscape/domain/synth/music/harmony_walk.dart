import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';

/// One pad-voice retune decided by the [HarmonyWalk].
class HarmonyChange {
  /// Creates a change moving voice [voice] to [midi] at [offsetFrames] within
  /// the block that was just advanced over.
  const HarmonyChange({
    required this.voice,
    required this.midi,
    required this.offsetFrames,
  });

  /// Index of the pad voice that moves.
  final int voice;

  /// The MIDI note the voice moves to.
  final int midi;

  /// Sample offset of the change within the advanced block.
  final int offsetFrames;
}

/// The slow, voice-led chord walk under a soundscape.
///
/// Every `intervalSeconds` (± seeded jitter) exactly ONE voice moves one step
/// along its candidate list (an adjacent scale tone), all other voices hold —
/// there is never a block chord change, only a single tone drifting. Moves
/// that would land on another voice's note or closer than two semitones to
/// one are rejected (critical-band spacing; close intervals in the low
/// register read as roughness). The walk is a pure function of its
/// [SeededPrng] and the sample clock, so renders stay deterministic.
class HarmonyWalk {
  /// Creates a walk over [voices] stepping every [intervalSeconds] at
  /// [sampleRate]. An [intervalSeconds] `<= 0` freezes the harmony.
  HarmonyWalk(
    double sampleRate,
    SeededPrng prng, {
    required List<HarmonyVoicePlan> voices,
    required double intervalSeconds,
    double jitter = 0.25,
  }) : _sampleRate = sampleRate,
       _prng = prng,
       _plans = List<HarmonyVoicePlan>.unmodifiable(voices),
       _intervalSeconds = intervalSeconds,
       _jitter = jitter.clamp(0.0, 0.9),
       _currentMidi = <int>[for (final v in voices) v.initialMidi] {
    _untilNext = _intervalSeconds <= 0 ? -1 : _drawIntervalSamples();
  }

  final double _sampleRate;
  final SeededPrng _prng;
  final List<HarmonyVoicePlan> _plans;
  final double _intervalSeconds;
  final double _jitter;
  final List<int> _currentMidi;

  /// Samples until the next step; negative when the harmony is frozen.
  int _untilNext = -1;

  int _drawIntervalSamples() {
    final scale = 1.0 + _jitter * _prng.nextRange(-1.0, 1.0);
    return math.max(1, (_intervalSeconds * scale * _sampleRate).round());
  }

  /// The MIDI note each voice currently holds (or is gliding toward).
  List<int> get currentMidi => List<int>.unmodifiable(_currentMidi);

  /// Advances the clock by [frames] and returns the retunes that fall inside
  /// this block (at most a handful; usually zero or one).
  List<HarmonyChange> advance(int frames) {
    if (_untilNext < 0) {
      return const <HarmonyChange>[];
    }
    final changes = <HarmonyChange>[];
    var consumed = 0;
    var remaining = frames;
    while (remaining > 0) {
      if (_untilNext > remaining) {
        _untilNext -= remaining;
        break;
      }
      consumed += _untilNext;
      remaining -= _untilNext;
      final change = _step(offsetFrames: consumed);
      if (change != null) {
        changes.add(change);
      }
      _untilNext = _drawIntervalSamples();
    }
    return changes;
  }

  /// Attempts one walk step: picks a movable voice by weight and moves it one
  /// candidate-list step, honouring spacing. Returns null when the chosen
  /// move is blocked (the harmony simply rests this round).
  HarmonyChange? _step({required int offsetFrames}) {
    var totalWeight = 0.0;
    for (var v = 0; v < _plans.length; v++) {
      if (_plans[v].candidatesMidi.length > 1) {
        totalWeight += _plans[v].moveWeight;
      }
    }
    if (totalWeight <= 0) {
      return null;
    }
    var pick = _prng.nextDouble() * totalWeight;
    var voice = -1;
    for (var v = 0; v < _plans.length; v++) {
      if (_plans[v].candidatesMidi.length <= 1) {
        continue;
      }
      pick -= _plans[v].moveWeight;
      if (pick <= 0) {
        voice = v;
        break;
      }
    }
    if (voice < 0) {
      return null;
    }

    final candidates = _plans[voice].candidatesMidi;
    final index = candidates.indexOf(_currentMidi[voice]);
    final up = _prng.nextBool(0.5);
    final targetIndex = _clampIndex(index + (up ? 1 : -1), candidates.length);
    if (targetIndex == index) {
      return null;
    }
    final midi = candidates[targetIndex];
    for (var v = 0; v < _currentMidi.length; v++) {
      if (v != voice && (midi - _currentMidi[v]).abs() < 2) {
        return null;
      }
    }
    _currentMidi[voice] = midi;
    return HarmonyChange(voice: voice, midi: midi, offsetFrames: offsetFrames);
  }

  /// Steps that run off the end of the candidate list reflect back inside.
  int _clampIndex(int index, int length) {
    if (index < 0) {
      return 1 < length ? 1 : 0;
    }
    if (index >= length) {
      return length - 2 >= 0 ? length - 2 : length - 1;
    }
    return index;
  }
}
