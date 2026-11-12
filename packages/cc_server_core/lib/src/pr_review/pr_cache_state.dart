part of '../cached_pr_review_repository.dart';

/// The `caches` kinds this repository writes, all declared in
/// [PrReviewCacheKinds].
class _Kind {
  static const prDetail = PrReviewCacheKinds.prDetail;
  static const prDiff = PrReviewCacheKinds.prDiff;
  static const prFiles = PrReviewCacheKinds.prFiles;
  static const prFileContent = PrReviewCacheKinds.prFileContent;
  static const prImageDiff = PrReviewCacheKinds.prImageDiff;
  static const prCommits = PrReviewCacheKinds.prCommits;
  static const prCommitFiles = PrReviewCacheKinds.prCommitFiles;
  static const prReviews = PrReviewCacheKinds.prReviews;
  static const prReviewComments = PrReviewCacheKinds.prReviewComments;
  static const prIssueComments = PrReviewCacheKinds.prIssueComments;
  static const prTimelineEvents = PrReviewCacheKinds.prTimelineEvents;
  static const prCheckRuns = PrReviewCacheKinds.prCheckRuns;
  static const prCommitStatuses = PrReviewCacheKinds.prCommitStatuses;

  /// Enriched reviewer rows (users + teams + code-owner flags + on-behalf
  /// merge) resolved from the GraphQL review-state query, keyed by PR number.
  static const prReviewerState = PrReviewCacheKinds.prReviewerState;

  /// Repo-scoped picker candidate caches (TTL-enveloped), keyed by repo.
  static const assignableUsers = PrReviewCacheKinds.assignableUsers;
  static const requestableTeams = PrReviewCacheKinds.requestableTeams;
  static const repoLabels = PrReviewCacheKinds.repoLabels;

  /// Kinds keyed by PR number ([CachedPrReviewRepository._prKey]).
  static const prScoped = <String>[
    prDetail,
    prDiff,
    prFiles,
    prCommits,
    prReviews,
    prReviewComments,
    prIssueComments,
    prTimelineEvents,
    prReviewerState,
  ];

  /// Kinds keyed by the head commit (`_shaKey`): a PR-number key can never
  /// reach these rows, so invalidation deletes them by the head SHA.
  static const headShaScoped = <String>[prCheckRuns, prCommitStatuses];
}

// GitHub caps the files endpoint at 3 000 entries; above this threshold we
// fall back to the local-git source.
const _githubFilesApiLimit = 3000;

// GitHub refuses `Accept: application/vnd.github.diff` once the unified
// diff exceeds 20 000 lines (HTTP 406, `too_large`). Changed-line churn is
// a lower bound (context lines also count), so crossing this means the
// raw-diff backfill cannot succeed and we clone locally instead.
const _githubDiffLineLimit = 20000;

/// Cross-pass state for a long-lived SWR stream: the fingerprint of the last
/// emission (so a re-validation that changes nothing emits nothing) and
/// whether the stream was cancelled mid-pass (so the outer signal loop stops
/// instead of idling on a dead subscription).
class _SwrState {
  String? lastEncoded;
  bool cancelled = false;
}

/// One in-flight upstream fetch. A holder rather than a bare `Future` so the
/// leader can compare identity in its `finally` without the analyzer reading
/// the map lookup as an unawaited future.
class _InflightFetch {
  _InflightFetch(this.future);

  final Future<Object?> future;
}
