import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';

/// [CredentialBrokerPort] on top of [GitHubClients.mintScoped]: every token a
/// sandbox, rig or gateway receives is for exactly one repository and is
/// bounded by the accountable human.
///
/// [ForgeTokenScope.read] is `read`, whoever the human is.
/// [ForgeTokenScope.review] asks for `review` (read plus PR comments),
/// clamped down to `read` when the human cannot push.
/// [ForgeTokenScope.write] asks for `write` and is only requested by
/// whatever applies the push rule. A
/// `personal` mint (a person's terminal) is their own sign-in narrowed to the
/// repository. There is no fallback: a refused mint leaves the environment
/// without a token and says why in the notes.
class GitHubScopedCredentialBroker implements CredentialBrokerPort {
  /// Creates the broker.
  GitHubScopedCredentialBroker(this._clients, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GitHubClients _clients;
  final DateTime Function() _now;
  final Map<String, GitHubScopedGrant> _handles = {};

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
        notes: const [
          'No GitHub token: this run is not tied to one linked repository.',
        ],
      );
    }
    final requested = switch (scope) {
      ForgeTokenScope.read => GitHubTokenScope.read,
      ForgeTokenScope.review => GitHubTokenScope.review,
      ForgeTokenScope.write => GitHubTokenScope.write,
    };
    final GitHubScopedGrant grant;
    try {
      grant = await _mint(
        workspaceId,
        repoOwner,
        repoName,
        requested,
        actingUserId,
        personal: personal,
      );
    } on GitHubScopeRefused catch (e) {
      return _refused(handle, repoOwner, repoName, e);
    }
    _handles[handle] = grant;
    return ScopedCredentials(
      handle: handle,
      environment: {'GH_TOKEN': grant.token, 'GITHUB_TOKEN': grant.token},
      expiresAt: grant.expiresAt,
      notes: [
        'GitHub token for $repoOwner/$repoName only (${grant.scope.wire}, via ${grant.lane.wire}).',
      ],
    );
  }

  Future<GitHubScopedGrant> _mint(
    String workspaceId,
    String owner,
    String repo,
    GitHubTokenScope scope,
    String? actingUserId, {
    required bool personal,
  }) => _clients.mintScoped(
    workspaceId: workspaceId,
    owner: owner,
    repo: repo,
    scope: scope,
    actingUserId: actingUserId,
    viaPerson: personal,
  );

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

  /// Tokens are cached and shared across runs of the same human and
  /// repository, so a teardown only forgets the handle; sign-out and member
  /// removal revoke through [GitHubClients.forgetPerson].
  @override
  Future<void> revoke(String handle) async {
    _handles.remove(handle);
  }
}
