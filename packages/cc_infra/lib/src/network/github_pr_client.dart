import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/github/github_http.dart' show isHttpStatus;
import 'package:cc_infra/src/network/github_merge_error.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_commit.dart';
import 'package:cc_infra/src/network/models/github_commit_status.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_job_run.dart';
import 'package:cc_infra/src/network/models/github_label.dart';
import 'package:cc_infra/src/network/models/github_pr_stack.dart';
import 'package:cc_infra/src/network/models/github_pull_request.dart';
import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:cc_infra/src/network/models/github_reaction.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';
import 'package:cc_infra/src/network/models/github_team.dart';
import 'package:cc_infra/src/network/models/github_timeline_event.dart';
import 'package:cc_infra/src/network/models/github_workflow_run.dart';
import 'package:rhttp/rhttp.dart';

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

/// Client for GitHub PR-related REST API endpoints.
class GitHubPrClient {
  /// Creates a [GitHubPrClient] backed by [RhttpClient].
  ///
  /// [_downloadHttpClient] is a plain client used for the second hop of log
  /// downloads: the logs endpoint 302-redirects to a signed Azure URL and
  /// re-sending the authed client's `Authorization` header on that redirect
  /// would leak the token. Tests inject a mock here.
  GitHubPrClient(
    RhttpClient httpClient, {
    this._downloadHttpClient,
    this._redirectlessHttpClient,
  }) : _httpClient = httpClient;

  final RhttpClient _httpClient;

  /// Lazily replaced with a created client on first use by [_download] /
  /// [_redirectless], so they cannot be `final`.
  RhttpClient? _downloadHttpClient;
  RhttpClient? _redirectlessHttpClient;

  /// The plain, unauthenticated client for the second hop of a log download (a
  /// signed Azure URL): re-sending the authed client's `Authorization` header
  /// there would leak the token.
  ///
  /// A bare client has NO timeouts at all, so a stalled signed-URL hop could
  /// hang the RPC that asked for the logs indefinitely. These are generous —
  /// a CI log can be tens of megabytes on a slow link — but finite.
  RhttpClient get _download => _downloadHttpClient ??= createHttpClient(
    settings: const ClientSettings(
      timeoutSettings: TimeoutSettings(
        connectTimeout: Duration(seconds: 20),
        timeout: Duration(minutes: 3),
      ),
    ),
  );

  /// A sibling of the authed client with redirects disabled: the logs endpoint
  /// answers 302 with the signed URL in `Location`, and following it on the
  /// authed client would forward `Authorization` to Azure. rhttp picks the
  /// redirect policy per client, so it is copied along with the base URL and
  /// the interceptors (the auth header source).
  RhttpClient get _redirectless => _redirectlessHttpClient ??= createHttpClient(
    settings: _httpClient.settings.copyWith(
      redirectSettings: const RedirectSettings.none(),
    ),
    interceptors: [
      if (_httpClient.interceptor != null) _httpClient.interceptor!,
    ],
  );

  static const _pullsPerPage = 100;

  /// Lists open pull requests for [owner]/[repo], one page at a time.
  /// Returns a [PaginatedPullRequests] with the current page's items and a
  /// flag indicating whether more pages are available.
  Future<PaginatedPullRequests> listOpenPullRequestsPage(
    String owner,
    String repo, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls',
        query: {'state': 'open', 'per_page': '$_pullsPerPage', 'page': '$page'},
        cancelToken: cancelToken,
      );
      final items = _decodeList(
        httpJsonBody(response),
        GitHubPullRequest.fromJson,
      );
      final hasMore = _hasNextPage(response);
      return PaginatedPullRequests(items: items, hasMore: hasMore);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Pages PRs for one head ref across every state. Unlike the open-list
  /// poll, this is a one-time, branch-scoped history discovery; `head` is
  /// qualified by the repository owner and the API paginates the complete
  /// result so a closed PR cannot be hidden behind the first 100.
  Future<PaginatedPullRequests> listBranchPullRequestsPage(
    String owner,
    String repo,
    String branch, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls',
        query: {
          'state': 'all',
          'head': '$owner:$branch',
          'per_page': '$_pullsPerPage',
          'page': '$page',
        },
        cancelToken: cancelToken,
      );
      return PaginatedPullRequests(
        items: _decodeList(httpJsonBody(response), GitHubPullRequest.fromJson),
        hasMore: _hasNextPage(response),
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  static bool _hasNextPage(HttpTextResponse response) {
    final link = response.headerMap['link'];
    if (link == null) {
      return false;
    }
    return link.contains('rel="next"');
  }

  /// Cheap change probe for the open-PR list of [owner]/[repo], using a
  /// conditional request. Presents [etag] as `If-None-Match`; GitHub answers
  /// 304 (rate-limit-free) when nothing changed, or 200 with a fresh ETag when
  /// it did. The 200 body is deliberately discarded — callers that learn of a
  /// change re-fetch through the enriched GraphQL batch, so decoding it here
  /// would be wasted work.
  ///
  /// Note the probe reflects list-level changes (PRs opened/closed/updated);
  /// CI check state does not bump it and needs its own pass.
  Future<ConditionalPrListProbe> probeOpenPullRequests(
    String owner,
    String repo, {
    String? etag,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls',
        query: {'state': 'open', 'per_page': '$_pullsPerPage', 'page': '1'},
        headers: HttpHeaders.rawMap({
          if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
        }),
        cancelToken: cancelToken,
      );
      if (response.statusCode == 304) {
        return const ConditionalPrListProbe(changed: false);
      }
      return ConditionalPrListProbe(
        changed: true,
        etag: response.headerMap['etag'],
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Lists open pull requests that have requested reviews for the authenticated user.
  Future<List<GitHubPullRequest>> listRequestedReviews(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/search/issues',
        query: {
          'q': 'type:pr state:open review-requested:@me repo:$owner/$repo',
        },
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final map = data as Map<String, dynamic>?;
      final items = map?['items'] as List?;
      return _decodeList(items, GitHubPullRequest.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/search/issues',
        query: {'q': 'type:pr state:open reviewed-by:@me repo:$owner/$repo'},
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
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
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Searches the non-open (merged + closed) pull requests authored by
  /// [author] in [owner]/[repo], one [_pullsPerPage]-sized [page] at a time,
  /// most-recently-updated first. `hasMore` (from the `Link` header) drives the
  /// caller's "load more". (GitHub's search API only pages through the first
  /// 1000 results — beyond that `hasMore` stays false; the accurate *total*
  /// comes from `GitHubGraphqlClient.prCountsByAuthor`, not this list.)
  ///
  /// GitHub treats merged PRs as `state:closed`, so a single `state:closed`
  /// query returns both merged and unmerged-closed PRs. Results are
  /// issue-shaped: the merge timestamp comes back under `pull_request.merged_at`
  /// (recovered by [GitHubPullRequest.fromJson]), letting callers split merged
  /// from closed via the mapped `mergedAt`. Diff size / check status are not
  /// included (no GraphQL metrics enrichment for non-open PRs).
  Future<PaginatedPullRequests> searchClosedPullRequestsByAuthor(
    String owner,
    String repo,
    String author, {
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final q = 'type:pr state:closed author:$author repo:$owner/$repo';
    try {
      final response = await _httpClient.get(
        '/search/issues',
        query: {
          'q': q,
          'per_page': '$_pullsPerPage',
          'page': '$page',
          'sort': 'updated',
          'order': 'desc',
        },
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final map = data as Map<String, dynamic>?;
      final items = map?['items'] as List?;
      return PaginatedPullRequests(
        items: _decodeList(items, GitHubPullRequest.fromJson),
        hasMore: _hasNextPage(response),
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  // `full+json` returns body, body_html, body_text together with reactions.
  // body_html is required so private user-attachment URLs come back as
  // self-signed `private-user-images.githubusercontent.com` JWT URLs the
  // app can fetch without a github.com session cookie.
  static const _fullBodyHeader = <String, String>{
    'Accept': 'application/vnd.github.full+json',
  };

  // The reaction-only endpoint does not need expanded HTML bodies.
  static const _reactionsHeader = <String, String>{
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/$number',
        headers: const HttpHeaders.rawMap(_fullBodyHeader),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubPullRequest.fromJson(data);
      }
      return null;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Fetches the reaction summary for an issue (not a PR) by issue number.
  Future<GitHubReactionSummary?> getIssueReactionSummary(
    String owner,
    String repo,
    int issueNumber, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/issues/$issueNumber',
        headers: const HttpHeaders.rawMap(_reactionsHeader),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic> &&
          data['reactions'] is Map<String, dynamic>) {
        return GitHubReactionSummary.fromJson(
          data['reactions'] as Map<String, dynamic>,
        );
      }
      return null;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/$number',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github.diff',
        }),
        cancelToken: cancelToken,
      );
      return response.body;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
        final response = await _httpClient.get(
          '/repos/$owner/$repo/pulls/$number/files',
          query: {'per_page': '$_filesPerPage', 'page': '$page'},
          cancelToken: cancelToken,
        );
        batch = _decodeList(
          httpJsonBody(response),
          GitHubPullRequestFile.fromJson,
        );
      } on RhttpException catch (e) {
        if (e is RhttpCancelException) {
          rethrow;
        }
        throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/$number/commits',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubCommit.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
        final response = await _httpClient.get(
          '/repos/$owner/$repo/pulls/$number/commits',
          query: {'per_page': '$_commitsPerPage', 'page': '$page'},
          cancelToken: cancelToken,
        );
        final batch = _decodeList(
          httpJsonBody(response),
          GitHubCommit.fromJson,
        );
        all.addAll(batch);
        if (batch.length < _commitsPerPage || !_hasNextPage(response)) {
          break;
        }
      } on RhttpException catch (e) {
        if (e is RhttpCancelException) {
          rethrow;
        }
        throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/commits/$sha',
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubCommit.fromJson(data);
      }
      return null;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/commits/$sha',
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final raw = data is Map<String, dynamic> ? data['files'] : null;
      return _decodeList(raw, GitHubPullRequestFile.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/$number/reviews',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubReview.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/$number/comments',
        query: {'per_page': '100'},
        headers: const HttpHeaders.rawMap(_fullBodyHeader),
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubReviewComment.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/issues/$number/comments',
        query: {'per_page': '100'},
        headers: const HttpHeaders.rawMap(_fullBodyHeader),
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubIssueComment.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Lists conversation-timeline events for the PR, filtered to the kinds
  /// the activity feed renders (`review_requested` / `review_request_removed`
  /// / `labeled` / `unlabeled`). Other event kinds (reviews, comments,
  /// commits) ride their dedicated endpoints.
  Future<List<GitHubTimelineEvent>> listTimelineEvents(
    String owner,
    String repo,
    int number, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/issues/$number/timeline',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubTimelineEvent.fromJson)
          .where(
            (e) =>
                e.event == 'review_requested' ||
                e.event == 'review_request_removed' ||
                e.event == 'labeled' ||
                e.event == 'unlabeled',
          )
          .toList(growable: false);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/commits/$ref/check-runs',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final raw = data is Map<String, dynamic> ? data['check_runs'] : null;
      return _decodeList(raw, GitHubCheckRun.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Lists commit statuses for a commit SHA via the combined-status API.
  ///
  /// Separate from [listCheckRuns]: this is the Statuses API, which is what
  /// Netlify (and some Vercel setups) use to publish a deploy-preview URL in
  /// each status's `target_url`.
  Future<List<GitHubCommitStatus>> listCommitStatuses(
    String owner,
    String repo,
    String ref, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (ref.isEmpty) {
      return <GitHubCommitStatus>[];
    }

    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/commits/$ref/status',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final raw = data is Map<String, dynamic> ? data['statuses'] : null;
      return _decodeList(raw, GitHubCommitStatus.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/repos/$owner/$repo/actions/runs',
        query: {'head_sha': headSha, 'per_page': '100'},
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final raw = data is Map<String, dynamic> ? data['workflow_runs'] : null;
      return _decodeList(raw, GitHubWorkflowRun.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Lists the jobs (latest attempt) of one workflow run. Used to resolve
  /// the Actions job id backing a check run via `check_run_url`.
  Future<List<GitHubJobRun>> listWorkflowRunJobs(
    String owner,
    String repo,
    int runId, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/actions/runs/$runId/jobs',
        query: {'per_page': '100'},
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final raw = data is Map<String, dynamic> ? data['jobs'] : null;
      return _decodeList(raw, GitHubJobRun.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Fetches one Actions job (status + steps). Returns null on 404.
  Future<GitHubJobRun?> getJobRun(
    String owner,
    String repo,
    int jobId, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/actions/jobs/$jobId',
        cancelToken: cancelToken,
      );
      return GitHubJobRun.fromJson(
        httpJsonBody(response) as Map<String, dynamic>,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      if (isHttpStatus(e, 404)) {
        return null;
      }
      throw mapHttpException(e);
    }
  }

  /// Fetches one workflow run (for its `path` + `headSha`, the workflow-YAML
  /// coordinates). Returns null on 404.
  Future<GitHubWorkflowRun?> getWorkflowRun(
    String owner,
    String repo,
    int runId, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/actions/runs/$runId',
        cancelToken: cancelToken,
      );
      return GitHubWorkflowRun.fromJson(
        httpJsonBody(response) as Map<String, dynamic>,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      if (isHttpStatus(e, 404)) {
        return null;
      }
      throw mapHttpException(e);
    }
  }

  /// Downloads the plain-text log of a completed job, keeping only the last
  /// [maxBytes]. Null when GitHub has no logs (job running, logs expired).
  ///
  /// The logs endpoint 302-redirects to a signed Azure URL; the first hop
  /// deliberately goes through the redirect-less [_redirectless] and the
  /// download hop through the plain [_download] so the authed client's
  /// `Authorization` header is never forwarded to the redirect target.
  Future<({String text, bool truncated})?> getJobLogs(
    String owner,
    String repo,
    int jobId, {
    CancelToken? cancelToken,
    int maxBytes = 512 * 1024,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final HttpTextResponse head;
      try {
        head = await _redirectless.get(
          '/repos/$owner/$repo/actions/jobs/$jobId/logs',
          cancelToken: cancelToken,
        );
      } on RhttpStatusCodeException catch (e) {
        // Client errors mean no accessible logs: the job may be running, its
        // logs expired, or the token lacks access. Server errors propagate.
        if (e.statusCode < 500) {
          return null;
        }
        throw mapHttpException(e);
      }
      if (head.statusCode == 404) {
        return null;
      }
      final location = head.headerMap['location'];
      if (location == null || head.statusCode ~/ 100 != 3) {
        return null;
      }
      final response = await _download.getStream(location);
      // Retain byte chunks without boxing each byte or shifting a large list.
      final window = Queue<Uint8List>();
      var buffered = 0;
      var total = 0;
      await for (final chunk in response.body) {
        total += chunk.length;
        window.add(chunk);
        buffered += chunk.length;
        // Drop whole leading chunks while the tail still covers the window,
        // then trim at most one chunk to land exactly on maxBytes.
        while (window.length > 1 &&
            buffered - window.first.length >= maxBytes) {
          buffered -= window.removeFirst().length;
        }
        if (buffered > maxBytes) {
          final first = window.removeFirst();
          final keep = maxBytes - (buffered - first.length);
          final trimmed = Uint8List.sublistView(first, first.length - keep);
          window.addFirst(trimmed);
          buffered = maxBytes;
        }
      }
      final tail = BytesBuilder(copy: false);
      for (final chunk in window) {
        tail.add(chunk);
      }
      return (
        text: utf8
            .decode(tail.takeBytes(), allowMalformed: true)
            .replaceAll('\r\n', '\n'),
        truncated: total > maxBytes,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      if (isHttpStatus(e, 404)) {
        return null;
      }
      throw mapHttpException(e);
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
      final response = await _httpClient.post(
        '/repos/$owner/$repo/pulls/$prNumber/comments',
        body: HttpBody.json(payload),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException(
        'Unexpected payload from review-comment POST',
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Replaces the body of a top-level conversation comment.
  ///
  /// The PR conversation is the issues API
  /// (`PATCH /issues/comments/{id}`), so this is how a GFM task-list
  /// checkbox in a comment (or a Renovate rebase-check in the PR body,
  /// which uses [updatePullRequest] instead) is persisted without opening
  /// the editor. Inline review comments have [editReviewComment].
  Future<GitHubIssueComment> updateIssueComment(
    String owner,
    String repo, {
    required int commentId,
    required String body,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.patch(
        '/repos/$owner/$repo/issues/comments/$commentId',
        body: HttpBody.json({'body': body}),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubIssueComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from comment PATCH');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Deletes a top-level conversation comment.
  ///
  /// GitHub allows this for the author and for anyone with write access on
  /// the repo. A 403/404 propagates as a mapped exception.
  Future<void> deleteIssueComment(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _httpClient.delete(
        '/repos/$owner/$repo/issues/comments/$commentId',
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Posts a top-level comment on a pull request's conversation timeline.
  ///
  /// The PR conversation is the issues API (`POST /issues/{n}/comments`), so
  /// this is the lane a bot answers a `@mention` in; inline threads have
  /// [replyToReviewComment] instead.
  Future<GitHubIssueComment> createIssueComment(
    String owner,
    String repo, {
    required int prNumber,
    required String body,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/issues/$prNumber/comments',
        body: HttpBody.json({'body': body}),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubIssueComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from comment POST');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.post(
        '/repos/$owner/$repo/pulls/$prNumber/comments/$parentCommentId/replies',
        body: HttpBody.json({'body': body}),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reply POST');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      await _httpClient.delete(
        '/repos/$owner/$repo/pulls/comments/$commentId',
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
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
      final response = await _httpClient.patch(
        '/repos/$owner/$repo/pulls/comments/$commentId',
        body: HttpBody.json({'body': body}),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReviewComment.fromJson(data);
      }
      throw const FormatException('Unexpected payload from comment PATCH');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Submits a pull request review with the given [event] (`APPROVE`,
  /// `REQUEST_CHANGES`, or `COMMENT`) and optional [body].
  ///
  /// Pass [comments] to attach inline (line-anchored) review comments in the
  /// same review, mirroring how a human reviewer leaves comments then submits.
  /// Each entry follows the GitHub reviews `comments[]` shape:
  /// `{path, line, side, body, start_line?, start_side?}`. GitHub rejects the
  /// **whole** review with 422 if any comment's `line` is not part of the PR
  /// diff, so callers that build comments from arbitrary findings should be
  /// prepared to retry without [comments].
  Future<GitHubReview> submitReview(
    String owner,
    String repo, {
    required int prNumber,
    required String event,
    String? body,
    String? commitId,
    List<Map<String, dynamic>>? comments,
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
    if (comments != null && comments.isNotEmpty) {
      payload['comments'] = comments;
    }
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/pulls/$prNumber/reviews',
        body: HttpBody.json(payload),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReview.fromJson(data);
      }
      throw const FormatException('Unexpected payload from review submit POST');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Creates a new pull request. When [draft] is true the PR is opened as a
  /// GitHub draft (`draft: true`); some repos/plans reject this with a 422.
  Future<Map<String, dynamic>> createPullRequest(
    String owner,
    String repo, {
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/pulls',
        body: HttpBody.json({
          'title': title,
          'body': body,
          'head': head,
          'base': base,
          'draft': draft,
        }),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {};
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }

      throw mapHttpException(e);
    }
  }

  /// Creates a reaction on a review comment.

  Future<GitHubReaction> createReviewCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/pulls/comments/$commentId/reactions',
        body: HttpBody.json({'content': content}),
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reaction POST');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Deletes a reaction from a review comment.
  Future<void> deleteReviewCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _httpClient.delete(
        '/repos/$owner/$repo/pulls/comments/$commentId/reactions/$reactionId',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Lists reactions on a review comment.
  Future<List<GitHubReaction>> listReviewCommentReactions(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/pulls/comments/$commentId/reactions',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubReaction.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Creates a reaction on an issue comment.
  Future<GitHubReaction> createIssueCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/issues/comments/$commentId/reactions',
        body: HttpBody.json({'content': content}),
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException('Unexpected payload from reaction POST');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Deletes a reaction from an issue comment.
  Future<void> deleteIssueCommentReaction(
    String owner,
    String repo, {
    required int commentId,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _httpClient.delete(
        '/repos/$owner/$repo/issues/comments/$commentId/reactions/$reactionId',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Lists reactions on an issue comment.
  Future<List<GitHubReaction>> listIssueCommentReactions(
    String owner,
    String repo, {
    required int commentId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/issues/comments/$commentId/reactions',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubReaction.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Creates a reaction on an issue (not a PR review comment).
  Future<GitHubReaction> createIssueReaction(
    String owner,
    String repo, {
    required int issueNumber,
    required String content,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/issues/$issueNumber/reactions',
        body: HttpBody.json({'content': content}),
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubReaction.fromJson(data);
      }
      throw const FormatException(
        'Unexpected payload from issue reaction POST',
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Deletes a reaction from an issue.
  Future<void> deleteIssueReaction(
    String owner,
    String repo, {
    required int issueNumber,
    required int reactionId,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      await _httpClient.delete(
        '/repos/$owner/$repo/issues/$issueNumber/reactions/$reactionId',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Lists reactions on an issue.
  Future<List<GitHubReaction>> listIssueReactions(
    String owner,
    String repo, {
    required int issueNumber,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/issues/$issueNumber/reactions',
        headers: const HttpHeaders.rawMap({
          'Accept': 'application/vnd.github+json',
        }),
        cancelToken: cancelToken,
      );
      return _decodeList(httpJsonBody(response), GitHubReaction.fromJson);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Merges a pull request.
  ///
  /// Returns a map with `merged` (bool), `message` (String) and `sha` (String).
  /// Throws when GitHub declines the merge (conflicts, a required check, a
  /// protection rule), carrying the forge's own reason.
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
      final response = await _httpClient.put(
        '/repos/$owner/$repo/pulls/$prNumber/merge',
        body: HttpBody.json(payload),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return data;
      }
      throw const FormatException('Unexpected payload from merge PUT');
    } on RhttpException catch (e) {
      mapPullRequestMergeError(e);
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
      await _httpClient.patch(
        '/repos/$owner/$repo/pulls/$prNumber',
        body: const HttpBody.json({'state': 'closed'}),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  // The stacks endpoints ship under a newer API version than the client's
  // default, so every stacks request pins it explicitly.
  static const _stacksHeaders = <String, String>{
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2026-03-10',
  };

  /// Lists the pull request stacks of [owner]/[repo], one page at a time.
  /// Pass [pullRequest] to filter to the stack containing that PR number.
  Future<PaginatedPrStacks> listStacks(
    String owner,
    String repo, {
    int? pullRequest,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/stacks',
        query: {
          'per_page': '$_pullsPerPage',
          'page': '$page',
          'pull_request': ?pullRequest?.toString(),
        },
        headers: const HttpHeaders.rawMap(_stacksHeaders),
        cancelToken: cancelToken,
      );
      return PaginatedPrStacks(
        items: _decodeList(httpJsonBody(response), GitHubPrStack.fromJson),
        hasMore: _hasNextPage(response),
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Gets the stack [stackNumber] of [owner]/[repo], or null when it doesn't
  /// exist (404).
  Future<GitHubPrStack?> getStack(
    String owner,
    String repo,
    int stackNumber, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/stacks/$stackNumber',
        headers: const HttpHeaders.rawMap(_stacksHeaders),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return GitHubPrStack.fromJson(data);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      if (isHttpStatus(e, 404)) {
        return null;
      }
      throw mapHttpException(e);
    }
  }

  /// Creates a stack from [pullRequests], ordered bottom to top. GitHub
  /// answers 422 unless each PR's base ref matches the previous PR's head
  /// ref — the caller is expected to order the chain first.
  Future<GitHubPrStack> createStack(
    String owner,
    String repo,
    List<int> pullRequests, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/stacks',
        body: HttpBody.json({'pull_requests': pullRequests}),
        headers: const HttpHeaders.rawMap(_stacksHeaders),
        cancelToken: cancelToken,
      );
      return GitHubPrStack.fromJson(
        httpJsonBody(response) as Map<String, dynamic>,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Appends [pullRequests] (ordered from the current top upward) onto the
  /// stack [stackNumber]. Returns the updated stack.
  Future<GitHubPrStack> addToStack(
    String owner,
    String repo,
    int stackNumber,
    List<int> pullRequests, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/stacks/$stackNumber/add',
        body: HttpBody.json({'pull_requests': pullRequests}),
        headers: const HttpHeaders.rawMap(_stacksHeaders),
        cancelToken: cancelToken,
      );
      return GitHubPrStack.fromJson(
        httpJsonBody(response) as Map<String, dynamic>,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Removes the unmerged pull requests from the stack [stackNumber]. Returns
  /// the updated stack, or null when nothing remained and the stack dissolved
  /// (GitHub answers 204).
  Future<GitHubPrStack?> unstack(
    String owner,
    String repo,
    int stackNumber, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.post(
        '/repos/$owner/$repo/stacks/$stackNumber/unstack',
        headers: const HttpHeaders.rawMap(_stacksHeaders),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return GitHubPrStack.fromJson(data);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
    final payload = <String, dynamic>{'title': ?title, 'body': ?body};
    try {
      final response = await _httpClient.patch(
        '/repos/$owner/$repo/pulls/$prNumber',
        body: HttpBody.json(payload),
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return GitHubPullRequest.fromJson(data);
      }
      throw const FormatException('Unexpected payload from PR update PATCH');
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      await _httpClient.post(
        '/repos/$owner/$repo/issues/$prNumber/assignees',
        body: HttpBody.json({'assignees': logins}),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      await _httpClient.delete(
        '/repos/$owner/$repo/issues/$prNumber/assignees',
        body: HttpBody.json({'assignees': logins}),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Lists labels defined on [owner]/[repo]. Paginates fully.
  Future<List<GitHubLabel>> listLabels(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final labels = <GitHubLabel>[];
    var page = 1;
    try {
      while (true) {
        final response = await _httpClient.get(
          '/repos/$owner/$repo/labels',
          query: {'per_page': '100', 'page': '$page'},
          cancelToken: cancelToken,
        );
        labels.addAll(
          _decodeList(httpJsonBody(response), GitHubLabel.fromJson),
        );
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return labels;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Adds [names] to the issue/PR. GitHub rejects a name the repository does
  /// not already define.
  Future<void> addLabels(
    String owner,
    String repo, {
    required int prNumber,
    required List<String> names,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    if (names.isEmpty) {
      return;
    }
    try {
      await _httpClient.post(
        '/repos/$owner/$repo/issues/$prNumber/labels',
        body: HttpBody.json({'labels': names}),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Removes each of [names] from the issue/PR. The name is a path segment,
  /// so it is percent-encoded (`bug/triage` must not become two segments).
  Future<void> removeLabels(
    String owner,
    String repo, {
    required int prNumber,
    required List<String> names,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      for (final name in names) {
        if (name.isEmpty) {
          continue;
        }
        await _httpClient.delete(
          '/repos/$owner/$repo/issues/$prNumber/labels/${Uri.encodeComponent(name)}',
          cancelToken: cancelToken,
        );
      }
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      await _httpClient.post(
        '/repos/$owner/$repo/pulls/$prNumber/requested_reviewers',
        body: HttpBody.json({
          'reviewers': reviewers,
          'team_reviewers': teamReviewers,
        }),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      await _httpClient.delete(
        '/repos/$owner/$repo/pulls/$prNumber/requested_reviewers',
        body: HttpBody.json({
          'reviewers': reviewers,
          'team_reviewers': teamReviewers,
        }),
        cancelToken: cancelToken,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
        final response = await _httpClient.get(
          '/repos/$owner/$repo/assignees',
          query: {'per_page': '100', 'page': '$page'},
          cancelToken: cancelToken,
        );
        users.addAll(_decodeList(httpJsonBody(response), GitHubUser.fromJson));
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return users;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
        final response = await _httpClient.get(
          '/repos/$owner/$repo/teams',
          query: {'per_page': '100', 'page': '$page'},
          cancelToken: cancelToken,
        );
        teams.addAll(_decodeList(httpJsonBody(response), GitHubTeam.fromJson));
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return teams;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      if (isHttpStatus(e, 404)) {
        return const [];
      }
      throw mapHttpException(e);
    }
  }

  /// Lists the branch names of [owner]/[repo]. Paginates fully. Only branches
  /// that exist on the remote are returned — which is exactly the set that can
  /// serve as a PR head or base.
  Future<List<String>> listBranches(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    final names = <String>[];
    var page = 1;
    try {
      while (true) {
        final response = await _httpClient.get(
          '/repos/$owner/$repo/branches',
          query: {'per_page': '100', 'page': '$page'},
          cancelToken: cancelToken,
        );
        final data = httpJsonBody(response);
        if (data is List) {
          for (final b in data.whereType<Map<String, dynamic>>()) {
            final name = b['name'] as String?;
            if (name != null && name.isNotEmpty) {
              names.add(name);
            }
          }
        }
        if (!_hasNextPage(response)) {
          break;
        }
        page++;
      }
      return names;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Returns the default branch (e.g. `main`) of [owner]/[repo].
  Future<String> getDefaultBranch(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo',
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is Map<String, dynamic>) {
        return data['default_branch'] as String? ?? '';
      }
      return '';
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  /// Compares [base]...[head] and returns the changed files plus commit count.
  /// The compare endpoint returns up to 300 files with the same shape as the
  /// PR-files endpoint, so the diff viewer can render them with no adaptation.
  Future<GitHubBranchComparison> compareBranches(
    String owner,
    String repo, {
    required String base,
    required String head,
    CancelToken? cancelToken,
  }) async {
    _requireOwnerRepo(owner, repo);
    try {
      final response = await _httpClient.get(
        '/repos/$owner/$repo/compare/$base...$head',
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final files = data is Map<String, dynamic>
          ? _decodeList(data['files'], GitHubPullRequestFile.fromJson)
          : <GitHubPullRequestFile>[];
      final totalCommits = data is Map<String, dynamic>
          ? (data['total_commits'] as num?)?.toInt() ?? 0
          : 0;
      final commits = data is Map<String, dynamic>
          ? _decodeList(data['commits'], GitHubCommit.fromJson)
          : <GitHubCommit>[];
      return GitHubBranchComparison(
        files: files,
        totalCommits: totalCommits,
        commits: commits,
      );
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
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
      final response = await _httpClient.get(
        '/search/issues',
        query: {
          'q': 'repo:$owner/$repo ${q.isEmpty ? 'state:open' : q}',
          'per_page': '8',
        },
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      final items = (data as Map<String, dynamic>?)?['items'] as List?;
      return <({int number, String title})>[
        for (final it in (items ?? const []).whereType<Map<String, dynamic>>())
          (
            number: (it['number'] as num?)?.toInt() ?? 0,
            title: it['title'] as String? ?? '',
          ),
      ];
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
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
