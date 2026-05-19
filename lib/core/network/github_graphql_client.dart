import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/network/error_mapper.dart';
import 'package:control_center/core/network/models/github_pr_review_state.dart';
import 'package:control_center/core/network/models/github_user_profile.dart';
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
        '$githubApiBaseUrl/graphql',
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
        templates.add(
          GitHubPrTemplate(name: '', body: text, isDefault: true),
        );
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
  /// fields, diff/comment/check metrics, requested reviewers, and the data
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
  /// request: each repo contributes up to 100 PRs, and every PR fans out into
  /// `reviewRequests` + `latestReviews` + `statusCheckRollup`. Batching 20 repos
  /// (≈2000 PRs) made the query so heavy GitHub's gateway returned **HTTP 504**
  /// before finishing; combined with dropping the mergeability computation (see
  /// `_prListFieldsFragment`), 5 repos/request (≈500 PRs) keeps each request
  /// inside the gateway budget. Chunks run sequentially — 5 repos is 1 request,
  /// 50 repos is 10. If 504s persist (watch the `createDio` error log for the
  /// query + response), lower this further.
  static const int _prBatchChunkSize = 5;

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

  /// Fetches `statusCheckRollup` for the first page of open PRs across [repos],
  /// using the same chunk/page sizes as [fetchOpenPullRequestsBatch]. Returns a
  /// map keyed by the caller's repo-input index, then by PR number, containing
  /// the raw `StatusState` string (or null when no checks are configured).
  ///
  /// Called as phase 2 of progressive loading: [fetchOpenPullRequestsBatch]
  /// omits `statusCheckRollup` so the list can render immediately, then this
  /// fetches checks in parallel and the provider overlays the results.
  Future<Map<int, Map<int, String?>>> fetchOpenPullRequestsChecks(
    List<({String owner, String name})> repos, {
    CancelToken? cancelToken,
  }) async {
    if (repos.isEmpty) {
      return const {};
    }

    final result = <int, Map<int, String?>>{};

    for (var start = 0; start < repos.length; start += _prBatchChunkSize) {
      final end = (start + _prBatchChunkSize) > repos.length
          ? repos.length
          : start + _prBatchChunkSize;
      final chunk = repos.sublist(start, end);
      final data = await _postTolerant(_buildChecksQuery(chunk), cancelToken);
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

        final checksForRepo = <int, String?>{};
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
          checksForRepo[number] = rollup?['state'] as String?;
        }
        result[start + i] = checksForRepo;
      }
    }

    return result;
  }

  String _escapeGraphqlString(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  /// Core PR list fields — scalars, diff size, comments, and requested
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
  /// - `url`/`mergedAt`/`headRefOid` — no list consumer reads them.
  /// - `mergeStateStatus` — forces per-PR mergeability computation → caused
  ///   HTTP 504s on the original 20-repo batch; lane classifier falls back.
  /// - `latestReviews` — "reviewed by me" filter is lazy via
  ///   [searchReviewedByPullRequests], not carried per-PR.
  static const String _prListFieldsCoreBody = r'''
  number
  title
  isDraft
  createdAt
  updatedAt
  id
  baseRefName
  headRefName
  author { login avatarUrl }
  additions
  deletions
  comments { totalCount }
  reviewRequests(first: 10) {
    nodes {
      requestedReviewer {
        __typename
        ... on User { login avatarUrl }
        ... on Bot { login avatarUrl }
        ... on Mannequin { login avatarUrl }
        ... on Team { name }
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
  lastCommit: commits(last: 1) {
    nodes { commit { statusCheckRollup { state } } }
  }
''';

  /// Batch fragment without checks — used by [fetchOpenPullRequestsBatch] for
  /// the fast phase-1 render. Checks are enriched separately by
  /// [fetchOpenPullRequestsChecks].
  static const String _prListFieldsFragment =
      'fragment PrListFields on PullRequest {$_prListFieldsCoreBody}';

  /// Minimal fragment for the checks-only enrichment pass. Only `number` (for
  /// matching back to the phase-1 rows) and `statusCheckRollup` (the checks
  /// pill) are needed — no other fields are decoded.
  static const String _prChecksFragment = r'''
fragment PrChecksFields on PullRequest {
  number
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

  /// Runs a chunked `search(type: ISSUE)` over [repos] for open PRs matching
  /// [qualifiers] (e.g. `draft:false review-requested:octocat`), selecting
  /// [prSelection] on each `PullRequest` hit and returning the raw node maps.
  /// Shared by the review-requested, reviewed-by, and free-text searches.
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

  /// Posts a GraphQL [query] and returns the decoded body **without** throwing
  /// on a partial `errors` array — batched multi-repo queries routinely return
  /// data for the accessible repos plus errors for the rest. Transport/auth
  /// failures still throw via [mapDioException].
  Future<Map<String, dynamic>?> _postTolerant(
    String query,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/graphql',
        data: {'query': query},
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
        '$githubApiBaseUrl/graphql',
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
  Future<GitHubUserProfile?> getUserProfile({
    required String login,
    CancelToken? cancelToken,
  }) async {
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

    final result = await _runQuery(query, variables, cancelToken);
    return _parseUserProfile(result);
  }

  /// Fetches only the contribution calendar for a GitHub user.
  Future<GitHubContributionCalendar?> getUserContributions({
    required String login,
    CancelToken? cancelToken,
  }) async {
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
  /// teams) with their `asCodeOwner` flag, plus the latest review per reviewer
  /// with its `state` and the teams it was submitted `onBehalfOf`.
  ///
  /// The REST detail endpoint can't supply this — it returns only user
  /// `requested_reviewers`, with no team reviewers, no code-owner flag, and no
  /// on-behalf-of linkage. This single query feeds the enriched reviewer rail.
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
            reviewRequests(first: 50) {
              nodes {
                asCodeOwner
                requestedReviewer {
                  __typename
                  ... on User { login avatarUrl }
                  ... on Bot { login avatarUrl }
                  ... on Mannequin { login avatarUrl }
                  ... on Team { name slug }
                }
              }
            }
            latestReviews(first: 50) {
              nodes {
                state
                author { login avatarUrl }
                onBehalfOf(first: 5) { nodes { name slug } }
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
    );
  }

  Future<Map<String, dynamic>?> _runQuery(
    String query,
    Map<String, dynamic> variables,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.post(
        '$githubApiBaseUrl/graphql',
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
    if (user == null) {
      return null;
    }
    return GitHubUserProfile.fromJson(user);
  }
}
