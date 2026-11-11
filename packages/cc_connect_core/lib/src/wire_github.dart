import 'package:cc_connect_core/src/wire.dart';

/// Whose token a `/v1/github/scope` mint is.
enum GitHubMintActor {
  /// A one-repository child of the person's own user token
  /// (`/applications/{client_id}/token/scoped`): what GitHub shows as the
  /// person "via" the App. For what a person does, or an agent does in their
  /// name (pull requests it opens for them, pushes to them).
  user('user'),

  /// A one-repository installation token of the App (`ghs_`): GitHub shows
  /// the App's bot. Authorized by the person's sealed grant (they must see
  /// the repository with the asked permission), never broader than them.
  app('app');

  const GitHubMintActor(this.wire);

  /// The wire spelling (`as`).
  final String wire;

  /// Parses a wire value; null when unknown.
  static GitHubMintActor? fromWire(Object? wire) {
    for (final actor in values) {
      if (actor.wire == wire) {
        return actor;
      }
    }
    return null;
  }
}

/// `POST /v1/github/scope`.
final class GitHubScopeRequest {
  /// Creates the request.
  const GitHubScopeRequest({
    required this.seal,
    required this.workspaceId,
    required this.repoId,
    required this.repoOwner,
    required this.repoName,
    required this.scope,
    required this.actor,
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopeRequest.fromJson(Map<String, Object?> json) {
    final seal = json['seal'];
    final workspace = json['workspace_id'];
    final repoId = json['repo_id'];
    final owner = json['repo_owner'];
    final name = json['repo_name'];
    final scope = json['scope'];
    final actor = GitHubMintActor.fromWire(json['as']);
    if (actor == null ||
        seal is! String ||
        seal.isEmpty ||
        workspace is! String ||
        !isWorkspaceScope(workspace) ||
        repoId is! int ||
        repoId <= 0 ||
        owner is! String ||
        name is! String ||
        scope is! String) {
      throw const FormatException('github scope');
    }
    return GitHubScopeRequest(
      seal: seal,
      workspaceId: workspace,
      repoId: repoId,
      repoOwner: owner,
      repoName: name,
      scope: scope,
      actor: actor,
    );
  }

  /// The accountable human's GitHub seal.
  final String seal;

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The numeric repository id (from the linked repo record).
  final int repoId;

  /// The repository owner login.
  final String repoOwner;

  /// The repository name.
  final String repoName;

  /// The requested scope wire value.
  final String scope;

  /// Whose token to mint (`as`).
  final GitHubMintActor actor;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'seal': seal,
    'workspace_id': workspaceId,
    'repo_id': repoId,
    'repo_owner': repoOwner,
    'repo_name': repoName,
    'scope': scope,
    'as': actor.wire,
  };
}

/// The answer to [GitHubScopeRequest].
final class GitHubScopedToken {
  /// Creates the token.
  const GitHubScopedToken({
    required this.accessToken,
    required this.grantedScope,
    required this.expiresAt,
    this.updatedSeal = '',
    this.installationId = 0,
    this.repositorySelection = '',
    this.repositoryIds = const [],
    this.permissions = const {},
  });

  /// Parses the body; throws [FormatException].
  factory GitHubScopedToken.fromJson(Map<String, Object?> json) {
    final access = json['access_token'];
    final granted = json['granted_scope'];
    final expires = json['expires_at'];
    final parsedExpiry = expires is String ? DateTime.tryParse(expires) : null;
    final updated = json['updated_seal'];
    final installation = json['installation_id'];
    final selection = json['repository_selection'];
    final repositories = json['repositories'];
    final permissions = json['permissions'];
    if (access is! String ||
        access.isEmpty ||
        granted is! String ||
        parsedExpiry == null ||
        (selection != null && selection is! String) ||
        (repositories != null &&
            (repositories is! List || repositories.any((r) => r is! int))) ||
        (permissions != null &&
            (permissions is! Map ||
                permissions.entries.any(
                  (e) => e.key is! String || e.value is! String,
                )))) {
      throw const FormatException('github scoped token');
    }
    return GitHubScopedToken(
      accessToken: access,
      grantedScope: granted,
      expiresAt: parsedExpiry.toUtc(),
      updatedSeal: updated is String ? updated : '',
      installationId: installation is int ? installation : 0,
      repositorySelection: selection as String? ?? '',
      repositoryIds: [
        if (repositories is List)
          for (final r in repositories) r as int,
      ],
      permissions: {
        if (permissions is Map)
          for (final e in permissions.entries) e.key as String: e.value as String,
      },
    );
  }

  /// The one-repository `ghu_` token.
  final String accessToken;

  /// The scope actually granted (possibly clamped below the request).
  final String grantedScope;

  /// When the token expires.
  final DateTime expiresAt;

  /// A rotated parent seal the server must persist, when the parent was
  /// refreshed on the way.
  final String updatedSeal;

  /// The installation the token was minted through.
  final int installationId;

  /// An installation token's (`as: app`) `repository_selection` as GitHub
  /// answered the mint; empty for a user child.
  final String repositorySelection;

  /// The repository ids an installation token covers, as GitHub answered
  /// the mint; empty for a user child.
  final List<int> repositoryIds;

  /// The permissions an installation token carries, as GitHub answered the
  /// mint; empty for a user child.
  final Map<String, String> permissions;

  /// The GitHub mint answer's coverage, in the shape `scopedTokenMatches`
  /// reads: the server proves an installation token covers exactly one
  /// repository with exactly the granted permissions before using it.
  Map<String, Object?> get coverage => {
    'repository_selection': repositorySelection,
    'repositories': repositoryIds,
    'permissions': permissions,
  };

  /// The wire body.
  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'granted_scope': grantedScope,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (updatedSeal.isNotEmpty) 'updated_seal': updatedSeal,
    if (installationId > 0) 'installation_id': installationId,
    if (repositorySelection.isNotEmpty)
      'repository_selection': repositorySelection,
    if (repositoryIds.isNotEmpty) 'repositories': repositoryIds,
    if (permissions.isNotEmpty) 'permissions': permissions,
  };
}

/// `POST /v1/github/revoke`: a full disconnect (seal) or one scoped token.
final class GitHubRevokeRequest {
  /// Creates the request.
  const GitHubRevokeRequest({
    required this.workspaceId,
    this.seal = '',
    this.scopedToken = '',
  });

  /// Parses the body; throws [FormatException].
  factory GitHubRevokeRequest.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace_id'];
    final seal = json['seal'];
    final token = json['scoped_token'];
    if (workspace is! String ||
        !isWorkspaceScope(workspace) ||
        seal is! String ||
        seal.isEmpty ||
        (token != null && token is! String)) {
      throw const FormatException('github revoke');
    }
    return GitHubRevokeRequest(
      workspaceId: workspace,
      seal: seal,
      scopedToken: token as String? ?? '',
    );
  }

  /// The workspace the seal belongs to.
  final String workspaceId;

  /// The grant's seal (proves the caller owns it).
  final String seal;

  /// When set, only this scoped token is revoked; otherwise the whole grant.
  final String scopedToken;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'workspace_id': workspaceId,
    'seal': seal,
    if (scopedToken.isNotEmpty) 'scoped_token': scopedToken,
  };
}

/// One installation of the shared GitHub App the signed-in person can see
/// (`POST /v1/github/installations`, body: [SealRequest]). Any server a
/// member of the account signs in on may mint against it: the org's install
/// is its consent, and every token is the member's own, clamped to their
/// repository role.
final class GitHubInstallationView {
  /// Creates the view.
  const GitHubInstallationView({
    required this.installationId,
    required this.accountId,
    required this.accountLogin,
    required this.targetType,
    required this.suspended,
  });

  /// Parses one item; null when malformed.
  static GitHubInstallationView? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final id = json['installation_id'];
    final accountId = json['account_id'];
    final login = json['account_login'];
    final type = json['target_type'];
    if (id is! int ||
        accountId is! int ||
        login is! String ||
        type is! String) {
      return null;
    }
    return GitHubInstallationView(
      installationId: id,
      accountId: accountId,
      accountLogin: login,
      targetType: type,
      suspended: json['suspended'] == true,
    );
  }

  /// GitHub's installation id.
  final int installationId;

  /// The account the app is installed on (numeric).
  final int accountId;

  /// Its login.
  final String accountLogin;

  /// `Organization` or `User`.
  final String targetType;

  /// Whether the installation is suspended.
  final bool suspended;

  /// The wire body.
  Map<String, Object?> toJson() => {
    'installation_id': installationId,
    'account_id': accountId,
    'account_login': accountLogin,
    'target_type': targetType,
    'suspended': suspended,
  };
}
