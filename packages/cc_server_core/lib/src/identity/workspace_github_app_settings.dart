import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/github_auth_mode.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';

/// Per-workspace GitHub App identity (act-as-server + optional sign-in).
///
/// Secrets live in [FileSecretsStore], never in `workspace.db` — exporting a
/// workspace must not leak a private key. [workspaces.github_app_id] on the
/// registry row is the non-secret id; the PEM and OAuth secret stay here.
///
/// [GithubAuthMode.inherit] workspaces share the install App. [GithubAuthMode.pat]
/// workspaces have no App. A missing workspace key in [GithubAuthMode.app]
/// does **not** fall through to the install App.
class WorkspaceGitHubAppSettings {
  /// Creates a [WorkspaceGitHubAppSettings].
  WorkspaceGitHubAppSettings({
    required FileSecretsStore secrets,
    required ProviderAppSettings install,
    GitHubAppClient Function({required String appId, required String pem})?
    githubAppFactory,
  }) : _secrets = secrets,
       _install = install,
       _githubAppFactory = githubAppFactory;

  final FileSecretsStore _secrets;
  final ProviderAppSettings _install;
  final GitHubAppClient Function({required String appId, required String pem})?
  _githubAppFactory;

  /// Cache keyed by `appId:pem.hashCode` so two workspaces sharing one App
  /// (or a save that did not change the key) reuse the client.
  final Map<String, GitHubAppClient> _clients = {};

  /// Secrets-file key for [workspaceId]'s GitHub App private key.
  static String privateKeySecret(String workspaceId) =>
      'workspace_provider_app_github_${workspaceId}_private_key';

  /// Secrets-file key for [workspaceId]'s GitHub OAuth client secret.
  static String clientSecretSecret(String workspaceId) =>
      'workspace_provider_app_github_${workspaceId}_client_secret';

  /// Secrets-file key for [workspaceId]'s GitHub OAuth client id (not a
  /// secret, kept next to the key so there is not a second store).
  static String clientIdSecret(String workspaceId) =>
      'workspace_provider_app_github_${workspaceId}_client_id';

  /// Secrets-file key for [workspaceId]'s background GitHub PAT.
  static String backgroundPatSecret(String workspaceId) =>
      'workspace_forge_github_$workspaceId';

  /// True when [key] belongs to [workspaceId]'s GitHub identity.
  static bool isWorkspaceSecret(String key, String workspaceId) {
    if (key == backgroundPatSecret(workspaceId) ||
        key == privateKeySecret(workspaceId) ||
        key == clientSecretSecret(workspaceId) ||
        key == clientIdSecret(workspaceId)) {
      return true;
    }
    // Per-(user, workspace) GitHub overlay: `user_forge_github_<userId>_<ws>`.
    const prefix = 'user_forge_github_';
    return key.startsWith(prefix) && key.endsWith('_$workspaceId');
  }

  /// Deletes every secret belonging to [workspaceId].
  Future<int> deleteForWorkspace(String workspaceId) =>
      _secrets.deleteMatching((key) => isWorkspaceSecret(key, workspaceId));

  /// The GitHub App this workspace uses to act as the server, or null.
  ///
  /// Inherit: the install App. App mode: this workspace's App, or null when
  /// the key is missing (fail-closed). PAT mode: always null.
  Future<GitHubAppClient?> githubApp(Workspace workspace) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        return _install.githubApp();
      case GithubAuthMode.pat:
        return null;
      case GithubAuthMode.app:
        return _workspaceClient(workspace);
    }
  }

  /// Whether this workspace's App can mint installation tokens.
  Future<bool> canActAsServer(Workspace workspace) async =>
      await githubApp(workspace) != null;

  /// OAuth client credentials for Sign in with GitHub in [workspace].
  ///
  /// Inherit uses the install App. App mode uses the workspace App's client
  /// id (optional secret). PAT mode returns null — device-flow OAuth is
  /// installation-bounded and cannot see refused orgs.
  Future<OAuthAppCredentials?> oauthCredentials(Workspace workspace) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        return _install.oauthCredentials(ProviderApp.github);
      case GithubAuthMode.pat:
        return null;
      case GithubAuthMode.app:
        final clientId =
            (await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '')
                .trim();
        if (clientId.isEmpty) {
          return null;
        }
        final clientSecret =
            await _secrets.readPsk(clientSecretSecret(workspace.id)) ?? '';
        return (clientId: clientId, clientSecret: clientSecret);
    }
  }

  /// Background PAT for [workspace], or null.
  Future<String?> backgroundPat(String workspaceId) async {
    final raw = await _secrets.readPsk(backgroundPatSecret(workspaceId));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw.trim();
  }

  /// Stores or clears the workspace background PAT. Empty [token] deletes.
  Future<void> setBackgroundPat(String workspaceId, String? token) async {
    final key = backgroundPatSecret(workspaceId);
    if (token == null || token.trim().isEmpty) {
      await _secrets.deletePsk(key);
      return;
    }
    await _secrets.writePsk(key, token.trim());
  }

  /// Presence-only: whether a background PAT is stored.
  Future<bool> hasBackgroundPat(String workspaceId) async =>
      (await backgroundPat(workspaceId)) != null;

  /// Saves this workspace's GitHub App credentials.
  ///
  /// Null leaves a field alone; an empty string clears it. Throws
  /// [AuthException] when a private key does not parse.
  Future<ProviderAppStatus> save(
    Workspace workspace, {
    String? clientId,
    String? clientSecret,
    String? privateKeyPem,
  }) async {
    if (privateKeyPem != null && privateKeyPem.trim().isNotEmpty) {
      final appId = workspace.githubAppId.trim().isNotEmpty
          ? workspace.githubAppId.trim()
          : 'probe';
      final probe = GitHubAppClient.tryCreate(
        appId: appId,
        privateKeyPem: privateKeyPem.trim(),
      );
      if (probe == null) {
        throw const AuthException(
          'That private key could not be read. Paste the whole .pem file '
          'GitHub gave you, including its BEGIN and END lines.',
        );
      }
    }
    await _applySecret(privateKeySecret(workspace.id), privateKeyPem);
    await _applySecret(clientIdSecret(workspace.id), clientId);
    await _applySecret(clientSecretSecret(workspace.id), clientSecret);
    _evictWorkspace(workspace.id);
    return status(workspace);
  }

  /// Configuration as reported to clients (presence flags, never secrets).
  Future<ProviderAppStatus> status(
    Workspace workspace, {
    bool probe = false,
  }) async {
    final appId = workspace.githubAuthMode == GithubAuthMode.app
        ? workspace.githubAppId
        : '';
    final pem =
        await _secrets.readPsk(privateKeySecret(workspace.id)) ?? '';
    final clientId =
        await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '';
    var installations = const <Map<String, Object?>>[];
    var error = '';
    var botLogin = '';
    if (probe &&
        workspace.githubAuthMode == GithubAuthMode.app &&
        appId.isNotEmpty &&
        pem.isNotEmpty) {
      final app = await _workspaceClient(workspace);
      if (app == null) {
        error =
            'The private key could not be read. Paste the whole .pem '
            'file GitHub gave you, including its BEGIN and END lines.';
      } else {
        botLogin = (await app.botInfo())?.botLogin ?? '';
        final found = await app.installations(refresh: true);
        installations = [for (final i in found) i.toJson()];
        if (installations.isEmpty) {
          error =
              'The credentials work, but the app is not installed on any '
              'account yet — install it from its GitHub App page.';
        }
      }
    } else if (workspace.githubAuthMode == GithubAuthMode.app &&
        (appId.isEmpty || pem.isEmpty)) {
      error =
          'This workspace is set to use its own GitHub App, but the app id '
          'or private key is missing. Background GitHub work will not fall '
          'back to this install\'s App.';
    }
    return ProviderAppStatus(
      provider: ProviderApp.github,
      appId: appId,
      clientId: clientId,
      botLogin: botLogin,
      hasPrivateKey: pem.isNotEmpty,
      hasClientSecret:
          (await _secrets.readPsk(clientSecretSecret(workspace.id)) ?? '')
              .isNotEmpty,
      installations: installations,
      error: error,
    );
  }

  Future<GitHubAppClient?> _workspaceClient(Workspace workspace) async {
    final appId = workspace.githubAppId.trim();
    final pem =
        (await _secrets.readPsk(privateKeySecret(workspace.id)) ?? '').trim();
    if (appId.isEmpty || pem.isEmpty) {
      return null;
    }
    final cacheKey = '$appId:${pem.hashCode}';
    final cached = _clients[cacheKey];
    if (cached != null) {
      return cached;
    }
    final factory = _githubAppFactory;
    final client = factory != null
        ? factory(appId: appId, pem: pem)
        : GitHubAppClient.tryCreate(appId: appId, privateKeyPem: pem);
    if (client != null) {
      _clients[cacheKey] = client;
    }
    return client;
  }

  void _evictWorkspace(String workspaceId) {
    // Drop every cached client; App id/key changes are rare and a stale
    // installation token would mint as the wrong identity.
    for (final client in _clients.values) {
      client.invalidate();
    }
    _clients.clear();
  }

  Future<void> _applySecret(String key, String? value) async {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _secrets.deletePsk(key);
      return;
    }
    await _secrets.writePsk(key, trimmed);
  }
}
