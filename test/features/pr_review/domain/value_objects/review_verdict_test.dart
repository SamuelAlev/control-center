import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReviewVerdictOverall', () {
    test('has ship, hold, block values', timeout: const Timeout.factor(2), () {
      expect(ReviewVerdictOverall.values, containsAll([
        ReviewVerdictOverall.ship,
        ReviewVerdictOverall.hold,
        ReviewVerdictOverall.block,
      ]));
    });
  });

  group('ReviewVerdict constructor', () {
    test('creates with all fields', timeout: const Timeout.factor(2), () {
      const verdict = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.95,
        explanation: 'All clear',
        counts: {
          ReviewNodePriority.p0: 0,
          ReviewNodePriority.p1: 0,
          ReviewNodePriority.p2: 1,
          ReviewNodePriority.p3: 2,
        },
      );
      expect(verdict.overall, ReviewVerdictOverall.ship);
      expect(verdict.confidence, 0.95);
      expect(verdict.explanation, 'All clear');
      expect(verdict.p0Count, 0);
      expect(verdict.p1Count, 0);
      expect(verdict.p2Count, 1);
      expect(verdict.p3Count, 2);
    });
  });

  group('ReviewVerdict count getters', () {
    test('returns count from map', timeout: const Timeout.factor(2), () {
      const verdict = ReviewVerdict(
        overall: ReviewVerdictOverall.block,
        confidence: 0.9,
        explanation: '',
        counts: {
          ReviewNodePriority.p0: 3,
          ReviewNodePriority.p1: 5,
          ReviewNodePriority.p2: 7,
          ReviewNodePriority.p3: 11,
        },
      );
      expect(verdict.p0Count, 3);
      expect(verdict.p1Count, 5);
      expect(verdict.p2Count, 7);
      expect(verdict.p3Count, 11);
    });

    test('defaults to 0 for missing keys', timeout: const Timeout.factor(2), () {
      const verdict = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.9,
        explanation: '',
        counts: {},
      );
      expect(verdict.p0Count, 0);
      expect(verdict.p1Count, 0);
      expect(verdict.p2Count, 0);
      expect(verdict.p3Count, 0);
    });
  });

  group('ReviewVerdict == and hashCode', () {
    const a = ReviewVerdict(
      overall: ReviewVerdictOverall.ship,
      confidence: 0.9,
      explanation: 'ok',
      counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
    );

    test('equal when all fields match', timeout: const Timeout.factor(2), () {
      const b = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.9,
        explanation: 'ok',
        counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when overall differs', timeout: const Timeout.factor(2), () {
      const b = ReviewVerdict(
        overall: ReviewVerdictOverall.hold,
        confidence: 0.9,
        explanation: 'ok',
        counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when confidence differs', timeout: const Timeout.factor(2), () {
      const b = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.5,
        explanation: 'ok',
        counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when explanation differs', timeout: const Timeout.factor(2), () {
      const b = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.9,
        explanation: 'different',
        counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when counts differ', timeout: const Timeout.factor(2), () {
      const b = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 0.9,
        explanation: 'ok',
        counts: {ReviewNodePriority.p0: 1, ReviewNodePriority.p1: 0, ReviewNodePriority.p2: 0, ReviewNodePriority.p3: 0},
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', timeout: const Timeout.factor(2), () {
      expect(a, equals(a));
    });
  });

  group('ReviewVerdict.toMetadata', () {
    test('serializes to flat map', timeout: const Timeout.factor(2), () {
      const verdict = ReviewVerdict(
        overall: ReviewVerdictOverall.block,
        confidence: 0.85,
        explanation: 'Critical issues found',
        counts: {ReviewNodePriority.p0: 2, ReviewNodePriority.p1: 3, ReviewNodePriority.p2: 1, ReviewNodePriority.p3: 0},
      );
      final meta = verdict.toMetadata();
      expect(meta['verdict'], 'block');
      expect(meta['verdictConfidence'], 0.85);
      expect(meta['verdictExplanation'], 'Critical issues found');
      final counts = meta['priorityCounts'] as Map<String, dynamic>;
      expect(counts['p0'], 2);
      expect(counts['p1'], 3);
      expect(counts['p2'], 1);
      expect(counts['p3'], 0);
    });
  });

  group('ReviewVerdict.fromMetadata', () {
    test('parses valid metadata', timeout: const Timeout.factor(2), () {
      final meta = {
        'verdict': 'hold',
        'verdictConfidence': 0.75,
        'verdictExplanation': 'Needs work',
        'priorityCounts': {'p0': 0, 'p1': 1, 'p2': 2, 'p3': 3},
      };
      final verdict = ReviewVerdict.fromMetadata(meta)!;
      expect(verdict.overall, ReviewVerdictOverall.hold);
      expect(verdict.confidence, 0.75);
      expect(verdict.explanation, 'Needs work');
      expect(verdict.p0Count, 0);
      expect(verdict.p1Count, 1);
      expect(verdict.p2Count, 2);
      expect(verdict.p3Count, 3);
    });

    test('returns null for null input', timeout: const Timeout.factor(2), () {
      expect(ReviewVerdict.fromMetadata(null), isNull);
    });

    test('returns null when verdict key is missing', timeout: const Timeout.factor(2), () {
      expect(ReviewVerdict.fromMetadata({}), isNull);
    });

    test('returns null for unrecognized verdict string', timeout: const Timeout.factor(2), () {
      expect(ReviewVerdict.fromMetadata({'verdict': 'unknown'}), isNull);
    });

    test('returns null for non-string verdict', timeout: const Timeout.factor(2), () {
      expect(ReviewVerdict.fromMetadata({'verdict': 42}), isNull);
    });

    test('defaults confidence to 1.0 when missing or invalid', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({
        'verdict': 'ship',
        'verdictConfidence': 'not-a-number',
      })!;
      expect(verdict.confidence, 1.0);
    });

    test('defaults confidence to 1.0 when out of range', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({
        'verdict': 'ship',
        'verdictConfidence': 2.0,
      })!;
      expect(verdict.confidence, 1.0);
    });

    test('defaults confidence to 1.0 when negative', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({
        'verdict': 'ship',
        'verdictConfidence': -1.0,
      })!;
      expect(verdict.confidence, 1.0);
    });

    test('defaults explanation to empty string when missing', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({'verdict': 'ship'})!;
      expect(verdict.explanation, '');
    });

    test('defaults counts to all zeros when missing', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({'verdict': 'ship'})!;
      expect(verdict.p0Count, 0);
      expect(verdict.p1Count, 0);
      expect(verdict.p2Count, 0);
      expect(verdict.p3Count, 0);
    });

    test('handles partial priorityCounts', timeout: const Timeout.factor(2), () {
      final verdict = ReviewVerdict.fromMetadata({
        'verdict': 'ship',
        'priorityCounts': {'p0': 5},
      })!;
      expect(verdict.p0Count, 5);
      expect(verdict.p1Count, 0);
      expect(verdict.p2Count, 0);
      expect(verdict.p3Count, 0);
    });
  });

  group('ReviewVerdict round-trip', () {
    test('toMetadata → fromMetadata preserves verdict', timeout: const Timeout.factor(2), () {
      const original = ReviewVerdict(
        overall: ReviewVerdictOverall.hold,
        confidence: 0.88,
        explanation: 'One P1 issue needs fixing',
        counts: {ReviewNodePriority.p0: 0, ReviewNodePriority.p1: 1, ReviewNodePriority.p2: 3, ReviewNodePriority.p3: 5},
      );
      final restored = ReviewVerdict.fromMetadata(original.toMetadata())!;
      expect(restored.overall, original.overall);
      expect(restored.confidence, original.confidence);
      expect(restored.explanation, original.explanation);
      expect(restored.p0Count, original.p0Count);
      expect(restored.p1Count, original.p1Count);
      expect(restored.p2Count, original.p2Count);
      expect(restored.p3Count, original.p3Count);
    });
  });
}
