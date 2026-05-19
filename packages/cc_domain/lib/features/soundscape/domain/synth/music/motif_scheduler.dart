import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';

/// One scheduled motif note.
class MotifEvent {
  /// Creates an event at [offsetFrames] within the advanced block.
  const MotifEvent({
    required this.offsetFrames,
    required this.frequencyHz,
    required this.velocity,
    required this.pan,
    this.timbre = 0,
  });

  /// Sample offset of the onset within the advanced block.
  final int offsetFrames;

  /// The note frequency in Hz.
  final double frequencyHz;

  /// Loudness scaler in `[0, 1]`.
  final double velocity;

  /// Stereo position in `[-1, 1]`.
  final double pan;

  /// Index of the instrument color this note speaks in (the composer maps
  /// it onto its timbre bank). Rotated per phrase, so a phrase reads as one
  /// instrument answering another.
  final int timbre;
}

/// Phrase-structured melodic scheduling — the replacement for the old
/// Poisson-triggered bells.
///
/// Notes land on an (inaudible) beat grid with small onset jitter, grouped
/// into short phrases of 2–4 notes separated by long rests, so sparse events
/// read as intentional instead of accidental. Pitches walk the pentatonic
/// table with the melodic-expectancy rules that make melodies feel "expected"
/// (Temperley/Narmour/Huron): mostly single-degree steps, a soft attractor
/// toward the register center and gap-fill (a leap is answered by a step
/// back the other way). Phrase openings snap to the current pad chord so the
/// line always agrees with the harmony. Density is a live parameter (weather
/// and daypart thin it out) expressed in notes per minute; rests stretch to
/// hit it. About half the notes trail a quiet one-beat echo on the opposite
/// side of the stereo field — cheap call-and-response.
///
/// Everything is a pure function of the [SeededPrng] and the sample clock;
/// advancing is boundary-exact so renders are independent of block size.
class MotifScheduler {
  /// Creates a scheduler over [scaleMidi] (ascending) with a pulse grid of
  /// [beatsPerMinute] at [sampleRate].
  MotifScheduler(
    double sampleRate,
    SeededPrng prng, {
    required List<int> scaleMidi,
    required double beatsPerMinute,
    int timbreCount = 1,
  }) : _sampleRate = sampleRate,
       _prng = prng,
       _scaleMidi = List<int>.unmodifiable(scaleMidi),
       _beatSamples = math.max(1, (sampleRate * 60.0 / beatsPerMinute).round()),
       _timbreCount = math.max(1, timbreCount),
       _index = scaleMidi.length ~/ 2 {
    if (scaleMidi.isEmpty) {
      throw ArgumentError('motif scheduler needs a scale');
    }
    // Ease in: the first phrase starts after a few beats, not at t=0.
    _untilNext = _beatSamples * 4;
    _resting = true;
  }

  static const double _echoProbability = 0.45;
  static const double _echoVelocity = 0.35;

  final double _sampleRate;
  final SeededPrng _prng;
  final List<int> _scaleMidi;
  final int _beatSamples;
  final int _timbreCount;

  int _index;
  int _untilNext = 0;
  bool _resting = true;
  int _notesLeftInPhrase = 0;
  int _phraseNoteCount = 0;
  int _phraseSpanSamples = 0;
  int _pendingGapFill = 0;
  int _timbre = 0;
  double _lastPan = 0.0;

  /// Echoes waiting to fire, as `[samplesUntilOnset, frequencyHz, velocity,
  /// pan, timbre]` tuples.
  final List<List<double>> _pendingEchoes = <List<double>>[];

  /// Advances the clock by [frames], emitting the notes that fall inside this
  /// block. [notesPerMinute] is the live density target (`<= 0` pauses the
  /// melody, the phrase machinery keeps running silently so the stream stays
  /// deterministic); [chordMidi] is the pad's current voicing, used to anchor
  /// phrase openings.
  List<MotifEvent> advance(
    int frames, {
    required double notesPerMinute,
    required List<int> chordMidi,
  }) {
    final events = <MotifEvent>[];
    final audible = notesPerMinute > 0.05;

    // Fire any pending echoes that land in this block.
    for (var i = _pendingEchoes.length - 1; i >= 0; i--) {
      final echo = _pendingEchoes[i];
      if (echo[0] < frames) {
        if (audible) {
          events.add(
            MotifEvent(
              offsetFrames: echo[0].toInt(),
              frequencyHz: echo[1],
              velocity: echo[2],
              pan: echo[3],
              timbre: echo[4].toInt(),
            ),
          );
        }
        _pendingEchoes.removeAt(i);
      } else {
        echo[0] -= frames;
      }
    }

    var consumed = 0;
    var remaining = frames;
    while (remaining > 0) {
      if (_untilNext > remaining) {
        _untilNext -= remaining;
        break;
      }
      consumed += _untilNext;
      remaining -= _untilNext;
      _untilNext = 0;
      _fire(consumed, notesPerMinute, chordMidi, audible, events);
    }
    events.sort((a, b) => a.offsetFrames.compareTo(b.offsetFrames));
    return events;
  }

  void _fire(
    int offsetFrames,
    double notesPerMinute,
    List<int> chordMidi,
    bool audible,
    List<MotifEvent> events,
  ) {
    if (_resting) {
      // Phrase start: 2-4 notes, opening pitch anchored to the chord and
      // the phrase picks the instrument color it will speak in.
      _resting = false;
      _phraseNoteCount = 2 + _prng.nextInt(3);
      _notesLeftInPhrase = _phraseNoteCount;
      _phraseSpanSamples = 0;
      _timbre = _prng.nextInt(_timbreCount);
      _snapToChordTone(chordMidi);
    } else {
      _walkStep();
    }

    final velocity = _prng.nextRange(0.75, 1.0);
    final pan = _prng.nextRange(-0.5, 0.5);
    _lastPan = pan;
    if (audible) {
      events.add(
        MotifEvent(
          offsetFrames: offsetFrames,
          frequencyHz: _midiToHz(_scaleMidi[_index]),
          velocity: velocity,
          pan: pan,
          timbre: _timbre,
        ),
      );
    }
    if (_prng.nextBool(_echoProbability)) {
      _pendingEchoes.add(<double>[
        (offsetFrames + _beatSamples).toDouble(),
        _midiToHz(_scaleMidi[_index]),
        velocity * _echoVelocity,
        -_lastPan,
        _timbre.toDouble(),
      ]);
    }

    _notesLeftInPhrase--;
    if (_notesLeftInPhrase > 0) {
      // Next note: 1-3 beats away, jittered by +/-5-30 ms, never closer than
      // ~one beat (minimum inter-onset keeps events from clumping).
      final beats = 1 + _prng.nextInt(3);
      final jitter =
          (_prng.nextRange(0.005, 0.03) * _sampleRate).round() *
          (_prng.nextBool(0.5) ? 1 : -1);
      _untilNext = math.max(
        (0.9 * _beatSamples).round(),
        beats * _beatSamples + jitter,
      );
      _phraseSpanSamples += _untilNext;
    } else {
      // Rest long enough that the average density hits notesPerMinute.
      _resting = true;
      final targetNpm = notesPerMinute.clamp(0.5, 30.0);
      final spanSeconds = _phraseSpanSamples / _sampleRate;
      final restSeconds = (60.0 * _phraseNoteCount / targetNpm - spanSeconds)
          .clamp(8.0, 120.0);
      final jittered = restSeconds * (1.0 + 0.2 * _prng.nextRange(-1.0, 1.0));
      _untilNext = math.max(_beatSamples, (jittered * _sampleRate).round());
    }
  }

  /// Melodic-expectancy walk: mostly steps, occasional small leaps, edges
  /// reflect toward the center and any leap queues a gap-fill step back.
  void _walkStep() {
    int step;
    if (_pendingGapFill != 0) {
      step = _pendingGapFill;
      _pendingGapFill = 0;
    } else {
      final roll = _prng.nextDouble();
      int magnitude;
      if (roll < 0.08) {
        magnitude = 0;
      } else if (roll < 0.63) {
        magnitude = 1;
      } else if (roll < 0.90) {
        magnitude = 2;
      } else {
        magnitude = 3;
      }
      final bool up;
      if (_index <= 1) {
        up = true;
      } else if (_index >= _scaleMidi.length - 2) {
        up = false;
      } else {
        up = _prng.nextBool(0.5);
      }
      step = up ? magnitude : -magnitude;
    }
    _index = (_index + step).clamp(0, _scaleMidi.length - 1);
    if (step.abs() >= 2) {
      _pendingGapFill = step > 0 ? -1 : 1;
    }
  }

  /// Moves the walk to the nearest scale tone that belongs to the current
  /// chord (compared by pitch class), so phrase openings are always chord
  /// tones. Keeps the current position when the chord has no pitch class in
  /// the motif register.
  void _snapToChordTone(List<int> chordMidi) {
    if (chordMidi.isEmpty) {
      return;
    }
    final chordClasses = <int>{for (final m in chordMidi) m % 12};
    var best = -1;
    var bestDistance = 1 << 30;
    for (var i = 0; i < _scaleMidi.length; i++) {
      if (!chordClasses.contains(_scaleMidi[i] % 12)) {
        continue;
      }
      final distance = (i - _index).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    if (best >= 0) {
      _index = best;
    }
  }

  static double _midiToHz(int midi) =>
      440.0 * math.pow(2.0, (midi - 69) / 12.0);
}
