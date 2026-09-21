import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/github_auth_mode.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';

/// Reads a process environment variable. Injected so tests can drive the
/// environment source without touching `Platform.environment`.
typedef EnvLookup = String? Function(String name);

/// Asks a forge who the bearer of [token] is, for the connection's username.
/// Returns null when the token is rejected or the call fails.
typedef ViewerProbe = Future<String?> Function(ForgeHost forge, String token);

/// Exchanges an expired credential for a fresh one, or null when it cannot be
/// refreshed (no refresh token, or the provider rejected it).
typedef ProviderTokenRefresh =
    Future<ProviderToken?> Function(
      String userId,
      ForgeHost forge,
      ProviderToken expired, {
      String? workspaceId,
    });

/// Server-side [ForgeCredentialPort], resolved per call (not captured at boot).
///
/// Lanes: (1) caller's own credential when `userId` set — else nothing for that call;
/// (2) workspace/install GitHub App; (3) server owner's pasted PAT when no caller;
/// (4) environment (`GITHUB_TOKEN`, …) for CI. [tokenForActor] is the exception: act as
/// the user, falling back to the no-caller chain only if they have not signed in.
class ForgeCredentials implements ForgeCredentialPort {
  /// Creates a [ForgeCredentials].
  ///
  /// [users] holds the per-user credentials; [apps] supplies the server's own
  /// app identity. Both may be null on a minimal host, which degrades to the
  /// environment lane. [viewerProbe] resolves the account name behind a token;
  /// without it connections report authentication with no username.
  ///
  /// [workspaceApps] / [workspaceLookup] may be assigned after construction —
  /// the workspace registry is assembled later on the boot path.
  ForgeCredentials({
    required EnvLookup env,
    UserCredentialsStore? users,
    ProviderAppSettings? apps,
    WorkspaceGitHubAppSettings? workspaceApps,
    Future<Workspace?> Function(String workspaceId)? workspaceLookup,
    Future<String?> Function()? serverOwnerUserId,
    ViewerProbe? viewerProbe,
  }) : _env = env,
       _users = users,
       _apps = apps,
       workspaceApps = workspaceApps,
       workspaceLookup = workspaceLookup,
       _serverOwnerUserId = serverOwnerUserId,
       _viewerProbe = viewerProbe;

  final EnvLookup _env;
  final UserCredentialsStore? _users;
  final ProviderAppSettings? _apps;
  WorkspaceGitHubAppSettings? workspaceApps;
  Future<Workspace?> Function(String workspaceId)? workspaceLookup;
  final Future<String?> Function()? _serverOwnerUserId;
  final ViewerProbe? _viewerProbe;

  /// Refreshes an expired user credential. Set by the OAuth service after
  /// construction — it needs this store to read the credential it refreshes,
  /// so the two cannot be constructed in one direction.
  ProviderTokenRefresh? refreshUserToken;

  /// Cached viewer identity per (user, forge, workspace), so the roster and
  /// "is this mine?" checks do not re-probe on every read. Invalidated
  /// whenever that user's token for the forge changes.
  final Map<String, String> _viewerCache = {};

  static String _cacheKey(
    ForgeHost forge,
    String? userId, {
    String? workspaceId,
  }) => '${workspaceId ?? ''}:${userId ?? ''}:${forge.wire}';

  /// Environment variable names per forge, in the order they are consulted.
  ///
  /// Bitbucket Cloud authenticates with an account email plus an API token, so
  /// its token is assembled from two variables rather than read from one.
  static const Map<ForgeHost, List<String>> _envNames = {
    ForgeHost.github: ['GITHUB_TOKEN', 'GH_TOKEN'],
    ForgeHost.gitlab: ['GITLAB_TOKEN', 'CI_JOB_TOKEN'],
    ForgeHost.bitbucket: ['BITBUCKET_API_TOKEN', 'BITBUCKET_TOKEN'],
  };

  /// The Bitbucket account email, needed as the username half of its basic
  /// auth. Empty when unset.
  String get bitbucketEmail => _env('BITBUCKET_EMAIL') ?? '';

  @override
  Future<String?> tokenFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    final resolved = await _resolve(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    return resolved.token.isEmpty ? null : resolved.token;
  }

  /// Credential to act as [userId]: their token first (forge attribution), else the no-caller chain.
  /// With [workspaceId], GitHub uses that workspace's overlay → inherit onboarding → that workspace's App only.
  Future<String?> tokenForActor(
    ForgeHost forge,
    String? userId, {
    String? workspaceId,
  }) async {
    if (userId != null) {
      final own = await _userLane(
        forge,
        userId,
        workspaceId: workspaceId,
      );
      if (own != null && own.token.isNotEmpty) {
        return own.token;
      }
      if (workspaceId != null &&
          workspaceId.isNotEmpty &&
          forge == ForgeHost.github) {
        final workspace = await workspaceLookup?.call(workspaceId);
        if (workspace == null ||
            workspace.githubAuthMode == GithubAuthMode.inherit) {
          final global = await _userLane(forge, userId);
          if (global != null && global.token.isNotEmpty) {
            return global.token;
          }
        }
      }
    }
    return tokenFor(forge, workspaceId: workspaceId);
  }

  /// Whether [userId] holds their own credential for [forge] — i.e. whether
  /// [tokenForActor] will act as them rather than falling back to the app.
  ///
  /// The surface uses this to say whose name a write will carry instead of
  /// letting the operator discover it from the byline on GitHub.
  Future<bool> actsAsSelf(
    ForgeHost forge,
    String? userId, {
    String? workspaceId,
  }) async {
    if (userId == null) {
      return false;
    }
    final own = await _userLane(forge, userId, workspaceId: workspaceId);
    if (own != null && own.token.isNotEmpty) {
      return true;
    }
    if (workspaceId != null &&
        workspaceId.isNotEmpty &&
        forge == ForgeHost.github) {
      final workspace = await workspaceLookup?.call(workspaceId);
      if (workspace == null ||
          workspace.githubAuthMode == GithubAuthMode.inherit) {
        final global = await _userLane(forge, userId);
        return global != null && global.token.isNotEmpty;
      }
    }
    return false;
  }

  /// The app-installation token covering [owner], or null when the server has
  /// no app identity there.
  ///
  /// Used by the paths that know which account they are acting on (a repo's
  /// owner), so the token is scoped to that installation rather than whichever
  /// one answered first.
  Future<String?> appTokenForOwner(
    ForgeHost forge,
    String owner, {
    String? workspaceId,
  }) async {
    if (forge != ForgeHost.github) {
      return null;
    }
    final app = await _githubAppFor(workspaceId);
    return app?.tokenForOwner(owner);
  }

  /// The credential for repo-scoped background work about [owner]'s repos.
  ///
  /// [tokenFor] with no caller answers with a token for whichever installation
  /// responded first — right for work that is not about one account, wrong for
  /// a repo whose owner the app is not installed on: GitHub answers such a
  /// token with 404 (not 403), forever, and the caller reads it as the repo
  /// not existing. This resolves the installation covering [owner]
  /// specifically; when the app is not installed there the fallback is the
  /// workspace background PAT (or the server owner's pasted PAT) and then the
  /// environment — never another owner's installation token, which is
  /// guaranteed not to work.
  ///
  /// When [workspaceId] is set, [GithubAuthMode.app] never returns the install
  /// App's `ghs_`, and [GithubAuthMode.pat] never returns any App token.
  Future<String?> tokenForRepoOwner(
    ForgeHost forge,
    String owner, {
    String? workspaceId,
  }) async {
    if (!forge.isSupported) {
      return null;
    }
    if (forge == ForgeHost.github &&
        workspaceId != null &&
        workspaceId.isNotEmpty) {
      final workspace = await workspaceLookup?.call(workspaceId);
      if (workspace != null) {
        return _tokenForRepoOwnerInWorkspace(workspace, owner);
      }
    }
    return _inheritRepoOwner(forge, owner);
  }

  @override
  Future<void> setToken(
    ForgeHost forge,
    String token, {
    String? userId,
    String? workspaceId,
  }) async {
    final owner = userId ?? await _resolveOwnerId();
    if (owner == null) {
      // No identity to attach it to. Storing it server-wide would give every
      // member the credential, which is the model this replaced.
      throw StateError('Cannot store a forge token without a user.');
    }
    await _users?.setForgeToken(
      owner,
      forge,
      ProviderToken(accessToken: token),
      workspaceId: workspaceId,
    );
    _invalidate(forge, owner, workspaceId: workspaceId);
  }

  @override
  Future<void> clearToken(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    final owner = userId ?? await _resolveOwnerId();
    if (owner == null) {
      return;
    }
    await _users?.clearForgeToken(owner, forge, workspaceId: workspaceId);
    _invalidate(forge, owner, workspaceId: workspaceId);
  }

  @override
  Future<List<ForgeConnection>> connections({
    String? userId,
    String? workspaceId,
  }) async {
    final result = <ForgeConnection>[];
    for (final forge in ForgeHost.supported) {
      result.add(
        await _connectionFor(
          forge,
          userId: userId,
          workspaceId: workspaceId,
          probeViewer: false,
        ),
      );
    }
    return result;
  }

  @override
  Future<ForgeConnection> testConnection(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    _viewerCache.remove(
      _cacheKey(forge, userId, workspaceId: workspaceId),
    );
    return _connectionFor(
      forge,
      userId: userId,
      workspaceId: workspaceId,
      probeViewer: true,
    );
  }

  @override
  Future<String> viewerLogin(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    final key = _cacheKey(forge, userId, workspaceId: workspaceId);
    final cached = _viewerCache[key];
    if (cached != null) {
      return cached;
    }
    final resolved = await _resolve(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (resolved.token.isEmpty) {
      return '';
    }
    if (resolved.username.isNotEmpty) {
      return _viewerCache[key] = resolved.username;
    }
    final probed = await _viewerProbe?.call(forge, resolved.token);
    if (probed == null || probed.isEmpty) {
      return '';
    }
    return _viewerCache[key] = probed;
  }

  void _invalidate(ForgeHost forge, String userId, {String? workspaceId}) {
    _viewerCache.remove(
      _cacheKey(forge, userId, workspaceId: workspaceId),
    );
    _viewerCache.remove(_cacheKey(forge, userId));
    _viewerCache.remove(_cacheKey(forge, null));
    _revision++;
  }

  int _revision = 0;

  /// Bumps whenever any credential changes. Clients of this store cache
  /// per-forge HTTP clients and compare this to know when to rebuild them.
  int get revision => _revision;

  Future<String?> _resolveOwnerId() async => _serverOwnerUserId?.call();

  Future<ForgeConnection> _connectionFor(
    ForgeHost forge, {
    required String? userId,
    required bool probeViewer,
    String? workspaceId,
  }) async {
    final resolved = await _resolve(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (resolved.token.isEmpty) {
      return ForgeConnection.disconnected(forge);
    }
    final key = _cacheKey(forge, userId, workspaceId: workspaceId);
    var username = resolved.username;
    if (username.isEmpty) {
      username = probeViewer
          ? (await _viewerProbe?.call(forge, resolved.token) ?? '')
          : (_viewerCache[key] ?? '');
      if (probeViewer && username.isNotEmpty) {
        _viewerCache[key] = username;
      }
    }
    if (probeViewer && username.isEmpty) {
      return ForgeConnection(
        forge: forge,
        authenticated: false,
        source: resolved.source,
        error: '${forge.displayName} rejected the stored credential.',
      );
    }
    return ForgeConnection(
      forge: forge,
      authenticated: true,
      username: username,
      source: resolved.source,
    );
  }

  /// Walks the precedence chain once.
  Future<({String token, String username, ForgeCredentialSource source})>
  _resolve(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    const empty = (token: '', username: '', source: ForgeCredentialSource.none);
    if (!forge.isSupported) {
      return empty;
    }

    if (userId != null) {
      final overlay = await _userLane(
        forge,
        userId,
        workspaceId: workspaceId,
      );
      if (overlay != null) {
        return overlay;
      }
      if (workspaceId != null &&
          workspaceId.isNotEmpty &&
          forge == ForgeHost.github) {
        final workspace = await workspaceLookup?.call(workspaceId);
        if (workspace == null ||
            workspace.githubAuthMode == GithubAuthMode.inherit) {
          final global = await _userLane(forge, userId);
          return global ?? empty;
        }
      }
      return empty;
    }

    if (forge == ForgeHost.github &&
        workspaceId != null &&
        workspaceId.isNotEmpty) {
      final workspace = await workspaceLookup?.call(workspaceId);
      if (workspace != null) {
        final scoped = await _serverLaneForWorkspace(workspace);
        if (scoped != null) {
          return scoped;
        }
        return empty;
      }
    }

    // No caller: the server's own identity first, so background work does not
    // ride on a human's credential when the app can answer.
    final appToken = await _installAppLane(forge);
    if (appToken != null) {
      return appToken;
    }

    final ownerId = await _resolveOwnerId();
    if (ownerId != null) {
      final owner = await _userLane(forge, ownerId);
      if (owner != null) {
        return owner;
      }
    }

    return await _envLane(forge) ?? empty;
  }

  Future<String?> _tokenForRepoOwnerInWorkspace(
    Workspace workspace,
    String owner,
  ) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        return _inheritRepoOwner(ForgeHost.github, owner);
      case GithubAuthMode.app:
        final app = await workspaceApps?.githubApp(workspace);
        if (app != null) {
          final token = await app.tokenForOwner(owner);
          if (token != null && token.isNotEmpty) {
            return token;
          }
        }
        return _workspacePatThenOwnerPastedThenEnv(workspace.id);
      case GithubAuthMode.pat:
        return _workspacePatThenOwnerPastedThenEnv(workspace.id);
    }
  }

  Future<String?> _inheritRepoOwner(ForgeHost forge, String owner) async {
    final appToken = await appTokenForOwner(forge, owner);
    if (appToken != null && appToken.isNotEmpty) {
      return appToken;
    }
    final ownerId = await _resolveOwnerId();
    if (ownerId != null) {
      final own = await _userLane(forge, ownerId);
      if (own != null && own.token.isNotEmpty) {
        return own.token;
      }
    }
    return _envToken(forge);
  }

  Future<String?> _workspacePatThenOwnerPastedThenEnv(
    String workspaceId,
  ) async {
    final pat = await workspaceApps?.backgroundPat(workspaceId);
    if (pat != null && pat.isNotEmpty) {
      return pat;
    }
    final pasted = await _ownerPastedPat(ForgeHost.github);
    if (pasted != null && pasted.token.isNotEmpty) {
      return pasted.token;
    }
    return _envToken(ForgeHost.github);
  }

  Future<({String token, String username, ForgeCredentialSource source})?>
  _serverLaneForWorkspace(Workspace workspace) async {
    switch (workspace.githubAuthMode) {
      case GithubAuthMode.inherit:
        final app = await _installAppLane(ForgeHost.github);
        if (app != null) {
          return app;
        }
        final ownerId = await _resolveOwnerId();
        if (ownerId != null) {
          final owner = await _userLane(ForgeHost.github, ownerId);
          if (owner != null) {
            return owner;
          }
        }
        return await _envLane(ForgeHost.github);
      case GithubAuthMode.app:
        final client = await workspaceApps?.githubApp(workspace);
        final token = await client?.anyInstallationToken();
        if (token != null && token.isNotEmpty) {
          return (token: token, username: '', source: ForgeCredentialSource.app);
        }
        final fallback = await _workspacePatThenOwnerPastedThenEnv(
          workspace.id,
        );
        if (fallback == null) {
          return null;
        }
        return (
          token: fallback,
          username: '',
          source: ForgeCredentialSource.settings,
        );
      case GithubAuthMode.pat:
        final fallback = await _workspacePatThenOwnerPastedThenEnv(
          workspace.id,
        );
        if (fallback == null) {
          return null;
        }
        return (
          token: fallback,
          username: '',
          source: ForgeCredentialSource.settings,
        );
    }
  }

  Future<GitHubAppClient?> _githubAppFor(String? workspaceId) async {
    if (workspaceId != null && workspaceId.isNotEmpty) {
      final workspace = await workspaceLookup?.call(workspaceId);
      if (workspace != null) {
        return workspaceApps?.githubApp(workspace);
      }
    }
    return _apps?.githubApp();
  }

  /// One user's own credential, refreshed in place when it has expired.
  Future<({String token, String username, ForgeCredentialSource source})?>
  _userLane(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null) {
      return null;
    }
    var token = await users.forgeToken(
      userId,
      forge,
      workspaceId: workspaceId,
    );
    if (token == null) {
      return null;
    }
    if (token.isExpired) {
      final refreshed = token.canRefresh
          ? await refreshUserToken?.call(
              userId,
              forge,
              token,
              workspaceId: workspaceId,
            )
          : null;
      if (refreshed == null) {
        // An expired credential that cannot be refreshed is worse than none:
        // every call fails with a 401 the UI reports as an unexplained error.
        // Drop it so the row reads "not connected" and offers a sign-in.
        await users.clearForgeToken(
          userId,
          forge,
          workspaceId: workspaceId,
        );
        _invalidate(forge, userId, workspaceId: workspaceId);
        return null;
      }
      await users.setForgeToken(
        userId,
        forge,
        refreshed,
        workspaceId: workspaceId,
      );
      token = refreshed;
    }
    return (
      token: token.accessToken,
      username: token.accountLogin,
      source: token.source,
    );
  }

  /// The owner's pasted PAT (Settings source), never an App OAuth token.
  Future<({String token, String username, ForgeCredentialSource source})?>
  _ownerPastedPat(ForgeHost forge) async {
    final ownerId = await _resolveOwnerId();
    if (ownerId == null) {
      return null;
    }
    final own = await _userLane(forge, ownerId);
    if (own == null || own.source != ForgeCredentialSource.settings) {
      return null;
    }
    return own;
  }

  /// The install-wide app identity for [forge], when it has one.
  Future<({String token, String username, ForgeCredentialSource source})?>
  _installAppLane(ForgeHost forge) async {
    if (forge != ForgeHost.github) {
      // Only GitHub has an app identity today. GitLab and Bitbucket would each
      // need their own registration, and claiming otherwise would report them
      // connected on a server that cannot call them.
      return null;
    }
    final app = await _apps?.githubApp();
    final token = await app?.anyInstallationToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return (token: token, username: '', source: ForgeCredentialSource.app);
  }

  Future<({String token, String username, ForgeCredentialSource source})?>
  _envLane(ForgeHost forge) async {
    final value = _envToken(forge);
    if (value == null) {
      return null;
    }
    return (
      token: value,
      username: '',
      source: ForgeCredentialSource.environment,
    );
  }

  String? _envToken(ForgeHost forge) {
    for (final name in _envNames[forge] ?? const <String>[]) {
      final value = _env(name);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
