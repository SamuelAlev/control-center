import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_error_messages.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
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
  /// [GitHubScopeRefused] when there is none.
  Future<({String seal, String scope})> sealFor(
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

/// Repository id, owner id, visibility and the accountable human's role, as
/// that human's own token sees them.
final class GitHubRepoFacts {
  /// Creates the facts.
  const GitHubRepoFacts({
    required this.id,
    required this.ownerId,
    required this.isPublic,
    required this.role,
  });

  /// Numeric repository id.
  final int id;

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

  final DateTime Function() _now;

  final Map<GitHubRepoKey, ({GitHubRepoFacts facts, DateTime at})> _repos = {};

  /// Mints on [lane]. Throws [GitHubScopeRefused].
  Future<GitHubScopedGrant> mint({
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
    if (await app.isOwnerSuspended(owner)) {
      throw GitHubScopeRefused(
        GitHubRefusal.suspended,
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
        GitHubRefusal.notInstalled,
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
    if (json is! Map || token is! String || !token.startsWith('ghu_')) {
      throw const GitHubScopeRefused(
        GitHubRefusal.providerUnavailable,
        'GitHub returned no narrowed token.',
      );
    }
    if (!scopedTokenMatches(
      json,
      repoId: facts.id,
      permissions: granted.permissions,
    )) {
      throw GitHubScopeRefused(
        GitHubRefusal.accessDenied,
        'GitHub did not narrow the sign-in to $owner/$repo alone.',
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
        GitHubRefusal.needsSignIn,
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
        GitHubRefusal.needsSignIn,
        'The accountable person needs to sign in to GitHub again.',
      );
    }
    final facts = await repoFacts(workspaceId, human, owner, repo);
    final sealScope = stored.workspaceId ?? globalWorkspaceScope;
    try {
      final minted = await connect.githubScope(
        GitHubScopeRequest(
          seal: stored.token.seal,
          workspaceId: sealScope,
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
      final granted = GitHubTokenScope.fromWire(minted.grantedScope);
      if (granted == null || granted.index > scope.index) {
        // Connect answered a scope this server did not ask for, or one wider
        // than it did: never trust it.
        throw const GitHubScopeRefused(
          GitHubRefusal.providerUnavailable,
          'Control Center Connect answered an unexpected token scope.',
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
        connectSeal: minted.updatedSeal.isNotEmpty
            ? minted.updatedSeal
            : stored.token.seal,
        connectSealScope: sealScope,
      );
    } on ConnectException catch (e) {
      if (e.code.clearsGrant) {
        await credentials.clearToken(
          ForgeHost.github,
          userId: human,
          workspaceId: stored.workspaceId,
        );
      }
      throw GitHubScopeRefused(
        GitHubRefusal.fromConnect(e.code),
        connectErrorMessage(e.code, ConnectErrorContext.githubMint(owner)),
      );
    }
  }

  /// [human]'s facts about [owner]/[repo], read with their own token and
  /// cached briefly. Throws [GitHubScopeRefused].
  Future<GitHubRepoFacts> repoFacts(
    String workspaceId,
    String human,
    String owner,
    String repo,
  ) async {
    final key = gitHubRepoKey(workspaceId, human, owner, repo);
    final cached = _repos[key];
    if (cached != null && _now().difference(cached.at) < _repoCacheTtl) {
      return cached.facts;
    }
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
    final response = await rest.send(
      'GET',
      '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}',
      bearer: token,
    );
    switch (response.status) {
      case 200:
        break;
      case 401:
        throw const GitHubScopeRefused(
          GitHubRefusal.needsSignIn,
          'The accountable person needs to sign in to GitHub again.',
        );
      case 403 || 404:
        throw GitHubScopeRefused(
          GitHubRefusal.accessDenied,
          'The accountable person cannot access $owner/$repo on GitHub.',
        );
      default:
        throw const GitHubScopeRefused(
          GitHubRefusal.providerUnavailable,
          'GitHub is unreachable right now.',
        );
    }
    final json = response.json;
    final id = json is Map ? json['id'] : null;
    final ownerJson = json is Map ? json['owner'] : null;
    final ownerId = ownerJson is Map ? ownerJson['id'] : null;
    if (json is! Map || id is! int || ownerId is! int) {
      throw const GitHubScopeRefused(
        GitHubRefusal.providerUnavailable,
        'GitHub returned an unreadable repository.',
      );
    }
    final facts = GitHubRepoFacts(
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

  /// Drops the cached facts for [key], so the next read asks GitHub.
  void forgetRepo(GitHubRepoKey key) => _repos.remove(key);

  /// Drops every cached repository fact [drop] accepts.
  void forgetReposWhere(bool Function(GitHubRepoKey key) drop) =>
      _repos.removeWhere((key, _) => drop(key));

  /// Revokes [grant] upstream, best effort (it expires on its own).
  ///
  /// Per token type: a Connect child through Connect, with its parent seal;
  /// an installation token (`ghs_`) with itself (`DELETE
  /// /installation/token`); a person downscope (`ghu_` on an App lane) with
  /// the App's client credentials (`DELETE /applications/{id}/token`), when
  /// that App is still configured.
  Future<void> revoke(GitHubScopedGrant grant) async {
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
            await rest.send(
              'DELETE',
              '/installation/token',
              bearer: grant.token,
            );
          } else if (grant.token.startsWith('ghu_')) {
            final creds = await lanes.oauthFor(grant.workspaceId, grant.lane);
            if (creds != null) {
              await rest.send(
                'DELETE',
                '/applications/${Uri.encodeComponent(creds.clientId)}/token',
                basic: creds,
                body: {'access_token': grant.token},
              );
            }
          }
        case GitHubLane.none:
          break;
      }
    } on Object {
      // Best effort: the token expires on its own.
    }
  }
}
