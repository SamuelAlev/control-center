import 'package:cc_domain/core/domain/value_objects/cache_kind.dart';

/// The `caches` kinds the pull-request surface keeps: forge answers it can ask
/// for again.
///
/// Each name is declared here once; the PR review repository, the open-PR
/// poller, the link previews and the demo world all refer to these constants.
abstract final class PrReviewCacheKinds {
  /// A pull request's own detail row.
  static const String prDetail = 'prDetail';

  /// The unified diff, stored as raw text.
  static const String prDiff = 'prDiff';

  /// The changed-file list.
  static const String prFiles = 'prFiles';

  /// One file's content at a ref, stored as raw text.
  static const String prFileContent = 'prFileContent';

  /// A rendered image diff.
  static const String prImageDiff = 'prImageDiff';

  /// The commit list.
  static const String prCommits = 'prCommits';

  /// Files touched by one commit.
  static const String prCommitFiles = 'prCommitFiles';

  /// Submitted reviews.
  static const String prReviews = 'prReviews';

  /// Inline code-review comments.
  static const String prReviewComments = 'prReviewComments';

  /// Conversation (issue) comments.
  static const String prIssueComments = 'prIssueComments';

  /// The timeline rail.
  static const String prTimelineEvents = 'prTimelineEvents';

  /// CI check runs of a head commit.
  static const String prCheckRuns = 'prCheckRuns';

  /// Commit statuses of a head commit.
  static const String prCommitStatuses = 'prCommitStatuses';

  /// Enriched reviewer rows.
  static const String prReviewerState = 'prReviewerState';

  /// Repository-scoped assignee picker candidates.
  static const String assignableUsers = 'assignableUsers';

  /// Repository-scoped team picker candidates.
  static const String requestableTeams = 'requestableTeams';

  /// Repository-scoped labels.
  static const String repoLabels = 'repoLabels';

  /// A `#123` reference chip's pull request preview.
  static const String prPreview = 'prPreview';

  /// A commit reference chip's preview.
  static const String commitPreview = 'commitPreview';

  /// The open-PR poller's per-workspace snapshot.
  static const String openPrList = 'openPrList';

  /// Pull requests found for one head branch.
  static const String branchPrHistory = 'branchPrHistory';

  /// The demo world's merged-PR history, read in place of the forge's.
  static const String closedPrList = 'closedPrList';

  /// How long a forge answer nobody refreshed is worth keeping.
  ///
  /// Three weeks: an open pull request someone looks at is rewritten on every
  /// visit, so only rows of pull requests nobody opened in that time age out,
  /// and their diffs and file lists run to megabytes per row.
  static const Duration retention = Duration(days: 21);

  /// Every kind above, with its retention.
  static const List<CacheKind> declared = [
    CacheKind(prDetail, retention: retention),
    CacheKind(prDiff, retention: retention),
    CacheKind(prFiles, retention: retention),
    CacheKind(prFileContent, retention: retention),
    CacheKind(prImageDiff, retention: retention),
    CacheKind(prCommits, retention: retention),
    CacheKind(prCommitFiles, retention: retention),
    CacheKind(prReviews, retention: retention),
    CacheKind(prReviewComments, retention: retention),
    CacheKind(prIssueComments, retention: retention),
    CacheKind(prTimelineEvents, retention: retention),
    CacheKind(prCheckRuns, retention: retention),
    CacheKind(prCommitStatuses, retention: retention),
    CacheKind(prReviewerState, retention: retention),
    CacheKind(assignableUsers, retention: retention),
    CacheKind(requestableTeams, retention: retention),
    CacheKind(repoLabels, retention: retention),
    CacheKind(prPreview, retention: retention),
    CacheKind(commitPreview, retention: retention),
    CacheKind(openPrList, retention: retention),
    CacheKind(branchPrHistory, retention: retention),
    CacheKind(closedPrList, retention: retention),
  ];
}
