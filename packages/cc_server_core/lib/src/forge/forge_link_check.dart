/// Whether a person's own GitLab or Bitbucket token can read one linked
/// repository (link verification of the member linking it), and the shared
/// repository probe the automation-token checks use too.
library;

import 'package:cc_domain/core/domain/entities/repo.dart'
    show splitRepoFullName;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_probe.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart'
    show ForgeRepoIdentity;
import 'package:cc_server_core/src/forge/repo_access_registry.dart';

/// Reads [owner]/[name] on [forge] with [token] and answers the HTTP status,
/// or null when the forge could not be reached. A 403 that is a rate limit
/// answers 429: it says nothing about who can see the repository.
typedef ForgeRepoProbe =
    Future<int?> Function(
      ForgeHost forge,
      String token,
      String owner,
      String name,
    );

/// What the forge answered for one repository read: the HTTP status (null
/// when it was not reached; a rate-limited 403 is 429), and on a 200 the
/// repository as the forge names it.
typedef ForgeRepoAnswer = ({int? status, ForgeRepoIdentity? repo});

/// Reads [owner]/[name] on [forge] with [token] ([readForgeRepo]).
typedef ForgeRepoRead =
    Future<ForgeRepoAnswer> Function(
      ForgeHost forge,
      String token,
      String owner,
      String name,
    );

/// The token-only forges' link check, on the linking member's own pasted
/// token. There is no server-owner or environment token behind it; what
/// automation will meet there is the automation token's check
/// (`ForgeAutomationTokens.check`).
final class ForgeLinkChecker {
  /// Creates the checker. [read] defaults to [readForgeRepo].
  ForgeLinkChecker({
    required this._credentials,
    ForgeRepoRead? read,
    DateTime Function()? now,
  }) : _read = read ?? readForgeRepo,
       _now = now ?? DateTime.now;

  final ForgeCredentials _credentials;
  final ForgeRepoRead _read;
  final DateTime Function() _now;

  /// Checks [owner]/[name] on [forge] with [userId]'s own token in
  /// [workspaceId]: no issue when it can read the repository, else why not;
  /// and the forge's durable id for it as that read saw it (empty unless it
  /// was read).
  Future<({RepoAccessIssue? issue, String forgeRepoId})> check(
    String workspaceId,
    ForgeHost forge,
    String owner,
    String name, {
    String? userId,
  }) async {
    final now = _now();
    RepoAccessIssue issue(RepoAccessState state, String message) =>
        RepoAccessIssue(
          forge: forge,
          owner: owner,
          name: name,
          state: state,
          since: now,
          checkedAt: now,
          message: message,
        );
    final token = userId == null || userId.isEmpty
        ? null
        : await _credentials.personToken(
            forge,
            userId,
            workspaceId: workspaceId,
          );
    if (token == null || token.isEmpty) {
      return (
        issue: issue(
          RepoAccessState.ownerNotSignedIn,
          'Add your ${forge.displayName} token to link $owner/$name.',
        ),
        forgeRepoId: '',
      );
    }
    final answer = await _read(forge, token, owner, name);
    final read = answer.repo;
    if (answer.status == 200 && read != null) {
      return (issue: null, forgeRepoId: read.id);
    }
    final found = switch (answer.status) {
      401 => issue(
        RepoAccessState.ownerNotSignedIn,
        'You have a ${forge.displayName} token ${forge.displayName} no '
        'longer accepts.',
      ),
      // 404 is how both forges hide a repository the token cannot see; a
      // 403 here is a refusal, never a rate limit (the probe answers those
      // as 429, which is transient below).
      403 || 404 => issue(
        RepoAccessState.ownerCannotSee,
        'You cannot see $owner/$name on ${forge.displayName}.',
      ),
      _ => issue(
        RepoAccessState.transient,
        '${forge.displayName} could not be reached to check $owner/$name.',
      ),
    };
    return (issue: found, forgeRepoId: '');
  }
}

/// Records [issue] for [owner]/[name] in [registry], or that the repository
/// is reachable when it is null. A transient answer never overwrites a
/// blocking record.
Future<void> recordForgeLinkCheck(
  RepoAccessRegistry registry,
  String workspaceId,
  ForgeHost forge,
  String owner,
  String name,
  RepoAccessIssue? issue, {
  String? repoId,
}) async {
  if (issue == null) {
    await registry.recordReachable(
      workspaceId,
      forge: forge,
      owner: owner,
      name: name,
    );
    return;
  }
  if (!issue.state.blocksAutomation) {
    final current = await registry.issueFor(
      workspaceId,
      forge: forge,
      owner: owner,
      name: name,
    );
    if (current != null && current.state.blocksAutomation) {
      return;
    }
  }
  await registry.record(
    workspaceId,
    forge: forge,
    owner: owner,
    name: name,
    state: issue.state,
    repoId: repoId,
    message: issue.message,
  );
}

/// The default [ForgeRepoProbe]: the status of [readForgeRepo].
Future<int?> probeForgeRepo(
  ForgeHost forge,
  String token,
  String owner,
  String name,
) async => (await readForgeRepo(forge, token, owner, name)).status;

/// The default [ForgeRepoRead]: GitLab `GET /projects/:url-encoded-path`
/// (the project's `id` and `path_with_namespace`; GitLab answers a moved
/// project's old path with the project), Bitbucket `GET
/// /2.0/repositories/{workspace}/{slug}` (its `uuid` and `full_name`),
/// GitHub `GET /repos/{owner}/{name}` (its `id` and `full_name`, for a
/// person's own request; automation reads it in `GitHubMinter.repoFacts`),
/// through [forgeGet] (a Bitbucket `email:token` API token as basic auth, an
/// access token as bearer). A 200 without a readable id and path has no
/// repository.
Future<ForgeRepoAnswer> readForgeRepo(
  ForgeHost forge,
  String token,
  String owner,
  String name,
) async {
  final path = switch (forge) {
    ForgeHost.gitlab => '/projects/${Uri.encodeComponent('$owner/$name')}',
    ForgeHost.bitbucket =>
      '/repositories/${Uri.encodeComponent(owner)}/'
          '${Uri.encodeComponent(name)}',
    ForgeHost.github =>
      '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(name)}',
    ForgeHost.local => null,
  };
  if (path == null) {
    return (status: null, repo: null);
  }
  final answer = await forgeGet(forge, token, path);
  if (answer.status == 403 &&
      isRateLimitedRefusal(answer.header, answer.body)) {
    return (status: 429, repo: null);
  }
  final json = answer.json;
  if (answer.status != 200 || json is! Map) {
    return (status: answer.status, repo: null);
  }
  final (id, fullName) = switch (forge) {
    ForgeHost.gitlab => (json['id'], json['path_with_namespace']),
    ForgeHost.github => (json['id'], json['full_name']),
    _ => (json['uuid'], json['full_name']),
  };
  final split = fullName is String ? splitRepoFullName(fullName) : null;
  final known = id is int || (id is String && id.isNotEmpty);
  return (
    status: answer.status,
    repo: split == null || !known
        ? null
        : (id: '$id', owner: split.owner, name: split.name),
  );
}

/// Whether a 403 is a rate limit rather than a refusal: a zero remaining
/// budget (`x-ratelimit-remaining`, GitLab's `ratelimit-remaining`), a
/// `retry-after`, or a body about a rate limit or abuse detection.
bool isRateLimitedRefusal(String? Function(String name) header, String body) {
  final lower = body.toLowerCase();
  return header('x-ratelimit-remaining')?.trim() == '0' ||
      header('ratelimit-remaining')?.trim() == '0' ||
      header('retry-after') != null ||
      lower.contains('rate limit') ||
      lower.contains('abuse');
}
