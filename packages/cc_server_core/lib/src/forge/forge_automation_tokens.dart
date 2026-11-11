/// The automation-token slot for GitLab and Bitbucket: the bot credential
/// work with no person behind it uses on those forges.
///
/// GitHub automation rides the App's one-repository installation tokens and
/// shows as the Control Center bot. GitLab and Bitbucket have no App, but
/// they have bot tokens built for this: GitLab project and group access
/// tokens, Bitbucket repository, project and workspace access tokens. An
/// admin stores one per linked repository and optionally one per workspace
/// per forge (the repository's own wins). The open-PR poller, AI review
/// chatter, unrequested agent pushes and merge requests, and the link sweep
/// use ONLY this token; with none, that automation pauses for the repository
/// and the [RepoAccessRegistry] records
/// [RepoAccessState.automationTokenMissing]. There is no fallback to any
/// person's token. A person acting still uses their own token.
///
/// Tokens live in the server's secrets file under the workspace's keys
/// (deleted with it), never in a database and never on the wire: clients
/// see presence, the bot's name, the slot, and status.
library;

import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show BitbucketCredential;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_link_check.dart'
    show ForgeRepoProbe, probeForgeRepo;
import 'package:cc_server_core/src/forge/forge_probe.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:meta/meta.dart';

/// Where an automation token applies.
enum AutomationTokenScope {
  /// One linked repository.
  repo('repo'),

  /// Every linked repository on the forge in the workspace that has no
  /// token of its own.
  workspace('workspace');

  const AutomationTokenScope(this.wire);

  /// The wire spelling.
  final String wire;
}

/// Whether a stored automation token still works.
enum AutomationTokenStatus {
  /// Verified when saved; nothing has refused it since.
  active('active'),

  /// The forge refused it (revoked or expired): it is no longer used.
  rejected('rejected');

  const AutomationTokenStatus(this.wire);

  /// The wire spelling.
  final String wire;

  static AutomationTokenStatus _parse(Object? wire) =>
      wire == rejected.wire ? rejected : active;
}

/// Who a bot token acts as, as the forge describes it.
typedef AutomationTokenIdentity = ({
  String name,
  String login,
  String kind,
  List<String> scopes,
});

/// Checks that [token] is a bot token for [forge] and says who it is.
/// Throws [ValidationException] with a person-readable reason when it is
/// not one (a personal token, refused, the forge unreachable). A Bitbucket
/// access token cannot always name itself: its identity may come back
/// empty, and the repository probes decide.
typedef AutomationTokenIdentify =
    Future<AutomationTokenIdentity> Function(ForgeHost forge, String token);

/// One stored automation token, without the token.
final class AutomationTokenInfo {
  /// Creates the description.
  const AutomationTokenInfo({
    required this.forge,
    required this.scope,
    required this.status,
    required this.verifiedAt,
    this.repoId,
    this.botName = '',
    this.botLogin = '',
    this.kind = '',
    this.scopes = const [],
  });

  /// The forge.
  final ForgeHost forge;

  /// The slot it lives in.
  final AutomationTokenScope scope;

  /// The repository, for [AutomationTokenScope.repo].
  final String? repoId;

  /// The bot's display name (the token's name on GitLab).
  final String botName;

  /// The bot's account name.
  final String botLogin;

  /// `project`, `group` (GitLab) or `access_token` (Bitbucket).
  final String kind;

  /// The token's scopes, when the forge reports them.
  final List<String> scopes;

  /// Whether it still works.
  final AutomationTokenStatus status;

  /// When it was last verified.
  final DateTime verifiedAt;

  /// Wire form. Never carries the token.
  Map<String, Object?> toJson() => {
    'forge': forge.wire,
    'scope': scope.wire,
    'repo_id': ?repoId,
    'bot_name': botName,
    'bot_login': botLogin,
    'kind': kind,
    'scopes': scopes,
    'status': status.wire,
    'verified_at': verifiedAt.toUtc().toIso8601String(),
  };
}

/// What [ForgeAutomationTokens.save] stored, and the covered repositories
/// the token cannot read (workspace slot only; a repository slot refuses).
typedef AutomationTokenSaved = ({
  AutomationTokenInfo info,
  List<String> unreadable,
});

typedef _Stored = ({String token, AutomationTokenInfo info});

/// The automation-token slots of every workspace. See the library doc.
final class ForgeAutomationTokens {
  /// Creates the store over the server's secrets file.
  ForgeAutomationTokens({
    required this._secrets,
    required this._registry,
    AutomationTokenIdentify? identify,
    ForgeRepoProbe? probe,
    DateTime Function()? now,
  }) : _identify = identify ?? identifyAutomationToken,
       _probe = probe ?? probeForgeRepo,
       _now = now ?? DateTime.now;

  final FileSecretsStore _secrets;
  final RepoAccessRegistry _registry;
  final AutomationTokenIdentify _identify;
  final ForgeRepoProbe _probe;
  final DateTime Function() _now;

  static const _prefix = 'workspace_forge_automation:';

  /// Whether [forge] takes an automation token.
  static bool supports(ForgeHost forge) =>
      forge == ForgeHost.gitlab || forge == ForgeHost.bitbucket;

  /// Secrets-file key of a slot.
  static String secretKey(
    String workspaceId,
    ForgeHost forge, {
    String? repoId,
  }) => repoId == null || repoId.isEmpty
      ? '$_prefix$workspaceId:${forge.wire}'
      : '$_prefix$workspaceId:${forge.wire}:repo:$repoId';

  /// True when [key] is one of [workspaceId]'s automation tokens.
  static bool isWorkspaceSecret(String key, String workspaceId) =>
      key.startsWith('$_prefix$workspaceId:');

  /// What a paused repository says when it has no automation token.
  static String missingMessage(Repo repo) =>
      'Automation on ${repo.fullName} is paused: it has no '
      '${repo.forge.displayName} automation token. An admin can add '
      '${_tokenKinds(repo.forge)} in Settings → Repositories.';

  static String _tokenKinds(ForgeHost forge) => forge == ForgeHost.gitlab
      ? 'a project or group access token'
      : 'a repository, project or workspace access token';

  /// The token automation uses on [repo] in [workspaceId]: the repository's
  /// own, else the workspace's for that forge. Null when there is none (or
  /// the one in effect was refused), which also pauses the repository in
  /// the registry.
  Future<String?> tokenForRepo(String workspaceId, Repo repo) async {
    if (!supports(repo.forge) || !repo.hasForgeRemote) {
      return null;
    }
    final stored = await _inEffect(workspaceId, repo);
    if (stored != null && stored.info.status == AutomationTokenStatus.active) {
      return stored.token;
    }
    await _recordMissing(
      workspaceId,
      repo,
      stored == null ? missingMessage(repo) : _refusedMessage(repo),
    );
    return null;
  }

  Future<_Stored?> _inEffect(String workspaceId, Repo repo) async =>
      await _read(secretKey(workspaceId, repo.forge, repoId: repo.id)) ??
      await _read(secretKey(workspaceId, repo.forge));

  /// Whether automation on [repo] can read it with the token in effect:
  /// null when it can, else the issue to record. Never records by itself;
  /// a token the forge refuses outright is marked rejected.
  Future<RepoAccessIssue?> check(String workspaceId, Repo repo) async {
    final now = _now();
    RepoAccessIssue issue(RepoAccessState state, String message) =>
        RepoAccessIssue(
          forge: repo.forge,
          owner: repo.remoteOwner,
          name: repo.remoteName,
          repoId: repo.id,
          state: state,
          since: now,
          checkedAt: now,
          message: message,
        );
    final stored = await _inEffect(workspaceId, repo);
    if (stored == null) {
      return issue(
        RepoAccessState.automationTokenMissing,
        missingMessage(repo),
      );
    }
    if (stored.info.status == AutomationTokenStatus.rejected) {
      return issue(
        RepoAccessState.automationTokenMissing,
        _refusedMessage(repo),
      );
    }
    final status = await _probe(
      repo.forge,
      stored.token,
      repo.remoteOwner,
      repo.remoteName,
    );
    switch (status) {
      case 200:
        return null;
      case 401:
        await _markRejected(workspaceId, repo, stored);
        return issue(
          RepoAccessState.automationTokenMissing,
          _refusedMessage(repo),
        );
      case 403 || 404:
        return issue(
          RepoAccessState.automationTokenMissing,
          _cannotReadMessage(repo),
        );
      default:
        return issue(
          RepoAccessState.transient,
          '${repo.forge.displayName} could not be reached to check '
          '${repo.fullName}.',
        );
    }
  }

  static String _refusedMessage(Repo repo) =>
      '${repo.forge.displayName} refused the automation token for '
      '${repo.fullName} (revoked or expired), so automation there is paused. '
      'An admin can replace it in Settings → Repositories.';

  static String _cannotReadMessage(Repo repo) =>
      'The automation token for ${repo.fullName} cannot read it, so '
      'automation there is paused. An admin can replace it in Settings → '
      'Repositories.';

  Future<void> _markRejected(
    String workspaceId,
    Repo repo,
    _Stored stored,
  ) async {
    final key = secretKey(
      workspaceId,
      repo.forge,
      repoId: stored.info.scope == AutomationTokenScope.repo ? repo.id : null,
    );
    await _write(
      key,
      stored.token,
      _copy(stored.info, AutomationTokenStatus.rejected),
    );
    forgeAudit(ForgeAuditEvent.forgeAutomationTokenRejected, {
      'forge': repo.forge.wire,
      'workspace_id': workspaceId,
      'repo': repo.fullName,
      'scope': stored.info.scope.wire,
      'reason': 'forge_refused',
    }, token: stored.token);
  }

  /// Every automation token stored for [workspaceId], without the tokens:
  /// the workspace slots, and the slots of repositories in [linked]. Reads
  /// only; an unlinked repository's slot is deleted by [forgetRepo] and the
  /// link sweep ([pruneUnlinked]).
  Future<List<AutomationTokenInfo>> list(
    String workspaceId,
    List<Repo> linked,
  ) async {
    final linkedKeys = _repoKeys(workspaceId, linked);
    final keys = await _secrets.keysMatching(
      (key) =>
          isWorkspaceSecret(key, workspaceId) &&
          (!key.contains(':repo:') || linkedKeys.contains(key)),
    );
    final out = <AutomationTokenInfo>[];
    for (final key in keys..sort()) {
      final stored = await _read(key);
      if (stored != null) {
        out.add(stored.info);
      }
    }
    return out;
  }

  static Set<String> _repoKeys(String workspaceId, List<Repo> linked) => {
    for (final repo in linked)
      if (supports(repo.forge))
        secretKey(workspaceId, repo.forge, repoId: repo.id),
  };

  /// Deletes repository slots in [workspaceId] whose repository is not in
  /// [linked] (by id and forge). Returns how many went.
  Future<int> pruneUnlinked(String workspaceId, List<Repo> linked) async {
    final keep = _repoKeys(workspaceId, linked);
    final pruned = await _secrets.deleteMatching(
      (key) =>
          isWorkspaceSecret(key, workspaceId) &&
          key.contains(':repo:') &&
          !keep.contains(key),
    );
    if (pruned > 0) {
      forgeAudit(ForgeAuditEvent.forgeAutomationTokenCleared, {
        'workspace_id': workspaceId,
        'reason': 'unlinked',
        'count': pruned,
      });
    }
    return pruned;
  }

  /// Deletes [repo]'s own slot in [workspaceId]: it was unlinked there.
  Future<void> forgetRepo(String workspaceId, Repo repo) async {
    if (!supports(repo.forge)) {
      return;
    }
    final key = secretKey(workspaceId, repo.forge, repoId: repo.id);
    if (await _read(key) == null) {
      return;
    }
    await _secrets.deletePsk(key);
    forgeAudit(ForgeAuditEvent.forgeAutomationTokenCleared, {
      'forge': repo.forge.wire,
      'workspace_id': workspaceId,
      'repo': repo.fullName,
      'scope': AutomationTokenScope.repo.wire,
      'reason': 'unlinked',
    });
  }

  /// Verifies [token] with [forge] and stores it in [workspaceId]'s slot:
  /// [repo]'s own when given, else the workspace's. [linked] is the
  /// workspace's linked repositories.
  ///
  /// Refuses (ValidationException) a token that is not a bot token, that
  /// the forge refuses, or that cannot read [repo]; for the workspace slot,
  /// one that can read none of the repositories it would cover. Covered
  /// repositories it can read are un-paused; ones it cannot are paused and
  /// returned.
  Future<AutomationTokenSaved> save(
    String workspaceId, {
    required ForgeHost forge,
    required String token,
    required List<Repo> linked,
    Repo? repo,
  }) async {
    final value = token.trim();
    if (!supports(forge)) {
      throw const ValidationException(
        'Automation tokens are for GitLab and Bitbucket. GitHub automation '
        'uses the GitHub App.',
      );
    }
    if (value.isEmpty) {
      throw const ValidationException('Paste the access token.');
    }
    if (repo != null && (repo.forge != forge || !repo.hasForgeRemote)) {
      throw ValidationException(
        '${repo.fullName} is not a ${forge.displayName} repository.',
      );
    }
    final AutomationTokenIdentity identity;
    try {
      identity = await _identify(forge, value);
    } on ValidationException catch (e) {
      _rejectedOnSave(workspaceId, forge, repo, value, 'identity', e.message);
      rethrow;
    }
    final covered = repo != null
        ? [repo]
        : [
            for (final r in linked)
              if (r.forge == forge &&
                  r.hasForgeRemote &&
                  await _read(secretKey(workspaceId, forge, repoId: r.id)) ==
                      null)
                r,
          ];
    final readable = <Repo>[];
    final unreadable = <({Repo repo, int? status})>[];
    for (final r in covered) {
      final status = await _probe(forge, value, r.remoteOwner, r.remoteName);
      if (status == 200) {
        readable.add(r);
      } else {
        unreadable.add((repo: r, status: status));
      }
    }
    // Saved only once it reads at least one repository it would serve: the
    // forge naming a bot is not enough on its own.
    if (readable.isEmpty) {
      final message = unreadable.isEmpty
          ? 'Link a ${forge.displayName} repository first, so the token can '
                'be checked against it.'
          : _saveRefusal(
              forge,
              unreadable.first.repo,
              unreadable.first.status,
            );
      _rejectedOnSave(
        workspaceId,
        forge,
        repo,
        value,
        unreadable.isEmpty ? 'nothing_to_read' : 'cannot_read',
        message,
      );
      throw ValidationException(message);
    }
    final info = AutomationTokenInfo(
      forge: forge,
      scope: repo == null
          ? AutomationTokenScope.workspace
          : AutomationTokenScope.repo,
      repoId: repo?.id,
      botName: identity.name,
      botLogin: identity.login,
      kind: identity.kind,
      scopes: identity.scopes,
      status: AutomationTokenStatus.active,
      verifiedAt: _now(),
    );
    await _write(secretKey(workspaceId, forge, repoId: repo?.id), value, info);
    forgeAudit(ForgeAuditEvent.forgeAutomationTokenSaved, {
      'forge': forge.wire,
      'workspace_id': workspaceId,
      'scope': info.scope.wire,
      'repo': repo?.fullName,
      'bot_login': identity.login,
      'kind': identity.kind,
      'readable': readable.length,
      'unreadable': unreadable.length,
    }, token: value);
    for (final r in readable) {
      final current = await _registry.issueFor(
        workspaceId,
        forge: forge,
        owner: r.remoteOwner,
        name: r.remoteName,
      );
      if (current?.state == RepoAccessState.automationTokenMissing) {
        await _registry.recordReachable(
          workspaceId,
          forge: forge,
          owner: r.remoteOwner,
          name: r.remoteName,
        );
      }
    }
    for (final miss in unreadable) {
      await _recordMissing(
        workspaceId,
        miss.repo,
        _cannotReadMessage(miss.repo),
      );
    }
    return (
      info: info,
      unreadable: [for (final miss in unreadable) miss.repo.fullName],
    );
  }

  static void _rejectedOnSave(
    String workspaceId,
    ForgeHost forge,
    Repo? repo,
    String token,
    String reason,
    String message,
  ) => forgeAudit(ForgeAuditEvent.forgeAutomationTokenRejected, {
    'forge': forge.wire,
    'workspace_id': workspaceId,
    'scope': (repo == null
            ? AutomationTokenScope.workspace
            : AutomationTokenScope.repo)
        .wire,
    'repo': repo?.fullName,
    'reason': reason,
    'message': message,
  }, token: token);

  static String _saveRefusal(ForgeHost forge, Repo repo, int? status) =>
      switch (status) {
        401 => '${forge.displayName} does not accept this token.',
        403 || 404 =>
          'This token cannot read ${repo.fullName}. Give it read access to '
              'the repository (${forge == ForgeHost.gitlab ? 'the read_api '
                        'and read_repository scopes' : 'repository read'}) '
              'and try again.',
        _ =>
          '${forge.displayName} could not be reached to check the token '
              'against ${repo.fullName}. Try again.',
      };

  /// Removes [workspaceId]'s automation token for [forge] ([repoId]'s own,
  /// or the workspace's) and pauses the repositories left with none.
  /// Returns whether one was stored.
  Future<bool> clear(
    String workspaceId, {
    required ForgeHost forge,
    required List<Repo> linked,
    String? repoId,
  }) async {
    final key = secretKey(workspaceId, forge, repoId: repoId);
    final present = await _read(key) != null;
    await _secrets.deletePsk(key);
    if (!present) {
      return false;
    }
    forgeAudit(ForgeAuditEvent.forgeAutomationTokenCleared, {
      'forge': forge.wire,
      'workspace_id': workspaceId,
      'scope': (repoId == null
              ? AutomationTokenScope.workspace
              : AutomationTokenScope.repo)
          .wire,
      'repo_id': repoId,
      'reason': 'admin',
    });
    for (final r in linked) {
      if (r.forge != forge ||
          !r.hasForgeRemote ||
          (repoId != null && r.id != repoId)) {
        continue;
      }
      if (await _inEffect(workspaceId, r) == null) {
        await _recordMissing(workspaceId, r, missingMessage(r));
      }
    }
    return true;
  }

  Future<void> _recordMissing(String workspaceId, Repo repo, String message) =>
      _registry.record(
        workspaceId,
        forge: repo.forge,
        owner: repo.remoteOwner,
        name: repo.remoteName,
        state: RepoAccessState.automationTokenMissing,
        repoId: repo.id,
        message: message,
      );

  Future<_Stored?> _read(String key) async {
    final raw = await _secrets.readFresh(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return null;
      }
      final token = json['token'];
      final forge = ForgeHost.fromWire(json['forge'] as String?);
      if (token is! String || token.isEmpty || !supports(forge)) {
        return null;
      }
      final repoId = json['repo_id'] as String?;
      return (
        token: token,
        info: AutomationTokenInfo(
          forge: forge,
          scope: repoId == null
              ? AutomationTokenScope.workspace
              : AutomationTokenScope.repo,
          repoId: repoId,
          botName: json['bot_name'] as String? ?? '',
          botLogin: json['bot_login'] as String? ?? '',
          kind: json['kind'] as String? ?? '',
          scopes: [
            for (final s in json['scopes'] as List? ?? const [])
              if (s is String) s,
          ],
          status: AutomationTokenStatus._parse(json['status']),
          verifiedAt:
              DateTime.tryParse(json['verified_at'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(String key, String token, AutomationTokenInfo info) =>
      _secrets.writePsk(key, jsonEncode({...info.toJson(), 'token': token}));

  static AutomationTokenInfo _copy(
    AutomationTokenInfo info,
    AutomationTokenStatus status,
  ) => AutomationTokenInfo(
    forge: info.forge,
    scope: info.scope,
    repoId: info.repoId,
    botName: info.botName,
    botLogin: info.botLogin,
    kind: info.kind,
    scopes: info.scopes,
    status: status,
    verifiedAt: info.verifiedAt,
  );
}

/// The default [AutomationTokenIdentify].
///
/// GitLab: `GET /personal_access_tokens/self` (the token's name and scopes)
/// and `GET /user`, which must be a bot user (project and group access
/// tokens are; a personal access token is a person and is refused).
/// Bitbucket: an `email:token` API token is a person's and is refused; any
/// other token is asked `GET /2.0/user` ([bitbucketAccessTokenIdentity]).
Future<AutomationTokenIdentity> identifyAutomationToken(
  ForgeHost forge,
  String token,
) async {
  switch (forge) {
    case ForgeHost.gitlab:
      final self = await forgeGet(forge, token, '/personal_access_tokens/self');
      if (self.status == 401 || self.status == 403) {
        throw const ValidationException('GitLab does not accept this token.');
      }
      final user = await forgeGet(forge, token, '/user');
      if (self.status == null || user.status == null) {
        throw const ValidationException(
          'GitLab could not be reached to check the token. Try again.',
        );
      }
      if (user.status != 200 || user.json is! Map) {
        throw const ValidationException('GitLab does not accept this token.');
      }
      final u = user.json! as Map;
      if (u['bot'] != true) {
        throw const ValidationException(
          'This is a personal access token, so automation would act as that '
          'person. Use a project or group access token: GitLab shows its '
          'work as a bot.',
        );
      }
      final login = u['username'] as String? ?? '';
      final s = self.json is Map ? self.json! as Map : const {};
      return (
        name: (u['name'] as String?) ?? (s['name'] as String?) ?? login,
        login: login,
        kind: login.startsWith('group_')
            ? 'group'
            : login.startsWith('project_')
            ? 'project'
            : 'bot',
        scopes: [
          for (final scope in s['scopes'] as List? ?? const [])
            if (scope is String) scope,
        ],
      );
    case ForgeHost.bitbucket:
      if (BitbucketCredential.parse(token).isApiToken) {
        throw const ValidationException(
          'This is an Atlassian API token, which belongs to a person. Use a '
          'repository, project or workspace access token: Bitbucket shows '
          'its work as a bot.',
        );
      }
      final user = await forgeGet(forge, token, '/user');
      return bitbucketAccessTokenIdentity(token, user.status, user.json);
    case ForgeHost.github || ForgeHost.local:
      throw const ValidationException(
        'Automation tokens are for GitLab and Bitbucket.',
      );
  }
}

/// Who a Bitbucket [token] is, from its `GET /2.0/user` answer ([status],
/// [json]; status null when Bitbucket was not reached). Accepted as an
/// access token only on positive evidence:
///
/// * a 200 naming an `app_user` account (the bot behind an access token);
/// * a 401 or 403 for a token in Atlassian's access-token form (`ATCTT`):
///   `/2.0/user` takes only a person's credentials (its API reference lists
///   `forge-oauth2` and `api-token`), so it refuses an access token there.
///   [ForgeAutomationTokens.save] then requires the token to read a
///   repository it would serve, so a revoked one is still refused.
///
/// A 200 naming any other account (`user`, `team`) is a person's OAuth
/// token: automation would act as them. A refusal for a token not shaped
/// like an access token, or any other answer, proves nothing and is refused.
/// With no answer to judge by (unreachable, rate-limited, failing) nothing
/// is stored.
@visibleForTesting
AutomationTokenIdentity bitbucketAccessTokenIdentity(
  String token,
  int? status,
  Object? json,
) {
  if (status == null || status == 429 || status >= 500) {
    throw const ValidationException(
      'Bitbucket could not be reached to check the token. Try again.',
    );
  }
  if (status == 200) {
    final u = json is Map ? json : const {};
    if (u['type'] != 'app_user') {
      throw const ValidationException(
        'This token signs in as a person, so automation would act as them. '
        'Use a repository, project or workspace access token: Bitbucket '
        'shows its work as a bot.',
      );
    }
    return (
      name: u['display_name'] as String? ?? '',
      login: u['nickname'] as String? ?? '',
      kind: 'access_token',
      scopes: const <String>[],
    );
  }
  if ((status == 401 || status == 403) && token.startsWith('ATCTT')) {
    return (
      name: '',
      login: '',
      kind: 'access_token',
      scopes: const <String>[],
    );
  }
  throw const ValidationException(
    'Bitbucket does not accept this token as a repository, project or '
    'workspace access token.',
  );
}
