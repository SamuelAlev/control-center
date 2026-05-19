import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:test/test.dart';

/// Exercises [ReviewCohort] and [CohortLayer]: JSON round-trips, copyWith,
/// equality and the construction asserts.
void main() {
  group('CohortDerivation', () {
    test('fromName parses known values', () {
      expect(CohortDerivation.fromName('graph'), CohortDerivation.graph);
      expect(CohortDerivation.fromName('path'), CohortDerivation.path);
    });

    test('fromName defaults to path for unknown/null', () {
      expect(CohortDerivation.fromName('bogus'), CohortDerivation.path);
      expect(CohortDerivation.fromName(null), CohortDerivation.path);
    });
  });

  group('CohortLayer', () {
    CohortLayer layer() => const CohortLayer(
      title: 'Token refresh',
      filePath: 'lib/auth.dart',
      startLine: 10,
      endLine: 20,
      summaryMarkdown: 'refresh logic',
    );

    test('hasRange is true when startLine is set', () {
      expect(layer().hasRange, isTrue);
      expect(const CohortLayer(title: 't', filePath: 'f').hasRange, isFalse);
    });

    test('fromJson + toJson round-trip', () {
      final l = layer();
      expect(CohortLayer.fromJson(l.toJson()), l);
    });

    test('fromJson tolerates missing fields', () {
      final l = CohortLayer.fromJson({});
      expect(l.title, '');
      expect(l.filePath, '');
    });

    test('equality and hashCode', () {
      expect(layer(), layer());
      expect(layer().hashCode, layer().hashCode);
    });

    test('unequal when filePath differs', () {
      expect(
        const CohortLayer(title: 't', filePath: 'a'),
        isNot(const CohortLayer(title: 't', filePath: 'b')),
      );
    });
  });

  group('ReviewCohort', () {
    ReviewCohort cohort() => const ReviewCohort(
      id: 'c-1',
      workspaceId: 'ws-1',
      prExternalId: 'pr-1',
      cohortKey: 'auth',
      title: 'Auth flow',
      orderIndex: 0,
      impactScore: 5,
      summaryMarkdown: 'summary',
      derivation: CohortDerivation.graph,
      filePaths: ['lib/auth.dart'],
      layers: [CohortLayer(title: 'L', filePath: 'f')],
    );

    test('asserts cohortKey is non-empty', () {
      expect(
        () => ReviewCohort(
          id: 'c',
          workspaceId: 'ws',
          prExternalId: 'pr',
          cohortKey: '',
          title: 't',
          orderIndex: 0,
          impactScore: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts impactScore is non-negative', () {
      expect(
        () => ReviewCohort(
          id: 'c',
          workspaceId: 'ws',
          prExternalId: 'pr',
          cohortKey: 'k',
          title: 't',
          orderIndex: 0,
          impactScore: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isPathDerived reflects derivation', () {
      expect(cohort().isPathDerived, isFalse);
      expect(
        const ReviewCohort(
          id: 'c',
          workspaceId: 'ws',
          prExternalId: 'pr',
          cohortKey: 'k',
          title: 't',
          orderIndex: 0,
          impactScore: 0,
          derivation: CohortDerivation.path,
        ).isPathDerived,
        isTrue,
      );
    });

    test('fromJson + toJson round-trip', () {
      final c = cohort();
      expect(ReviewCohort.fromJson(c.toJson()), c);
    });

    test('fromJson tolerates missing fields with safe defaults', () {
      // cohortKey must be non-empty (assert); other fields default.
      final c = ReviewCohort.fromJson({'cohortKey': 'k'});
      expect(c.id, '');
      expect(c.orderIndex, 0);
      expect(c.impactScore, 0);
      expect(c.derivation, CohortDerivation.path);
      expect(c.filePaths, isEmpty);
      expect(c.layers, isEmpty);
    });

    test('copyWith preserves unchanged fields', () {
      final c = cohort();
      final next = c.copyWith(title: 'New title');
      expect(next.title, 'New title');
      expect(next.cohortKey, c.cohortKey);
      expect(next.workspaceId, c.workspaceId);
      expect(next.filePaths, c.filePaths);
    });

    test('equality and hashCode', () {
      expect(cohort(), cohort());
      expect(cohort().hashCode, cohort().hashCode);
    });

    test('unequal when orderIndex differs', () {
      expect(
        cohort(),
        isNot(
          const ReviewCohort(
            id: 'c-1',
            workspaceId: 'ws-1',
            prExternalId: 'pr-1',
            cohortKey: 'auth',
            title: 'Auth flow',
            orderIndex: 1,
            impactScore: 5,
          ),
        ),
      );
    });
  });
}
