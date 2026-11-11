import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart'
    show
        ForgeCredentialUnavailable,
        ForgeHttpClientFactory,
        GitHubApiClient,
        createHttpClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_automation_request_policy.dart'
    show forgeRequestPathTemplate;
import 'package:cc_server_core/src/forge/forge_client_cache.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart'
    show ConfirmForgeRepo, ConfirmPersonForgeRequest, RepoLinkVerdict;
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_graphql_policy.dart';
import 'package:cc_server_core/src/forge/github_installations.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_link_checks.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_rate_budget.dart';
import 'package:cc_server_core/src/forge/github_request_policy.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:meta/meta.dart';
import 'package:rhttp/rhttp.dart';

export 'package:cc_server_core/src/forge/github_client_types.dart';
export 'package:cc_server_core/src/forge/github_lane_resolver.dart'
    show GitHubLaneIdentity, githubLaneFor;

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

/// The key of one per-repository automation client.
typedef _RepoClientKey = ({
  String workspaceId,
  String owner,
  String repo,
  String actingUserId,
  bool viaPerson,
});

/// The key of one per-person client.
typedef _PersonKey = ({String userId, String workspaceId});

/// The only way the server obtains an authenticated GitHub client.
///
/// * [asPerson] — a person's own App user token, for anything a person does.
///   Not signed in means no token: the caller says "Sign in to GitHub".
/// * [mintScoped] / [forOwner] / [forRepo] — one-repository tokens for work
///   no person is typing (agents, pipelines, pollers, clones, bot replies),
///   clamped to the accountable human's role, from the workspace's App, the
///   server's own App, or Connect: the App's bot on every lane, except
///   `viaPerson` (the person's own sign-in narrowed to the repository, for
///   pushes and pull requests made in their name). Refusals are final, and
///   automation with no acting person also stops on a blocking
///   [RepoAccessRegistry] record.
/// * [forSkillSource] — read-only one-repository tokens for the skill
///   catalogs a workspace browses and installs from ([isSkillSource]).
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
/// presence and install links), [GitHubLinkChecks] (what automation meets
/// on a linked repository, and the records of it) and
/// `github_request_policy.dart` (what an automation request may carry).
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
    required this.mayReadRepo,
    required this.repoAccess,
    required ConfirmForgeRepo confirmRepo,
    required this._confirmPersonRequest,
    GitHubRateBudget? rateBudget,
    GitHubRest? rest,
    DateTime Function()? now,
    @visibleForTesting this._maxCachedGrants = 2048,
  }) : rateBudget = rateBudget ?? GitHubRateBudget(),
       _rest = rest ?? GitHubRest(),
       _now = now ?? (() => DateTime.now().toUtc()) {
    lanes = GitHubLaneResolver(
      apps: apps,
      workspaceApps: workspaceApps,
      workspaceLookup: workspaceLookup,
      connect: connect,
      now: _now,
    );
    _minter = GitHubMinter(
      credentials: credentials,
      lanes: lanes,
      connect: connect,
      rest: _rest,
      confirmRepo: confirmRepo,
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
    _links = GitHubLinkChecks(
      lanes: lanes,
      minter: _minter,
      repoAccess: repoAccess,
      isSignedIn: isSignedIn,
      accountableHuman: accountableHuman,
      installationsFor: installationsFor,
      installLink: installLink,
      now: _now,
    );
    // A person's GitHub sign-in changed (another account, signed out,
    // refused on renewal, a dead seal): nothing minted from or bounded by
    // the old one is served again.
    _credentialChanges = credentials.changes
        .where((change) => change.forge == ForgeHost.github)
        .listen((change) => unawaited(forgetPerson(change.userId)));
  }

  static const Duration _reuseMargin = Duration(minutes: 15);
  static const int _revokeConcurrency = 4;
  static const Duration _refusalTtl = Duration(minutes: 1);

  /// How long a blocking [RepoAccessRegistry] record stops automation mints
  /// for its repository before the next one asks GitHub again (and records
  /// the answer). Sweeps, link verification and a person's own successful
  /// mints refresh it sooner.
  static const Duration automationRecheck = Duration(minutes: 10);

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

  /// Whether a member may read a linked repository in a workspace: an admin,
  /// or a read grant on it. The accountable human of a one-repository token
  /// must ([accountableHuman]).
  final Future<bool> Function(
    String workspaceId,
    String userId,
    String owner,
    String repo,
  )
  mayReadRepo;

  /// The one record of which linked repositories automation cannot act on.
  /// Automation mints, the link sweep and link verification write it; an
  /// automation mint (no acting person) reads it first.
  final RepoAccessRegistry repoAccess;

  /// Repositories a workspace reads skills from without linking them: its
  /// registered skill sources and the upstreams of its installed GitHub
  /// skills. They get `read` tokens through [forSkillSource] only. Set once
  /// the skill stores exist (they are built after this service); until then
  /// nothing qualifies.
  LinkedRepoLookup isSkillSource = (_, _, _) async => false;

  /// The `x-ratelimit-*` readings of every automation and person client
  /// built here, per `(workspace, person)`. Pollers back off on it.
  final GitHubRateBudget rateBudget;

  /// Which lane, and which App, each workspace runs on.
  late final GitHubLaneResolver lanes;

  late final GitHubMinter _minter;
  late final GitHubInstallations _installations;
  late final GitHubLinkChecks _links;
  final GitHubRest _rest;

  /// The pin check before a person's own request ([personHttp]).
  final ConfirmPersonForgeRequest _confirmPersonRequest;
  final DateTime Function() _now;
  final int _maxCachedGrants;

  late final StreamSubscription<ForgeCredentialChange> _credentialChanges;
  final Map<_GrantKey, GitHubScopedGrant> _grants = {};
  final Map<_GrantKey, Future<GitHubScopedGrant>> _minting = {};
  final GitHubForgetEpochs<_GrantKey> _grantEpochs = GitHubForgetEpochs();
  final Map<_GrantKey, ({GitHubScopeRefused refusal, DateTime at})> _refusals =
      {};
  final ForgeClientCache<_PersonKey, RhttpClient> _personHttp =
      ForgeClientCache.http();
  final ForgeClientCache<_OwnerKey, RhttpClient> _ownerHttp =
      ForgeClientCache.http();
  final ForgeClientCache<_OwnerKey, RhttpClient> _skillSourceHttp =
      ForgeClientCache.http();
  final ForgeClientCache<_RepoClientKey, RhttpClient> _repoHttp =
      ForgeClientCache.http();

  // --- Lanes ---------------------------------------------------------------

  /// How long whether a repository is linked is reused: every mint asks.
  /// Unlinking it ([forgetRepo]) drops the answer at once.
  static const Duration _linkedMemo = Duration(seconds: 5);
  final Map<(String, String), ({bool linked, DateTime at})> _linked = {};

  Future<bool> _isLinked(String workspaceId, String owner, String repo) async {
    final key = (workspaceId, '${owner.toLowerCase()}/${repo.toLowerCase()}');
    final hit = _linked[key];
    if (hit != null && _now().difference(hit.at) < _linkedMemo) {
      return hit.linked;
    }
    final linked = await isLinkedRepo(workspaceId, owner, repo);
    if (_linked.length >= _maxCachedGrants) {
      _linked.clear();
    }
    _linked[key] = (linked: linked, at: _now());
    return linked;
  }

  /// The lane [workspaceId]'s automation runs on right now.
  Future<GitHubLane> laneFor(String workspaceId) async =>
      (await lanes.resolve(workspaceId)).lane;

  // --- Installations -------------------------------------------------------

  /// The bot [workspaceId]'s automation converses as, and where its App is
  /// installed, or null when the workspace has no GitHub lane.
  Future<GitHubBotPresence?> botPresence(String workspaceId) =>
      _installations.botPresence(workspaceId);

  /// The link that installs [workspaceId]'s GitHub App.
  Future<Uri> installLink(String workspaceId) =>
      _installations.installLink(workspaceId);

  /// The installations [workspaceId]'s App has that [userId] may see; an
  /// own App's listing is asked of GitHub afresh only with [refresh].
  Future<List<GitHubInstallationView>> installationsFor(
    String workspaceId,
    String userId, {
    bool refresh = false,
  }) => _installations.installationsFor(
    workspaceId,
    userId,
    refresh: refresh,
  );

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
      _personHttp.get(
        (userId: userId, workspaceId: workspaceId ?? ''),
        () => ForgeHttpClientFactory(
          tokenLookup: (_) => personToken(userId, workspaceId: workspaceId),
          // A request about a linked repository first confirms it is still
          // the one linked (its durable id), as automation's mint does.
          requestTokenLookup: (forge, method, url, jsonBody) async {
            final token = await personToken(userId, workspaceId: workspaceId);
            await _confirmPersonRequest(
              workspaceId ?? '',
              forge,
              url,
              jsonBody,
              token,
            );
            return token;
          },
          onResponse: workspaceId == null || workspaceId.isEmpty
              ? null
              : (_, _, headers) =>
                    rateBudget.observe(workspaceId, headers, userId: userId),
        ).of(ForgeHost.github),
      );

  /// A GitHub client acting as [userId].
  GitHubApiClient asPerson(String userId, {String? workspaceId}) =>
      GitHubApiClient(personHttp(userId, workspaceId: workspaceId));

  // --- Accountable humans --------------------------------------------------

  /// The human whose access bounds automation in [workspaceId]: [actingUserId]
  /// when given and still a member, else the workspace owner when they are a
  /// member. Never an unrelated server owner. For work on one repository
  /// ([owner]/[repo]) they must also be able to read it there
  /// ([mayReadRepo]: an admin or a read grant), not only be a member.
  Future<String?> accountableHuman(
    String workspaceId, {
    String? actingUserId,
    String? owner,
    String? repo,
  }) async {
    if (workspaceId.isEmpty) {
      return null;
    }
    Future<String?> bounded(String userId) async {
      if (await members.getMember(workspaceId, userId) == null) {
        return null;
      }
      if (owner != null &&
          repo != null &&
          !await mayReadRepo(workspaceId, userId, owner, repo)) {
        return null;
      }
      return userId;
    }

    if (actingUserId != null && actingUserId.isNotEmpty) {
      return bounded(actingUserId);
    }
    final workspaceOwner = (await workspaceLookup(workspaceId))?.ownerUserId;
    if (workspaceOwner == null || workspaceOwner.isEmpty) {
      return null;
    }
    return bounded(workspaceOwner);
  }

  // --- Repository links ----------------------------------------------------

  /// Checks linking [owner]/[repo] to [workspaceId] by [userId] and records
  /// what automation will meet there; see [GitHubLinkChecks.verifyLink].
  Future<RepoLinkVerdict> verifyLink(
    String workspaceId,
    String userId,
    String owner,
    String repo, {
    String? repoId,
  }) => _links.verifyLink(workspaceId, userId, owner, repo, repoId: repoId);

  /// What automation meets on [owner]/[repo] in [workspaceId] right now,
  /// without minting or recording; see [GitHubLinkChecks.classifyRepo].
  Future<List<RepoAccessIssue>> classifyRepo(
    String workspaceId,
    String owner,
    String repo,
  ) => _links.classifyRepo(workspaceId, owner, repo);

  /// Re-checks and records every repository in [linked]; see
  /// [GitHubLinkChecks.sweepLinks].
  Future<int> sweepLinks(
    String workspaceId,
    List<({String owner, String repo})> linked,
  ) => _links.sweepLinks(workspaceId, linked);

  // --- Scoped tokens -------------------------------------------------------

  /// A token for exactly [owner]/[repo] with at most [scope], bounded by the
  /// accountable human. The repository must be linked to [workspaceId].
  ///
  /// [skillSource] is the one exception: a `read` token for a repository
  /// [isSkillSource] names, asked for only by [forSkillSource]. Every other
  /// caller (agent sandboxes, shell steps, rigs, the gateway) still gets
  /// nothing for a repository that is not linked.
  ///
  /// [viaPerson] downscopes [actingUserId]'s own user token (`/token/scoped`)
  /// even on an own App; with nobody acting it is refused, never anyone else's.
  ///
  /// [fresh] mints an uncached token of its own: what one agent run reads
  /// or pushes with, revoked when that run ends ([revokeGrant]).
  ///
  /// A cached grant that writes is used again only after the accountable
  /// human's role is re-read (cached at most five minutes): a person demoted
  /// on GitHub stops getting write tokens within minutes, not at the cached
  /// token's expiry.
  ///
  /// On a Control Center Connect lane the App's bot never holds contents
  /// write (it reads and comments): a `write` mint with nobody acting
  /// through their own token ([viaPerson]) is refused with
  /// [GitHubRefusal.needsRequester], and a `bot` mint (reviews) the Connect
  /// operator has not listed this install for goes out on the accountable
  /// person's own token instead ([connectBotOrPerson]).
  /// Throws [GitHubScopeRefused]; there is no fallback.
  Future<GitHubScopedGrant> mintScoped({
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    String? actingUserId,
    bool viaPerson = false,
    bool skillSource = false,
    bool fresh = false,
  }) async {
    if (!isGitHubSegment(owner) || !isGitHubSegment(repo)) {
      throw const GitHubScopeRefused(
        GitHubRefusal.invalidRequest,
        'That is not a GitHub repository name.',
      );
    }
    final linked = await _isLinked(workspaceId, owner, repo);
    if (!linked &&
        !(skillSource &&
            scope == GitHubTokenScope.read &&
            !viaPerson &&
            await isSkillSource(workspaceId, owner, repo))) {
      // Whatever was minted for it while it was linked is not served, and
      // not left alive either.
      await forgetRepo(workspaceId, owner, repo);
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        skillSource
            ? '$owner/$repo is neither linked to this workspace nor one of '
                  'its skill sources.'
            : '$owner/$repo is not linked to this workspace.',
      );
    }
    if (viaPerson && (actingUserId == null || actingUserId.isEmpty)) {
      throw const GitHubScopeRefused(
        GitHubRefusal.needsRequester,
        'Nobody is acting, so there is no person to act through.',
      );
    }
    final automation = actingUserId == null || actingUserId.isEmpty;
    if (automation && linked) {
      // The registry is the gate for work no person is doing: a repository
      // automation cannot act on stays refused until it is re-checked.
      final issue = await repoAccess.issueFor(
        workspaceId,
        forge: ForgeHost.github,
        owner: owner,
        name: repo,
      );
      if (issue != null &&
          issue.state.blocksAutomation &&
          _now().difference(issue.checkedAt) < automationRecheck) {
        throw GitHubScopeRefused(
          GitHubLinkChecks.refusalFor(issue.state),
          issue.message.isNotEmpty
              ? issue.message
              : 'Automation for $owner/$repo is paused (${issue.state.wire}).',
          installUrl: issue.installUrl == null
              ? null
              : Uri.tryParse(issue.installUrl!),
        );
      }
    }
    final human = await accountableHuman(
      workspaceId,
      actingUserId: actingUserId,
      // A skill source is not linked, so it has no grants to check.
      owner: linked ? owner : null,
      repo: linked ? repo : null,
    );
    if (human == null && actingUserId != null && actingUserId.isNotEmpty) {
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        'The person this is for has no access to $owner/$repo in this '
        'workspace.',
      );
    }
    final identity = await lanes.resolve(workspaceId);
    final key = _grantKey(
      identity,
      workspaceId,
      human ?? '',
      owner,
      repo,
      scope,
      viaPerson: viaPerson,
    );
    final now = _now();
    final cached = fresh ? null : _grants[key];
    if (cached != null && cached.expiresAt.isAfter(now.add(_reuseMargin))) {
      if (await _mayStillHold(cached, workspaceId, human, owner, repo)) {
        return cached;
      }
      if (identical(_grants[key], cached)) {
        _grants.remove(key);
      }
      unawaited(_minter.revoke(cached, reason: GitHubRevokeReason.replaced));
    }
    final refused = _refusals[key];
    if (refused != null && now.difference(refused.at) < _refusalTtl) {
      throw refused.refusal;
    }
    final inflight = fresh ? null : _minting[key];
    if (inflight != null) {
      return inflight;
    }
    // A forget that lands while this mint is in the air (a sign-out, a
    // member removed, an App or Connect changed) wins: the token it brings
    // back is revoked, never cached or handed out.
    Future<GitHubScopedGrant> landed() async {
      final epoch = _grantEpochs.open();
      GitHubRevokeReason? forgotten;
      final GitHubScopedGrant grant;
      try {
        grant = await _minter.mint(
          lane: identity.lane,
          appId: identity.appId,
          workspaceId: workspaceId,
          owner: owner,
          repo: repo,
          scope: scope,
          human: human,
          viaPerson: viaPerson,
        );
      } finally {
        forgotten = _grantEpochs.close(epoch, key);
      }
      if (forgotten != null) {
        await _minter.revoke(grant, reason: forgotten);
        throw GitHubScopeRefused(
          GitHubRefusal.providerUnavailable,
          'The GitHub identity behind $owner/$repo changed while its token '
          'was minted; try again.',
        );
      }
      if (!fresh) {
        _remember(key, grant);
      }
      return grant;
    }

    final future = landed();
    if (!fresh) {
      _minting[key] = future;
    }
    try {
      final grant = await future;
      _refusals.remove(key);
      if (linked && !viaPerson) {
        await _links.recordMinted(
          workspaceId,
          owner,
          repo,
          automation: automation,
        );
      }
      return grant;
    } on GitHubScopeRefused catch (e) {
      if (e.code == GitHubRefusal.repoReplaced) {
        // What was minted for the repository linked here is not served
        // under a path that names another one; a relink mints afresh.
        await forgetRepo(workspaceId, owner, repo);
      }
      if (_isDefinite(e.code)) {
        _refusals
          ..removeWhere((_, v) => now.difference(v.at) >= _refusalTtl)
          ..[key] = (refusal: e, at: now);
      }
      if (automation && linked) {
        await _links.recordRefusal(workspaceId, owner, repo, e);
      }
      rethrow;
    } finally {
      if (!fresh && identical(_minting[key], future)) {
        unawaited(_minting.remove(key));
      }
    }
  }

  /// Whether [cached] may be handed out again: a grant that only reads
  /// always; one that writes only while [human]'s role (re-read, cached at
  /// most five minutes) still allows its scope. An outage keeps it: the
  /// role was checked when it was minted, and GitHub being slow is no
  /// reason to stop.
  Future<bool> _mayStillHold(
    GitHubScopedGrant cached,
    String workspaceId,
    String? human,
    String owner,
    String repo,
  ) async {
    if (!cached.scope.writes) {
      return true;
    }
    if (human == null) {
      return false;
    }
    try {
      final facts = await _minter.repoFacts(workspaceId, human, owner, repo);
      return clampGitHubScope(
            requested: cached.scope,
            role: facts.role,
            repoIsPublic: facts.isPublic,
          ) ==
          cached.scope;
    } on GitHubScopeRefused catch (e) {
      return e.code.isTransient;
    }
  }

  /// Revokes [grant] upstream (best effort, recorded): a `fresh` mint whose
  /// run is over. A cached grant is never passed here.
  Future<void> revokeGrant(
    GitHubScopedGrant grant, {
    GitHubRevokeReason reason = GitHubRevokeReason.leaseClosed,
  }) => _minter.revoke(grant, reason: reason);

  /// Drops and revokes every cached grant [userId]'s own sign-in was
  /// narrowed into for [owner]/[repo] in [workspaceId]: GitHub refused one
  /// (it evicts a person's oldest tokens past its cap), so the next request
  /// mints anew.
  Future<void> _dropPersonGrants(
    String workspaceId,
    String userId,
    String owner,
    String repo,
  ) async {
    final full = '${owner.toLowerCase()}/${repo.toLowerCase()}';
    final dropped = _forgetGrants(
      (key) =>
          key.viaPerson &&
          key.workspaceId == workspaceId &&
          key.human == userId &&
          key.repo == full,
      GitHubRevokeReason.replaced,
    );
    await _revokeAll(dropped, GitHubRevokeReason.replaced);
  }

  static _GrantKey _grantKey(
    GitHubLaneIdentity identity,
    String workspaceId,
    String human,
    String owner,
    String repo,
    GitHubTokenScope scope, {
    required bool viaPerson,
  }) => (
    lane: identity.lane,
    appId: identity.appId,
    workspaceId: workspaceId,
    human: human,
    repo: '${owner.toLowerCase()}/${repo.toLowerCase()}',
    scope: scope,
    viaPerson: viaPerson,
  );

  /// Refusals nothing but a configuration or permission change undoes, so
  /// repeating the mint within [_refusalTtl] would only repeat the answer.
  static bool _isDefinite(GitHubRefusal code) => switch (code) {
    GitHubRefusal.notInstalled ||
    GitHubRefusal.repoNotSelected ||
    GitHubRefusal.suspended ||
    GitHubRefusal.accessDenied ||
    GitHubRefusal.ssoRequired ||
    GitHubRefusal.notConfigured => true,
    _ => false,
  };

  void _remember(_GrantKey key, GitHubScopedGrant grant) {
    final now = _now();
    _grants
      ..removeWhere((_, g) => !g.expiresAt.isAfter(now))
      ..remove(key);
    final evicted = <GitHubScopedGrant>[];
    while (_grants.length >= _maxCachedGrants) {
      final oldest = _grants.keys.first;
      evicted.add(_grants.remove(oldest)!);
    }
    _grants[key] = grant;
    if (evicted.isNotEmpty) {
      unawaited(_revokeAll(evicted, GitHubRevokeReason.evicted));
    }
  }

  // --- Forgetting ----------------------------------------------------------

  /// Drops every cached grant for [userId] (sign-out, another account, a
  /// sign-in that can never work again) and revokes them upstream, including
  /// any minted for them that is still in the air.
  Future<void> forgetPerson(String userId) async {
    bool match(_GrantKey key) => key.human == userId;
    final mine = _forgetGrants(match, GitHubRevokeReason.forgetPerson);
    _minter.forgetReposWhere((key) => key.human == userId);
    _personHttp.retireWhere((key) => key.userId == userId);
    // The person may have been the accountable human whose installations a
    // Connect workspace's bot presence was read through.
    _installations.forgetPresence();
    _invalidated('forget_person', mine.length, userId: userId);
    await _revokeAll(mine, GitHubRevokeReason.forgetPerson);
  }

  /// Drops [userId]'s cached grants in [workspaceId] (removed from it, or
  /// their role changed) and revokes them upstream.
  Future<void> forgetMember(String workspaceId, String userId) async {
    bool match(_GrantKey key) =>
        key.workspaceId == workspaceId && key.human == userId;
    final mine = _forgetGrants(match, GitHubRevokeReason.forgetMember);
    _minter.forgetReposWhere(
      (key) => key.workspaceId == workspaceId && key.human == userId,
    );
    _installations.forgetPresence(workspaceId);
    _invalidated(
      'forget_member',
      mine.length,
      workspaceId: workspaceId,
      userId: userId,
    );
    await _revokeAll(mine, GitHubRevokeReason.forgetMember);
  }

  /// Drops and revokes every cached grant for [owner]/[repo] in
  /// [workspaceId]: it is no longer linked there.
  Future<void> forgetRepo(String workspaceId, String owner, String repo) async {
    final full = '${owner.toLowerCase()}/${repo.toLowerCase()}';
    _linked.remove((workspaceId, full));
    bool match(_GrantKey key) =>
        key.workspaceId == workspaceId && key.repo == full;
    final theirs = _forgetGrants(match, GitHubRevokeReason.unlinked);
    if (theirs.isEmpty) {
      return;
    }
    _invalidated('unlinked', theirs.length, workspaceId: workspaceId);
    await _revokeAll(theirs, GitHubRevokeReason.unlinked);
  }

  /// Drops every cached grant, repository fact and bot presence and revokes
  /// the grants upstream: the server's own App or its Connect changed, so
  /// whatever was minted belongs to an identity this server no longer uses.
  Future<void> forgetAll() async {
    final all = _forgetGrants((_) => true, GitHubRevokeReason.appChanged);
    lanes.invalidate();
    _linked.clear();
    _minter.forgetReposWhere((_) => true);
    _installations.forgetPresence();
    _invalidated('app_changed', all.length);
    await _revokeAll(all, GitHubRevokeReason.appChanged);
  }

  /// Drops and revokes every cached grant for [workspaceId], its presence
  /// and clients (its own App saved or rotated, its mode changed, the
  /// workspace deleted). Its recorded GitHub access issues belonged to the
  /// previous identity, so they are dropped too and the next automation
  /// mint or sweep records afresh.
  Future<void> forgetWorkspace(String workspaceId) async {
    final theirs = _forgetGrants(
      (key) => key.workspaceId == workspaceId,
      GitHubRevokeReason.appChanged,
    );
    _minter.forgetReposWhere((key) => key.workspaceId == workspaceId);
    lanes.invalidate(workspaceId);
    _linked.removeWhere((key, _) => key.$1 == workspaceId);
    _installations.forgetPresence(workspaceId);
    _ownerHttp.retireWhere((key) => key.workspaceId == workspaceId);
    _repoHttp.retireWhere((key) => key.workspaceId == workspaceId);
    _skillSourceHttp.retireWhere((key) => key.workspaceId == workspaceId);
    try {
      await repoAccess.forgetWhere(
        workspaceId,
        (issue) => issue.forge == ForgeHost.github,
      );
    } on Object catch (e) {
      // A deleted workspace's database may be gone already.
      CcHostLog.warning('github: dropping access records failed ($e)');
    }
    rateBudget.forgetWorkspace(workspaceId);
    _invalidated('app_changed', theirs.length, workspaceId: workspaceId);
    await _revokeAll(theirs, GitHubRevokeReason.appChanged);
  }

  /// Takes every cached grant [match] accepts, forgets their refusals, and
  /// makes any mint for them still in the air land revoked ([reason]).
  List<GitHubScopedGrant> _forgetGrants(
    bool Function(_GrantKey key) match,
    GitHubRevokeReason reason,
  ) {
    _grantEpochs.drop(match, reason: reason);
    _minting.removeWhere((key, _) => match(key));
    _refusals.removeWhere((key, _) => match(key));
    final taken = <GitHubScopedGrant>[];
    _grants.removeWhere((key, grant) {
      if (match(key)) {
        taken.add(grant);
        return true;
      }
      return false;
    });
    return taken;
  }

  void _invalidated(
    String trigger,
    int count, {
    String? workspaceId,
    String? userId,
  }) => forgeAudit(ForgeAuditEvent.githubGrantCacheInvalidated, {
    'trigger': trigger,
    'grants': count,
    'workspace_id': workspaceId,
    'user_id': userId,
  });

  /// Revokes [grants] upstream, a few at a time.
  Future<void> _revokeAll(
    List<GitHubScopedGrant> grants,
    GitHubRevokeReason reason,
  ) async {
    for (var i = 0; i < grants.length; i += _revokeConcurrency) {
      await Future.wait([
        for (final grant in grants.skip(i).take(_revokeConcurrency))
          _minter.revoke(grant, reason: reason),
      ]);
    }
  }

  /// Whether [close] ran.
  bool get isClosed => _closed;
  var _closed = false;

  /// Releases the HTTP transport and stops following sign-in changes. The
  /// service must not be used afterwards.
  void close() {
    _closed = true;
    unawaited(_credentialChanges.cancel());
    _rest.close();
    _personHttp.close();
    _ownerHttp.close();
    _skillSourceHttp.close();
    _repoHttp.close();
  }

  // --- Background clients --------------------------------------------------

  /// An HTTP client for automation against repositories under [owner] in
  /// [workspaceId].
  ///
  /// Each request picks its own credential: `/repos/{owner}/{repo}/…` gets a
  /// token for that one repository ([githubScopeForRequest]), clamped to the
  /// accountable human ([actingUserId] when given): the App's bot on every
  /// lane. A write no one-repository scope covers is refused. A request that
  /// is not about one repository (GraphQL, search, users, orgs) is refused
  /// whoever is acting: this client never carries a person's own token, so
  /// a person's own work goes through [asPerson], and repository GraphQL
  /// through [forRepo]. A request with no credential is never sent
  /// anonymously: it fails locally with the status GitHub would have
  /// answered ([tokenForRequest]), so the caller degrades the same way and
  /// the shared per-IP anonymous budget is never touched.
  ///
  /// Automation never approves a pull request: an `APPROVE` review event is
  /// refused before it is sent ([refuseAutomatedGitHubApproval]). Approving is a
  /// person's act and rides [asPerson].
  RhttpClient httpForOwner(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) => _ownerHttp.get(
    (
      workspaceId: workspaceId,
      owner: owner.toLowerCase(),
      actingUserId: actingUserId ?? '',
    ),
    () => ForgeHttpClientFactory(
      tokenLookup: (_) async => null,
      requestTokenLookup: (_, method, url, _) => tokenForRequest(
        workspaceId,
        owner,
        method: method,
        url: url,
        actingUserId: actingUserId,
      ),
      requestGuard: (_, method, url, body) => _audited(
        workspaceId,
        method,
        url,
        refuseAutomatedGitHubApproval(method, url, body) ??
            refuseUnscopedGitHubWrite(method, url, body),
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
  }) => GitHubApiClient(
    httpForOwner(workspaceId, owner, actingUserId: actingUserId),
  );

  /// The HTTP client behind [forRepo]: automation for exactly [owner]/[repo].
  ///
  /// [viaPerson] (with [actingUserId]) carries that person's own sign-in
  /// narrowed to this one repository instead of the bot: the lane for a pull
  /// request an agent opens for them, so GitHub's own author rules see the
  /// person. Approving stays refused here either way. GitHub evicts a
  /// person's oldest tokens past its per-person cap, so a narrowed token it
  /// answers 401 for is dropped, revoked and minted again, once.
  RhttpClient httpForRepo(
    String workspaceId,
    String owner,
    String repo, {
    String? actingUserId,
    bool viaPerson = false,
  }) => _repoHttp.get(
    (
      workspaceId: workspaceId,
      owner: owner.toLowerCase(),
      repo: repo.toLowerCase(),
      actingUserId: actingUserId ?? '',
      viaPerson: viaPerson,
    ),
    () => ForgeHttpClientFactory(
      tokenLookup: (_) async => null,
      requestTokenLookup: (_, method, url, body) => tokenForRepoRequest(
        workspaceId,
        owner,
        repo,
        method: method,
        url: url,
        body: body,
        actingUserId: actingUserId,
        viaPerson: viaPerson,
      ),
      requestGuard: (_, method, url, body) => _audited(
        workspaceId,
        method,
        url,
        refuseGitHubRepoClientRequest(owner, repo, method, url, body),
      ),
      onResponse: (_, _, headers) =>
          rateBudget.observe(workspaceId, headers, userId: actingUserId),
      buildClient: viaPerson && actingUserId != null && actingUserId.isNotEmpty
          ? (baseUrl, settings, interceptors) => createHttpClient(
              baseUrl: baseUrl,
              settings: settings,
              interceptors: [
                ...interceptors,
                remintOnUnauthorized(
                  () =>
                      _dropPersonGrants(workspaceId, actingUserId, owner, repo),
                ),
              ],
            )
          : null,
    ).of(ForgeHost.github),
  );

  /// An automation client for exactly [owner]/[repo]: every request, GraphQL
  /// included, rides a one-repository installation-lane token for that repo
  /// (never a person's own token). REST scopes follow [githubScopeForRequest];
  /// GraphQL queries use `read`, allowlisted mutations their listed scope
  /// ([githubGraphQlScope]; any other is refused). Requests about any
  /// other repository are refused locally, and so is anything that is not
  /// about this one (`/user`, `/orgs`, a search that names another
  /// repository). [actingUserId] bounds the token by that member instead of
  /// the workspace's accountable person.
  GitHubApiClient forRepo(
    String workspaceId,
    String owner,
    String repo, {
    String? actingUserId,
  }) => GitHubApiClient(
    httpForRepo(workspaceId, owner, repo, actingUserId: actingUserId),
  );

  /// A read-only GitHub client for skill catalogs under [owner] in
  /// [workspaceId]: each `/repos/{owner}/{repo}/…` GET carries a `read` token
  /// for that one repository when it is linked or one of [isSkillSource]'s,
  /// clamped to the accountable human ([actingUserId] when a person asked).
  /// Anything else — a write, GraphQL, a request that is not about one
  /// repository — fails locally and is never sent.
  GitHubApiClient forSkillSource(
    String workspaceId,
    String owner, {
    String? actingUserId,
  }) => GitHubApiClient(
    _skillSourceHttp.get(
      (
        workspaceId: workspaceId,
        owner: owner.toLowerCase(),
        actingUserId: actingUserId ?? '',
      ),
      () => ForgeHttpClientFactory(
        tokenLookup: (_) async => null,
        requestTokenLookup: (_, method, url, _) => tokenForRequest(
          workspaceId,
          owner,
          method: method,
          url: url,
          actingUserId: actingUserId,
          skillSource: true,
        ),
        requestGuard: (_, method, url, body) => _audited(
          workspaceId,
          method,
          url,
          method.toUpperCase() == 'GET'
              ? null
              : 'Skill sources are read-only: $method is never sent.',
        ),
        onResponse: (_, _, headers) =>
            rateBudget.observe(workspaceId, headers, userId: actingUserId),
      ).of(ForgeHost.github),
    ),
  );

  /// [reason], recorded as `forge.request.refused` when the guard refused.
  static String? _audited(
    String workspaceId,
    String method,
    String url,
    String? reason,
  ) {
    if (reason != null) {
      forgeAudit(ForgeAuditEvent.forgeRequestRefused, {
        'forge': ForgeHost.github.wire,
        'workspace_id': workspaceId,
        'rule': 'github_request_policy',
        'method': method.toUpperCase(),
        'path': forgeRequestPathTemplate(url),
        'message': reason,
      });
    }
    return reason;
  }

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
    bool skillSource = false,
  }) async {
    final target = githubScopeForRequest(method, url);
    if (target == null && skillSource) {
      throw const ForgeCredentialUnavailable(
        404,
        'A skill source client only reads one repository.',
      );
    }
    if (target == null) {
      // Not about one repository: an automation client never carries a
      // person's own token, whoever is acting. A person's own work goes
      // through asPerson; repository GraphQL through forRepo.
      throw const ForgeCredentialUnavailable(
        403,
        'Automation reaches GitHub only through one-repository tokens; '
        'this request is not about one repository.',
      );
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
    return _mintForRequest(
      workspaceId,
      target.owner,
      target.repo,
      scope,
      actingUserId: actingUserId,
      skillSource: skillSource,
    );
  }

  /// The credential for one request on a [forRepo] client: REST about
  /// [owner]/[repo] at its [githubScopeForRequest] scope; GraphQL at its allowlisted
  /// [githubGraphQlScope]; a search confined to this repository at `read`.
  /// Anything else was refused by [refuseGitHubRequestOutsideRepo] before it got here.
  /// [viaPerson] mints [actingUserId]'s own one-repository token instead.
  @visibleForTesting
  Future<String> tokenForRepoRequest(
    String workspaceId,
    String owner,
    String repo, {
    required String method,
    required String url,
    Object? body,
    String? actingUserId,
    bool viaPerson = false,
  }) async {
    if (viaPerson && (actingUserId == null || actingUserId.isEmpty)) {
      throw const ForgeCredentialUnavailable(
        401,
        'Nobody is acting, so there is no person to act through.',
      );
    }
    final target = githubScopeForRequest(method, url);
    final GitHubTokenScope? scope;
    if (target != null) {
      scope =
          target.owner.toLowerCase() == owner.toLowerCase() &&
              target.repo.toLowerCase() == repo.toLowerCase()
          ? target.scope
          : null;
    } else if (isGitHubGraphQlRequest(method, url)) {
      scope = requireGitHubGraphQlScope(body);
    } else if (isGitHubRepoSearch(owner, repo, method, url)) {
      scope = GitHubTokenScope.read;
    } else {
      scope = null;
    }
    if (scope == null) {
      throw ForgeCredentialUnavailable(
        404,
        'This client only reaches $owner/$repo.',
      );
    }
    return _mintForRequest(
      workspaceId,
      owner,
      repo,
      scope,
      actingUserId: actingUserId,
      viaPerson: viaPerson,
    );
  }

  Future<String> _mintForRequest(
    String workspaceId,
    String owner,
    String repo,
    GitHubTokenScope scope, {
    String? actingUserId,
    bool viaPerson = false,
    bool skillSource = false,
  }) async {
    try {
      return (await mintScoped(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        scope: scope,
        actingUserId: actingUserId,
        viaPerson: viaPerson,
        skillSource: skillSource,
      )).token;
    } on GitHubScopeRefused catch (e) {
      CcHostLog.warning(
        'github: no token for $owner/$repo (${scope.wire}) in workspace '
        '$workspaceId: ${e.code.wire} — ${e.message}',
      );
      throw switch (e.code) {
        // `isGitHubInstallationSuspendedResponse` keys on this phrasing.
        GitHubRefusal.suspended => const ForgeCredentialUnavailable(
          403,
          'This installation has been suspended.',
        ),
        GitHubRefusal.providerUnavailable ||
        GitHubRefusal.rateLimited => ForgeCredentialUnavailable(503, e.message),
        // A person's own one-repository token: it is their sign-in that is
        // missing, so the refusal names it.
        GitHubRefusal.needsSignIn when viaPerson =>
          ForgeCredentialUnavailable.needsSignIn(
            ForgeHost.github.wire,
            e.message,
          ),
        GitHubRefusal.ssoRequired when viaPerson =>
          ForgeCredentialUnavailable.needsSignIn(
            ForgeHost.github.wire,
            e.message,
          ),
        GitHubRefusal.needsSignIn ||
        GitHubRefusal.ssoRequired ||
        GitHubRefusal.notConfigured => ForgeCredentialUnavailable(
          401,
          e.message,
        ),
        // Not a missing resource: the work needs a person who asked for it.
        GitHubRefusal.needsRequester => ForgeCredentialUnavailable(
          403,
          e.message,
        ),
        // Another repository at the linked path: a conflict an admin
        // resolves by relinking, as on GitLab and Bitbucket.
        GitHubRefusal.repoReplaced => ForgeCredentialUnavailable.repoReplaced(
          ForgeHost.github,
          e.message,
        ),
        _ => ForgeCredentialUnavailable(404, e.message),
      };
    }
  }
}

/// Retries a request GitHub answered 401 for, once, after [drop] forgot the
/// credential it carried: the retry runs the client's interceptors again, so
/// it carries a freshly minted one. A local refusal (no credential was sent)
/// is never retried.
@visibleForTesting
RetryInterceptor remintOnUnauthorized(
  Future<void> Function() drop,
) => RetryInterceptor(
  delay: (_) => Duration.zero,
  shouldRetry: (response, exception) {
    final request = response?.request ?? exception?.request;
    final status =
        response?.statusCode ??
        (exception is RhttpStatusCodeException ? exception.statusCode : null);
    return status == 401 &&
        request != null &&
        _hasAuthorization(request.headers);
  },
  beforeRetry: (_, request, _, _) async {
    await drop();
    return request.copyWith(headers: _withoutAuthorization(request.headers));
  },
);

bool _hasAuthorization(HttpHeaders? headers) => switch (headers) {
  null => false,
  HttpHeaderMap(:final map) => map.keys.any(
    (k) => k.httpName.toLowerCase() == 'authorization',
  ),
  HttpHeaderRawMap(:final map) => map.keys.any(
    (k) => k.toLowerCase() == 'authorization',
  ),
  HttpHeaderList(:final list) => list.any(
    (h) => h.$1.toLowerCase() == 'authorization',
  ),
};

HttpHeaders? _withoutAuthorization(HttpHeaders? headers) => switch (headers) {
  null => null,
  HttpHeaderMap(:final map) => HttpHeaders.map({
    for (final e in map.entries)
      if (e.key.httpName.toLowerCase() != 'authorization') e.key: e.value,
  }),
  HttpHeaderRawMap(:final map) => HttpHeaders.rawMap({
    for (final e in map.entries)
      if (e.key.toLowerCase() != 'authorization') e.key: e.value,
  }),
  HttpHeaderList(:final list) => HttpHeaders.list([
    for (final h in list)
      if (h.$1.toLowerCase() != 'authorization') h,
  ]),
};
