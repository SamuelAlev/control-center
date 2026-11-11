/// What an automation request to GitHub may carry, decided from its method,
/// URL and body alone: the one-repository scope it needs, and the requests
/// automation must never send at all.
library;

import 'package:cc_connect_core/cc_connect_core.dart'
    show GitHubTokenScope, isGitHubSegment;
import 'package:cc_server_core/src/forge/github_graphql_policy.dart';

/// Why a request must not be sent on an automation client, or null.
///
/// A `/repos/{o}/{r}/…` write that no one-repository scope covers is
/// refused. Anything else is refused unless it only reads (`GET`/`HEAD`, a
/// GraphQL query), whoever is acting: an automation client never carries a
/// person's own token, so a GraphQL mutation or a write outside one
/// repository is a person's to make through their own client.
String? refuseUnscopedGitHubWrite(String method, String url, Object? body) {
  final target = githubScopeForRequest(method, url);
  if (target != null) {
    return target.scope == null
        ? 'No single-repository GitHub token covers $method $url.'
        : null;
  }
  final verb = method.toUpperCase();
  if (verb == 'GET' || verb == 'HEAD') {
    return null;
  }
  final segments = (Uri.tryParse(url)?.pathSegments ?? const <String>[])
      .where((s) => s.isNotEmpty)
      .toList();
  final isGraphQl =
      verb == 'POST' && segments.length == 1 && segments.single == 'graphql';
  if (isGraphQl && !isGraphQlWrite(body)) {
    return null;
  }
  return 'Automation writes to GitHub only through a one-repository token; '
      'a person must do this from their own account.';
}

/// Why an automation request must not be sent, or null: a pull request
/// review (`POST /repos/{o}/{r}/pulls/{n}/reviews`, or submitting a pending
/// one at `.../reviews/{id}/events`) or a GraphQL review mutation whose
/// event is `APPROVE`. Comments and change requests pass.
///
/// On those two endpoints a body this guard cannot read (bytes, a form, none
/// at all) is refused too, and so is an `APPROVE` anywhere in the query
/// string: what the guard cannot see, it does not let through.
String? refuseAutomatedGitHubApproval(String method, String url, Object? body) {
  if (method.toUpperCase() != 'POST') {
    return null;
  }
  final uri = Uri.tryParse(url);
  final segments = (uri?.pathSegments ?? const <String>[])
      .where((s) => s.isNotEmpty)
      .toList();
  const refusal =
      'Automation never approves a pull request; a person approves from '
      'their own account.';
  const unreadable =
      'An automated pull request review or GraphQL request must carry a JSON '
      'body.';
  final isGraphQl = segments.length == 1 && segments.single == 'graphql';
  final isReview =
      segments.length >= 6 &&
      segments[0] == 'repos' &&
      segments[3] == 'pulls' &&
      segments[5] == 'reviews' &&
      (segments.length == 6 ||
          (segments.length == 8 && segments[7] == 'events'));
  if (!isGraphQl && !isReview) {
    return null;
  }
  final query = uri?.queryParametersAll ?? const <String, List<String>>{};
  if (query.values.any((values) => values.any(_anyApprove))) {
    return refusal;
  }
  if (body is! Map) {
    return unreadable;
  }
  if (isGraphQl) {
    final document = body['query'];
    final isReviewMutation =
        document is String &&
        document.toLowerCase().contains('pullrequestreview');
    final approves =
        (document is String && _approveWord.hasMatch(document)) ||
        _anyApprove(body['variables']);
    return isReviewMutation && approves ? refusal : null;
  }
  final event = body['event'];
  return event is String && event.toUpperCase() == 'APPROVE' ? refusal : null;
}

final _approveWord = RegExp(r'\bAPPROVE\b', caseSensitive: false);

bool _anyApprove(Object? value) => switch (value) {
  final String s => s.toUpperCase() == 'APPROVE',
  final Map<Object?, Object?> m => m.values.any(_anyApprove),
  final List<Object?> l => l.any(_anyApprove),
  _ => false,
};

/// The repository and scope a REST request needs, or null when it is not
/// about one repository (GraphQL, search, orgs, users).
///
/// A write is mapped only where a scope carries the permission it needs:
/// conversation through the issues API (comments, reactions, labels,
/// assignees, opening an issue) `comment`; reviews, review comments,
/// reactions on them and review requests `bot`; code, opening a pull request or
/// changing its title, state, base or branch, dismissing a review, and
/// editing or deleting a comment that may be someone else's `write` (on a
/// Connect lane only a person's own token holds it, so the shared App's bot
/// does none of these). Any other `/repos/{o}/{r}` write (statuses, checks,
/// actions, settings, locking a conversation…), or a malformed repository
/// path, answers a null scope: no token.
({String owner, String repo, GitHubTokenScope? scope})? githubScopeForRequest(
  String method,
  String url,
) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.first != 'repos') {
    return null;
  }
  if (segments.length < 3 ||
      !isGitHubSegment(segments[1]) ||
      !isGitHubSegment(segments[2])) {
    return (
      owner: segments.length > 1 ? segments[1] : '',
      repo: segments.length > 2 ? segments[2] : '',
      scope: null,
    );
  }
  final owner = segments[1];
  final repo = segments[2];
  final verb = method.toUpperCase();
  if (verb == 'GET' || verb == 'HEAD') {
    return (owner: owner, repo: repo, scope: GitHubTokenScope.read);
  }
  return (owner: owner, repo: repo, scope: _writeScope(segments.sublist(3)));
}

GitHubTokenScope? _writeScope(List<String> rest) {
  if (rest.isEmpty) {
    return null;
  }
  final tail = rest.sublist(1);
  switch (rest.first) {
    case 'issues' when tail.contains('reactions'):
      // A reaction on an issue, a pull request's conversation or one of its
      // comments.
      return GitHubTokenScope.comment;
    case 'pulls' when tail.contains('reactions'):
      // A reaction on a review comment: the pull requests API.
      return GitHubTokenScope.bot;
    case 'issues' || 'pulls' when tail.isNotEmpty && tail.first == 'comments':
      // `{issues,pulls}/comments/{id}`: editing or deleting a comment that
      // may be someone else's.
      return GitHubTokenScope.write;
    case 'issues' when tail.length > 1 && tail[1] == 'lock':
      // Locking a conversation is a moderator's act: no automation token.
      return null;
    case 'issues':
      // Opening an issue; its comments, labels and assignees; and
      // `PATCH /issues/{n}`. That last can also close or retitle a pull
      // request, but its URL cannot tell one from an issue, and ticket sync
      // edits the issues it opened with it: `write` carries no `issues`
      // permission. The server sends it for no pull request.
      return GitHubTokenScope.comment;
    case 'pulls':
      if (tail.contains('merge') ||
          tail.contains('update-branch') ||
          tail.contains('dismissals')) {
        return GitHubTokenScope.write;
      }
      // Review comments, reviews (approval is refused separately) and
      // asking for reviewers are review work; `POST /pulls` opens a pull
      // request and `PATCH /pulls/{n}` changes its title, body, state or
      // base.
      const review = {'comments', 'reviews', 'requested_reviewers'};
      return tail.length > 1 && review.contains(tail[1])
          ? GitHubTokenScope.bot
          : GitHubTokenScope.write;
    case 'contents' || 'git' || 'merges' || 'stacks':
      return GitHubTokenScope.write;
    default:
      return null;
  }
}

/// Whether [method] [url] is a GitHub GraphQL call (`POST /graphql`).
bool isGitHubGraphQlRequest(String method, String url) {
  final segments = (Uri.tryParse(url)?.pathSegments ?? const <String>[])
      .where((s) => s.isNotEmpty)
      .toList();
  return method.toUpperCase() == 'POST' &&
      segments.length == 1 &&
      segments.single == 'graphql';
}

/// A `GET /search/issues` whose query names exactly [owner]/[repo] as its
/// only repository, organization or user qualifier.
bool isGitHubRepoSearch(String owner, String repo, String method, String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || method.toUpperCase() != 'GET') {
    return false;
  }
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 2 ||
      segments.first != 'search' ||
      segments.last != 'issues') {
    return false;
  }
  final q = uri.queryParameters['q'] ?? '';
  final wanted = 'repo:${owner.toLowerCase()}/${repo.toLowerCase()}';
  var named = false;
  for (final term in q.split(RegExp(r'\s+'))) {
    final lower = term.toLowerCase();
    if (lower.startsWith('repo:') ||
        lower.startsWith('org:') ||
        lower.startsWith('user:')) {
      if (lower != wanted) {
        return false;
      }
      named = true;
    }
  }
  return named;
}

/// Why a client confined to [owner]/[repo] (`GitHubClients.forRepo`) must
/// not send this request, or null: REST about another repository, a write no
/// one-repository scope covers, or anything that is neither about this
/// repository, GraphQL, nor a search confined to it.
String? refuseGitHubRequestOutsideRepo(
  String owner,
  String repo,
  String method,
  String url,
) {
  final target = githubScopeForRequest(method, url);
  if (target != null) {
    if (target.owner.toLowerCase() != owner.toLowerCase() ||
        target.repo.toLowerCase() != repo.toLowerCase()) {
      return 'This client only reaches $owner/$repo.';
    }
    return target.scope == null
        ? 'No single-repository GitHub token covers $method $url.'
        : null;
  }
  if (isGitHubGraphQlRequest(method, url) ||
      isGitHubRepoSearch(owner, repo, method, url)) {
    return null;
  }
  return 'This client only reaches $owner/$repo.';
}

/// Why a [owner]/[repo] client (`GitHubClients.forRepo`, and the person's
/// one-repository lane beside it) must not send this request, or null: an
/// approval ([refuseAutomatedGitHubApproval]), anything outside this
/// repository ([refuseGitHubRequestOutsideRepo]), or a GraphQL document
/// [githubGraphQlScope] refuses (a mutation not on its allowlist, a
/// subscription, a document it cannot read).
String? refuseGitHubRepoClientRequest(
  String owner,
  String repo,
  String method,
  String url,
  Object? body,
) =>
    refuseAutomatedGitHubApproval(method, url, body) ??
    refuseGitHubRequestOutsideRepo(owner, repo, method, url) ??
    (isGitHubGraphQlRequest(method, url)
        ? githubGraphQlScope(body).refusal
        : null);
