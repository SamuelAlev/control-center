import 'package:cc_rpc/cc_rpc.dart';

/// One GitHub App installation a workspace can see.
class GitHubInstallationView {
  /// Creates a [GitHubInstallationView].
  const GitHubInstallationView({
    required this.installationId,
    required this.accountId,
    required this.accountLogin,
    required this.targetType,
    this.boundHere = false,
    this.suspended = false,
    this.callerIsAdmin = false,
  });

  /// Decodes one `github.installations` entry.
  factory GitHubInstallationView.fromJson(Map<String, dynamic> json) =>
      GitHubInstallationView(
        installationId: '${json['installation_id'] ?? ''}',
        accountId: '${json['account_id'] ?? ''}',
        accountLogin: json['account_login'] as String? ?? '',
        targetType: json['target_type'] as String? ?? '',
        boundHere: json['bound_here'] as bool? ?? false,
        suspended: json['suspended'] as bool? ?? false,
        callerIsAdmin: json['caller_is_admin'] as bool? ?? false,
      );

  /// GitHub's installation id.
  final String installationId;

  /// The installed-on account's immutable id.
  final String accountId;

  /// The installed-on account's login.
  final String accountLogin;

  /// `Organization` or `User`.
  final String targetType;

  /// Whether this server is authorized to use the installation.
  final bool boundHere;

  /// Whether GitHub has suspended it.
  final bool suspended;

  /// Whether the caller administers the installed-on organization.
  final bool callerIsAdmin;

  /// Whether this is an organization installation.
  bool get isOrganization => targetType.toLowerCase() == 'organization';

  /// Whether the caller can authorize this server for it right now.
  bool get canAuthorizeHere =>
      isOrganization && callerIsAdmin && !boundHere && !suspended;
}

/// GitHub App setup ops: the one-click manifest, the install link, the
/// installations list and org server authorization.
class RemoteGitHubAppSetup {
  /// Creates a [RemoteGitHubAppSetup] over [_client].
  RemoteGitHubAppSetup(this._client);

  final RemoteRpcClient _client;

  /// The one-time page that creates this server's own GitHub App from a
  /// manifest (server owner only), under [organization] when it names one and
  /// under the signed-in GitHub account otherwise.
  Future<String> beginManifest({String organization = ''}) async {
    final org = organization.trim();
    final data = await _client.call('github.manifest.begin', {
      if (org.isNotEmpty) 'organization': org,
    });
    return data['url'] as String? ?? '';
  }

  /// The install link for [workspaceId]'s GitHub App, bound to this server.
  Future<String> beginInstall({required String workspaceId}) async {
    final data = await _client.call('github.install.begin', {
      'workspace_id': workspaceId,
    });
    return data['url'] as String? ?? '';
  }

  /// The installations [workspaceId]'s GitHub lane can see.
  Future<List<GitHubInstallationView>> installations({
    required String workspaceId,
  }) async {
    final data = await _client.call('github.installations', {
      'workspace_id': workspaceId,
    });
    return [
      for (final entry
          in (data['installations'] as List? ?? const []).whereType<Map>())
        GitHubInstallationView.fromJson(entry.cast<String, dynamic>()),
    ];
  }

  /// Authorizes this server to use [installationId] for [workspaceId].
  Future<void> authorizeServer({
    required String workspaceId,
    required String installationId,
  }) => _client.call('github.authorizeServer', {
    'workspace_id': workspaceId,
    'installation_id': int.tryParse(installationId) ?? installationId,
  });
}
