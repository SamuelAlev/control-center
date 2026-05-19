import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/network/error_mapper.dart';
import 'package:control_center/core/network/models/github_check_run.dart';
import 'package:control_center/core/network/models/github_commit.dart';
import 'package:control_center/core/network/models/github_issue_comment.dart';
import 'package:control_center/core/network/models/github_pull_request.dart';
import 'package:control_center/core/network/models/github_pull_request_file.dart';
import 'package:control_center/core/network/models/github_reaction.dart';
import 'package:control_center/core/network/models/github_review.dart';
import 'package:control_center/core/network/models/github_review_comment.dart';
import 'package:control_center/core/network/models/github_team.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/core/network/models/github_workflow_run.dart';
import 'package:dio/dio.dart';

class PaginatedPullRequests {
  const PaginatedPullRequests({required this.items, required this.hasMore});
  final List<GitHubPullRequest> items;
  final bool hasMore;
}

/// Client for GitHub PR-related REST API endpoints.
class GitHubPrClient {
  /// Creates a [GitHubPrClient] backed by [Dio].
  GitHubPrClient(this._dio);

  final Dio _dio;

  static const _pullsPerPage = 100;

  Future<PaginatedPullRequests> listOpenPullRequestsPage(
    String owner,
    String repo, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls',
        queryParameters: {
          'state': 'open',
          'per_page': _pullsPerPage,
          'page': page,
        },
        cancelToken: cancelToken,
      );
      final items = _decodeList(response.data, GitHubPullRequest.fromJson);
      final hasMore = _hasNextPage(response);
      return PaginatedPullRequests(items: items, hasMore: hasMore);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  static bool _hasNextPage(Response<dynamic> response) {
    final link = response.headers.value('link');
    if (link == null) {
      return false;
    }
    return link.contains('rel="next"');
  }

  /// Lists open pull requests that have requested reviews for the authenticated user.
  Future<List<GitHubPullRequest>> listRequestedReviews(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/search/issues',
        queryParameters: {
          'q': 'type:pr state:open review-requested:@me repo:$owner/$repo',
        },
        cancelToken: cancelToken,
      );
      final data = response.data;
      final map = data as Map<String, dynamic>?;
      final items = map?['items'] as List?;
      return _decodeList(items, GitHubPullRequest.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists open PR numbers that the authenticated user has already reviewed
  /// (submitted a review or left comments on). Returns a set of PR numbers.
  Future<Set<int>> listReviewedByMePrNumbers(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/search/issues',
        queryParameters: {
          'q': 'type:pr state:open reviewed-by:@me repo:$owner/$repo',
        },
        cancelToken: cancelToken,
      );
      final data = response.data;
      final map = data as Map<String, dynamic>?;
      final items = map?['items'] as List?;
      if (items == null) {
        return {};
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map((j) => (j['number'] as num?)?.toInt() ?? 0)
          .where((n) => n > 0)
          .toSet();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Searches the non-open (merged + closed) pull requests authored by
  /// [author] in [owner]/[repo]. Returns the first page (up to
  /// [_pullsPerPage]) of matches, most-recently-updated first.
  ///
  /// GitHub treats merged PRs as `state:closed`, so a single `state:closed`
  /// query returns both merged and unmerged-closed PRs. Results are
  /// issue-shaped: the merge timestamp comes back under `pull_request.merged_at`
  /// (recovered by [GitHubPullRequest.fromJson]), letting callers split merged
  /// from closed via the mapped `mergedAt`. Diff size / check status are not
  /// included (no GraphQL metrics enrichment for non-open PRs).
  Future<List<GitHubPullRequest>> searchClosedPullRequestsByAuthor(
    String owner,
    String repo,
    String author, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final q = 'type:pr state:closed author:$author repo:$owner/$repo';
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/search/issues',
        queryParameters: {
          'q': q,
          'per_page': _pullsPerPage,
          'sort': 'updated',
          'order': 'desc',
        },
        cancelToken: cancelToken,
      );
      final data = response.data;
      final map = data as Map<String, dynamic>?;
      final items = map?['items'] as List?;
      return _decodeList(items, GitHubPullRequest.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  // `full+json` returns body, body_html, body_text together with reactions.
  // body_html is required so private user-attachment URLs come back as
  // self-signed `private-user-images.githubusercontent.com` JWT URLs the
  // app can fetch without a github.com session cookie.
  static const _fullBodyHeader = <String, dynamic>{
    'Accept': 'application/vnd.github.full+json',
  };

  // `squirrel-girl-preview` is the legacy reactions header. `full+json`
  // already includes reactions, but the reaction-only endpoint doesn't
  // need the larger HTML body.
  static const _reactionsHeader = <String, dynamic>{
    'Accept': 'application/vnd.github.squirrel-girl-preview+json',
  };

  /// Fetches a single pull request with full details (reviewers, assignees,
  /// head SHA, ...).
  Future<GitHubPullRequest?> getPullRequest(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number',
        options: Options(headers: _fullBodyHeader),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubPullRequest.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  Future<GitHubReactionSummary?> getIssueReactionSummary(
    String owner,
    String repo,
    int issueNumber, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$issueNumber',
        options: Options(headers: _reactionsHeader),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['reactions'] is Map<String, dynamic>) {
        return GitHubReactionSummary.fromJson(
          data['reactions'] as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Fetches the diff text for a pull request.
  Future<String> getPullRequestDiff(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number',
        options: Options(
          headers: {'Accept': 'application/vnd.github.diff'},
          responseType: ResponseType.plain,
        ),
        cancelToken: cancelToken,
      );
      return response.data?.toString() ?? '';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists files changed in a pull request, including per-file unified diff
  /// patches. Pages through GitHub's results so PRs with more than 100 files
  /// (the API maximum per request) return the complete set. GitHub caps the
  /// files endpoint at 3000 entries (30 pages of 100); we honour that and
  /// stop as soon as a page returns fewer than [_filesPerPage] items.
  ///
  /// For huge PRs prefer [streamPullRequestFiles] so the UI can render
  /// progressively instead of waiting for all 30 pages.
  Future<List<GitHubPullRequestFile>> listPullRequestFiles(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    final all = <GitHubPullRequestFile>[];
    await for (final page in streamPullRequestFiles(
      owner,
      repo,
      number,
      cancelToken: cancelToken,
    )) {
      all.addAll(page);
    }
    return all;
  }

  /// Streams pages of changed files as they arrive. Each emission is one
  /// page (up to [_filesPerPage] entries). For a 3000-file PR the first
  /// page typically lands in ~500 ms instead of the ~15 s the batch fetch
  /// needs to drain all 30 pages, so the file list can begin rendering
  /// immediately.
  Stream<List<GitHubPullRequestFile>> streamPullRequestFiles(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async* {
    _requireOwnerRepo(owner, repo);
    for (var page = 1; page <= _filesMaxPages; page++) {
      List<GitHubPullRequestFile> batch;
      try {
        final response = await _dio.get(
          '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number/files',
          queryParameters: {'per_page': _filesPerPage, 'page': page},
          cancelToken: cancelToken,
        );
        batch = _decodeList(response.data, GitHubPullRequestFile.fromJson);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          rethrow;
        }
        throw mapDioException(e);
      }
      if (batch.isNotEmpty) {
        yield batch;
      }
      if (batch.length < _filesPerPage) {
        return;
      }
    }
  }

  static const int _filesPerPage = 100;
  static const int _filesMaxPages = 30;

  /// Lists commits in a pull request (first page, up to 100).
  Future<List<GitHubCommit>> listPullRequestCommits(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number/commits',
        queryParameters: {'per_page': 100},
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubCommit.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Paginates through all commits in a pull request up to GitHub's ceiling
  /// (~250). Use this when displaying the full commit list — the single-page
  /// variant only fetches the first 100.
  Future<List<GitHubCommit>> listAllPullRequestCommits(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final all = <GitHubCommit>[];
    for (var page = 1; page <= _commitsMaxPages; page++) {
      try {
        final response = await _dio.get(
          '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number/commits',
          queryParameters: {'per_page': _commitsPerPage, 'page': page},
          cancelToken: cancelToken,
        );
        final batch = _decodeList(response.data, GitHubCommit.fromJson);
        all.addAll(batch);
        if (batch.length < _commitsPerPage || !_hasNextPage(response)) {
          break;
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        throw mapDioException(e);
      }
    }
    return all;
  }

  static const int _commitsPerPage = 100;
  // GitHub caps PR commits at ~250; 3 pages × 100 covers it.
  static const int _commitsMaxPages = 3;

  /// Fetches a single commit's metadata (sha, message, author, date). Used
  /// for inline commit reference previews — only the commit envelope is
  /// needed, not the per-file diff.
  Future<GitHubCommit?> getCommit(
    String owner,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (sha.isEmpty) {
      return null;
    }
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/commits/$sha',
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubCommit.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Fetches a single commit with its per-file change list. Same file shape
  /// as the PR-level files endpoint, so the diff view can render it
  /// interchangeably when the user scopes the diff to one commit.
  Future<List<GitHubPullRequestFile>> getCommitFiles(
    String owner,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (sha.isEmpty) {
      return <GitHubPullRequestFile>[];
    }

    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/commits/$sha',
        cancelToken: cancelToken,
      );
      final data = response.data;
      final raw = data is Map<String, dynamic> ? data['files'] : null;
      return _decodeList(raw, GitHubPullRequestFile.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists reviews (approvals, change requests, dismissals) for a PR.
  Future<List<GitHubReview>> listPullRequestReviews(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number/reviews',
        queryParameters: {'per_page': 100},
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubReview.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists inline review comments (attached to specific diff lines) for a PR.
  Future<List<GitHubReviewComment>> listPullRequestReviewComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$number/comments',
        queryParameters: {'per_page': 100},
        options: Options(headers: _fullBodyHeader),
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubReviewComment.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists issue-style comments on the pull request conversation timeline.
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$number/comments',
        queryParameters: {'per_page': 100},
        options: Options(headers: _fullBodyHeader),
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubIssueComment.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists check runs for a commit SHA.
  Future<List<GitHubCheckRun>> listCheckRuns(
    String owner,
    String repo,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (ref.isEmpty) {
      return <GitHubCheckRun>[];
    }

    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/commits/$ref/check-runs',
        queryParameters: {'per_page': 100},
        cancelToken: cancelToken,
      );
      final data = response.data;
      final raw = data is Map<String, dynamic> ? data['check_runs'] : null;
      return _decodeList(raw, GitHubCheckRun.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Lists GitHub Actions workflow runs that ran against [headSha]. Used to
  /// resolve a check run's parent workflow name (the `name:` field in the
  /// workflow YAML) — the check-runs API only exposes job-level data.
  Future<List<GitHubWorkflowRun>> listWorkflowRuns(
    String owner,
    String repo,
    String headSha, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (headSha.isEmpty) {
      return <GitHubWorkflowRun>[];
    }

    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/actions/runs',
        queryParameters: {'head_sha': headSha, 'per_page': 100},
        cancelToken: cancelToken,
      );
      final data = response.data;
      final raw = data is Map<String, dynamic>
          ? data['workflow_runs']
          : null;
      return _decodeList(raw, GitHubWorkflowRun.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Posts a new review comment on the PR head commit. Supports both
  /// single-line and multi-line anchors via [startLine] + [startSide].
  ///
  /// - For a single-line anchor leave [startLine] = null.
  /// - For a multi-line anchor pass `startLine` < `line` (and the same
  ///   `startSide` as `side` — GitHub doesn't support cross-side ranges).
  ///
  /// Returns the freshly-posted [GitHubReviewComment] decoded from the
  /// response.
  Future<GitHubReviewComment> postReviewComment(
    String owner,
    String repo, {
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final payload = <String, dynamic>{
      'commit_id': commitSha,
      'path': path,
      'body': body,
      'line': line,
      'side': side,
    };
    if (startLine != null && startLine != line) {
      payload['start_line'] = startLine;
      payload['start_side'] = startSide ?? side;
    }
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/comments',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException(
        'Unexpected payload from review-comment POST',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Posts a reply to an existing review comment thread.
  Future<GitHubReviewComment> replyToReviewComment(
    String owner,
    String repo, {
    required int prNumber,
    required int parentCommentId,
    required String body,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/comments/$parentCommentId/replies',
        data: {'body': body},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reply POST');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Deletes one of the authenticated user's review comments.
  Future<void> deleteReviewComment(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/comments/$commentId',
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Edits the body of one of the authenticated user's review comments.
  Future<GitHubReviewComment> editReviewComment(
    String owner,
    String repo, {
    required int commentId,
    required String body,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.patch(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/comments/$commentId',
        data: {'body': body},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from comment PATCH');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Submits a pull request review with the given [event] (`APPROVE`,
  /// `REQUEST_CHANGES`, or `COMMENT`) and optional [body].
  Future<GitHubReview> submitReview(
    String owner,
    String repo, {
    required int prNumber,
    required String event,
    String? body,
    String? commitId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final payload = <String, dynamic>{'event': event};
    if (body != null && body.isNotEmpty) {
      payload['body'] = body;
    }
    if (commitId != null && commitId.isNotEmpty) {
      payload['commit_id'] = commitId;
    }
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/reviews',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReview.fromJson(data);
      }
      throw const FormatException(
        'Unexpected payload from review submit POST',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  /// Creates a new pull request.
  Future<Map<String, dynamic>> createPullRequest(
    String owner,
    String repo, {
    required String title,
    required String body,
    required String head,
    required String base,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls',
        data: {'title': title, 'body': body, 'head': head, 'base': base},
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }

      throw mapDioException(e);
    }
  }

  Future<GitHubReaction> createReviewCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/comments/$commentId/reactions',
        data: {'content': content},
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reaction POST');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<void> deleteReviewCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/comments/$commentId/reactions/$reactionId',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<List<GitHubReaction>> listReviewCommentReactions(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/comments/$commentId/reactions',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubReaction.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<GitHubReaction> createIssueCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/comments/$commentId/reactions',
        data: {'content': content},
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reaction POST');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<void> deleteIssueCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/comments/$commentId/reactions/$reactionId',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<List<GitHubReaction>> listIssueCommentReactions(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/comments/$commentId/reactions',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubReaction.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<GitHubReaction> createIssueReaction(
    String owner,
    String repo, {
    required int issueNumber,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$issueNumber/reactions',
        data: {'content': content},
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException('Unexpected payload from issue reaction POST');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<void> deleteIssueReaction(
    String owner,
    String repo, {
    required int issueNumber,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$issueNumber/reactions/$reactionId',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  Future<List<GitHubReaction>> listIssueReactions(
    String owner,
    String repo, {
    required int issueNumber,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$issueNumber/reactions',
        options: Options(headers: {
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(response.data, GitHubReaction.fromJson);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Merges a pull request.
  ///
  /// Returns a map with `merged` (bool), `message` (String), and `sha` (String).
  /// Throws a [DioException] with status 405 if the merge is not possible
  /// (e.g. required checks failing, merge conflict).
  Future<Map<String, dynamic>> mergePullRequest(
    String owner,
    String repo, {
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final payload = <String, dynamic>{'merge_method': mergeMethod};
    if (commitTitle != null && commitTitle.isNotEmpty) {
      payload['commit_title'] = commitTitle;
    }
    if (commitMessage != null && commitMessage.isNotEmpty) {
      payload['commit_message'] = commitMessage;
    }
    try {
      final response = await _dio.put(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/merge',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw const FormatException(
        'Unexpected payload from merge PUT',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Closes a pull request by setting its state to "closed".
  Future<void> closePullRequest(
    String owner,
    String repo, {
    required int prNumber,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _dio.patch(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber',
        data: {'state': 'closed'},
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Updates a pull request's [title] and/or [body]. Only the non-null fields
  /// are sent, so a title-only edit doesn't clobber the body and vice-versa.
  /// Returns the updated PR.
  Future<GitHubPullRequest> updatePullRequest(
    String owner,
    String repo, {
    required int prNumber,
    String? title,
    String? body,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final payload = <String, dynamic>{
      'title': ?title,
      'body': ?body,
    };
    try {
      final response = await _dio.patch(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber',
        data: payload,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GitHubPullRequest.fromJson(data);
      }
      throw const FormatException('Unexpected payload from PR update PATCH');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Adds [logins] as assignees on the issue/PR. GitHub caps each call at 10
  /// assignees and silently ignores logins without push access.
  Future<void> addAssignees(
    String owner,
    String repo, {
    required int prNumber,
    required List<String> logins,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (logins.isEmpty) {
      return;
    }
    try {
      await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$prNumber/assignees',
        data: {'assignees': logins},
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Removes [logins] from the issue/PR's assignees.
  Future<void> removeAssignees(
    String owner,
    String repo, {
    required int prNumber,
    required List<String> logins,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (logins.isEmpty) {
      return;
    }
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/issues/$prNumber/assignees',
        data: {'assignees': logins},
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Requests reviews from the given user [reviewers] (logins) and
  /// [teamReviewers] (team slugs) on the PR.
  Future<void> requestReviewers(
    String owner,
    String repo, {
    required int prNumber,
    List<String> reviewers = const [],
    List<String> teamReviewers = const [],
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (reviewers.isEmpty && teamReviewers.isEmpty) {
      return;
    }
    try {
      await _dio.post(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/requested_reviewers',
        data: {
          'reviewers': reviewers,
          'team_reviewers': teamReviewers,
        },
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Cancels review requests from the given user [reviewers] (logins) and
  /// [teamReviewers] (team slugs) on the PR.
  Future<void> removeRequestedReviewers(
    String owner,
    String repo, {
    required int prNumber,
    List<String> reviewers = const [],
    List<String> teamReviewers = const [],
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (reviewers.isEmpty && teamReviewers.isEmpty) {
      return;
    }
    try {
      await _dio.delete(
        '$githubApiBaseUrl/repos/$owner/$repo/pulls/$prNumber/requested_reviewers',
        data: {
          'reviewers': reviewers,
          'team_reviewers': teamReviewers,
        },
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Lists users who can be assigned to issues/PRs in [owner]/[repo]
  /// (i.e. users with push access). Paginates fully.
  Future<List<GitHubUser>> listAssignableUsers(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final users = <GitHubUser>[];
    var page = 1;
    try {
      while (true) {
        final response = await _dio.get(
          '$githubApiBaseUrl/repos/$owner/$repo/assignees',
          queryParameters: {'per_page': 100, 'page': page},
          cancelToken: cancelToken,
        );
        users.addAll(_decodeList(response.data, GitHubUser.fromJson));
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return users;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  /// Lists teams that have access to [owner]/[repo] (and so can be requested
  /// as reviewers). Returns an empty list on 404 (a personal repo, or an org
  /// repo the token can't list teams for). Paginates fully.
  Future<List<GitHubTeam>> listRequestableTeams(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final teams = <GitHubTeam>[];
    var page = 1;
    try {
      while (true) {
        final response = await _dio.get(
          '$githubApiBaseUrl/repos/$owner/$repo/teams',
          queryParameters: {'per_page': 100, 'page': page},
          cancelToken: cancelToken,
        );
        teams.addAll(_decodeList(response.data, GitHubTeam.fromJson));
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return teams;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      if (e.response?.statusCode == 404) {
        return const [];
      }
      throw mapDioException(e);
    }
  }

  /// Searches issues + PRs in [owner]/[repo] matching the free-text [query].
  /// Returns lightweight `(number, title)` hits for `#`-reference
  /// autocomplete. Best-effort: returns an empty list on any non-cancel error
  /// (autocomplete must never throw into the editor).
  Future<List<({int number, String title})>> searchIssues(
    String owner,
    String repo,
    String query, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final q = query.trim();
    try {
      final response = await _dio.get(
        '$githubApiBaseUrl/search/issues',
        queryParameters: {
          'q': 'repo:$owner/$repo ${q.isEmpty ? 'state:open' : q}',
          'per_page': 8,
        },
        cancelToken: cancelToken,
      );
      final items = (response.data as Map<String, dynamic>?)?['items'] as List?;
      return <({int number, String title})>[
        for (final it in (items ?? const []).whereType<Map<String, dynamic>>())
          (
            number: (it['number'] as num?)?.toInt() ?? 0,
            title: it['title'] as String? ?? '',
          ),
      ];
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      return const [];
    }
  }

  void _requireOwnerRepo(String owner, String repo) {
    if (owner.isEmpty || repo.isEmpty) {
      throw ArgumentError('owner and repo must not be empty');
    }
  }

  List<T> _decodeList<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) {
      return <T>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
}
