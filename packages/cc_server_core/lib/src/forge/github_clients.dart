import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show ForgeHttpClientFactory, GitHubApiClient, GitHubAppClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:rhttp/rhttp.dart';

export 'package:cc_server_core/src/forge/github_client_types.dart';

/// The only way the server obtains an authenticated GitHub client.
///
/// * [asPerson] — a person's own App user token, for anything a person does.
///   Not signed in means no token: the caller says "Sign in to GitHub".
/// * [mintScoped] / [forOwner] — one-repository tokens for work no person is
///   typing (agents, pipelines, pollers, clones, bot replies), clamped to the
///   accountable human's role, from the workspace's App, the server's own
///   App, or Connect. Refusals are final.
///
/// Scoped tokens are cached per `(workspace, human, repo, scope)` until
/// fifteen minutes before they expire: GitHub caps user tokens at ten per
/// `(user, app, scope)` and creation at ten an hour, so minting per turn
/// would evict live tokens.
class GitHubClients {
  /// Creates the service.
  GitHubClients({
    required this.credentials,
    required this.apps,
    required this.workspaceApps,
    required this.workspaceLookup,
    required this.members,
    required this.connect,
    required this.isLinkedRepo,
    GitHubRateBudget? rateBudget,
    io.HttpClient? httpClient,
    DateTime Function()? now,
  }) : rateBudget = rateBudget ?? GitHubRateBudget(),
       _http = httpClient ?? (io.HttpClient()..connectionTimeout = _timeout),
       _now = now ?? (() => DateTime.now().toUtc());

  static const Duration _timeout = Duration(seconds: 12);
  static const Duration _reuseMargin = Duration(minutes: 15);
  static const Duration _repoCacheTtl = Duration(minutes: 5);
  static const Duration _presenceTtl = Duration(minutes: 1);
  static const int _maxCachedGrants = 2048;
  static const int _maxCachedRepos = 4096;

  /// Person grants.
  final ForgeCredentials credentials;

  /// The server's own apps.
  final ProviderAppSettings apps;

  /// Per-workspace GitHub Apps.
  final WorkspaceGitHubAppSettings workspaceApps;

  /// Loads a workspace.
  final Future<Workspace?> Function(String workspaceId) workspaceLookup;

  /// Workspace membership, for the accountable-human fallback.
  final WorkspaceMembershipRepository members;

  /// Connect.
  final ConnectClient connect;

  /// Every scoped token is for a repository linked to its workspace.
  final LinkedRepoLookup isLinkedRepo;

  /// The `x-ratelimit-*` readings of every automation and person client
  /// built here, per `(workspace, person)`. Pollers back off on it.
  final GitHubRateBudget rateBudget;

  final io.HttpClient _http;
  final DateTime Function() _now;

  final Map<String, GitHubScopedGrant> _grants = {};
  final Map<String, Future<GitHubScopedGrant>> _minting = {};
  final Map<String, ({_RepoFacts facts, DateTime at})> _repos = {};
  final Set<String> _pausedLinks = {};
  final Map<String, GitHubApiClient> _personClients = {};
  final Map<String, GitHubApiClient> _ownerClients = {};
  final Map<String, RhttpClient> _ownerHttp = {};
  final Map<String, RhttpClient> _personHttp = {};
  final Map<String, ({GitHubBotPresence? presence, DateTime at})> _presence =
      {};

  // --- Lanes ---------------------------------------------------------------

  /// The lane [workspaceId]'s automation runs on right now.
  Future<GitHubLane> laneFor(String workspaceId) async {
    final workspace = workspaceId.isEmpty
        ? null
        : await workspaceLookup(workspaceId);
    if (workspace != null && workspace.githubAuthMode == GithubAuthMode.app) {
      return GitHubLane.workspaceApp;
    }
    final status = await apps.status(ProviderApp.github);
    if (status.effectiveState == OwnAppState.complete) {
      return GitHubLane.ownApp;
    }
    if (status.effectiveState == OwnAppState.partial) {
      return GitHubLane.none;
    }
    final config = await connect.usableConfig();
    return config?.github == null ? GitHubLane.none : GitHubLane.connect;
  }

  Future<GitHubAppClient?> _appFor(String workspaceId, GitHubLane lane) async {
    switch (lane) {
      case GitHubLane.workspaceApp:
        final workspace = await workspaceLookup(workspaceId);
        return workspace == null ? null : workspaceApps.githubApp(workspace);
      case GitHubLane.ownApp:
        return apps.githubApp();
      case GitHubLane.connect || GitHubLane.none:
        return null;
    }
  }

  /// The App's public slug for [workspaceId] (`@<slug>` mentions), or empty.
  Future<String> appSlugFor(String workspaceId) async {
    final lane = await laneFor(workspaceId);
    if (lane == GitHubLane.connect) {
      return (await connect.usableConfig())?.github?.appSlug ?? '';
    }
    final app = await _appFor(workspaceId, lane);
    return (await app?.botInfo())?.slug ?? '';
  }

  /// The bot [workspaceId]'s automation converses as, and where its App is
  /// installed, or null when the workspace has no GitHub lane.
  ///
  /// An App lane reads its own installations. Connect cannot enumerate the
  /// shared App's installations for this server, so it lists the ones the
  /// workspace's accountable human can see (`GET /user/installations`).
  Future<GitHubBotPresence?> botPresence(String workspaceId) async {
    final cached = _presence[workspaceId];
    if (cached != null && _now().difference(cached.at) < _presenceTtl) {
      return cached.presence;
    }
    final presence = await _readPresence(workspaceId);
    _presence[workspaceId] = (presence: presence, at: _now());
    return presence;
  }

  Future<GitHubBotPresence?> _readPresence(String workspaceId) async {
    final lane = await laneFor(workspaceId);
    switch (lane) {
      case GitHubLane.none:
        return null;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final app = await _appFor(workspaceId, lane);
        final info = await app?.botInfo();
        if (app == null || info == null || info.botLogin.isEmpty) {
          return null;
        }
        final installs = await app.installations();
        return GitHubBotPresence(
          botLogin: info.botLogin,
          slug: info.slug,
          owners: [
            for (final i in installs)
              if (i.account.isNotEmpty) i.account,
          ],
          suspendedOwners: {
            for (final i in installs)
              if (i.isSuspended) i.account.toLowerCase(),
          },
        );
      case GitHubLane.connect:
        final config = (await connect.usableConfig())?.github;
        if (config == null) {
          return null;
        }
        final human = await accountableHuman(workspaceId);
        final token = human == null
            ? null
            : await personToken(human, workspaceId: workspaceId);
        if (token == null) {
          return null;
        }
        final installs = await _userInstallations(token, config.appId);
        return GitHubBotPresence(
          botLogin: '${config.appSlug}[bot]',
          slug: config.appSlug,
          owners: [for (final i in installs) i.account],
          suspendedOwners: {
            for (final i in installs)
              if (i.suspended) i.account.toLowerCase(),
          },
        );
    }
  }

  Future<List<({String account, bool suspended})>> _userInstallations(
    String token,
    int appId,
  ) async {
    try {
      final request = await _http.getUrl(
        Uri.https('api.github.com', '/user/installations', {'per_page': '100'}),
      );
      request.followRedirects = false;
      request.headers
        ..set(io.HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set(io.HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(io.HttpHeaders.userAgentHeader, 'control-center')
        ..set('X-GitHub-Api-Version', '2022-11-28');
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decodeStream(response.timeout(_timeout));
      if (response.statusCode != 200) {
        return const [];
      }
      final json = jsonDecode(body);
      final list = json is Map ? json['installations'] : null;
      if (list is! List) {
        return const [];
      }
      return [
        for (final item in list)
          if (item is Map && item['app_id'] == appId)
            if (item['account'] case {
              'login': final String login,
            } when login.isNotEmpty)
              (account: login, suspended: item['suspended_at'] != null),
      ];
    } on Object catch (e) {
      CcHostLog.warning('github: listing installations failed ($e)');
      return const [];
    }
  }

  // --- Installation setup --------------------------------------------------

  /// The link that installs [workspaceId]'s GitHub App, opened by [userId].
  ///
  /// On Connect the link carries a ticket that binds the new installation to
  /// this server (Connect verifies the installer before it records the
  /// binding). An own App needs no binding: it belongs to this server.
  Future<Uri> installLink(String workspaceId, String userId) async {
    final lane = await laneFor(workspaceId);
    switch (lane) {
      case GitHubLane.none:
        throw const GitHubScopeRefused(
          'not_configured',
          'This workspace has no GitHub App to install.',
        );
      case GitHubLane.connect:
        final seal = await _sealFor(userId, workspaceId);
        final started = await connect.githubInstallStart(
          SealRequest(seal: seal.seal, workspaceId: seal.scope),
        );
        await _adoptSeal(userId, seal.scope, started.updatedSeal);
        return started.installUrl;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final slug = (await (await _appFor(
          workspaceId,
          lane,
        ))?.botInfo())?.slug;
        if (slug == null || slug.isEmpty) {
          throw const GitHubScopeRefused(
            'provider_unavailable',
            'GitHub did not answer for this App. Test its settings first.',
          );
        }
        return Uri.https('github.com', '/apps/$slug/installations/new');
    }
  }

  /// The installations [workspaceId]'s App has that [userId] may see.
  ///
  /// On Connect that is the installations the person can see on GitHub,
  /// each saying whether it is bound to this server and whether the person
  /// can bind it. An own App lists every installation; all are this
  /// server's. The `github.installations` op narrows either list to the
  /// accounts owning this workspace's linked repositories.
  Future<List<GitHubInstallationView>> installationsFor(
    String workspaceId,
    String userId,
  ) async {
    final lane = await laneFor(workspaceId);
    switch (lane) {
      case GitHubLane.none:
        return const [];
      case GitHubLane.connect:
        final seal = await _sealFor(userId, workspaceId);
        final listed = await connect.githubInstallations(
          SealRequest(seal: seal.seal, workspaceId: seal.scope),
        );
        await _adoptSeal(userId, seal.scope, listed.updatedSeal);
        return listed.installations;
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final app = await _appFor(workspaceId, lane);
        if (app == null) {
          return const [];
        }
        return [
          for (final i in await app.installations(refresh: true))
            GitHubInstallationView(
              installationId: i.id,
              accountId: i.accountId,
              accountLogin: i.account,
              targetType: i.targetType,
              boundHere: true,
              suspended: i.isSuspended,
              callerIsAdmin: false,
            ),
        ];
    }
  }

  /// Binds an installation of Connect's shared App that already exists (an
  /// organization installed it on GitHub directly) to this server. Connect
  /// checks that [userId] administers the account.
  Future<void> authorizeServer(
    String workspaceId,
    String userId,
    int installationId,
  ) async {
    if (await laneFor(workspaceId) != GitHubLane.connect) {
      throw const GitHubScopeRefused(
        'invalid_request',
        'Only the shared Connect App needs authorizing; this workspace uses '
            'its own.',
      );
    }
    final seal = await _sealFor(userId, workspaceId);
    final ack = await connect.githubAuthorizeServer(
      GitHubAuthorizeServerRequest(
        seal: seal.seal,
        workspaceId: seal.scope,
        installationId: installationId,
      ),
    );
    await _adoptSeal(userId, seal.scope, ack.updatedSeal);
    _presence.remove(workspaceId);
  }

  /// Persists a seal Connect rotated on the way. [scope] is the stored
  /// credential's own scope ([globalWorkspaceScope] for the global row).
  Future<void> _adoptSeal(String userId, String scope, String updated) async {
    if (updated.isEmpty) {
      return;
    }
    await credentials.adoptRotatedSeal(
      ForgeHost.github,
      userId,
      updated,
      workspaceId: scope == globalWorkspaceScope ? null : scope,
    );
  }

  Future<({String seal, String scope})> _sealFor(
    String userId,
    String workspaceId,
  ) async {
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    if (stored == null || !stored.token.isSealed) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'Sign in to GitHub first.',
      );
    }
    return (
      seal: stored.token.seal,
      scope: stored.workspaceId ?? globalWorkspaceScope,
    );
  }

  // --- People --------------------------------------------------------------

  /// [userId]'s own token for [workspaceId], or null when they have not
  /// signed in. Never anybody else's.
  Future<String?> personToken(String userId, {String? workspaceId}) =>
      credentials.personToken(
        ForgeHost.github,
        userId,
        workspaceId: workspaceId,
      );

  /// Whether [userId] is signed in to GitHub for [workspaceId].
  Future<bool> isSignedIn(String userId, {String? workspaceId}) async =>
      (await personToken(userId, workspaceId: workspaceId)) != null;

  /// The authenticated HTTP client acting as [userId]. The token is read per
  /// request, so a sign-in or sign-out applies on the next call; a person
  /// who is not signed in sends no credential at all.
  RhttpClient personHttp(String userId, {String? workspaceId}) =>
      _personHttp.putIfAbsent(
        '$userId\u0000${workspaceId ?? ''}',
        () => ForgeHttpClientFactory(
          tokenLookup: (_) => personToken(userId, workspaceId: workspaceId),
          onResponse: workspaceId == null || workspaceId.isEmpty
              ? null
              : (_, _, headers) =>
                    rateBudget.observe(workspaceId, headers, userId: userId),
        ).of(ForgeHost.github),
      );

  /// A GitHub client acting as [userId].
  GitHubApiClient asPerson(String userId, {String? workspaceId}) =>
      _personClients.putIfAbsent(
        '$userId\u0000${workspaceId ?? ''}',
        () => GitHubApiClient(personHttp(userId, workspaceId: workspaceId)),
      );

  // --- Accountable humans --------------------------------------------------

  /// The human whose access bounds automation in [workspaceId]: [actingUserId]
  /// when given and still a member, else the workspace owner when they are a
  /// member. Never an unrelated server owner.
  Future<String?> accountableHuman(
    String workspaceId, {
    String? actingUserId,
  }) async {
    if (workspaceId.isEmpty) {
      return null;
    }
    if (actingUserId != null && actingUserId.isNotEmpty) {
      return await members.getMember(workspaceId, actingUserId) == null
          ? null
          : actingUserId;
    }
    final owner = (await workspaceLookup(workspaceId))?.ownerUserId;
    if (owner == null || owner.isEmpty) {
      return null;
    }
    return await members.getMember(workspaceId, owner) == null ? null : owner;
  }

  // --- Repository links ----------------------------------------------------

  /// Refuses linking [owner]/[repo] to [workspaceId] unless [userId] can see
  /// it on GitHub with their own sign-in. Without a GitHub lane nothing can
  /// mint for the link, so there is nothing to check. Throws
  /// [GitHubScopeRefused].
  Future<void> verifyLink(
    String workspaceId,
    String userId,
    String owner,
    String repo,
  ) async {
    if (await laneFor(workspaceId) == GitHubLane.none) {
      return;
    }
    if (!isGitHubSegment(owner) || !isGitHubSegment(repo)) {
      throw const GitHubScopeRefused(
        'invalid_request',
        'That is not a GitHub repository name.',
      );
    }
    if (!await isSignedIn(userId, workspaceId: workspaceId)) {
      throw GitHubScopeRefused(
        'needs_sign_in',
        'Sign in to GitHub to link $owner/$repo: automation in this workspace '
            'can reach only repositories the person linking them can see.',
      );
    }
    _repos.remove(_repoKey(workspaceId, userId, owner, repo));
    try {
      await _repoFacts(workspaceId, userId, owner, repo);
    } on GitHubScopeRefused catch (e) {
      if (e.code != 'access_denied') {
        rethrow;
      }
      throw GitHubScopeRefused(
        'access_denied',
        'Your GitHub account cannot see $owner/$repo, so it cannot be linked '
            'to this workspace.',
      );
    }
    _pausedLinks.remove(_linkKey(workspaceId, owner, repo));
  }

  /// Re-reads every repository in [linked] as [workspaceId]'s accountable
  /// human. One they can no longer see pauses its automation (no token is
  /// minted for it without an acting person) until a later sweep sees it
  /// again; an outage or a missing sign-in changes nothing. Returns how many
  /// links are paused in [workspaceId] afterwards.
  Future<int> sweepLinks(
    String workspaceId,
    List<({String owner, String repo})> linked,
  ) async {
    final human = await accountableHuman(workspaceId);
    if (human == null || await laneFor(workspaceId) == GitHubLane.none) {
      return 0;
    }
    var paused = 0;
    for (final link in linked) {
      final key = _linkKey(workspaceId, link.owner, link.repo);
      _repos.remove(_repoKey(workspaceId, human, link.owner, link.repo));
      try {
        await _repoFacts(workspaceId, human, link.owner, link.repo);
        _pausedLinks.remove(key);
      } on GitHubScopeRefused catch (e) {
        if (e.code == 'access_denied') {
          if (_pausedLinks.add(key)) {
            CcHostLog.warning(
              'github: automation paused for ${link.owner}/${link.repo} in '
              'workspace $workspaceId: its accountable person lost access',
            );
          }
        }
      }
      if (_pausedLinks.contains(key)) {
        paused++;
      }
    }
    return paused;
  }

  static String _linkKey(String workspaceId, String owner, String repo) =>
      '$workspaceId\u0000${owner.toLowerCase()}/${repo.toLowerCase()}';

  static String _repoKey(
    String workspaceId,
    String human,
    String owner,
    String repo,
  ) =>
      '$workspaceId\u0000$human\u0000${owner.toLowerCase()}/'
      '${repo.toLowerCase()}';

  // --- Scoped tokens -------------------------------------------------------

  /// A token for exactly [owner]/[repo] with at most [scope], bounded by the
  /// accountable human. The repository must be linked to [workspaceId].
  ///
  /// [viaPerson] downscopes the human's own user token (`/token/scoped`)
  /// even on an own App — terminal rigs, so commits there are the person's.
  /// Throws [GitHubScopeRefused]; there is no fallback.
  Future<GitHubScopedGrant> mintScoped({
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    String? actingUserId,
    bool viaPerson = false,
  }) async {
    if (!isGitHubSegment(owner) || !isGitHubSegment(repo)) {
      throw const GitHubScopeRefused(
        'invalid_request',
        'That is not a GitHub repository name.',
      );
    }
    if (!await isLinkedRepo(workspaceId, owner, repo)) {
      throw GitHubScopeRefused(
        'access_denied',
        '$owner/$repo is not linked to this workspace.',
      );
    }
    if ((actingUserId == null || actingUserId.isEmpty) &&
        _pausedLinks.contains(_linkKey(workspaceId, owner, repo))) {
      throw GitHubScopeRefused(
        'access_denied',
        'Automation for $owner/$repo is paused: the person accountable for '
            'this workspace can no longer see it on GitHub.',
      );
    }
    final human = await accountableHuman(
      workspaceId,
      actingUserId: actingUserId,
    );
    // The lane is part of the key: a workspace switching to its own App (or
    // the server switching to Connect) must never keep serving a token the
    // previous identity minted.
    final lane = await laneFor(workspaceId);
    final key = [
      lane.wire,
      workspaceId,
      human ?? '',
      owner.toLowerCase(),
      repo.toLowerCase(),
      scope.wire,
      if (viaPerson) 'person',
    ].join('\u0000');
    final cached = _grants[key];
    if (cached != null && cached.expiresAt.isAfter(_now().add(_reuseMargin))) {
      return cached;
    }
    final inflight = _minting[key];
    if (inflight != null) {
      return inflight;
    }
    final future = _mint(
      lane: lane,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      scope: scope,
      human: human,
      viaPerson: viaPerson,
    );
    _minting[key] = future;
    try {
      final grant = await future;
      _remember(key, grant);
      return grant;
    } finally {
      unawaited(_minting.remove(key));
    }
  }

  void _remember(String key, GitHubScopedGrant grant) {
    final now = _now();
    _grants
      ..removeWhere((_, g) => !g.expiresAt.isAfter(now))
      ..remove(key);
    while (_grants.length >= _maxCachedGrants) {
      _grants.remove(_grants.keys.first);
    }
    _grants[key] = grant;
  }

  Future<GitHubScopedGrant> _mint({
    required GitHubLane lane,
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
    required bool viaPerson,
  }) async {
    switch (lane) {
      case GitHubLane.none:
        throw const GitHubScopeRefused(
          'not_configured',
          'GitHub is not set up on this server. Turn on Control Center '
              'Connect or add your own GitHub App in Settings.',
        );
      case GitHubLane.connect:
        return _mintViaConnect(
          workspaceId: workspaceId,
          owner: owner,
          repo: repo,
          scope: scope,
          human: human,
        );
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        if (viaPerson) {
          return _downscopePerson(
            workspaceId: workspaceId,
            lane: lane,
            owner: owner,
            repo: repo,
            scope: scope,
            human: human,
          );
        }
        return _mintViaApp(
          workspaceId: workspaceId,
          lane: lane,
          owner: owner,
          repo: repo,
          scope: scope,
          human: human,
        );
    }
  }

  Future<GitHubTokenScope> _clampForHuman({
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
  }) async {
    if (human == null) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'Nobody accountable for this workspace is signed in to GitHub.',
      );
    }
    final facts = await _repoFacts(workspaceId, human, owner, repo);
    final clamped = clampGitHubScope(
      requested: scope,
      role: facts.role,
      repoIsPublic: facts.isPublic,
    );
    if (clamped == null) {
      throw GitHubScopeRefused(
        'access_denied',
        facts.isPublic && facts.role == GitHubRepoRole.pull
            ? 'Reading the public repository $owner/$repo through the GitHub '
                  'App needs triage access or more; the accountable person '
                  'only has read access.'
            : 'The accountable person cannot access $owner/$repo on GitHub.',
      );
    }
    return clamped;
  }

  Future<GitHubScopedGrant> _mintViaApp({
    required String workspaceId,
    required GitHubLane lane,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
  }) async {
    final app = await _appFor(workspaceId, lane);
    if (app == null) {
      throw const GitHubScopeRefused(
        'not_configured',
        'This workspace uses its own GitHub App, but its app id or private '
            'key is missing.',
      );
    }
    // Reads too: an installation token is never broader than what the
    // accountable person can see themselves.
    final granted = await _clampForHuman(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      scope: scope,
      human: human,
    );
    if (await app.isOwnerSuspended(owner)) {
      throw GitHubScopeRefused(
        'suspended',
        'The GitHub App installation on $owner is suspended.',
      );
    }
    final minted = await app.mintScopedForOwner(
      owner,
      repositories: [repo],
      permissions: granted.permissions,
    );
    if (minted == null) {
      throw GitHubScopeRefused(
        'not_installed',
        'The GitHub App is not installed on $owner. Install it from Settings.',
      );
    }
    return GitHubScopedGrant(
      token: minted.token,
      scope: granted,
      expiresAt:
          minted.expiresAt?.toUtc() ?? _now().add(const Duration(minutes: 55)),
      lane: lane,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      accountableUserId: human,
    );
  }

  /// `/applications/{client_id}/token/scoped` on an own App: the person's
  /// user token, narrowed to one repository.
  Future<GitHubScopedGrant> _downscopePerson({
    required String workspaceId,
    required GitHubLane lane,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
  }) async {
    if (human == null) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'Sign in to GitHub to use it from this terminal.',
      );
    }
    final parent = await personToken(human, workspaceId: workspaceId);
    if (parent == null) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'Sign in to GitHub to use it from this terminal.',
      );
    }
    final granted = await _clampForHuman(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      scope: scope,
      human: human,
    );
    final facts = await _repoFacts(workspaceId, human, owner, repo);
    final workspace = lane == GitHubLane.workspaceApp
        ? await workspaceLookup(workspaceId)
        : null;
    final creds = workspace != null
        ? await workspaceApps.oauthCredentials(workspace)
        : await apps.oauthCredentials(ProviderApp.github);
    if (creds == null) {
      throw const GitHubScopeRefused(
        'not_configured',
        'The GitHub App has no client secret configured.',
      );
    }
    final request = await _http.postUrl(
      Uri.https(
        'api.github.com',
        '/applications/${Uri.encodeComponent(creds.clientId)}/token/scoped',
      ),
    );
    request.followRedirects = false;
    request.headers
      ..set(
        io.HttpHeaders.authorizationHeader,
        'Basic ${base64Encode(utf8.encode('${creds.clientId}:${creds.clientSecret}'))}',
      )
      ..set(io.HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(io.HttpHeaders.userAgentHeader, 'control-center')
      ..set('X-GitHub-Api-Version', '2022-11-28')
      ..contentType = io.ContentType.json;
    request.write(
      jsonEncode({
        'access_token': parent,
        'target_id': facts.ownerId,
        'repository_ids': [facts.id],
        'permissions': granted.permissions,
      }),
    );
    final response = await request.close().timeout(_timeout);
    final body = await utf8.decodeStream(response.timeout(_timeout));
    if (response.statusCode != 200) {
      throw GitHubScopeRefused(
        response.statusCode >= 500 ? 'provider_unavailable' : 'access_denied',
        'GitHub refused to narrow the sign-in to $owner/$repo.',
      );
    }
    final json = jsonDecode(body);
    final token = json is Map ? json['token'] : null;
    if (json is! Map || token is! String || !token.startsWith('ghu_')) {
      throw const GitHubScopeRefused(
        'provider_unavailable',
        'GitHub returned no narrowed token.',
      );
    }
    if (!scopedTokenMatches(
      json,
      repoId: facts.id,
      permissions: granted.permissions,
    )) {
      throw GitHubScopeRefused(
        'access_denied',
        'GitHub did not narrow the sign-in to $owner/$repo alone.',
      );
    }
    final expires = await credentials.personCredential(
      ForgeHost.github,
      human,
      workspaceId: workspaceId,
    );
    return GitHubScopedGrant(
      token: token,
      scope: granted,
      expiresAt: expires?.expiresAt ?? _now().add(const Duration(hours: 1)),
      lane: lane,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      accountableUserId: human,
    );
  }

  Future<GitHubScopedGrant> _mintViaConnect({
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
  }) async {
    if (human == null) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'Nobody accountable for this workspace is signed in to GitHub.',
      );
    }
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      human,
      workspaceId: workspaceId,
    );
    if (stored == null || !stored.token.isSealed) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'The accountable person needs to sign in to GitHub again.',
      );
    }
    final facts = await _repoFacts(workspaceId, human, owner, repo);
    try {
      final minted = await connect.githubScope(
        GitHubScopeRequest(
          seal: stored.token.seal,
          workspaceId: stored.workspaceId ?? globalWorkspaceScope,
          repoId: facts.id,
          repoOwner: owner,
          repoName: repo,
          scope: scope.wire,
        ),
      );
      if (minted.updatedSeal.isNotEmpty) {
        await credentials.adoptRotatedSeal(
          ForgeHost.github,
          human,
          minted.updatedSeal,
          workspaceId: stored.workspaceId,
        );
      }
      final granted =
          GitHubTokenScope.fromWire(minted.grantedScope) ??
          GitHubTokenScope.read;
      return GitHubScopedGrant(
        token: minted.accessToken,
        scope: granted,
        expiresAt: minted.expiresAt,
        lane: GitHubLane.connect,
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        accountableUserId: human,
        connectSeal: minted.updatedSeal.isNotEmpty
            ? minted.updatedSeal
            : stored.token.seal,
        connectSealScope: stored.workspaceId ?? globalWorkspaceScope,
      );
    } on ConnectException catch (e) {
      if (e.code.clearsGrant) {
        await credentials.clearToken(
          ForgeHost.github,
          userId: human,
          workspaceId: stored.workspaceId,
        );
      }
      throw GitHubScopeRefused(e.code.wire, _connectRefusal(e.code, owner));
    }
  }

  static String _connectRefusal(ConnectErrorCode code, String owner) =>
      switch (code) {
        ConnectErrorCode.needsSignIn =>
          'The accountable person needs to sign in to GitHub again.',
        ConnectErrorCode.accessDenied =>
          'The accountable person cannot access this repository.',
        ConnectErrorCode.notInstalled =>
          'The Control Center GitHub App is not installed on $owner.',
        ConnectErrorCode.installationBoundElsewhere =>
          'The GitHub App installation on $owner is bound to another '
              'server. An admin of $owner can authorize this server in '
              'Settings.',
        ConnectErrorCode.suspended =>
          'The GitHub App installation on $owner is suspended.',
        ConnectErrorCode.installBlocked =>
          'Control Center Connect refused this server.',
        _ => 'GitHub is unreachable through Control Center Connect right now.',
      };

  /// Repository id, owner id, visibility and the human's role, read with the
  /// human's own token (cached briefly).
  Future<_RepoFacts> _repoFacts(
    String workspaceId,
    String human,
    String owner,
    String repo,
  ) async {
    final key = _repoKey(workspaceId, human, owner, repo);
    final cached = _repos[key];
    if (cached != null && _now().difference(cached.at) < _repoCacheTtl) {
      return cached.facts;
    }
    final token = await personToken(human, workspaceId: workspaceId);
    if (token == null) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'The accountable person needs to sign in to GitHub.',
      );
    }
    final request = await _http.getUrl(
      Uri.https(
        'api.github.com',
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}',
      ),
    );
    request.followRedirects = false;
    request.headers
      ..set(io.HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set(io.HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(io.HttpHeaders.userAgentHeader, 'control-center')
      ..set('X-GitHub-Api-Version', '2022-11-28');
    final io.HttpClientResponse response;
    final String body;
    try {
      response = await request.close().timeout(_timeout);
      body = await utf8.decodeStream(response.timeout(_timeout));
    } on Object {
      throw const GitHubScopeRefused(
        'provider_unavailable',
        'GitHub is unreachable right now.',
      );
    }
    if (response.statusCode == 401) {
      throw const GitHubScopeRefused(
        'needs_sign_in',
        'The accountable person needs to sign in to GitHub again.',
      );
    }
    if (response.statusCode == 404 || response.statusCode == 403) {
      throw GitHubScopeRefused(
        'access_denied',
        'The accountable person cannot access $owner/$repo on GitHub.',
      );
    }
    if (response.statusCode != 200) {
      throw const GitHubScopeRefused(
        'provider_unavailable',
        'GitHub is unreachable right now.',
      );
    }
    final json = jsonDecode(body);
    if (json is! Map) {
      throw const GitHubScopeRefused(
        'provider_unavailable',
        'GitHub returned an unreadable repository.',
      );
    }
    final id = json['id'];
    final ownerJson = json['owner'];
    final ownerId = ownerJson is Map ? ownerJson['id'] : null;
    if (id is! int || ownerId is! int) {
      throw const GitHubScopeRefused(
        'provider_unavailable',
        'GitHub returned an unreadable repository.',
      );
    }
    final facts = _RepoFacts(
      id: id,
      ownerId: ownerId,
      isPublic: json['private'] != true && json['visibility'] != 'internal',
      role: GitHubRepoRole.fromPermissions(json['permissions']),
    );
    final now = _now();
    _repos.removeWhere((_, v) => now.difference(v.at) >= _repoCacheTtl);
    while (_repos.length >= _maxCachedRepos) {
      _repos.remove(_repos.keys.first);
    }
    _repos[key] = (facts: facts, at: now);
    return facts;
  }

  /// Drops every cached grant for [userId] (sign-out, removal) and revokes
  /// the Connect ones upstream.
  Future<void> forgetPerson(String userId) async {
    final mine = _grants.entries
        .where((e) => e.value.accountableUserId == userId)
        .toList();
    for (final entry in mine) {
      _grants.remove(entry.key);
    }
    _repos.removeWhere((key, _) => key.split('\u0000')[1] == userId);
    _personClients.removeWhere((key, _) => key.startsWith('$userId\u0000'));
    _personHttp.removeWhere((key, _) => key.startsWith('$userId\u0000'));
    for (final entry in mine) {
      await _revokeUpstream(entry.value);
    }
  }

  /// Drops [userId]'s cached grants in [workspaceId] (removed from it) and
  /// revokes the Connect ones upstream.
  Future<void> forgetMember(String workspaceId, String userId) async {
    final mine = _grants.entries
        .where(
          (e) =>
              e.value.workspaceId == workspaceId &&
              e.value.accountableUserId == userId,
        )
        .toList();
    for (final entry in mine) {
      _grants.remove(entry.key);
    }
    _repos.removeWhere((key, _) {
      final parts = key.split('\u0000');
      return parts[0] == workspaceId && parts[1] == userId;
    });
    _presence.remove(workspaceId);
    for (final entry in mine) {
      await _revokeUpstream(entry.value);
    }
  }

  /// Drops every cached grant, repository fact and bot presence: the
  /// server's own App or its Connect changed, so whatever was minted belongs
  /// to an identity this server no longer uses.
  void forgetAll() {
    _grants.clear();
    _repos.clear();
    _presence.clear();
  }

  /// Drops every cached grant for [workspaceId] (mode change, deletion).
  void forgetWorkspace(String workspaceId) {
    _grants.removeWhere((_, grant) => grant.workspaceId == workspaceId);
    _pausedLinks.removeWhere((key) => key.startsWith('$workspaceId\u0000'));
    _presence.remove(workspaceId);
    _ownerClients.removeWhere((key, _) => key.startsWith('$workspaceId\u0000'));
    _ownerHttp.removeWhere((key, _) => key.startsWith('$workspaceId\u0000'));
  }

  Future<void> _revokeUpstream(GitHubScopedGrant grant) async {
    try {
      switch (grant.lane) {
        case GitHubLane.connect:
          if (grant.connectSeal.isEmpty) {
            return;
          }
          await connect.githubRevoke(
            GitHubRevokeRequest(
              workspaceId: grant.connectSealScope,
              seal: grant.connectSeal,
              scopedToken: grant.token,
            ),
          );
        case GitHubLane.workspaceApp || GitHubLane.ownApp:
          if (grant.token.startsWith('ghs_')) {
            await (await _appFor(
              grant.workspaceId,
              grant.lane,
            ))?.revokeToken(grant.token);
          }
        case GitHubLane.none:
          break;
      }
    } on Object catch (e) {
      // Best effort: the token expires on its own.
      CcHostLog.warning('github: scoped token revoke failed ($e)');
    }
  }

  // --- Background clients --------------------------------------------------

  /// An HTTP client for automation against repositories under [owner] in
  /// [workspaceId].
  ///
  /// Each request picks its own credential: `/repos/{owner}/{repo}/…` gets a
  /// token for that one repository ([scopeForRequest]), clamped to the
  /// accountable human; a write no one-repository scope covers is refused.
  /// GraphQL and requests that are not about one repository ride the
  /// accountable human's own token, so without an [actingUserId] they may
  /// only read ([refuseUnscopedWrite]). A refused mint sends no credential,
  /// so the call fails like any unauthenticated one and the caller degrades.
  ///
  /// Automation never approves a pull request: an `APPROVE` review event is
  /// refused before it is sent ([refuseAutomatedApproval]). Approving is a
  /// person's act and rides [asPerson].
  RhttpClient httpForOwner(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) => _ownerHttp.putIfAbsent(
    '$workspaceId\u0000${owner.toLowerCase()}\u0000${actingUserId ?? ''}',
    () => ForgeHttpClientFactory(
      tokenLookup: (_) async => null,
      requestTokenLookup: (_, method, url) => _tokenForRequest(
        workspaceId,
        owner,
        method: method,
        url: url,
        actingUserId: actingUserId,
      ),
      requestGuard: (_, method, url, body) =>
          refuseAutomatedApproval(method, url, body) ??
          refuseUnscopedWrite(
            method,
            url,
            body,
            personActing: actingUserId != null && actingUserId.isNotEmpty,
          ),
      onResponse: (_, _, headers) =>
          rateBudget.observe(workspaceId, headers, userId: actingUserId),
    ).of(ForgeHost.github),
  );

  /// A GitHub client for automation under [owner] in [workspaceId].
  GitHubApiClient forOwner(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) => _ownerClients.putIfAbsent(
    '$workspaceId\u0000${owner.toLowerCase()}\u0000${actingUserId ?? ''}',
    () => GitHubApiClient(
      httpForOwner(workspaceId, owner, actingUserId: actingUserId),
    ),
  );

  /// Whether automation under [owner] in [workspaceId] has any way to
  /// authenticate right now.
  Future<bool> canReach(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) async {
    final lane = await laneFor(workspaceId);
    switch (lane) {
      case GitHubLane.none:
        return false;
      case GitHubLane.connect:
        final human = await accountableHuman(
          workspaceId,
          actingUserId: actingUserId,
        );
        return human != null &&
            await isSignedIn(human, workspaceId: workspaceId);
      case GitHubLane.workspaceApp || GitHubLane.ownApp:
        final app = await _appFor(workspaceId, lane);
        if (app == null) {
          return false;
        }
        return (await app.installations()).any(
          (i) =>
              i.account.toLowerCase() == owner.toLowerCase() && !i.isSuspended,
        );
    }
  }

  Future<String?> _tokenForRequest(
    String workspaceId,
    String owner, {
    required String method,
    required String url,
    String? actingUserId,
  }) async {
    final target = scopeForRequest(method, url);
    if (target == null) {
      final human = await accountableHuman(
        workspaceId,
        actingUserId: actingUserId,
      );
      return human == null
          ? null
          : personToken(human, workspaceId: workspaceId);
    }
    final scope = target.scope;
    if (scope == null || target.owner.toLowerCase() != owner.toLowerCase()) {
      // A client built for one owner never mints for another, and a write
      // no one-repository scope covers gets no credential.
      return null;
    }
    try {
      return (await mintScoped(
        workspaceId: workspaceId,
        owner: target.owner,
        repo: target.repo,
        scope: scope,
        actingUserId: actingUserId,
      )).token;
    } on GitHubScopeRefused catch (e) {
      CcHostLog.warning(
        'github: no token for ${target.owner}/${target.repo} '
        '(${scope.wire}) in workspace $workspaceId: ${e.code}',
      );
      return null;
    }
  }

  /// Why a request must not be sent on an automation client, or null.
  ///
  /// A `/repos/{o}/{r}/…` write that no one-repository scope covers is
  /// refused. Anything else rides a person's whole sign-in, so unless that
  /// person is the one acting ([personActing]) only reads pass: `GET`/`HEAD`
  /// and GraphQL queries. GraphQL mutations and other writes are refused.
  static String? refuseUnscopedWrite(
    String method,
    String url,
    Object? body, {
    required bool personActing,
  }) {
    final target = scopeForRequest(method, url);
    if (target != null) {
      return target.scope == null
          ? 'No single-repository GitHub token covers $method $url.'
          : null;
    }
    if (personActing) {
      return null;
    }
    final verb = method.toUpperCase();
    if (verb == 'GET' || verb == 'HEAD') {
      return null;
    }
    final segments = (Uri.tryParse(url)?.pathSegments ?? const <String>[])
        .where((s) => s.isNotEmpty)
        .toList();
    final isGraphQl =
        verb == 'POST' && segments.length == 1 && segments.single == 'graphql';
    if (isGraphQl && !_isGraphQlWrite(body)) {
      return null;
    }
    return 'Automation writes to GitHub only through a one-repository token; '
        'a person must do this from their own account.';
  }

  /// Whether a GraphQL request body may change anything. Unreadable bodies
  /// count as writes.
  static bool _isGraphQlWrite(Object? body) {
    final query = body is Map ? body['query'] : null;
    if (query is! String) {
      return true;
    }
    final code = query
        .replaceAll(RegExp(r'"""[\s\S]*?"""'), '""')
        .replaceAll(RegExp(r'"(?:[^"\\]|\\.)*"'), '""')
        .replaceAll(RegExp('#[^\n]*'), '');
    return RegExp(r'\b(mutation|subscription)\b').hasMatch(code);
  }

  /// Why an automation request must not be sent, or null: a pull request
  /// review (`POST /repos/{o}/{r}/pulls/{n}/reviews`, or submitting a pending
  /// one at `.../reviews/{id}/events`) or a GraphQL review mutation whose
  /// event is `APPROVE`. Comments and change requests pass.
  static String? refuseAutomatedApproval(
    String method,
    String url,
    Object? body,
  ) {
    if (method.toUpperCase() != 'POST') {
      return null;
    }
    final segments = (Uri.tryParse(url)?.pathSegments ?? const <String>[])
        .where((s) => s.isNotEmpty)
        .toList();
    const refusal =
        'Automation never approves a pull request; a person approves from '
        'their own account.';
    if (segments.length == 1 && segments.single == 'graphql') {
      final query = body is Map ? body['query'] : null;
      final variables = body is Map ? body['variables'] : null;
      final isReviewMutation =
          query is String && query.toLowerCase().contains('pullrequestreview');
      final approves =
          (query is String &&
              RegExp(r'\bAPPROVE\b', caseSensitive: false).hasMatch(query)) ||
          _anyApprove(variables);
      return isReviewMutation && approves ? refusal : null;
    }
    final isReview =
        segments.length >= 6 &&
        segments[0] == 'repos' &&
        segments[3] == 'pulls' &&
        segments[5] == 'reviews' &&
        (segments.length == 6 ||
            (segments.length == 8 && segments[7] == 'events'));
    final event = body is Map ? body['event'] : null;
    return isReview && event is String && event.toUpperCase() == 'APPROVE'
        ? refusal
        : null;
  }

  static bool _anyApprove(Object? value) => switch (value) {
    final String s => s.toUpperCase() == 'APPROVE',
    final Map<Object?, Object?> m => m.values.any(_anyApprove),
    final List<Object?> l => l.any(_anyApprove),
    _ => false,
  };

  /// The repository and scope a REST request needs, or null when it is not
  /// about one repository (GraphQL, search, orgs, users).
  ///
  /// A write is mapped only where a scope carries the permission it needs:
  /// issues and PR conversation `bot`, code and pull requests `write`. Any
  /// other `/repos/{o}/{r}` write (statuses, checks, actions, settings…), or
  /// a malformed repository path, answers a null scope: no token.
  static ({String owner, String repo, GitHubTokenScope? scope})?
  scopeForRequest(String method, String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.first != 'repos') {
      return null;
    }
    if (segments.length < 3 ||
        !isGitHubSegment(segments[1]) ||
        !isGitHubSegment(segments[2])) {
      return (
        owner: segments.length > 1 ? segments[1] : '',
        repo: segments.length > 2 ? segments[2] : '',
        scope: null,
      );
    }
    final owner = segments[1];
    final repo = segments[2];
    final verb = method.toUpperCase();
    if (verb == 'GET' || verb == 'HEAD') {
      return (owner: owner, repo: repo, scope: GitHubTokenScope.read);
    }
    return (owner: owner, repo: repo, scope: _writeScope(segments.sublist(3)));
  }

  static GitHubTokenScope? _writeScope(List<String> rest) {
    if (rest.isEmpty) {
      return null;
    }
    switch (rest.first) {
      case 'issues':
        return GitHubTokenScope.bot;
      case 'pulls':
        const conversation = {
          'comments',
          'reviews',
          'reactions',
          'labels',
          'assignees',
          'requested_reviewers',
        };
        if (rest.contains('merge') || rest.contains('update-branch')) {
          return GitHubTokenScope.write;
        }
        return rest.length == 1 || rest.any(conversation.contains)
            ? GitHubTokenScope.bot
            : GitHubTokenScope.write;
      case 'contents' || 'git' || 'merges' || 'stacks':
        return GitHubTokenScope.write;
      default:
        return null;
    }
  }
}

final class _RepoFacts {
  const _RepoFacts({
    required this.id,
    required this.ownerId,
    required this.isPublic,
    required this.role,
  });

  final int id;
  final int ownerId;
  final bool isPublic;
  final GitHubRepoRole role;
}
