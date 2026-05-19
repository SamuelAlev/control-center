import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/detect_pr_notifiable_transitions.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/evaluate_pr_merge_readiness.dart';
import 'package:test/test.dart';

/// One PR's wire entry, in the shape `pullRequestToWire` writes.
Map<String, dynamic> wire({
  String state = 'open',
  bool isDraft = false,
  String author = 'me',
  PrChecksStatus checks = PrChecksStatus.passing,
  PrReviewDecision decision = PrReviewDecision.approved,
  PrMergeableState mergeable = PrMergeableState.unrecognized,
  List<String> requestedReviewers = const [],
  List<String> requestedTeams = const [],
  String headSha = 'aaa',
}) => {
  'number': 1,
  'title': 'A pull request',
  'state': state,
  'is_draft': isDraft,
  'author': {'login': author},
  'checks_status': checks.name,
  'review_decision': decision.name,
  'mergeable_state': mergeable.name,
  'requested_reviewers': [for (final r in requestedReviewers) {'login': r}],
  'requested_team_slugs': requestedTeams,
  'head_sha': headSha,
};

List<PrTransition> transitions(
  Map<String, dynamic>? before,
  Map<String, dynamic> after,
) => detectPrNotifiableTransitions(
  before: before == null ? null : PrNotifiableState.fromWire(before),
  after: PrNotifiableState.fromWire(after),
);

void main() {
  group('baseline', () {
    test('a null before publishes nothing', () {
      // A server meeting a repo for the first time must not announce its
      // whole backlog.
      expect(transitions(null, wire()), isEmpty);
    });

    test('an identical repeat publishes nothing', () {
      expect(transitions(wire(), wire()), isEmpty);
    });

    test('a closed pull request publishes nothing', () {
      expect(
        transitions(
          wire(checks: PrChecksStatus.passing),
          wire(state: 'closed', checks: PrChecksStatus.failing),
        ),
        isEmpty,
      );
    });
  });

  group('checks', () {
    test('passing to failing fires once', () {
      final result = transitions(
        wire(checks: PrChecksStatus.passing),
        wire(checks: PrChecksStatus.failing),
      );
      expect(result.whereType<PrChecksFailed>(), hasLength(1));
    });

    test('failing to failing does not re-fire', () {
      expect(
        transitions(
          wire(checks: PrChecksStatus.failing),
          wire(checks: PrChecksStatus.failing),
        ).whereType<PrChecksFailed>(),
        isEmpty,
      );
    });

    test('none and pending both count as entering failure', () {
      for (final from in [PrChecksStatus.none, PrChecksStatus.pending]) {
        expect(
          transitions(
            wire(checks: from),
            wire(checks: PrChecksStatus.failing),
          ).whereType<PrChecksFailed>(),
          hasLength(1),
          reason: 'from $from',
        );
      }
    });

    test('failing to passing is recovery', () {
      expect(
        transitions(
          wire(checks: PrChecksStatus.failing),
          wire(checks: PrChecksStatus.passing),
        ).whereType<PrChecksRecovered>(),
        hasLength(1),
      );
    });

    test('failing to pending is NOT recovery — a re-run starting is not news', () {
      final result = transitions(
        wire(checks: PrChecksStatus.failing),
        wire(checks: PrChecksStatus.pending),
      );
      expect(result.whereType<PrChecksRecovered>(), isEmpty);
      expect(result.whereType<PrChecksFailed>(), isEmpty);
    });
  });

  group('review decision', () {
    test('into approved fires PrWasApproved', () {
      final result = transitions(
        wire(decision: PrReviewDecision.reviewRequired),
        wire(decision: PrReviewDecision.approved),
      );
      expect(result.whereType<PrWasApproved>(), hasLength(1));
    });

    test('into changesRequested fires PrChangesRequested', () {
      expect(
        transitions(
          wire(decision: PrReviewDecision.reviewRequired),
          wire(decision: PrReviewDecision.changesRequested),
        ).whereType<PrChangesRequested>(),
        hasLength(1),
      );
    });

    test('approved back to reviewRequired is a dismissal', () {
      expect(
        transitions(
          wire(decision: PrReviewDecision.approved),
          wire(decision: PrReviewDecision.reviewRequired),
        ).whereType<PrReviewDismissed>(),
        hasLength(1),
      );
    });

    test('reviewRequired arrived at any other way is not a dismissal', () {
      expect(
        transitions(
          wire(decision: PrReviewDecision.none),
          wire(decision: PrReviewDecision.reviewRequired),
        ).whereType<PrReviewDismissed>(),
        isEmpty,
      );
    });

    test('an unchanged decision fires nothing', () {
      expect(
        transitions(
          wire(decision: PrReviewDecision.approved),
          wire(decision: PrReviewDecision.approved),
        ).whereType<PrWasApproved>(),
        isEmpty,
      );
    });
  });

  group('approver attribution and the remaining count', () {
    test('the single reviewer who left the requested set is the approver', () {
      final result = transitions(
        wire(
          decision: PrReviewDecision.reviewRequired,
          requestedReviewers: ['octocat', 'hubot'],
        ),
        wire(
          decision: PrReviewDecision.approved,
          requestedReviewers: ['hubot'],
        ),
      ).whereType<PrWasApproved>().single;
      expect(result.approverLogin, 'octocat');
      expect(result.reviewersRemaining, 1);
    });

    test('two reviewers leaving at once is not attributed', () {
      // Guessing between two logins is worse than not naming one.
      final result = transitions(
        wire(
          decision: PrReviewDecision.reviewRequired,
          requestedReviewers: ['octocat', 'hubot'],
        ),
        wire(decision: PrReviewDecision.approved),
      ).whereType<PrWasApproved>().single;
      expect(result.approverLogin, isNull);
      expect(result.reviewersRemaining, 0);
    });

    test('an approval by someone never requested is not attributed', () {
      final result = transitions(
        wire(decision: PrReviewDecision.reviewRequired),
        wire(decision: PrReviewDecision.approved),
      ).whereType<PrWasApproved>().single;
      expect(result.approverLogin, isNull);
    });

    test('outstanding teams count toward reviewersRemaining', () {
      final result = transitions(
        wire(decision: PrReviewDecision.reviewRequired),
        wire(
          decision: PrReviewDecision.approved,
          requestedReviewers: ['hubot'],
          requestedTeams: ['platform'],
        ),
      ).whereType<PrWasApproved>().single;
      expect(result.reviewersRemaining, 2);
    });
  });

  group('merge readiness', () {
    test('becoming ready fires once', () {
      final result = transitions(
        wire(decision: PrReviewDecision.reviewRequired),
        wire(decision: PrReviewDecision.approved),
      );
      expect(result.whereType<PrBecameReadyToMerge>(), hasLength(1));
    });

    test('staying ready does not re-fire', () {
      expect(
        transitions(wire(), wire()).whereType<PrBecameReadyToMerge>(),
        isEmpty,
      );
    });

    test('becoming blocked carries the reason', () {
      final result = transitions(
        wire(),
        wire(mergeable: PrMergeableState.dirty),
      ).whereType<PrBecameBlocked>().single;
      expect(result.reason, PrBlockReason.conflicts);
    });

    test('a confirmed clean verdict on an already-ready PR is not news', () {
      // The poller folds a confirmation into the same evaluation; it must not
      // read as a second edge.
      expect(
        transitions(
          wire(),
          wire(mergeable: PrMergeableState.clean),
        ).whereType<PrBecameReadyToMerge>(),
        isEmpty,
      );
    });

    test('a draft going green is blocked, never ready', () {
      final result = transitions(
        wire(isDraft: true, decision: PrReviewDecision.reviewRequired),
        wire(isDraft: true),
      );
      expect(result.whereType<PrBecameReadyToMerge>(), isEmpty);
    });

    test('marking a ready PR as draft blocks it', () {
      final result = transitions(
        wire(),
        wire(isDraft: true),
      ).whereType<PrBecameBlocked>().single;
      expect(result.reason, PrBlockReason.draft);
    });
  });

  group('fromWire tolerates an older snapshot', () {
    test('a wire map with no fields at all reads as neutral', () {
      final state = PrNotifiableState.fromWire(const {});
      expect(state.checksStatus, PrChecksStatus.none);
      expect(state.reviewDecision, PrReviewDecision.none);
      expect(state.mergeableState, PrMergeableState.unrecognized);
      expect(state.authorLogin, '');
      expect(state.headSha, '');
      expect(state.isOpen, isTrue);
    });

    test('an upgrade from a snapshot with no decision does not fire', () {
      // The first pass after an upgrade must not announce every PR.
      final before = wire()..remove('review_decision');
      expect(
        transitions(before, wire(decision: PrReviewDecision.none)),
        isEmpty,
      );
    });
  });
}
