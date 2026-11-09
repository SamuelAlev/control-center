import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart'
    show SealStanding, sealStandingOf;
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';

/// Reads a process environment variable. Injected so tests can drive the
/// environment source without touching `Platform.environment`.
typedef EnvLookup = String? Function(String name);

/// Asks a forge who the bearer of [token] is, for the connection's username.
/// Returns null when the token is rejected or the call fails.
typedef ViewerProbe = Future<String?> Function(ForgeHost forge, String token);

/// Renews an expired credential. Implemented by the sign-in service, which
/// knows whether the grant is an own-app OAuth token or a Connect seal.
typedef ProviderTokenRefresh =
    Future<RefreshOutcome> Function(
      String userId,
      ForgeHost forge,
      ProviderToken expired, {
      String? workspaceId,
    });

/// The current install id for the Connect that sealed [connectOrigin], or
/// null when this server no longer uses that Connect.
typedef SealInstallIdLookup = Future<String?> Function(String connectOrigin);

/// One stored credential changed: [userId]'s [forge] sign-in in
/// [workspaceId] (null for the global slot, which every workspace that
/// inherits it sees).
final class ForgeCredentialChange {
  /// Creates the change.
  const ForgeCredentialChange({
    required this.forge,
    required this.userId,
    this.workspaceId,
  });

  /// The forge.
  final ForgeHost forge;

  /// Whose credential.
  final String userId;

  /// The workspace slot, or null for the global one.
  final String? workspaceId;
}

/// Server-side [ForgeTokenStore] and [ForgeConnectionView]: **people's**
/// forge credentials,
/// resolved per call.
///
/// GitHub is person-only here. A user's GitHub token is theirs and nobody
/// else's: there is no App, server-owner, environment or pasted-PAT
/// fallback, so a person who has not signed in gets `null` and the caller
/// says "Sign in to GitHub". Work no person is doing (agents, pollers,
/// pipelines, bot replies) never comes here — it uses `GitHubClients`, which
/// mints one-repository tokens.
///
/// GitLab and Bitbucket stay token-based: a person's pasted token, and for
/// background work the server owner's pasted token, then the environment.
///
/// Connect-sealed credentials keep only the seal on disk; their access
/// tokens live in [_memory] for this process. Refreshes are single-flight per
/// `(workspace, user, forge)` because GitHub refresh tokens are single-use,
/// and only a [RefreshRejected] outcome clears a credential.
class ForgeCredentials implements ForgeTokenStore, ForgeConnectionView {
  /// Creates a [ForgeCredentials].
  ForgeCredentials({
    required this._env,
    this._users,
    this.workspaceLookup,
    this._serverOwnerUserId,
    this._viewerProbe,
  });

  final EnvLookup _env;
  final UserCredentialsStore? _users;

  /// Loads a workspace so GitHub resolution can follow its mode. Assigned
  /// after construction, once the workspace registry exists.
  Future<Workspace?> Function(String workspaceId)? workspaceLookup;
  final Future<String?> Function()? _serverOwnerUserId;
  final ViewerProbe? _viewerProbe;

  /// Refreshes an expired credential. Set by the sign-in service after
  /// construction (each needs the other).
  ProviderTokenRefresh? refreshUserToken;

  /// Resolves the install id a sealed credential must carry. Set once the
  /// Connect client exists.
  SealInstallIdLookup? currentSealInstallId;

  /// Access tokens of sealed credentials, by storage key. Never persisted.
  final Map<String, ProviderToken> _memory = {};

  /// A rotated sealed grant whose write failed, with the seal it replaced.
  /// Connect spent that parent when it rotated, so this is the only copy of
  /// the new seal: it is served from memory and written again on the next
  /// call, never dropped while the stored grant is still its parent.
  final Map<String, ({String parent, ProviderToken token})> _unsaved = {};

  /// In-flight refreshes, by storage key.
  final SingleFlight<String, ProviderToken?> _refreshing = SingleFlight();

  /// Cached viewer identity per (user, forge, workspace).
  final Map<String, String> _viewerCache = {};

  static String _cacheKey(
    ForgeHost forge,
    String? userId, {
    String? workspaceId,
  }) => '${workspaceId ?? ''}:${userId ?? ''}:${forge.wire}';

  /// Environment variable names per forge. GitHub has none on purpose: a
  /// host token would be nobody's identity.
  static const Map<ForgeHost, List<String>> _envNames = {
    ForgeHost.gitlab: ['GITLAB_TOKEN', 'CI_JOB_TOKEN'],
    ForgeHost.bitbucket: ['BITBUCKET_API_TOKEN', 'BITBUCKET_TOKEN'],
  };

  /// The Bitbucket account email, needed as the username half of its basic
  /// auth. Empty when unset.
  String get bitbucketEmail => _env('BITBUCKET_EMAIL') ?? '';

  /// The credential for [forge]: [userId]'s own when given. Without a user,
  /// GitHub answers null (use `GitHubClients.mintScoped`/`forOwner`); GitLab and
  /// Bitbucket answer the owner's pasted token, then the environment.
  @override
  Future<String?> tokenFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      return personToken(forge, userId, workspaceId: workspaceId);
    }
    if (forge == ForgeHost.github || !forge.isSupported) {
      return null;
    }
    final ownerId = await _serverOwnerUserId?.call();
    if (ownerId != null) {
      final own = await _userLane(forge, ownerId);
      if (own != null) {
        return own.accessToken;
      }
    }
    return _envToken(forge);
  }

  /// [userId]'s own credential for [forge], or null when they have none.
  ///
  /// GitHub with a [workspaceId]: that workspace's sign-in first; a
  /// workspace that inherits the server's lane then accepts the person's
  /// global sign-in. A workspace on its own App accepts only a sign-in to
  /// that App.
  Future<String?> personToken(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async => (await personCredential(
    forge,
    userId,
    workspaceId: workspaceId,
  ))?.accessToken;

  /// Like [personToken], with the credential's identity fields.
  Future<ProviderToken?> personCredential(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    if (!forge.isSupported || userId.isEmpty) {
      return null;
    }
    final scoped = workspaceId != null && workspaceId.isNotEmpty;
    if (scoped) {
      final overlay = await _userLane(forge, userId, workspaceId: workspaceId);
      if (overlay != null) {
        return overlay;
      }
      if (forge == ForgeHost.github) {
        final workspace = await workspaceLookup?.call(workspaceId);
        if (workspace != null &&
            workspace.githubAuthMode == GithubAuthMode.app) {
          return null;
        }
      }
    }
    return _userLane(forge, userId);
  }

  /// The stored (possibly sealed) credential and the slot it lives in, for
  /// callers that need the seal itself (Connect scope minting, revoke).
  Future<({ProviderToken token, String? workspaceId})?> storedCredential(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null) {
      return null;
    }
    if (workspaceId != null && workspaceId.isNotEmpty) {
      final overlay = await users.forgeToken(
        userId,
        forge,
        workspaceId: workspaceId,
      );
      if (overlay != null) {
        return forge == ForgeHost.github && !isGitHubSignIn(overlay)
            ? null
            : (token: overlay, workspaceId: workspaceId);
      }
      if (forge == ForgeHost.github) {
        final workspace = await workspaceLookup?.call(workspaceId);
        if (workspace != null &&
            workspace.githubAuthMode == GithubAuthMode.app) {
          return null;
        }
      }
    }
    final global = await users.forgeToken(userId, forge);
    if (global == null ||
        (forge == ForgeHost.github && !isGitHubSignIn(global))) {
      return null;
    }
    return (token: global, workspaceId: null);
  }

  /// Persists a rotated seal handed back by Connect on the way through
  /// another call (a scope mint that refreshed the parent token).
  ///
  /// Waits out a refresh of that credential already in flight, so the two
  /// never interleave their read-modify-write. The in-memory access token
  /// belonged to the old seal and is dropped: the next read asks Connect,
  /// which answers a still-fresh sealed token without rotating it again.
  Future<void> adoptRotatedSeal(
    ForgeHost forge,
    String userId,
    String newSeal, {
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null || newSeal.isEmpty) {
      return;
    }
    final key = UserCredentialsStore.forgeKey(
      forge,
      userId,
      workspaceId: workspaceId,
    );
    while (_refreshing.isRunning(key)) {
      await _refreshing.run(key, () async => null);
    }
    final stored = await users.forgeToken(
      userId,
      forge,
      workspaceId: workspaceId,
    );
    if (stored == null || !stored.isSealed || stored.seal == newSeal) {
      return;
    }
    await users.setForgeToken(
      userId,
      forge,
      stored.copyWith(seal: newSeal),
      workspaceId: workspaceId,
    );
    _memory.remove(key);
  }

  /// Stores a credential minted by a sign-in. Sealed credentials keep their
  /// access token in memory only.
  Future<void> storeSignIn(
    ForgeHost forge,
    String userId,
    ProviderToken token, {
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null) {
      return;
    }
    await users.setForgeToken(userId, forge, token, workspaceId: workspaceId);
    final key = UserCredentialsStore.forgeKey(
      forge,
      userId,
      workspaceId: workspaceId,
    );
    if (token.isSealed && token.accessToken.isNotEmpty) {
      _memory[key] = token;
    } else {
      _memory.remove(key);
    }
    _invalidate(forge, userId, workspaceId: workspaceId);
  }

  /// Pasted tokens are for GitLab and Bitbucket only. GitHub is sign-in only.
  @override
  Future<ForgeConnection> setToken(
    ForgeHost forge,
    String token, {
    String? userId,
    String? workspaceId,
  }) async {
    if (forge == ForgeHost.github) {
      throw const ValidationException(
        'GitHub uses sign-in only. Sign in to GitHub instead of pasting a '
        'token.',
      );
    }
    final owner = userId ?? await _serverOwnerUserId?.call();
    if (owner == null) {
      throw StateError('Cannot store a forge token without a user.');
    }
    await _users?.setForgeToken(
      owner,
      forge,
      ProviderToken(accessToken: token, source: ForgeCredentialSource.settings),
      workspaceId: workspaceId,
    );
    _invalidate(forge, owner, workspaceId: workspaceId);
    return _probedConnection(forge, userId: owner, workspaceId: workspaceId);
  }

  @override
  Future<void> clearToken(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    final owner = userId ?? await _serverOwnerUserId?.call();
    if (owner == null) {
      return;
    }
    await _users?.clearForgeToken(owner, forge, workspaceId: workspaceId);
    _memory.remove(
      UserCredentialsStore.forgeKey(forge, owner, workspaceId: workspaceId),
    );
    _invalidate(forge, owner, workspaceId: workspaceId);
  }

  @override
  Future<List<ForgeConnection>> connections({
    String? userId,
    String? workspaceId,
  }) async => [
    for (final forge in ForgeHost.supported)
      await _connectionFor(
        forge,
        userId: userId,
        workspaceId: workspaceId,
        probeViewer: false,
      ),
  ];

  /// [forge]'s connection re-probed against the forge, refreshing the cached
  /// viewer identity.
  Future<ForgeConnection> _probedConnection(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    _viewerCache.remove(_cacheKey(forge, userId, workspaceId: workspaceId));
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
    final credential = await _credentialFor(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (credential == null || credential.accessToken.isEmpty) {
      return '';
    }
    if (credential.accountLogin.isNotEmpty) {
      return _viewerCache[key] = credential.accountLogin;
    }
    final probed = await _viewerProbe?.call(forge, credential.accessToken);
    if (probed == null || probed.isEmpty) {
      return '';
    }
    return _viewerCache[key] = probed;
  }

  void _invalidate(ForgeHost forge, String userId, {String? workspaceId}) {
    _viewerCache.remove(_cacheKey(forge, userId, workspaceId: workspaceId));
    _viewerCache.remove(_cacheKey(forge, userId));
    _changes.add(
      ForgeCredentialChange(
        forge: forge,
        userId: userId,
        workspaceId: workspaceId,
      ),
    );
  }

  final StreamController<ForgeCredentialChange> _changes =
      StreamController.broadcast(sync: true);

  /// Every stored credential change: a sign-in, a disconnect, a credential
  /// cleared because it can never work again. Caches keyed on who signed in
  /// as what (the PR bridge's account directory) drop their entry on it.
  Stream<ForgeCredentialChange> get changes => _changes.stream;

  Future<ProviderToken?> _credentialFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      return personCredential(forge, userId, workspaceId: workspaceId);
    }
    final token = await tokenFor(forge, workspaceId: workspaceId);
    return token == null
        ? null
        : ProviderToken(
            accessToken: token,
            source: ForgeCredentialSource.environment,
          );
  }

  Future<ForgeConnection> _connectionFor(
    ForgeHost forge, {
    required String? userId,
    required bool probeViewer,
    String? workspaceId,
  }) async {
    final credential = await _credentialFor(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (credential == null || credential.accessToken.isEmpty) {
      final needsSignIn =
          userId != null &&
          (await storedCredential(forge, userId, workspaceId: workspaceId)) !=
              null;
      return needsSignIn
          ? ForgeConnection(
              forge: forge,
              authenticated: false,
              source: ForgeCredentialSource.none,
              error: '${forge.displayName} is unreachable right now.',
            )
          : ForgeConnection.disconnected(forge);
    }
    final key = _cacheKey(forge, userId, workspaceId: workspaceId);
    var username = credential.accountLogin;
    if (username.isEmpty) {
      username = probeViewer
          ? (await _viewerProbe?.call(forge, credential.accessToken) ?? '')
          : (_viewerCache[key] ?? '');
      if (probeViewer && username.isNotEmpty) {
        _viewerCache[key] = username;
      }
    }
    if (probeViewer && username.isEmpty) {
      return ForgeConnection(
        forge: forge,
        authenticated: false,
        source: credential.source,
        error: '${forge.displayName} rejected the stored credential.',
      );
    }
    return ForgeConnection(
      forge: forge,
      authenticated: true,
      username: username,
      source: credential.source,
    );
  }

  /// One user's own credential, refreshed in place when it has expired.
  Future<ProviderToken?> _userLane(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null) {
      return null;
    }
    final key = UserCredentialsStore.forgeKey(
      forge,
      userId,
      workspaceId: workspaceId,
    );
    final stored = await users.forgeToken(
      userId,
      forge,
      workspaceId: workspaceId,
    );
    if (stored == null) {
      _memory.remove(key);
      return null;
    }
    if (forge == ForgeHost.github && !isGitHubSignIn(stored)) {
      // Anything that is not a GitHub App sign-in — a pasted token, an
      // OAuth-app grant — is not a credential this server accepts.
      await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
      _memory.remove(key);
      _invalidate(forge, userId, workspaceId: workspaceId);
      return null;
    }
    if (stored.isSealed) {
      switch (sealStandingOf(
        sealInstallId: stored.sealInstallId,
        currentInstallId: await currentSealInstallId?.call(
          stored.connectOrigin,
        ),
      )) {
        case SealStanding.parked:
          _memory.remove(key);
          return null;
        case SealStanding.dead:
          await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
          _memory.remove(key);
          _invalidate(forge, userId, workspaceId: workspaceId);
          return null;
        case SealStanding.usable:
          break;
      }
      final live = _memory[key];
      if (live != null && live.seal == stored.seal && !live.isExpired) {
        return live;
      }
    } else if (!stored.isExpired) {
      return stored;
    }
    if (!stored.canRefresh) {
      await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
      _invalidate(forge, userId, workspaceId: workspaceId);
      return null;
    }
    return _refreshing.run(
      key,
      () => _refresh(key, forge, userId, workspaceId: workspaceId),
    );
  }

  /// Renews [userId]'s credential, inside the single flight for [key].
  ///
  /// The stored credential is re-read here, not handed in: a caller that read
  /// it just before an earlier flight rotated the single-use refresh token
  /// would otherwise spend the dead one, get `invalid_grant`, and sign the
  /// person out. Whatever an earlier flight already renewed is answered as
  /// is; only a credential that is still expired is refreshed.
  Future<ProviderToken?> _refresh(
    String key,
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    final users = _users!;
    final refresh = refreshUserToken;
    if (refresh == null) {
      return null;
    }
    var stored = await users.forgeToken(
      userId,
      forge,
      workspaceId: workspaceId,
    );
    if (stored == null) {
      _memory.remove(key);
      _unsaved.remove(key);
      return null;
    }
    final orphan = _unsaved.remove(key);
    if (orphan != null && stored.isSealed && orphan.parent == stored.seal) {
      try {
        await users.setForgeToken(
          userId,
          forge,
          orphan.token,
          workspaceId: workspaceId,
        );
      } on Object {
        _unsaved[key] = orphan;
        return orphan.token.isExpired ? null : orphan.token;
      }
      stored = orphan.token;
    }
    if (stored.isSealed) {
      final live = _memory[key];
      if (live != null && live.seal == stored.seal && !live.isExpired) {
        return live;
      }
    } else if (!stored.isExpired) {
      return stored;
    }
    if (!stored.canRefresh) {
      return null;
    }
    final RefreshOutcome outcome;
    try {
      outcome = await refresh(userId, forge, stored, workspaceId: workspaceId);
    } on Object {
      return null;
    }
    // Compare-and-set: a sign-out or sign-in that landed while the refresh
    // was in the air wins; the renewal of the older grant is dropped.
    final current = await users.forgeToken(
      userId,
      forge,
      workspaceId: workspaceId,
    );
    if (current == null) {
      _memory.remove(key);
      return null;
    }
    if (!_sameGrant(current, stored)) {
      return current.isSealed || current.isExpired ? null : current;
    }
    switch (outcome) {
      case Refreshed(:final token):
        if (token.isSealed) {
          _memory[key] = token;
        }
        try {
          await users.setForgeToken(
            userId,
            forge,
            token,
            workspaceId: workspaceId,
          );
        } on Object catch (e) {
          if (!token.isSealed) {
            rethrow;
          }
          // The parent seal is spent upstream: keep the only copy.
          _unsaved[key] = (parent: stored.seal, token: token);
          CcHostLog.warning(
            'forge: a renewed ${forge.name} sign-in could not be saved; kept '
            'in memory and saved on the next use ($e)',
          );
        }
        return token;
      case RefreshRejected():
        await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
        _memory.remove(key);
        _invalidate(forge, userId, workspaceId: workspaceId);
        return null;
      case RefreshUnavailable():
        // Keep the credential: the next call tries again.
        return null;
    }
  }

  static bool _sameGrant(ProviderToken a, ProviderToken b) => a.isSealed
      ? a.seal == b.seal
      : a.refreshToken == b.refreshToken && a.accessToken == b.accessToken;

  /// Whether [token] is a GitHub App sign-in this server accepts: a Connect
  /// seal, or an own-app user token (`ghu_`, expiring, refreshable) that
  /// names the app it came from.
  static bool isGitHubSignIn(ProviderToken token) => token.isSealed
      ? token.source == ForgeCredentialSource.connect
      : token.source == ForgeCredentialSource.oauth &&
            token.appId.isNotEmpty &&
            token.accessToken.startsWith('ghu_') &&
            token.expiresAt != null &&
            token.refreshToken.isNotEmpty;

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
