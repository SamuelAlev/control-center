import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';

/// Default broker that hands the environment's GitHub token to a launch.
///
/// The token is injected as both `GH_TOKEN` and `GITHUB_TOKEN` whatever the
/// [ForgeTokenScope]: one server-wide token cannot be narrowed, which is the
/// reason `GitHubFineGrainedTokenBroker` exists. With this broker the push
/// rule is enforced for `git push` (the agent run gateway) but not for code
/// that uses the token directly.
class EnvCredentialBroker implements CredentialBrokerPort {
  /// Creates an [EnvCredentialBroker] backed by the given `credentials` repo.
  EnvCredentialBroker(this._credentials);

  final CredentialsRepository _credentials;

  // Track active grants so revoke is observable, even though env-only grants
  // don't actually need network revocation.
  final Set<String> _active = <String>{};

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    // Ignored here, and that is the point of this broker: it hands out ONE
    // server-wide token from the environment, so it cannot narrow anything to a
    // person. Anything that needs a per-member boundary must run on
    // `GitHubFineGrainedTokenBroker` instead.
    String? actingUserId,
    String? workspaceId,
  }) async {
    final creds = await _credentials.loadCredentials();
    final env = <String, String>{};
    final notes = <String>[];

    if (creds.githubToken.isNotEmpty) {
      env['GH_TOKEN'] = creds.githubToken;
      env['GITHUB_TOKEN'] = creds.githubToken;
      notes.add(
        'Using raw GitHub PAT — swap in fine-grained tokens via '
        'GitHubFineGrainedTokenBroker for production deployments.',
      );
    }

    final handle = '$conversationId-${DateTime.now().millisecondsSinceEpoch}';
    _active.add(handle);
    return ScopedCredentials(handle: handle, environment: env, notes: notes);
  }

  @override
  Future<void> revoke(String handle) async {
    _active.remove(handle);
  }
}
