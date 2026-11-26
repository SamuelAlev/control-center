import 'dart:async';
import 'dart:convert';

import 'package:cc_connect/src/connect_log.dart';
import 'package:cc_connect/src/context.dart';
import 'package:cc_connect/src/credential_seal.dart';
import 'package:cc_connect/src/provider_github.dart';
import 'package:cc_connect/src/provider_google.dart';
import 'package:cc_connect/src/provider_slack.dart';
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

  /// Refuses seals for another provider, of a retired app or below the
  /// minimum generation, and logs `seal.refused`.
  void _checkSealHeader(
    SealHeader header, {
    required ConnectProvider provider,
    required String appId,
    required int minGeneration,
  }) {
    if (header.provider != provider) {
      ctx.sealer.refused(provider, 'provider');
      throw _denied;
    }
    if (header.appId != appId) {
      ctx.sealer.refused(provider, 'retired_app');
      throw _signIn;
    }
    if (header.generation < minGeneration) {
      ctx.sealer.refused(provider, 'below_min_generation');
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
    ctx.log.event('seal.handoff_unsaved', {
      'provider': provider.name,
    }, ConnectLogLevel.error);
  }

  Future<(String, OpenedSeal)> _rotateGitHub(
    ConnectCaller caller,
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
        await ctx.quotas.admit(
          ctx.githubTokenQuotas(
            caller,
            accountId: int.tryParse(opened.header.accountId),
          ),
        );
        final tokens = await api.refresh(refresh);
        ctx.log.event('github.rotated', {
          'github_user_id': int.tryParse(opened.header.accountId),
          'hashed_token': githubHashedToken(tokens.access),
        });
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
  /// [admit] runs once the seal opened, before any upstream call.
  Future<GitHubGrant> resolveGitHub(
    ConnectCaller caller,
    String workspaceId,
    String seal, {
    required GitHubLane lane,
    required Duration minRemaining,
    Future<void> Function(OpenedSeal opened)? admit,
  }) async {
    final (config, creds, _) = lane;
    final binding = caller.binding(workspaceId);
    _checkSealHeader(
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
    await admit?.call(opened);
    final expires = opened.time('access_expires_at');
    if (opened.text('access').isEmpty ||
        expires == null ||
        expires.difference(ctx.now()) < minRemaining) {
      (current, opened) = await _rotateGitHub(
        caller,
        current,
        opened,
        binding,
        lane,
      );
      updated = current;
    }
    return GitHubGrant(opened, current, updated);
  }

  // ---------------------------------------------------------------- refresh

  Future<_SealedLane> _sealedLane(
    ConnectProvider provider,
    ConnectCaller caller,
  ) async {
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
              _rotateGitHub(caller, seal, opened, binding, lane),
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
  /// Slack refreshes only for the install the team is bound to, checked
  /// after the seal opened: a caller without a seal for the team learns
  /// nothing about its binding.
  Future<Object?> refresh(
    ConnectCaller caller,
    Map<String, Object?> body,
    ConnectProvider provider,
  ) async {
    final request = _parse(() => SealRequest.fromJson(body));
    final lane = await _sealedLane(provider, caller);
    final binding = caller.binding(request.workspaceId);
    final header = ctx.sealer.header(request.seal);
    _checkSealHeader(
      header,
      provider: provider,
      appId: lane.appId,
      minGeneration: lane.minGeneration,
    );
    final (seal, opened, replayed) = await _openOrReplay(
      provider,
      request.seal,
      binding,
    );
    if (provider == ConnectProvider.slack) {
      await _requireSlackBinding(opened.header.accountId, caller.installId);
    }
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

  // ------------------------------------------------------------ GitHub scope

  /// `POST /v1/github/scope`: one repository, clamped to the person's role.
  ///
  /// `as: user` mints a child of the person's own user token through the
  /// App's installation on the repository's owner; `as: app` mints an
  /// installation token of the App itself (the bot), authorized by the same
  /// person: their own token must see the repository with the asked
  /// permission, and the token never carries more than the clamp allows.
  /// GitHub does not clamp an installation token to that person, and any
  /// server may be anyone's script, so the bot holds at most `comment`
  /// (`read`, `review`, `comment`) for every install, and `bot` (reviews,
  /// `pull_requests: write`) only for the installs the operator lists in
  /// `CONNECT_GITHUB_REVIEW_BOT_INSTALLS`. Anything else answers
  /// `needs_requester` before GitHub is asked: the server then mints for the
  /// person (`as: user`), whom GitHub clamps itself.
  ///
  /// Everything this decides on is read fresh, never from a cache: the
  /// person's role on the repository (a demotion must not keep minting the
  /// old scope) and the installation (suspended, removed, repository
  /// deselected). Servers cache the minted tokens, so this runs about once
  /// per repository and scope per token lifetime.
  Future<Object?> githubScope(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubScopeRequest.fromJson(body));
    try {
      return await _githubScope(caller, request);
    } on ConnectException catch (error) {
      ctx.log.event('github.mint', {
        'as': request.actor.wire,
        'outcome': 'refused',
        'error': error.code.wire,
        if (error.reason.isNotEmpty) 'reason': error.reason,
      }, ConnectLogLevel.warn);
      rethrow;
    }
  }

  Future<Object?> _githubScope(
    ConnectCaller caller,
    GitHubScopeRequest request,
  ) async {
    if (!isGitHubSegment(request.repoOwner) ||
        !isGitHubSegment(request.repoName)) {
      throw _invalid;
    }
    final requested = GitHubTokenScope.fromWire(request.scope);
    if (requested == null) {
      throw _invalid;
    }
    // Nothing binds an organization's installation of this shared App to
    // one Control Center server, so its bot never writes contents, and
    // reviews only for a server the operator listed. A push, a branch, a
    // pull request or a review is otherwise minted for the person who asked.
    if (request.actor == GitHubMintActor.app &&
        !requested.connectBotMayHold &&
        !(requested.connectBotNeedsListing &&
            ctx.config.githubReviewBotInstalls.contains(caller.installId))) {
      throw ConnectException(
        ConnectErrorCode.needsRequester,
        reason: requested.connectBotNeedsListing
            ? 'github_app_review_scope'
            : 'github_app_write_scope',
      );
    }
    final lane = await ctx.githubLane();
    final (_, _, api) = lane;
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: githubParentMinRemaining,
      // Once the seal opened (so the account is the verified one) and before
      // any upstream call.
      admit: request.actor == GitHubMintActor.app
          ? (opened) => ctx.quotas.admit(
              ctx.githubAppMintQuotas(caller, opened.header.accountId),
            )
          : null,
    );
    // The person's own view of the repository is the authorization for
    // either kind of token: they must see it, and their role clamps it.
    final repo = await api.repo(
      grant.parent,
      request.repoOwner,
      request.repoName,
    );
    if (repo.id != request.repoId) {
      throw _denied;
    }
    final allowedOwners = ctx.config.githubAllowedOwners;
    if (allowedOwners.isNotEmpty && !allowedOwners.contains(repo.ownerId)) {
      throw _denied;
    }
    final granted = clampGitHubScope(
      requested: requested,
      role: GitHubRepoRole.fromPermissions(repo.permissions),
      repoIsPublic: !repo.isPrivate,
    );
    if (granted == null) {
      throw _denied;
    }
    return switch (request.actor) {
      GitHubMintActor.user => _githubUserChild(
        caller,
        api,
        grant,
        request,
        repo,
        requested,
        granted,
      ),
      GitHubMintActor.app => _githubInstallationToken(
        caller,
        api,
        grant,
        request,
        repo,
        requested,
        granted,
      ),
    };
  }

  /// `as: user`: a child of the person's token, through the installation
  /// on the owner they can see. No per-server binding: the account's
  /// installation is its consent, and the child is the member's own token.
  ///
  /// GitHub caps how many tokens one person may hold for the App and how
  /// fast they may be created, evicting the oldest past the cap: a child
  /// another request still uses. So a live child for the same install,
  /// workspace slot, parent, repository and permissions is handed out again
  /// instead of minting another ([_reusableChild]); revoking it ends that.
  /// The answer carries the coverage the server checks: `selected`, this one
  /// repository, exactly the granted permissions.
  Future<Object?> _githubUserChild(
    ConnectCaller caller,
    GitHubApi api,
    GitHubGrant grant,
    GitHubScopeRequest request,
    GitHubRepo repo,
    GitHubTokenScope requested,
    GitHubTokenScope granted,
  ) async {
    final userId = grant.accountId;
    final installations = await api.installations(grant.parent);
    final installation = installations
        .where((i) => i.accountId == repo.ownerId)
        .firstOrNull;
    if (installation == null) {
      throw const ConnectException(ConnectErrorCode.notInstalled);
    }
    if (installation.suspended) {
      throw const ConnectException(ConnectErrorCode.suspended);
    }
    final binding = caller.binding(request.workspaceId);
    final reuseKey = _childReuseKey(
      caller.installId,
      request.workspaceId,
      userId,
      repo.id,
      granted.permissions,
    );
    final reused = await _reusableChild(reuseKey, grant, binding);
    GitHubScopedToken answer(String token, DateTime expires) =>
        GitHubScopedToken(
          accessToken: token,
          grantedScope: granted.wire,
          expiresAt: expires,
          updatedSeal: grant.updatedSeal,
          installationId: installation.id,
          repositorySelection: 'selected',
          repositoryIds: [repo.id],
          permissions: granted.permissions,
        );
    void audit(String token, {required bool reuse, String? requestId}) =>
        ctx.log.event('github.mint', {
          'as': GitHubMintActor.user.wire,
          'outcome': 'ok',
          'installation_id': installation.id,
          'repo_id': repo.id,
          'github_user_id': userId,
          'scope': requested.wire,
          'granted_scope': granted.wire,
          'reused': reuse,
          'hashed_token': githubHashedToken(token),
          'github_request_id': requestId,
        });
    if (reused != null) {
      audit(reused.token, reuse: true);
      return answer(reused.token, reused.expires).toJson();
    }
    await ctx.quotas.admit(ctx.githubTokenQuotas(caller, accountId: userId));
    final mint = await api.scoped(
      parent: grant.parent,
      targetId: installation.accountId,
      repoId: repo.id,
      permissions: granted.permissions,
    );
    audit(mint.token, reuse: false, requestId: mint.requestId);
    await _countLiveChild(userId);
    final minted = mint.expiresAt ?? grant.parentExpiresAt;
    final expires = minted.isAfter(grant.parentExpiresAt)
        ? grant.parentExpiresAt
        : minted;
    final lifetime = expires.difference(ctx.now()) + const Duration(minutes: 5);
    // Who may revoke this child later: only the install it was minted for,
    // presenting a seal of the same GitHub account.
    await ctx.state.set(
      _childKey(mint.token),
      _childOwner(caller.installId, '$userId'),
      lifetime,
    );
    await _rememberChild(reuseKey, grant, binding, mint.token, expires);
    await ctx.state.push(
      _childrenKey(caller.installId, request.workspaceId, userId),
      await _sealChild(grant, binding, {'child': mint.token}),
      _childrenTtl,
      maxLength: _maxRecordedChildren,
    );
    return answer(mint.token, expires).toJson();
  }

  /// Counts a new child against its account across every install (an
  /// 8-hour window: a child never outlives its parent) and logs
  /// `github.token_cap` past [ConnectRateLimits.githubLiveChildrenWarn].
  /// GitHub does not document how many tokens one person may hold for an
  /// App; past an undocumented cap it may revoke their oldest, which can
  /// be another server's.
  Future<void> _countLiveChild(int accountId) async {
    const window = Duration(hours: 8);
    final index = ctx.now().millisecondsSinceEpoch ~/ window.inMilliseconds;
    final count = await ctx.state.increment(
      'livechildren:$accountId:$index',
      window * 2,
    );
    if (count > ctx.config.rateLimits.githubLiveChildrenWarn) {
      ctx.log.sampled('github.token_cap', '$accountId', {
        'github_user_id': accountId,
        'count': count,
      });
    }
  }

  /// How long the list of one sign-in's children lives past its last
  /// entry: longer than any child (a child never outlives its 8-hour
  /// parent).
  static const Duration _childrenTtl = Duration(hours: 9);

  /// Most children recorded per sign-in for a disconnect to revoke.
  static const int _maxRecordedChildren = 200;

  /// The state key listing the children minted for one sign-in (install,
  /// workspace slot, GitHub account), each sealed to it: what a disconnect
  /// revokes along with the sign-in's own token.
  static String _childrenKey(
    String installId,
    String workspaceId,
    int accountId,
  ) =>
      'children:${sealDigest(canonicalJson({'install': installId, 'workspace': workspaceId, 'account': accountId}))}';

  /// Seals [payload] (a child token) to [binding] under [grant]'s account.
  Future<String> _sealChild(
    GitHubGrant grant,
    SealBinding binding,
    Map<String, Object?> payload,
  ) {
    final header = grant.opened.header;
    return ctx.sealer.seal(
      provider: ConnectProvider.github,
      accountId: header.accountId,
      appId: header.appId,
      generation: header.generation,
      binding: binding,
      payload: payload,
      kind: SealKind.childRecord,
    );
  }

  /// The state key of the reusable child for one install, workspace slot,
  /// GitHub account, repository and permission set. Ids only: the token is
  /// stored sealed under it ([_rememberChild]).
  static String _childReuseKey(
    String installId,
    String workspaceId,
    int accountId,
    int repoId,
    Map<String, String> permissions,
  ) =>
      'childfor:${sealDigest(canonicalJson({'install': installId, 'workspace': workspaceId, 'account': accountId, 'repo': repoId, 'permissions': permissions}))}';

  /// Remembers [token] for reuse, sealed to the caller's binding (another
  /// install or workspace slot cannot open it) and tied to the parent it
  /// came from.
  Future<void> _rememberChild(
    String reuseKey,
    GitHubGrant grant,
    SealBinding binding,
    String token,
    DateTime expires,
  ) async {
    final ttl = expires.difference(ctx.now()) - githubParentMinRemaining;
    if (ttl <= Duration.zero) {
      return;
    }
    final sealed = await _sealChild(grant, binding, {
      'child': token,
      'expires_at': expires.toUtc().toIso8601String(),
      'parent': sealDigest(grant.parent),
    });
    await ctx.state.set(reuseKey, sealed, ttl);
  }

  /// The remembered child under [reuseKey], when it opens for [binding], was
  /// minted from [grant]'s current parent for the same account, has not been
  /// revoked (its revocation owner is still recorded) and still lives long
  /// enough for a server to use it.
  Future<({String token, DateTime expires})?> _reusableChild(
    String reuseKey,
    GitHubGrant grant,
    SealBinding binding,
  ) async {
    final stored = await ctx.state.get(reuseKey);
    if (stored == null) {
      return null;
    }
    final OpenedSeal opened;
    try {
      opened = await ctx.sealer.open(
        stored,
        provider: ConnectProvider.github,
        binding: binding,
        kind: SealKind.childRecord,
      );
    } on ConnectException {
      return null;
    }
    final token = opened.text('child');
    final expires = opened.time('expires_at');
    if (opened.header.accountId != grant.opened.header.accountId ||
        opened.text('parent') != sealDigest(grant.parent) ||
        !token.startsWith('ghu_') ||
        expires == null ||
        expires.difference(ctx.now()) < githubParentMinRemaining ||
        await ctx.state.get(_childKey(token)) == null) {
      return null;
    }
    return (token: token, expires: expires);
  }

  /// `as: app`: an installation token for exactly this repository, found
  /// with the App JWT (not through what the person can list, so a
  /// repository left out of the installation reads as `repo_not_selected`
  /// rather than "not installed").
  Future<Object?> _githubInstallationToken(
    ConnectCaller caller,
    GitHubApi api,
    GitHubGrant grant,
    GitHubScopeRequest request,
    GitHubRepo repo,
    GitHubTokenScope requested,
    GitHubTokenScope granted,
  ) async {
    final installation = await _requireRepoInstallation(
      api,
      request.repoOwner,
      request.repoName,
      expectedOwnerId: repo.ownerId,
    );
    final mint = await api.installationToken(
      installationId: installation.id,
      repoId: repo.id,
      permissions: granted.permissions,
    );
    ctx.log.event('github.mint', {
      'as': GitHubMintActor.app.wire,
      'outcome': 'ok',
      'installation_id': installation.id,
      'repo_id': repo.id,
      'github_user_id': grant.accountId,
      'scope': requested.wire,
      'granted_scope': granted.wire,
      'hashed_token': githubHashedToken(mint.token),
      'github_request_id': mint.requestId,
    });
    return GitHubScopedToken(
      accessToken: mint.token,
      grantedScope: granted.wire,
      expiresAt:
          mint.expiresAt ?? ctx.now().toUtc().add(const Duration(minutes: 55)),
      updatedSeal: grant.updatedSeal,
      installationId: installation.id,
      repositorySelection: mint.repositorySelection,
      repositoryIds: mint.repositoryIds,
      permissions: mint.permissions,
    ).toJson();
  }

  Future<GitHubInstallation> _requireRepoInstallation(
    GitHubApi api,
    String owner,
    String name, {
    required int expectedOwnerId,
  }) async {
    final installation = await api.repoInstallation(owner, name);
    if (installation == null) {
      final onOwner = await api.accountInstallation(owner);
      if (onOwner == null || onOwner.accountId != expectedOwnerId) {
        throw const ConnectException(ConnectErrorCode.notInstalled);
      }
      throw onOwner.suspended
          ? const ConnectException(ConnectErrorCode.suspended)
          : const ConnectException(ConnectErrorCode.repoNotSelected);
    }
    if (installation.accountId != expectedOwnerId) {
      // The repository moved between the two reads; never mint across.
      throw _denied;
    }
    if (installation.suspended) {
      throw const ConnectException(ConnectErrorCode.suspended);
    }
    return installation;
  }

  /// `POST /v1/github/review_comments`: posts a batch of inline pull-request
  /// review comments through a short-lived single-repo `pull_requests: write`
  /// installation token that never leaves Connect and is revoked immediately
  /// after the batch completes.
  Future<Object?> githubReviewComments(
    ConnectCaller caller,
    Map<String, Object?> body,
  ) async {
    final request = _parse(() => GitHubReviewCommentsRequest.fromJson(body));
    try {
      return await _githubReviewComments(caller, request);
    } on ConnectException catch (error) {
      ctx.log.event('github.review_comments', {
        'outcome': 'refused',
        'error': error.code.wire,
        if (error.reason.isNotEmpty) 'reason': error.reason,
      }, ConnectLogLevel.warn);
      rethrow;
    }
  }

  Future<Object?> _githubReviewComments(
    ConnectCaller caller,
    GitHubReviewCommentsRequest request,
  ) async {
    final lane = await ctx.githubLane();
    final (_, _, api) = lane;
    final grant = await resolveGitHub(
      caller,
      request.workspaceId,
      request.seal,
      lane: lane,
      minRemaining: const Duration(minutes: 5),
      admit: (opened) => ctx.quotas.admit(
        ctx.githubAppMintQuotas(caller, opened.header.accountId),
      ),
    );
    final repo = await api.repo(
      grant.parent,
      request.repoOwner,
      request.repoName,
    );
    if (repo.id != request.repoId) {
      throw _denied;
    }
    final allowedOwners = ctx.config.githubAllowedOwners;
    if (allowedOwners.isNotEmpty && !allowedOwners.contains(repo.ownerId)) {
      throw _denied;
    }
    final granted = clampGitHubScope(
      requested: GitHubTokenScope.bot,
      role: GitHubRepoRole.fromPermissions(repo.permissions),
      repoIsPublic: !repo.isPrivate,
    );
    if (granted != GitHubTokenScope.bot) {
      throw const ConnectException(
        ConnectErrorCode.accessDenied,
        reason: 'github_review_comment_role_denied',
      );
    }
    final viewer = await api.user(grant.parent);
    if (viewer.id != grant.accountId || viewer.login.isEmpty) {
      throw _denied;
    }
    final installation = await _requireRepoInstallation(
      api,
      request.repoOwner,
      request.repoName,
      expectedOwnerId: repo.ownerId,
    );
    final mint = await api.installationToken(
      installationId: installation.id,
      repoId: repo.id,
      permissions: const {'metadata': 'read', 'pull_requests': 'write'},
    );
    var postedCount = 0;
    final outcomes = <GitHubReviewCommentOutcome>[];
    try {
      for (var i = 0; i < request.comments.length; i++) {
        final item = request.comments[i];
        final result = await api.postPullRequestReviewComment(
          installationToken: mint.token,
          owner: request.repoOwner,
          name: request.repoName,
          prNumber: request.prNumber,
          commitSha: request.commitSha,
          path: item.path,
          line: item.line,
          side: item.side,
          body: attributeConnectBotComment(viewer.login, item.body),
          startLine: item.startLine,
          startSide: item.startSide,
        );
        if (result.status == GitHubReviewCommentStatus.posted) {
          postedCount++;
        }
        outcomes.add(
          GitHubReviewCommentOutcome(
            index: i,
            status: result.status,
            commentId: result.commentId,
          ),
        );
      }
    } finally {
      await api.revokeInstallationToken(mint.token);
    }
    ctx.log.event('github.review_comments', {
      'outcome': 'ok',
      'installation_id': installation.id,
      'repo_id': repo.id,
      'github_user_id': grant.accountId,
      'count': postedCount,
      'hashed_token': githubHashedToken(mint.token),
      'github_request_id': mint.requestId,
    });
    return GitHubReviewCommentsResponse(
      results: outcomes,
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  static String _childKey(String token) => 'child:${sealDigest(token)}';

  static String _childOwner(String installId, String accountId) =>
      '$installId|$accountId';

  /// Most installations one listing shows.
  static const int _maxListedInstallations = 50;

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
    final installations = (await _cachedInstallations(
      api,
      grant.parent,
    )).take(_maxListedInstallations);
    return GitHubInstallationsResponse(
      installations: [
        for (final installation in installations)
          GitHubInstallationView(
            installationId: installation.id,
            accountId: installation.accountId,
            accountLogin: installation.accountLogin,
            targetType: installation.targetType,
            suspended: installation.suspended,
          ),
      ],
      updatedSeal: grant.updatedSeal,
    ).toJson();
  }

  /// `POST /v1/github/revoke`: one scoped token, or this sign-in.
  ///
  /// Disconnecting ends this sign-in only, never the person's whole
  /// authorization (`.../grant`): on a shared App that would sign them out
  /// of every other server. Its refresh token is spent once (a copy of the
  /// seal then answers `needs_sign_in`), the access token that refresh
  /// returned is deleted unsealed, as are the seal's own access token
  /// (`DELETE /applications/{client_id}/token`) and the children recorded
  /// for the same install, workspace slot and account. It runs under the
  /// seal's rotation lease, so a refresh of the same seal waits for it and
  /// then finds the refresh token spent.
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
      _checkSealHeader(
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
        ctx.log.event('github.child_revoked', {'outcome': 'unknown'});
        return const ConnectAck().toJson();
      }
      if (mintedFor != _childOwner(caller.installId, header.accountId)) {
        ctx.log.event('github.child_revoked', {
          'outcome': 'denied',
        }, ConnectLogLevel.warn);
        throw _denied;
      }
      await api.deleteToken(token);
      await ctx.state.delete(child);
      ctx.log.event('github.child_revoked', {
        'outcome': 'ok',
        'hashed_token': githubHashedToken(token),
      });
      return const ConnectAck().toJson();
    }
    final binding = caller.binding(request.workspaceId);
    _checkSealHeader(
      ctx.sealer.header(request.seal),
      provider: ConnectProvider.github,
      appId: '${creds.appId}',
      minGeneration: config.minSealGeneration,
    );
    var (seal, opened, _) = await _openOrReplay(
      ConnectProvider.github,
      request.seal,
      binding,
    );
    var lease = await _revokeLease(seal);
    // A rotation that finished while this waited left its successor: that
    // one holds the live refresh token.
    for (var hop = 0; hop < 3; hop++) {
      final newer = await _replay(ConnectProvider.github, seal, binding);
      if (newer == null) {
        break;
      }
      await lease.release();
      (seal, opened) = newer;
      lease = await _revokeLease(seal);
    }
    final grant = GitHubGrant(opened, seal, '');
    try {
      final refresh = opened.text('refresh');
      var spent = '';
      if (refresh.isNotEmpty) {
        await ctx.quotas.admit(
          ctx.githubTokenQuotas(
            caller,
            accountId: grant.accountId,
            enforce: false,
          ),
        );
        try {
          spent = (await api.refresh(refresh)).access;
        } on ConnectException catch (error) {
          // Already spent (a rotation won the race, or GitHub dropped it):
          // nothing is left to spend.
          if (error.code != ConnectErrorCode.needsSignIn) {
            rethrow;
          }
        }
      }
      for (final token in {spent, grant.parent}) {
        if (token.isNotEmpty) {
          await api.deleteToken(token);
        }
      }
      final children = await _revokeChildren(binding, grant, api);
      ctx.log.event('grant.revoked', {
        'provider': 'github',
        'scope': 'token',
        'github_user_id': grant.accountId,
        'hashed_token': grant.parent.isEmpty
            ? null
            : githubHashedToken(grant.parent),
        'reason': spent.isEmpty ? 'refresh_already_spent' : 'refresh_spent',
        'count': children,
      });
      return const ConnectAck().toJson();
    } finally {
      await lease.release();
    }
  }

  /// The seal's rotation lease, waited for as a refresh waits: a rotation
  /// running now finishes first, and every later one finds the refresh
  /// token spent.
  Future<StateLease> _revokeLease(String seal) async {
    final key = 'lock:${sealDigest(seal)}';
    for (var waited = 0; ; waited++) {
      final lease = await StateLease.acquire(ctx.state, key, rotationLockTtl);
      if (lease != null) {
        return lease;
      }
      if (waited >= 50) {
        throw _unavailable;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Revokes the live children recorded for [binding] and [grant]'s
  /// account; returns how many.
  Future<int> _revokeChildren(
    SealBinding binding,
    GitHubGrant grant,
    GitHubApi api,
  ) async {
    final recorded = await ctx.state.drain(
      _childrenKey(binding.installId, binding.workspaceId, grant.accountId),
      max: _maxRecordedChildren,
    );
    var revoked = 0;
    for (final sealed in recorded) {
      final OpenedSeal opened;
      try {
        opened = await ctx.sealer.open(
          sealed,
          provider: ConnectProvider.github,
          binding: binding,
          kind: SealKind.childRecord,
        );
      } on ConnectException {
        continue;
      }
      final token = opened.text('child');
      if (!token.startsWith('ghu_') ||
          opened.header.accountId != grant.opened.header.accountId ||
          await ctx.state.get(_childKey(token)) == null) {
        continue; // Expired or revoked already.
      }
      await api.deleteToken(token);
      await ctx.state.delete(_childKey(token));
      revoked++;
    }
    return revoked;
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
