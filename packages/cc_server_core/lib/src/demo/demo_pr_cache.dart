/// The cache kinds and key shapes the PR-review surface is stored under.
///
/// These MIRROR the private `_Kind` constants and `_prKey`/`_shaKey` helpers in
/// `cached_pr_review_repository.dart`. They are duplicated rather than shared
/// because that class keeps them private, and the demo has to agree with it
/// exactly: the seeder writes rows the demo repository reads, and keeping the
/// real format means a demo fixture is a realistic cache entry rather than a
/// parallel invention.
library;

/// Cache kinds for the PR review surface.
class DemoPrCacheKind {
  const DemoPrCacheKind._();

  /// The PR's own detail row.
  static const String detail = 'prDetail';

  /// The unified diff, stored as raw text (not JSON).
  static const String diff = 'prDiff';

  /// The changed-file list.
  static const String files = 'prFiles';

  /// One file's content at a ref, stored as raw text (not JSON).
  static const String fileContent = 'prFileContent';

  /// The commit list.
  static const String commits = 'prCommits';

  /// Files touched by one commit.
  static const String commitFiles = 'prCommitFiles';

  /// Submitted reviews.
  static const String reviews = 'prReviews';

  /// Inline code-review comments.
  static const String reviewComments = 'prReviewComments';

  /// Conversation (issue) comments.
  static const String issueComments = 'prIssueComments';

  /// The timeline rail.
  static const String timelineEvents = 'prTimelineEvents';

  /// CI check runs.
  static const String checkRuns = 'prCheckRuns';

  /// Commit statuses.
  static const String commitStatuses = 'prCommitStatuses';

  /// Enriched reviewer rows.
  static const String reviewerState = 'prReviewerState';

  /// Repo-scoped assignable users.
  static const String assignableUsers = 'assignableUsers';

  /// Repo-scoped requestable teams.
  static const String requestableTeams = 'requestableTeams';

  /// The open-PR list snapshot the poller persists and
  /// `pr.watchOpenForWorkspace` follows.
  static const String openPrList = 'openPrList';

  /// Single-row key for [openPrList].
  static const String openPrListKey = 'v1';
}

/// Cache key for a PR-scoped entry: `owner/repo#number`.
///
/// The repo is part of the key because the `caches` table is keyed
/// `(workspaceId, kind, key)` with no repo dimension — two linked repos with
/// the same PR number would otherwise collide inside one workspace.
String demoPrCacheKey(String repoFullName, int prNumber) =>
    '$repoFullName#$prNumber';

/// Cache key for a SHA-scoped entry: `owner/repo|sha`.
String demoShaCacheKey(String repoFullName, String sha) =>
    '$repoFullName|$sha';

/// Cache key for a file-content entry: `owner/repo|ref|path`.
String demoFileContentCacheKey(
  String repoFullName,
  String ref,
  String path,
) => '$repoFullName|$ref|$path';
