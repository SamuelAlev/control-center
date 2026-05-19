import 'package:cc_infra/src/network/gitlab/models/gitlab_commit.dart';
import 'package:cc_infra/src/network/gitlab/models/gitlab_diff.dart';

/// The result of `GET /projects/:id/repository/compare?from=…&to=…`.
///
/// One request answers the whole compose-PR preview: [commits] is what the
/// merge request would carry and [diffs] is the same per-file shape the
/// merge-request diff endpoint returns, so both map through the existing
/// mappers untouched.
///
/// Both collections are subject to instance limits — [compareTimeout] is
/// GitLab's own flag for "this comparison was too big to finish", and the diff
/// list is capped independently — so the counts are a floor, not a guarantee.
class GitLabComparison {
  /// Creates a [GitLabComparison].
  const GitLabComparison({
    this.commits = const <GitLabCommit>[],
    this.diffs = const <GitLabDiff>[],
    this.compareTimeout = false,
    this.compareSameRef = false,
    this.webUrl = '',
  });

  /// Reads a [GitLabComparison] off a decoded JSON object.
  factory GitLabComparison.fromJson(Map<String, dynamic> json) {
    final commits = json['commits'];
    final diffs = json['diffs'];
    return GitLabComparison(
      commits: commits is List
          ? commits
                .whereType<Map<String, dynamic>>()
                .map(GitLabCommit.fromJson)
                .toList(growable: false)
          : const <GitLabCommit>[],
      diffs: diffs is List
          ? diffs
                .whereType<Map<String, dynamic>>()
                .map(GitLabDiff.fromJson)
                .toList(growable: false)
          : const <GitLabDiff>[],
      compareTimeout: json['compare_timeout'] as bool? ?? false,
      compareSameRef: json['compare_same_ref'] as bool? ?? false,
      webUrl: json['web_url'] as String? ?? '',
    );
  }

  /// Commits reachable from the head ref but not the base ref.
  final List<GitLabCommit> commits;

  /// Files the comparison touches.
  final List<GitLabDiff> diffs;

  /// Whether GitLab gave up part-way through the comparison.
  final bool compareTimeout;

  /// Whether both refs resolve to the same commit.
  final bool compareSameRef;

  /// Link to the comparison page.
  final String webUrl;
}
