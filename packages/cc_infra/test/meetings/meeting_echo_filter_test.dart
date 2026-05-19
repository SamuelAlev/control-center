import 'dart:async';

import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/services/transcribed_window.dart';
import 'package:cc_infra/src/meetings/meeting_echo_filter.dart';
import 'package:test/test.dart';

/// Exercises [MeetingEchoFilter] plus its top-level pure helpers
/// (`echoTokens`, `echoSimilarity`, `isEchoMatch`). The filter is pure Dart —
/// persistence is injected via [OnAccepted] — so the full match/drop/hold
/// matrix is exercised without touching any I/O. Uses a fake clock: the
/// filter keys on emit-timestamps it is fed, never on real wall time, so
/// candidate ordering and `noteSystemActivity` drive every branch.
void main() {
  group('echoTokens', () {
    test('lowercases, strips punctuation, splits on whitespace', () {
      expect(echoTokens("Hello, world! It's me — again."), [
        'hello',
        'world',
        'it',
        's',
        'me',
        'again',
      ]);
    });

    test('drops empty tokens', () {
      expect(echoTokens('   '), isEmpty);
      expect(echoTokens('a    b'), ['a', 'b']);
    });

    test('folds non-alphanumeric runs to single spaces', () {
      expect(echoTokens('foo...bar===baz'), ['foo', 'bar', 'baz']);
    });
  });

  group('echoSimilarity (containment coefficient)', () {
    test('returns 1.0 for an exact subset (fragment of a longer line)', () {
      final a = {'the', 'quick', 'brown'};
      final b = {'the', 'quick', 'brown', 'fox', 'jumps'};
      expect(echoSimilarity(a, b), 1.0);
    });

    test('returns 0.5 for half-overlap when smaller set has 2 tokens', () {
      final a = {'x', 'y'};
      final b = {'x', 'z'};
      expect(echoSimilarity(a, b), 0.5);
    });

    test('returns 0 when either set is empty', () {
      expect(echoSimilarity(<String>{}, {'a'}), 0);
      expect(echoSimilarity({'a'}, <String>{}), 0);
    });

    test('symmetric with respect to which set is the subset', () {
      final fragment = {'a', 'b'};
      final longer = {'a', 'b', 'c', 'd'};
      // min(2,4)=2 → intersection=2 → 1.0 either direction.
      expect(
        echoSimilarity(fragment, longer),
        echoSimilarity(longer, fragment),
      );
    });
  });

  group('isEchoMatch', () {
    test('true at or above threshold, false below', () {
      final a = {'a', 'b', 'c', 'd'};
      final b = {'a', 'b', 'x', 'y'}; // similarity = 2/4 = 0.5
      expect(isEchoMatch(a, b, threshold: 0.5), isTrue);
      expect(isEchoMatch(a, b, threshold: 0.6), isFalse);
    });

    test('false when either set is empty', () {
      expect(isEchoMatch(<String>{}, {'a'}), isFalse);
    });
  });

  group('MeetingEchoFilter — "them" handling', () {
    test('"them" is always accepted immediately and never dropped', () async {
      final accepted = <MeetingSpeaker>[];
      final filter = MeetingEchoFilter(
        onAccepted: (speaker, window) async {
          accepted.add(speaker);
        },
      );
      filter.add(
        _candidate(
          MeetingSpeaker.them,
          'the quick brown fox jumps over',
          emitMs: 1000,
        ),
      );
      // Give the unawaited _commit microtask a chance to run.
      await Future<void>.delayed(Duration.zero);
      expect(accepted, [MeetingSpeaker.them]);
      filter.dispose();
    });

    test('dispose makes the filter a no-op', () async {
      final accepted = <MeetingSpeaker>[];
      final filter = MeetingEchoFilter(
        onAccepted: (speaker, window) async {
          accepted.add(speaker);
        },
      );
      filter.dispose();
      filter.add(
        _candidate(MeetingSpeaker.them, 'anything at all here', emitMs: 0),
      );
      filter.noteSystemActivity(5);
      await Future<void>.delayed(Duration.zero);
      expect(accepted, isEmpty);
    });
  });

  group('MeetingEchoFilter — me/them echo matching', () {
    test(
      'a "me" that matches a buffered "them" is dropped (them-first)',
      () async {
        final accepted = <MeetingSpeaker>[];
        final filter = MeetingEchoFilter(
          idleHoldMs: 50,
          activeHoldMs: 5000,
          bufferMs: 10000,
          matchWindowMs: 5000,
          onAccepted: (speaker, window) async {
            accepted.add(speaker);
          },
        );
        // "them" arrives first.
        filter.add(
          _candidate(
            MeetingSpeaker.them,
            'the quick brown fox jumps over the lazy dog',
            emitMs: 1000,
          ),
        );
        // A "me" echo of the same line, well within the match window.
        filter.add(
          _candidate(
            MeetingSpeaker.me,
            'the quick brown fox jumps', // >= 3 tokens, contained in them
            emitMs: 1500,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(accepted, [MeetingSpeaker.them]);
        filter.dispose();
      },
    );

    test(
      'a "me" with no match commits after the idle hold when remote is quiet',
      () async {
        final accepted = <MeetingSpeaker>[];
        final filter = MeetingEchoFilter(
          idleHoldMs: 20,
          activeHoldMs: 5000,
          matchWindowMs: 5000,
          onAccepted: (speaker, window) async {
            accepted.add(speaker);
          },
        );
        // No system activity → idle hold.
        filter.add(
          _candidate(
            MeetingSpeaker.me,
            'i am speaking into the silence now',
            emitMs: 1000,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(accepted, [MeetingSpeaker.me]);
        filter.dispose();
      },
    );

    test(
      'a "me" matching a later-arriving "them" is cancelled by reconciliation',
      () async {
        final accepted = <MeetingSpeaker>[];
        final filter = MeetingEchoFilter(
          idleHoldMs: 20,
          activeHoldMs: 5000,
          activeWindowMs: 5000,
          matchWindowMs: 5000,
          onAccepted: (speaker, window) async {
            accepted.add(speaker);
          },
        );
        // Mark the remote as active so the "me" is held long enough to be
        // reconciled.
        filter.noteSystemActivity(900);
        // "me" first.
        filter.add(
          _candidate(
            MeetingSpeaker.me,
            'the quick brown fox jumps',
            emitMs: 1000,
          ),
        );
        // "them" arrives before the active hold expires → cancels the held "me".
        filter.add(
          _candidate(
            MeetingSpeaker.them,
            'the quick brown fox jumps over the lazy dog',
            emitMs: 1200,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(accepted, [MeetingSpeaker.them]);
        filter.dispose();
      },
    );

    test(
      'a "me" shorter than minTokens is never matched (commits after hold)',
      () async {
        final accepted = <String>[];
        final filter = MeetingEchoFilter(
          idleHoldMs: 20,
          activeHoldMs: 5000,
          matchWindowMs: 5000,
          minTokens: 3,
          onAccepted: (speaker, window) async {
            accepted.add(window.text);
          },
        );
        // Buffer a long "them".
        filter.add(
          _candidate(
            MeetingSpeaker.them,
            'okay sure yes indeed really truly',
            emitMs: 0,
          ),
        );
        // "me" backchannel that is a subset but only 2 tokens.
        filter.add(_candidate(MeetingSpeaker.me, 'okay sure', emitMs: 100));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(accepted, ['okay sure yes indeed really truly', 'okay sure']);
        filter.dispose();
      },
    );

    test('buffered "them" windows older than bufferMs are pruned', () async {
      final accepted = <String>[];
      final filter = MeetingEchoFilter(
        idleHoldMs: 20,
        activeHoldMs: 5000,
        bufferMs: 100, // very short retention
        matchWindowMs: 5000,
        onAccepted: (speaker, window) async {
          accepted.add(window.text);
        },
      );
      // Old "them" — should be pruned when the next candidate arrives.
      filter.add(
        _candidate(
          MeetingSpeaker.them,
          'the quick brown fox jumps over the lazy dog',
          emitMs: 0,
        ),
      );
      // Echo of the old "them", but its buffer has aged out → no match → commits.
      filter.add(
        _candidate(
          MeetingSpeaker.me,
          'the quick brown fox jumps',
          emitMs: 1000, // 1000 > 0 + bufferMs(100)
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(accepted, contains('the quick brown fox jumps'));
      filter.dispose();
    });

    test('a "me" outside the matchWindow time band is not matched', () async {
      final accepted = <String>[];
      final filter = MeetingEchoFilter(
        idleHoldMs: 20,
        activeHoldMs: 5000,
        matchWindowMs: 500, // tight time band
        onAccepted: (speaker, window) async {
          accepted.add(window.text);
        },
      );
      filter.add(
        _candidate(
          MeetingSpeaker.them,
          'the quick brown fox jumps over the lazy dog',
          emitMs: 0,
        ),
      );
      // Same text but far outside the time band.
      filter.add(
        _candidate(
          MeetingSpeaker.me,
          'the quick brown fox jumps',
          emitMs: 5000, // |5000-0| > 500
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(accepted, contains('the quick brown fox jumps'));
      filter.dispose();
    });
  });

  group('MeetingEchoFilter — drain & dispose', () {
    test('drain commits held "me" windows immediately', () async {
      final accepted = <MeetingSpeaker>[];
      final filter = MeetingEchoFilter(
        idleHoldMs:
            10000, // long enough that the timer won't fire during the test
        activeHoldMs: 10000,
        matchWindowMs: 5000,
        onAccepted: (speaker, window) async {
          accepted.add(speaker);
        },
      );
      filter.add(
        _candidate(
          MeetingSpeaker.me,
          'i will be drained before my timer fires',
          emitMs: 0,
        ),
      );
      // Sanity: nothing committed yet.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(accepted, isEmpty);
      await filter.drain();
      expect(accepted, [MeetingSpeaker.me]);
    });

    test('drain swallows persistence failures', () async {
      final filter = MeetingEchoFilter(
        idleHoldMs: 10000,
        activeHoldMs: 10000,
        onAccepted: (speaker, window) async {
          throw StateError('persist failed');
        },
      );
      filter.add(
        _candidate(
          MeetingSpeaker.me,
          'this will fail to persist but drain must not throw',
          emitMs: 0,
        ),
      );
      // Should not throw.
      await filter.drain();
    });

    test('drain on a disposed filter is a no-op', () async {
      final accepted = <MeetingSpeaker>[];
      final filter = MeetingEchoFilter(
        onAccepted: (speaker, window) async {
          accepted.add(speaker);
        },
      );
      filter.dispose();
      await filter.drain();
      expect(accepted, isEmpty);
    });

    test('assertion fails when activeHoldMs < matchWindowMs', () {
      expect(
        () => MeetingEchoFilter(
          activeHoldMs: 100,
          matchWindowMs: 1000,
          onAccepted: (_, _) async {},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

EchoCandidate _candidate(
  MeetingSpeaker speaker,
  String text, {
  required int emitMs,
}) {
  return EchoCandidate(
    speaker: speaker,
    window: TranscribedWindow(text: text, startMs: emitMs, endMs: emitMs + 100),
    emitMs: emitMs,
  );
}
