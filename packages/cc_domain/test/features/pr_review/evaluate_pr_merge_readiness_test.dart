import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/evaluate_pr_merge_readiness.dart';
import 'package:test/test.dart';

({PrMergeReadiness readiness, PrBlockReason reason}) evaluate({
  bool isDraft = false,
  PrMergeableState mergeableState = PrMergeableState.unrecognized,
  PrReviewDecision reviewDecision = PrReviewDecision.approved,
  PrChecksStatus checksStatus = PrChecksStatus.passing,
  List<String> requestedReviewerLogins = const [],
  List<String> requestedTeamSlugs = const [],
  List<String> approvedLogins = const [],
}) => evaluatePrMergeReadiness(
  isDraft: isDraft,
  mergeableState: mergeableState,
  reviewDecision: reviewDecision,
  checksStatus: checksStatus,
  requestedReviewerLogins: requestedReviewerLogins,
  requestedTeamSlugs: requestedTeamSlugs,
  approvedLogins: approvedLogins,
);

void main() {
  group('draft', () {
    test('a draft is blocked no matter how green it is', () {
      // The whole point of the check: without it every green draft would fire
      // a "ready to merge" notification.
      final result = evaluate(
        isDraft: true,
        mergeableState: PrMergeableState.clean,
      );
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.draft);
    });

    test('draft beats every forge verdict', () {
      for (final state in PrMergeableState.values) {
        expect(
          evaluate(isDraft: true, mergeableState: state).readiness,
          PrMergeReadiness.blocked,
          reason: 'draft with mergeableState $state',
        );
      }
    });
  });

  group('the forge verdict wins when it has one', () {
    test('clean is ready even with a red check and an unapproved reviewer', () {
      final result = evaluate(
        mergeableState: PrMergeableState.clean,
        checksStatus: PrChecksStatus.failing,
        reviewDecision: PrReviewDecision.reviewRequired,
      );
      expect(result.readiness, PrMergeReadiness.ready);
      expect(result.reason, PrBlockReason.none);
    });

    test('hasHooks is ready', () {
      expect(
        evaluate(mergeableState: PrMergeableState.hasHooks).readiness,
        PrMergeReadiness.ready,
      );
    });

    test('unstable is pending, not blocked — the forge allows that merge', () {
      final result = evaluate(
        mergeableState: PrMergeableState.unstable,
        checksStatus: PrChecksStatus.failing,
      );
      expect(result.readiness, PrMergeReadiness.pending);
      expect(result.reason, PrBlockReason.none);
    });

    test('dirty names conflicts', () {
      final result = evaluate(mergeableState: PrMergeableState.dirty);
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.conflicts);
    });

    test('behind names behind', () {
      final result = evaluate(mergeableState: PrMergeableState.behind);
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.behind);
    });

    test('blocked borrows a nameable reason from the local signals', () {
      final result = evaluate(
        mergeableState: PrMergeableState.blocked,
        checksStatus: PrChecksStatus.failing,
      );
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.checksFailing);
    });

    test('blocked with nothing locally wrong reports forgeBlocked', () {
      final result = evaluate(mergeableState: PrMergeableState.blocked);
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.forgeBlocked);
    });
  });

  group('no forge verdict falls back to the local approximation', () {
    for (final missing in [
      PrMergeableState.unknown,
      PrMergeableState.unrecognized,
    ]) {
      test('$missing: green and approved is ready', () {
        final result = evaluate(mergeableState: missing);
        expect(result.readiness, PrMergeReadiness.ready);
        expect(result.reason, PrBlockReason.none);
      });

      test('$missing: a failing check blocks', () {
        final result = evaluate(
          mergeableState: missing,
          checksStatus: PrChecksStatus.failing,
        );
        expect(result.readiness, PrMergeReadiness.blocked);
        expect(result.reason, PrBlockReason.checksFailing);
      });

      test('$missing: a pending check is pending, not blocked', () {
        final result = evaluate(
          mergeableState: missing,
          checksStatus: PrChecksStatus.pending,
        );
        expect(result.readiness, PrMergeReadiness.pending);
        expect(result.reason, PrBlockReason.none);
      });
    }

    test('no checks configured at all is still ready', () {
      expect(
        evaluate(checksStatus: PrChecksStatus.none).readiness,
        PrMergeReadiness.ready,
      );
    });

    test('reviewRequired blocks with reviewsOutstanding', () {
      final result = evaluate(reviewDecision: PrReviewDecision.reviewRequired);
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.reviewsOutstanding);
    });

    test('changesRequested blocks and is named distinctly', () {
      final result = evaluate(
        reviewDecision: PrReviewDecision.changesRequested,
      );
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.changesRequested);
    });

    test('a review requirement outranks a failing check in the reason', () {
      // Both are wrong; the reason names the reviews because that is the one
      // the author has to chase a person about.
      final result = evaluate(
        reviewDecision: PrReviewDecision.reviewRequired,
        checksStatus: PrChecksStatus.failing,
      );
      expect(result.reason, PrBlockReason.reviewsOutstanding);
    });
  });

  group('requested reviewers, when the forge gave no decision', () {
    test('an unapproved requested reviewer blocks', () {
      final result = evaluate(
        reviewDecision: PrReviewDecision.none,
        requestedReviewerLogins: ['octocat'],
      );
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.reviewsOutstanding);
    });

    test('every requested reviewer approved is ready', () {
      final result = evaluate(
        reviewDecision: PrReviewDecision.none,
        requestedReviewerLogins: ['octocat', 'hubot'],
        approvedLogins: ['Octocat', 'HUBOT'],
      );
      expect(result.readiness, PrMergeReadiness.ready);
    });

    test('login comparison is case-insensitive', () {
      expect(
        evaluate(
          reviewDecision: PrReviewDecision.none,
          requestedReviewerLogins: ['OctoCat'],
          approvedLogins: ['octocat'],
        ).readiness,
        PrMergeReadiness.ready,
      );
    });

    test('an outstanding TEAM request blocks even with no individuals', () {
      // The forge drops a team from reviewRequests once any member reviews, so
      // a slug still present means nobody on it has.
      final result = evaluate(
        reviewDecision: PrReviewDecision.none,
        requestedTeamSlugs: ['platform'],
      );
      expect(result.readiness, PrMergeReadiness.blocked);
      expect(result.reason, PrBlockReason.reviewsOutstanding);
    });

    test('nobody requested and no decision is ready', () {
      expect(
        evaluate(reviewDecision: PrReviewDecision.none).readiness,
        PrMergeReadiness.ready,
      );
    });

    test('an approved decision ignores a stale requested-reviewer list', () {
      expect(
        evaluate(
          reviewDecision: PrReviewDecision.approved,
          requestedReviewerLogins: ['octocat'],
        ).readiness,
        PrMergeReadiness.ready,
      );
    });
  });

  group('prReviewsSatisfied is usable on its own', () {
    test('it reports unsatisfied while the forge still says clean', () {
      // The merge button's warning list depends on exactly this split.
      const args = (
        reviewDecision: PrReviewDecision.none,
        requested: ['octocat'],
      );
      expect(
        prReviewsSatisfied(
          reviewDecision: args.reviewDecision,
          requestedReviewerLogins: args.requested,
          requestedTeamSlugs: const [],
          approvedLogins: const [],
        ),
        isFalse,
      );
      expect(
        evaluate(
          mergeableState: PrMergeableState.clean,
          reviewDecision: args.reviewDecision,
          requestedReviewerLogins: args.requested,
        ).readiness,
        PrMergeReadiness.ready,
      );
    });
  });
}
