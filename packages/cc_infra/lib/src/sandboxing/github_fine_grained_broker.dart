import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github/github_app_client.dart';

/// Mints fine-grained, repo-scoped, time-limited GitHub tokens per sandbox
/// launch (avoids handing the raw PAT down).
///
/// With a GitHub App: an installation token for the run's repo. A
/// [ForgeTokenScope.read] token (the one an agent's environment carries) reads
/// contents and works with pull requests but cannot push; a
/// [ForgeTokenScope.write] token can, and only the agent run gateway asks for
/// one. Else / on mint failure: the workspace or server PAT, which cannot be
/// narrowed — the push rule is then only as strong as the agent's restraint,
/// and the notes say so. Installation resolved from repo owner per launch —
/// not a single server-wide installation id.
class GitHubFineGrainedTokenBroker implements CredentialBrokerPort {
  /// Creates a [GitHubFineGrainedTokenBroker].
  ///
  /// [_app] resolves the server's GitHub App at mint time rather than at
  /// construction, so an operator who configures (or changes) it in Settings
  /// does not have to restart for the next run to use it. Returning null there
  /// means "no app", and every launch falls back to the PAT.
  ///
  /// [_serverOwnerUserId] identifies the operator. It exists so the raw-PAT
  /// fallback can be withheld from a run acting for somebody ELSE: that PAT is
  /// the SERVER's credential, so handing it to a member's run would give them
  /// the server's whole reach rather than access bounded by their own.
  GitHubFineGrainedTokenBroker(
    this._credentials, {
    this._app,
    this._serverOwnerUserId,
    this._workspacePat,
  });

  final CredentialsRepository _credentials;
  final Future<GitHubAppClient?> Function({String? workspaceId})? _app;
  final Future<String?> Function()? _serverOwnerUserId;

  /// Workspace background PAT. Allowed as the fallback for member-driven
  /// runs in that workspace; the install owner's personal PAT is not.
  final Future<String?> Function(String workspaceId)? _workspacePat;

  final Set<String> _active = <String>{};

  /// handle → minted installation token, so [revoke] can invalidate it.
  final Map<String, String> _minted = <String, String>{};

  /// Appended to a fallback note: a PAT cannot be narrowed to read-only, so
  /// one in an agent's environment could push around the gateway.
  static const String _unscopedNote =
      ' A PAT cannot be narrowed to read-only, so the push rule is advisory '
      'for code that uses it directly; configure the GitHub App to enforce it.';

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async {
    final creds = await _credentials.loadCredentials();
    final env = <String, String>{};
    final notes = <String>[];
    final handle =
        'fg-$conversationId-'
        '${DateTime.now().millisecondsSinceEpoch}';
    var expiresAt = DateTime.now().add(const Duration(hours: 1));

    final push = scope == ForgeTokenScope.write;
    final client = await _app?.call(workspaceId: workspaceId);
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
            // Opening and commenting on a PR is the action policy's call
            // ("Open a pull request", "Publish a review or merge"), asked by
            // the shell classifier; the token only has to be able to do it.
            if (!push) 'pull_requests': 'write',
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
    if (!minted) {
      final workspacePat = workspaceId == null || workspaceId.isEmpty
          ? null
          : await _workspacePat?.call(workspaceId);
      if (workspacePat != null && workspacePat.isNotEmpty) {
        env['GH_TOKEN'] = workspacePat;
        env['GITHUB_TOKEN'] = workspacePat;
        notes.add(
          'Fallback: workspace background PAT (installation-token mint '
          'unavailable).$_unscopedNote',
        );
      } else if (creds.githubToken.isNotEmpty) {
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
          final fallback = client == null
              ? 'Fallback: raw PAT (no GitHub App configured).'
              : 'Fallback: raw PAT (installation-token mint unavailable).';
          notes.add('$fallback$_unscopedNote');
        }
      }
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
