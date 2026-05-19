import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// Whether a pull request can be landed right now.
enum PrMergeReadiness {
  /// Every requirement the caller can see is satisfied.
  ready,

  /// Nothing is failing, but something is still running.
  pending,

  /// Merging would override the forge, or is outright refused.
  blocked,
}

/// Why a pull request is not [PrMergeReadiness.ready].
///
/// Carried alongside the readiness so a notification can say *what* to fix
/// rather than only that something is wrong. [none] accompanies
/// [PrMergeReadiness.ready] and [PrMergeReadiness.pending].
enum PrBlockReason {
  /// Not blocked.
  none,

  /// The pull request is still a draft.
  draft,

  /// The head branch conflicts with the base.
  conflicts,

  /// The head branch is behind the base and the repo requires it current.
  behind,

  /// A reviewer requested changes.
  changesRequested,

  /// A required review has not been given yet.
  reviewsOutstanding,

  /// At least one check failed.
  checksFailing,

  /// The forge refuses for a reason it did not break down (custom hooks,
  /// branch protection the API reports only as `blocked`).
  forgeBlocked,
}

/// Whether every requested reviewer has approved.
///
/// A local approximation only: it cannot tell a *required* reviewer from an
/// optional one, which is why [evaluatePrMergeReadiness] prefers the forge's
/// own verdict whenever that has been computed.
///
/// A non-empty [requestedTeamSlugs] counts as outstanding: GitHub drops a team
/// from `reviewRequests` once any member reviews, so a slug still present means
/// nobody on that team has.
bool _allRequestedReviewersApproved({
  required Iterable<String> requestedReviewerLogins,
  required Iterable<String> requestedTeamSlugs,
  required Iterable<String> approvedLogins,
}) {
  if (requestedTeamSlugs.isNotEmpty) {
    return false;
  }
  final requested = requestedReviewerLogins.toList();
  if (requested.isEmpty) {
    return true;
  }
  final approved = approvedLogins.map((l) => l.toLowerCase()).toSet();
  return requested.every((r) => approved.contains(r.toLowerCase()));
}

/// Whether the review requirement is satisfied, from the strongest signal in
/// hand: the forge's rolled-up `reviewDecision` when it was fetched (it already
/// knows which reviews the repo *requires*), otherwise the local
/// requested-reviewer approximation.
/// Public because the merge button shows a "reviews pending" warning from the
/// same predicate, independently of whether the forge is blocking: a PR the
/// forge reports as `clean` can still have a requested reviewer who has not
/// looked, and that is worth saying even though merging is allowed.
bool prReviewsSatisfied({
  required PrReviewDecision reviewDecision,
  required Iterable<String> requestedReviewerLogins,
  required Iterable<String> requestedTeamSlugs,
  required Iterable<String> approvedLogins,
}) {
  switch (reviewDecision) {
    case PrReviewDecision.approved:
      return true;
    case PrReviewDecision.reviewRequired:
    case PrReviewDecision.changesRequested:
      return false;
    case PrReviewDecision.none:
      return _allRequestedReviewersApproved(
        requestedReviewerLogins: requestedReviewerLogins,
        requestedTeamSlugs: requestedTeamSlugs,
        approvedLogins: approvedLogins,
      );
  }
}

/// Readiness derived from the checks and reviews the caller was handed, used
/// only until the forge's own verdict arrives.
({PrMergeReadiness readiness, PrBlockReason reason}) _localReadiness({
  required PrReviewDecision reviewDecision,
  required PrChecksStatus checksStatus,
  required Iterable<String> requestedReviewerLogins,
  required Iterable<String> requestedTeamSlugs,
  required Iterable<String> approvedLogins,
}) {
  final reviewsOk = prReviewsSatisfied(
    reviewDecision: reviewDecision,
    requestedReviewerLogins: requestedReviewerLogins,
    requestedTeamSlugs: requestedTeamSlugs,
    approvedLogins: approvedLogins,
  );
  if (!reviewsOk) {
    return (
      readiness: PrMergeReadiness.blocked,
      reason: reviewDecision == PrReviewDecision.changesRequested
          ? PrBlockReason.changesRequested
          : PrBlockReason.reviewsOutstanding,
    );
  }
  if (checksStatus == PrChecksStatus.failing) {
    return (
      readiness: PrMergeReadiness.blocked,
      reason: PrBlockReason.checksFailing,
    );
  }
  if (checksStatus == PrChecksStatus.pending) {
    return (readiness: PrMergeReadiness.pending, reason: PrBlockReason.none);
  }
  return (readiness: PrMergeReadiness.ready, reason: PrBlockReason.none);
}

/// Whether a pull request can be merged, and if not, why.
///
/// [mergeableState] is the forge's own verdict and it already factors in the
/// things a check list cannot show: WHICH checks are required, codeowner rules,
/// branch protection and conflicts with the base branch. So it wins whenever it
/// has been computed — a PR the forge reports as `clean` is ready even if some
/// optional check is red or a non-required reviewer hasn't looked yet.
///
/// It is computed lazily server-side, so `unknown` (and any state the client
/// doesn't recognise) falls back to the local approximation over
/// [reviewDecision], [checksStatus] and the requested-reviewer set.
///
/// A draft is always blocked. That is deliberate and is *not* inherited from
/// the merge button, which is simply hidden on drafts: without the check, every
/// green draft would report ready and fire a "ready to merge" notification.
({PrMergeReadiness readiness, PrBlockReason reason}) evaluatePrMergeReadiness({
  required bool isDraft,
  required PrMergeableState mergeableState,
  required PrReviewDecision reviewDecision,
  required PrChecksStatus checksStatus,
  required Iterable<String> requestedReviewerLogins,
  required Iterable<String> requestedTeamSlugs,
  Iterable<String> approvedLogins = const [],
}) {
  if (isDraft) {
    return (readiness: PrMergeReadiness.blocked, reason: PrBlockReason.draft);
  }
  switch (mergeableState) {
    case PrMergeableState.clean:
    case PrMergeableState.hasHooks:
      return (readiness: PrMergeReadiness.ready, reason: PrBlockReason.none);
    // Mergeable with a non-passing rollup: nothing REQUIRED is failing (that
    // would be `blocked`), so merging is permitted — just not all-green.
    case PrMergeableState.unstable:
      return (readiness: PrMergeReadiness.pending, reason: PrBlockReason.none);
    case PrMergeableState.dirty:
      return (
        readiness: PrMergeReadiness.blocked,
        reason: PrBlockReason.conflicts,
      );
    case PrMergeableState.behind:
      return (
        readiness: PrMergeReadiness.blocked,
        reason: PrBlockReason.behind,
      );
    case PrMergeableState.blocked:
      // The forge says no but not why. Ask the local signals for a reason we
      // can name; keep the forge's refusal if they see nothing wrong.
      final local = _localReadiness(
        reviewDecision: reviewDecision,
        checksStatus: checksStatus,
        requestedReviewerLogins: requestedReviewerLogins,
        requestedTeamSlugs: requestedTeamSlugs,
        approvedLogins: approvedLogins,
      );
      return (
        readiness: PrMergeReadiness.blocked,
        reason: local.reason == PrBlockReason.none
            ? PrBlockReason.forgeBlocked
            : local.reason,
      );
    case PrMergeableState.unknown:
    case PrMergeableState.unrecognized:
      return _localReadiness(
        reviewDecision: reviewDecision,
        checksStatus: checksStatus,
        requestedReviewerLogins: requestedReviewerLogins,
        requestedTeamSlugs: requestedTeamSlugs,
        approvedLogins: approvedLogins,
      );
  }
}
