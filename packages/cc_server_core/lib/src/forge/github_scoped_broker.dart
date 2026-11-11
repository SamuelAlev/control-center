import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';

/// What a run that names no linked GitHub repository is told.
const String _noRepositoryNote =
    'No forge token: this run is not tied to one linked GitHub repository. '
    'GitLab and Bitbucket runs hold no forge credential; they publish through '
    'stack_publish.';

/// [CredentialBrokerPort] on top of [GitHubClients.mintScoped]: every token a
/// sandbox, rig or gateway receives is for exactly one repository and is
/// bounded by the accountable human.
///
/// [ForgeTokenScope.read] is `read`, whoever the human is.
/// [ForgeTokenScope.review] is what an agent run reads with: `review`, which
/// only reads (code, pull requests, issues, CI). The agent run gateway asks
/// for it when the run's git or `gh` does, for a repository the run works
/// on. Agents comment through the server (`comment_on_pull_request`, as the
/// bot) and open pull requests through it (`open_pull_request`). It is
/// minted for the one run and revoked upstream when the run ends
/// ([revoke]), never shared with another run.
/// [ForgeTokenScope.write] asks for `write` and is only requested by
/// whatever applies the push rule; without a person (`personal`) it is the
/// bot's, minted per request and revoked with the handle too. A
/// `personal` mint (a person's terminal, a requested agent push) is their
/// own sign-in narrowed to the repository, shared through the grant cache
/// (GitHub caps how many a person may hold). There is no fallback: a refused
/// mint leaves the environment without a token and says why in the notes.
class GitHubScopedCredentialBroker implements CredentialBrokerPort {
  /// Creates the broker.
  GitHubScopedCredentialBroker(this._clients, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GitHubClients _clients;
  final DateTime Function() _now;
  final Map<String, GitHubScopedGrant> _handles = {};

  /// Handles whose grant is this run's own ([GitHubClients.mintScoped]
  /// `fresh`): revoked upstream on [revoke].
  final Set<String> _own = {};

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  }) async {
    final handle = 'gh-$conversationId-${_now().microsecondsSinceEpoch}';
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        repoOwner == null ||
        repoOwner.isEmpty ||
        repoName == null ||
        repoName.isEmpty) {
      return ScopedCredentials(
        handle: handle,
        environment: const {},
        notes: const [_noRepositoryNote],
      );
    }
    final requested = switch (scope) {
      ForgeTokenScope.read => GitHubTokenScope.read,
      ForgeTokenScope.review => GitHubTokenScope.review,
      ForgeTokenScope.write => GitHubTokenScope.write,
    };
    final own =
        !personal &&
        (requested == GitHubTokenScope.review ||
            requested == GitHubTokenScope.write);
    final GitHubScopedGrant grant;
    try {
      grant = await _clients.mintScoped(
        workspaceId: workspaceId,
        owner: repoOwner,
        repo: repoName,
        scope: requested,
        actingUserId: actingUserId,
        viaPerson: personal,
        fresh: own,
      );
    } on GitHubScopeRefused catch (e) {
      return _refused(handle, repoOwner, repoName, e);
    }
    _handles[handle] = grant;
    if (own) {
      _own.add(handle);
    }
    return ScopedCredentials(
      handle: handle,
      environment: {'GH_TOKEN': grant.token, 'GITHUB_TOKEN': grant.token},
      expiresAt: grant.expiresAt,
      notes: [
        'GitHub token for $repoOwner/$repoName only (${grant.scope.wire}, via ${grant.lane.wire}).',
      ],
    );
  }

  ScopedCredentials _refused(
    String handle,
    String owner,
    String repo,
    GitHubScopeRefused e,
  ) => ScopedCredentials(
    handle: handle,
    environment: const {},
    notes: ['No GitHub token for $owner/$repo: ${e.message}'],
  );

  /// A run's own token (a sandbox's, a bot push's) is revoked upstream
  /// (`DELETE /installation/token`, or through Connect for a person's child)
  /// so it dies with the run instead of living out its hour. A shared one
  /// (`read`, a person's own narrowed token) only forgets the handle;
  /// sign-out and member removal revoke those through
  /// [GitHubClients.forgetPerson].
  @override
  Future<void> revoke(String handle) async {
    final grant = _handles.remove(handle);
    if (grant != null && _own.remove(handle)) {
      await _clients.revokeGrant(grant);
    }
  }
}
