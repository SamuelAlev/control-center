import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart'
    show LinearAppGrants;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/google_calendar_server.dart'
    show FileGoogleCredentialsStore;
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// Per-workspace GitHub App identity (act-as-server + optional sign-in).
///
/// Secrets live in [FileSecretsStore], never in `workspace.db` — exporting a
/// workspace must not leak a private key. `workspaces.github_app_id` on the
/// registry row is the non-secret id; the PEM and OAuth secret stay here.
///
/// [GithubAuthMode.inherit] workspaces share the server's GitHub lane (its own
/// App, else Connect). A missing workspace key in [GithubAuthMode.app] does
/// **not** fall through to the server's lane.
class WorkspaceGitHubAppSettings {
  /// Creates a [WorkspaceGitHubAppSettings].
  WorkspaceGitHubAppSettings({
    required this._secrets,
    required this._install,
    this._githubAppFactory,
  });

  final FileSecretsStore _secrets;
  final ProviderAppSettings _install;
  final GitHubAppClient Function({required String appId, required String pem})?
  _githubAppFactory;

  /// Cache keyed by `appId:pem.hashCode` so two workspaces sharing one App
  /// (or a save that did not change the key) reuse the client.
  final Map<String, GitHubAppClient> _clients = {};

  /// Which [_clients] entry each workspace resolved to last.
  final Map<String, String> _clientKeyOf = {};

  final List<void Function(String workspaceId)> _listeners = [];

  /// Calls [listener] after a workspace's App credentials are saved or
  /// deleted: whatever was minted under the previous identity must not be
  /// served again (`GitHubClients.forgetWorkspace`).
  void addListener(void Function(String workspaceId) listener) =>
      _listeners.add(listener);

  /// Reports that [workspaceId]'s GitHub identity changed outside this
  /// class (its mode or App id was edited on the workspace row).
  void identityChanged(String workspaceId) => _changed(workspaceId);

  void _changed(String workspaceId) {
    _evictWorkspace(workspaceId);
    for (final listener in List.of(_listeners)) {
      listener(workspaceId);
    }
  }

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

  /// True when [key] belongs to [workspaceId]: its GitHub identity, its
  /// Google, Linear and Klipy apps, its members' GitHub overlays, Linear
  /// grants and calendar credentials, and its Linear app-actor grant.
  static bool isWorkspaceSecret(String key, String workspaceId) {
    if (key == privateKeySecret(workspaceId) ||
        key == clientSecretSecret(workspaceId) ||
        key == clientIdSecret(workspaceId) ||
        key == LinearAppGrants.keyFor(workspaceId) ||
        WorkspaceProviderAppSettings.isWorkspaceSecret(key, workspaceId) ||
        UserCredentialsStore.isWorkspaceTicketKey(key, workspaceId) ||
        FileGoogleCredentialsStore.isWorkspaceSecret(key, workspaceId)) {
      return true;
    }
    // Per-(user, workspace) GitHub overlay: `user_forge_github_<userId>_<ws>`.
    const prefix = 'user_forge_github_';
    return key.startsWith(prefix) && key.endsWith('_$workspaceId');
  }

  /// Deletes the per-workspace GitHub personal access tokens earlier
  /// versions stored (`workspace_forge_github_<ws>`). GitHub is sign-in only;
  /// nothing reads them, so they must not linger in the secrets file.
  Future<int> purgeLegacyTokens() => _secrets.deleteMatching(
    (key) => key.startsWith('workspace_forge_github_'),
  );

  /// Deletes every secret belonging to [workspaceId].
  Future<int> deleteForWorkspace(String workspaceId) async {
    final deleted = await _secrets.deleteMatching(
      (key) => isWorkspaceSecret(key, workspaceId),
    );
    _changed(workspaceId);
    return deleted;
  }

  /// The GitHub App this workspace uses to act as the server, or null.
  ///
  /// Inherit: the server's own App, when fully configured. App mode: this
  /// workspace's App, or null when the key is missing (fail-closed).
  Future<GitHubAppClient?> githubApp(Workspace workspace) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        return _install.githubApp();
      case GithubAuthMode.app:
        return _workspaceClient(workspace);
    }
  }

  /// Whether this workspace's App can mint installation tokens.
  Future<bool> canActAsServer(Workspace workspace) async =>
      await githubApp(workspace) != null;

  /// OAuth client credentials for Sign in with GitHub in [workspace].
  ///
  /// Inherit uses the server's own App (null when the server rides
  /// Connect). App mode uses the workspace App's client id and secret; the
  /// web flow needs both.
  Future<OAuthAppCredentials?> oauthCredentials(Workspace workspace) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        return _install.oauthCredentials(ProviderApp.github);
      case GithubAuthMode.app:
        final clientId =
            (await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '').trim();
        final clientSecret =
            (await _secrets.readPsk(clientSecretSecret(workspace.id)) ?? '')
                .trim();
        if (clientId.isEmpty || clientSecret.isEmpty) {
          return null;
        }
        return (clientId: clientId, clientSecret: clientSecret);
    }
  }

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
      if (!GitHubAppClient.isReadablePrivateKey(privateKeyPem.trim())) {
        throw const AuthException(
          'That private key could not be read. Paste the whole .pem file '
          'GitHub gave you, including its BEGIN and END lines.',
        );
      }
    }
    await _applySecret(privateKeySecret(workspace.id), privateKeyPem);
    await _applySecret(clientIdSecret(workspace.id), clientId);
    await _applySecret(clientSecretSecret(workspace.id), clientSecret);
    _changed(workspace.id);
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
    final pem = await _secrets.readPsk(privateKeySecret(workspace.id)) ?? '';
    final clientId = await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '';
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
    final pem = (await _secrets.readPsk(privateKeySecret(workspace.id)) ?? '')
        .trim();
    if (appId.isEmpty || pem.isEmpty) {
      return null;
    }
    final cacheKey = '$appId:${pem.hashCode}';
    _clientKeyOf[workspace.id] = cacheKey;
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

  /// Drops the cached client [workspaceId] last used, unless another
  /// workspace still resolves to the same App and key.
  void _evictWorkspace(String workspaceId) {
    final key = _clientKeyOf.remove(workspaceId);
    if (key == null || _clientKeyOf.containsValue(key)) {
      return;
    }
    _clients.remove(key)?.invalidate();
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
