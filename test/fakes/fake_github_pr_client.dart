import 'package:control_center/core/network/github_pr_client.dart';
import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_review_comment.dart';
import 'package:dio/dio.dart';

/// In-memory fake [GitHubPrClient] for testing protocol handlers.
///
/// Configure the maps before running a test; unconfigured calls return empty
/// defaults (null / empty list / empty string) so tests only need to set
/// the data they care about.
class FakeGitHubPrClient extends GitHubPrClient {
  FakeGitHubPrClient() : super(_fakeDio);

  static final _fakeDio = _NullDio();

  /// PR lookup by "$owner/$repo/$number".
  final Map<String, GitHubPullRequest> pullRequests = {};

  /// Diff text by "$owner/$repo/$number".
  final Map<String, String> diffs = {};

  /// Reviews by "$owner/$repo/$number".
  final Map<String, List<GitHubReview>> reviews = {};

  /// Review comments by "$owner/$repo/$number".
  final Map<String, List<GitHubReviewComment>> reviewComments = {};

  /// Issue comments by "$owner/$repo/$number".
  final Map<String, List<GitHubIssueComment>> issueComments = {};

  /// Check runs by "$owner/$repo/$sha".
  final Map<String, List<GitHubCheckRun>> checkRuns = {};

  /// Files by "$owner/$repo/$number".
  final Map<String, List<GitHubPullRequestFile>> files = {};

  /// When set, [listCheckRuns] throws this instead of returning data.
  Object? checkRunError;

  /// When set, [getPullRequestDiff] throws this instead of returning data.
  Object? diffError;

  @override
  Future<GitHubPullRequest?> getPullRequest(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    return pullRequests['$owner/$repo/$number'];
  }

  @override
  Future<String> getPullRequestDiff(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    if (diffError != null) {
      throw diffError!;
    }
    return diffs['$owner/$repo/$number'] ?? '';
  }

  @override
  Future<List<GitHubPullRequestFile>> listPullRequestFiles(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    return files['$owner/$repo/$number'] ?? const [];
  }

  @override
  Future<List<GitHubReview>> listPullRequestReviews(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    return reviews['$owner/$repo/$number'] ?? const [];
  }

  @override
  Future<List<GitHubReviewComment>> listPullRequestReviewComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    return reviewComments['$owner/$repo/$number'] ?? const [];
  }

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    return issueComments['$owner/$repo/$number'] ?? const [];
  }

  @override
  Future<List<GitHubCheckRun>> listCheckRuns(
    String owner,
    String repo,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    if (checkRunError != null) {
      throw checkRunError!;
    }
    return checkRuns['$owner/$repo/$ref'] ?? const [];
  }
}

/// A Dio instance that never gets called — all methods are overridden.
class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('FakeGitHubPrClient should not reach Dio');
}
