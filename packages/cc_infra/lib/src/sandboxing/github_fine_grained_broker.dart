import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/sandboxing/github_app_token_minter.dart';

/// Broker that mints **fine-grained, repo-scoped, time-limited** GitHub tokens
/// per sandbox launch instead of handing the user's raw PAT down (FINDINGS
/// §1.1/1.2).
///
/// When a [GitHubAppTokenMinter] is supplied (the operator registered a GitHub
/// App and configured its credentials), a GitHub-API/push capability mints a
/// scoped **installation access token** limited to the run's repo, with
/// `contents:write` only when the run may push. Without a minter — or on any
/// mint failure — it falls back to the user's PAT, so it is never worse than
/// the plain `EnvCredentialBroker`. Surfaced as "Strong (per-launch token)".
class GitHubFineGrainedTokenBroker implements CredentialBrokerPort {
  /// Creates a [GitHubFineGrainedTokenBroker]. Pass a [minter] to enable real
  /// per-launch installation tokens; omit it to always fall back to the PAT.
  GitHubFineGrainedTokenBroker(
    this._credentials, {
    GitHubAppTokenMinter? minter,
  }) : _minter = minter;

  final CredentialsRepository _credentials;
  final GitHubAppTokenMinter? _minter;

  final Set<String> _active = <String>{};

  /// handle → minted installation token, so [revoke] can invalidate it.
  final Map<String, String> _minted = <String, String>{};

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
    final handle =
        'fg-$conversationId-'
        '${DateTime.now().millisecondsSinceEpoch}';
    var expiresAt = DateTime.now().add(const Duration(hours: 1));

    if (capabilities.canCallGitHubApi || capabilities.canPushToRepo) {
      final push = capabilities.canPushToRepo;
      final minter = _minter;
      var minted = false;
      if (minter != null && repoName != null && repoName.isNotEmpty) {
        try {
          final tok = await minter.mint(
            repositories: [repoName],
            permissions: {
              'metadata': 'read',
              'contents': push ? 'write' : 'read',
              if (push) 'pull_requests': 'write',
            },
          );
          env['GH_TOKEN'] = tok.token;
          env['GITHUB_TOKEN'] = tok.token;
          _minted[handle] = tok.token;
          expiresAt = tok.expiresAt ?? expiresAt;
          notes.add(
            'Minted a fine-grained, repo-scoped GitHub App installation token '
            '(${push ? 'contents:write' : 'contents:read'}) for $repoName.',
          );
          minted = true;
        } on Object catch (e) {
          CcInfraLog.warning(
            'Fine-grained GitHub token mint failed for $repoName; '
            'falling back to PAT: $e',
          );
        }
      }
      if (!minted && creds.githubToken.isNotEmpty) {
        env['GH_TOKEN'] = creds.githubToken;
        env['GITHUB_TOKEN'] = creds.githubToken;
        notes.add(
          minter == null
              ? 'Fallback: raw PAT (no GitHub App configured).'
              : 'Fallback: raw PAT (installation-token mint unavailable).',
        );
      }
    }

    if (capabilities.canCallTicketing && creds.ticketingApiKey.isNotEmpty) {
      env['TICKETING_API_KEY'] = creds.ticketingApiKey;
    }

    _active.add(handle);

    return ScopedCredentials(
      handle: handle,
      environment: env,
      expiresAt: expiresAt,
      notes: notes,
    );
  }

  @override
  Future<void> revoke(String handle) async {
    _active.remove(handle);
    final token = _minted.remove(handle);
    final minter = _minter;
    if (token != null && minter != null) {
      try {
        await minter.revoke(token);
      } on Object catch (e) {
        // Best-effort: the token expires on its own (~1h) regardless.
        CcInfraLog.warning('Fine-grained token revoke failed for $handle: $e');
      }
    }
  }
}
