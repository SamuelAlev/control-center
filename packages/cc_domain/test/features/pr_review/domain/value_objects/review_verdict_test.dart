import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:test/test.dart';

/// Coverage for the per-PR review verdict aggregate: the
/// [ReviewVerdictOverall] enum, [ReviewVerdict] value object, and its
/// interaction with [ReviewAxisResult] via `withAxisResults`.
void main() {
  group('ReviewVerdictOverall', () {
    test('exposes ship, hold and block', () {
      expect(ReviewVerdictOverall.values, contains(ReviewVerdictOverall.ship));
      expect(ReviewVerdictOverall.values, contains(ReviewVerdictOverall.hold));
      expect(ReviewVerdictOverall.values, contains(ReviewVerdictOverall.block));
    });
  });

  group('ReviewVerdict', () {
    Map<ReviewNodePriority, int> counts({
      int p0 = 0,
      int p1 = 0,
      int p2 = 0,
      int p3 = 0,
    }) => {
      ReviewNodePriority.p0: p0,
      ReviewNodePriority.p1: p1,
      ReviewNodePriority.p2: p2,
      ReviewNodePriority.p3: p3,
    };

    final base = ReviewVerdict(
      overall: ReviewVerdictOverall.ship,
      confidence: 0.9,
      explanation: 'looks fine',
      counts: counts(p0: 0, p1: 2, p2: 3, p3: 4),
      axisResults: const [],
    );

    test('construction round-trips every field', () {
      expect(base.overall, ReviewVerdictOverall.ship);
      expect(base.confidence, 0.9);
      expect(base.explanation, 'looks fine');
      expect(base.axisResults, isEmpty);
    });

    group('priority-count getters', () {
      test('read through counts', () {
        expect(base.p0Count, 0);
        expect(base.p1Count, 2);
        expect(base.p2Count, 3);
        expect(base.p3Count, 4);
      });

      test('default to zero when a priority key is missing', () {
        const sparse = ReviewVerdict(
          overall: ReviewVerdictOverall.ship,
          confidence: 1.0,
          explanation: '',
          counts: {},
        );
        expect(sparse.p0Count, 0);
        expect(sparse.p1Count, 0);
        expect(sparse.p2Count, 0);
        expect(sparse.p3Count, 0);
      });
    });

    test('blockingAxes returns the gated, non-clearing axis results', () {
      const verdict = ReviewVerdict(
        overall: ReviewVerdictOverall.ship,
        confidence: 1.0,
        explanation: '',
        counts: {},
        axisResults: [
          ReviewAxisResult(
            axis: ReviewAxis.security,
            verdict: ReviewAxisVerdict.fail,
            findingsCount: 1,
            gated: true,
            confidence: 0.9,
          ),
          ReviewAxisResult(
            axis: ReviewAxis.correctness,
            verdict: ReviewAxisVerdict.pass,
            findingsCount: 0,
            gated: true,
            confidence: 1.0,
          ),
          ReviewAxisResult(
            axis: ReviewAxis.performance,
            verdict: ReviewAxisVerdict.fail,
            findingsCount: 1,
            gated: false,
            confidence: 1.0,
          ),
        ],
      );
      expect(verdict.blockingAxes.length, 1);
      expect(verdict.blockingAxes.single.axis, ReviewAxis.security);
    });

    group('withAxisResults', () {
      test('upgrades ship to block on a gated fail', () {
        final next = base.withAxisResults(const [
          ReviewAxisResult(
            axis: ReviewAxis.security,
            verdict: ReviewAxisVerdict.fail,
            findingsCount: 1,
            gated: true,
            confidence: 0.9,
          ),
        ]);
        expect(next.overall, ReviewVerdictOverall.block);
        expect(next.axisResults, hasLength(1));
        // confidence / explanation / counts are preserved.
        expect(next.confidence, base.confidence);
        expect(next.explanation, base.explanation);
        expect(next.counts, base.counts);
      });

      test('upgrades ship to hold on a gated unavailable axis', () {
        final next = base.withAxisResults(const [
          ReviewAxisResult(
            axis: ReviewAxis.visual,
            verdict: ReviewAxisVerdict.unavailable,
            findingsCount: 0,
            gated: true,
            confidence: 1.0,
          ),
        ]);
        expect(next.overall, ReviewVerdictOverall.hold);
      });

      test('upgrades ship to hold on a gated partial axis', () {
        final next = base.withAxisResults(const [
          ReviewAxisResult(
            axis: ReviewAxis.visual,
            verdict: ReviewAxisVerdict.partial,
            findingsCount: 0,
            gated: true,
            confidence: 1.0,
          ),
        ]);
        expect(next.overall, ReviewVerdictOverall.hold);
      });

      test('does not downgrade an existing hold on a gated partial axis', () {
        const hold = ReviewVerdict(
          overall: ReviewVerdictOverall.hold,
          confidence: 1.0,
          explanation: '',
          counts: {},
        );
        final next = hold.withAxisResults(const [
          ReviewAxisResult(
            axis: ReviewAxis.visual,
            verdict: ReviewAxisVerdict.partial,
            findingsCount: 0,
            gated: true,
            confidence: 1.0,
          ),
        ]);
        expect(next.overall, ReviewVerdictOverall.hold);
      });

      test('leaves ship unchanged when every gated axis clears the gate', () {
        final next = base.withAxisResults(const [
          ReviewAxisResult(
            axis: ReviewAxis.security,
            verdict: ReviewAxisVerdict.pass,
            findingsCount: 0,
            gated: true,
            confidence: 1.0,
          ),
          // A non-gated axis must never affect the verdict even on fail.
          ReviewAxisResult(
            axis: ReviewAxis.performance,
            verdict: ReviewAxisVerdict.fail,
            findingsCount: 9,
            gated: false,
            confidence: 1.0,
          ),
        ]);
        expect(next.overall, ReviewVerdictOverall.ship);
      });

      test('with empty axis results preserves the overall verdict', () {
        expect(
          base.withAxisResults(const []).overall,
          ReviewVerdictOverall.ship,
        );
      });
    });

    group('toMetadata', () {
      test(
        'serializes overall, confidence, explanation and priority counts',
        () {
          final meta = base.toMetadata();
          expect(meta['verdict'], 'ship');
          expect(meta['verdictConfidence'], 0.9);
          expect(meta['verdictExplanation'], 'looks fine');
          expect(meta['priorityCounts'], {'p0': 0, 'p1': 2, 'p2': 3, 'p3': 4});
          // No axis results -> key omitted.
          expect(meta.containsKey('axisResults'), isFalse);
        },
      );

      test('emits every overall string', () {
        for (final pair in <(ReviewVerdictOverall, String)>[
          (ReviewVerdictOverall.ship, 'ship'),
          (ReviewVerdictOverall.hold, 'hold'),
          (ReviewVerdictOverall.block, 'block'),
        ]) {
          final v = ReviewVerdict(
            overall: pair.$1,
            confidence: 1.0,
            explanation: '',
            counts: const {},
          );
          expect(v.toMetadata()['verdict'], pair.$2);
        }
      });

      test('serializes axisResults when present', () {
        const verdict = ReviewVerdict(
          overall: ReviewVerdictOverall.ship,
          confidence: 1.0,
          explanation: '',
          counts: {},
          axisResults: [
            ReviewAxisResult(
              axis: ReviewAxis.security,
              verdict: ReviewAxisVerdict.warn,
              findingsCount: 2,
              gated: true,
              confidence: 0.8,
              note: 'minor',
            ),
          ],
        );
        final meta = verdict.toMetadata();
        expect(meta['axisResults'], isA<List>());
        final axisMap = (meta['axisResults'] as List).single as Map;
        expect(axisMap['axis'], 'security');
        expect(axisMap['verdict'], 'warn');
      });
    });

    group('fromMetadata', () {
      test('returns null when meta is null', () {
        expect(ReviewVerdict.fromMetadata(null), isNull);
      });

      test('returns null when the verdict key is missing', () {
        expect(ReviewVerdict.fromMetadata(const {}), isNull);
      });

      test('returns null when the verdict is not a string', () {
        expect(ReviewVerdict.fromMetadata(const {'verdict': 3}), isNull);
      });

      test('returns null for an unrecognized verdict string', () {
        expect(ReviewVerdict.fromMetadata(const {'verdict': 'frozen'}), isNull);
      });

      test('parses each recognized verdict with sensible defaults', () {
        for (final overall in ReviewVerdictOverall.values) {
          final v = ReviewVerdict.fromMetadata({'verdict': overall.name})!;
          expect(v.overall, overall);
          // Defaults: confidence 1.0, empty explanation, zeroed counts.
          expect(v.confidence, 1.0);
          expect(v.explanation, '');
          expect(v.p0Count, 0);
          expect(v.p1Count, 0);
          expect(v.p2Count, 0);
          expect(v.p3Count, 0);
          expect(v.axisResults, isEmpty);
        }
      });

      test('parses confidence, explanation and priority counts', () {
        final v = ReviewVerdict.fromMetadata({
          'verdict': 'hold',
          'verdictConfidence': 0.6,
          'verdictExplanation': 'be careful',
          'priorityCounts': {'p0': 1, 'p1': 2, 'p2': 3, 'p3': 4},
        })!;
        expect(v.overall, ReviewVerdictOverall.hold);
        expect(v.confidence, 0.6);
        expect(v.explanation, 'be careful');
        expect(v.p0Count, 1);
        expect(v.p1Count, 2);
        expect(v.p2Count, 3);
        expect(v.p3Count, 4);
      });

      test('defaults confidence to 1.0 when missing or out of range', () {
        final missing = ReviewVerdict.fromMetadata(const {'verdict': 'ship'})!;
        expect(missing.confidence, 1.0);

        final tooLow = ReviewVerdict.fromMetadata(const {
          'verdict': 'ship',
          'verdictConfidence': -1.0,
        })!;
        expect(tooLow.confidence, 1.0);

        final tooHigh = ReviewVerdict.fromMetadata(const {
          'verdict': 'ship',
          'verdictConfidence': 5.0,
        })!;
        expect(tooHigh.confidence, 1.0);

        final notNum = ReviewVerdict.fromMetadata(const {
          'verdict': 'ship',
          'verdictConfidence': 'high',
        })!;
        expect(notNum.confidence, 1.0);
      });

      test('defaults confidence to 1.0 when NaN', () {
        final v = ReviewVerdict.fromMetadata({
          'verdict': 'ship',
          'verdictConfidence': double.nan,
        })!;
        expect(v.confidence, 1.0);
      });

      test('falls back to empty explanation when not a string', () {
        final v = ReviewVerdict.fromMetadata(const {
          'verdict': 'ship',
          'verdictExplanation': 5,
        })!;
        expect(v.explanation, '');
      });

      test(
        'falls back to zero counts when priorityCounts is missing or not a map',
        () {
          final missing = ReviewVerdict.fromMetadata(const {
            'verdict': 'ship',
          })!;
          expect(missing.p0Count, 0);

          final notMap = ReviewVerdict.fromMetadata(const {
            'verdict': 'ship',
            'priorityCounts': 'nope',
          })!;
          expect(notMap.p0Count, 0);
        },
      );

      test('defaults missing count entries to zero', () {
        final v = ReviewVerdict.fromMetadata({
          'verdict': 'ship',
          'priorityCounts': {'p1': 7},
        })!;
        expect(v.p0Count, 0);
        expect(v.p1Count, 7);
        expect(v.p2Count, 0);
        expect(v.p3Count, 0);
      });

      test('parses nested axis results', () {
        final v = ReviewVerdict.fromMetadata({
          'verdict': 'ship',
          'axisResults': [
            {
              'axis': 'security',
              'verdict': 'warn',
              'findingsCount': 2,
              'gated': true,
              'confidence': 0.8,
              'note': 'minor',
            },
          ],
        })!;
        expect(v.axisResults, hasLength(1));
        expect(v.axisResults.single.axis, ReviewAxis.security);
        expect(v.axisResults.single.verdict, ReviewAxisVerdict.warn);
      });

      test('ignores non-map axis result entries', () {
        final v = ReviewVerdict.fromMetadata({
          'verdict': 'ship',
          'axisResults': ['junk', 1],
        })!;
        expect(v.axisResults, isEmpty);
      });
    });

    group('equality', () {
      test('equal verdicts are equal by value and hash', () {
        final other = ReviewVerdict(
          overall: ReviewVerdictOverall.ship,
          confidence: 0.9,
          explanation: 'looks fine',
          counts: counts(p0: 0, p1: 2, p2: 3, p3: 4),
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differs when any field differs', () {
        expect(
          ReviewVerdict(
            overall: ReviewVerdictOverall.block,
            confidence: 0.9,
            explanation: 'looks fine',
            counts: counts(p1: 2, p2: 3, p3: 4),
          ),
          isNot(base),
        );
        expect(
          ReviewVerdict(
            overall: ReviewVerdictOverall.ship,
            confidence: 0.5,
            explanation: 'looks fine',
            counts: counts(p1: 2, p2: 3, p3: 4),
          ),
          isNot(base),
        );
        expect(
          ReviewVerdict(
            overall: ReviewVerdictOverall.ship,
            confidence: 0.9,
            explanation: 'different',
            counts: counts(p1: 2, p2: 3, p3: 4),
          ),
          isNot(base),
        );
        expect(
          ReviewVerdict(
            overall: ReviewVerdictOverall.ship,
            confidence: 0.9,
            explanation: 'looks fine',
            counts: counts(p0: 1, p1: 2, p2: 3, p3: 4),
          ),
          isNot(base),
        );
        expect(
          ReviewVerdict(
            overall: ReviewVerdictOverall.ship,
            confidence: 0.9,
            explanation: 'looks fine',
            counts: counts(p1: 2, p2: 3, p3: 4),
            axisResults: const [
              ReviewAxisResult(
                axis: ReviewAxis.security,
                verdict: ReviewAxisVerdict.pass,
                findingsCount: 0,
                gated: true,
                confidence: 1.0,
              ),
            ],
          ),
          isNot(base),
        );
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('string'));
      });
    });
  });
}
