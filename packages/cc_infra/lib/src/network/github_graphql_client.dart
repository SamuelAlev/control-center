/// @docImport 'package:cc_domain/core/domain/events/pr_events.dart';
library;

import 'dart:math' show max, min;

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/github_team_profile.dart';
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/entities/github_user_profile.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show githubPrConversationMentionLogin;
import 'package:cc_infra/src/network/app_network.dart'
    show expectStatuses, maxRetriesOption;
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/github/github_http.dart';
import 'package:cc_infra/src/network/models/github_graphql_results.dart';
import 'package:cc_infra/src/network/models/github_pr_review_state.dart';
import 'package:cc_infra/src/network/models/github_team.dart';
import 'package:cc_infra/src/network/models/github_viewer_activity.dart';
import 'package:rhttp/rhttp.dart';

/// One bounded `(repos, authors)` slice for profile PR count/search queries.
typedef ProfileSearchChunk = ({
  List<({String owner, String name})> repos,
  List<String> authors,
});

/// Client for GitHub GraphQL API mutations and queries.
class GitHubGraphQLClient {
  /// Creates a [GitHubGraphQLClient] backed by [RhttpClient].
  GitHubGraphQLClient(RhttpClient httpClient) : _httpClient = httpClient;

  final RhttpClient _httpClient;

  /// Marks a file as viewed in a pull request.
  Future<void> markFileAsViewed({
    required String pullRequestId,
    required String path,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation MarkFileAsViewed($pullRequestId: ID!, $path: String!) {
        markFileAsViewed(input: {pullRequestId: $pullRequestId, path: $path}) {
          clientMutationId
        }
      }
    ''';
    try {
      await _httpClient.post(
        '/graphql',
        body: HttpBody.json({
          'query': mutation,
          'variables': {'pullRequestId': pullRequestId, 'path': path},
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

  /// Returns the viewer's `viewerViewedState` for every file in the given
  /// PR, keyed by path. Values are the raw GraphQL enum names
  /// (`UNVIEWED` / `VIEWED` / `DISMISSED`). Paginates through the
  /// `pullRequest.files` connection.
  Future<Map<String, String>> getFileViewedStates({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $number: Int!, $after: String) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            files(first: 100, after: $after) {
              pageInfo { hasNextPage endCursor }
              nodes { path viewerViewedState }
            }
          }
        }
      }
    ''';

    final result = <String, String>{};
    String? cursor;
    while (true) {
      final response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
        'number': number,
        'after': cursor,
      }, cancelToken);
      final data = response?['data'] as Map<String, dynamic>?;
      final repository = data?['repository'] as Map<String, dynamic>?;
      final pullRequest = repository?['pullRequest'] as Map<String, dynamic>?;
      final files = pullRequest?['files'] as Map<String, dynamic>?;
      if (files == null) {
        break;
      }
      final nodes = files['nodes'] as List?;
      if (nodes != null) {
        for (final node in nodes.whereType<Map<String, dynamic>>()) {
          final path = node['path'] as String?;
          final state = node['viewerViewedState'] as String?;
          if (path != null && state != null) {
            result[path] = state;
          }
        }
      }
      final pageInfo = files['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      cursor = pageInfo?['endCursor'] as String?;
      if (!hasNext || cursor == null) {
        break;
      }
    }
    return result;
  }

  /// Every inline review thread on a PR with its conversation state and the
  /// numeric ids of its comments.
  ///
  /// REST's review-comment payload has no `resolved` field — resolution lives
  /// on the thread object, which is GraphQL-only. `databaseId` is what ties a
  /// thread back to the REST comments the diff renders, so nothing here needs a
  /// second lookup per comment.
  ///
  /// Paginates threads (100/page); a thread's comments are capped at 100, which
  /// is far past any real conversation and only ever costs the thread↔comment
  /// link for the overflow, never the thread's own state.
  Future<List<GitHubReviewThread>> listReviewThreads({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $number: Int!, $after: String) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            reviewThreads(first: 100, after: $after) {
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                isResolved
                isOutdated
                resolvedBy { login }
                comments(first: 100) { nodes { databaseId } }
              }
            }
          }
        }
      }
    ''';

    final out = <GitHubReviewThread>[];
    String? cursor;
    while (true) {
      final response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
        'number': number,
        'after': cursor,
      }, cancelToken);
      final data = response?['data'] as Map<String, dynamic>?;
      final repository = data?['repository'] as Map<String, dynamic>?;
      final pullRequest = repository?['pullRequest'] as Map<String, dynamic>?;
      final threads = pullRequest?['reviewThreads'] as Map<String, dynamic>?;
      if (threads == null) {
        break;
      }
      for (final node
          in (threads['nodes'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        final id = node['id'] as String?;
        if (id == null || id.isEmpty) {
          continue;
        }
        final comments = node['comments'] as Map<String, dynamic>?;
        final resolvedByRaw =
            (node['resolvedBy'] as Map<String, dynamic>?)?['login'] as String?;
        final resolvedByLogin =
            resolvedByRaw != null && resolvedByRaw.isNotEmpty
            ? resolvedByRaw
            : null;
        out.add(
          GitHubReviewThread(
            id: id,
            isResolved: node['isResolved'] as bool? ?? false,
            isOutdated: node['isOutdated'] as bool? ?? false,
            resolvedByLogin: resolvedByLogin,
            commentIds: [
              for (final c
                  in (comments?['nodes'] as List? ?? const [])
                      .whereType<Map<String, dynamic>>())
                if ((c['databaseId'] as num?)?.toInt() case final int id) id,
            ],
          ),
        );
      }
      final pageInfo = threads['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      cursor = pageInfo?['endCursor'] as String?;
      if (!hasNext || cursor == null) {
        break;
      }
    }
    return out;
  }

  /// Marks a review thread resolved, or reopens it.
  ///
  /// [threadId] is the GraphQL thread node id from [listReviewThreads] — a
  /// comment's `databaseId` is not accepted here.
  Future<void> setReviewThreadResolved({
    required String threadId,
    required bool resolved,
    CancelToken? cancelToken,
  }) async {
    final mutation = resolved
        ? r'''
          mutation ResolveThread($threadId: ID!) {
            resolveReviewThread(input: {threadId: $threadId}) {
              thread { id isResolved }
            }
          }
        '''
        : r'''
          mutation UnresolveThread($threadId: ID!) {
            unresolveReviewThread(input: {threadId: $threadId}) {
              thread { id isResolved }
            }
          }
        ''';
    await _runQuery(mutation, <String, dynamic>{
      'threadId': threadId,
    }, cancelToken);
  }

  /// Moves a pull request between draft and ready-for-review.
  ///
  /// GraphQL-only: REST's `PATCH /pulls/{n}` has no `draft` field, so this is
  /// the only lane GitHub gives us. Both mutations take the PR's *node* id, not
  /// its number, so the node id is resolved first — one extra round trip that
  /// cannot be folded into the mutation document (GraphQL allows one operation
  /// type per request).
  ///
  /// Returns silently when the PR is already in the requested state: GitHub
  /// rejects `markPullRequestReadyForReview` on a non-draft PR, and reporting
  /// that as an error would surface a failure for a no-op.
  Future<void> setPullRequestDraft({
    required String owner,
    required String repo,
    required int number,
    required bool draft,
    CancelToken? cancelToken,
  }) async {
    const idQuery = r'''
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) { id isDraft }
        }
      }
    ''';
    final idResult = await _runQuery(idQuery, <String, dynamic>{
      'owner': owner,
      'repo': repo,
      'number': number,
    }, cancelToken);
    final pr =
        ((idResult?['data'] as Map<String, dynamic>?)?['repository']
                as Map<String, dynamic>?)?['pullRequest']
            as Map<String, dynamic>?;
    final nodeId = pr?['id'] as String?;
    if (nodeId == null) {
      throw const NetworkException(
        'Pull request not found',
        code: 'graphql_error',
      );
    }
    if ((pr?['isDraft'] as bool?) == draft) {
      return;
    }

    final mutation = draft
        ? r'''
          mutation ConvertToDraft($id: ID!) {
            convertPullRequestToDraft(input: {pullRequestId: $id}) {
              pullRequest { id isDraft }
            }
          }
        '''
        : r'''
          mutation MarkReady($id: ID!) {
            markPullRequestReadyForReview(input: {pullRequestId: $id}) {
              pullRequest { id isDraft }
            }
          }
        ''';
    await _runQuery(mutation, <String, dynamic>{'id': nodeId}, cancelToken);
  }

  /// Every review summary's reactions on a PR, keyed by nothing — the set
  /// carries the REST `databaseId` that joins it back to the reviews the REST
  /// client already fetched.
  ///
  /// REST has no reactions on the review payload at all (only on comments,
  /// issues and the PR root), so this is the ONLY lane that can see a 👍 on a
  /// review summary. It also returns the GraphQL node ids the reaction
  /// mutations need: `databaseId` is not accepted as a mutation subject.
  ///
  /// Paginates reviews (100/page); a single review's reactions are capped at
  /// 100, which is far past any real reaction pile on a summary.
  Future<List<GitHubReviewReactionSet>> listReviewReactions({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $number: Int!, $after: String) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            reviews(first: 100, after: $after) {
              pageInfo { hasNextPage endCursor }
              nodes {
                databaseId
                id
                reactions(first: 100) {
                  nodes { id content user { login } }
                }
              }
            }
          }
        }
      }
    ''';

    final out = <GitHubReviewReactionSet>[];
    String? cursor;
    while (true) {
      final response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
        'number': number,
        'after': cursor,
      }, cancelToken);
      final data = response?['data'] as Map<String, dynamic>?;
      final repository = data?['repository'] as Map<String, dynamic>?;
      final pullRequest = repository?['pullRequest'] as Map<String, dynamic>?;
      final reviews = pullRequest?['reviews'] as Map<String, dynamic>?;
      if (reviews == null) {
        break;
      }
      for (final node
          in (reviews['nodes'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        final databaseId = (node['databaseId'] as num?)?.toInt();
        final nodeId = node['id'] as String?;
        if (databaseId == null || nodeId == null || nodeId.isEmpty) {
          continue;
        }
        final reactionNodes =
            node['reactions'] as Map<String, dynamic>? ?? const {};
        out.add(
          GitHubReviewReactionSet(
            databaseId: databaseId,
            nodeId: nodeId,
            reactions: [
              for (final r
                  in (reactionNodes['nodes'] as List? ?? const [])
                      .whereType<Map<String, dynamic>>())
                GitHubReviewReaction(
                  id: r['id'] as String? ?? '',
                  content: _reactionShortcode(r['content'] as String? ?? ''),
                  login:
                      (r['user'] as Map<String, dynamic>?)?['login']
                          as String? ??
                      '',
                ),
            ],
          ),
        );
      }
      final pageInfo = reviews['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      cursor = pageInfo?['endCursor'] as String?;
      if (!hasNext || cursor == null) {
        break;
      }
    }
    return out;
  }

  /// Adds a reaction with content `+1`/`rocket`/… to [subjectId], the GraphQL
  /// node id of any reactable subject (a review summary today).
  Future<void> addReaction({
    required String subjectId,
    required String content,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation($subject: ID!, $content: ReactionContent!) {
        addReaction(input: {subject: $subject, content: $content}) {
          reaction { id content }
        }
      }
    ''';
    await _runQuery(mutation, <String, dynamic>{
      'subject': subjectId,
      'content': _reactionEnumName(content),
    }, cancelToken);
  }

  /// Removes the reaction with GraphQL node id [reactionId]. GitHub deletes a
  /// reaction by its own id — the same read-then-delete shape the REST paths
  /// use, with the ids coming from [listReviewReactions].
  Future<void> removeReaction({
    required String reactionId,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation($reactionId: ID!) {
        removeReaction(input: {reactionId: $reactionId}) {
          reaction { id content }
        }
      }
    ''';
    await _runQuery(mutation, <String, dynamic>{
      'reactionId': reactionId,
    }, cancelToken);
  }

  /// Lists the head branches of [owner]/[repo] together with their last-commit
  /// activity: the committed date and the GitHub login of the commit author (if
  /// the author maps to a GitHub user). Paginates fully. Used to order the PR
  /// compose branch pickers by recency, with the current user's branches first.
  Future<List<GitHubBranchActivity>> listBranchesWithActivity(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $after: String) {
        repository(owner: $owner, name: $repo) {
          refs(
            refPrefix: "refs/heads/"
            first: 100
            after: $after
            orderBy: {field: TAG_COMMIT_DATE, direction: DESC}
          ) {
            pageInfo { hasNextPage endCursor }
            nodes {
              name
              target {
                ... on Commit {
                  committedDate
                  author { user { login } }
                }
              }
            }
          }
        }
      }
    ''';

    final out = <GitHubBranchActivity>[];
    String? cursor;
    while (true) {
      final response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
        'after': cursor,
      }, cancelToken);
      final data = response?['data'] as Map<String, dynamic>?;
      final repository = data?['repository'] as Map<String, dynamic>?;
      final refs = repository?['refs'] as Map<String, dynamic>?;
      if (refs == null) {
        break;
      }
      final nodes = refs['nodes'] as List?;
      if (nodes != null) {
        for (final node in nodes.whereType<Map<String, dynamic>>()) {
          final name = node['name'] as String?;
          if (name == null || name.isEmpty) {
            continue;
          }
          final target = node['target'] as Map<String, dynamic>?;
          final committedDate = target?['committedDate'] as String?;
          final author = target?['author'] as Map<String, dynamic>?;
          final user = author?['user'] as Map<String, dynamic>?;
          out.add(
            GitHubBranchActivity(
              name: name,
              committedDate: committedDate == null
                  ? null
                  : DateTime.tryParse(committedDate),
              authorLogin: user?['login'] as String?,
            ),
          );
        }
      }
      final pageInfo = refs['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      cursor = pageInfo?['endCursor'] as String?;
      if (!hasNext || cursor == null) {
        break;
      }
    }
    return out;
  }

  /// Discovers the repo's pull-request template(s) in a **single GraphQL
  /// request** against the default branch (`HEAD`).
  ///
  /// GitHub recognises a PR template under several conventional paths: a single
  /// `pull_request_template.md` in the repo root, `docs/`, or `.github/`; and/or
  /// any number of named templates inside a `PULL_REQUEST_TEMPLATE/` directory
  /// in those same three locations. This queries all of them at once and returns
  /// whatever exists — named directory templates first (in directory order),
  /// then the single default template (labelled via [GitHubPrTemplate.isDefault],
  /// first found wins in `.github` → root → `docs` precedence).
  ///
  /// Repos with no template return an empty list. Returns `[]` on any non-cancel
  /// error too, so the compose form degrades to an empty body rather than
  /// failing to open.
  Future<List<GitHubPrTemplate>> fetchPullRequestTemplates(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!) {
        repository(owner: $owner, name: $repo) {
          githubFile: object(expression: "HEAD:.github/pull_request_template.md") { ... on Blob { text } }
          rootFile: object(expression: "HEAD:pull_request_template.md") { ... on Blob { text } }
          docsFile: object(expression: "HEAD:docs/pull_request_template.md") { ... on Blob { text } }
          githubDir: object(expression: "HEAD:.github/PULL_REQUEST_TEMPLATE") { ...TemplateDir }
          rootDir: object(expression: "HEAD:PULL_REQUEST_TEMPLATE") { ...TemplateDir }
          docsDir: object(expression: "HEAD:docs/PULL_REQUEST_TEMPLATE") { ...TemplateDir }
        }
      }
      fragment TemplateDir on Tree {
        entries { name type object { ... on Blob { text } } }
      }
    ''';

    Map<String, dynamic>? response;
    try {
      response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
      }, cancelToken);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      return const [];
    } on NetworkException {
      // A malformed/odd repo response shouldn't block composing a PR.
      return const [];
    }

    final repository =
        (response?['data'] as Map<String, dynamic>?)?['repository']
            as Map<String, dynamic>?;
    if (repository == null) {
      return const [];
    }

    final templates = <GitHubPrTemplate>[];
    final seen = <String>{};

    // Named templates from the PULL_REQUEST_TEMPLATE directories.
    for (final dirAlias in const ['githubDir', 'rootDir', 'docsDir']) {
      final tree = repository[dirAlias] as Map<String, dynamic>?;
      final entries = tree?['entries'] as List?;
      if (entries == null) {
        continue;
      }
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        if (entry['type'] != 'blob') {
          continue;
        }
        final filename = entry['name'] as String? ?? '';
        if (!_isMarkdownTemplate(filename)) {
          continue;
        }
        final text =
            (entry['object'] as Map<String, dynamic>?)?['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          continue;
        }
        final name = _templateDisplayName(filename);
        if (seen.add(name.toLowerCase())) {
          templates.add(GitHubPrTemplate(name: name, body: text));
        }
      }
    }

    // The single default template — first found wins (.github > root > docs).
    for (final fileAlias in const ['githubFile', 'rootFile', 'docsFile']) {
      final blob = repository[fileAlias] as Map<String, dynamic>?;
      final text = blob?['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        templates.add(GitHubPrTemplate(name: '', body: text, isDefault: true));
        break;
      }
    }

    return templates;
  }

  bool _isMarkdownTemplate(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.md') || lower.endsWith('.markdown');
  }

  /// Turns a template filename (e.g. `bug_fix.md`) into a readable picker label
  /// (`bug fix`).
  String _templateDisplayName(String filename) {
    var name = filename;
    final dot = name.lastIndexOf('.');
    if (dot > 0) {
      name = name.substring(0, dot);
    }
    return name.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  }

  /// Runs [run] across [items] using a work-queue of at most [concurrency]
  /// concurrent workers (no wave barriers).
  static Future<void> _runBounded<T>(
    List<T> items,
    int concurrency,
    Future<void> Function(int index, T item) run,
  ) async {
    if (items.isEmpty) {
      return;
    }
    var next = 0;
    final workers = min(concurrency, items.length);
    await Future.wait([
      for (var w = 0; w < workers; w++)
        () async {
          while (true) {
            final i = next++;
            if (i >= items.length) {
              break;
            }
            await run(i, items[i]);
          }
        }(),
    ]);
  }

  /// Whether [error] is a transient server/gateway timeout or 5xx that is worth
  /// splitting into smaller GraphQL batches instead of failing or repeating.
  static bool _isSplittableServerFailure(Object error) {
    if (error is! NetworkException) {
      return false;
    }
    return error.code == 'timeout' ||
        const {500, 502, 503, 504}.contains(error.statusCode);
  }

  /// First page of open PRs per repo (up to [_prBatchPageSize] nodes, paged at
  /// [_prListPageSize] and adaptively halved down to [_prListMinPageSize] on
  /// 5xx/timeout), one repo per request, [_prListConcurrency] workers at a
  /// time. A failed or inaccessible repo is absent from `byIndex` (the caller
  /// keeps its last entry); only a sweep where every repo failed throws.
  ///
  /// When [onPage] is provided, each fetched page of nodes is handed to it as
  /// soon as it lands so callers can pipeline checks enrichment while later
  /// pages still paginate.
  Future<GitHubPrBatchResult> fetchOpenPullRequestsBatch(
    List<({String owner, String name})> repos, {
    CancelToken? cancelToken,
    void Function(int repoIndex, List<Map<String, dynamic>> pageNodes)? onPage,
  }) async {
    if (repos.isEmpty) {
      return const GitHubPrBatchResult(viewerLogin: null, byIndex: {});
    }

    final byIndex = <int, GitHubRepoPrNodes>{};
    Object? failure;

    await _runBounded(repos, _prListConcurrency, (index, repo) async {
      var pageSize = _prListPageSize;
      String? after;
      final allNodes = <Map<String, dynamic>>[];
      int? totalCount;
      var hasMore = false;

      while (allNodes.length < _prBatchPageSize) {
        final ask = min(pageSize, _prBatchPageSize - allNodes.length);
        final canSplit = ask > _prListMinPageSize;
        final Map<String, dynamic>? data;
        try {
          data = await _postTolerant(
            _buildListQuery(repo, pageSize: ask, after: after),
            cancelToken,
            maxRetries: canSplit ? 0 : 1,
            expectedStatuses: canSplit ? const [502, 503, 504] : null,
          );
        } on Object catch (e) {
          if (_isSplittableServerFailure(e) && canSplit) {
            pageSize = max(_prListMinPageSize, ask ~/ 2);
            continue;
          }
          failure = e;
          return;
        }
        // Cancelled or inaccessible repo (`repository == null`): abort so a
        // truncated page is never returned as the complete open-PR list.
        final root = data?['data'] as Map<String, dynamic>?;
        final repository = root?['r0'] as Map<String, dynamic>?;
        if (repository == null) {
          return;
        }
        final pulls = repository['pullRequests'] as Map<String, dynamic>?;
        totalCount ??= (pulls?['totalCount'] as num?)?.toInt();
        final nodes =
            (pulls?['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList(growable: false) ??
            const <Map<String, dynamic>>[];
        allNodes.addAll(nodes);
        if (nodes.isNotEmpty) {
          onPage?.call(index, nodes);
        }
        final pageInfo = pulls?['pageInfo'] as Map<String, dynamic>?;
        hasMore = pageInfo?['hasNextPage'] as bool? ?? false;
        final next = pageInfo?['endCursor'] as String?;
        if (!hasMore || next == null || next.isEmpty || nodes.isEmpty) {
          break;
        }
        after = next;
      }

      byIndex[index] = GitHubRepoPrNodes(
        nodes: allNodes,
        hasMore: hasMore,
        totalCount: totalCount,
      );
    });

    if (byIndex.isEmpty && failure != null) {
      throw failure!;
    }
    return GitHubPrBatchResult(viewerLogin: null, byIndex: byIndex);
  }

  /// List requests in flight at once. Aliasing busy repos into one query ran
  /// past GitHub's GraphQL timeout (HTTP 504) and failed the whole chunk.
  static const int _prListConcurrency = 4;

  /// Initial page size for [fetchOpenPullRequestsBatch] — answers in one fast
  /// round trip for repos with ≤50 open PRs while keeping busy repos well below
  /// GitHub's GraphQL timeout; halves down to [_prListMinPageSize] on 5xx.
  static const int _prListPageSize = 50;

  /// Floor for adaptive halving in [fetchOpenPullRequestsBatch].
  static const int _prListMinPageSize = 5;

  /// Open PRs per checks/review enrichment request. One repo per request,
  /// paged: `statusCheckRollup` is resolved per PR on GitHub's side, and on a
  /// busy repo even two repos × 100 PRs in one query ran past the gateway
  /// budget on every single poll (HTTP 502/504, then three identical retries),
  /// so the checks pills never refreshed at all. A small page answers well
  /// inside it, and a page that does fail halves down to [_prChecksMinPageSize].
  static const int _prChecksPageSize = 25;

  /// Floor for adaptive halving in [fetchOpenPullRequestsChecks].
  static const int _prChecksMinPageSize = 1;

  /// Open PRs fetched per repo on the first page. Matches the REST list's
  /// `per_page`, so REST pagination (`loadMore`) continues cleanly.
  static const int _prBatchPageSize = 100;

  /// PR node IDs per `nodes(ids:)` checks/review-decision batch.
  static const int _prStatusChunkSize = 20;

  /// Concurrent `nodes(ids:)` chunks in [fetchPullRequestStatusByIds].
  static const int _prStatusConcurrency = 4;

  String _buildListQuery(
    ({String owner, String name}) repo, {
    int pageSize = _prListPageSize,
    String? after,
  }) {
    final cursor = after == null
        ? ''
        : ', after: "${_escapeGraphqlString(after)}"';
    return '''
query {
  r0: repository(owner: "${_escapeGraphqlString(repo.owner)}", name: "${_escapeGraphqlString(repo.name)}") {
    pullRequests(states: OPEN, first: $pageSize$cursor, orderBy: {field: CREATED_AT, direction: DESC}) {
      totalCount
      pageInfo { hasNextPage endCursor }
      nodes { ...PrListFields }
    }
  }
}
$_prListFieldsFragment''';
  }

  String _buildChecksQuery(
    ({String owner, String name}) repo, {
    int pageSize = _prChecksPageSize,
    String? after,
  }) {
    final owner = _escapeGraphqlString(repo.owner);
    final name = _escapeGraphqlString(repo.name);
    final cursor = after == null
        ? ''
        : ', after: "${_escapeGraphqlString(after)}"';
    return '''
query {
  r0: repository(owner: "$owner", name: "$name") {
    pullRequests(states: OPEN, first: $pageSize$cursor, orderBy: {field: CREATED_AT, direction: DESC}) {
      pageInfo { hasNextPage endCursor }
      nodes { ...PrChecksFields }
    }
  }
}
$_prChecksFragment''';
  }

  static ({int number, GitHubPrStatusOverlay overlay})? _parseChecksNode(
    Map<String, dynamic> node,
  ) {
    final number = (node['number'] as num?)?.toInt() ?? 0;
    if (number <= 0) {
      return null;
    }
    final lastCommit = node['lastCommit'] as Map<String, dynamic>?;
    final lastCommitNodes = lastCommit?['nodes'] as List?;
    final firstCommit =
        (lastCommitNodes != null && lastCommitNodes.isNotEmpty)
        ? lastCommitNodes.first as Map<String, dynamic>?
        : null;
    final commit = firstCommit?['commit'] as Map<String, dynamic>?;
    final rollup = commit?['statusCheckRollup'] as Map<String, dynamic>?;
    return (
      number: number,
      overlay: (
        checksRollup: rollup?['state'] as String?,
        reviewDecision: node['reviewDecision'] as String?,
      ),
    );
  }

  /// Fetches `statusCheckRollup` + `reviewDecision` for known PR GraphQL
  /// [nodeIds] via parallel `nodes(ids:)` chunks ([_prStatusChunkSize] per
  /// request, [_prStatusConcurrency] workers).
  ///
  /// When a chunk hits a 5xx/timeout, it splits in half recursively instead of
  /// blindly retrying or failing the whole repo, so one pathological PR never
  /// starves the rest. Only throws if every chunk failed.
  Future<Map<int, GitHubPrStatusOverlay>> fetchPullRequestStatusByIds(
    List<String> nodeIds, {
    CancelToken? cancelToken,
  }) async {
    final unique = <String>[
      for (final id in nodeIds.toSet())
        if (id.isNotEmpty) id,
    ];
    if (unique.isEmpty) {
      return const {};
    }

    const query =
        '''
query(\$ids: [ID!]!) {
  nodes(ids: \$ids) {
    ... on PullRequest {
      ...PrChecksFields
    }
  }
}
$_prChecksFragment''';

    final overlays = <int, GitHubPrStatusOverlay>{};
    var succeededChunks = 0;
    Object? failure;

    Future<void> fetchChunk(List<String> ids) async {
      final canSplit = ids.length > 1;
      final Map<String, dynamic>? data;
      try {
        data = await _postTolerant(
          query,
          cancelToken,
          variables: {'ids': ids},
          maxRetries: canSplit ? 0 : 1,
          expectedStatuses: canSplit ? const [502, 503, 504] : null,
        );
      } on Object catch (e) {
        if (_isSplittableServerFailure(e) && canSplit) {
          final mid = ids.length ~/ 2;
          await Future.wait([
            fetchChunk(ids.sublist(0, mid)),
            fetchChunk(ids.sublist(mid)),
          ]);
          return;
        }
        failure = e;
        return;
      }
      if (data == null) {
        return;
      }
      succeededChunks++;
      final root = data['data'] as Map<String, dynamic>?;
      final nodes = root?['nodes'] as List?;
      if (nodes == null) {
        return;
      }
      for (final node in nodes.whereType<Map<String, dynamic>>()) {
        final parsed = _parseChecksNode(node);
        if (parsed != null) {
          overlays[parsed.number] = parsed.overlay;
        }
      }
    }

    final chunks = <List<String>>[
      for (var start = 0; start < unique.length; start += _prStatusChunkSize)
        unique.sublist(start, min(start + _prStatusChunkSize, unique.length)),
    ];
    await _runBounded(chunks, _prStatusConcurrency, (_, chunk) async {
      await fetchChunk(chunk);
    });

    if (succeededChunks == 0 && failure != null) {
      throw failure!;
    }
    return overlays;
  }

  /// Fetches specific pull requests by [numbers] in [owner]/[repo] with full
  /// list fields plus `state`, `mergedAt`, `reviewDecision`, and
  /// `statusCheckRollup`, aliased into one request per chunk of 10.
  Future<Map<int, Map<String, dynamic>>> fetchPullRequestsByNumbers({
    required String owner,
    required String repo,
    required List<int> numbers,
    CancelToken? cancelToken,
  }) async {
    final unique = <int>[
      for (final n in numbers.toSet())
        if (n > 0) n,
    ];
    if (unique.isEmpty) {
      return const {};
    }

    final out = <int, Map<String, dynamic>>{};
    const chunkSize = 10;
    for (var start = 0; start < unique.length; start += chunkSize) {
      final end = min(start + chunkSize, unique.length);
      final chunk = unique.sublist(start, end);
      final selections = StringBuffer();
      for (var i = 0; i < chunk.length; i++) {
        selections.write(
          '    p$i: pullRequest(number: ${chunk[i]}) { ...PrFullFields }\n',
        );
      }
      final query =
          'query(\$owner: String!, \$repo: String!) {\n'
          '  repository(owner: \$owner, name: \$repo) {\n'
          '$selections'
          '  }\n'
          '}\n'
          'fragment PrFullFields on PullRequest {\n'
          '  state\n'
          '  mergedAt\n'
          '$_prListFieldsBody'
          '}';
      final data = await _postTolerant(
        query,
        cancelToken,
        variables: {'owner': owner, 'repo': repo},
      );
      final root = data?['data'] as Map<String, dynamic>?;
      final repository = root?['repository'] as Map<String, dynamic>?;
      if (repository == null) {
        continue;
      }
      for (var i = 0; i < chunk.length; i++) {
        final node = repository['p$i'];
        if (node is Map<String, dynamic>) {
          out[chunk[i]] = node;
        }
      }
    }
    return out;
  }

  /// `statusCheckRollup` + `reviewDecision` for open PRs ([_prBatchPageSize] per
  /// repo; one repo per request, starting at [_prChecksPageSize] PRs per page
  /// and adaptively halving on 5xx/timeout). Phase 2 after
  /// [fetchOpenPullRequestsBatch]. Absent repo index = unread this pass (keep
  /// prior state); empty map = answered with no open PRs. Treating absent as
  /// "no checks" turns gateway timeouts into repeat notifications.
  Future<Map<int, Map<int, GitHubPrStatusOverlay>>> fetchOpenPullRequestsChecks(
    List<({String owner, String name})> repos, {
    CancelToken? cancelToken,
  }) async {
    if (repos.isEmpty) {
      return const {};
    }

    final result = <int, Map<int, GitHubPrStatusOverlay>>{};
    // Repos are independent requests, so one gateway timeout must not throw
    // away the repos that DID answer: the caller overlays what it got and
    // keeps its previous value for the rest. A repo whose pages did not ALL
    // answer stays absent (a partial overlay would read its unread PRs as
    // checkless). Only a sweep where every repo failed rethrows, so "GitHub
    // could not answer at all" still reaches the caller's log instead of
    // looking like a workspace with no checks.
    Object? failure;

    await _runBounded(repos, _prListConcurrency, (index, repo) async {
      final checksForRepo = <int, GitHubPrStatusOverlay>{};
      String? after;
      var fetched = 0;
      var pageSize = _prChecksPageSize;
      while (true) {
        final canSplit = pageSize > _prChecksMinPageSize;
        final Map<String, dynamic>? data;
        try {
          data = await _postTolerant(
            _buildChecksQuery(repo, pageSize: pageSize, after: after),
            cancelToken,
            maxRetries: canSplit ? 0 : 1,
            expectedStatuses: canSplit ? const [502, 503, 504] : null,
          );
        } on Object catch (e) {
          if (_isSplittableServerFailure(e) && canSplit) {
            pageSize = max(_prChecksMinPageSize, pageSize ~/ 2);
            continue;
          }
          failure = e;
          return;
        }
        final root = data?['data'] as Map<String, dynamic>?;
        if (root == null) {
          return;
        }
        final repository = root['r0'] as Map<String, dynamic>?;
        if (repository == null) {
          return;
        }
        final pulls = repository['pullRequests'] as Map<String, dynamic>?;
        final nodes =
            (pulls?['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList(growable: false) ??
            const <Map<String, dynamic>>[];
        for (final node in nodes) {
          final parsed = _parseChecksNode(node);
          if (parsed != null) {
            checksForRepo[parsed.number] = parsed.overlay;
          }
        }
        fetched += nodes.length;
        final pageInfo = pulls?['pageInfo'] as Map<String, dynamic>?;
        final next = pageInfo?['endCursor'] as String?;
        // The same first [_prBatchPageSize] PRs the list query covers; the
        // checks of older ones load with the list's own pagination.
        if (pageInfo?['hasNextPage'] != true ||
            next == null ||
            nodes.isEmpty ||
            fetched >= _prBatchPageSize) {
          break;
        }
        after = next;
      }
      result[index] = checksForRepo;
    });

    if (result.isEmpty && failure != null) {
      throw failure!;
    }
    return result;
  }

  String _escapeGraphqlString(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  /// Core PR list fields. Omits `statusCheckRollup` (phase 2 via
  /// [fetchPullRequestStatusByIds] / [fetchOpenPullRequestsChecks]);
  /// `body`/`url`/`mergedAt`/`mergeStateStatus` (`mergeStateStatus` caused 504s
  /// — never re-add here or in [_prChecksFragment]); `latestReviews` (lazy via
  /// [searchReviewedByPullRequests]). Keeps `headRefOid` for [PrHeadChanged]
  /// and merge-readiness dedupe.
  static const String _prListFieldsCoreBody = r'''
  number
  title
  isDraft
  createdAt
  updatedAt
  id
  baseRefName
  headRefName
  headRefOid baseRepository { databaseId } headRepository { databaseId }
  author { login avatarUrl }
  additions
  deletions
  comments { totalCount }
  reviewRequests(first: 20) {
    nodes {
      requestedReviewer {
        __typename
        ... on User { login avatarUrl }
        ... on Bot { login avatarUrl }
        ... on Mannequin { login avatarUrl }
        ... on Team { name slug avatarUrl databaseId }
      }
    }
  }
  labels(first: 20) {
    nodes { name color description }
  }
''';

  /// Full list fields including `statusCheckRollup`. Used by
  /// [searchPullRequestNodes] where the search returns only matched PRs
  /// (typically a handful), so including the checks connection is acceptable —
  /// the cost is proportional to matched count, not total open PRs.
  static const String _prListFieldsBody =
      _prListFieldsCoreBody +
      r'''
  reviewDecision
  lastCommit: commits(last: 1) {
    nodes { commit { statusCheckRollup { state } } }
  }
''';

  /// Batch fragment without checks — used by [fetchOpenPullRequestsBatch] for
  /// the fast phase-1 render. Checks are enriched separately by
  /// [fetchOpenPullRequestsChecks].
  static const String _prListFieldsFragment =
      'fragment PrListFields on PullRequest {$_prListFieldsCoreBody}';

  /// Minimal fragment for the checks-only enrichment pass: `number` (for
  /// matching back to the phase-1 rows), `statusCheckRollup` (the checks
  /// pill) and `reviewDecision` (the inbox's approved/changes-requested
  /// classification — a single server-computed enum, far cheaper than the
  /// `latestReviews` connection that was dropped from the hot list query).
  static const String _prChecksFragment = r'''
fragment PrChecksFields on PullRequest {
  number
  reviewDecision
  lastCommit: commits(last: 1) {
    nodes { commit { statusCheckRollup { state } } }
  }
}''';

  /// Lean search for open non-draft PRs requesting [reviewerLogin]'s review
  /// (`review-requested:<login>`), scoped to [repos]. Avoids
  /// [fetchOpenPullRequestsBatch]'s full open-PR pull. Chunked at
  /// [_reviewSearchChunkSize]. Returns raw GraphQL nodes; caller applies
  /// stale cut.
  Future<List<Map<String, dynamic>>> searchReviewRequestedPullRequests({
    required String reviewerLogin,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) async {
    if (reviewerLogin.isEmpty || repos.isEmpty) {
      return const [];
    }
    return _searchOpenPullRequestNodes(
      qualifiers: 'draft:false review-requested:$reviewerLogin',
      prSelection: r'''
        number
        title
        isDraft
        createdAt
        updatedAt
        url
        headRefName
        additions
        deletions
        comments { totalCount }
        repository { nameWithOwner }
      ''',
      repos: repos,
      cancelToken: cancelToken,
    );
  }

  /// The PR-list "reviewed by me" filter needs the set of open PRs
  /// [reviewerLogin] has already reviewed. Rather than carry `latestReviews` on
  /// every PR in the hot list query (10 reviews × every PR, every load — see
  /// [_prListFieldsFragment]), this resolves the set lazily with one
  /// server-side `reviewed-by:<login>` search, only while that filter is active.
  /// Returns `(repoFullName, number)` pairs so the caller can flag matching PRs
  /// without any per-PR review data on the entity.
  Future<List<({String repoFullName, int number})>>
  searchReviewedByPullRequests({
    required String reviewerLogin,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) async {
    if (reviewerLogin.isEmpty || repos.isEmpty) {
      return const [];
    }
    final nodes = await _searchOpenPullRequestNodes(
      qualifiers: 'reviewed-by:$reviewerLogin',
      prSelection: 'number repository { nameWithOwner }',
      repos: repos,
      cancelToken: cancelToken,
    );
    final out = <({String repoFullName, int number})>[];
    for (final node in nodes) {
      final number = (node['number'] as num?)?.toInt() ?? 0;
      final repo =
          (node['repository'] as Map<String, dynamic>?)?['nameWithOwner']
              as String?;
      if (number > 0 && repo != null && repo.isNotEmpty) {
        out.add((repoFullName: repo, number: number));
      }
    }
    return out;
  }

  /// Searches open PRs across [repos] matching [searchQualifiers] — the user's
  /// parsed query (e.g. `author:foo bar`) — in one chunked server-side
  /// `search`, returning the *same* rich list fields as
  /// [fetchOpenPullRequestsBatch] (diff size, checks, requested reviewers) plus
  /// `repository.nameWithOwner` for grouping, so results decode through the same
  /// `pullRequestFromGraphQlNode` mapper.
  Future<List<Map<String, dynamic>>> searchPullRequestNodes({
    required String searchQualifiers,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) {
    if (repos.isEmpty) {
      return Future.value(const []);
    }
    return _searchOpenPullRequestNodes(
      qualifiers: searchQualifiers,
      prSelection: '$_prListFieldsBody  repository { nameWithOwner }',
      repos: repos,
      cancelToken: cancelToken,
    );
  }

  /// One sweep of viewer PR activity in a single request (four aliased
  /// searches). App tokens cannot read `GET /notifications`; there is no PAT
  /// fallback. Not scoped by `repo:` (caller filters). [since]
  /// bounds activity lanes only; pending-review is an unbounded set. Overlap
  /// [since] — search index lags. User-to-server tokens only see App-installed
  /// repos (silent empty, not error).
  Future<GitHubViewerActivity> searchViewerPullRequestActivity({
    DateTime? since,
    CancelToken? cancelToken,
  }) async {
    final window = (since ?? DateTime.now().toUtc().subtract(_activityWindow))
        .toUtc();
    // Second precision: GitHub rejects sub-second values in a date qualifier.
    final stamp = window.toIso8601String().split('.').first;
    final updatedSince = 'updated:>$stamp';

    const query = r'''
query($rr: String!, $mn: String!, $mg: String!, $up: String!, $first: Int!) {
  reviewRequested: search(query: $rr, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
  mentioned: search(query: $mn, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
  merged: search(query: $mg, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
  updated: search(query: $up, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
}
fragment viewerPr on PullRequest {
  number
  title
  updatedAt
  repository { nameWithOwner }
  mergedBy { login }
}''';

    final response = await _runQuery(query, <String, dynamic>{
      // `draft:false` is what makes a draft a false→true transition when it is
      // later marked ready, instead of a notification GitHub itself withholds.
      'rr': 'is:pr is:open draft:false review-requested:@me',
      // Open AND closed on purpose: a mention on a PR that was just closed is
      // still addressed to a person, and the inbox would have delivered it.
      'mn': 'is:pr mentions:@me $updatedSince',
      'mg': 'is:pr is:merged involves:@me $updatedSince',
      'up': 'is:pr is:open involves:@me $updatedSince',
      'first': _reviewSearchPageSize,
    }, cancelToken);

    final data = response?['data'] as Map<String, dynamic>?;
    return GitHubViewerActivity(
      reviewRequested: _viewerPrNodes(data, 'reviewRequested'),
      mentioned: _viewerPrNodes(data, 'mentioned'),
      merged: _viewerPrNodes(data, 'merged'),
      updated: _viewerPrNodes(data, 'updated'),
    );
  }

  /// Decodes one aliased search lane's nodes, skipping unparseable hits.
  static List<GitHubViewerPr> _viewerPrNodes(
    Map<String, dynamic>? data,
    String alias,
  ) {
    final nodes = (data?[alias] as Map<String, dynamic>?)?['nodes'] as List?;
    if (nodes == null) {
      return const [];
    }
    final out = <GitHubViewerPr>[];
    for (final node in nodes.whereType<Map<String, dynamic>>()) {
      final pr = GitHubViewerPr.fromNode(node);
      if (pr != null) {
        out.add(pr);
      }
    }
    return out;
  }

  /// Open PRs invoking the conversation bridge: mentions of the dedicated
  /// @usectrl account, plus [label] (apps cannot hold requested-reviewer).
  /// One aliased request, not `repo:`-scoped; [since] bounds only the
  /// mention lane. An empty [label] is left out of the request rather than
  /// sent as a filler query; an empty [botLogin] (no installed App) searches
  /// nothing.
  Future<BotConversationCandidates> searchBotConversationCandidates({
    required String botLogin,
    required String label,
    DateTime? since,
    String? repoFullName,
    CancelToken? cancelToken,
  }) async {
    if (botLogin.isEmpty) {
      return BotConversationCandidates.empty;
    }
    // Confined to one repository when asked (a one-repository token sees
    // nothing else anyway; saying so keeps the search honest and cheap).
    final scope = repoFullName == null || repoFullName.isEmpty
        ? ''
        : ' repo:$repoFullName';
    final window = (since ?? DateTime.now().toUtc().subtract(_activityWindow))
        .toUtc();
    // Second precision: GitHub rejects sub-second values in a date qualifier.
    final stamp = window.toIso8601String().split('.').first;

    // (alias, variable, search string) per lane that has something to find.
    final lanes = <(String, String, String)>[
      (
        'mentioned',
        'mn',
        'is:pr mentions:"$githubPrConversationMentionLogin" '
            'updated:>$stamp$scope',
      ),
      if (label.isNotEmpty)
        ('labeled', 'lb', 'is:pr is:open label:"$label"$scope'),
    ];
    final variables = <String, dynamic>{'first': _reviewSearchPageSize};
    final declarations = StringBuffer();
    final selections = StringBuffer();
    for (final (alias, variable, search) in lanes) {
      variables[variable] = search;
      declarations.write('\$$variable: String!, ');
      selections.write(
        '  $alias: search(query: \$$variable, type: ISSUE, '
        'first: \$first) {\n'
        '    nodes { ...viewerPr }\n'
        '  }\n',
      );
    }
    final query =
        'query($declarations\$first: Int!) {\n'
        '$selections'
        '}\n'
        'fragment viewerPr on PullRequest {\n'
        '  number\n'
        '  title\n'
        '  updatedAt\n'
        '  repository { nameWithOwner }\n'
        '}';

    final response = await _runQuery(query, variables, cancelToken);

    final data = response?['data'] as Map<String, dynamic>?;
    return BotConversationCandidates(
      mentioned: _viewerPrNodes(data, 'mentioned'),
      labeled: label.isEmpty
          ? const <GitHubViewerPr>[]
          : _viewerPrNodes(data, 'labeled'),
    );
  }

  /// Runs a chunked `search(type: ISSUE)` over [repos] for open PRs matching
  /// [qualifiers] (e.g. `draft:false review-requested:octocat`), selecting
  /// [prSelection] on each `PullRequest` hit and returning the raw node maps.
  /// Shared by the review-requested, reviewed-by and free-text searches.
  ///
  /// The search string is passed as the `$q` *variable*, never interpolated
  /// into the query body, so repo/login values need no GraphQL escaping. Repos
  /// are chunked into [_reviewSearchChunkSize]-sized `repo:` lists so no query
  /// grows past GitHub's length limit; chunks run sequentially (one request
  /// each). Cancellation returns whatever was collected (empty in practice),
  /// mirroring `_postTolerant`.
  Future<List<Map<String, dynamic>>> _searchOpenPullRequestNodes({
    required String qualifiers,
    required String prSelection,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) async {
    if (repos.isEmpty) {
      return const [];
    }
    final query =
        'query(\$q: String!, \$first: Int!) {\n'
        '  search(query: \$q, type: ISSUE, first: \$first) {\n'
        '    nodes { ... on PullRequest { $prSelection } }\n'
        '  }\n'
        '}';

    final chunks = <List<({String owner, String name})>>[
      for (var start = 0; start < repos.length; start += _reviewSearchChunkSize)
        repos.sublist(start, min(start + _reviewSearchChunkSize, repos.length)),
    ];
    final nodes = <Map<String, dynamic>>[];
    var cancelled = false;
    await _runBounded(chunks, 2, (_, chunk) async {
      if (cancelled) {
        return;
      }
      final q = StringBuffer('is:pr is:open ')..write(qualifiers);
      for (final r in chunk) {
        q
          ..write(' repo:')
          ..write(r.owner)
          ..write('/')
          ..write(r.name);
      }

      final Map<String, dynamic>? response;
      try {
        response = await _runQuery(query, <String, dynamic>{
          'q': q.toString(),
          'first': _reviewSearchPageSize,
        }, cancelToken);
      } on RhttpException catch (e) {
        if (e is RhttpCancelException) {
          cancelled = true;
          return;
        }
        rethrow;
      }

      final data = response?['data'] as Map<String, dynamic>?;
      final search = data?['search'] as Map<String, dynamic>?;
      final searchNodes = search?['nodes'] as List?;
      if (searchNodes == null) {
        return;
      }
      // Non-PR hits (none expected given `is:pr`) deserialize as empty maps.
      nodes.addAll(
        searchNodes.whereType<Map<String, dynamic>>().where(
          (n) => n.isNotEmpty,
        ),
      );
    });
    return cancelled ? const [] : nodes;
  }

  /// Repos per review-requested search query. Keeps each query's `repo:`
  /// qualifier list short enough to stay under GitHub's search query-length
  /// limit; chunks run sequentially.
  static const int _reviewSearchChunkSize = 5;

  /// PRs fetched per review-requested search page. A single operator almost
  /// never has more than this many reviews outstanding across a chunk.
  static const int _reviewSearchPageSize = 100;

  static const int _profileRepoChunkSize = 10;
  static const int _profileAuthorChunkSize = 10;
  static const int _profileRepoQualifierCharBudget = 400;
  static const int _profileSearchConcurrency = 3;
  static const int _profileMaxResults = 200;
  static const int _profileMinPageSize = 25;

  /// Packs [repos] and [logins] into bounded `(repos, authors)` search chunks.
  ///
  /// Repositories are grouped up to [_profileRepoChunkSize] within
  /// [_profileRepoQualifierCharBudget] characters (always at least one repo per
  /// chunk), and authors are grouped up to [_profileAuthorChunkSize].
  static List<ProfileSearchChunk> buildProfileSearchChunks({
    required List<String> logins,
    required List<({String owner, String name})> repos,
  }) {
    final authors = logins
        .map((login) => login.trim())
        .where((login) => login.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (authors.isEmpty || repos.isEmpty) {
      return const [];
    }

    final repoChunks = <List<({String owner, String name})>>[];
    var currentRepos = <({String owner, String name})>[];
    var currentChars = 0;
    for (final repo in repos) {
      final qualifierLength = ' repo:${repo.owner}/${repo.name}'.length;
      if (currentRepos.isNotEmpty &&
          (currentRepos.length >= _profileRepoChunkSize ||
              currentChars + qualifierLength >
                  _profileRepoQualifierCharBudget)) {
        repoChunks.add(currentRepos);
        currentRepos = <({String owner, String name})>[];
        currentChars = 0;
      }
      currentRepos.add(repo);
      currentChars += qualifierLength;
    }
    if (currentRepos.isNotEmpty) {
      repoChunks.add(currentRepos);
    }

    final chunks = <ProfileSearchChunk>[];
    for (final repoChunk in repoChunks) {
      for (
        var authorStart = 0;
        authorStart < authors.length;
        authorStart += _profileAuthorChunkSize
      ) {
        final authorEnd = min(
          authorStart + _profileAuthorChunkSize,
          authors.length,
        );
        chunks.add((
          repos: repoChunk,
          authors: authors.sublist(authorStart, authorEnd),
        ));
      }
    }
    return chunks;
  }

  /// The `updated:>` window used by [searchViewerPullRequestActivity] when the
  /// caller has no previous sweep to anchor on (first run ever, or a dropped
  /// watermark). A day is wide enough that a server restarted after a short
  /// outage catches up, and narrow enough that the first sweep of a busy
  /// account stays inside one page.
  static const Duration _activityWindow = Duration(hours: 24);

  /// True PR counts authored by [login] across [repos], read from GitHub
  /// search `issueCount`s — accurate regardless of page size, unlike counting a
  /// fetched list capped at 100/repo. The four states are mutually exclusive
  /// and exhaustive (open-nondraft / open-draft / merged / closed-unmerged),
  /// each a separate aliased `search` in one request per repo-chunk; counts sum
  /// across chunks. Repos are chunked (like [_searchOpenPullRequestNodes]) so no
  /// query outgrows GitHub's length limit. `issueCount` is exact even past 1000
  /// (only result *pagination* is capped there). Zeros when login/repos empty.
  Future<({int open, int draft, int merged, int closed})> prCountsByAuthor({
    required String login,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) => prCountsByAuthors(
    logins: [login],
    repos: repos,
    cancelToken: cancelToken,
  );

  /// Exact PR outcome counts authored by any of [logins] across [repos].
  ///
  /// Repeated `author:` and `repo:` qualifiers are ORed within each GitHub
  /// search. Authors and repositories are chunked to keep queries bounded;
  /// summing author chunks is exact because one pull request has one author.
  Future<({int open, int draft, int merged, int closed})> prCountsByAuthors({
    required List<String> logins,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) async {
    final result = await prCountsByAuthorChunks(
      logins: logins,
      repos: repos,
      cancelToken: cancelToken,
    );
    return (
      open: result.open,
      draft: result.draft,
      merged: result.merged,
      closed: result.closed,
    );
  }

  /// Exact PR outcome counts authored by any of [logins] across [repos], plus
  /// the subset of [ProfileSearchChunk]s that matched at least one PR.
  Future<
    ({
      int open,
      int draft,
      int merged,
      int closed,
      List<ProfileSearchChunk> nonEmptyChunks,
    })
  >
  prCountsByAuthorChunks({
    required List<String> logins,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
  }) async {
    final chunks = buildProfileSearchChunks(logins: logins, repos: repos);
    if (chunks.isEmpty) {
      return (
        open: 0,
        draft: 0,
        merged: 0,
        closed: 0,
        nonEmptyChunks: const <ProfileSearchChunk>[],
      );
    }
    const query =
        'query(\$open: String!, \$draft: String!, \$merged: String!, '
        '\$closed: String!) {\n'
        '  open: search(query: \$open, type: ISSUE, first: 1) { issueCount }\n'
        '  draft: search(query: \$draft, type: ISSUE, first: 1) { issueCount }\n'
        '  merged: search(query: \$merged, type: ISSUE, first: 1) { issueCount }\n'
        '  closed: search(query: \$closed, type: ISSUE, first: 1) { issueCount }\n'
        '}';

    final results = List<({int open, int draft, int merged, int closed})?>.filled(
      chunks.length,
      null,
    );
    var cancelled = false;

    await _runBounded(chunks, _profileSearchConcurrency, (index, chunk) async {
      if (cancelled) {
        return;
      }
      final scope = StringBuffer();
      for (final login in chunk.authors) {
        scope
          ..write(' author:')
          ..write(login);
      }
      for (final repo in chunk.repos) {
        scope
          ..write(' repo:')
          ..write(repo.owner)
          ..write('/')
          ..write(repo.name);
      }
      final base = scope.toString();

      Map<String, dynamic>? response;
      try {
        response = await _runQuery(query, <String, dynamic>{
          'open': 'is:pr is:open draft:false$base',
          'draft': 'is:pr is:open draft:true$base',
          'merged': 'is:pr is:merged$base',
          'closed': 'is:pr is:closed is:unmerged$base',
        }, cancelToken);
      } on RhttpException catch (e) {
        if (e is RhttpCancelException) {
          cancelled = true;
          return;
        }
        rethrow;
      }

      final data = response?['data'] as Map<String, dynamic>?;
      int countOf(String alias) =>
          ((data?[alias] as Map<String, dynamic>?)?['issueCount'] as num?)
              ?.toInt() ??
          0;
      results[index] = (
        open: countOf('open'),
        draft: countOf('draft'),
        merged: countOf('merged'),
        closed: countOf('closed'),
      );
    });

    var open = 0, draft = 0, merged = 0, closed = 0;
    final nonEmptyChunks = <ProfileSearchChunk>[];
    for (var i = 0; i < chunks.length; i++) {
      final counts = results[i];
      if (counts == null) {
        continue;
      }
      open += counts.open;
      draft += counts.draft;
      merged += counts.merged;
      closed += counts.closed;
      if (counts.open + counts.draft + counts.merged + counts.closed > 0) {
        nonEmptyChunks.add(chunks[i]);
      }
    }
    return (
      open: open,
      draft: draft,
      merged: merged,
      closed: closed,
      nonEmptyChunks: nonEmptyChunks,
    );
  }

  /// Posts a GraphQL [query] (with optional [variables]) and returns the decoded
  /// body **without** throwing on a partial `errors` array — batched multi-repo
  /// queries routinely return data for the accessible repos plus errors for the
  /// rest, and a single-entity query can have one sub-field forbidden by the
  /// credential while every other field resolved. Transport/auth failures still
  /// throw via [mapHttpException].
  Future<Map<String, dynamic>?> _postTolerant(
    String query,
    CancelToken? cancelToken, {
    Map<String, dynamic>? variables,
    int? maxRetries,
    Iterable<int>? expectedStatuses,
  }) async {
    try {
      final payload = HttpBody.json({'query': query, 'variables': ?variables});
      final HttpResponse response;
      if (maxRetries != null || expectedStatuses != null) {
        final req = BaseHttpRequest(
          method: HttpMethod.post,
          url: '/graphql',
          body: payload,
          expectBody: HttpExpectBody.text,
          cancelToken: cancelToken,
        )..additionalData.addAll({
            if (maxRetries != null) ...maxRetriesOption(maxRetries),
            if (expectedStatuses != null) ...expectStatuses(expectedStatuses),
          });
        response = await _httpClient.send(req);
      } else {
        response = await _httpClient.post(
          '/graphql',
          body: payload,
          cancelToken: cancelToken,
        );
      }
      final body = httpJsonBody(response);
      return body is Map<String, dynamic> ? body : null;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        // Cancellation is the normal teardown path: `prsByRepoProvider` cancels
        // this request via its `onDispose` whenever the provider rebuilds (a
        // watched repo/auth/workspace stream re-emitting at startup, or a
        // workspace switch). That is not an error — returning null lets the
        // (already-superseded) build settle quietly instead of throwing a raw,
        // unmapped RhttpException into Riverpod, which would surface as a
        // spurious error and churn the loading state. The fresh build's request
        // is what actually populates the list.
        return null;
      }
      throw mapHttpException(e);
    }
  }

  /// Un-marks a file as viewed in a pull request.
  Future<void> unmarkFileAsViewed({
    required String pullRequestId,
    required String path,
    CancelToken? cancelToken,
  }) async {
    const mutation = r'''
      mutation UnmarkFileAsViewed($pullRequestId: ID!, $path: String!) {
        unmarkFileAsViewed(input: {pullRequestId: $pullRequestId, path: $path}) {
          clientMutationId
        }
      }
    ''';
    try {
      await _httpClient.post(
        '/graphql',
        body: HttpBody.json({
          'query': mutation,
          'variables': {'pullRequestId': pullRequestId, 'path': path},
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

  /// Fetches a GitHub identity's profile via GraphQL.
  ///
  /// Bot logins (`login[bot]`) are skipped. App slugs (no `[bot]`) miss
  /// `repositoryOwner` → fall through to `GET /apps/{slug}` instead of throwing.
  /// Uses `repositoryOwner` (User and Organization). Tolerates a partial answer:
  /// an App installation token is forbidden on `organizations.nodes.teams`, so
  /// GitHub nulls org nodes with FORBIDDEN while login/bio/calendar still
  /// resolve — throwing on the errors array (as [_runQuery] does) blanked the
  /// hover card. No owner plus a non-NOT_FOUND errors array still throws.
  Future<GitHubUserProfile?> getUserProfile({
    required String login,
    CancelToken? cancelToken,
  }) async {
    if (isGitHubBotLogin(login)) {
      return null;
    }
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 365));

    const query = r'''
      query($login: String!, $from: DateTime!, $to: DateTime!) {
        repositoryOwner(login: $login) {
          __typename
          login
          avatarUrl
          ... on User {
            name
            bio
            location
            company
            websiteUrl
            twitterUsername
            status {
              message
              emoji
              indicatesLimitedAvailability
            }
            organizations(first: 6) {
              nodes {
                login
                name
                avatarUrl
                url
                teams(first: 10, userLogins: [$login]) {
                  nodes {
                    name
                    slug
                  }
                }
              }
            }
            contributionsCollection(from: $from, to: $to) {
              restrictedContributionsCount
              contributionCalendar {
                totalContributions
                weeks {
                  contributionDays {
                    contributionCount
                    date
                  }
                }
              }
            }
          }
          ... on Organization {
            name
            description
            location
            websiteUrl
            twitterUsername
          }
        }
      }
    ''';

    final variables = <String, dynamic>{
      'login': login,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };

    final result = await _postTolerant(
      query,
      cancelToken,
      variables: variables,
    );
    if (result == null) {
      return null;
    }
    final profile = _parseUserProfile(result);
    if (profile != null) {
      return profile;
    }
    // `repositoryOwner` is User | Organization. A GitHub App slug is
    // neither, so GraphQL answers NOT_FOUND — look the app up by slug.
    if (_graphqlErrorsAreNotFound(result['errors'] as List?)) {
      return _fetchAppProfile(login, cancelToken);
    }
    return null;
  }

  /// Fetches an organization team and every member visible to the caller.
  ///
  /// Membership is paginated because the profile activity query must represent
  /// the whole team rather than the first 100 people GitHub returns.
  Future<GitHubTeamProfile?> getTeamProfile({
    required String organization,
    required String slug,
    CancelToken? cancelToken,
  }) async {
    if (organization.trim().isEmpty || slug.trim().isEmpty) {
      return null;
    }
    const query = r'''
      query($organization: String!, $slug: String!, $after: String) {
        organization(login: $organization) {
          team(slug: $slug) {
            name
            slug
            description
            avatarUrl
            url
            members(first: 100, after: $after) {
              totalCount
              nodes { login name avatarUrl }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
      }
    ''';

    final members = <Map<String, dynamic>>[];
    Map<String, dynamic>? team;
    String? cursor;
    while (true) {
      final result = await _postTolerant(
        query,
        cancelToken,
        variables: <String, dynamic>{
          'organization': organization,
          'slug': slug,
          'after': cursor,
        },
      );
      final data = result?['data'] as Map<String, dynamic>?;
      final org = data?['organization'] as Map<String, dynamic>?;
      final pageTeam = org?['team'] as Map<String, dynamic>?;
      if (pageTeam == null) {
        return null;
      }
      team ??= Map<String, dynamic>.from(pageTeam);
      final connection = pageTeam['members'] as Map<String, dynamic>?;
      members.addAll(
        (connection?['nodes'] as List? ?? const [])
            .whereType<Map<String, dynamic>>(),
      );
      final pageInfo = connection?['pageInfo'] as Map<String, dynamic>?;
      if (pageInfo?['hasNextPage'] != true) {
        final combined = Map<String, dynamic>.from(team)
          ..['members'] = <String, dynamic>{
            'totalCount':
                (connection?['totalCount'] as num?)?.toInt() ?? members.length,
            'nodes': members,
          };
        return GitHubTeamProfile.fromGraphQl(
          combined,
          organization: organization,
        );
      }
      final next = pageInfo?['endCursor'] as String?;
      if (next == null || next.isEmpty || next == cursor) {
        return null;
      }
      cursor = next;
    }
  }

  /// Fetches a detailed, bounded all-state PR sample authored by any of
  /// [logins] across [repos], newest activity first.
  ///
  /// Fetches at most 2 concurrent waves across chunks up to [maxResults] so
  /// large profiles settle in a predictable number of round trips. The returned
  /// `truncated` flag is true whenever GitHub reports additional matches beyond
  /// the sampled window.
  Future<({List<Map<String, dynamic>> nodes, bool truncated})>
  searchProfilePullRequestNodes({
    required List<String> logins,
    required List<({String owner, String name})> repos,
    CancelToken? cancelToken,
    List<ProfileSearchChunk>? chunks,
    int maxResults = _profileMaxResults,
  }) async {
    final activeChunks =
        chunks ?? buildProfileSearchChunks(logins: logins, repos: repos);
    if (activeChunks.isEmpty || maxResults <= 0) {
      return (nodes: const <Map<String, dynamic>>[], truncated: false);
    }

    const query = r'''
      query($q: String!, $first: Int!, $after: String) {
        search(query: $q, type: ISSUE, first: $first, after: $after) {
          issueCount
          nodes {
            ... on PullRequest {
              number
              title
              state
              isDraft
              createdAt
              updatedAt
              mergedAt
              url
              id
              baseRefName
              headRefName
              headRefOid
              author { login avatarUrl }
              additions
              deletions
              comments { totalCount }
              reviews(first: 5) {
                nodes {
                  author { login }
                  submittedAt
                }
              }
              repository { nameWithOwner }
            }
          }
          pageInfo { hasNextPage endCursor }
        }
      }
    ''';

    final initialPageSize = activeChunks.length <= 2
        ? min(_reviewSearchPageSize, maxResults)
        : (maxResults / activeChunks.length)
            .ceil()
            .clamp(_profileMinPageSize, _reviewSearchPageSize);

    final states = <_ProfileSearchChunkState>[
      for (final chunk in activeChunks)
        _ProfileSearchChunkState(
          qualifiers: _profileChunkQualifiers(chunk),
          pageSize: initialPageSize,
        ),
    ];

    final byKey = <String, Map<String, dynamic>>{};
    var cancelled = false;
    var hitCap = false;

    void absorbPage(
      _ProfileSearchChunkState state,
      Map<String, dynamic> response,
    ) {
      final data = response['data'] as Map<String, dynamic>?;
      final search = data?['search'] as Map<String, dynamic>?;
      final nodes = (search?['nodes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      for (final node in nodes) {
        final repo =
            (node['repository'] as Map<String, dynamic>?)?['nameWithOwner']
                as String?;
        final number = (node['number'] as num?)?.toInt() ?? 0;
        if (repo == null || repo.isEmpty || number <= 0) {
          continue;
        }
        final key = '${repo.toLowerCase()}#$number';
        if (byKey.length >= maxResults && !byKey.containsKey(key)) {
          hitCap = true;
          continue;
        }
        byKey[key] = node;
      }
      state.fetched += nodes.length;
      state.issueCount = (search?['issueCount'] as num?)?.toInt() ?? 0;
      final pageInfo = search?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] == true;
      final next = pageInfo?['endCursor'] as String?;
      if (!hasNext || next == null || next.isEmpty || next == state.cursor) {
        state.hasNext = hasNext;
        state.cursor = null;
      } else {
        state.hasNext = true;
        state.cursor = next;
      }
    }

    // Wave 1: fetch the first page of every active chunk concurrently so no
    // repo/author chunk is starved.
    await _runBounded(states, _profileSearchConcurrency, (_, state) async {
      if (cancelled) {
        return;
      }
      final response = await _runSearchPageWithSplit(
        query: query,
        state: state,
        maxAsk: state.pageSize,
        cancelToken: cancelToken,
      );
      if (response == null) {
        cancelled = true;
        return;
      }
      absorbPage(state, response);
    });

    // Wave 2: fetch at most one additional page for chunks that still have
    // cursor pages while under the sample cap.
    if (!cancelled && byKey.length < maxResults) {
      final nextStates = [
        for (final state in states)
          if (state.hasNext &&
              state.cursor != null &&
              state.cursor!.isNotEmpty)
            state,
      ];
      if (nextStates.isNotEmpty) {
        await _runBounded(nextStates, _profileSearchConcurrency, (
          _,
          state,
        ) async {
          if (cancelled || byKey.length >= maxResults) {
            return;
          }
          final remaining = maxResults - byKey.length;
          final maxAsk = nextStates.length == 1
              ? min(state.pageSize, remaining)
              : state.pageSize;
          if (maxAsk <= 0) {
            return;
          }
          final response = await _runSearchPageWithSplit(
            query: query,
            state: state,
            maxAsk: maxAsk,
            cancelToken: cancelToken,
          );
          if (response == null) {
            cancelled = true;
            return;
          }
          absorbPage(state, response);
        });
      }
    }

    final truncated =
        hitCap ||
        states.any((s) => s.hasNext || s.issueCount > s.fetched);
    return (nodes: byKey.values.toList(growable: false), truncated: truncated);
  }

  static String _profileChunkQualifiers(ProfileSearchChunk chunk) {
    final qualifiers = StringBuffer('is:pr sort:updated-desc');
    for (final login in chunk.authors) {
      qualifiers
        ..write(' author:')
        ..write(login);
    }
    for (final repo in chunk.repos) {
      qualifiers
        ..write(' repo:')
        ..write(repo.owner)
        ..write('/')
        ..write(repo.name);
    }
    return qualifiers.toString();
  }

  Future<Map<String, dynamic>?> _runSearchPageWithSplit({
    required String query,
    required _ProfileSearchChunkState state,
    required int maxAsk,
    CancelToken? cancelToken,
  }) async {
    while (true) {
      final ask = min(state.pageSize, maxAsk);
      final canSplit = ask > _profileMinPageSize;
      final Map<String, dynamic>? response;
      try {
        response = await _postTolerant(
          query,
          cancelToken,
          variables: <String, dynamic>{
            'q': state.qualifiers,
            'first': ask,
            'after': state.cursor,
          },
          maxRetries: canSplit ? 0 : 1,
          expectedStatuses: canSplit ? const [502, 503, 504] : null,
        );
      } on Object catch (e) {
        if (_isSplittableServerFailure(e) && canSplit) {
          state.pageSize = max(_profileMinPageSize, ask ~/ 2);
          continue;
        }
        rethrow;
      }
      if (response == null) {
        return null;
      }
      final errors = response['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.first as Map?;
        final message = first?['message'] as String? ?? 'Unknown GraphQL error';
        throw NetworkException(message, code: 'graphql_error');
      }
      return response;
    }
  }

  /// Fetches GitHub's suggested reviewers for a PR — the users GitHub
  /// recommends (from git-blame authorship and prior review history). This is
  /// GraphQL-only; the REST API has no suggested-reviewers endpoint. Bots and
  /// duplicate logins are dropped; the caller filters out self / already
  /// requested reviewers.
  Future<List<PrUser>> getSuggestedReviewers({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            suggestedReviewers {
              reviewer {
                login
                name
                avatarUrl
              }
            }
          }
        }
      }
    ''';

    final response = await _runQuery(query, <String, dynamic>{
      'owner': owner,
      'repo': repo,
      'number': number,
    }, cancelToken);

    final data = response?['data'] as Map<String, dynamic>?;
    final repository = data?['repository'] as Map<String, dynamic>?;
    final pullRequest = repository?['pullRequest'] as Map<String, dynamic>?;
    final suggested = pullRequest?['suggestedReviewers'] as List?;
    if (suggested == null) {
      return const <PrUser>[];
    }

    final out = <PrUser>[];
    final seen = <String>{};
    for (final s in suggested.whereType<Map<String, dynamic>>()) {
      final reviewer = s['reviewer'] as Map<String, dynamic>?;
      final login = reviewer?['login'] as String? ?? '';
      if (login.isEmpty || !seen.add(login.toLowerCase())) {
        continue;
      }
      out.add(_prUserFromGraphQl(reviewer!));
    }
    return out;
  }

  /// Lists users who can be assigned to issues/PRs in [owner]/[repo]
  /// (push access). GraphQL is required because the REST assignees list is a
  /// Simple User and has no display [PrUser.name]. Paginates fully.
  Future<List<PrUser>> listAssignableUsers(
    String owner,
    String repo, {
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $after: String) {
        repository(owner: $owner, name: $repo) {
          assignableUsers(first: 100, after: $after) {
            pageInfo { hasNextPage endCursor }
            nodes { login name avatarUrl }
          }
        }
      }
    ''';

    final out = <PrUser>[];
    final seen = <String>{};
    String? cursor;
    while (true) {
      final response = await _runQuery(query, <String, dynamic>{
        'owner': owner,
        'repo': repo,
        'after': cursor,
      }, cancelToken);
      final data = response?['data'] as Map<String, dynamic>?;
      final repository = data?['repository'] as Map<String, dynamic>?;
      final connection =
          repository?['assignableUsers'] as Map<String, dynamic>?;
      if (connection == null) {
        break;
      }
      final nodes = connection['nodes'] as List?;
      if (nodes != null) {
        for (final node in nodes.whereType<Map<String, dynamic>>()) {
          final login = node['login'] as String? ?? '';
          if (login.isEmpty || !seen.add(login.toLowerCase())) {
            continue;
          }
          out.add(_prUserFromGraphQl(node));
        }
      }
      final pageInfo = connection['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      cursor = pageInfo?['endCursor'] as String?;
      if (!hasNext || cursor == null) {
        break;
      }
    }
    return out;
  }

  /// Fetches only the contribution calendar for a GitHub user.
  Future<GitHubContributionCalendar?> getUserContributions({
    required String login,
    CancelToken? cancelToken,
  }) async {
    if (isGitHubBotLogin(login)) {
      return null;
    }
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 365));

    const query = r'''
      query($login: String!, $from: DateTime!, $to: DateTime!) {
        user(login: $login) {
          contributionsCollection(from: $from, to: $to) {
            contributionCalendar {
              totalContributions
              weeks {
                contributionDays {
                  contributionCount
                  date
                }
              }
            }
          }
        }
      }
    ''';

    final variables = <String, dynamic>{
      'login': login,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };

    final result = await _runQuery(query, variables, cancelToken);
    final data = result?['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    final calendar = user?['contributionCalendar'] as Map<String, dynamic>?;
    if (calendar != null) {
      return GitHubContributionCalendar.fromJson(calendar);
    }
    return null;
  }

  /// Fetches the review state of a single PR: requested reviewers (users AND
  /// teams) with their `asCodeOwner` flag, the latest review per reviewer
  /// with its `state` and the teams it was submitted `onBehalfOf`, plus
  /// `state` / `isDraft` so the notifications poller can withhold
  /// review-requested bells on drafts.
  ///
  /// The REST detail endpoint can't supply this — it returns only user
  /// `requested_reviewers`, with no team reviewers, no code-owner flag and no
  /// on-behalf-of linkage. This single query feeds the enriched reviewer rail
  /// and the review-requested notification gate.
  Future<GitHubPrReviewState> getPullRequestReviewState({
    required String owner,
    required String repo,
    required int number,
    CancelToken? cancelToken,
  }) async {
    const query = r'''
      query($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            state
            isDraft
            reviewRequests(first: 50) {
              nodes {
                asCodeOwner
                requestedReviewer {
                  __typename
                  ... on User { login avatarUrl }
                  ... on Bot { login avatarUrl }
                  ... on Mannequin { login avatarUrl }
                  ... on Team { name slug avatarUrl databaseId }
                }
              }
            }
            latestReviews(first: 50) {
              nodes {
                state
                author { login avatarUrl }
                onBehalfOf(first: 5) { nodes { name slug avatarUrl databaseId } }
              }
            }
          }
        }
      }
    ''';

    final response = await _runQuery(query, <String, dynamic>{
      'owner': owner,
      'repo': repo,
      'number': number,
    }, cancelToken);

    final data = response?['data'] as Map<String, dynamic>?;
    final repository = data?['repository'] as Map<String, dynamic>?;
    final pullRequest = repository?['pullRequest'] as Map<String, dynamic>?;
    if (pullRequest == null) {
      return const GitHubPrReviewState();
    }

    final pendingUsers = <GitHubPendingUserRequest>[];
    final pendingTeams = <GitHubPendingTeamRequest>[];
    final reviewRequests =
        pullRequest['reviewRequests'] as Map<String, dynamic>?;
    for (final rr
        in (reviewRequests?['nodes'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()) {
      final asCodeOwner = rr['asCodeOwner'] as bool? ?? false;
      final reviewer = rr['requestedReviewer'] as Map<String, dynamic>?;
      if (reviewer == null) {
        continue;
      }
      if (reviewer['__typename'] == 'Team') {
        final slug = reviewer['slug'] as String? ?? '';
        if (slug.isEmpty) {
          continue;
        }
        pendingTeams.add(
          GitHubPendingTeamRequest(
            name: (reviewer['name'] as String?)?.trim().isNotEmpty == true
                ? reviewer['name'] as String
                : slug,
            slug: slug,
            asCodeOwner: asCodeOwner,
            avatarUrl: githubTeamAvatarUrlFromJson(reviewer),
          ),
        );
      } else {
        final login = reviewer['login'] as String? ?? '';
        if (login.isEmpty) {
          continue;
        }
        pendingUsers.add(
          GitHubPendingUserRequest(
            login: login,
            avatarUrl: reviewer['avatarUrl'] as String? ?? '',
            asCodeOwner: asCodeOwner,
          ),
        );
      }
    }

    final completed = <GitHubCompletedReview>[];
    final latestReviews = pullRequest['latestReviews'] as Map<String, dynamic>?;
    for (final r
        in (latestReviews?['nodes'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()) {
      final author = r['author'] as Map<String, dynamic>?;
      final login = author?['login'] as String? ?? '';
      if (login.isEmpty) {
        continue;
      }
      final onBehalfOf = <GitHubReviewTeamRef>[];
      final obo = r['onBehalfOf'] as Map<String, dynamic>?;
      for (final t
          in (obo?['nodes'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()) {
        final slug = t['slug'] as String? ?? '';
        if (slug.isEmpty) {
          continue;
        }
        onBehalfOf.add(
          GitHubReviewTeamRef(
            name: (t['name'] as String?)?.trim().isNotEmpty == true
                ? t['name'] as String
                : slug,
            slug: slug,
            avatarUrl: githubTeamAvatarUrlFromJson(t),
          ),
        );
      }
      completed.add(
        GitHubCompletedReview(
          authorLogin: login,
          authorAvatarUrl: author?['avatarUrl'] as String? ?? '',
          state: r['state'] as String? ?? '',
          onBehalfOf: onBehalfOf,
        ),
      );
    }

    return GitHubPrReviewState(
      pendingUsers: pendingUsers,
      pendingTeams: pendingTeams,
      completedReviews: completed,
      prState: pullRequest['state'] as String? ?? '',
      isDraft: pullRequest['isDraft'] as bool? ?? false,
    );
  }

  static PrUser _prUserFromGraphQl(Map<String, dynamic> node) {
    final rawName = (node['name'] as String?)?.trim();
    return PrUser(
      login: node['login'] as String? ?? '',
      avatarUrl: node['avatarUrl'] as String? ?? '',
      name: (rawName == null || rawName.isEmpty) ? null : rawName,
    );
  }

  Future<Map<String, dynamic>?> _runQuery(
    String query,
    Map<String, dynamic> variables,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _httpClient.post(
        '/graphql',
        body: HttpBody.json({'query': query, 'variables': variables}),
        cancelToken: cancelToken,
      );
      final body = httpJsonBody(response);
      final data = body is Map<String, dynamic> ? body : null;
      if (data == null) {
        return null;
      }

      final errors = data['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.first as Map?;
        final message = first?['message'] as String? ?? 'Unknown GraphQL error';
        throw NetworkException(message, code: 'graphql_error');
      }
      return data;
    } on NetworkException {
      rethrow;
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        rethrow;
      }
      throw mapHttpException(e);
    }
  }

  GitHubUserProfile? _parseUserProfile(Map<String, dynamic>? result) {
    final data = result?['data'] as Map<String, dynamic>?;
    final owner = data?['repositoryOwner'] as Map<String, dynamic>?;
    if (owner != null) {
      // Partial answers land here too: `fromJson` already drops nulled org
      // nodes, so a forbidden `teams` sub-field costs the org list, not the
      // card.
      return _profileFromRepositoryOwner(owner);
    }
    // No owner AND a non-NOT_FOUND errors array is a real failure (a bad
    // credential, a schema error) — surface it rather than passing it off
    // as "no such user". NOT_FOUND is the miss for an org, an app, or a
    // login GitHub has never heard of; the caller may still try GET /apps.
    final errors = result?['errors'] as List?;
    if (errors != null &&
        errors.isNotEmpty &&
        !_graphqlErrorsAreNotFound(errors)) {
      final first = errors.first as Map?;
      throw NetworkException(
        first?['message'] as String? ?? 'Unknown GraphQL error',
        code: 'graphql_error',
      );
    }
    return null;
  }

  /// Public GitHub App metadata for [login] (`GET /apps/{slug}`), or null
  /// when that slug is not an app. 404 is a miss, not an error — the GraphQL
  /// NOT_FOUND that got us here is equally true of a made-up login.
  Future<GitHubUserProfile?> _fetchAppProfile(
    String login,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _httpClient.get(
        '/apps/${Uri.encodeComponent(login)}',
        cancelToken: cancelToken,
      );
      final data = httpJsonBody(response);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return _profileFromGitHubApp(data, fallbackLogin: login);
    } on RhttpException catch (e) {
      if (e is RhttpCancelException) {
        return null;
      }
      if (isHttpStatus(e, 404)) {
        return null;
      }
      throw mapHttpException(e);
    }
  }
}

GitHubUserProfile _profileFromRepositoryOwner(Map<String, dynamic> owner) {
  if (owner['__typename'] == 'Organization') {
    return GitHubUserProfile.fromJson({...owner, 'bio': owner['description']});
  }
  return GitHubUserProfile.fromJson(owner);
}

GitHubUserProfile _profileFromGitHubApp(
  Map<String, dynamic> json, {
  required String fallbackLogin,
}) {
  final slug = json['slug'] as String? ?? '';
  final name = json['name'] as String? ?? '';
  final description = (json['description'] as String?)?.trim();
  final htmlUrl = (json['html_url'] as String?)?.trim();
  final externalUrl = (json['external_url'] as String?)?.trim();
  final id = json['id'];
  final owner = json['owner'];
  final ownerAvatar = owner is Map
      ? owner['avatar_url'] as String? ?? owner['avatarUrl'] as String?
      : null;
  final avatarUrl = id is num
      ? 'https://avatars.githubusercontent.com/in/${id.toInt()}?v=4'
      : (ownerAvatar ?? '');
  final website = (externalUrl != null && externalUrl.isNotEmpty)
      ? externalUrl
      : (htmlUrl != null && htmlUrl.isNotEmpty ? htmlUrl : null);
  return GitHubUserProfile(
    login: slug.isNotEmpty ? slug : fallbackLogin,
    name: name.isNotEmpty ? name : (slug.isNotEmpty ? slug : fallbackLogin),
    avatarUrl: avatarUrl,
    bio: (description != null && description.isNotEmpty) ? description : null,
    websiteUrl: website,
  );
}

/// GitHub puts `NOT_FOUND` in the errors array whenever `repositoryOwner`
/// (or the older `user(login:)`) does not match that type — orgs, apps,
/// and unknown logins all look like this. Only *that* miss is silent.
bool _graphqlErrorsAreNotFound(List? errors) {
  if (errors == null || errors.isEmpty) {
    return false;
  }
  for (final error in errors) {
    if (error is! Map) {
      return false;
    }
    final type = error['type'] as String?;
    if (type == 'NOT_FOUND') {
      continue;
    }
    final message = error['message'] as String? ?? '';
    if (message.contains('Could not resolve to a')) {
      continue;
    }
    return false;
  }
  return true;
}

/// Reaction shortcodes (`+1`, `rocket`, …) mapped to the GraphQL
/// `ReactionContent` enum names the mutations take.
const Map<String, String> _kReactionEnumByShortcode = <String, String>{
  '+1': 'THUMBS_UP',
  '-1': 'THUMBS_DOWN',
  'laugh': 'LAUGH',
  'hooray': 'HOORAY',
  'confused': 'CONFUSED',
  'heart': 'HEART',
  'rocket': 'ROCKET',
  'eyes': 'EYES',
};

/// The enum name a mutation needs for [shortcode], or the shortcode itself
/// when unknown (GitHub rejects it with a named error rather than a mystery).
String _reactionEnumName(String shortcode) =>
    _kReactionEnumByShortcode[shortcode] ?? shortcode;

/// The REST-style shortcode for a GraphQL [enumName] reaction (`THUMBS_UP` →
/// `+1`), so reactions read here and ones written by mutation name the same
/// thing. Unknown values keep the enum name: they stay distinguishable
/// instead of collapsing into somebody else's emoji.
String _reactionShortcode(String enumName) {
  for (final e in _kReactionEnumByShortcode.entries) {
    if (e.value == enumName) {
      return e.key;
    }
  }
  return enumName;
}

class _ProfileSearchChunkState {
  _ProfileSearchChunkState({
    required this.qualifiers,
    required this.pageSize,
  });

  final String qualifiers;
  int pageSize;
  String? cursor;
  int fetched = 0;
  int issueCount = 0;
  bool hasNext = false;
}
