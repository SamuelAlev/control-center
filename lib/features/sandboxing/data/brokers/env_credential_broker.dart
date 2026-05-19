
import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/features/auth/domain/repositories/credentials_repository.dart';

/// Default broker that maps capabilities → env vars.
///
/// * GitHub PAT is injected as both `GH_TOKEN` and `GITHUB_TOKEN` when the
///   user has granted [AgentCapabilities.canCallGitHubApi] *or*
///   [AgentCapabilities.canPushToRepo]. Pushes piggyback on the same token
///   today — a fine-grained broker can replace this without changing the
///   port shape (see `GitHubFineGrainedTokenBroker`).
/// * Ticketing key → `TICKETING_API_KEY` when
///   [AgentCapabilities.canCallTicketing] and a remote provider key is set.
///   The raw key flows through; the note is surfaced in the UI.
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
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) async {
    final creds = await _credentials.loadCredentials();
    final env = <String, String>{};
    final notes = <String>[];

    if ((capabilities.canCallGitHubApi || capabilities.canPushToRepo) &&
        creds.githubToken.isNotEmpty) {
      env['GH_TOKEN'] = creds.githubToken;
      env['GITHUB_TOKEN'] = creds.githubToken;
      if (capabilities.canPushToRepo) {
        notes.add(
          'Using raw GitHub PAT — swap in fine-grained tokens via '
          'GitHubFineGrainedTokenBroker for production deployments.',
        );
      }
    }
    if (capabilities.canCallTicketing && creds.ticketingApiKey.isNotEmpty) {
      env['TICKETING_API_KEY'] = creds.ticketingApiKey;
      notes.add(
        'The ticketing provider API key is injected into the sandbox env.',
      );
    }

    final handle = '$conversationId-${DateTime.now().millisecondsSinceEpoch}';
    _active.add(handle);
    return ScopedCredentials(
      handle: handle,
      environment: env,
      notes: notes,
    );
  }

  @override
  Future<void> revoke(String handle) async {
    _active.remove(handle);
  }
}
