import 'package:cc_domain/features/pr_review/domain/services/finding_cohort_router.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

ReviewCohort _cohort(String key, List<String> files, {int impact = 1}) =>
    ReviewCohort(
      id: 'id-$key',
      workspaceId: 'ws',
      prExternalId: 'pr',
      cohortKey: key,
      title: key,
      orderIndex: 0,
      impactScore: impact,
      filePaths: files,
    );

ReviewNodePayload _payload({
  String? cohortKey,
  String? filePath,
  ReviewNodePriority priority = ReviewNodePriority.p2,
}) => ReviewNodePayload(
  kind: ReviewNodeKind.bug,
  priority: priority,
  confidence: 0.8,
  anchor: ReviewNodeAnchor(filePath: filePath),
  status: ReviewNodeStatus.open,
  cohortKey: cohortKey,
);

void main() {
  const router = FindingCohortRouter();

  group('FindingCohortRouter', () {
    test('routes by the stamped cohort key first', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart']),
          _cohort('billing', ['lib/b.dart']),
        ],
        findings: [
          (
            message: 'm1',
            payload: _payload(cohortKey: 'billing', filePath: 'lib/a.dart'),
          ),
        ],
        payloadOf: (f) => f.payload,
      );

      expect(routing.areas.first.cohort.cohortKey, 'auth');
      expect(routing.areas.first.isEmpty, isTrue);
      expect(routing.areas.last.findings, hasLength(1));
      expect(routing.repositoryWide, isEmpty);
    });

    test('falls back to the anchor file when no key is stamped', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart', 'lib/a2.dart']),
        ],
        findings: [(message: 'm1', payload: _payload(filePath: 'lib/a2.dart'))],
        payloadOf: (f) => f.payload,
      );

      expect(routing.areas.single.findings, hasLength(1));
    });

    test('a stale stamped key falls through to the anchor file', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart']),
        ],
        findings: [
          (
            message: 'm1',
            payload: _payload(cohortKey: 'gone-key', filePath: 'lib/a.dart'),
          ),
        ],
        payloadOf: (f) => f.payload,
      );

      expect(routing.areas.single.findings, hasLength(1));
      expect(routing.repositoryWide, isEmpty);
    });

    test(
      'unanchored findings with no matching key go to the repo-wide bucket',
      () {
        final routing = router.route(
          cohorts: [
            _cohort('auth', ['lib/a.dart']),
          ],
          findings: [
            (message: 'm1', payload: _payload(cohortKey: 'gone')),
            (message: 'm2', payload: _payload()),
          ],
          payloadOf: (f) => f.payload,
        );

        expect(routing.repositoryWide, hasLength(2));
        expect(routing.totalFindings, 2);
      },
    );

    test('cohorts with zero findings are still present as areas', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart']),
          _cohort('billing', ['lib/b.dart']),
        ],
        findings: const <({String message, ReviewNodePayload payload})>[],
        payloadOf: (f) => f.payload,
      );

      expect(routing.areas, hasLength(2));
      expect(routing.areas.every((a) => a.isEmpty), isTrue);
    });

    test('aggregates count by priority and compute the worst priority', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart']),
        ],
        findings: [
          (
            message: 'm1',
            payload: _payload(
              filePath: 'lib/a.dart',
              priority: ReviewNodePriority.p1,
            ),
          ),
          (
            message: 'm2',
            payload: _payload(
              filePath: 'lib/a.dart',
              priority: ReviewNodePriority.p3,
            ),
          ),
          (
            message: 'm3',
            payload: _payload(
              filePath: 'lib/a.dart',
              priority: ReviewNodePriority.p0,
            ),
          ),
        ],
        payloadOf: (f) => f.payload,
      );
      final area = routing.areas.single;

      expect(area.p0Count, 1);
      expect(area.p1Count, 1);
      expect(area.p2Count, 0);
      expect(area.p3Count, 1);
      expect(area.worstPriority, ReviewNodePriority.p0);
    });

    test('worstPriority is null for an empty area', () {
      final routing = router.route(
        cohorts: [
          _cohort('auth', ['lib/a.dart']),
        ],
        findings: const <({String message, ReviewNodePayload payload})>[],
        payloadOf: (f) => f.payload,
      );

      expect(routing.areas.single.worstPriority, isNull);
    });
  });
}
