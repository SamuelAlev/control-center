import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/models/github_pr_review_state.dart';
import 'package:cc_infra/src/network/models/github_team.dart';
import 'package:cc_infra/src/network/models/github_user_profile.dart';
import 'package:cc_infra/src/network/models/github_viewer_activity.dart';
import 'package:dio/dio.dart';

/// Raw open-pull-request nodes for a single repo, as returned by the batched
/// GraphQL query. Holds undecoded GraphQL `PullRequest` maps so this network
/// model stays free of feature-domain types — the pr_review mapper turns the
/// nodes into `PullRequest` entities.
class GitHubRepoPrNodes {
  /// Creates a [GitHubRepoPrNodes].
  const GitHubRepoPrNodes({required this.nodes, required this.hasMore});

  /// Raw GraphQL `PullRequest` node maps (created-desc, first page).
  final List<Map<String, dynamic>> nodes;

  /// Whether the repo has more open PRs beyond this first page.
  final bool hasMore;
}

/// Result of [GitHubGraphQLClient.fetchOpenPullRequestsBatch]: the viewer's
/// login (for `reviewed-by-me` derivation) plus the per-repo nodes keyed by the
/// caller's input index. Repos that errored/are inaccessible are simply absent
/// from [byIndex] (GraphQL returns partial data + an errors array; one bad repo
/// must not blank the whole dashboard).
class GitHubPrBatchResult {
  /// Creates a [GitHubPrBatchResult].
  const GitHubPrBatchResult({required this.viewerLogin, required this.byIndex});

  /// The authenticated user's login, or null if the query couldn't resolve it.
  final String? viewerLogin;

  /// Per-repo nodes keyed by the index of the repo in the caller's input list.
  final Map<int, GitHubRepoPrNodes> byIndex;
}

/// One PR's slice of the checks/review enrichment pass
/// ([GitHubGraphQLClient.fetchOpenPullRequestsChecks]): the raw
/// `statusCheckRollup.state` string (null when no checks are configured) and
/// the raw `reviewDecision` string (null when no reviews are required/given).
typedef GitHubPrStatusOverlay = ({
  String? checksRollup,
  String? reviewDecision,
});

/// One inline review thread's conversation state, from
/// [GitHubGraphQLClient.listReviewThreads].
///
/// [commentIds] are REST `databaseId`s, so a thread's state can be stamped onto
/// the comments the diff already fetched without a per-comment round trip.
class GitHubReviewThread {
  /// Creates a [GitHubReviewThread].
  const GitHubReviewThread({
    required this.id,
    required this.isResolved,
    required this.isOutdated,
    required this.commentIds,
  });

  /// GraphQL node id of the thread — the handle the resolve mutations take.
  final String id;

  /// Whether the conversation is marked resolved.
  final bool isResolved;

  /// Whether the thread's anchor line is gone from the current diff.
  final bool isOutdated;

  /// Numeric ids of the thread's comments.
  final List<int> commentIds;
}

/// One reaction on a review summary, from
/// [GitHubGraphQLClient.listReviewReactions].
class GitHubReviewReaction {
  /// Creates a [GitHubReviewReaction].
  const GitHubReviewReaction({
    required this.id,
    required this.content,
    required this.login,
  });

  /// GraphQL node id of the reaction — the handle `removeReaction` takes.
  final String id;

  /// Reaction content in the REST shortcode vocabulary (`+1`, `rocket`, …).
  final String content;

  /// Login of the account that reacted (empty when withheld).
  final String login;
}

/// One review's reactions plus the handles reacting to it requires, from
/// [GitHubGraphQLClient.listReviewReactions].
class GitHubReviewReactionSet {
  /// Creates a [GitHubReviewReactionSet].
  const GitHubReviewReactionSet({
    required this.databaseId,
    required this.nodeId,
    required this.reactions,
  });

  /// The review's REST numeric id — what joins this back to the REST review.
  final int databaseId;

  /// GraphQL node id of the review — the `addReaction` subject handle.
  final String nodeId;

  /// The reactions themselves.
  final List<GitHubReviewReaction> reactions;
}

/// A head branch plus its last-commit activity, from
/// [GitHubGraphQLClient.listBranchesWithActivity].
class GitHubBranchActivity {
  /// Creates a [GitHubBranchActivity].
  const GitHubBranchActivity({
    required this.name,
    required this.committedDate,
    required this.authorLogin,
  });

  /// Branch name (without the `refs/heads/` prefix).
  final String name;

  /// Date of the branch's tip commit, or null if unavailable.
  final DateTime? committedDate;

  /// GitHub login of the tip commit's author, or null if the author doesn't
  /// map to a GitHub user.
  final String? authorLogin;
}

/// A single pull-request template discovered in a repo: a display [name] and
/// the markdown [body] used to seed a new PR's description. [isDefault] marks
/// the repo's single conventional `pull_request_template.md` (as opposed to a
/// named template from a `PULL_REQUEST_TEMPLATE/` directory) so the UI can
/// localise its label.
class GitHubPrTemplate {
  /// Creates a [GitHubPrTemplate].
  const GitHubPrTemplate({
    required this.name,
    required this.body,
    this.isDefault = false,
  });

  /// Display name — derived from the template's filename, or empty for the
  /// single default template (the UI substitutes a localised "Default").
  final String name;

  /// The template's markdown content.
  final String body;

  /// Whether this is the repo's single default template (not a named one).
  final bool isDefault;
}

/// Client for GitHub GraphQL API mutations and queries.
class GitHubGraphQLClient {
  /// Creates a [GitHubGraphQLClient] backed by [Dio].
  GitHubGraphQLClient(this._dio);

  final Dio _dio;

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
      await _dio.post(
        '/graphql',
        data: {
          'query': mutation,
          'variables': {'pullRequestId': pullRequestId, 'path': path},
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
        out.add(
          GitHubReviewThread(
            id: id,
            isResolved: node['isResolved'] as bool? ?? false,
            isOutdated: node['isOutdated'] as bool? ?? false,
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
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

  /// Fetches the first page of open pull requests for many repos in a **single
  /// GraphQL request** (one aliased `repository` node per repo), with the list
  /// fields, diff/comment/check metrics, requested reviewers and the data
  /// needed to derive `reviewed-by-me` — all at once.
  ///
  /// This replaces what was a 3×N REST/GraphQL fan-out on the dashboard (per
  /// repo: `GET /pulls` + a `reviewed-by:@me` search + a metrics query) with a
  /// single round-trip. PRs are ordered `CREATED_AT DESC` to match the REST
  /// `GET /pulls` default, so a later REST `loadMore` page lines up with this
  /// first page.
  ///
  /// Large repo lists are split into chunks of [_prBatchChunkSize] to bound
  /// each request's cost under GitHub's GraphQL secondary rate limit; chunks run
  /// sequentially, one request each. The result tolerates partial failure: a
  /// repo whose
  /// alias errored (no access, etc.) is omitted from
  /// [GitHubPrBatchResult.byIndex] rather than failing the whole batch.
  Future<GitHubPrBatchResult> fetchOpenPullRequestsBatch(
    List<({String owner, String name})> repos, {
    CancelToken? cancelToken,
  }) async {
    if (repos.isEmpty) {
      return const GitHubPrBatchResult(viewerLogin: null, byIndex: {});
    }

    final byIndex = <int, GitHubRepoPrNodes>{};

    for (var start = 0; start < repos.length; start += _prBatchChunkSize) {
      final end = (start + _prBatchChunkSize) > repos.length
          ? repos.length
          : start + _prBatchChunkSize;
      final chunk = repos.sublist(start, end);
      final data = await _postTolerant(_buildBatchQuery(chunk), cancelToken);
      final root = data?['data'] as Map<String, dynamic>?;
      if (root == null) {
        continue;
      }
      for (var i = 0; i < chunk.length; i++) {
        // An inaccessible/errored repo alias comes back null alongside an entry
        // in the top-level `errors` array — skip it, keep the rest.
        final repository = root['r$i'] as Map<String, dynamic>?;
        if (repository == null) {
          continue;
        }
        final pulls = repository['pullRequests'] as Map<String, dynamic>?;
        final nodes =
            (pulls?['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList(growable: false) ??
            const <Map<String, dynamic>>[];
        final pageInfo = pulls?['pageInfo'] as Map<String, dynamic>?;
        final hasMore = pageInfo?['hasNextPage'] as bool? ?? false;
        byIndex[start + i] = GitHubRepoPrNodes(nodes: nodes, hasMore: hasMore);
      }
    }

    return GitHubPrBatchResult(viewerLogin: null, byIndex: byIndex);
  }

  /// Maximum repos per GraphQL request. Bounds how much work GitHub does for one
  /// request: each repo contributes up to 100 PRs and every PR fans out into
  /// `reviewRequests` + `latestReviews` + `statusCheckRollup`. Batching 20 repos
  /// (≈2000 PRs) made the query so heavy GitHub's gateway returned **HTTP 504**
  /// before finishing; combined with dropping the mergeability computation (see
  /// `_prListFieldsFragment`), 5 repos/request (≈500 PRs) keeps each request
  /// inside the gateway budget. Chunks run sequentially — 5 repos is 1 request,
  /// 50 repos is 10. If 504s persist (watch the `createDio` error log for the
  /// query + response), lower this further.
  static const int _prBatchChunkSize = 5;

  /// Repos per request for the checks/review enrichment pass, deliberately
  /// smaller than [_prBatchChunkSize].
  ///
  /// `statusCheckRollup` makes GitHub walk every open PR's head commit and
  /// roll up its check runs, so this query is far heavier per repo than the
  /// list it enriches — at 5 repos × 100 PRs it draws **HTTP 502/504 several
  /// times an hour** against a busy org (measured across five Frontify repos),
  /// and those chunks come back with no data at all. Two repos per request
  /// keeps each one inside the gateway budget and, when one does fail anyway,
  /// costs the sweep two repos' fresh checks instead of five.
  static const int _prChecksChunkSize = 2;

  /// Open PRs fetched per repo on the first page. Matches the REST list's
  /// `per_page`, so REST pagination (`loadMore`) continues cleanly.
  static const int _prBatchPageSize = 100;

  String _buildBatchQuery(List<({String owner, String name})> chunk) {
    final b = StringBuffer('query {\n');
    for (var i = 0; i < chunk.length; i++) {
      final owner = _escapeGraphqlString(chunk[i].owner);
      final name = _escapeGraphqlString(chunk[i].name);
      b
        ..writeln('  r$i: repository(owner: "$owner", name: "$name") {')
        ..writeln(
          '    pullRequests(states: OPEN, first: $_prBatchPageSize, '
          'orderBy: {field: CREATED_AT, direction: DESC}) {',
        )
        ..writeln('      pageInfo { hasNextPage }')
        ..writeln('      nodes { ...PrListFields }')
        ..writeln('    }')
        ..writeln('  }');
    }
    b
      ..writeln('}')
      ..writeln(_prListFieldsFragment);
    return b.toString();
  }

  String _buildChecksQuery(List<({String owner, String name})> chunk) {
    final b = StringBuffer('query {\n');
    for (var i = 0; i < chunk.length; i++) {
      final owner = _escapeGraphqlString(chunk[i].owner);
      final name = _escapeGraphqlString(chunk[i].name);
      b
        ..writeln('  r$i: repository(owner: "$owner", name: "$name") {')
        ..writeln(
          '    pullRequests(states: OPEN, first: $_prBatchPageSize, '
          'orderBy: {field: CREATED_AT, direction: DESC}) {',
        )
        ..writeln('      nodes { ...PrChecksFields }')
        ..writeln('    }')
        ..writeln('  }');
    }
    b
      ..writeln('}')
      ..writeln(_prChecksFragment);
    return b.toString();
  }

  /// Fetches `statusCheckRollup` + `reviewDecision` for the first page of open
  /// PRs across [repos], at [_prBatchPageSize] per repo and
  /// [_prChecksChunkSize] repos per request. Returns a map keyed by the
  /// caller's repo-input index, then by PR number, containing the raw
  /// `StatusState` string (or null when no checks are configured) and the raw
  /// `PullRequestReviewDecision` string (or null when no reviews are required
  /// or given).
  ///
  /// Called as phase 2 of progressive loading: [fetchOpenPullRequestsBatch]
  /// omits both fields so the list can render immediately, then this fetches
  /// them in parallel and the provider overlays the results.
  ///
  /// A repo index ABSENT from the result was not read this pass — it is not
  /// the same claim as an index mapping to an empty map, which means the repo
  /// answered and has no open PRs. Callers that persist these values must keep
  /// their previous state for an absent index rather than writing "no checks";
  /// null and "nothing" decode to the same enum, and announcing the difference
  /// as news is what turned every gateway timeout into a repeat notification.
  Future<Map<int, Map<int, GitHubPrStatusOverlay>>> fetchOpenPullRequestsChecks(
    List<({String owner, String name})> repos, {
    CancelToken? cancelToken,
  }) async {
    if (repos.isEmpty) {
      return const {};
    }

    final result = <int, Map<int, GitHubPrStatusOverlay>>{};
    // Chunks are independent requests, so one gateway timeout must not throw
    // away the chunks that DID answer: the caller overlays what it got and
    // keeps its previous value for the rest. Only a sweep where every chunk
    // failed rethrows, so "GitHub could not answer at all" still reaches the
    // caller's log instead of looking like a workspace with no checks.
    Object? failure;

    for (var start = 0; start < repos.length; start += _prChecksChunkSize) {
      final end = (start + _prChecksChunkSize) > repos.length
          ? repos.length
          : start + _prChecksChunkSize;
      final chunk = repos.sublist(start, end);
      final Map<String, dynamic>? data;
      try {
        data = await _postTolerant(_buildChecksQuery(chunk), cancelToken);
      } on Object catch (e) {
        failure = e;
        continue;
      }
      final root = data?['data'] as Map<String, dynamic>?;
      if (root == null) {
        continue;
      }

      for (var i = 0; i < chunk.length; i++) {
        final repository = root['r$i'] as Map<String, dynamic>?;
        if (repository == null) {
          continue;
        }
        final pulls = repository['pullRequests'] as Map<String, dynamic>?;
        final nodes =
            (pulls?['nodes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList(growable: false) ??
            const <Map<String, dynamic>>[];

        final checksForRepo = <int, GitHubPrStatusOverlay>{};
        for (final node in nodes) {
          final number = (node['number'] as num?)?.toInt() ?? 0;
          if (number <= 0) {
            continue;
          }
          final lastCommit = node['lastCommit'] as Map<String, dynamic>?;
          final lastCommitNodes = lastCommit?['nodes'] as List?;
          final firstCommit =
              (lastCommitNodes != null && lastCommitNodes.isNotEmpty)
              ? lastCommitNodes.first as Map<String, dynamic>?
              : null;
          final commit = firstCommit?['commit'] as Map<String, dynamic>?;
          final rollup = commit?['statusCheckRollup'] as Map<String, dynamic>?;
          checksForRepo[number] = (
            checksRollup: rollup?['state'] as String?,
            reviewDecision: node['reviewDecision'] as String?,
          );
        }
        result[start + i] = checksForRepo;
      }
    }

    if (result.isEmpty && failure != null) {
      throw failure;
    }
    return result;
  }

  String _escapeGraphqlString(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  /// Core PR list fields — scalars, diff size, comments and requested
  /// reviewers. Intentionally excludes `statusCheckRollup` (inside
  /// `lastCommit: commits(last: 1)`):
  ///
  /// - `statusCheckRollup` is relatively cheap per PR but not free; across
  ///   100 PRs × N repos on every load it is the dominant remaining latency.
  ///   Dropping it here lets the list render immediately (phase 1). Checks are
  ///   fetched in a separate, parallel pass via [fetchOpenPullRequestsChecks]
  ///   (phase 2) and overlaid onto the already-visible rows.
  ///
  /// Other omissions (unchanged from before):
  /// - `body`/`bodyHtml`/`changedFiles`/`commitsTotal` — peek-panel only, lazy
  ///   via `peekPrContentProvider`.
  /// - `url`/`mergedAt` — no list consumer reads them.
  /// - `mergeStateStatus` — forces per-PR mergeability computation → caused
  ///   HTTP 504s on the original 20-repo batch; lane classifier falls back.
  ///   Merge readiness is derived from `reviewDecision` + the checks rollup
  ///   instead, and confirmed with ONE targeted REST call on the transition —
  ///   never re-added here, and never to [_prChecksFragment] either, which
  ///   runs even more often.
  /// - `latestReviews` — "reviewed by me" filter is lazy via
  ///   [searchReviewedByPullRequests], not carried per-PR.
  /// `headRefOid` IS carried: it is a plain scalar (not a connection and not
  /// a computed field, so it is not what blew the gateway budget) and two
  /// things need it. `PrHeadChanged` — and therefore the stale-review
  /// notification — can only fire when the poller can see the head move, and
  /// the merge-readiness dedupe has to re-arm when the author pushes.
  static const String _prListFieldsCoreBody = r'''
  number
  title
  isDraft
  createdAt
  updatedAt
  id
  baseRefName
  headRefName
  headRefOid
  author { login avatarUrl }
  additions
  deletions
  comments { totalCount }
  reviewRequests(first: 50) {
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

  /// The dashboard's "priority reviews" panel shows only the PRs that request
  /// the operator's review. Fetching that handful through
  /// [fetchOpenPullRequestsBatch] is wasteful — that query pulls *every* open
  /// PR in *every* repo (100/repo) with full reviewer/check connections, then
  /// the dashboard discards all but a few. This is the lean alternative: GitHub
  /// filters server-side (`is:pr is:open draft:false review-requested:<login>`,
  /// scoped to [repos]), so only the matching PRs come back, carrying just the
  /// fields that panel renders (title, branch, age, diff size, comments).
  ///
  /// Returns the raw GraphQL `PullRequest` node maps (each with a
  /// `repository.nameWithOwner` for grouping under the caller's repo set), so
  /// this network model stays free of feature-domain types — the pr_review
  /// mapper decodes them. The caller still applies the ">24h stale" cut.
  ///
  /// Repos are chunked into groups of [_reviewSearchChunkSize] so no single
  /// search query grows past GitHub's query-length limit; chunks run
  /// sequentially (one request each), matching [fetchOpenPullRequestsBatch]'s
  /// rate-limit discipline. A typical single-repo workspace is one request.
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
  ///
  /// Replaces the old per-repo REST `/search/issues` + `fetchPullRequestMetrics`
  /// pair (2×N calls, with metrics fetched for 100 PRs/repo *including* the
  /// expensive `mergeStateStatus` mergeability computation) — here the fields
  /// are fetched only for the PRs that actually matched.
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

  /// One sweep of the viewer's own pull-request activity, in a **single**
  /// request.
  ///
  /// This is the replacement for `GET /notifications`, which no GitHub App
  /// token — installation *or* user-to-server — can ever read (GitHub answers
  /// "Resource not accessible by integration", permanently, because no App
  /// permission grants that endpoint). Since signing in mints a GitHub App user
  /// token, the inbox lane was dead for every install that had not additionally
  /// pasted a classic PAT. `search` is reachable by every credential kind, so
  /// this lane works the same for an App token, an OAuth token and a PAT.
  ///
  /// The four lanes ride four **aliased** searches in one HTTP request and one
  /// rate-limit charge. Each is a server-side predicate, which is what makes
  /// this *cheaper* than the inbox poll it replaces rather than merely
  /// equivalent: the old path fetched threads and then spent an extra per-thread
  /// GraphQL round-trip verifying whether the review was really pending and
  /// whether the PR was really merged. Here GitHub applied both predicates
  /// before answering.
  ///
  /// Deliberately **not** scoped by `repo:`. The old inbox was global and the
  /// caller filtered it against its repo→workspace index; keeping that shape
  /// means one request regardless of how many repos are linked, instead of one
  /// per five-repo chunk. The caller still drops anything it cannot route.
  ///
  /// [since] bounds the three activity lanes (the pending-review lane is a
  /// *set*, not a delta, so it is unbounded by design — a review requested
  /// months ago is still pending today). Pass the previous sweep's start, minus
  /// an overlap: GitHub's search index lags writes by seconds to a minute, so
  /// an exactly-abutting window silently drops events. Over-fetching is free
  /// here because the caller dedupes.
  ///
  /// One caveat, stated rather than smoothed: a **user-to-server token only
  /// sees repos the App is installed on**. A linked repo without the
  /// installation returns nothing from these searches and simply goes quiet —
  /// it does not error, so there is no failure to report. Every other surface
  /// in the product needs that installation too, so this narrows nothing that
  /// was otherwise working.
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

  /// Searches the open pull requests the server's bot identity is being
  /// invoked on: PRs whose conversation @mentions [botLogin] or its bare
  /// slug (GitHub does not resolve `@slug` to an app account, so the short
  /// form needs a raw comment-TEXT lane to be discoverable at all), and PRs
  /// carrying [label] (the reviewer-assignment stand-in — an installed app
  /// cannot hold the native requested-reviewer slot, so a label is the
  /// explicit "review this" ask).
  ///
  /// Same shape and cost discipline as [searchViewerPullRequestActivity]:
  /// one aliased request for every lane, deliberately not scoped by `repo:`
  /// (the caller filters against its repo→workspace index), and [since]
  /// bounds ONLY the mention lanes — the label lane is an unbounded *set*
  /// whose membership is itself the trigger state, exactly like the
  /// pending-review lane of the viewer sweep.
  ///
  /// The bot login carries brackets (`app[bot]`) and the label may contain
  /// spaces, so both ride as quoted search values. The short-alias lane is
  /// phrase-matched over comment text (`in:comments "@slug"`), which also
  /// catches full-login mentions as a substring — harmless, the caller
  /// dedupes per PR and per comment id.
  Future<
    ({
      List<GitHubViewerPr> mentioned,
      List<GitHubViewerPr> shortMentioned,
      List<GitHubViewerPr> labeled,
    })
  >
  searchBotConversationCandidates({
    required String botLogin,
    required String label,
    DateTime? since,
    CancelToken? cancelToken,
  }) async {
    if (botLogin.isEmpty) {
      return (
        mentioned: const <GitHubViewerPr>[],
        shortMentioned: const <GitHubViewerPr>[],
        labeled: const <GitHubViewerPr>[],
      );
    }
    final short = botLogin.toLowerCase().endsWith('[bot]')
        ? botLogin.substring(0, botLogin.length - '[bot]'.length)
        : '';
    final window = (since ?? DateTime.now().toUtc().subtract(_activityWindow))
        .toUtc();
    // Second precision: GitHub rejects sub-second values in a date qualifier.
    final stamp = window.toIso8601String().split('.').first;

    const query = r'''
query($mn: String!, $sm: String!, $lb: String!, $first: Int!) {
  mentioned: search(query: $mn, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
  shortMentioned: search(query: $sm, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
  labeled: search(query: $lb, type: ISSUE, first: $first) {
    nodes { ...viewerPr }
  }
}
fragment viewerPr on PullRequest {
  number
  title
  updatedAt
  repository { nameWithOwner }
}''';

    final response = await _runQuery(query, <String, dynamic>{
      'mn': 'is:pr mentions:"$botLogin" updated:>$stamp',
      'sm': short.isEmpty
          ? 'is:pr no:label no:milestone'
          : 'is:pr in:comments "@$short" updated:>$stamp',
      'lb': label.isEmpty
          ? 'is:pr is:open no:label'
          : 'is:pr is:open label:"$label"',
      'first': _reviewSearchPageSize,
    }, cancelToken);

    final data = response?['data'] as Map<String, dynamic>?;
    return (
      mentioned: _viewerPrNodes(data, 'mentioned'),
      shortMentioned: short.isEmpty
          ? const <GitHubViewerPr>[]
          : _viewerPrNodes(data, 'shortMentioned'),
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

    final nodes = <Map<String, dynamic>>[];
    for (var start = 0; start < repos.length; start += _reviewSearchChunkSize) {
      final end = (start + _reviewSearchChunkSize) > repos.length
          ? repos.length
          : start + _reviewSearchChunkSize;
      final chunk = repos.sublist(start, end);

      final q = StringBuffer('is:pr is:open ')..write(qualifiers);
      for (final r in chunk) {
        q
          ..write(' repo:')
          ..write(r.owner)
          ..write('/')
          ..write(r.name);
      }

      Map<String, dynamic>? response;
      try {
        response = await _runQuery(query, <String, dynamic>{
          'q': q.toString(),
          'first': _reviewSearchPageSize,
        }, cancelToken);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          return const [];
        }
        rethrow;
      }

      final data = response?['data'] as Map<String, dynamic>?;
      final search = data?['search'] as Map<String, dynamic>?;
      final searchNodes = search?['nodes'] as List?;
      if (searchNodes == null) {
        continue;
      }
      // Non-PR hits (none expected given `is:pr`) deserialize as empty maps.
      nodes.addAll(
        searchNodes.whereType<Map<String, dynamic>>().where(
          (n) => n.isNotEmpty,
        ),
      );
    }
    return nodes;
  }

  /// Repos per review-requested search query. Keeps each query's `repo:`
  /// qualifier list short enough to stay under GitHub's search query-length
  /// limit; chunks run sequentially.
  static const int _reviewSearchChunkSize = 5;

  /// PRs fetched per review-requested search page. A single operator almost
  /// never has more than this many reviews outstanding across a chunk.
  static const int _reviewSearchPageSize = 100;

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
  }) async {
    if (login.isEmpty || repos.isEmpty) {
      return (open: 0, draft: 0, merged: 0, closed: 0);
    }
    const query =
        'query(\$open: String!, \$draft: String!, \$merged: String!, '
        '\$closed: String!) {\n'
        '  open: search(query: \$open, type: ISSUE, first: 1) { issueCount }\n'
        '  draft: search(query: \$draft, type: ISSUE, first: 1) { issueCount }\n'
        '  merged: search(query: \$merged, type: ISSUE, first: 1) { issueCount }\n'
        '  closed: search(query: \$closed, type: ISSUE, first: 1) { issueCount }\n'
        '}';

    var open = 0, draft = 0, merged = 0, closed = 0;
    for (var start = 0; start < repos.length; start += _reviewSearchChunkSize) {
      final end = (start + _reviewSearchChunkSize) > repos.length
          ? repos.length
          : start + _reviewSearchChunkSize;
      final chunk = repos.sublist(start, end);

      // Shared `author:<login> repo:<o/r> …` scope; the state qualifiers
      // (is:open/draft/merged/unmerged) are prepended per alias. Values go in
      // via variables, never interpolated into the query body, so they need no
      // GraphQL escaping.
      final scope = StringBuffer('author:')..write(login);
      for (final r in chunk) {
        scope
          ..write(' repo:')
          ..write(r.owner)
          ..write('/')
          ..write(r.name);
      }
      final base = scope.toString();

      Map<String, dynamic>? response;
      try {
        response = await _runQuery(query, <String, dynamic>{
          'open': 'is:pr is:open draft:false $base',
          'draft': 'is:pr is:open draft:true $base',
          'merged': 'is:pr is:merged $base',
          'closed': 'is:pr is:closed is:unmerged $base',
        }, cancelToken);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          return (open: open, draft: draft, merged: merged, closed: closed);
        }
        rethrow;
      }

      final data = response?['data'] as Map<String, dynamic>?;
      int countOf(String alias) =>
          ((data?[alias] as Map<String, dynamic>?)?['issueCount'] as num?)
              ?.toInt() ??
          0;
      open += countOf('open');
      draft += countOf('draft');
      merged += countOf('merged');
      closed += countOf('closed');
    }
    return (open: open, draft: draft, merged: merged, closed: closed);
  }

  /// Posts a GraphQL [query] (with optional [variables]) and returns the decoded
  /// body **without** throwing on a partial `errors` array — batched multi-repo
  /// queries routinely return data for the accessible repos plus errors for the
  /// rest, and a single-entity query can have one sub-field forbidden by the
  /// credential while every other field resolved. Transport/auth failures still
  /// throw via [mapDioException].
  Future<Map<String, dynamic>?> _postTolerant(
    String query,
    CancelToken? cancelToken, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      final response = await _dio.post(
        '/graphql',
        data: {'query': query, 'variables': ?variables},
        cancelToken: cancelToken,
      );
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Cancellation is the normal teardown path: `prsByRepoProvider` cancels
        // this request via its `onDispose` whenever the provider rebuilds (a
        // watched repo/auth/workspace stream re-emitting at startup, or a
        // workspace switch). That is not an error — returning null lets the
        // (already-superseded) build settle quietly instead of throwing a raw,
        // unmapped DioException into Riverpod, which would surface as a spurious
        // error and churn the loading state. The fresh build's request is what
        // actually populates the list.
        return null;
      }
      throw mapDioException(e);
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
      await _dio.post(
        '/graphql',
        data: {
          'query': mutation,
          'variables': {'pullRequestId': pullRequestId, 'path': path},
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

  /// Fetches a GitHub user's profile (name, bio, avatar, contribution
  /// calendar) via the GraphQL API.
  ///
  /// GitHub App bots (`login[bot]`) are skipped: `user(login:)` cannot
  /// resolve them (they are `Bot` nodes, not `User`).
  ///
  /// Tolerant of a PARTIAL answer, because one credential kind cannot read all
  /// of it: a GitHub App installation token is refused `organizations.nodes
  /// .teams` ("Resource not accessible by integration"), and since `teams` is
  /// non-null in the schema GitHub nulls the whole org node and reports one
  /// FORBIDDEN error per org — while `login`, `name`, `bio`, `status` and the
  /// contribution calendar all resolved in the same response. Throwing on the
  /// errors array (what [_runQuery] does) discarded that complete answer and
  /// blanked the hover card. The caller fetches on the acting user's own token,
  /// where nothing is forbidden; this keeps the app-identity FALLBACK — a
  /// member who has not connected GitHub — showing a profile without orgs
  /// instead of an error. A response with no `user` at all and an errors array
  /// still throws: that is a real failure, not a partial one.
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
        user(login: $login) {
          login
          name
          avatarUrl
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
    return _parseUserProfile(result);
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
      final response = await _dio.post(
        '/graphql',
        data: {'query': query, 'variables': variables},
        cancelToken: cancelToken,
      );
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : null;
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        rethrow;
      }
      throw mapDioException(e);
    }
  }

  GitHubUserProfile? _parseUserProfile(Map<String, dynamic>? result) {
    final data = result?['data'] as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    if (user != null) {
      // Partial answers land here too: `fromJson` already drops nulled org
      // nodes, so a forbidden `teams` sub-field costs the org list, not the
      // card.
      return GitHubUserProfile.fromJson(user);
    }
    // No user AND an errors array is a real failure (a bad credential, a
    // rate limit) — surface it rather than passing it off as "no such user",
    // which is what a plain null means here.
    final errors = result?['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final first = errors.first as Map?;
      throw NetworkException(
        first?['message'] as String? ?? 'Unknown GraphQL error',
        code: 'graphql_error',
      );
    }
    return null;
  }
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
