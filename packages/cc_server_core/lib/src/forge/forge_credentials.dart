import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, ValidationException;
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/utils/single_flight.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart'
    show SealStanding, sealStandingOf;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_person_token_check.dart';
import 'package:cc_server_core/src/forge/forge_viewer_probe.dart'
    show ForgeViewer;
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';

/// Asks a forge who the bearer of [token] is, for the connection's username
/// and the account's durable id. Returns null when the token is rejected or
/// the call fails.
typedef ViewerProbe =
    Future<ForgeViewer?> Function(ForgeHost forge, String token);

/// Renews an expired credential. Implemented by the sign-in service, which
/// knows whether the grant is an own-app OAuth token or a Connect seal.
typedef ProviderTokenRefresh =
    Future<RefreshOutcome> Function(
      String userId,
      ForgeHost forge,
      ProviderToken expired, {
      String? workspaceId,
    });

/// The current install id for the Connect that sealed [connectOrigin], as
/// the credential's slot sees it ([workspaceId], null for the server-wide
/// slot), or null when that slot's Connect is off or another one.
typedef SealInstallIdLookup =
    Future<String?> Function(String connectOrigin, {String? workspaceId});

/// The OAuth client id of the GitHub App a slot's own-App sign-ins come from
/// right now ([workspaceId] null for the server-wide slot), or null when that
/// slot has no own App.
typedef GitHubClientIdLookup = Future<String?> Function({String? workspaceId});

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
/// GitLab and Bitbucket stay token-based: a person's pasted token, theirs
/// only, one per forge and used in every workspace on the server (they have
/// no workspace slot). Work no person is doing on those forges never comes
/// here either: it
/// uses the repository's or workspace's automation token
/// (`ForgeAutomationTokens`), a project/group or repository/workspace access
/// token that shows as a bot. There is no accountable-person, server-owner
/// or environment fallback.
///
/// Connect-sealed credentials keep only the seal on disk; their access
/// tokens live in [_memory] for this process. Refreshes are single-flight per
/// `(workspace, user, forge)` because GitHub refresh tokens are single-use,
/// and only a [RefreshRejected] outcome clears a credential.
class ForgeCredentials implements ForgeTokenStore, ForgeConnectionView {
  /// Creates a [ForgeCredentials].
  ForgeCredentials({this._users, this._viewerProbe, this._personTokenCheck});

  final UserCredentialsStore? _users;

  /// Whether a workspace currently keeps GitHub sign-ins in its own slot
  /// (`ConnectRoute.workspaceSlot`): its sign-in target differs from the
  /// server's. Assigned once the Connect settings exist; unset, every
  /// workspace shares the person's global sign-in.
  Future<bool> Function(String workspaceId)? workspaceOwnsSlot;
  final ViewerProbe? _viewerProbe;

  /// Decides, before anything is stored, whether a pasted token may be a
  /// person's own: one the forge answers for as that person, with the
  /// scopes the features need, not expired. Required to store a token.
  final PersonTokenCheck? _personTokenCheck;

  /// Refreshes an expired credential. Set by the sign-in service after
  /// construction (each needs the other).
  ProviderTokenRefresh? refreshUserToken;

  /// Resolves the install id a sealed credential must carry. Set once the
  /// Connect client exists.
  SealInstallIdLookup? currentSealInstallId;

  /// Resolves the App an own-App GitHub sign-in must come from. Set once the
  /// App settings exist; unset, any App's sign-in is accepted.
  GitHubClientIdLookup? currentGitHubClientId;

  /// Slots already announced (on [changes]) as holding a sign-in from
  /// another App than the current one, with that grant's App, so the
  /// announcement is made once per grant rather than per read.
  final Map<String, String> _foreignAnnounced = {};

  /// Access tokens of sealed credentials, by storage key. Never persisted.
  final Map<String, ProviderToken> _memory = {};

  /// A renewed grant whose write failed, with the grant it replaced (its
  /// seal, or its refresh token). The renewal spent that parent upstream
  /// (Connect rotates the seal, GitHub's refresh tokens are single-use), so
  /// this is the only valid copy: it is served from memory and written again
  /// on the next call, never dropped while the stored grant is its parent.
  final Map<String, ({String parent, ProviderToken token})> _unsaved = {};

  /// In-flight refreshes, by storage key.
  final SingleFlight<String, ProviderToken?> _refreshing = SingleFlight();

  /// Cached viewer identity per (user, forge, slot).
  final Map<String, String> _viewerCache = {};

  static String _cacheKey(
    ForgeHost forge,
    String? userId, {
    String? workspaceId,
  }) => '${workspaceId ?? ''}:${userId ?? ''}:${forge.wire}';

  /// The credential for [forge]: [userId]'s own when given, and nothing
  /// without a user on any forge. Automation on GitHub mints one-repository
  /// tokens (`GitHubClients.mintScoped`/`forOwner`); on GitLab and Bitbucket
  /// it uses the repository's automation token (`ForgeAutomationTokens`).
  @override
  Future<String?> tokenFor(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return personToken(forge, userId, workspaceId: workspaceId);
  }

  /// [userId]'s own credential for [forge], or null when they have none.
  ///
  /// GitHub with a [workspaceId]: the workspace's own slot exactly while it
  /// owns one (its sign-in target differs from the server's), else the
  /// person's global sign-in; never both. GitLab and Bitbucket: the person's
  /// one pasted token, the same in every workspace.
  Future<String?> personToken(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async => (await personCredential(
    forge,
    userId,
    workspaceId: workspaceId,
  ))?.accessToken;

  /// [userId]'s own [forge] token for something they are doing themselves,
  /// or [NeedsSignInException] (lane: the forge wire for GitLab and
  /// Bitbucket, `github` for GitHub) when they have no usable one. Never
  /// anyone else's token.
  Future<String> requirePersonToken(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    final token = userId.isEmpty
        ? null
        : await personToken(forge, userId, workspaceId: workspaceId);
    if (token == null || token.isEmpty) {
      throw NeedsSignInException(forge.wire, signInRequiredMessage(forge));
    }
    return token;
  }

  /// What a person is told when they act on [forge] without a sign-in.
  static String signInRequiredMessage(ForgeHost forge) =>
      forge == ForgeHost.github
      ? 'Sign in to GitHub to do this as yourself.'
      : 'Connect your ${forge.displayName} account to do this as yourself.';

  /// Like [personToken], with the credential's identity fields.
  Future<ProviderToken?> personCredential(
    ForgeHost forge,
    String userId, {
    String? workspaceId,
  }) async {
    if (!forge.isSupported || userId.isEmpty) {
      return null;
    }
    return _userLane(
      forge,
      userId,
      workspaceId: await slotFor(forge, workspaceId: workspaceId),
    );
  }

  /// The slot a person's [forge] credential in effect for [workspaceId]
  /// lives in: the workspace id, or null for the global slot.
  ///
  /// GitHub follows the workspace's sign-in target: its own slot exactly
  /// while it owns one ([workspaceOwnsSlot]), else the global sign-in, so a
  /// grant left in a slot the workspace no longer owns is never read. A
  /// token-only forge (GitLab, Bitbucket) always uses the global slot.
  Future<String?> slotFor(ForgeHost forge, {String? workspaceId}) async {
    if (workspaceId == null || workspaceId.isEmpty) {
      return null;
    }
    // A pasted token is not issued by an app, so nothing ties it to one
    // workspace's sign-in target: GitLab and Bitbucket have no workspace slot.
    if (forge != ForgeHost.github) {
      return null;
    }
    return await _ownsSlot(workspaceId) ? workspaceId : null;
  }

  /// Whether [workspaceId] keeps GitHub sign-ins in its own slot now.
  Future<bool> _ownsSlot(String workspaceId) async =>
      await workspaceOwnsSlot?.call(workspaceId) ?? false;

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
    final slot = await slotFor(forge, workspaceId: workspaceId);
    final token = await users.forgeToken(userId, forge, workspaceId: slot);
    if (token == null ||
        (forge == ForgeHost.github &&
            await _gitHubUnusable(userId, token, slot) != null)) {
      return null;
    }
    return (token: token, workspaceId: slot);
  }

  /// Deletes every member's [forge] credential kept in [workspaceId]'s own
  /// slot and returns what was removed, so the caller can revoke each grant
  /// upstream. Run when the workspace's sign-in target changes: those grants
  /// came from a service the workspace no longer signs in with.
  /// Only credentials [where] accepts are removed, when it is given.
  Future<List<({String userId, ProviderToken token})>> clearWorkspaceSlot(
    ForgeHost forge,
    String workspaceId, {
    bool Function(ProviderToken token)? where,
  }) async {
    final users = _users;
    if (users == null || workspaceId.isEmpty) {
      return const [];
    }
    final removed = await users.clearWorkspaceForgeTokens(
      forge,
      workspaceId,
      where: where,
    );
    for (final entry in removed) {
      final key = UserCredentialsStore.forgeKey(
        forge,
        entry.userId,
        workspaceId: workspaceId,
      );
      _memory.remove(key);
      _unsaved.remove(key);
      _invalidate(forge, entry.userId, workspaceId: workspaceId);
    }
    await users.clearWorkspaceForgeLapses(forge, workspaceId);
    return removed;
  }

  /// Persists a rotated seal handed back by Connect on the way through
  /// another call (a scope mint that refreshed the parent token). A write
  /// that fails keeps the new seal in memory, written again on the next use.
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
    _memory.remove(key);
    final adopted = stored.copyWith(seal: newSeal);
    try {
      await users.setForgeToken(userId, forge, adopted, workspaceId: workspaceId);
    } on Object catch (e) {
      // Connect spent the parent seal: keep the only copy of the new one.
      _unsaved[key] = (parent: stored.seal, token: adopted);
      _persistFailed(forge, userId, workspaceId, e);
    }
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
    await users.clearForgeLapse(userId, forge, workspaceId: workspaceId);
    _invalidate(forge, userId, workspaceId: workspaceId);
  }

  /// Pasted tokens are for GitLab and Bitbucket only. GitHub is sign-in only.
  ///
  /// The token is the person's one credential for [forge] on this server:
  /// it replaces the previous one and is used in every workspace.
  @override
  Future<ForgeConnection> setToken(
    ForgeHost forge,
    String token, {
    String? userId,
  }) async {
    if (forge == ForgeHost.github) {
      throw const ValidationException(
        'GitHub uses sign-in only. Sign in to GitHub instead of pasting a '
        'token.',
      );
    }
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot store a forge token without a user.');
    }
    final check = _personTokenCheck;
    if (check == null) {
      throw StateError('Cannot store a forge token without a token check.');
    }
    // Asked before anything is stored: a token the forge does not answer
    // for as this person (a bot's, an access token, a refused, too narrow or
    // expired one) never lands in a person's slot. The answer names who the
    // token belongs to (the login PR authors are matched by, and the
    // account's durable id) and when it lapses; both travel with it.
    // An empty token clears the slot (the store never keeps one).
    final verdict = token.isEmpty ? null : await check(forge, token);
    if (verdict case PersonTokenRefused(:final reason, :final message)) {
      throw ValidationException(message, code: reason.wire);
    }
    final accepted = verdict as PersonTokenAccepted?;
    await _users?.setForgeToken(
      userId,
      forge,
      ProviderToken(
        accessToken: token,
        source: ForgeCredentialSource.settings,
        accountLogin: accepted?.viewer.login ?? '',
        accountId: accepted?.viewer.id ?? '',
        expiresAt: accepted?.expiresAt,
      ),
    );
    _memory.remove(UserCredentialsStore.forgeKey(forge, userId));
    await _users?.clearForgeLapse(userId, forge);
    _invalidate(forge, userId);
    return _probedConnection(forge, userId: userId);
  }

  /// Clears [userId]'s credential in effect for [forge] in [workspaceId]:
  /// the workspace's own when one is in effect there, else the global one.
  /// Answers the scope it cleared, or null when nothing was stored.
  @override
  Future<ForgeCredentialScope?> clearToken(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    final users = _users;
    if (users == null || userId == null || userId.isEmpty) {
      return null;
    }
    final slot = await slotFor(forge, workspaceId: workspaceId);
    final key = UserCredentialsStore.forgeKey(forge, userId, workspaceId: slot);
    final present = await users.hasForgeToken(userId, forge, workspaceId: slot);
    await users.clearForgeToken(userId, forge, workspaceId: slot);
    await users.clearForgeLapse(userId, forge, workspaceId: slot);
    _memory.remove(key);
    _unsaved.remove(key);
    _invalidate(forge, userId, workspaceId: slot);
    if (!present) {
      return null;
    }
    return slot == null
        ? ForgeCredentialScope.global
        : ForgeCredentialScope.workspace;
  }

  @override
  Future<List<ForgeConnection>> connections({
    String? userId,
    String? workspaceId,
  }) async => [
    for (final forge in ForgeHost.supported)
      await connection(forge, userId: userId, workspaceId: workspaceId),
  ];

  @override
  Future<ForgeConnection> connection(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) => _connectionFor(
    forge,
    userId: userId,
    workspaceId: workspaceId,
    probeViewer: false,
  );

  /// [forge]'s connection re-probed against the forge, refreshing the cached
  /// viewer identity.
  Future<ForgeConnection> _probedConnection(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    _viewerCache.remove(
      _cacheKey(
        forge,
        userId,
        workspaceId: await _viewerSlot(forge, userId, workspaceId),
      ),
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
    if (userId == null || userId.isEmpty) {
      // Nobody's login: there is no credential without a person, and an
      // entry cached under no one would never be invalidated by anyone's
      // sign-in or sign-out.
      return '';
    }
    final key = _cacheKey(
      forge,
      userId,
      workspaceId: await _viewerSlot(forge, userId, workspaceId),
    );
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
    final probed = (await _viewerProbe?.call(
      forge,
      credential.accessToken,
    ))?.login;
    if (probed == null || probed.isEmpty) {
      return '';
    }
    return _viewerCache[key] = probed;
  }

  /// [userId]'s account on [forge] in effect for [workspaceId]: the login
  /// [viewerLogin] answers plus the forge's durable account id (GitHub and
  /// GitLab numeric id, Bitbucket `account_id`; '' when unknown), or null
  /// when they hold no usable credential there. The id travels with a
  /// credential stored with one; any other is asked of the forge, uncached
  /// (only the rare approval check needs it).
  Future<ForgeViewer?> viewerAccount(
    ForgeHost forge, {
    String? userId,
    String? workspaceId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final credential = await _credentialFor(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    if (credential == null || credential.accessToken.isEmpty) {
      return null;
    }
    if (credential.accountLogin.isNotEmpty && credential.accountId.isNotEmpty) {
      return (login: credential.accountLogin, id: credential.accountId);
    }
    final probed = await _viewerProbe?.call(forge, credential.accessToken);
    if (probed != null && probed.login.isNotEmpty) {
      return probed;
    }
    final login = await viewerLogin(
      forge,
      userId: userId,
      workspaceId: workspaceId,
    );
    return login.isEmpty ? null : (login: login, id: '');
  }

  /// The slot a viewer identity is cached under: the credential's slot for
  /// a person, so a workspace that stops (or starts) owning a slot never
  /// serves the other slot's login.
  Future<String?> _viewerSlot(
    ForgeHost forge,
    String? userId,
    String? workspaceId,
  ) async => userId == null || userId.isEmpty
      ? workspaceId
      : slotFor(forge, workspaceId: workspaceId);

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
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return personCredential(forge, userId, workspaceId: workspaceId);
  }

  Future<ForgeConnection> _connectionFor(
    ForgeHost forge, {
    required String? userId,
    required bool probeViewer,
    String? workspaceId,
  }) async {
    final person = userId != null && userId.isNotEmpty;
    final slot = person
        ? await slotFor(forge, workspaceId: workspaceId)
        : workspaceId;
    final scope = slot == null || slot.isEmpty
        ? ForgeCredentialScope.global
        : ForgeCredentialScope.workspace;
    final ProviderToken? credential;
    if (person) {
      credential = forge.isSupported
          ? await _userLane(forge, userId, workspaceId: slot)
          : null;
    } else {
      credential = await _credentialFor(forge, workspaceId: workspaceId);
    }
    if (credential == null || credential.accessToken.isEmpty) {
      if (!person) {
        return ForgeConnection.disconnected(forge);
      }
      return _unusableConnection(forge, userId, slot: slot, scope: scope);
    }
    final key = _cacheKey(forge, userId, workspaceId: slot);
    var username = credential.accountLogin;
    if (username.isEmpty) {
      username = probeViewer
          ? ((await _viewerProbe?.call(forge, credential.accessToken))?.login ??
                '')
          : (_viewerCache[key] ?? '');
      if (probeViewer && username.isNotEmpty) {
        _viewerCache[key] = username;
      }
    }
    if (probeViewer && username.isEmpty) {
      return ForgeConnection(
        forge: forge,
        status: ForgeConnectionStatus.needsSignIn,
        scope: scope,
        source: credential.source,
        error: '${forge.displayName} rejected the stored credential.',
      );
    }
    return ForgeConnection(
      forge: forge,
      status: ForgeConnectionStatus.connected,
      scope: scope,
      username: username,
      accountId: credential.accountId,
      source: credential.source,
      // A grant that renews itself never lapses for the person; a pasted
      // token does, on its date.
      expiresAt: credential.canRefresh ? null : credential.expiresAt,
    );
  }

  /// Why [userId] has no usable [forge] credential in [slot]: a sealed grant
  /// parked because the slot's sign-in service changed (`paused`), a kept
  /// grant whose renewal failed for now (`unreachable`), one cleared because
  /// it was refused or expired upstream (`needs_sign_in`), or nothing at all.
  Future<ForgeConnection> _unusableConnection(
    ForgeHost forge,
    String userId, {
    required String? slot,
    required ForgeCredentialScope scope,
  }) async {
    final stored = await _users?.forgeToken(userId, forge, workspaceId: slot);
    final unusable = stored != null && forge == ForgeHost.github
        ? await _gitHubUnusable(userId, stored, slot)
        : null;
    if (unusable != null) {
      return ForgeConnection(
        forge: forge,
        status: ForgeConnectionStatus.needsSignIn,
        scope: scope,
        username: stored!.accountLogin,
        accountId: stored.accountId,
        error: unusable,
      );
    }
    if (stored != null) {
      final parked =
          stored.isSealed &&
          sealStandingOf(
                sealInstallId: stored.sealInstallId,
                currentInstallId: await currentSealInstallId?.call(
                  stored.connectOrigin,
                  workspaceId: slot,
                ),
              ) ==
              SealStanding.parked;
      return ForgeConnection(
        forge: forge,
        status: parked
            ? ForgeConnectionStatus.paused
            : ForgeConnectionStatus.unreachable,
        scope: scope,
        username: stored.accountLogin,
        accountId: stored.accountId,
        source: stored.source,
        error: parked
            ? 'This sign-in was made through a sign-in service this '
                  'workspace no longer uses.'
            : '${forge.displayName} is unreachable right now.',
      );
    }
    final lapsed = await _users?.forgeLapse(userId, forge, workspaceId: slot);
    if (lapsed != null) {
      return ForgeConnection(
        forge: forge,
        status: ForgeConnectionStatus.needsSignIn,
        scope: scope,
        username: lapsed,
        error: 'The ${forge.displayName} sign-in expired or was revoked.',
      );
    }
    return ForgeConnection(
      forge: forge,
      status: ForgeConnectionStatus.notConnected,
      scope: scope,
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
    if (forge == ForgeHost.github &&
        await _gitHubUnusable(userId, stored, workspaceId) != null) {
      _memory.remove(key);
      return null;
    }
    if (stored.isSealed) {
      switch (sealStandingOf(
        sealInstallId: stored.sealInstallId,
        currentInstallId: await currentSealInstallId?.call(
          stored.connectOrigin,
          workspaceId: workspaceId,
        ),
      )) {
        case SealStanding.parked:
          _memory.remove(key);
          return null;
        case SealStanding.dead:
          await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
          _memory.remove(key);
          await _lapse(forge, userId, stored, workspaceId: workspaceId);
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
      await _lapse(forge, userId, stored, workspaceId: workspaceId);
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
    if (orphan != null && orphan.parent == _grantId(stored)) {
      try {
        await users.setForgeToken(
          userId,
          forge,
          orphan.token,
          workspaceId: workspaceId,
        );
      } on Object catch (e) {
        _persistFailed(forge, userId, workspaceId, e);
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
    } on Object catch (e) {
      // Kept, like an unreachable provider: the next use tries again.
      forgeAudit(ForgeAuditEvent.forgeCredentialRefreshFailed, {
        'forge': forge.wire,
        'user_id': userId,
        'workspace_id': workspaceId,
        'reason': 'refresh_threw',
        'error': e.runtimeType.toString(),
      });
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
          // The parent is spent upstream: keep the only valid copy.
          _unsaved[key] = (parent: _grantId(stored), token: token);
          _persistFailed(forge, userId, workspaceId, e);
        }
        return token;
      case RefreshRejected():
        forgeAudit(ForgeAuditEvent.forgeCredentialRefreshFailed, {
          'forge': forge.wire,
          'user_id': userId,
          'workspace_id': workspaceId,
          'reason': 'refresh_rejected',
        });
        await users.clearForgeToken(userId, forge, workspaceId: workspaceId);
        _memory.remove(key);
        await _lapse(forge, userId, stored, workspaceId: workspaceId);
        _invalidate(forge, userId, workspaceId: workspaceId);
        return null;
      case RefreshUnavailable():
        // Keep the credential: the next call tries again.
        forgeAudit(ForgeAuditEvent.forgeCredentialRefreshFailed, {
          'forge': forge.wire,
          'user_id': userId,
          'workspace_id': workspaceId,
          'reason': 'provider_unavailable',
        });
        return null;
    }
  }

  /// Remembers, with the credential record, that [userId]'s [forge]
  /// credential in the slot was cleared because its grant can never work
  /// again: the connection reads `needs_sign_in` (a restart included) until
  /// they sign in again, paste a new token or disconnect.
  Future<void> _lapse(
    ForgeHost forge,
    String userId,
    ProviderToken cleared, {
    String? workspaceId,
  }) async {
    try {
      await _users?.markForgeLapsed(
        userId,
        forge,
        cleared.accountLogin,
        workspaceId: workspaceId,
      );
    } on Object catch (e) {
      // The credential is already gone; without the marker the connection
      // reads `not_connected`, which asks for the same sign-in. The error's
      // type only: its text may carry the credentials file path or token.
      CcHostLog.warning(
        'forge: could not record a lapsed ${forge.wire} sign-in for $userId '
        '(${e.runtimeType})',
      );
    }
  }

  /// Why [token] in [userId]'s GitHub [slot] is not a usable sign-in, or
  /// null when it is: not a GitHub App sign-in at all, missing the account
  /// it names, or made with another App than the one the slot signs in with
  /// now. Nothing is cleared: the grant is simply not used, and the person
  /// signs in again. The first time a slot's grant is found to belong to
  /// another App, [changes] says so, so caches built on it are dropped.
  Future<String?> _gitHubUnusable(
    String userId,
    ProviderToken token,
    String? slot,
  ) async {
    if (!isGitHubSignIn(token)) {
      return 'This is not a GitHub App sign-in.';
    }
    final lookup = currentGitHubClientId;
    if (token.isSealed || lookup == null) {
      return null;
    }
    final current = await lookup(workspaceId: slot);
    final key = UserCredentialsStore.forgeKey(
      ForgeHost.github,
      userId,
      workspaceId: slot,
    );
    if (current != null && current == token.appId) {
      _foreignAnnounced.remove(key);
      return null;
    }
    if (_foreignAnnounced[key] != token.appId) {
      _foreignAnnounced[key] = token.appId;
      _invalidate(ForgeHost.github, userId, workspaceId: slot);
    }
    return 'This sign-in was made with another GitHub App than the one this '
        'workspace uses now.';
  }

  /// What a renewal spends: a sealed grant's seal, an own-App grant's
  /// refresh token.
  static String _grantId(ProviderToken token) =>
      token.isSealed ? token.seal : token.refreshToken;

  static void _persistFailed(
    ForgeHost forge,
    String userId,
    String? workspaceId,
    Object error,
  ) => forgeAudit(ForgeAuditEvent.grantPersistFailed, {
    'forge': forge.wire,
    'user_id': userId,
    'workspace_id': workspaceId,
    'kept_in_memory': true,
    'error': error.runtimeType.toString(),
  });

  static bool _sameGrant(ProviderToken a, ProviderToken b) => a.isSealed
      ? a.seal == b.seal
      : a.refreshToken == b.refreshToken && a.accessToken == b.accessToken;

  /// Whether [token] is a GitHub App sign-in this server accepts: a Connect
  /// seal, or an own-app user token (`ghu_`, expiring, refreshable) that
  /// names the app it came from. Either names the account it signed in
  /// (login and numeric id): a grant without them is not a usable sign-in.
  static bool isGitHubSignIn(ProviderToken token) =>
      token.accountLogin.isNotEmpty &&
      (int.tryParse(token.accountId) ?? 0) > 0 &&
      (token.isSealed
          ? token.source == ForgeCredentialSource.connect
          : token.source == ForgeCredentialSource.oauth &&
                token.appId.isNotEmpty &&
                token.accessToken.startsWith('ghu_') &&
                token.expiresAt != null &&
                token.refreshToken.isNotEmpty);
}
