import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/sandboxing/env_credential_broker.dart' show EnvCredentialBroker;

/// Broker that mints **fine-grained, repo-scoped, time-limited** GitHub
/// tokens per sandbox launch instead of handing the user's raw PAT down.
///
/// Status: scaffolding only. Today this falls back to the user's raw PAT
/// — the same as [EnvCredentialBroker] — until we wire the GitHub Apps
/// installation-token mint endpoint. Surface in settings as
/// "Strong (per-launch token)" once enabled.
class GitHubFineGrainedTokenBroker implements CredentialBrokerPort {
  /// Creates a [GitHubFineGrainedTokenBroker].
  GitHubFineGrainedTokenBroker(this._credentials);

  final CredentialsRepository _credentials;

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

    if (capabilities.canCallGitHubApi || capabilities.canPushToRepo) {
      // TODO: replace with GitHub Apps installation-token mint:
      //   POST /repos/{owner}/{repo}/installation-token with restricted perms,
      //   1h TTL, contents:write only when canPushToRepo is set.
      if (creds.githubToken.isNotEmpty) {
        env['GH_TOKEN'] = creds.githubToken;
        env['GITHUB_TOKEN'] = creds.githubToken;
        notes.add(
          'Fallback: passing raw PAT until fine-grained installation tokens '
          'are wired in.',
        );
      }
    }

    if (capabilities.canCallTicketing && creds.ticketingApiKey.isNotEmpty) {
      env['TICKETING_API_KEY'] = creds.ticketingApiKey;
    }

    final handle = 'fg-$conversationId-'
        '${DateTime.now().millisecondsSinceEpoch}';
    _active.add(handle);

    return ScopedCredentials(
      handle: handle,
      environment: env,
      // 1h target lifetime when fine-grained tokens are real.
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      notes: notes,
    );
  }

  @override
  Future<void> revoke(String handle) async {
    _active.remove(handle);
    // TODO: when fine-grained: call DELETE /installation/token to invalidate.
  }
}
