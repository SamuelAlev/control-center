import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewWalkthroughSummary', () {
    test('round-trips through metadata', () {
      const summary = ReviewWalkthroughSummary(
        headline: 'Adds token refresh',
        areas: [
          ReviewWalkthroughArea(
            cohortKey: 'auth',
            title: 'Auth flow',
            bullets: ['New refresh endpoint', 'Rotates on use'],
          ),
        ],
        riskNotes: ['Refresh token now long-lived'],
        headSha: 'abc123',
      );

      final parsed = ReviewWalkthroughSummary.fromMetadata(
        summary.toMetadata(),
      );

      expect(parsed, summary);
      expect(parsed!.isAbsent, isFalse);
    });

    test('parses to null for legacy summaries without structured keys', () {
      expect(
        ReviewWalkthroughSummary.fromMetadata({
          'verdict': 'ship',
          'priorityCounts': {'p0': 0},
        }),
        isNull,
      );
      expect(ReviewWalkthroughSummary.fromMetadata(null), isNull);
    });

    test('drops malformed areas but keeps the parseable ones', () {
      final parsed = ReviewWalkthroughSummary.fromMetadata({
        'summaryHeadline': 'headline',
        'summaryAreas': [
          {
            'cohortKey': 'auth',
            'title': 'Auth',
            'bullets': ['b'],
          },
          {'title': 'no cohort key — dropped'},
          'not a map',
        ],
        'summaryRisks': ['r1', 42],
      });

      expect(parsed!.areas, hasLength(1));
      expect(parsed.areas.single.cohortKey, 'auth');
      expect(parsed.riskNotes, ['r1']);
    });

    test('isAbsent when there is neither headline nor areas', () {
      const empty = ReviewWalkthroughSummary(headline: '');
      expect(empty.isAbsent, isTrue);
      expect(empty.toMetadata(), isEmpty);
    });

    test('copyWith can override headSha', () {
      const base = ReviewWalkthroughSummary(headline: 'h', headSha: null);
      expect(base.copyWith(headSha: 'sha1').headSha, 'sha1');
      expect(base.copyWith(headSha: null).headSha, isNull);
      expect(base.headSha, isNull);
    });
  });
}
