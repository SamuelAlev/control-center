// Finding→cohort routing: the join that makes Findings and Studio ONE review.
//
// Findings live as `review_node` space messages; areas live as
// deterministic `ReviewCohort` rows. This pure service joins them so every
// consumer (the Review Hub UI, the finalizer's summary, the GitHub
// publisher) routes findings into areas by the SAME rules:
//
//   1. the finding's stamped `cohortKey` (exact match), else
//   2. the finding's anchor file (a member of the cohort's `filePaths`), else
//   3. the repository-wide bucket (unanchored notes, stale keys).
//
// Generic over the finding representation so the client can pass its
// `(message, payload)` records and the server its raw payloads alike.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_cohort.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// One cohort plus the findings routed into it, with priority aggregates for
/// badges and ordering.
class CohortFindings<T> {
  /// Creates a [CohortFindings]. Constructed by [FindingCohortRouter.route];
  /// [payloadOf] is how the aggregates read each finding's typed payload.
  const CohortFindings({
    required this.cohort,
    required this.findings,
    required ReviewNodePayload Function(T finding) payloadOf,
  }) : _payloadOf = payloadOf;

  /// The area (deterministic cohort) the findings were routed into.
  final ReviewCohort cohort;

  /// The findings belonging to this cohort, in the caller's order (callers
  /// typically pass findings already sorted by priority/status/recency).
  final List<T> findings;

  final ReviewNodePayload Function(T finding) _payloadOf;

  /// Whether no finding routed into this cohort.
  bool get isEmpty => findings.isEmpty;

  /// Number of findings matching [test].
  int countWhere(bool Function(ReviewNodePayload payload) test) {
    var count = 0;
    for (final f in findings) {
      if (test(_payloadOf(f))) {
        count++;
      }
    }
    return count;
  }

  /// Number of P0 findings.
  int get p0Count => countWhere((p) => p.priority == ReviewNodePriority.p0);

  /// Number of P1 findings.
  int get p1Count => countWhere((p) => p.priority == ReviewNodePriority.p1);

  /// Number of P2 findings.
  int get p2Count => countWhere((p) => p.priority == ReviewNodePriority.p2);

  /// Number of P3 findings.
  int get p3Count => countWhere((p) => p.priority == ReviewNodePriority.p3);

  /// The most severe priority among this cohort's findings, or null when
  /// empty. `p0` is the most severe (lowest enum index).
  ReviewNodePriority? get worstPriority {
    ReviewNodePriority? worst;
    for (final f in findings) {
      final p = _payloadOf(f).priority;
      if (worst == null || p.index < worst.index) {
        worst = p;
      }
    }
    return worst;
  }
}

/// The full routing result: per-cohort findings plus the repository-wide
/// bucket for findings that match no area.
class FindingCohortRouting<T> {
  /// Creates a [FindingCohortRouting].
  const FindingCohortRouting({
    required this.areas,
    required this.repositoryWide,
  });

  /// One entry per cohort, in the cohort order given to the router (the
  /// deterministic reading/impact order). Cohorts with zero findings are
  /// included — the area still exists for the deep dive.
  final List<CohortFindings<T>> areas;

  /// Findings that matched no cohort (repository-wide notes, stale keys with
  /// no anchor fallback).
  final List<T> repositoryWide;

  /// Total findings routed anywhere (areas + repository-wide).
  int get totalFindings =>
      repositoryWide.length +
      areas.fold(0, (sum, a) => sum + a.findings.length);
}

/// Routes findings into semantic cohorts (areas).
///
/// Pure and deterministic: same cohorts + findings in, same routing out. The
/// caller owns filtering (dismissed/resolved toggles) and sorting.
class FindingCohortRouter {
  /// Creates a [FindingCohortRouter].
  const FindingCohortRouter();

  /// Routes [findings] into [cohorts]. [payloadOf] extracts each finding's
  /// typed payload (callers pass parsed `ReviewNodePayload`s; malformed
  /// findings should be filtered before routing).
  FindingCohortRouting<T> route<T>({
    required List<ReviewCohort> cohorts,
    required Iterable<T> findings,
    required ReviewNodePayload Function(T finding) payloadOf,
  }) {
    final byKey = {for (final c in cohorts) c.cohortKey: c};
    final byPath = <String, ReviewCohort>{};
    for (final c in cohorts) {
      for (final path in c.filePaths) {
        // Cohorts are disjoint by construction (union-find), but a path-
        // fallback regeneration could transiently overlap — first wins.
        byPath.putIfAbsent(path, () => c);
      }
    }

    final routed = {for (final c in cohorts) c.cohortKey: <T>[]};
    final repositoryWide = <T>[];
    for (final finding in findings) {
      final payload = payloadOf(finding);
      ReviewCohort? target;
      final stampedKey = payload.cohortKey;
      if (stampedKey != null) {
        target = byKey[stampedKey];
      }
      // A stamped key that no longer matches (stale from a previous push)
      // falls through to the anchor file rather than vanishing.
      target ??= payload.anchor.filePath == null
          ? null
          : byPath[payload.anchor.filePath];
      if (target == null) {
        repositoryWide.add(finding);
      } else {
        routed[target.cohortKey]!.add(finding);
      }
    }

    return FindingCohortRouting<T>(
      areas: [
        for (final c in cohorts)
          CohortFindings<T>(
            cohort: c,
            findings: routed[c.cohortKey] ?? const [],
            payloadOf: payloadOf,
          ),
      ],
      repositoryWide: repositoryWide,
    );
  }
}
