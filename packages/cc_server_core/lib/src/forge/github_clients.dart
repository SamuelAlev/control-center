import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show ForgeCredentialUnavailable, ForgeHttpClientFactory, GitHubApiClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_installations.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:cc_server_core/src/forge/github_request_policy.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:meta/meta.dart';
import 'package:rhttp/rhttp.dart';

export 'package:cc_server_core/src/forge/github_client_types.dart';
export 'package:cc_server_core/src/forge/github_lane_resolver.dart'
    show GitHubLaneIdentity, githubLaneFor, workspaceOwnsGitHubApp;

/// The key of one cached scoped grant. The lane **and** the App id are part
/// of it: a workspace switching lanes, or rotating to another App, never
/// keeps serving a token the previous identity minted.
typedef _GrantKey = ({
  GitHubLane lane,
  String appId,
  String workspaceId,
  String human,
  String repo,
  GitHubTokenScope scope,
  bool viaPerson,
});

/// The key of one per-owner automation client.
typedef _OwnerKey = ({String workspaceId, String owner, String actingUserId});

/// The key of one per-person client.
typedef _PersonKey = ({String userId, String workspaceId});

/// The only way the server obtains an authenticated GitHub client.
///
/// * [asPerson] — a person's own App user token, for anything a person does.
///   Not signed in means no token: the caller says "Sign in to GitHub".
/// * [mintScoped] / [forOwner] — one-repository tokens for work no person is
///   typing (agents, pipelines, pollers, clones, bot replies), clamped to the
///   accountable human's role, from the workspace's App, the server's own
///   App, or Connect. Refusals are final.
///
/// Scoped tokens are cached per `(lane, App, workspace, human, repo, scope)`
/// until fifteen minutes before they expire: GitHub caps user tokens at ten
/// per `(user, app, scope)` and creation at ten an hour, so minting per turn
/// would evict live tokens. A definite refusal (not installed, suspended, not
/// configured) is remembered for a minute, so an uninstalled owner does not
/// cost an App JWT and an installation listing on every request.
///
/// The parts: [GitHubLaneResolver] (which lane and App), [GitHubMinter] (one
/// mint per lane, repository facts, revocation), [GitHubInstallations] (bot
/// presence and install links) and `github_request_policy.dart` (what an
/// automation request may carry).
class GitHubClients {
  /// Creates the service.
  GitHubClients({
    required this.credentials,
    required ProviderAppSettings apps,
    required WorkspaceGitHubAppSettings workspaceApps,
    required this.workspaceLookup,
    required this.members,
    required this.connect,
    required this.isLinkedRepo,
    GitHubRateBudget? rateBudget,
    GitHubRest? rest,
    DateTime Function()? now,
  }) : rateBudget = rateBudget ?? GitHubRateBudget(),
       _rest = rest ?? GitHubRest(),
       _now = now ?? (() => DateTime.now().toUtc()) {
    lanes = GitHubLaneResolver(
      apps: apps,
      workspaceApps: workspaceApps,
      workspaceLookup: workspaceLookup,
      connect: connect,
    );
    _minter = GitHubMinter(
      credentials: credentials,
      lanes: lanes,
      connect: connect,
      rest: _rest,
      now: _now,
    );
    final seals = GitHubSeals(credentials);
    _installations = GitHubInstallations(
      lanes: lanes,
      connect: connect,
      seals: seals,
      rest: _rest,
      humanToken: (workspaceId) async {
        final human = await accountableHuman(workspaceId);
        return human == null
            ? null
            : personToken(human, workspaceId: workspaceId);
      },
      now: _now,
    );
  }

  static const Duration _reuseMargin = Duration(minutes: 15);
  static const Duration _refusalTtl = Duration(minutes: 1);
  static const int _maxCachedGrants = 2048;

  /// Person grants.
  final ForgeCredentials credentials;

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

  /// Which lane, and which App, each workspace runs on.
  late final GitHubLaneResolver lanes;

  late final GitHubMinter _minter;
  late final GitHubInstallations _installations;
  final GitHubRest _rest;
  final DateTime Function() _now;

  final Map<_GrantKey, GitHubScopedGrant> _grants = {};
  final Map<_GrantKey, Future<GitHubScopedGrant>> _minting = {};
  final Map<_GrantKey, ({GitHubScopeRefused refusal, DateTime at})> _refusals =
      {};
  final Set<String> _pausedLinks = {};
  final Map<_PersonKey, GitHubApiClient> _personClients = {};
  final Map<_PersonKey, RhttpClient> _personHttp = {};
  final Map<_OwnerKey, GitHubApiClient> _ownerClients = {};
  final Map<_OwnerKey, RhttpClient> _ownerHttp = {};

  // --- Lanes ---------------------------------------------------------------

  /// The lane [workspaceId]'s automation runs on right now.
  Future<GitHubLane> laneFor(String workspaceId) async =>
      (await lanes.resolve(workspaceId)).lane;

  // --- Installations -------------------------------------------------------

  /// The bot [workspaceId]'s automation converses as, and where its App is
  /// installed, or null when the workspace has no GitHub lane.
  Future<GitHubBotPresence?> botPresence(String workspaceId) =>
      _installations.botPresence(workspaceId);

  /// The link that installs [workspaceId]'s GitHub App, opened by [userId].
  Future<Uri> installLink(String workspaceId, String userId) =>
      _installations.installLink(workspaceId, userId);

  /// The installations [workspaceId]'s App has that [userId] may see.
  Future<List<GitHubInstallationView>> installationsFor(
    String workspaceId,
    String userId,
  ) => _installations.installationsFor(workspaceId, userId);

  /// Binds an existing installation of Connect's shared App to this server.
  Future<void> authorizeServer(
    String workspaceId,
    String userId,
    int installationId,
  ) => _installations.authorizeServer(workspaceId, userId, installationId);

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
        (userId: userId, workspaceId: workspaceId ?? ''),
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
      _personClients.putIfAbsent((
        userId: userId,
        workspaceId: workspaceId ?? '',
      ), () => GitHubApiClient(personHttp(userId, workspaceId: workspaceId)));

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
    // Checked before anything else, lane or not: a stored `..` or `%2e`
    // segment would otherwise be linked now and resolve to another path
    // the moment a lane is configured.
    if (!isGitHubSegment(owner) || !isGitHubSegment(repo)) {
      throw const GitHubScopeRefused(
        GitHubRefusal.invalidRequest,
        'That is not a GitHub repository name.',
      );
    }
    if (await laneFor(workspaceId) == GitHubLane.none) {
      return;
    }
    if (!await isSignedIn(userId, workspaceId: workspaceId)) {
      throw GitHubScopeRefused(
        GitHubRefusal.needsSignIn,
        'Sign in to GitHub to link $owner/$repo: automation in this workspace '
        'can reach only repositories the person linking them can see.',
      );
    }
    _minter.forgetRepo(gitHubRepoKey(workspaceId, userId, owner, repo));
    try {
      await _minter.repoFacts(workspaceId, userId, owner, repo);
    } on GitHubScopeRefused catch (e) {
      if (e.code != GitHubRefusal.accessDenied) {
        rethrow;
      }
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
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
      _minter.forgetRepo(
        gitHubRepoKey(workspaceId, human, link.owner, link.repo),
      );
      try {
        await _minter.repoFacts(workspaceId, human, link.owner, link.repo);
        _pausedLinks.remove(key);
      } on GitHubScopeRefused catch (e) {
        if (e.code == GitHubRefusal.accessDenied && _pausedLinks.add(key)) {
          CcHostLog.warning(
            'github: automation paused for ${link.owner}/${link.repo} in '
            'workspace $workspaceId: its accountable person lost access',
          );
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
        GitHubRefusal.invalidRequest,
        'That is not a GitHub repository name.',
      );
    }
    if (!await isLinkedRepo(workspaceId, owner, repo)) {
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        '$owner/$repo is not linked to this workspace.',
      );
    }
    if ((actingUserId == null || actingUserId.isEmpty) &&
        _pausedLinks.contains(_linkKey(workspaceId, owner, repo))) {
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        'Automation for $owner/$repo is paused: the person accountable for '
        'this workspace can no longer see it on GitHub.',
      );
    }
    final human = await accountableHuman(
      workspaceId,
      actingUserId: actingUserId,
    );
    final identity = await lanes.resolve(workspaceId);
    final _GrantKey key = (
      lane: identity.lane,
      appId: identity.appId,
      workspaceId: workspaceId,
      human: human ?? '',
      repo: '${owner.toLowerCase()}/${repo.toLowerCase()}',
      scope: scope,
      viaPerson: viaPerson,
    );
    final now = _now();
    final cached = _grants[key];
    if (cached != null && cached.expiresAt.isAfter(now.add(_reuseMargin))) {
      return cached;
    }
    final refused = _refusals[key];
    if (refused != null && now.difference(refused.at) < _refusalTtl) {
      throw refused.refusal;
    }
    final inflight = _minting[key];
    if (inflight != null) {
      return inflight;
    }
    final future = _minter.mint(
      lane: identity.lane,
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
      _refusals.remove(key);
      return grant;
    } on GitHubScopeRefused catch (e) {
      if (_isDefinite(e.code)) {
        _refusals
          ..removeWhere((_, v) => now.difference(v.at) >= _refusalTtl)
          ..[key] = (refusal: e, at: now);
      }
      rethrow;
    } finally {
      unawaited(_minting.remove(key));
    }
  }

  /// Refusals nothing but a configuration change undoes, so repeating the
  /// mint within [_refusalTtl] would only repeat the answer.
  static bool _isDefinite(GitHubRefusal code) => switch (code) {
    GitHubRefusal.notInstalled ||
    GitHubRefusal.suspended ||
    GitHubRefusal.notConfigured ||
    GitHubRefusal.installationBoundElsewhere => true,
    _ => false,
  };

  void _remember(_GrantKey key, GitHubScopedGrant grant) {
    final now = _now();
    _grants
      ..removeWhere((_, g) => !g.expiresAt.isAfter(now))
      ..remove(key);
    while (_grants.length >= _maxCachedGrants) {
      _grants.remove(_grants.keys.first);
    }
    _grants[key] = grant;
  }

  // --- Forgetting ----------------------------------------------------------

  /// Drops every cached grant for [userId] (sign-out, removal) and revokes
  /// them upstream.
  Future<void> forgetPerson(String userId) async {
    final mine = _takeGrants((key, _) => key.human == userId);
    _refusals.removeWhere((key, _) => key.human == userId);
    _minter.forgetReposWhere((key) => key.human == userId);
    _personClients.removeWhere((key, _) => key.userId == userId);
    _personHttp.removeWhere((key, _) => key.userId == userId);
    // The person may have been the accountable human whose installations a
    // Connect workspace's bot presence was read through.
    _installations.forgetPresence();
    await _revokeAll(mine);
  }

  /// Drops [userId]'s cached grants in [workspaceId] (removed from it, or
  /// their role changed) and revokes them upstream.
  Future<void> forgetMember(String workspaceId, String userId) async {
    final mine = _takeGrants(
      (key, _) => key.workspaceId == workspaceId && key.human == userId,
    );
    _refusals.removeWhere(
      (key, _) => key.workspaceId == workspaceId && key.human == userId,
    );
    _minter.forgetReposWhere(
      (key) => key.workspaceId == workspaceId && key.human == userId,
    );
    _installations.forgetPresence(workspaceId);
    await _revokeAll(mine);
  }

  /// Drops every cached grant, repository fact and bot presence and revokes
  /// the grants upstream: the server's own App or its Connect changed, so
  /// whatever was minted belongs to an identity this server no longer uses.
  Future<void> forgetAll() async {
    final all = _takeGrants((_, _) => true);
    _refusals.clear();
    _minter.forgetReposWhere((_) => true);
    _installations.forgetPresence();
    await _revokeAll(all);
  }

  /// Drops and revokes every cached grant for [workspaceId], its paused
  /// links, presence and clients (its own App saved or rotated, its mode
  /// changed, the workspace deleted).
  Future<void> forgetWorkspace(String workspaceId) async {
    final theirs = _takeGrants((key, _) => key.workspaceId == workspaceId);
    _refusals.removeWhere((key, _) => key.workspaceId == workspaceId);
    _minter.forgetReposWhere((key) => key.workspaceId == workspaceId);
    _pausedLinks.removeWhere((key) => key.startsWith('$workspaceId\u0000'));
    _installations.forgetPresence(workspaceId);
    _ownerClients.removeWhere((key, _) => key.workspaceId == workspaceId);
    _ownerHttp.removeWhere((key, _) => key.workspaceId == workspaceId);
    rateBudget.forgetWorkspace(workspaceId);
    await _revokeAll(theirs);
  }

  List<GitHubScopedGrant> _takeGrants(
    bool Function(_GrantKey key, GitHubScopedGrant grant) match,
  ) {
    final taken = <GitHubScopedGrant>[];
    _grants.removeWhere((key, grant) {
      if (match(key, grant)) {
        taken.add(grant);
        return true;
      }
      return false;
    });
    return taken;
  }

  Future<void> _revokeAll(List<GitHubScopedGrant> grants) async {
    for (final grant in grants) {
      await _minter.revoke(grant);
    }
  }

  /// Releases the HTTP transport. The service must not be used afterwards.
  void close() => _rest.close();

  // --- Background clients --------------------------------------------------

  /// An HTTP client for automation against repositories under [owner] in
  /// [workspaceId].
  ///
  /// Each request picks its own credential: `/repos/{owner}/{repo}/…` gets a
  /// token for that one repository ([scopeForRequest]), clamped to the
  /// accountable human; a write no one-repository scope covers is refused.
  /// GraphQL and requests that are not about one repository ride the
  /// accountable human's own token, so without an [actingUserId] they may
  /// only read ([refuseUnscopedWrite]). A request with no credential is never
  /// sent anonymously: it fails locally with the status GitHub would have
  /// answered ([tokenForRequest]), so the caller degrades the same way and the
  /// shared per-IP anonymous budget is never touched.
  ///
  /// Automation never approves a pull request: an `APPROVE` review event is
  /// refused before it is sent ([refuseAutomatedApproval]). Approving is a
  /// person's act and rides [asPerson].
  RhttpClient httpForOwner(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) => _ownerHttp.putIfAbsent(
    (
      workspaceId: workspaceId,
      owner: owner.toLowerCase(),
      actingUserId: actingUserId ?? '',
    ),
    () => ForgeHttpClientFactory(
      tokenLookup: (_) async => null,
      requestTokenLookup: (_, method, url) => tokenForRequest(
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
    (
      workspaceId: workspaceId,
      owner: owner.toLowerCase(),
      actingUserId: actingUserId ?? '',
    ),
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
        final app = await lanes.appFor(workspaceId, lane);
        if (app == null) {
          return false;
        }
        return (await app.installations()).any(
          (i) =>
              i.account.toLowerCase() == owner.toLowerCase() && !i.isSuspended,
        );
    }
  }

  /// The credential for one automation request under [owner], or a
  /// [ForgeCredentialUnavailable] carrying the status GitHub would answer.
  ///
  /// Never null: an anonymous request draws on the 60-an-hour per-IP budget
  /// every unauthenticated call on this machine shares, and once that is spent
  /// GitHub rate-limits everything else here too. A suspended installation
  /// fails with GitHub's own suspended shape so callers park the repo at once;
  /// an unreachable provider is transient (503); a missing sign-in is 401; any
  /// other refusal is the 404 GitHub gives a credential that cannot see a repo.
  @visibleForTesting
  Future<String> tokenForRequest(
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
      final token = human == null
          ? null
          : await personToken(human, workspaceId: workspaceId);
      if (token == null || token.isEmpty) {
        throw const ForgeCredentialUnavailable(
          401,
          'No accountable person is signed in to GitHub for this workspace.',
        );
      }
      return token;
    }
    final scope = target.scope;
    if (scope == null || target.owner.toLowerCase() != owner.toLowerCase()) {
      // A client built for one owner never mints for another, and a write
      // no one-repository scope covers gets no credential.
      throw const ForgeCredentialUnavailable(
        404,
        'No single-repository GitHub token covers this request.',
      );
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
        '(${scope.wire}) in workspace $workspaceId: ${e.code.wire}',
      );
      throw switch (e.code) {
        // `isGitHubInstallationSuspendedResponse` keys on this phrasing.
        GitHubRefusal.suspended => const ForgeCredentialUnavailable(
          403,
          'This installation has been suspended.',
        ),
        GitHubRefusal.providerUnavailable ||
        GitHubRefusal.rateLimited => ForgeCredentialUnavailable(503, e.message),
        GitHubRefusal.needsSignIn || GitHubRefusal.notConfigured =>
          ForgeCredentialUnavailable(401, e.message),
        _ => ForgeCredentialUnavailable(404, e.message),
      };
    }
  }

  // --- Request policy ------------------------------------------------------

  /// See [refuseUnscopedGitHubWrite].
  static String? refuseUnscopedWrite(
    String method,
    String url,
    Object? body, {
    required bool personActing,
  }) =>
      refuseUnscopedGitHubWrite(method, url, body, personActing: personActing);

  /// See [refuseAutomatedGitHubApproval].
  static String? refuseAutomatedApproval(
    String method,
    String url,
    Object? body,
  ) => refuseAutomatedGitHubApproval(method, url, body);

  /// See [githubScopeForRequest].
  static ({String owner, String repo, GitHubTokenScope? scope})?
  scopeForRequest(String method, String url) =>
      githubScopeForRequest(method, url);
}
