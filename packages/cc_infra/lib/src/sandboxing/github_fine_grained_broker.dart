import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github/github_app_client.dart';

/// Broker that mints **fine-grained, repo-scoped, time-limited** GitHub tokens
/// per sandbox launch instead of handing the user's raw PAT down (FINDINGS
/// §1.1/1.2).
///
/// When the server has a GitHub App, a GitHub-API/push
/// capability mints a scoped **installation access token** limited to the run's
/// repo, with `contents:write` only when the run may push. Without an app — or
/// on any mint failure — it falls back to the user's PAT, so it is never worse
/// than the plain `EnvCredentialBroker`. Surfaced as "Strong (per-launch
/// token)".
///
/// The installation is resolved from the run's **repo owner**, per launch.
/// There used to be one `GITHUB_APP_INSTALLATION_ID` for the whole server,
/// which cannot be right: an app is installed per account, and which account
/// matters is only known once a repo is picked — so a host whose agents touched
/// two orgs minted against whichever one was pinned.
class GitHubFineGrainedTokenBroker implements CredentialBrokerPort {
  /// Creates a [GitHubFineGrainedTokenBroker].
  ///
  /// [app] resolves the server's GitHub App at mint time rather than at
  /// construction, so an operator who configures (or changes) it in Settings
  /// does not have to restart for the next run to use it. Returning null there
  /// means "no app", and every launch falls back to the PAT.
  ///
  /// [serverOwnerUserId] identifies the operator. It exists so the raw-PAT
  /// fallback can be withheld from a run acting for somebody ELSE: that PAT is
  /// the SERVER's credential, so handing it to a member's run would give them
  /// the server's whole reach rather than access bounded by their own.
  GitHubFineGrainedTokenBroker(
    this._credentials, {
    Future<GitHubAppClient?> Function()? app,
    Future<String?> Function()? serverOwnerUserId,
  }) : _app = app,
       _serverOwnerUserId = serverOwnerUserId;

  final CredentialsRepository _credentials;
  final Future<GitHubAppClient?> Function()? _app;
  final Future<String?> Function()? _serverOwnerUserId;

  final Set<String> _active = <String>{};

  /// handle → minted installation token, so [revoke] can invalidate it.
  final Map<String, String> _minted = <String, String>{};

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
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
      final client = await _app?.call();
      var minted = false;
      // Both halves are required: the OWNER picks the installation, the NAME
      // scopes the token to one repository inside it.
      if (client != null &&
          repoOwner != null &&
          repoOwner.isNotEmpty &&
          repoName != null &&
          repoName.isNotEmpty) {
        try {
          final tok = await client.mintScopedForOwner(
            repoOwner,
            repositories: [repoName],
            permissions: {
              'metadata': 'read',
              'contents': push ? 'write' : 'read',
              if (push) 'pull_requests': 'write',
            },
          );
          if (tok != null) {
            env['GH_TOKEN'] = tok.token;
            env['GITHUB_TOKEN'] = tok.token;
            _minted[handle] = tok.token;
            expiresAt = tok.expiresAt ?? expiresAt;
            notes.add(
              'Minted a fine-grained, repo-scoped GitHub App installation '
              'token (${push ? 'contents:write' : 'contents:read'}) for '
              '$repoOwner/$repoName.',
            );
            minted = true;
          } else {
            CcInfraLog.warning(
              'No GitHub App installation for $repoOwner; falling back to PAT.',
            );
          }
        } on Object catch (e) {
          CcInfraLog.warning(
            'Fine-grained GitHub token mint failed for $repoOwner/$repoName; '
            'falling back to PAT: $e',
          );
        }
      }
      if (!minted && creds.githubToken.isNotEmpty) {
        // The raw PAT is the SERVER's credential, not this member's.
        //
        // Falling back to it for a run acting on someone else's behalf would
        // hand them the server's whole reach whenever that member simply has
        // not connected GitHub. A run with no acting user (a webhook, a
        // reconciler) is the server acting as itself and keeps the fallback,
        // as does the operator running their own server.
        final ownerId = await _serverOwnerUserId?.call();
        final actsForSomeoneElse =
            actingUserId != null &&
            actingUserId.isNotEmpty &&
            (ownerId == null || ownerId.isEmpty || ownerId != actingUserId);
        if (actsForSomeoneElse) {
          notes.add(
            'No GitHub credential for this run: it is acting for a member who '
            'has not connected GitHub, and this server\'s own token is not '
            'theirs to use. Ask them to sign in to GitHub in Settings.',
          );
          CcInfraLog.warning(
            'Withholding the server PAT from a run acting for $actingUserId; '
            'that member has no GitHub credential of their own.',
          );
        } else {
          env['GH_TOKEN'] = creds.githubToken;
          env['GITHUB_TOKEN'] = creds.githubToken;
          notes.add(
            client == null
                ? 'Fallback: raw PAT (no GitHub App configured).'
                : 'Fallback: raw PAT (installation-token mint unavailable).',
          );
        }
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
    if (token == null) {
      return;
    }
    final client = await _app?.call();
    if (client == null) {
      return;
    }
    try {
      // Authenticated with the token itself, so no installation is named —
      // which is why revocation needs nothing the mint did not already have.
      await client.revokeToken(token);
    } on Object catch (e) {
      // Best-effort: the token expires on its own (~1h) regardless.
      CcInfraLog.warning('Fine-grained token revoke failed for $handle: $e');
    }
  }
}
