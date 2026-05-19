import 'package:cc_domain/features/observability/domain/doom_loop_detector.dart';
import 'package:test/test.dart';

void main() {
  group('ToolCallSignature', () {
    test('from() encodes args to stable JSON', () {
      final sig = ToolCallSignature.from('read', {'path': 'a.dart'});
      expect(sig.toolName, 'read');
      expect(sig.argsJson, '{"path":"a.dart"}');
    });

    test('map argsJson is key-order-insensitive', () {
      final a = ToolCallSignature.from('grep', {'q': 'x', 'limit': 5});
      final b = ToolCallSignature.from('grep', {'limit': 5, 'q': 'x'});
      expect(a.argsJson, b.argsJson);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('nested maps are canonicalized recursively', () {
      final a = ToolCallSignature.from('call', {
        'outer': {'b': 2, 'a': 1},
        'tail': [1, 2, 3],
      });
      final b = ToolCallSignature.from('call', {
        'tail': [1, 2, 3],
        'outer': {'a': 1, 'b': 2},
      });
      expect(a, b);
    });

    test('list order is preserved (semantically significant)', () {
      final a = ToolCallSignature.from('call', {
        'items': [1, 2, 3],
      });
      final b = ToolCallSignature.from('call', {
        'items': [3, 2, 1],
      });
      expect(a, isNot(b));
    });

    test('different tool name with same args is not equal', () {
      final a = ToolCallSignature.from('read', {'path': 'x'});
      final b = ToolCallSignature.from('write', {'path': 'x'});
      expect(a, isNot(b));
    });

    test('different arg values are not equal', () {
      final a = ToolCallSignature.from('read', {'path': 'x'});
      final b = ToolCallSignature.from('read', {'path': 'y'});
      expect(a, isNot(b));
    });

    test('null and empty-map args differ', () {
      final none = ToolCallSignature.from('ping', null);
      final empty = ToolCallSignature.from('ping', <String, Object?>{});
      expect(none.argsJson, 'null');
      expect(empty.argsJson, '{}');
      expect(none, isNot(empty));
    });

    test('equals is reflexive via identical fast-path', () {
      final sig = ToolCallSignature.from('read', {'path': 'x'});
      expect(sig == sig, isTrue);
    });

    test('is not equal to an unrelated type', () {
      final sig = ToolCallSignature.from('read', null);
      expect(sig == Object(), isFalse);
    });

    test('const construction with precomputed argsJson compares equal', () {
      const a = ToolCallSignature('read', '{"path":"x"}');
      const b = ToolCallSignature('read', '{"path":"x"}');
      expect(a, b);
      expect(identical(a, b), isTrue, reason: 'const canonicalization');
    });

    test('toString includes tool and args', () {
      final sig = ToolCallSignature.from('read', {'path': 'x'});
      expect(sig.toString(), contains('read'));
      expect(sig.toString(), contains('path'));
    });
  });

  group('DoomLoopDetector', () {
    test('default threshold is the doom-loop constant', () {
      expect(DoomLoopDetector().threshold, kDoomLoopThreshold);
      expect(kDoomLoopThreshold, 3);
    });

    test('fires on the 3rd identical call, not before', () {
      final d = DoomLoopDetector();
      final sig = ToolCallSignature.from('read', {'path': 'a.dart'});

      expect(d.record(sig), DoomLoopDecision.none);
      expect(d.currentStreak, 1);

      expect(d.record(sig), DoomLoopDecision.none);
      expect(d.currentStreak, 2);

      expect(d.record(sig), DoomLoopDecision.detected);
      expect(d.currentStreak, 3);
    });

    test('keeps firing on each further identical call past threshold', () {
      final d = DoomLoopDetector();
      final sig = ToolCallSignature.from('read', {'path': 'a.dart'});
      d.record(sig);
      d.record(sig);
      expect(d.record(sig), DoomLoopDecision.detected);
      expect(d.record(sig), DoomLoopDecision.detected);
      expect(d.currentStreak, 4);
    });

    test('a different tool resets the streak', () {
      final d = DoomLoopDetector();
      final read = ToolCallSignature.from('read', {'path': 'a.dart'});
      final write = ToolCallSignature.from('write', {'path': 'a.dart'});

      expect(d.record(read), DoomLoopDecision.none);
      expect(d.record(read), DoomLoopDecision.none);
      expect(d.currentStreak, 2);

      // Different tool breaks the run.
      expect(d.record(write), DoomLoopDecision.none);
      expect(d.currentStreak, 1);

      // Now only one read again, so still below threshold.
      expect(d.record(read), DoomLoopDecision.none);
      expect(d.currentStreak, 1);
      expect(d.record(read), DoomLoopDecision.none);
      expect(d.record(read), DoomLoopDecision.detected);
    });

    test('different args for the same tool reset the streak', () {
      final d = DoomLoopDetector();
      final a = ToolCallSignature.from('read', {'path': 'a.dart'});
      final b = ToolCallSignature.from('read', {'path': 'b.dart'});

      expect(d.record(a), DoomLoopDecision.none);
      expect(d.record(a), DoomLoopDecision.none);
      expect(d.record(b), DoomLoopDecision.none);
      expect(d.currentStreak, 1);
    });

    test('alternating tools never detect a loop', () {
      final d = DoomLoopDetector();
      final a = ToolCallSignature.from('toolA', {'i': 1});
      final b = ToolCallSignature.from('toolB', {'i': 1});
      for (var i = 0; i < 50; i++) {
        expect(d.record(i.isEven ? a : b), DoomLoopDecision.none);
        expect(d.currentStreak, 1);
      }
    });

    test('key-order variants of the same call count as identical', () {
      final d = DoomLoopDetector();
      final s1 = ToolCallSignature.from('grep', {'q': 'x', 'n': 1});
      final s2 = ToolCallSignature.from('grep', {'n': 1, 'q': 'x'});
      final s3 = ToolCallSignature.from('grep', {'q': 'x', 'n': 1});

      expect(d.record(s1), DoomLoopDecision.none);
      expect(d.record(s2), DoomLoopDecision.none);
      expect(d.record(s3), DoomLoopDecision.detected);
      expect(d.currentStreak, 3);
    });

    test('reset clears streak and last signature', () {
      final d = DoomLoopDetector();
      final sig = ToolCallSignature.from('read', {'path': 'a.dart'});
      d.record(sig);
      d.record(sig);
      expect(d.currentStreak, 2);

      d.reset();
      expect(d.currentStreak, 0);

      // After reset, the same signature starts a brand-new streak.
      expect(d.record(sig), DoomLoopDecision.none);
      expect(d.currentStreak, 1);
    });

    test('streak is 0 before any call', () {
      expect(DoomLoopDetector().currentStreak, 0);
    });

    test('custom threshold of 1 detects on the first call', () {
      final d = DoomLoopDetector(threshold: 1);
      final sig = ToolCallSignature.from('read', null);
      expect(d.record(sig), DoomLoopDecision.detected);
      expect(d.currentStreak, 1);
    });

    test('custom threshold of 5 requires five in a row', () {
      final d = DoomLoopDetector(threshold: 5);
      final sig = ToolCallSignature.from('read', {'path': 'a'});
      for (var i = 0; i < 4; i++) {
        expect(d.record(sig), DoomLoopDecision.none);
      }
      expect(d.record(sig), DoomLoopDecision.detected);
    });

    test('threshold below 1 is rejected', () {
      expect(
        () => DoomLoopDetector(threshold: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('doomLoopSteerNotice', () {
    test('mentions the tool, the count, and steering guidance', () {
      final notice = doomLoopSteerNotice('read', 3);
      expect(notice, contains('[loop notice]'));
      expect(notice, contains('`read`'));
      expect(notice, contains('3'));
      expect(notice, contains('Stop repeating it'));
      expect(notice, contains('change approach'));
    });
  });
}
