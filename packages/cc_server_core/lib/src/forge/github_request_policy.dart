/// What an automation request to GitHub may carry, decided from its method,
/// URL and body alone: the one-repository scope it needs, and the requests
/// automation must never send at all.
library;

import 'package:cc_connect_core/cc_connect_core.dart'
    show GitHubTokenScope, isGitHubSegment;

/// Why a request must not be sent on an automation client, or null.
///
/// A `/repos/{o}/{r}/…` write that no one-repository scope covers is
/// refused. Anything else rides a person's whole sign-in, so unless that
/// person is the one acting ([personActing]) only reads pass: `GET`/`HEAD`
/// and GraphQL queries. GraphQL mutations and other writes are refused.
String? refuseUnscopedGitHubWrite(
  String method,
  String url,
  Object? body, {
  required bool personActing,
}) {
  final target = githubScopeForRequest(method, url);
  if (target != null) {
    return target.scope == null
        ? 'No single-repository GitHub token covers $method $url.'
        : null;
  }
  if (personActing) {
    return null;
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

/// Whether a GraphQL request body may change anything. Unreadable bodies
/// count as writes.
bool isGraphQlWrite(Object? body) {
  final query = body is Map ? body['query'] : null;
  if (query is! String) {
    return true;
  }
  final code = query
      .replaceAll(RegExp(r'"""[\s\S]*?"""'), '""')
      .replaceAll(RegExp(r'"(?:[^"\\]|\\.)*"'), '""')
      .replaceAll(RegExp('#[^\n]*'), '');
  return RegExp(r'\b(mutation|subscription)\b').hasMatch(code);
}

/// Why an automation request must not be sent, or null: a pull request
/// review (`POST /repos/{o}/{r}/pulls/{n}/reviews`, or submitting a pending
/// one at `.../reviews/{id}/events`) or a GraphQL review mutation whose
/// event is `APPROVE`. Comments and change requests pass.
String? refuseAutomatedGitHubApproval(String method, String url, Object? body) {
  if (method.toUpperCase() != 'POST') {
    return null;
  }
  final segments = (Uri.tryParse(url)?.pathSegments ?? const <String>[])
      .where((s) => s.isNotEmpty)
      .toList();
  const refusal =
      'Automation never approves a pull request; a person approves from '
      'their own account.';
  if (segments.length == 1 && segments.single == 'graphql') {
    final query = body is Map ? body['query'] : null;
    final variables = body is Map ? body['variables'] : null;
    final isReviewMutation =
        query is String && query.toLowerCase().contains('pullrequestreview');
    final approves =
        (query is String &&
            RegExp(r'\bAPPROVE\b', caseSensitive: false).hasMatch(query)) ||
        _anyApprove(variables);
    return isReviewMutation && approves ? refusal : null;
  }
  final isReview =
      segments.length >= 6 &&
      segments[0] == 'repos' &&
      segments[3] == 'pulls' &&
      segments[5] == 'reviews' &&
      (segments.length == 6 ||
          (segments.length == 8 && segments[7] == 'events'));
  final event = body is Map ? body['event'] : null;
  return isReview && event is String && event.toUpperCase() == 'APPROVE'
      ? refusal
      : null;
}

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
/// issues and PR conversation `bot`, code and pull requests `write`. Any
/// other `/repos/{o}/{r}` write (statuses, checks, actions, settings…), or
/// a malformed repository path, answers a null scope: no token.
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
  switch (rest.first) {
    case 'issues':
      return GitHubTokenScope.bot;
    case 'pulls':
      const conversation = {
        'comments',
        'reviews',
        'reactions',
        'labels',
        'assignees',
        'requested_reviewers',
      };
      if (rest.contains('merge') || rest.contains('update-branch')) {
        return GitHubTokenScope.write;
      }
      return rest.length == 1 || rest.any(conversation.contains)
          ? GitHubTokenScope.bot
          : GitHubTokenScope.write;
    case 'contents' || 'git' || 'merges' || 'stacks':
      return GitHubTokenScope.write;
    default:
      return null;
  }
}
