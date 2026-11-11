import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart'
    show LinearAppGrants;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart'
    show ForgeAutomationTokens;
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
/// The workspace's App applies only while its Connect choice is
/// [WorkspaceConnectMode.own]; a missing key then does **not** fall through
/// to the server's lane. [WorkspaceConnectMode.inherit] workspaces share the
/// server's GitHub lane (its own App, else its Connect); a workspace on a
/// Connect of its own has no App here at all.
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
  final List<Future<void> Function(String workspaceId)> _deletionListeners = [];

  /// Calls [listener] after a workspace's App credentials are saved or
  /// deleted: whatever was minted under the previous identity must not be
  /// served again (`GitHubClients.forgetWorkspace`).
  void addListener(void Function(String workspaceId) listener) =>
      _listeners.add(listener);

  /// Runs first when a workspace is deleted, while its secrets (and its own
  /// Connect's trust) are still there: its members' grants are revoked
  /// upstream (`CredentialOffboarding.workspaceDeleted`).
  Future<void> Function(String workspaceId)? offboardWorkspace;

  /// Calls [listener] once a workspace is deleted, after its secrets went:
  /// state kept elsewhere for it (its own Connect's trust store) goes too.
  void addDeletionListener(
    Future<void> Function(String workspaceId) listener,
  ) => _deletionListeners.add(listener);

  /// Reports that [workspaceId]'s GitHub identity changed outside this
  /// class (its App id was edited on the workspace row, or its Connect
  /// choice changed).
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
  /// Google, Linear and Klipy apps, its members' forge sign-ins and lapse
  /// markers (every forge), Linear grants and calendar credentials, its
  /// Linear app-actor grant, and its GitLab/Bitbucket automation tokens.
  /// Every match is exact or a full prefix ending in a delimiter workspace
  /// ids cannot contain, so one workspace never reaches another's keys or a
  /// person's global ones.
  static bool isWorkspaceSecret(String key, String workspaceId) =>
      key == privateKeySecret(workspaceId) ||
      key == clientSecretSecret(workspaceId) ||
      key == clientIdSecret(workspaceId) ||
      key == LinearAppGrants.keyFor(workspaceId) ||
      WorkspaceProviderAppSettings.isWorkspaceSecret(key, workspaceId) ||
      UserCredentialsStore.isWorkspaceTicketKey(key, workspaceId) ||
      UserCredentialsStore.isWorkspaceForgeKey(key, workspaceId) ||
      ForgeAutomationTokens.isWorkspaceSecret(key, workspaceId) ||
      FileGoogleCredentialsStore.isWorkspaceSecret(key, workspaceId);

  /// Deletes every secret belonging to [workspaceId].
  Future<int> deleteForWorkspace(String workspaceId) async {
    await offboardWorkspace?.call(workspaceId);
    final deleted = await _secrets.deleteMatching(
      (key) => isWorkspaceSecret(key, workspaceId),
    );
    _changed(workspaceId);
    for (final listener in List.of(_deletionListeners)) {
      await listener(workspaceId);
    }
    return deleted;
  }

  /// The GitHub App this workspace uses to act as the server, or null.
  ///
  /// Inherit: the server's own App, when fully configured and in force. Own
  /// apps: this workspace's App, or null when the key is missing
  /// (fail-closed). A Connect of its own: none.
  Future<GitHubAppClient?> githubApp(Workspace workspace) async {
    switch (workspace.connectMode) {
      case WorkspaceConnectMode.inherit:
        return _install.githubApp();
      case WorkspaceConnectMode.own:
        return _workspaceClient(workspace);
      case WorkspaceConnectMode.hosted || WorkspaceConnectMode.custom:
        return null;
    }
  }

  /// Whether this workspace's App can mint installation tokens.
  Future<bool> canActAsServer(Workspace workspace) async =>
      await githubApp(workspace) != null;

  /// OAuth client credentials for Sign in with GitHub in [workspace].
  ///
  /// Inherit uses the server's own App (null when the server rides
  /// Connect). Own apps use the workspace App's client id and secret; the
  /// web flow needs both. A Connect of its own: none.
  Future<OAuthAppCredentials?> oauthCredentials(Workspace workspace) async {
    switch (workspace.connectMode) {
      case WorkspaceConnectMode.inherit:
        return _install.oauthCredentials(ProviderApp.github);
      case WorkspaceConnectMode.own:
        final clientId =
            (await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '').trim();
        final clientSecret =
            (await _secrets.readPsk(clientSecretSecret(workspace.id)) ?? '')
                .trim();
        if (clientId.isEmpty || clientSecret.isEmpty) {
          return null;
        }
        return (clientId: clientId, clientSecret: clientSecret);
      case WorkspaceConnectMode.hosted || WorkspaceConnectMode.custom:
        return null;
    }
  }

  /// The OAuth client stored for [workspaceId]'s own App, whatever its
  /// Connect choice now, or null when either half is missing. For revoking
  /// grants that App issued after the workspace moved off it; sign-in uses
  /// [oauthCredentials].
  Future<OAuthAppCredentials?> storedOAuthCredentials(
    String workspaceId,
  ) async {
    final clientId = (await _secrets.readPsk(clientIdSecret(workspaceId)) ?? '')
        .trim();
    final clientSecret =
        (await _secrets.readPsk(clientSecretSecret(workspaceId)) ?? '').trim();
    if (clientId.isEmpty || clientSecret.isEmpty) {
      return null;
    }
    return (clientId: clientId, clientSecret: clientSecret);
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
    forgeAudit(ForgeAuditEvent.providerAppSaved, {
      'provider': 'github',
      'scope': 'workspace',
      'workspace_id': workspace.id,
      // Names only: which fields this save set or cleared.
      'fields': [
        if (clientId != null) 'client_id',
        if (clientSecret != null) 'client_secret',
        if (privateKeyPem != null) 'private_key',
      ].join(','),
    });
    return status(workspace);
  }

  /// The workspace's own App as reported to clients (presence flags, never
  /// secrets), whatever its Connect choice: it applies only on its own apps,
  /// where a partial App is the setup error [ProviderAppStatus.error] names.
  Future<ProviderAppStatus> status(
    Workspace workspace, {
    bool probe = false,
  }) async {
    final appId = workspace.githubAppId.trim();
    final pem = await _secrets.readPsk(privateKeySecret(workspace.id)) ?? '';
    final clientId = await _secrets.readPsk(clientIdSecret(workspace.id)) ?? '';
    final hasClientSecret =
        (await _secrets.readPsk(clientSecretSecret(workspace.id)) ?? '')
            .isNotEmpty;
    var installations = const <Map<String, Object?>>[];
    var error = '';
    var botLogin = '';
    final own = workspace.connectMode == WorkspaceConnectMode.own;
    final fields = [
      appId.isNotEmpty,
      pem.isNotEmpty,
      clientId.isNotEmpty,
      hasClientSecret,
    ];
    if (probe && appId.isNotEmpty && pem.isNotEmpty) {
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
    } else if (own && fields.any((f) => f) && !fields.every((f) => f)) {
      error =
          'This workspace uses its own apps, but its GitHub App is only partly '
          'set up. Add the app id, private key, client id and client secret. '
          'GitHub in this workspace will not fall back to this server\'s App.';
    }
    return ProviderAppStatus(
      provider: ProviderApp.github,
      appId: appId,
      clientId: clientId,
      botLogin: botLogin,
      hasPrivateKey: pem.isNotEmpty,
      hasClientSecret: hasClientSecret,
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
