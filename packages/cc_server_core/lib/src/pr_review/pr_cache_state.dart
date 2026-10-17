part of '../cached_pr_review_repository.dart';

class _Kind {
  static const prDetail = 'prDetail';
  static const prDiff = 'prDiff';
  static const prFiles = 'prFiles';
  static const prFileContent = 'prFileContent';
  static const prImageDiff = 'prImageDiff';
  static const prCommits = 'prCommits';
  static const prCommitFiles = 'prCommitFiles';
  static const prReviews = 'prReviews';
  static const prReviewComments = 'prReviewComments';
  static const prIssueComments = 'prIssueComments';
  static const prTimelineEvents = 'prTimelineEvents';
  static const prCheckRuns = 'prCheckRuns';
  static const prCommitStatuses = 'prCommitStatuses';

  /// Enriched reviewer rows (users + teams + code-owner flags + on-behalf
  /// merge) resolved from the GraphQL review-state query, keyed by PR number.
  static const prReviewerState = 'prReviewerState';

  /// Monotonic per-PR set of reviewer identities ever seen flagged
  /// `asCodeOwner`. Deliberately NOT in `prScoped`: it accumulates so the
  /// shield survives the pending→reviewed transition (GitHub drops the flag).
  static const prCodeOwnerIds = 'prCodeOwnerIds';

  /// Repo-scoped picker candidate caches (TTL-enveloped), keyed by repo.
  static const assignableUsers = 'assignableUsers';
  static const requestableTeams = 'requestableTeams';
  static const repoLabels = 'repoLabels';

  static const prScoped = <String>[
    prDetail,
    prDiff,
    prFiles,
    prCommits,
    prReviews,
    prReviewComments,
    prIssueComments,
    prTimelineEvents,
    prCheckRuns,
    prCommitStatuses,
    prReviewerState,
  ];
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
