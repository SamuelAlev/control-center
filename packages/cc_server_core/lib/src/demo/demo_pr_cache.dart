/// The cache kinds and key shapes the PR-review surface is stored under.
///
/// The kinds are the production ones ([PrReviewCacheKinds]); the key helpers
/// MIRROR the private `_prKey`/`_shaKey` in `cached_pr_review_repository.dart`.
/// The demo has to agree with it exactly: the seeder writes rows the demo
/// repository reads, and keeping the real format means a demo fixture is a
/// realistic cache entry rather than a parallel invention.
library;

import 'package:cc_domain/features/pr_review/domain/value_objects/pr_review_cache_kinds.dart';

/// Cache kinds for the PR review surface.
class DemoPrCacheKind {
  const DemoPrCacheKind._();

  /// The PR's own detail row.
  static const String detail = PrReviewCacheKinds.prDetail;

  /// The unified diff, stored as raw text (not JSON).
  static const String diff = PrReviewCacheKinds.prDiff;

  /// The changed-file list.
  static const String files = PrReviewCacheKinds.prFiles;

  /// One file's content at a ref, stored as raw text (not JSON).
  static const String fileContent = PrReviewCacheKinds.prFileContent;

  /// The commit list.
  static const String commits = PrReviewCacheKinds.prCommits;

  /// Files touched by one commit.
  static const String commitFiles = PrReviewCacheKinds.prCommitFiles;

  /// Submitted reviews.
  static const String reviews = PrReviewCacheKinds.prReviews;

  /// Inline code-review comments.
  static const String reviewComments = PrReviewCacheKinds.prReviewComments;

  /// Conversation (issue) comments.
  static const String issueComments = PrReviewCacheKinds.prIssueComments;

  /// The timeline rail.
  static const String timelineEvents = PrReviewCacheKinds.prTimelineEvents;

  /// CI check runs.
  static const String checkRuns = PrReviewCacheKinds.prCheckRuns;

  /// Commit statuses.
  static const String commitStatuses = PrReviewCacheKinds.prCommitStatuses;

  /// Enriched reviewer rows.
  static const String reviewerState = PrReviewCacheKinds.prReviewerState;

  /// Repo-scoped assignable users.
  static const String assignableUsers = PrReviewCacheKinds.assignableUsers;

  /// Repo-scoped requestable teams.
  static const String requestableTeams = PrReviewCacheKinds.requestableTeams;

  /// The open-PR list snapshot the poller persists and
  /// `pr.watchOpenForWorkspace` follows.
  static const String openPrList = PrReviewCacheKinds.openPrList;

  /// Single-row key for [openPrList].
  static const String openPrListKey = 'v1';

  /// Maya's merged-PR history, the snapshot
  /// `pr.closedByAuthorForWorkspace` reads in demo mode.
  static const String closedPrList = PrReviewCacheKinds.closedPrList;

  /// Single-row key for [closedPrList].
  static const String closedPrListKey = 'v1';
}

/// Cache key for a PR-scoped entry: `owner/repo#number`.
///
/// The repo is part of the key because the `caches` table is keyed
/// `(workspaceId, kind, key)` with no repo dimension — two linked repos with
/// the same PR number would otherwise collide inside one workspace.
String demoPrCacheKey(String repoFullName, int prNumber) =>
    '$repoFullName#$prNumber';

/// Cache key for a SHA-scoped entry: `owner/repo|sha`.
String demoShaCacheKey(String repoFullName, String sha) => '$repoFullName|$sha';

/// Cache key for a file-content entry: `owner/repo|ref|path`.
String demoFileContentCacheKey(String repoFullName, String ref, String path) =>
    '$repoFullName|$ref|$path';
