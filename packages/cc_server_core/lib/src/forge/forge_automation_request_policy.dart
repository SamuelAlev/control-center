/// What a GitLab or Bitbucket automation request may carry: the request
/// guard every automation client is built with.
///
/// A project or group access token (GitLab), or a repository, project or
/// workspace access token (Bitbucket), often reaches more than the one
/// linked repository it was saved for. An automation client is built for one
/// repository, so a request about any other is refused before it is sent,
/// and so is an approval: approving is a person's act, made from their own
/// account. A person's own client is not guarded here: a person may approve.
library;

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';

/// Why an automation request for [owner]/[name] on [forge] must not be
/// sent, or null. Recorded as `forge.request.refused` when it is refused.
String? refuseForgeAutomationRequest(
  ForgeHost forge,
  String owner,
  String name,
  String method,
  String url, {
  String? workspaceId,
}) {
  final reason = switch (forge) {
    ForgeHost.gitlab => _gitlab('$owner/$name', method, url),
    ForgeHost.bitbucket => _bitbucket(owner, name, method, url),
    ForgeHost.github || ForgeHost.local => null,
  };
  if (reason != null) {
    forgeAudit(ForgeAuditEvent.forgeRequestRefused, {
      'forge': forge.wire,
      'workspace_id': workspaceId,
      'repo': '$owner/$name',
      'rule': reason.rule,
      'method': method.toUpperCase(),
      'path': forgeRequestPathTemplate(url),
    });
  }
  return reason?.message;
}

/// [url]'s path without its query, numeric segments as `{n}`: what a log
/// line names a request by.
String forgeRequestPathTemplate(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return '';
  }
  return '/${[for (final s in uri.pathSegments)
    if (s.isNotEmpty) RegExp(r'^\d+$').hasMatch(s) ? '{n}' : s].join('/')}';
}

typedef _Refusal = ({String rule, String message});

const _approval = (
  rule: 'automated_approval',
  message:
      'Automation never approves a merge or pull request; a person approves '
      'from their own account.',
);

/// The few requests not about one repository an automation client makes:
/// who the token is, and looking a person up by name. Reads only.
bool _identityRead(
  String method,
  List<String> segments, {
  required bool gitlab,
}) =>
    method.toUpperCase() == 'GET' &&
    segments.length == 1 &&
    (segments.single == 'user' || (gitlab && segments.single == 'users'));

_Refusal? _gitlab(String project, String method, String url) {
  final segments = _segments(url);
  if (segments == null) {
    return (
      rule: 'unreadable_url',
      message: 'This request has no readable path.',
    );
  }
  if (_identityRead(method, segments, gitlab: true)) {
    return null;
  }
  if (segments.length < 2 ||
      segments[0] != 'projects' ||
      segments[1].toLowerCase() != project.toLowerCase()) {
    return (
      rule: 'outside_repository',
      message: 'This automation client only reaches $project.',
    );
  }
  // `/projects/:id/merge_requests/:iid/approve`, and the approvals
  // endpoint's writes (approving, or changing who must approve).
  final writes = method.toUpperCase() != 'GET';
  if (writes &&
      segments.length == 5 &&
      segments[2] == 'merge_requests' &&
      (segments[4] == 'approve' || segments[4] == 'approvals')) {
    return _approval;
  }
  return null;
}

_Refusal? _bitbucket(String workspace, String slug, String method, String url) {
  final segments = _segments(url);
  if (segments == null) {
    return (
      rule: 'unreadable_url',
      message: 'This request has no readable path.',
    );
  }
  if (_identityRead(method, segments, gitlab: false)) {
    return null;
  }
  final ownWorkspaceMembers =
      method.toUpperCase() == 'GET' &&
      segments.length == 3 &&
      segments[0] == 'workspaces' &&
      segments[1].toLowerCase() == workspace.toLowerCase() &&
      segments[2] == 'members';
  if (ownWorkspaceMembers) {
    return null;
  }
  if (segments.length < 3 ||
      segments[0] != 'repositories' ||
      segments[1].toLowerCase() != workspace.toLowerCase() ||
      segments[2].toLowerCase() != slug.toLowerCase()) {
    return (
      rule: 'outside_repository',
      message: 'This automation client only reaches $workspace/$slug.',
    );
  }
  // `POST /repositories/:ws/:slug/pullrequests/:id/approve` (DELETE there
  // withdraws an approval, which is not one).
  if (method.toUpperCase() == 'POST' &&
      segments.length == 6 &&
      segments[3] == 'pullrequests' &&
      segments[5] == 'approve') {
    return _approval;
  }
  return null;
}

/// [url]'s decoded, normalized path segments (dot segments resolved, so a
/// `..` cannot climb out of the repository), without a leading API prefix
/// (`api/v4`, `2.0`) when the URL is absolute; null when it cannot be read.
List<String>? _segments(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return null;
  }
  final segments = [
    for (final s in uri.normalizePath().pathSegments)
      if (s.isNotEmpty) s,
  ];
  if (segments.length >= 2 && segments[0] == 'api' && segments[1] == 'v4') {
    return segments.sublist(2);
  }
  if (segments.isNotEmpty && segments[0] == '2.0') {
    return segments.sublist(1);
  }
  return segments;
}

/// The repository one request on [forge] is about, read from its [url]
/// (`/repos/{owner}/{name}` on GitHub, `/projects/{path}` on GitLab,
/// `/repositories/{workspace}/{slug}` on Bitbucket) or, for a GitHub GraphQL
/// request, from its `owner` and `name` (or `repo`) variables. Null when the
/// request names none this way (who the token is, a search, a project named
/// by its numeric id).
({String owner, String name})? forgeRequestRepo(
  ForgeHost forge,
  String url,
  Object? jsonBody,
) {
  final segments = _segments(url);
  if (segments == null) {
    return null;
  }
  switch (forge) {
    case ForgeHost.github:
      if (segments.length >= 3 && segments[0] == 'repos') {
        return (owner: segments[1], name: segments[2]);
      }
      final variables = jsonBody is Map ? jsonBody['variables'] : null;
      if (segments.length == 1 &&
          segments.single == 'graphql' &&
          variables is Map) {
        final owner = variables['owner'];
        final name = variables['name'] ?? variables['repo'];
        if (owner is String &&
            owner.isNotEmpty &&
            name is String &&
            name.isNotEmpty) {
          return (owner: owner, name: name);
        }
      }
      return null;
    case ForgeHost.gitlab:
      if (segments.length < 2 || segments[0] != 'projects') {
        return null;
      }
      final project = segments[1];
      final cut = project.lastIndexOf('/');
      return cut <= 0 || cut == project.length - 1
          ? null
          : (owner: project.substring(0, cut), name: project.substring(cut + 1));
    case ForgeHost.bitbucket:
      return segments.length >= 3 && segments[0] == 'repositories'
          ? (owner: segments[1], name: segments[2])
          : null;
    case ForgeHost.local:
      return null;
  }
}
