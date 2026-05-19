import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/harmony_walk.dart';
import 'package:cc_domain/features/soundscape/domain/synth/music/scale.dart';
import 'package:cc_domain/features/soundscape/domain/synth/seeded_prng.dart';
import 'package:test/test.dart';

/// Control-rate tests can run at a tiny sample rate; the walk only uses it to
/// scale its interval clock.
const double _sampleRate = 8000.0;
const int _block = 1024;

/// Pitch classes of D major pentatonic (D E F# A B).
const Set<int> _dPentatonic = <int>{2, 4, 6, 9, 11};

HarmonyWalk _focusWalk(int seed) {
  final music = MoodMusic.of(SoundscapeMood.focus);
  return HarmonyWalk(
    _sampleRate,
    SeededPrng(seed),
    voices: music.harmonyVoices,
    // Short interval so a simulated hour of walking stays fast.
    intervalSeconds: 5.0,
  );
}

void main() {
  group('MoodMusic', () {
    test('AM rates are integer multiples of the beat (focus/relax)', () {
      final focus = MoodMusic.of(SoundscapeMood.focus);
      final relax = MoodMusic.of(SoundscapeMood.relax);
      final focusRatio = focus.amRateHz / (focus.beatsPerMinute / 60.0);
      final relaxRatio = relax.amRateHz / (relax.beatsPerMinute / 60.0);
      expect(focusRatio, closeTo(focusRatio.roundToDouble(), 1e-9));
      expect(relaxRatio, closeTo(relaxRatio.roundToDouble(), 1e-9));
    });

    test('sleep has no motifs and a frozen harmony', () {
      final sleep = MoodMusic.of(SoundscapeMood.sleep);
      expect(sleep.hasMotifs, isFalse);
      expect(sleep.harmonyIntervalSeconds, lessThanOrEqualTo(0.0));
    });

    test('every harmony candidate and motif note is in the mood scale', () {
      final scales = <SoundscapeMood, Set<int>>{
        SoundscapeMood.focus: _dPentatonic,
        SoundscapeMood.relax: <int>{0, 2, 4, 7, 9},
        SoundscapeMood.sleep: <int>{9, 4},
      };
      for (final mood in SoundscapeMood.values) {
        final music = MoodMusic.of(mood);
        for (final plan in music.harmonyVoices) {
          expect(plan.candidatesMidi, contains(plan.initialMidi));
          for (final midi in plan.candidatesMidi) {
            expect(
              scales[mood],
              contains(midi % 12),
              reason: '${mood.name} candidate $midi out of scale',
            );
          }
        }
        for (final midi in music.motifScaleMidi) {
          expect(
            scales[mood],
            contains(midi % 12),
            reason: '${mood.name} motif note $midi out of scale',
          );
        }
      }
    });
  });

  group('HarmonyWalk', () {
    test('moves at most one voice at a time (the root may walk)', () {
      final walk = _focusWalk(7);
      var previous = walk.currentMidi;
      // ~1 hour of simulated walking at the shortened interval.
      final blocks = (3600 * _sampleRate / _block).round();
      var changeCount = 0;
      var rootMoves = 0;
      for (var b = 0; b < blocks; b++) {
        final changes = walk.advance(_block);
        for (final change in changes) {
          changeCount++;
          if (change.voice == 0) {
            rootMoves++;
          }
          final current = walk.currentMidi;
          var moved = 0;
          for (var v = 0; v < current.length; v++) {
            if (current[v] != previous[v]) {
              moved++;
            }
          }
          expect(moved, lessThanOrEqualTo(1));
          previous = current;
        }
      }
      expect(
        changeCount,
        greaterThan(50),
        reason: 'the harmony must actually wander',
      );
      expect(
        rootMoves,
        greaterThan(0),
        reason:
            'the focus root voice walks its low neighbours '
            '(the ground moves with the chord)',
      );
    });

    test('keeps every voice in scale, in its candidate set, and spaced', () {
      final music = MoodMusic.of(SoundscapeMood.focus);
      final walk = _focusWalk(1234);
      final blocks = (3600 * _sampleRate / _block).round();
      for (var b = 0; b < blocks; b++) {
        walk.advance(_block);
        final current = walk.currentMidi;
        for (var v = 0; v < current.length; v++) {
          expect(music.harmonyVoices[v].candidatesMidi, contains(current[v]));
          expect(_dPentatonic, contains(current[v] % 12));
          for (var w = v + 1; w < current.length; w++) {
            expect(
              (current[v] - current[w]).abs(),
              greaterThanOrEqualTo(2),
              reason: 'voices $v/$w closer than two semitones',
            );
          }
        }
      }
    });

    test('is deterministic for a given seed', () {
      final a = _focusWalk(42);
      final b = _focusWalk(42);
      for (var i = 0; i < 2000; i++) {
        final changesA = a.advance(_block);
        final changesB = b.advance(_block);
        expect(changesA.length, changesB.length);
        for (var c = 0; c < changesA.length; c++) {
          expect(changesA[c].voice, changesB[c].voice);
          expect(changesA[c].midi, changesB[c].midi);
          expect(changesA[c].offsetFrames, changesB[c].offsetFrames);
        }
      }
    });

    test('a non-positive interval freezes the harmony', () {
      final music = MoodMusic.of(SoundscapeMood.sleep);
      final walk = HarmonyWalk(
        _sampleRate,
        SeededPrng(9),
        voices: music.harmonyVoices,
        intervalSeconds: music.harmonyIntervalSeconds,
      );
      for (var i = 0; i < 5000; i++) {
        expect(walk.advance(_block), isEmpty);
      }
    });
  });
}
