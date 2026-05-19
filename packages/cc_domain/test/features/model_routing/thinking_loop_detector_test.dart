import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

void main() {
  group('verbatim tail repeat', () {
    test('detects a short unit repeated past the char threshold', () {
      final d = ThinkingLoopDetector();
      String? reason;
      // "loopy" (5 chars) × 40 = 200 chars ≥ 180-char threshold.
      for (var i = 0; i < 40 && reason == null; i++) {
        reason = d.push('loopy');
      }
      expect(reason, isNotNull);
      expect(reason, contains('verbatim'));
    });

    test('does not fire on healthy varied prose', () {
      final d = ThinkingLoopDetector();
      const prose =
          'First I will read the file, then inspect the failing test, '
          'then form a hypothesis about the root cause and verify it.';
      expect(d.push(prose), isNull);
      expect(d.flush(), isNull);
    });
  });

  group('paragraph near-duplicate cluster', () {
    test('fires when ≥4 of ≥8 segments are near-identical', () {
      final d = ThinkingLoopDetector();
      String? reason;

      // 4 distinct, substantial filler segments (warm-up).
      const fillers = [
        'I should begin by reading the parser module and the failing integration test to understand the observed behavior here.',
        'Next the configuration loader deserves a careful look because the environment variables might be parsed in the wrong order.',
        'The database migration could also be relevant since the schema version changed recently and a column may be missing now.',
        'Finally the network retry policy might be masking the underlying error and swallowing the exception before it surfaces anywhere.',
      ];
      for (final f in fillers) {
        reason ??= d.push('$f\n\n');
      }
      expect(reason, isNull, reason: 'fillers should not trigger');

      // The same intent re-emitted with cosmetic drift, 4 times.
      const repeated =
          'I really need to fix the parser bug in the tokenizer function '
          'right now before anything else can possibly proceed correctly.';
      for (var i = 0; i < 4 && reason == null; i++) {
        reason = d.push('$repeated (attempt ${i + 1})\n\n');
      }
      expect(reason, isNotNull);
      expect(reason, contains('duplicate'));
    });
  });

  test('disabled detector never fires', () {
    final d = ThinkingLoopDetector(enabled: false);
    String? reason;
    for (var i = 0; i < 100; i++) {
      reason ??= d.push('loopy');
    }
    expect(reason, isNull);
    expect(d.flush(), isNull);
  });
}
