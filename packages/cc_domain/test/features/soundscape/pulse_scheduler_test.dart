import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/pulse_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:test/test.dart';

const double _sampleRate = 8000.0;
const int _block = 1024;
const int _rootMidi = 50; // D3

class _Note {
  _Note(this.atSample, this.event);
  final int atSample;
  final MotifEvent event;
}

PulseScheduler _focusPulse(int seed) => PulseScheduler(
  _sampleRate,
  SeededPrng(seed),
  beatsPerMinute: MoodMusic.of(SoundscapeMood.focus).beatsPerMinute,
);

List<_Note> _run(
  PulseScheduler scheduler, {
  required double seconds,
  required double fill,
}) {
  final notes = <_Note>[];
  final blocks = (seconds * _sampleRate / _block).round();
  for (var b = 0; b < blocks; b++) {
    for (final event in scheduler.advance(
      _block,
      fill: fill,
      rootMidi: _rootMidi,
    )) {
      notes.add(_Note(b * _block + event.offsetFrames, event));
    }
  }
  return notes;
}

int _toMidi(double frequencyHz) =>
    (69 + 12 * (math.log(frequencyHz / 440.0) / math.ln2)).round();

void main() {
  final beatSamples =
      (_sampleRate * 60.0 / MoodMusic.of(SoundscapeMood.focus).beatsPerMinute)
          .round();

  group('PulseScheduler', () {
    test('is silent at zero fill', () {
      expect(_run(_focusPulse(1), seconds: 300, fill: 0.0), isEmpty);
    });

    test('low fill plays downbeats only; high fill fills the bar in', () {
      final low = _run(_focusPulse(5), seconds: 600, fill: 0.2);
      final high = _run(_focusPulse(5), seconds: 600, fill: 1.0);
      expect(low, isNotEmpty);
      // Downbeats only = one note per 4-beat bar.
      expect(
        low.length * 3,
        lessThan(high.length),
        reason: 'full fill must be at least ~4x denser than downbeats',
      );
      for (final note in low) {
        expect(
          note.atSample % (beatSamples * 4),
          0,
          reason: 'low-fill notes must sit on bar downbeats',
        );
      }
    });

    test('every hit sits on its grid: bass/backbeat on eighths, ticks on '
        'sixteenths', () {
      final notes = _run(_focusPulse(9), seconds: 600, fill: 1.0);
      for (final note in notes) {
        final grid = note.event.timbre == 1
            ? beatSamples ~/ 4
            : beatSamples ~/ 2;
        expect(
          note.atSample % grid,
          0,
          reason:
              'onset ${note.atSample} (timbre ${note.event.timbre}) '
              'is off the grid',
        );
      }
    });

    test('the bassline walks pentatonic-safe low neighbours of the root', () {
      final notes = _run(
        _focusPulse(21),
        seconds: 1800,
        fill: 1.0,
      ).where((n) => n.event.timbre == 0);
      final midis = <int>{for (final n in notes) _toMidi(n.event.frequencyHz)};
      const root = _rootMidi - 12;
      expect(midis, contains(root));
      expect(
        midis.difference(const <int>{root, root - 3, root - 5}),
        isEmpty,
        reason: 'bassline must stay on root / -3 / -5 semitone offsets',
      );
      expect(
        midis.length,
        greaterThan(1),
        reason: 'the bassline must actually move',
      );
    });

    test('downbeats are the accents (bass lane)', () {
      final notes = _run(
        _focusPulse(33),
        seconds: 600,
        fill: 1.0,
      ).where((n) => n.event.timbre == 0);
      for (final note in notes) {
        if (note.atSample % (beatSamples * 4) == 0) {
          expect(note.event.velocity, greaterThan(0.8));
        }
      }
    });

    test('the kit fades in by fill: ticks above 0.5, backbeat above 0.7', () {
      Set<int> timbresAt(double fill) => {
        for (final n in _run(_focusPulse(45), seconds: 600, fill: fill))
          n.event.timbre,
      };
      expect(timbresAt(0.4), equals({0}), reason: 'low fill is bass only');
      expect(
        timbresAt(0.6),
        equals({0, 1}),
        reason: 'mid fill adds the tick, not the backbeat',
      );
      expect(timbresAt(1.0), equals({0, 1, 2}));
      // Ticks stay quiet and high: articulation, not a lead voice.
      for (final n in _run(_focusPulse(45), seconds: 600, fill: 1.0)) {
        if (n.event.timbre == 1) {
          expect(n.event.velocity, lessThanOrEqualTo(0.5));
          expect(_toMidi(n.event.frequencyHz), _rootMidi + 48);
        }
      }
    });

    test('is deterministic for a given seed', () {
      final a = _run(_focusPulse(77), seconds: 300, fill: 0.8);
      final b = _run(_focusPulse(77), seconds: 300, fill: 0.8);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].atSample, b[i].atSample);
        expect(a[i].event.frequencyHz, b[i].event.frequencyHz);
        expect(a[i].event.velocity, b[i].event.velocity);
      }
    });

    test('the sounding bass pattern is a subset of the full-fill stream', () {
      final sparse = _run(
        _focusPulse(41),
        seconds: 600,
        fill: 0.4,
      ).where((n) => n.event.timbre == 0);
      final denseOnsets = <int, double>{
        for (final n in _run(_focusPulse(41), seconds: 600, fill: 1.0))
          if (n.event.timbre == 0) n.atSample: n.event.frequencyHz,
      };
      for (final n in sparse) {
        expect(denseOnsets[n.atSample], n.event.frequencyHz);
      }
    });
  });
}
