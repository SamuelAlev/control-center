import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        GitHubAppMintFailure,
        GitHubAppMintRefused,
        MintedToken,
        gitHubInstallationSettingsUrl;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_error_messages.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart'
    show ConfirmForgeRepo, forgeRepoReplacedCode;
import 'package:cc_server_core/src/forge/github_client_types.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';

/// A person's stored Connect seal for GitHub and the slot it lives in.
final class GitHubSeals {
  /// Creates the accessor.
  const GitHubSeals(this.credentials);

  /// Person grants.
  final ForgeCredentials credentials;

  /// [userId]'s seal as seen from [workspaceId], with its scope
  /// ([globalWorkspaceScope] for the global row). Throws
  /// [GitHubScopeRefused] when there is none, or when it was sealed by
  /// another Connect than [target]: a seal goes only to the Connect that
  /// made it.
  Future<({String seal, String scope})> sealFor(
    String userId,
    String workspaceId,
    ConnectTarget target,
  ) async {
    final stored = await credentials.storedCredential(
      ForgeHost.github,
      userId,
      workspaceId: workspaceId,
    );
    if (stored == null ||
        !stored.token.isSealed ||
        stored.token.connectOrigin != target.origin) {
      throw const GitHubScopeRefused(
        GitHubRefusal.needsSignIn,
        'Sign in to GitHub first.',
      );
    }
    return (
      seal: stored.token.seal,
      scope: stored.workspaceId ?? globalWorkspaceScope,
    );
  }

  /// Persists a seal Connect rotated on the way. [scope] is the stored
  /// credential's own scope ([globalWorkspaceScope] for the global row).
  Future<void> adopt(String userId, String scope, String updated) async {
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
}

/// Which forgets happened while an await was in the air, so whatever that
/// await brings back for a forgotten key is dropped instead of cached.
///
/// [open] before the await, [close] after it (always, once): [close] answers
/// the reason of a [drop] since [open] that matched the key, or null. Drops
/// are only remembered while something is open.
final class GitHubForgetEpochs<K> {
  int _epoch = 0;
  int _open = 0;
  final List<
    ({int epoch, bool Function(K key) match, GitHubRevokeReason reason})
  >
  _drops = [];

  /// Starts watching; pass the answer to [close].
  int open() {
    _open++;
    return _epoch;
  }

  /// Stops watching: why [key] was dropped since [since], or null.
  GitHubRevokeReason? close(int since, K key) {
    _open--;
    GitHubRevokeReason? reason;
    for (final drop in _drops) {
      if (drop.epoch > since && drop.match(key)) {
        reason = drop.reason;
        break;
      }
    }
    if (_open == 0) {
      _drops.clear();
    }
    return reason;
  }

  /// Records a forget of every key [match] accepts.
  void drop(
    bool Function(K key) match, {
    GitHubRevokeReason reason = GitHubRevokeReason.appChanged,
  }) {
    _epoch++;
    if (_open > 0) {
      _drops.add((epoch: _epoch, match: match, reason: reason));
    }
  }
}

/// Why a GitHub token is revoked, as the audit trail names it.
enum GitHubRevokeReason {
  /// The agent run or lease that held it ended.
  leaseClosed('lease_closed'),

  /// The person's sign-in changed or went away.
  forgetPerson('forget_person'),

  /// The member left the workspace or their role changed.
  forgetMember('forget_member'),

  /// The App, Connect or lane behind it changed.
  appChanged('app_changed'),

  /// GitHub answered a token wider than asked.
  scopeMismatch('scope_mismatch'),

  /// Dropped from a full cache.
  evicted('evicted'),

  /// Its repository is no longer linked.
  unlinked('unlinked'),

  /// GitHub stopped accepting it (a 401) or the person's role no longer
  /// allows its scope; a fresh one replaces it.
  replaced('replaced');

  const GitHubRevokeReason(this.wire);

  /// The audit spelling.
  final String wire;
}

/// Repository id, current path, owner id, visibility and the accountable
/// human's role, as that human's own token sees them.
final class GitHubRepoFacts {
  /// Creates the facts.
  const GitHubRepoFacts({
    required this.id,
    required this.owner,
    required this.name,
    required this.ownerId,
    required this.isPublic,
    required this.role,
  });

  /// Numeric repository id.
  final int id;

  /// The owner's login now (a renamed or transferred repository answers
  /// under its new path).
  final String owner;

  /// The repository's name now.
  final String name;

  /// Numeric owner id.
  final int ownerId;

  /// Public (neither private nor internal).
  final bool isPublic;

  /// The human's role on it.
  final GitHubRepoRole role;
}

/// The key of one cached [GitHubRepoFacts]: per workspace and human, because
/// the role is theirs.
typedef GitHubRepoKey = ({String workspaceId, String human, String repo});

/// Builds a [GitHubRepoKey]; [owner]/[repo] compare case-insensitively.
GitHubRepoKey gitHubRepoKey(
  String workspaceId,
  String human,
  String owner,
  String repo,
) => (
  workspaceId: workspaceId,
  human: human,
  repo: '${owner.toLowerCase()}/${repo.toLowerCase()}',
);

/// Mints one-repository tokens on each lane, clamped to the accountable
/// human, and reads the repository facts that bound them.
final class GitHubMinter {
  /// Creates the minter.
  GitHubMinter({
    required this.credentials,
    required this.lanes,
    required this.connect,
    required this.rest,
    required this.confirmRepo,
    required this._now,
  });

  static const Duration _repoCacheTtl = Duration(minutes: 5);
  static const int _maxCachedRepos = 4096;

  /// Person grants.
  final ForgeCredentials credentials;

  /// Lane and App resolution.
  final GitHubLaneResolver lanes;

  /// Connect.
  final ConnectClient connect;

  /// The REST transport.
  final GitHubRest rest;

  /// Compares a linked repository's pinned durable id with what GitHub
  /// answers for its path (`ForgeRepoPins.confirm`).
  final ConfirmForgeRepo confirmRepo;

  final DateTime Function() _now;

  final Map<GitHubRepoKey, ({GitHubRepoFacts facts, DateTime at})> _repos = {};
  final GitHubForgetEpochs<GitHubRepoKey> _repoEpochs = GitHubForgetEpochs();

  /// Mints on [lane] and records the outcome in the audit trail
  /// (`github.token.minted` / `clamped` / `refused`). Throws
  /// [GitHubScopeRefused].
  Future<GitHubScopedGrant> mint({
    required GitHubLane lane,
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
    required bool viaPerson,
    String appId = '',
  }) async {
    final fields = <String, Object?>{
      'workspace_id': workspaceId,
      'human_user_id': human,
      'lane': lane.wire,
      'app_id': appId,
      'repo': '$owner/$repo',
      'scope_requested': scope.wire,
      'via_person': viaPerson,
    };
    try {
      final grant = await _mint(
        lane: lane,
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        scope: scope,
        human: human,
        viaPerson: viaPerson,
      );
      if (grant.scope != scope) {
        forgeAudit(ForgeAuditEvent.githubTokenClamped, {
          ...fields,
          'scope_granted': grant.scope.wire,
        });
      }
      forgeAudit(ForgeAuditEvent.githubTokenMinted, {
        ...fields,
        'scope_granted': grant.scope.wire,
        'expires_at': grant.expiresAt,
        'github_request_id': grant.requestId,
      }, token: grant.token);
      return grant;
    } on GitHubScopeRefused catch (e) {
      forgeAudit(ForgeAuditEvent.githubTokenRefused, {
        ...fields,
        'reason': e.code.wire,
        'message': e.message,
      });
      rethrow;
    }
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
          GitHubRefusal.notConfigured,
          'GitHub is not set up on this server. Turn on Control Center '
          'Connect or add your own GitHub App in Settings.',
        );
      case GitHubLane.connect:
        Future<GitHubScopedGrant> mintAs(GitHubMintActor actor) =>
            _mintViaConnect(
              workspaceId: workspaceId,
              owner: owner,
              repo: repo,
              scope: scope,
              human: human,
              actor: actor,
            );
        if (viaPerson) {
          return mintAs(GitHubMintActor.user);
        }
        return connectBotOrPerson(scope: scope, human: human, mint: mintAs);
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
        GitHubRefusal.needsSignIn,
        'Nobody accountable for this workspace is signed in to GitHub.',
      );
    }
    final facts = await repoFacts(workspaceId, human, owner, repo);
    final clamped = clampGitHubScope(
      requested: scope,
      role: facts.role,
      repoIsPublic: facts.isPublic,
    );
    if (clamped == null) {
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
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
    final app = await lanes.appFor(workspaceId, lane);
    if (app == null) {
      throw const GitHubScopeRefused(
        GitHubRefusal.notConfigured,
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
    final facts = await repoFacts(workspaceId, human!, owner, repo);
    final MintedToken minted;
    try {
      // One installation listing (cached a minute) answers "installed?",
      // "suspended?" and which installation to mint through.
      // By the path GitHub answers now: a moved repository's old one names
      // no installation repository.
      minted = await app.mintScopedForOwner(
        facts.owner,
        repositories: [facts.name],
        permissions: granted.permissions,
      );
    } on GitHubAppMintRefused catch (e) {
      final installation = e.installation;
      throw switch (e.failure) {
        GitHubAppMintFailure.notInstalled => GitHubScopeRefused(
          GitHubRefusal.notInstalled,
          'The GitHub App is not installed on $owner. Install it from '
          'Settings.',
        ),
        GitHubAppMintFailure.repoNotSelected => GitHubScopeRefused(
          GitHubRefusal.repoNotSelected,
          'The GitHub App is installed on $owner, but $owner/$repo is not '
          'among the repositories it may reach.',
          installUrl: installation == null
              ? null
              : gitHubInstallationSettingsUrl(installation),
        ),
        GitHubAppMintFailure.suspended => GitHubScopeRefused(
          GitHubRefusal.suspended,
          'The GitHub App installation on $owner is suspended.',
        ),
        // A permission the App lacks, or an answer wider than asked: the
        // App's configuration, nothing a retry changes.
        GitHubAppMintFailure.denied => GitHubScopeRefused(
          GitHubRefusal.notConfigured,
          'GitHub refused a token for $owner/$repo: ${e.message}',
        ),
        // The App's own JWT (already in the audit trail as
        // `github.app_jwt.rejected`): a key, App id or clock to fix.
        GitHubAppMintFailure.jwtRejected => GitHubScopeRefused(
          GitHubRefusal.notConfigured,
          e.message,
        ),
        GitHubAppMintFailure.unavailable => const GitHubScopeRefused(
          GitHubRefusal.providerUnavailable,
          'GitHub is unreachable right now.',
        ),
      };
    }
    // Proven again by repository id, not name: exactly this repository with
    // exactly the granted permissions.
    if (!scopedTokenMatches(
      minted.coverage,
      repoId: facts.id,
      permissions: granted.permissions,
    )) {
      await _revokeInstallationToken(
        minted.token,
        GitHubRevokeReason.scopeMismatch,
        workspaceId: workspaceId,
        lane: lane,
      );
      throw GitHubScopeRefused(
        GitHubRefusal.notConfigured,
        'GitHub answered a token for $owner/$repo that is not limited to '
        'it at the granted permissions; it was revoked.',
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
      requestId: minted.requestId,
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
    const signIn = GitHubScopeRefused(
      GitHubRefusal.needsSignIn,
      'Sign in to GitHub to use it from this terminal.',
    );
    if (human == null) {
      throw signIn;
    }
    final parent = await credentials.personCredential(
      ForgeHost.github,
      human,
      workspaceId: workspaceId,
    );
    if (parent == null || parent.accessToken.isEmpty) {
      throw signIn;
    }
    final granted = await _clampForHuman(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      scope: scope,
      human: human,
    );
    final facts = await repoFacts(workspaceId, human, owner, repo);
    final creds = await lanes.oauthFor(workspaceId, lane);
    if (creds == null) {
      throw const GitHubScopeRefused(
        GitHubRefusal.notConfigured,
        'The GitHub App has no client secret configured.',
      );
    }
    final response = await rest.send(
      'POST',
      '/applications/${Uri.encodeComponent(creds.clientId)}/token/scoped',
      basic: creds,
      body: {
        'access_token': parent.accessToken,
        'target_id': facts.ownerId,
        'repository_ids': [facts.id],
        'permissions': granted.permissions,
      },
    );
    if (response.status != 200) {
      throw GitHubScopeRefused(
        response.unavailable
            ? GitHubRefusal.providerUnavailable
            : GitHubRefusal.accessDenied,
        'GitHub refused to narrow the sign-in to $owner/$repo.',
      );
    }
    final json = response.json;
    final token = json is Map ? json['token'] : null;
    if (json is! Map || token is! String || token.isEmpty) {
      throw const GitHubScopeRefused(
        GitHubRefusal.providerUnavailable,
        'GitHub returned no narrowed token.',
      );
    }
    // GitHub's `/token/scoped` answer names the selection and permissions
    // but no repository list; the request named exactly this repository.
    // Anything else GitHub created is revoked before it is refused, with
    // the App that created it.
    if (!token.startsWith('ghu_') ||
        !scopedTokenMatches(
          json,
          repoId: facts.id,
          permissions: granted.permissions,
          requireRepositories: false,
        )) {
      await _revokeUserToken(
        token,
        creds,
        GitHubRevokeReason.scopeMismatch,
        workspaceId: workspaceId,
        lane: lane,
      );
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        'GitHub did not narrow the sign-in to $owner/$repo alone; the token '
        'it answered was revoked.',
      );
    }
    return GitHubScopedGrant(
      token: token,
      scope: granted,
      // A narrowed token never outlives the user token it came from.
      expiresAt: parent.expiresAt ?? _now().add(const Duration(hours: 1)),
      lane: lane,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      accountableUserId: human,
      // Revoked with the App that narrowed it, whatever the settings say
      // by then: a rotated or removed App leaves no live child behind.
      appClient: creds,
      requestId: response.headers['x-github-request-id'] ?? '',
    );
  }

  /// Connect's `/v1/github/scope`, authorized by [human]'s sealed grant:
  /// [GitHubMintActor.app] is the App's bot (an installation token for this
  /// one repository), [GitHubMintActor.user] a child of [human]'s own user
  /// token. The scope asked for is clamped here first, to what [human] may
  /// hold, exactly as an own App would; Connect clamps again. Either answer
  /// must cover exactly this repository; one that does not is revoked here
  /// and refused.
  Future<GitHubScopedGrant> _mintViaConnect({
    required String workspaceId,
    required String owner,
    required String repo,
    required GitHubTokenScope scope,
    required String? human,
    required GitHubMintActor actor,
  }) async {
    if (human == null) {
      throw const GitHubScopeRefused(
        GitHubRefusal.needsSignIn,
        'Nobody accountable for this workspace is signed in to GitHub.',
      );
    }
    final target = await connect.targetFor(workspaceId);
    final sealed = await GitHubSeals(
      credentials,
    ).sealFor(human, workspaceId, target);
    final asked = await _clampForHuman(
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      scope: scope,
      human: human,
    );
    final facts = await repoFacts(workspaceId, human, owner, repo);
    final GitHubScopedToken minted;
    try {
      minted = await connect.githubScope(
        target,
        GitHubScopeRequest(
          seal: sealed.seal,
          workspaceId: sealed.scope,
          repoId: facts.id,
          repoOwner: facts.owner,
          repoName: facts.name,
          scope: asked.wire,
          actor: actor,
        ),
      );
    } on ConnectException catch (e) {
      if (e.code.clearsGrant) {
        await credentials.clearToken(
          ForgeHost.github,
          userId: human,
          workspaceId: sealed.scope == globalWorkspaceScope
              ? null
              : sealed.scope,
        );
      }
      throw GitHubScopeRefused(
        GitHubRefusal.fromConnect(e.code),
        connectErrorMessage(e.code, ConnectErrorContext.githubMint(owner)),
      );
    }
    final seal = minted.updatedSeal.isNotEmpty
        ? minted.updatedSeal
        : sealed.seal;
    // A write that fails keeps the rotated seal in memory (Connect spent the
    // old one), written again on the next use.
    await GitHubSeals(
      credentials,
    ).adopt(human, sealed.scope, minted.updatedSeal);
    final granted = GitHubTokenScope.fromWire(minted.grantedScope);
    final kind = actor == GitHubMintActor.app ? 'ghs_' : 'ghu_';
    final covered =
        minted.accessToken.startsWith(kind) &&
        granted != null &&
        // Within what was asked, permission by permission: the enum's order
        // says nothing about which scope is a subset of which.
        gitHubPermissionsWithin(granted.permissions, asked.permissions) &&
        // The bot holds `bot` only where the Connect operator listed this
        // install, which Connect decides; it never holds `write`.
        (actor == GitHubMintActor.user ||
            granted.connectBotMayHold ||
            granted.connectBotNeedsListing) &&
        // Either kind proves its coverage: exactly this repository, with
        // exactly the granted permissions.
        minted.repositorySelection == 'selected' &&
        minted.repositoryIds.length == 1 &&
        scopedTokenMatches(
          minted.coverage,
          repoId: facts.id,
          permissions: granted.permissions,
        );
    if (!covered) {
      if (actor == GitHubMintActor.app) {
        await _revokeInstallationToken(
          minted.accessToken,
          GitHubRevokeReason.scopeMismatch,
          workspaceId: workspaceId,
          lane: GitHubLane.connect,
        );
      } else {
        await _revokeConnectChild(
          target,
          sealed.scope,
          seal,
          minted.accessToken,
          GitHubRevokeReason.scopeMismatch,
          workspaceId: workspaceId,
        );
      }
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        'Control Center Connect answered a token that is not limited to '
        '$owner/$repo at the asked scope; it was revoked.',
      );
    }
    return GitHubScopedGrant(
      token: minted.accessToken,
      scope: granted,
      expiresAt: minted.expiresAt,
      lane: GitHubLane.connect,
      workspaceId: workspaceId,
      owner: owner,
      repo: repo,
      accountableUserId: human,
      // A user child is revoked through Connect with its parent seal; an
      // installation token revokes itself.
      connectSeal: actor == GitHubMintActor.app ? '' : seal,
      connectSealScope: actor == GitHubMintActor.app ? '' : sealed.scope,
      connectTarget: actor == GitHubMintActor.app ? null : target,
    );
  }

  /// Revokes a Connect user child through Connect, with its parent seal, and
  /// records the outcome.
  Future<void> _revokeConnectChild(
    ConnectTarget target,
    String sealScope,
    String seal,
    String token,
    GitHubRevokeReason reason, {
    required String workspaceId,
  }) async {
    final fields = {
      'workspace_id': workspaceId,
      'lane': GitHubLane.connect.wire,
      'reason': reason.wire,
    };
    try {
      await connect.githubRevoke(
        target,
        GitHubRevokeRequest(
          workspaceId: sealScope,
          seal: seal,
          scopedToken: token,
        ),
      );
      forgeAudit(ForgeAuditEvent.githubTokenRevoked, fields, token: token);
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
        ...fields,
        'error': e is ConnectException ? e.code.wire : e.runtimeType.toString(),
      }, token: token);
    }
  }

  /// Revokes an installation token (`DELETE /installation/token`, authed
  /// with itself), then proves it: a token GitHub still accepts afterwards
  /// is recorded as `github.token.revoke_failed`, never assumed revoked. A
  /// stateless installation token (`ghs_<app id>_<JWT>`) is the case this
  /// guards: GitHub does not promise the DELETE ends it before it expires.
  Future<void> _revokeInstallationToken(
    String token,
    GitHubRevokeReason reason, {
    required String workspaceId,
    required GitHubLane lane,
  }) async {
    final fields = {
      'workspace_id': workspaceId,
      'lane': lane.wire,
      'reason': reason.wire,
    };
    final deleted = await rest.send(
      'DELETE',
      '/installation/token',
      bearer: token,
    );
    if (deleted.status != 204) {
      forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
        ...fields,
        'status': deleted.status,
        'github_request_id': deleted.headers['x-github-request-id'],
      }, token: token);
      return;
    }
    final probe = await rest.send(
      'GET',
      '/installation/repositories',
      query: const {'per_page': '1'},
      bearer: token,
    );
    if (probe.status != 401) {
      forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
        ...fields,
        'status': probe.status,
        'detail': probe.status == 200 ? 'still_accepted' : 'unverified',
        'github_request_id': probe.headers['x-github-request-id'],
      }, token: token);
      return;
    }
    forgeAudit(ForgeAuditEvent.githubTokenRevoked, {
      ...fields,
      'github_request_id': deleted.headers['x-github-request-id'],
    }, token: token);
  }

  /// Revokes a user token (`DELETE /applications/{client_id}/token`) with
  /// [creds], the App that issued it, and records the outcome.
  Future<void> _revokeUserToken(
    String token,
    ({String clientId, String clientSecret})? creds,
    GitHubRevokeReason reason, {
    required String workspaceId,
    required GitHubLane lane,
  }) async {
    final fields = {
      'workspace_id': workspaceId,
      'lane': lane.wire,
      'reason': reason.wire,
    };
    if (creds == null) {
      forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
        ...fields,
        'detail': 'no_app_credentials',
      }, token: token);
      return;
    }
    final response = await rest.send(
      'DELETE',
      '/applications/${Uri.encodeComponent(creds.clientId)}/token',
      basic: creds,
      body: {'access_token': token},
    );
    forgeAudit(
      response.status == 204
          ? ForgeAuditEvent.githubTokenRevoked
          : ForgeAuditEvent.githubTokenRevokeFailed,
      {
        ...fields,
        'client_id': creds.clientId,
        if (response.status != 204) 'status': response.status,
        'github_request_id': response.headers['x-github-request-id'],
      },
      token: token,
    );
  }

  /// [human]'s facts about [owner]/[repo], read with their own token and
  /// cached briefly. Throws [GitHubScopeRefused].
  ///
  /// Unless [pinned] is false (a link being made, whose read is what pins
  /// it), every answer, cached or not, is held against the durable id the
  /// linked repository is pinned to ([confirmRepo]): another repository at
  /// that path is refused as [GitHubRefusal.repoReplaced]; the same one
  /// under a new path moves the link there. A repository GitHub moved
  /// answers 301 with its id; it is read again by id
  /// (`GET /repositories/{id}`) with the same token.
  Future<GitHubRepoFacts> repoFacts(
    String workspaceId,
    String human,
    String owner,
    String repo, {
    bool pinned = true,
  }) async {
    final key = gitHubRepoKey(workspaceId, human, owner, repo);
    final cached = _repos[key];
    if (cached != null && _now().difference(cached.at) < _repoCacheTtl) {
      if (pinned) {
        await _confirmPinned(workspaceId, owner, repo, cached.facts);
      }
      return cached.facts;
    }
    var stale = false;
    final epoch = _repoEpochs.open();
    GitHubRestResponse response;
    try {
      final token = await credentials.personToken(
        ForgeHost.github,
        human,
        workspaceId: workspaceId,
      );
      if (token == null) {
        throw const GitHubScopeRefused(
          GitHubRefusal.needsSignIn,
          'The accountable person needs to sign in to GitHub.',
        );
      }
      response = await rest.send(
        'GET',
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}',
        bearer: token,
      );
      final movedTo = _movedRepositoryId(response);
      if (movedTo != null) {
        response = await rest.send(
          'GET',
          '/repositories/$movedTo',
          bearer: token,
        );
      }
    } finally {
      // A forget that landed meanwhile (the person signed out or in as
      // someone else) means these facts are never cached.
      stale = _repoEpochs.close(epoch, key) != null;
    }
    if (response.status != 200) {
      throw switch (classifyGitHubRepoRead(response)) {
        GitHubRefusal.needsSignIn => const GitHubScopeRefused(
          GitHubRefusal.needsSignIn,
          'The accountable person needs to sign in to GitHub again.',
        ),
        GitHubRefusal.accessDenied => GitHubScopeRefused(
          GitHubRefusal.accessDenied,
          'The accountable person cannot access $owner/$repo on GitHub.',
        ),
        GitHubRefusal.rateLimited => const GitHubScopeRefused(
          GitHubRefusal.rateLimited,
          'GitHub is rate limiting the accountable person right now; it will '
          'be retried.',
        ),
        GitHubRefusal.ssoRequired => GitHubScopeRefused(
          GitHubRefusal.ssoRequired,
          '$owner enforces SAML single sign-on: the accountable person needs '
          "to sign in to GitHub again through the organization's SSO.",
        ),
        _ => const GitHubScopeRefused(
          GitHubRefusal.providerUnavailable,
          'GitHub is unreachable right now.',
        ),
      };
    }
    final json = response.json;
    final id = json is Map ? json['id'] : null;
    final name = json is Map ? json['name'] : null;
    final ownerJson = json is Map ? json['owner'] : null;
    final ownerId = ownerJson is Map ? ownerJson['id'] : null;
    final ownerLogin = ownerJson is Map ? ownerJson['login'] : null;
    if (json is! Map ||
        id is! int ||
        ownerId is! int ||
        name is! String ||
        ownerLogin is! String ||
        !isGitHubSegment(ownerLogin) ||
        !isGitHubSegment(name)) {
      throw const GitHubScopeRefused(
        GitHubRefusal.providerUnavailable,
        'GitHub returned an unreadable repository.',
      );
    }
    final facts = GitHubRepoFacts(
      id: id,
      owner: ownerLogin,
      name: name,
      ownerId: ownerId,
      isPublic: json['private'] != true && json['visibility'] != 'internal',
      role: GitHubRepoRole.fromPermissions(json['permissions']),
    );
    if (!stale) {
      final now = _now();
      _repos.removeWhere((_, v) => now.difference(v.at) >= _repoCacheTtl);
      while (_repos.length >= _maxCachedRepos) {
        _repos.remove(_repos.keys.first);
      }
      _repos[key] = (facts: facts, at: now);
    }
    if (pinned) {
      await _confirmPinned(workspaceId, owner, repo, facts);
    }
    return facts;
  }

  Future<void> _confirmPinned(
    String workspaceId,
    String owner,
    String repo,
    GitHubRepoFacts facts,
  ) async {
    try {
      await confirmRepo(workspaceId, ForgeHost.github, owner, repo, (
        id: '${facts.id}',
        owner: facts.owner,
        name: facts.name,
      ));
    } on AuthException catch (e) {
      if (e.code != forgeRepoReplacedCode) {
        rethrow;
      }
      throw GitHubScopeRefused(GitHubRefusal.repoReplaced, e.message);
    }
  }

  /// The id a 301 for a repository read names (`Location:
  /// https://api.github.com/repositories/{id}`, also the body's `url`), or
  /// null for any other answer.
  static int? _movedRepositoryId(GitHubRestResponse response) {
    if (response.status != 301) {
      return null;
    }
    final body = response.json;
    final location =
        response.headers['location'] ?? (body is Map ? body['url'] : null);
    if (location is! String) {
      return null;
    }
    final match = RegExp(
      r'^https://api\.github\.com/repositories/(\d{1,19})$',
    ).firstMatch(location);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Drops the cached facts for [key], so the next read asks GitHub.
  void forgetRepo(GitHubRepoKey key) => forgetReposWhere((k) => k == key);

  /// Drops every cached repository fact [drop] accepts, and any such read
  /// still in the air.
  void forgetReposWhere(bool Function(GitHubRepoKey key) drop) {
    _repoEpochs.drop(drop);
    _repos.removeWhere((key, _) => drop(key));
  }

  /// Revokes [grant] upstream and records the outcome; never throws (the
  /// token expires on its own).
  ///
  /// Per token type: a Connect child through the Connect that minted it,
  /// with its parent seal; an installation token (`ghs_`) with itself
  /// (`DELETE /installation/token`), then proven revoked; a person downscope
  /// (`ghu_` on an App lane) with the client credentials of the App that
  /// narrowed it, captured on the grant ([GitHubScopedGrant.appClient]).
  Future<void> revoke(
    GitHubScopedGrant grant, {
    required GitHubRevokeReason reason,
  }) async {
    try {
      if (grant.token.startsWith('ghs_')) {
        await _revokeInstallationToken(
          grant.token,
          reason,
          workspaceId: grant.workspaceId,
          lane: grant.lane,
        );
        return;
      }
      switch (grant.lane) {
        case GitHubLane.connect:
          final target = grant.connectTarget;
          if (grant.connectSeal.isEmpty || target == null) {
            forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
              'workspace_id': grant.workspaceId,
              'lane': grant.lane.wire,
              'reason': reason.wire,
              'detail': 'no_parent_seal',
            }, token: grant.token);
            return;
          }
          await _revokeConnectChild(
            target,
            grant.connectSealScope,
            grant.connectSeal,
            grant.token,
            reason,
            workspaceId: grant.workspaceId,
          );
        case GitHubLane.workspaceApp || GitHubLane.ownApp:
          await _revokeUserToken(
            grant.token,
            grant.appClient,
            reason,
            workspaceId: grant.workspaceId,
            lane: grant.lane,
          );
        case GitHubLane.none:
          break;
      }
    } on Object catch (e) {
      forgeAudit(ForgeAuditEvent.githubTokenRevokeFailed, {
        'workspace_id': grant.workspaceId,
        'lane': grant.lane.wire,
        'reason': reason.wire,
        'error': e.runtimeType.toString(),
      }, token: grant.token);
    }
  }
}

/// Who a token no person asked to act through ([GitHubMintActor.app]) comes
/// from on a shared Connect App: the one decision of what the bot does there.
///
/// The bot holds what writes nothing but issues itself (read, review,
/// comment). It never holds `write`: that is refused before Connect is
/// asked, since nothing binds an organization's installation of the shared
/// App to this server. `bot` (reviews, review comments) it holds only for an
/// install the Connect operator listed, which only Connect knows: the bot is
/// asked first, and when Connect answers `needs_requester` the work goes
/// out on [human]'s own one-repository token ([GitHubMintActor.user]),
/// which GitHub clamps to them. With nobody accountable the refusal stands.
Future<GitHubScopedGrant> connectBotOrPerson({
  required GitHubTokenScope scope,
  required String? human,
  required Future<GitHubScopedGrant> Function(GitHubMintActor actor) mint,
}) async {
  if (!scope.connectBotMayHold && !scope.connectBotNeedsListing) {
    throw const GitHubScopeRefused(
      GitHubRefusal.needsRequester,
      kGitHubNeedsRequesterMessage,
    );
  }
  try {
    return await mint(GitHubMintActor.app);
  } on GitHubScopeRefused catch (e) {
    if (e.code != GitHubRefusal.needsRequester ||
        !scope.connectBotNeedsListing ||
        human == null) {
      rethrow;
    }
    return mint(GitHubMintActor.user);
  }
}

/// What GitHub refusing a person's `GET /repos/{owner}/{repo}` amounts to.
///
/// A repository the token cannot see answers 404 ([GitHubRefusal.accessDenied]).
/// A 403 is only a denial when it is neither a rate limit (primary: a zero
/// `x-ratelimit-remaining`; secondary: a `retry-after`, or a message about a
/// rate limit or abuse detection), which is transient and never cached nor
/// recorded as blocking, nor SAML enforcement (`x-github-sso: required`, or a
/// message naming SAML), which the person fixes by signing in again. 401 is a
/// sign-in GitHub no longer accepts; anything else is an outage.
GitHubRefusal classifyGitHubRepoRead(GitHubRestResponse response) {
  final message =
      '${response.json is Map ? (response.json! as Map)['message'] ?? '' : ''}'
          .toLowerCase();
  final headers = response.headers;
  bool rateLimited() =>
      headers['x-ratelimit-remaining']?.trim() == '0' ||
      headers.containsKey('retry-after') ||
      message.contains('rate limit') ||
      message.contains('abuse');
  return switch (response.status) {
    401 => GitHubRefusal.needsSignIn,
    404 => GitHubRefusal.accessDenied,
    429 => GitHubRefusal.rateLimited,
    403 when rateLimited() => GitHubRefusal.rateLimited,
    403
        when (headers['x-github-sso'] ?? '').toLowerCase().startsWith(
              'required',
            ) ||
            message.contains('saml') =>
      GitHubRefusal.ssoRequired,
    403 => GitHubRefusal.accessDenied,
    _ => GitHubRefusal.providerUnavailable,
  };
}

/// Whether [granted] asks for nothing beyond [asked]: every permission it
/// names is in [asked], at the same level or `read` under a `write`.
bool gitHubPermissionsWithin(
  Map<String, String> granted,
  Map<String, String> asked,
) => granted.entries.every((entry) {
  final allowed = asked[entry.key];
  return allowed != null && (allowed == entry.value || entry.value == 'read');
});
