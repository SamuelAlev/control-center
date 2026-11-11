/// Result shapes [GitHubPrClient]'s paged, compare and probe reads return.
/// @docImport 'package:cc_infra/src/network/github_pr_client.dart';
library;

import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_pr_stack.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';

/// A page of pull request results with a flag indicating whether more pages
/// are available.
class PaginatedPullRequests {
  /// Creates a [PaginatedPullRequests].
  const PaginatedPullRequests({required this.items, required this.hasMore});

  /// The pull requests in this page.
  final List<GitHubPullRequest> items;

  /// Whether there are more pages available.
  final bool hasMore;
}

/// A page of pull request stacks with a flag indicating whether more pages
/// are available.
class PaginatedPrStacks {
  /// Creates a [PaginatedPrStacks].
  const PaginatedPrStacks({required this.items, required this.hasMore});

  /// The stacks in this page.
  final List<GitHubPrStack> items;

  /// Whether there are more pages available.
  final bool hasMore;
}

/// The result of comparing two branches (`base...head`): the changed files
/// (same shape as the PR-files endpoint, so the diff viewer can render them
/// directly) plus the commit count. Additions/deletions are summed from the
/// files since the compare endpoint carries no top-level totals.
class GitHubBranchComparison {
  /// Creates a [GitHubBranchComparison].
  const GitHubBranchComparison({
    required this.files,
    required this.totalCommits,
    this.commits = const [],
  });

  /// The files changed between base and head.
  final List<GitHubPullRequestFile> files;

  /// Number of commits head is ahead of base.
  final int totalCommits;

  /// The commits between base and head (same shape as the PR-commits endpoint).
  final List<GitHubCommit> commits;

  /// Total lines added across all files.
  int get additions => files.fold(0, (sum, f) => sum + f.additions);

  /// Total lines deleted across all files.
  int get deletions => files.fold(0, (sum, f) => sum + f.deletions);
}

/// The outcome of a conditional (ETag) open-PR list probe: whether GitHub
/// reported a change since the caller's last ETag and the ETag to present on
/// the next probe. A 304 response does not count against the REST rate limit,
/// which is what makes a short polling cadence affordable.
class ConditionalPrListProbe {
  /// Creates a [ConditionalPrListProbe].
  const ConditionalPrListProbe({required this.changed, this.etag});

  /// True when the list changed (HTTP 200); false on 304 Not Modified.
  final bool changed;

  /// The response's ETag (present on 200; null on 304, where the caller keeps
  /// its previous one).
  final String? etag;
}
