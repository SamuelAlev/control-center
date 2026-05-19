import 'package:cc_infra/src/network/bitbucket/models/bitbucket_activity_entry.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_branch.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_comment.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_commit.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_commit_status.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_diffstat_entry.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_json.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pipeline.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_pull_request.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_user.dart';
import 'package:cc_infra/src/network/bitbucket/models/bitbucket_workspace_member.dart';
import 'package:dio/dio.dart';

/// Client for the Bitbucket Cloud REST API 2.0.
///
/// Wire vocabulary only: every method returns a `Bitbucket*` model or a raw
/// string, never a domain entity. `BitbucketPrMapper`'s `…FromBitbucket`
/// functions do the anti-corruption translation and
/// `BitbucketForgePrClient` composes the two.
///
/// **The injected [Dio] owns the base URL and the credentials.** Authentication
/// (an app password's Basic header, or an OAuth bearer) is an interceptor the
/// caller installs; this client never constructs one and never names a host.
/// Every path here is RELATIVE — `/repositories/{workspace}/{repo}/…` — so
/// pointing the client at a different endpoint (a proxy, a test server) is a
/// matter of changing `BaseOptions.baseUrl` alone.
///
/// [DioException]s propagate untouched; callers that treat a specific status
/// as a value rather than a failure (a 404 on a pull request, a 401 on the
/// viewer) handle it themselves.
class BitbucketApiClient {
  /// Creates a [BitbucketApiClient] over [dio], which must already carry the
  /// Bitbucket API base URL and an auth interceptor.
  BitbucketApiClient(Dio dio) : _dio = dio;

  final Dio _dio;

  /// Bitbucket's maximum page size for list endpoints.
  static const int pageLen = 100;

  /// The largest `pagelen` the pull request list endpoint accepts. Lower than
  /// [pageLen]: Bitbucket caps this one collection at 50.
  static const int pullRequestPageLen = 50;

  /// Partial-response expansion asking Bitbucket to include the reviewer
  /// roster and the participant verdicts in a LIST response.
  ///
  /// The list representation of a pull request is leaner than the detail one
  /// and omits `participants`/`reviewers`, which are exactly what the review
  /// rollup reads. The `+` modifier ADDS to the default field set rather than
  /// replacing it, so everything else still comes back. Without this a listed
  /// pull request would report "no reviews" — indistinguishable from a pull
  /// request nobody has looked at.
  static const String _rosterFields = '+values.participants,+values.reviewers';

  /// How many pages a paginated read will follow before it stops.
  ///
  /// Bitbucket answers with a `next` link rather than a total, so an unbounded
  /// follow is an unbounded number of round trips against a repository we do
  /// not control. Ten pages is 1000 rows — well past any pull request a human
  /// reviews — and a truncated list degrades the UI, whereas an unbounded walk
  /// stalls it.
  static const int maxPages = 10;

  // ── Pull requests ────────────────────────────────────────────────────────

  /// Fetches one pull request, or null when Bitbucket answers 404.
  Future<BitbucketPullRequest?> getPullRequest(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    try {
      final response = await _dio.get<Object?>(
        '/repositories/$workspace/$repo/pullrequests/$id',
        cancelToken: cancelToken,
      );
      final json = asJsonMap(response.data);
      return json == null ? null : BitbucketPullRequest.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// One page of pull requests in [state] (`OPEN`, `MERGED`, `DECLINED`,
  /// `SUPERSEDED`), newest-activity first, plus whether Bitbucket had more.
  ///
  /// Deliberately a SINGLE page rather than a `next`-following read: the
  /// callers are feed surfaces that want a bounded, most-recent slice and a
  /// "load more" affordance, not the repository's whole history.
  ///
  /// [limit] is clamped to [pullRequestPageLen] — this endpoint caps `pagelen`
  /// at 50, lower than the 100 the rest of the API allows.
  ///
  /// [query] is a raw BBQL predicate (`author.nickname="jdoe"`); build its
  /// string literals with [bbqlLiteral] so a quote in the value cannot break
  /// out of the expression.
  Future<({List<BitbucketPullRequest> items, bool hasMore})>
  listPullRequestsPage(
    String workspace,
    String repo, {
    String state = 'OPEN',
    int limit = pullRequestPageLen,
    String? query,
    String sort = '-updated_on',
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.get<Object?>(
      '/repositories/$workspace/$repo/pullrequests',
      queryParameters: <String, dynamic>{
        'state': state,
        'sort': sort,
        'pagelen': limit.clamp(1, pullRequestPageLen),
        'fields': _rosterFields,
        if (query != null && query.isNotEmpty) 'q': query,
      },
      cancelToken: cancelToken,
    );
    final body = asJsonMap(response.data);
    final next = body?['next'] as String?;
    return (
      items: decodeJsonList(body?['values'], BitbucketPullRequest.fromJson),
      hasMore: next != null && next.isNotEmpty,
    );
  }

  /// Quotes and escapes [value] as a BBQL string literal, including the
  /// surrounding double quotes.
  ///
  /// BBQL has no parameter binding, so a value carrying a quote or a backslash
  /// would otherwise terminate the literal early and change the predicate.
  static String bbqlLiteral(String value) {
    final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    return '"$escaped"';
  }

  /// The unified diff of a pull request, as plain text.
  ///
  /// Bitbucket serves this endpoint as `text/plain` (via a redirect to a
  /// content-addressed URL), so the request asks for text and takes the
  /// response body raw — letting Dio's JSON transformer near it would throw on
  /// the first `@@` line.
  Future<String> getPullRequestDiff(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    return _getText(
      '/repositories/$workspace/$repo/pullrequests/$id/diff',
      cancelToken: cancelToken,
    );
  }

  /// The unified diff of an arbitrary revision [spec] — a commit hash, or a
  /// `head..base` pair — as plain text.
  Future<String> getDiff(
    String workspace,
    String repo,
    String spec, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getText(
      '/repositories/$workspace/$repo/diff/${_encodePath(spec)}',
      cancelToken: cancelToken,
    );
  }

  /// The per-file summary of a pull request's changes.
  Future<List<BitbucketDiffstatEntry>> listPullRequestDiffstat(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/pullrequests/$id/diffstat',
      BitbucketDiffstatEntry.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// The per-file summary of an arbitrary revision [spec] — a commit hash, or
  /// a `head..base` pair.
  Future<List<BitbucketDiffstatEntry>> listDiffstat(
    String workspace,
    String repo,
    String spec, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/diffstat/${_encodePath(spec)}',
      BitbucketDiffstatEntry.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// The commits reachable from [revision] but not from [exclude], alongside
  /// the collection total Bitbucket reported.
  ///
  /// This is Bitbucket's substitute for a compare endpoint: it has no single
  /// call that answers "what would a pull request from head to base contain",
  /// so the commit half of a comparison is a range read and the file half is a
  /// separate diffstat.
  ///
  /// `size` is null on this collection more often than not — Bitbucket omits
  /// the total for ranges it cannot count cheaply — in which case the caller
  /// only knows how many commits it actually received.
  Future<({List<BitbucketCommit> items, int? size})> listCommitsExcluding(
    String workspace,
    String repo,
    String revision, {
    required String exclude,
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPagedResult(
      '/repositories/$workspace/$repo/commits/${_encodePath(revision)}',
      BitbucketCommit.fromJson,
      queryParameters: <String, dynamic>{'exclude': exclude},
      cancelToken: cancelToken,
    );
  }

  /// The commits on a pull request. Bitbucket returns them newest-first.
  Future<List<BitbucketCommit>> listPullRequestCommits(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/pullrequests/$id/commits',
      BitbucketCommit.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Every comment on a pull request — inline and top-level alike, since
  /// Bitbucket serves both from this one endpoint.
  Future<List<BitbucketComment>> listPullRequestComments(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/pullrequests/$id/comments',
      BitbucketComment.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// The activity feed of a pull request (updates, approvals, comments),
  /// newest first.
  Future<List<BitbucketActivityEntry>> listPullRequestActivity(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/pullrequests/$id/activity',
      BitbucketActivityEntry.fromJson,
      cancelToken: cancelToken,
    );
  }

  // ── Pull request writes ──────────────────────────────────────────────────

  /// Posts a comment. [payload] is the raw Bitbucket body — `content.raw`
  /// plus, optionally, `inline` (for a file anchor) or `parent` (for a reply).
  Future<BitbucketComment?> createPullRequestComment(
    String workspace,
    String repo,
    int id,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/comments',
      data: payload,
      cancelToken: cancelToken,
    );
    final json = asJsonMap(response.data);
    return json == null ? null : BitbucketComment.fromJson(json);
  }

  /// Records the caller's approval of a pull request.
  Future<void> approvePullRequest(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/approve',
      cancelToken: cancelToken,
    );
  }

  /// Withdraws the caller's approval of a pull request.
  Future<void> unapprovePullRequest(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    await _dio.delete<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/approve',
      cancelToken: cancelToken,
    );
  }

  /// Records the caller's "changes requested" verdict on a pull request.
  Future<void> requestChanges(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/request-changes',
      cancelToken: cancelToken,
    );
  }

  /// Merges a pull request with [payload] (`merge_strategy`, `message`,
  /// `close_source_branch`).
  ///
  /// Returns the HTTP status alongside the decoded pull request. Bitbucket may
  /// answer **202 Accepted** and complete the merge asynchronously, in which
  /// case the body is a task handle rather than a pull request and the decoded
  /// pull request is null — a caller must not read that as "merged".
  Future<({int statusCode, BitbucketPullRequest? pullRequest})>
  mergePullRequest(
    String workspace,
    String repo,
    int id,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/merge',
      data: payload,
      cancelToken: cancelToken,
    );
    final json = asJsonMap(response.data);
    final pr = json != null && json['id'] is num
        ? BitbucketPullRequest.fromJson(json)
        : null;
    return (statusCode: response.statusCode ?? 0, pullRequest: pr);
  }

  /// Declines (closes without merging) a pull request.
  Future<void> declinePullRequest(
    String workspace,
    String repo,
    int id, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id/decline',
      cancelToken: cancelToken,
    );
  }

  /// Opens a pull request. [payload] is the raw Bitbucket body (`title`,
  /// `description`, `source.branch.name`, `destination.branch.name`).
  Future<BitbucketPullRequest?> createPullRequest(
    String workspace,
    String repo,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.post<Object?>(
      '/repositories/$workspace/$repo/pullrequests',
      data: payload,
      cancelToken: cancelToken,
    );
    final json = asJsonMap(response.data);
    return json == null ? null : BitbucketPullRequest.fromJson(json);
  }

  /// Updates a pull request in place.
  ///
  /// Bitbucket models every mutation of an open pull request — title, body and
  /// the reviewer roster alike — as a `PUT` of the fields being changed. There
  /// is no dedicated reviewers endpoint, which is why setting reviewers means
  /// read-modify-write of this same resource.
  Future<BitbucketPullRequest?> updatePullRequest(
    String workspace,
    String repo,
    int id,
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.put<Object?>(
      '/repositories/$workspace/$repo/pullrequests/$id',
      data: payload,
      cancelToken: cancelToken,
    );
    final json = asJsonMap(response.data);
    return json == null ? null : BitbucketPullRequest.fromJson(json);
  }

  // ── CI ───────────────────────────────────────────────────────────────────

  /// The build statuses published against [sha].
  Future<List<BitbucketCommitStatus>> listCommitStatuses(
    String workspace,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/commit/${_encodePath(sha)}/statuses',
      BitbucketCommitStatus.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// Bitbucket Pipelines runs that targeted [sha], newest first.
  ///
  /// A supplement to [listCommitStatuses], not a replacement: a Pipelines run
  /// also publishes a build status, so merging both into one check list would
  /// double-count. Use this when the native run number, trigger or target ref
  /// is wanted.
  Future<List<BitbucketPipeline>> listPipelinesForCommit(
    String workspace,
    String repo,
    String sha, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/pipelines/',
      BitbucketPipeline.fromJson,
      queryParameters: <String, dynamic>{
        'target.commit.hash': sha,
        'sort': '-created_on',
      },
      cancelToken: cancelToken,
    );
  }

  // ── Repository ───────────────────────────────────────────────────────────

  /// The repository's branches, most-recently-committed first.
  ///
  /// [limit] caps the read to a single page of that size (clamped to
  /// [pageLen]); omitting it walks up to [maxPages]. The compose-PR picker
  /// wants the newest handful, so it passes a limit and pays one round trip.
  Future<List<BitbucketBranch>> listBranches(
    String workspace,
    String repo, {
    int? limit,
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final path = '/repositories/$workspace/$repo/refs/branches';
    const sort = <String, dynamic>{'sort': '-target.date'};
    if (limit == null || limit <= 0) {
      return _getPaged(
        path,
        BitbucketBranch.fromJson,
        queryParameters: sort,
        cancelToken: cancelToken,
      );
    }
    final response = await _dio.get<Object?>(
      path,
      queryParameters: <String, dynamic>{
        ...sort,
        'pagelen': limit.clamp(1, pageLen),
      },
      cancelToken: cancelToken,
    );
    return decodeJsonList(
      asJsonMap(response.data)?['values'],
      BitbucketBranch.fromJson,
    );
  }

  /// The repository's default branch name (`mainbranch.name`), or `''` when
  /// the repository reports none.
  ///
  /// An empty string means Bitbucket answered but named no main branch (an
  /// empty repository). A repository that cannot be READ throws — that is a
  /// different fact from "this repository has no default branch".
  Future<String> getDefaultBranch(
    String workspace,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    _requireCoordinate(workspace, repo);
    final response = await _dio.get<Object?>(
      '/repositories/$workspace/$repo',
      cancelToken: cancelToken,
    );
    final body = asJsonMap(response.data);
    return asJsonMap(body?['mainbranch'])?['name'] as String? ?? '';
  }

  // ── Content and accounts ─────────────────────────────────────────────────

  /// The raw content of [path] at [ref] (a commit hash, branch or tag).
  Future<String> getFileContent(
    String workspace,
    String repo,
    String path,
    String ref, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getText(
      '/repositories/$workspace/$repo/src/'
      '${_encodePath(ref)}/${_encodePath(path)}',
      cancelToken: cancelToken,
    );
  }

  /// The authenticated account, or null when the credentials are missing or
  /// rejected (401/403). Every other failure propagates.
  Future<BitbucketUser?> getCurrentUser({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<Object?>(
        '/user',
        cancelToken: cancelToken,
      );
      final json = asJsonMap(response.data);
      return json == null ? null : BitbucketUser.fromJson(json);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        return null;
      }
      rethrow;
    }
  }

  /// The members of [workspace] — the pool every reviewer picker draws from,
  /// and the only index from a human-readable handle back to an account uuid.
  Future<List<BitbucketWorkspaceMember>> listWorkspaceMembers(
    String workspace, {
    CancelToken? cancelToken,
  }) {
    if (workspace.isEmpty) {
      throw ArgumentError.value(workspace, 'workspace', 'must not be empty');
    }
    return _getPaged(
      '/workspaces/$workspace/members',
      BitbucketWorkspaceMember.fromJson,
      cancelToken: cancelToken,
    );
  }

  /// The repository's default reviewers — Bitbucket's own suggestion for who
  /// should look at a change here.
  Future<List<BitbucketUser>> listDefaultReviewers(
    String workspace,
    String repo, {
    CancelToken? cancelToken,
  }) {
    _requireCoordinate(workspace, repo);
    return _getPaged(
      '/repositories/$workspace/$repo/default-reviewers',
      BitbucketUser.fromJson,
      cancelToken: cancelToken,
    );
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Reads a paginated Bitbucket collection, following `next` for at most
  /// [maxPages] pages.
  ///
  /// The `next` link is an absolute URL, but re-requesting it verbatim would
  /// route around the injected Dio's base URL. Only its query string is
  /// carried forward instead — that is where the cursor lives (`page` on most
  /// endpoints, an opaque `ctx` on the commit feeds), so paging stays correct
  /// AND every request stays relative.
  Future<List<T>> _getPaged<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final result = await _getPagedResult(
      path,
      fromJson,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    return result.items;
  }

  /// [_getPaged], additionally reporting the collection total Bitbucket
  /// declared on the first page.
  ///
  /// `size` is null whenever Bitbucket withheld it, which it does for
  /// collections it cannot count cheaply. Null therefore means "unknown", NOT
  /// zero — a caller wanting a true total must treat it as such rather than
  /// substituting the number of rows it happened to receive.
  Future<({List<T> items, int? size})> _getPagedResult<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final results = <T>[];
    int? size;
    var params = <String, dynamic>{...?queryParameters, 'pagelen': pageLen};
    for (var page = 0; page < maxPages; page++) {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: params,
        cancelToken: cancelToken,
      );
      final body = asJsonMap(response.data);
      if (page == 0) {
        size = (body?['size'] as num?)?.toInt();
      }
      results.addAll(decodeJsonList(body?['values'], fromJson));
      final next = body?['next'] as String?;
      if (next == null || next.isEmpty) {
        break;
      }
      final uri = Uri.tryParse(next);
      if (uri == null || uri.queryParameters.isEmpty) {
        break;
      }
      params = <String, dynamic>{...uri.queryParameters};
    }
    return (items: results, size: size);
  }

  /// GETs [path] as plain text, bypassing JSON decoding.
  Future<String> _getText(String path, {CancelToken? cancelToken}) async {
    final response = await _dio.get<String>(
      path,
      options: Options(
        headers: <String, dynamic>{'Accept': 'text/plain'},
        responseType: ResponseType.plain,
      ),
      cancelToken: cancelToken,
    );
    return response.data ?? '';
  }

  /// Percent-encodes each segment of [value] while preserving the `/`
  /// separators, so a branch name like `feature/x` or a path with spaces
  /// survives interpolation into a URL.
  static String _encodePath(String value) =>
      value.split('/').map(Uri.encodeComponent).join('/');

  static void _requireCoordinate(String workspace, String repo) {
    if (workspace.isEmpty || repo.isEmpty) {
      throw ArgumentError('workspace and repo must not be empty');
    }
  }
}
