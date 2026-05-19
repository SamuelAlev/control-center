import 'dart:math' as math;

import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/motif_scheduler.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:test/test.dart';

const double _sampleRate = 8000.0;
const int _block = 1024;

/// The focus chord the pad holds at build time (D3, A3, F#4, A4).
const List<int> _focusChord = <int>[50, 57, 66, 69];

class _Note {
  _Note(this.atSample, this.event);
  final int atSample;
  final MotifEvent event;
}

/// Runs the scheduler for [seconds] and returns every emitted event with its
/// absolute onset sample.
List<_Note> _run(
  MotifScheduler scheduler, {
  required double seconds,
  required double notesPerMinute,
}) {
  final notes = <_Note>[];
  final blocks = (seconds * _sampleRate / _block).round();
  for (var b = 0; b < blocks; b++) {
    final events = scheduler.advance(
      _block,
      notesPerMinute: notesPerMinute,
      chordMidi: _focusChord,
    );
    for (final event in events) {
      notes.add(_Note(b * _block + event.offsetFrames, event));
    }
  }
  return notes;
}

MotifScheduler _focusScheduler(int seed) {
  final music = MoodMusic.of(SoundscapeMood.focus);
  return MotifScheduler(
    _sampleRate,
    SeededPrng(seed),
    scaleMidi: music.motifScaleMidi,
    beatsPerMinute: music.beatsPerMinute,
  );
}

/// Echoes are the quiet trailing repeats; main notes carry the melody.
bool _isMain(MotifEvent e) => e.velocity > 0.5;

int _nearestScaleIndex(List<int> scale, double frequencyHz) {
  var best = -1;
  var bestCents = double.infinity;
  for (var i = 0; i < scale.length; i++) {
    final cents =
        (1200.0 * (math.log(frequencyHz / midiToHz(scale[i])) / math.ln2))
            .abs();
    if (cents < bestCents) {
      bestCents = cents;
      best = i;
    }
  }
  return bestCents < 1.0 ? best : -1;
}

void main() {
  final scale = MoodMusic.of(SoundscapeMood.focus).motifScaleMidi;

  group('MotifScheduler', () {
    test('hits the requested density within a sane band', () {
      final notes = _run(
        _focusScheduler(11),
        seconds: 1200,
        notesPerMinute: 7.0,
      );
      final main = notes.where((n) => _isMain(n.event)).length;
      final perMinute = main / 20.0;
      // ~54/min was the old Poisson engine; the point is SPARSE.
      expect(perMinute, greaterThan(3.0));
      expect(perMinute, lessThan(11.0));
    });

    test('emits nothing while the density is zero', () {
      final notes = _run(_focusScheduler(3), seconds: 600, notesPerMinute: 0.0);
      expect(notes, isEmpty);
    });

    test('every note is exactly on the pentatonic scale', () {
      final notes = _run(_focusScheduler(5), seconds: 900, notesPerMinute: 8.0);
      expect(notes, isNotEmpty);
      for (final note in notes) {
        expect(
          _nearestScaleIndex(scale, note.event.frequencyHz),
          isNot(-1),
          reason: '${note.event.frequencyHz} Hz is not a scale tone',
        );
      }
    });

    test('keeps a minimum inter-onset gap and phrase rests', () {
      final notes = _run(
        _focusScheduler(21),
        seconds: 1800,
        notesPerMinute: 7.0,
      ).where((n) => _isMain(n.event)).toList();
      expect(notes.length, greaterThan(20));

      // The scheduler enforces >= 0.9 of a beat between onsets.
      final minGapSamples =
          0.9 *
          (60.0 / MoodMusic.of(SoundscapeMood.focus).beatsPerMinute) *
          _sampleRate;
      var longRests = 0;
      for (var i = 1; i < notes.length; i++) {
        final gap = notes[i].atSample - notes[i - 1].atSample;
        expect(
          gap,
          greaterThanOrEqualTo(minGapSamples.round()),
          reason: 'notes $i-1/$i clump',
        );
        if (gap > 8.0 * _sampleRate) {
          longRests++;
        }
      }
      expect(
        longRests,
        greaterThan(5),
        reason: 'phrases must be separated by long rests',
      );
    });

    test('melody is stepwise: most moves are small, none are wild', () {
      final notes = _run(
        _focusScheduler(31),
        seconds: 1800,
        notesPerMinute: 8.0,
      ).where((n) => _isMain(n.event)).toList();

      final indices = <int>[
        for (final n in notes) _nearestScaleIndex(scale, n.event.frequencyHz),
      ];
      var small = 0;
      var moves = 0;
      for (var i = 1; i < indices.length; i++) {
        final step = (indices[i] - indices[i - 1]).abs();
        expect(step, lessThanOrEqualTo(scale.length - 1));
        moves++;
        if (step <= 1) {
          small++;
        }
      }
      expect(moves, greaterThan(20));
      expect(
        small / moves,
        greaterThan(0.5),
        reason: 'stepwise motion must dominate',
      );
    });

    test('velocities are narrow and quiet-biased, pans are moderate', () {
      final notes = _run(
        _focusScheduler(17),
        seconds: 600,
        notesPerMinute: 8.0,
      );
      for (final note in notes) {
        expect(note.event.velocity, inInclusiveRange(0.2, 1.0));
        expect(note.event.pan, inInclusiveRange(-0.55, 0.55));
      }
      // Echoes exist and are quiet.
      final echoes = notes.where((n) => !_isMain(n.event));
      expect(echoes, isNotEmpty);
      for (final echo in echoes) {
        expect(echo.event.velocity, lessThan(0.4));
      }
    });

    test('rotates instrument colors per phrase within the bank', () {
      final music = MoodMusic.of(SoundscapeMood.focus);
      final scheduler = MotifScheduler(
        _sampleRate,
        SeededPrng(63),
        scaleMidi: music.motifScaleMidi,
        beatsPerMinute: music.beatsPerMinute,
        timbreCount: music.motifTimbres.length,
      );
      final notes = <_Note>[];
      final blocks = (1800 * _sampleRate / _block).round();
      for (var b = 0; b < blocks; b++) {
        final events = scheduler.advance(
          _block,
          notesPerMinute: 8.0,
          chordMidi: _focusChord,
        );
        for (final event in events) {
          notes.add(_Note(b * _block + event.offsetFrames, event));
        }
      }
      expect(notes, isNotEmpty);
      final timbres = <int>{for (final n in notes) n.event.timbre};
      for (final t in timbres) {
        expect(t, inInclusiveRange(0, music.motifTimbres.length - 1));
      }
      expect(
        timbres.length,
        greaterThan(1),
        reason: 'phrases must not all speak in one instrument',
      );
      // Notes inside one phrase share a timbre: consecutive main notes less
      // than a phrase-rest apart never switch color.
      final main = notes.where((n) => _isMain(n.event)).toList();
      for (var i = 1; i < main.length; i++) {
        final gap = main[i].atSample - main[i - 1].atSample;
        if (gap < 4.0 * _sampleRate) {
          expect(
            main[i].event.timbre,
            main[i - 1].event.timbre,
            reason: 'timbre switched mid-phrase at note $i',
          );
        }
      }
    });

    test('is deterministic for a given seed', () {
      final a = _run(_focusScheduler(99), seconds: 600, notesPerMinute: 7.0);
      final b = _run(_focusScheduler(99), seconds: 600, notesPerMinute: 7.0);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].atSample, b[i].atSample);
        expect(a[i].event.frequencyHz, b[i].event.frequencyHz);
        expect(a[i].event.velocity, b[i].event.velocity);
        expect(a[i].event.pan, b[i].event.pan);
      }
    });
  });
}
