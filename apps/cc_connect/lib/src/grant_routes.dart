import 'dart:async';
import 'dart:convert';

import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/provider_github.dart';
import 'package:cc_connect/src/provider_slack.dart';
import 'package:cc_connect/src/upstream_http.dart' show upstreamTimeout;
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

  /// Rotates a single-use refresh token behind a per-seal lock, and leaves a
  /// ciphertext-only handoff (`sha256(old) -> new`, 5 min) so a retry with
  /// the old seal after a dropped response replays the new one instead of
  /// failing on a spent refresh token.
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
    final lock = 'lock:$digest';
    // Outlives the slowest rotation the holder can run — a refresh tried
    // with both client secrets, then the KMS seal, each bounded by
    // [upstreamTimeout] — so a second request never takes the lock while the
    // first still holds the single-use refresh token.
    if (!await ctx.state.putIfAbsent(lock, '1', upstreamTimeout * 6)) {
      // Another request is rotating this seal right now: wait for its
      // handoff rather than spending the refresh token twice.
      for (var i = 0; i < 50; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final replay = await _replay(provider, oldSeal, binding);
        if (replay != null) {
          return replay;
        }
      }
      throw _unavailable;
    }
    try {
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
      await ctx.state.set('handoff:$digest', sealed, sealHandoffTtl);
      return (sealed, OpenedSeal(ctx.sealer.header(sealed), fresh.payload));
    } finally {
      await ctx.state.delete(lock);
    }
  }

  Future<(String, OpenedSeal)> _rotateGitHub(
    String seal,
    OpenedSeal opened,
    SealBinding binding,
  ) async {
    final (_, creds, api) = await ctx.githubLane();
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
  ///
  /// With [rotate] false a parent below [minRemaining] answers
  /// `needs_sign_in` instead: for callers that cannot hand a rotated seal
  /// back to the server (the browser-side setup redirect).
  Future<GitHubGrant> resolveGitHub(
    ConnectCaller caller,
    String workspaceId,
    String seal, {
    required Duration minRemaining,
    bool rotate = true,
  }) async {
    final (lane, creds, _) = await ctx.githubLane();
    final binding = caller.binding(workspaceId);
    checkSealHeader(
      ctx.sealer.header(seal),
      provider: ConnectProvider.github,
      appId: '${creds.appId}',
      minGeneration: lane.minSealGeneration,
    );
    var current = seal;
    var updated = '';
    OpenedSeal opened;
    final replay = await _replay(ConnectProvider.github, seal, binding);
    if (replay != null) {
      (current, opened) = replay;
      updated = current;
    } else {
      opened = await ctx.sealer.open(
        seal,
        provider: ConnectProvider.github,
        binding: binding,
      );
    }
    final expires = opened.time('access_expires_at');
    if (opened.text('access').isEmpty ||
        expires == null ||
        expires.difference(ctx.now()) < minRemaining) {
      if (!rotate) {
        throw _signIn;
      }
      (current, opened) = await _rotateGitHub(current, opened, binding);
      updated = current;
    }
    return GitHubGrant(opened, current, updated);
  }

  // ---------------------------------------------------------------- refresh

  /// `POST /v1/github/refresh`.
  Future<Object?> refreshGitHub(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final (lane, creds, _) = await ctx.githubLane();
    final binding = caller.binding(request.workspaceId);
    checkSealHeader(
      ctx.sealer.header(request.seal),
      provider: ConnectProvider.github,
      appId: '${creds.appId}',
      minGeneration: lane.minSealGeneration,
    );
    final replay = await _replay(ConnectProvider.github, request.seal, binding);
    if (replay != null) {
      return _grantBody(seal: replay.$1, opened: replay.$2);
    }
    final opened = await ctx.sealer.open(
      request.seal,
      provider: ConnectProvider.github,
      binding: binding,
    );
    final (sealed, fresh) = await _rotateGitHub(request.seal, opened, binding);
    ctx.log.event('grant.refreshed', {
      'provider': 'github',
      'install': ctx.log.tag(caller.installId),
      'generation': creds.clientSecret.generation,
    });
    return _grantBody(seal: sealed, opened: fresh);
  }

  /// `POST /v1/google/refresh`. Google refresh tokens are reusable, so no
  /// handoff is needed; the seal is re-made under the current generation.
  Future<Object?> refreshGoogle(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final (lane, creds, api) = await ctx.googleLane();
    final binding = caller.binding(request.workspaceId);
    checkSealHeader(
      ctx.sealer.header(request.seal),
      provider: ConnectProvider.google,
      appId: creds.clientId,
      minGeneration: lane.minSealGeneration,
    );
    final opened = await ctx.sealer.open(
      request.seal,
      provider: ConnectProvider.google,
      binding: binding,
    );
    final refresh = opened.text('refresh');
    if (refresh.isEmpty) {
      throw _signIn;
    }
    final tokens = await api.refresh(refresh);
    if (tokens.scopes.isNotEmpty &&
        !scopesExactlyMatch(tokens.scopes, googleConnectScopes)) {
      throw _signIn;
    }
    final sealed = await ctx.sealer.seal(
      provider: ConnectProvider.google,
      accountId: opened.header.accountId,
      appId: opened.header.appId,
      generation: creds.clientSecret.generation,
      binding: binding,
      payload: {
        'refresh': tokens.refresh.isNotEmpty ? tokens.refresh : refresh,
      },
    );
    ctx.log.event('grant.refreshed', {
      'provider': 'google',
      'install': ctx.log.tag(caller.installId),
      'generation': creds.clientSecret.generation,
    });
    return SealedGrant(
      seal: sealed,
      accessToken: tokens.access,
      expiresAt: tokens.expiresAt,
      accountId: opened.header.accountId,
      appId: opened.header.appId,
    ).toJson();
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
  ) async {
    final (_, creds, api) = await ctx.slackLane();
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

  /// `POST /v1/slack/refresh`. Only the install the team is bound to may
  /// refresh its bot token.
  Future<Object?> refreshSlack(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final (lane, creds, _) = await ctx.slackLane();
    final binding = caller.binding(request.workspaceId);
    final header = ctx.sealer.header(request.seal);
    checkSealHeader(
      header,
      provider: ConnectProvider.slack,
      appId: creds.appId,
      minGeneration: lane.minSealGeneration,
    );
    await _requireSlackBinding(header.accountId, caller.installId);
    final replay = await _replay(ConnectProvider.slack, request.seal, binding);
    if (replay != null) {
      return _grantBody(seal: replay.$1, opened: replay.$2);
    }
    final opened = await ctx.sealer.open(
      request.seal,
      provider: ConnectProvider.slack,
      binding: binding,
    );
    final (sealed, fresh) = await _rotateSlack(request.seal, opened, binding);
    ctx.log.event('grant.refreshed', {
      'provider': 'slack',
      'install': ctx.log.tag(caller.installId),
      'team': ctx.log.tag(header.accountId),
      'generation': creds.clientSecret.generation,
    });
    return _grantBody(seal: sealed, opened: fresh);
  }

  // ------------------------------------------------------------ GitHub reads

  Future<List<GitHubInstallation>> _installations(
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

  Future<GitHubRepo> _repo(
    GitHubApi api,
    String parent,
    String owner,
    String name,
  ) async {
    final key =
        'ghc:${ctx.tokenCacheKey(parent)}:repo:'
        '${owner.toLowerCase()}/${name.toLowerCase()}';
    final cached = await ctx.state.get(key);
    if (cached != null) {
      final repo = GitHubRepo.tryParse(jsonDecode(cached));
      if (repo != null) {
        return repo;
      }
    }
    final fresh = await api.repo(parent, owner, name);
    await ctx.state.set(key, jsonEncode(fresh.toJson()), githubReadCacheTtl);
    return fresh;
  }

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
    final (_, _, api) = await ctx.githubLane();
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      minRemaining: githubParentMinRemaining,
    );
    final userId = grant.accountId;
    final installations = await _installations(api, grant.parent);
    final repo = await _repo(
      api,
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
    final binding = await ctx.bindings.github(installation.id);
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
    final GitHubScopedMint mint;
    try {
      mint = await api.scoped(
        parent: grant.parent,
        targetId: installation.accountId,
        repoId: repo.id,
        permissions: granted.permissions,
      );
    } on ConnectException {
      // Drop cached read probes for this parent token so a revoked grant or
      // uninstalled App surfaces on the very next call instead of for 5 min.
      final prefix = 'ghc:${ctx.tokenCacheKey(grant.parent)}';
      await ctx.state.delete('$prefix:installations');
      await ctx.state.delete('$prefix:user');
      await ctx.state.delete(
        '$prefix:repo:'
        '${request.repoOwner.toLowerCase()}/${request.repoName.toLowerCase()}',
      );
      rethrow;
    }
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
    // Who may revoke this child later: only the install it was minted for.
    await ctx.state.set(
      _childKey(mint.token),
      caller.installId,
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

  // ------------------------------------------------- GitHub install binding

  /// Binds [installId] to [installationId] when [grant]'s person
  /// administers it (org admin, or the personal account itself).
  Future<AuthorizeOutcome> authorizeInstallation(
    GitHubGrant grant,
    int installationId,
    String installId,
  ) async {
    final (_, _, api) = await ctx.githubLane();
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
    final (lane, _, _) = await ctx.githubLane();
    // Opening the seal proves the caller owns it before a ticket exists. The
    // parent must outlive the ticket: setup cannot rotate it.
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
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
        '/apps/${lane.appSlug}/installations/new',
        {'state': ticket},
      ),
      expiresAt: ctx.now().add(installTicketTtl),
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  /// `POST /v1/github/installations`.
  Future<Object?> githubInstallations(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final (_, _, api) = await ctx.githubLane();
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      minRemaining: const Duration(minutes: 5),
    );
    final user = await _user(api, grant.parent);
    if (user.id != grant.accountId) {
      throw _denied;
    }
    Future<GitHubInstallationView> view(GitHubInstallation installation) async {
      final own =
          !installation.isOrganization && installation.accountId == user.id;
      final (binding, admin) = await (
        ctx.bindings.github(installation.id),
        installation.isOrganization
            ? api.isActiveOrgAdmin(
                grant.parent,
                installation.accountLogin,
                user.login,
              )
            : Future.value(own),
      ).wait;
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

    // Eight at a time: one membership lookup per organization, inside the
    // caller's request deadline, without a burst against GitHub.
    final installations = (await _installations(
      api,
      grant.parent,
    )).take(50).toList();
    final views = <GitHubInstallationView>[];
    for (var i = 0; i < installations.length; i += 8) {
      views.addAll(
        await Future.wait(installations.skip(i).take(8).map(view)),
      );
    }
    return GitHubInstallationsResponse(
      installations: views,
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  /// `POST /v1/github/authorize_server`.
  Future<Object?> githubAuthorizeServer(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubAuthorizeServerRequest.fromJson(body));
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      minRemaining: const Duration(minutes: 5),
    );
    final outcome = await authorizeInstallation(
      grant,
      request.installationId,
      caller.installId,
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
    final (lane, creds, api) = await ctx.githubLane();
    if (request.scopedToken.isNotEmpty) {
      final token = request.scopedToken;
      if (!token.startsWith('ghu_') || token.length > 512) {
        throw _invalid;
      }
      // The seal proves the caller holds a grant on this app.
      checkSealHeader(
        ctx.sealer.header(request.seal),
        provider: ConnectProvider.github,
        appId: '${creds.appId}',
        minGeneration: lane.minSealGeneration,
      );
      final binding = caller.binding(request.workspaceId);
      final replay = await _replay(
        ConnectProvider.github,
        request.seal,
        binding,
      );
      if (replay == null) {
        await ctx.sealer.open(
          request.seal,
          provider: ConnectProvider.github,
          binding: binding,
        );
      }
      final child = _childKey(token);
      final mintedFor = await ctx.state.get(child);
      if (mintedFor == null) {
        // Expired, already revoked, or never minted here: nothing to do.
        return const ConnectAck().toJson();
      }
      if (mintedFor != caller.installId) {
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
    final (_, creds, api) = await ctx.slackLane();
    final binding = caller.binding(request.workspaceId);
    final header = ctx.sealer.header(request.seal);
    if (header.provider != ConnectProvider.slack ||
        header.appId != creds.appId) {
      throw _denied;
    }
    var (seal, opened) =
        await _replay(ConnectProvider.slack, request.seal, binding) ??
        (
          request.seal,
          await ctx.sealer.open(
            request.seal,
            provider: ConnectProvider.slack,
            binding: binding,
          ),
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
        (seal, opened) = await _rotateSlack(seal, opened, binding);
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
