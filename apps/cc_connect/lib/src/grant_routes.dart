import 'dart:async';
import 'dart:convert';

import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/provider_github.dart';
import 'package:cc_connect/src/provider_google.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/rate_limiter.dart' show BoundedPool;
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/state_store.dart' show StateLease;
import 'package:cc_connect_core/cc_connect_core.dart';

const ConnectException _denied = ConnectException(
  ConnectErrorCode.accessDenied,
);
const ConnectException _signIn = ConnectException(ConnectErrorCode.needsSignIn);
const ConnectException _invalid = ConnectException(
  ConnectErrorCode.invalidRequest,
);
const ConnectException _unavailable = ConnectException(
  ConnectErrorCode.providerUnavailable,
);

/// Below this much parent-token lifetime, `/v1/github/scope` refreshes the
/// parent first (a scoped child never outlives its parent).
const Duration githubParentMinRemaining = Duration(minutes: 65);

/// How long a rotation lock lives past its last renewal. The holder renews
/// it while its refresh runs, so this only bounds how long a holder that died
/// mid-rotation keeps the seal locked.
const Duration rotationLockTtl = Duration(seconds: 30);

/// The served GitHub lane, resolved once per request.
typedef GitHubLane = (GitHubLaneConfig, GitHubCredentials, GitHubApi);

/// The served Slack lane, resolved once per request.
typedef SlackLane = (SlackLaneConfig, SlackCredentials, SlackApi);

/// A usable GitHub grant for one request.
final class GitHubGrant {
  /// Creates the grant.
  const GitHubGrant(this.opened, this.seal, this.updatedSeal);

  /// The opened seal now in effect.
  final OpenedSeal opened;

  /// The seal now in effect.
  final String seal;

  /// The seal the server must persist, when it changed during the request.
  final String updatedSeal;

  /// The parent `ghu_`.
  String get parent => opened.text('access');

  /// When [parent] expires.
  DateTime get parentExpiresAt =>
      opened.time('access_expires_at') ?? DateTime.utc(1970);

  /// The person's numeric GitHub id.
  int get accountId => int.tryParse(opened.header.accountId) ?? 0;
}

/// What an attempt to bind a server to an installation found.
enum AuthorizeOutcome {
  /// The server is now bound.
  bound,

  /// GitHub does not report the installation for this person and app.
  notInstalled,

  /// The installation is suspended.
  suspended,

  /// The person may not authorize servers on it.
  notAdmin,
}

/// Map a seal payload's fields into a fresh [SealedGrant] wire body.
Map<String, Object?> _grantBody({
  required String seal,
  required OpenedSeal opened,
  String accountLogin = '',
  String teamName = '',
  String authedUserId = '',
}) {
  final expires = opened.time('access_expires_at');
  final access = opened.text('access');
  if (access.isEmpty || expires == null) {
    throw _unavailable;
  }
  final header = opened.header;
  final slack = header.provider == ConnectProvider.slack;
  return SealedGrant(
    seal: seal,
    accessToken: access,
    expiresAt: expires,
    accountId: header.accountId,
    accountLogin: accountLogin,
    appId: header.appId,
    teamId: slack ? header.accountId : '',
    teamName: teamName,
    botUserId: slack ? opened.text('bot_user_id') : '',
    botId: slack ? opened.text('bot_id') : '',
    authedUserId: authedUserId,
  ).toJson();
}

/// The GitHub seal payload for [tokens].
Map<String, Object?> githubSealPayload(GitHubTokens tokens) => {
  'refresh': tokens.refresh,
  'access': tokens.access,
  'access_expires_at': tokens.accessExpiresAt.toUtc().toIso8601String(),
  'refresh_expires_at': tokens.refreshExpiresAt?.toUtc().toIso8601String(),
};

/// The Slack seal payload for [grant].
Map<String, Object?> slackSealPayload(SlackBotGrant grant, String botId) => {
  'refresh': grant.refresh,
  'access': grant.access,
  'access_expires_at': grant.accessExpiresAt.toUtc().toIso8601String(),
  'team_id': grant.teamId,
  'bot_user_id': grant.botUserId,
  'bot_id': botId,
};

/// One sealed lane as a refresh sees it: what a seal must name to be opened
/// here, and how its grant is renewed.
final class _SealedLane {
  const _SealedLane({
    required this.provider,
    required this.appId,
    required this.minGeneration,
    required this.generation,
    required this.renew,
  });

  final ConnectProvider provider;
  final String appId;
  final int minGeneration;
  final int generation;
  final Future<(String, OpenedSeal)> Function(
    String seal,
    OpenedSeal opened,
    SealBinding binding,
  )
  renew;
}

/// `/v1/{github,google,slack}/refresh`, `/v1/github/scope`, the GitHub
/// install and authorization routes, and both revokes.
final class GrantRoutes {
  /// Creates the routes.
  GrantRoutes(this.ctx);

  /// The shared context.
  final ConnectContext ctx;

  static T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw _invalid;
    }
  }

  /// Refuses seals of a retired app or below the minimum generation.
  static void checkSealHeader(
    SealHeader header, {
    required ConnectProvider provider,
    required String appId,
    required int minGeneration,
  }) {
    if (header.provider != provider) {
      throw _denied;
    }
    if (header.appId != appId || header.generation < minGeneration) {
      throw _signIn;
    }
  }

  Future<(String, OpenedSeal)?> _replay(
    ConnectProvider provider,
    String seal,
    SealBinding binding,
  ) async {
    final newer = await ctx.state.get('handoff:${sealDigest(seal)}');
    if (newer == null) {
      return null;
    }
    final opened = await ctx.sealer.open(
      newer,
      provider: provider,
      binding: binding,
    );
    return (newer, opened);
  }

  /// Opens [seal] for [binding] — or, when a rotation already replaced it,
  /// the seal that rotation left in its handoff. The one place a route opens
  /// the seal it was handed; the flag is true for a replay.
  Future<(String, OpenedSeal, bool)> _openOrReplay(
    ConnectProvider provider,
    String seal,
    SealBinding binding,
  ) async {
    final replay = await _replay(provider, seal, binding);
    if (replay != null) {
      return (replay.$1, replay.$2, true);
    }
    return (
      seal,
      await ctx.sealer.open(seal, provider: provider, binding: binding),
      false,
    );
  }

  /// Rotates a single-use refresh token under a per-seal lease, and leaves a
  /// ciphertext-only handoff (`sha256(old) -> new`, 5 min) so a retry with
  /// the old seal after a dropped response replays the new one instead of
  /// failing on a spent refresh token.
  ///
  /// The lease ([StateLease], [rotationLockTtl]) is renewed while the
  /// rotation runs and released only by its holder: a holder that dies frees
  /// the seal within the TTL, and one whose lease lapsed never unlocks its
  /// successor. A request that finds the seal locked waits for the holder's
  /// handoff, and takes the lock itself once it is free.
  Future<(String, OpenedSeal)> _rotate({
    required ConnectProvider provider,
    required String oldSeal,
    required SealBinding binding,
    required int generation,
    required Future<
      ({String accountId, String appId, Map<String, Object?> payload})
    >
    Function()
    upstream,
  }) async {
    final digest = sealDigest(oldSeal);
    StateLease? lease;
    for (var waited = 0; lease == null; waited++) {
      lease = await StateLease.acquire(
        ctx.state,
        'lock:$digest',
        rotationLockTtl,
      );
      if (lease != null) {
        break;
      }
      if (waited >= 50) {
        throw _unavailable;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final replay = await _replay(provider, oldSeal, binding);
      if (replay != null) {
        return replay;
      }
    }
    try {
      // A rotation that finished between this request's first look and its
      // lock left a handoff: answer it rather than spend a dead token.
      final earlier = await _replay(provider, oldSeal, binding);
      if (earlier != null) {
        return earlier;
      }
      final ({String accountId, String appId, Map<String, Object?> payload})
      fresh;
      try {
        fresh = await upstream();
      } on ConnectException catch (error) {
        if (error.code == ConnectErrorCode.needsSignIn) {
          final replay = await _replay(provider, oldSeal, binding);
          if (replay != null) {
            return replay;
          }
        }
        rethrow;
      }
      final sealed = await ctx.sealer.seal(
        provider: provider,
        accountId: fresh.accountId,
        appId: fresh.appId,
        generation: generation,
        binding: binding,
        payload: fresh.payload,
      );
      await _leaveHandoff(provider, digest, sealed);
      return (sealed, OpenedSeal(ctx.sealer.header(sealed), fresh.payload));
    } finally {
      await lease.release();
    }
  }

  /// Leaves `sha256(old) -> new` for [sealHandoffTtl].
  ///
  /// The old refresh token is already spent, so the new seal is the only
  /// copy of the grant: a failed write must not fail the request and drop it.
  /// The answer carries the seal regardless; only a retry after a dropped
  /// answer loses its replay. Tried twice, then logged.
  Future<void> _leaveHandoff(
    ConnectProvider provider,
    String digest,
    String sealed,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await ctx.state.set('handoff:$digest', sealed, sealHandoffTtl);
        return;
      } on Object {
        // Retried once below.
      }
    }
    ctx.log.event('seal.handoff_unsaved', {'provider': provider.name});
  }

  Future<(String, OpenedSeal)> _rotateGitHub(
    String seal,
    OpenedSeal opened,
    SealBinding binding,
    GitHubLane lane,
  ) {
    final (_, creds, api) = lane;
    return _rotate(
      provider: ConnectProvider.github,
      oldSeal: seal,
      binding: binding,
      generation: creds.clientSecret.generation,
      upstream: () async {
        final refresh = opened.text('refresh');
        if (refresh.isEmpty) {
          throw _signIn;
        }
        final tokens = await api.refresh(refresh);
        return (
          accountId: opened.header.accountId,
          appId: opened.header.appId,
          payload: githubSealPayload(tokens),
        );
      },
    );
  }

  /// Opens a GitHub seal for [caller] (replaying a handoff when one exists)
  /// and refreshes the parent token when it has less than [minRemaining].
  /// A parent with more is answered as it is: these routes need a usable
  /// parent, not a new one, and every rotation spends a refresh token.
  ///
  /// With [rotate] false a parent below [minRemaining] answers
  /// `needs_sign_in` instead: for callers that cannot hand a rotated seal
  /// back to the server (the browser-side setup redirect).
  Future<GitHubGrant> resolveGitHub(
    ConnectCaller caller,
    String workspaceId,
    String seal, {
    required GitHubLane lane,
    required Duration minRemaining,
    bool rotate = true,
  }) async {
    final (config, creds, _) = lane;
    final binding = caller.binding(workspaceId);
    checkSealHeader(
      ctx.sealer.header(seal),
      provider: ConnectProvider.github,
      appId: '${creds.appId}',
      minGeneration: config.minSealGeneration,
    );
    final (openedSeal, openedValue, replayed) = await _openOrReplay(
      ConnectProvider.github,
      seal,
      binding,
    );
    var current = openedSeal;
    var opened = openedValue;
    var updated = replayed ? current : '';
    final expires = opened.time('access_expires_at');
    if (opened.text('access').isEmpty ||
        expires == null ||
        expires.difference(ctx.now()) < minRemaining) {
      if (!rotate) {
        throw _signIn;
      }
      (current, opened) = await _rotateGitHub(current, opened, binding, lane);
      updated = current;
    }
    return GitHubGrant(opened, current, updated);
  }

  // ---------------------------------------------------------------- refresh

  Future<_SealedLane> _sealedLane(ConnectProvider provider) async {
    switch (provider) {
      case ConnectProvider.github:
        final lane = await ctx.githubLane();
        final (config, creds, _) = lane;
        return _SealedLane(
          provider: provider,
          appId: '${creds.appId}',
          minGeneration: config.minSealGeneration,
          generation: creds.clientSecret.generation,
          renew: (seal, opened, binding) =>
              _rotateGitHub(seal, opened, binding, lane),
        );
      case ConnectProvider.google:
        final (config, creds, api) = await ctx.googleLane();
        return _SealedLane(
          provider: provider,
          appId: creds.clientId,
          minGeneration: config.minSealGeneration,
          generation: creds.clientSecret.generation,
          renew: (_, opened, binding) =>
              _renewGoogle(opened, binding, creds, api),
        );
      case ConnectProvider.slack:
        final lane = await ctx.slackLane();
        final (config, creds, _) = lane;
        return _SealedLane(
          provider: provider,
          appId: creds.appId,
          minGeneration: config.minSealGeneration,
          generation: creds.clientSecret.generation,
          renew: (seal, opened, binding) =>
              _rotateSlack(seal, opened, binding, lane),
        );
      case ConnectProvider.linear:
        // Linear grants are never sealed: the server refreshes them itself.
        throw _invalid;
    }
  }

  /// `POST /v1/{github,google,slack}/refresh`: one handler for every sealed
  /// lane.
  ///
  /// A seal a rotation already replaced replays its successor. Otherwise the
  /// grant is renewed upstream every time, even when the sealed access token
  /// is still fresh: a server asks because it holds no live token (expired,
  /// or gone with a restart, since access tokens live only in its memory),
  /// and only a renewal answers with a full-lifetime one. The routes that
  /// just need a usable parent ([resolveGitHub]) reuse a fresh one instead.
  /// Slack refreshes only for the install the team is bound to.
  Future<Object?> refresh(
    ConnectCaller caller,
    Map<String, Object?> body,
    ConnectProvider provider,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final lane = await _sealedLane(provider);
    final binding = caller.binding(request.workspaceId);
    final header = ctx.sealer.header(request.seal);
    checkSealHeader(
      header,
      provider: provider,
      appId: lane.appId,
      minGeneration: lane.minGeneration,
    );
    if (provider == ConnectProvider.slack) {
      await _requireSlackBinding(header.accountId, caller.installId);
    }
    final (seal, opened, replayed) = await _openOrReplay(
      provider,
      request.seal,
      binding,
    );
    if (replayed) {
      return _grantBody(seal: seal, opened: opened);
    }
    final (sealed, fresh) = await lane.renew(seal, opened, binding);
    ctx.log.event('grant.refreshed', {
      'provider': provider.name,
      'install': ctx.log.tag(caller.installId),
      if (provider == ConnectProvider.slack)
        'team': ctx.log.tag(header.accountId),
      'generation': lane.generation,
    });
    return _grantBody(seal: sealed, opened: fresh);
  }

  /// Google refresh tokens are reusable, so there is no lock or handoff: the
  /// seal is re-made under the current generation, and the access token
  /// (which a Google seal never holds) rides in the answer only.
  Future<(String, OpenedSeal)> _renewGoogle(
    OpenedSeal opened,
    SealBinding binding,
    GoogleCredentials creds,
    GoogleApi api,
  ) async {
    final refresh = opened.text('refresh');
    if (refresh.isEmpty) {
      throw _signIn;
    }
    final tokens = await api.refresh(refresh);
    if (tokens.scopes.isNotEmpty &&
        !scopesExactlyMatch(tokens.scopes, googleConnectScopes)) {
      throw _signIn;
    }
    final kept = tokens.refresh.isNotEmpty ? tokens.refresh : refresh;
    final sealed = await ctx.sealer.seal(
      provider: ConnectProvider.google,
      accountId: opened.header.accountId,
      appId: opened.header.appId,
      generation: creds.clientSecret.generation,
      binding: binding,
      payload: {'refresh': kept},
    );
    return (
      sealed,
      OpenedSeal(ctx.sealer.header(sealed), {
        'refresh': kept,
        'access': tokens.access,
        'access_expires_at': tokens.expiresAt.toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> _requireSlackBinding(String teamId, String installId) async {
    // Authorizes a refresh: a cached positive could outlive a move or an
    // uninstall on another instance.
    final bound = await ctx.bindings.slack(teamId, fresh: true);
    if (bound == null) {
      throw _signIn;
    }
    if (bound.installId != installId) {
      throw const ConnectException(ConnectErrorCode.teamBoundElsewhere);
    }
  }

  Future<(String, OpenedSeal)> _rotateSlack(
    String seal,
    OpenedSeal opened,
    SealBinding binding,
    SlackLane lane,
  ) {
    final (_, creds, api) = lane;
    return _rotate(
      provider: ConnectProvider.slack,
      oldSeal: seal,
      binding: binding,
      generation: creds.clientSecret.generation,
      upstream: () async {
        final refresh = opened.text('refresh');
        if (refresh.isEmpty) {
          throw _signIn;
        }
        final grant = await api.refresh(refresh);
        final team = opened.header.accountId;
        if ((grant.teamId.isNotEmpty && grant.teamId != team) ||
            (grant.appId.isNotEmpty && grant.appId != opened.header.appId)) {
          throw _denied;
        }
        return (
          accountId: team,
          appId: opened.header.appId,
          payload: {
            'refresh': grant.refresh,
            'access': grant.access,
            'access_expires_at': grant.accessExpiresAt
                .toUtc()
                .toIso8601String(),
            'team_id': team,
            'bot_user_id': grant.botUserId.isNotEmpty
                ? grant.botUserId
                : opened.text('bot_user_id'),
            'bot_id': opened.text('bot_id'),
          },
        );
      },
    );
  }

  // ------------------------------------------------------------ GitHub reads

  Future<List<GitHubInstallation>> _cachedInstallations(
    GitHubApi api,
    String parent,
  ) async {
    final key = 'ghc:${ctx.tokenCacheKey(parent)}:installations';
    final cached = await ctx.state.get(key);
    if (cached != null) {
      final decoded = jsonDecode(cached);
      if (decoded is List) {
        return [for (final item in decoded) ?GitHubInstallation.tryParse(item)];
      }
    }
    final fresh = await api.installations(parent);
    await ctx.state.set(
      key,
      jsonEncode([for (final i in fresh) i.toJson()]),
      githubReadCacheTtl,
    );
    return fresh;
  }

  /// The parent token's person. Cached: a token's account never changes.
  Future<GitHubUser> _user(GitHubApi api, String parent) async {
    final key = 'ghc:${ctx.tokenCacheKey(parent)}:user';
    final cached = await ctx.state.get(key);
    if (cached != null) {
      final json = jsonDecode(cached);
      if (json is Map && json['id'] is int && json['login'] is String) {
        return GitHubUser(
          id: json['id'] as int,
          login: json['login'] as String,
        );
      }
    }
    final user = await api.user(parent);
    await ctx.state.set(
      key,
      jsonEncode({'id': user.id, 'login': user.login}),
      githubReadCacheTtl,
    );
    return user;
  }

  // ------------------------------------------------------------ GitHub scope

  /// `POST /v1/github/scope`: one repository, clamped to the person's role,
  /// through an installation this server is bound to.
  ///
  /// Everything this decides on is read fresh, never from a cache: the
  /// person's role on the repository (a demotion must not keep minting the
  /// old scope), the installation list (suspended or removed) and the
  /// installation's server binding. Servers cache the minted tokens, so this
  /// runs about once per repository and scope per parent lifetime.
  Future<Object?> githubScope(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubScopeRequest.fromJson(body));
    if (!isGitHubSegment(request.repoOwner) ||
        !isGitHubSegment(request.repoName)) {
      throw _invalid;
    }
    final requested = GitHubTokenScope.fromWire(request.scope);
    if (requested == null) {
      throw _invalid;
    }
    final lane = await ctx.githubLane();
    final (_, _, api) = lane;
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: githubParentMinRemaining,
    );
    final userId = grant.accountId;
    final installations = await api.installations(grant.parent);
    final repo = await api.repo(
      grant.parent,
      request.repoOwner,
      request.repoName,
    );
    if (repo.id != request.repoId) {
      throw _denied;
    }
    final installation = installations
        .where((i) => i.accountId == repo.ownerId)
        .firstOrNull;
    if (installation == null) {
      throw const ConnectException(ConnectErrorCode.notInstalled);
    }
    if (installation.suspended) {
      throw const ConnectException(ConnectErrorCode.suspended);
    }
    final allowedOwners = ctx.config.githubAllowedOwners;
    if (allowedOwners.isNotEmpty && !allowedOwners.contains(repo.ownerId)) {
      throw _denied;
    }
    final binding = await ctx.bindings.github(installation.id, fresh: true);
    final boundHere = binding?.installIds.contains(caller.installId) ?? false;
    if (!boundHere) {
      if (installation.isOrganization || installation.accountId != userId) {
        throw const ConnectException(
          ConnectErrorCode.installationBoundElsewhere,
        );
      }
      // The person's own account: any server they sign in on may bind it.
      await ctx.bindings.addGitHub(installation.id, caller.installId);
      ctx.log.event('github.bound', {
        'installation_id': installation.id,
        'install': ctx.log.tag(caller.installId),
        'reason': 'personal',
      });
    }
    final granted = clampGitHubScope(
      requested: requested,
      role: GitHubRepoRole.fromPermissions(repo.permissions),
      repoIsPublic: !repo.isPrivate,
    );
    if (granted == null) {
      throw _denied;
    }
    final mint = await api.scoped(
      parent: grant.parent,
      targetId: installation.accountId,
      repoId: repo.id,
      permissions: granted.permissions,
    );
    ctx.log.event('github.scope', {
      'installation_id': installation.id,
      'repo_id': repo.id,
      'github_user_id': userId,
      'scope': requested.wire,
      'granted_scope': granted.wire,
      'install': ctx.log.tag(caller.installId),
    });
    final minted = mint.expiresAt ?? grant.parentExpiresAt;
    final expires = minted.isAfter(grant.parentExpiresAt)
        ? grant.parentExpiresAt
        : minted;
    // Who may revoke this child later: only the install it was minted for,
    // presenting a seal of the same GitHub account.
    await ctx.state.set(
      _childKey(mint.token),
      _childOwner(caller.installId, '$userId'),
      expires.difference(ctx.now()) + const Duration(minutes: 5),
    );
    return GitHubScopedToken(
      accessToken: mint.token,
      grantedScope: granted.wire,
      expiresAt: expires,
      updatedSeal: grant.updatedSeal,
      installationId: installation.id,
    ).toJson();
  }

  static String _childKey(String token) => 'child:${sealDigest(token)}';

  static String _childOwner(String installId, String accountId) =>
      '$installId|$accountId';

  // ------------------------------------------------- GitHub install binding

  /// Binds [installId] to [installationId] when [grant]'s person
  /// administers it (org admin, or the personal account itself).
  Future<AuthorizeOutcome> authorizeInstallation(
    GitHubGrant grant,
    int installationId,
    String installId, {
    required GitHubLane lane,
  }) async {
    final (_, _, api) = lane;
    final user = await _user(api, grant.parent);
    if (user.id != grant.accountId) {
      return AuthorizeOutcome.notAdmin;
    }
    // A binding write is authorization: read the installation list fresh.
    final installation = (await api.installations(
      grant.parent,
    )).where((i) => i.id == installationId).firstOrNull;
    if (installation == null) {
      return AuthorizeOutcome.notInstalled;
    }
    if (installation.suspended) {
      return AuthorizeOutcome.suspended;
    }
    final admin = installation.isOrganization
        ? await api.isActiveOrgAdmin(
            grant.parent,
            installation.accountLogin,
            user.login,
          )
        : installation.accountId == user.id;
    if (!admin) {
      return AuthorizeOutcome.notAdmin;
    }
    await ctx.bindings.addGitHub(installation.id, installId);
    ctx.log.event('github.bound', {
      'installation_id': installation.id,
      'github_user_id': user.id,
      'install': ctx.log.tag(installId),
      'reason': installation.isOrganization ? 'org_admin' : 'personal',
    });
    return AuthorizeOutcome.bound;
  }

  /// `POST /v1/github/install/start`.
  Future<Object?> githubInstallStart(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final lane = await ctx.githubLane();
    // Opening the seal proves the caller owns it before a ticket exists. The
    // parent must outlive the ticket: setup cannot rotate it.
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: installTicketTtl + const Duration(minutes: 5),
    );
    final ticket = b64url(randomBytes(32));
    await ctx.state.set(
      'ticket:$ticket',
      jsonEncode({
        'install_id': caller.installId,
        'workspace_id': request.workspaceId,
        'seal': grant.seal,
      }),
      installTicketTtl,
    );
    return GitHubInstallStartResponse(
      installUrl: Uri.https(
        'github.com',
        '/apps/${lane.$1.appSlug}/installations/new',
        {'state': ticket},
      ),
      expiresAt: ctx.now().add(installTicketTtl),
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  /// Most installations one listing shows.
  static const int _maxListedInstallations = 50;

  /// Organization membership lookups in flight at once for one listing.
  static const int _listingConcurrency = 8;

  /// `POST /v1/github/installations`.
  Future<Object?> githubInstallations(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final lane = await ctx.githubLane();
    final (_, _, api) = lane;
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: const Duration(minutes: 5),
    );
    final user = await _user(api, grant.parent);
    if (user.id != grant.accountId) {
      throw _denied;
    }
    Future<GitHubInstallationView> view(GitHubInstallation installation) async {
      final own =
          !installation.isOrganization && installation.accountId == user.id;
      final admin = installation.isOrganization
          ? await api.isActiveOrgAdmin(
              grant.parent,
              installation.accountLogin,
              user.login,
            )
          : own;
      final binding = await ctx.bindings.github(installation.id);
      return GitHubInstallationView(
        installationId: installation.id,
        accountId: installation.accountId,
        accountLogin: installation.accountLogin,
        targetType: installation.targetType,
        boundHere:
            (binding?.installIds.contains(caller.installId) ?? false) || own,
        suspended: installation.suspended,
        callerIsAdmin: admin,
      );
    }

    // One membership lookup per organization, at most eight in flight: the
    // whole listing fits the caller's deadline without a burst at GitHub,
    // and one slow organization never holds up the rest of its batch.
    final installations = (await _cachedInstallations(
      api,
      grant.parent,
    )).take(_maxListedInstallations).toList();
    final pool = BoundedPool(
      concurrency: _listingConcurrency,
      maxQueued: _maxListedInstallations,
    );
    final views = await Future.wait([
      for (final installation in installations)
        pool.run(() => view(installation)),
    ]);
    return GitHubInstallationsResponse(
      installations: [for (final v in views) ?v],
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  /// `POST /v1/github/authorize_server`.
  Future<Object?> githubAuthorizeServer(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubAuthorizeServerRequest.fromJson(body));
    final lane = await ctx.githubLane();
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: const Duration(minutes: 5),
    );
    final outcome = await authorizeInstallation(
      grant,
      request.installationId,
      caller.installId,
      lane: lane,
    );
    return switch (outcome) {
      AuthorizeOutcome.bound => ConnectAck(
        updatedSeal: grant.updatedSeal,
      ).toJson(),
      AuthorizeOutcome.notInstalled => throw const ConnectException(
        ConnectErrorCode.notInstalled,
      ),
      AuthorizeOutcome.suspended => throw const ConnectException(
        ConnectErrorCode.suspended,
      ),
      AuthorizeOutcome.notAdmin => throw _denied,
    };
  }

  /// `POST /v1/github/revoke`: one scoped token, or the whole grant.
  Future<Object?> githubRevoke(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubRevokeRequest.fromJson(body));
    final lane = await ctx.githubLane();
    final (config, creds, api) = lane;
    if (request.scopedToken.isNotEmpty) {
      final token = request.scopedToken;
      if (!token.startsWith('ghu_') || token.length > 512) {
        throw _invalid;
      }
      // The seal proves the caller holds a grant on this app, and whose.
      final header = ctx.sealer.header(request.seal);
      checkSealHeader(
        header,
        provider: ConnectProvider.github,
        appId: '${creds.appId}',
        minGeneration: config.minSealGeneration,
      );
      await _openOrReplay(
        ConnectProvider.github,
        request.seal,
        caller.binding(request.workspaceId),
      );
      final child = _childKey(token);
      final mintedFor = await ctx.state.get(child);
      if (mintedFor == null) {
        // Expired, already revoked, or never minted here: nothing to do.
        return const ConnectAck().toJson();
      }
      // A child minted before owners carried the account names the install
      // alone; it still revokes for that install.
      if (mintedFor != _childOwner(caller.installId, header.accountId) &&
          mintedFor != caller.installId) {
        throw _denied;
      }
      await api.deleteToken(token);
      await ctx.state.delete(child);
      return const ConnectAck().toJson();
    }
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: const Duration(minutes: 1),
    );
    await api.deleteGrant(grant.parent);
    ctx.log.event('grant.revoked', {
      'provider': 'github',
      'install': ctx.log.tag(caller.installId),
    });
    return const ConnectAck().toJson();
  }

  /// `POST /v1/slack/revoke`: only the bound install. Revokes the bot token
  /// and releases the team.
  Future<Object?> slackRevoke(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final lane = await ctx.slackLane();
    final (_, creds, api) = lane;
    final binding = caller.binding(request.workspaceId);
    final header = ctx.sealer.header(request.seal);
    if (header.provider != ConnectProvider.slack ||
        header.appId != creds.appId) {
      throw _denied;
    }
    var (seal, opened, _) = await _openOrReplay(
      ConnectProvider.slack,
      request.seal,
      binding,
    );
    final team = header.accountId;
    final bound = await ctx.bindings.slack(team, fresh: true);
    if (bound != null && bound.installId != caller.installId) {
      throw _denied;
    }
    final expires = opened.time('access_expires_at');
    var access = opened.text('access');
    try {
      if (access.isEmpty ||
          expires == null ||
          expires.difference(ctx.now()) < const Duration(minutes: 1)) {
        (seal, opened) = await _rotateSlack(seal, opened, binding, lane);
        access = opened.text('access');
      }
      await api.revoke(access);
    } on ConnectException catch (error) {
      // A dead refresh token means the bot token is gone already.
      if (error.code != ConnectErrorCode.needsSignIn) {
        rethrow;
      }
    }
    if (bound != null) {
      await ctx.bindings.releaseSlack(team, installId: caller.installId);
    }
    ctx.log.event('slack.released', {
      'team': ctx.log.tag(team),
      'install': ctx.log.tag(caller.installId),
      'reason': 'revoke',
    });
    return const ConnectAck().toJson();
  }
}

/// Seals a fresh Slack grant for [binding] (claim).
Future<String> sealSlackGrant(
  ConnectContext ctx, {
  required SlackBotGrant grant,
  required String botId,
  required int generation,
  required SealBinding binding,
}) => ctx.sealer.seal(
  provider: ConnectProvider.slack,
  accountId: grant.teamId,
  appId: grant.appId,
  generation: generation,
  binding: binding,
  payload: slackSealPayload(grant, botId),
);
