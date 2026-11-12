/// The one record of whether the server can act on a linked repository.
///
/// Every writer (the poller's probes, the link sweep, automation mints, link
/// verification) records here, every reader (the automation gate, the
/// poller's skip list, the `repo_access` wire) reads here, and the record
/// survives a restart in the workspace's own database.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/repos/domain/value_objects/repo_access_cache_kinds.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_persistence/database/daos/cache_dao.dart';

/// Why the server cannot act on a repository.
enum RepoAccessState {
  /// The workspace's GitHub App is not installed on the repository's owner.
  appNotInstalled('app_not_installed'),

  /// The App is installed on the owner, but this repository is not among the
  /// installation's selected repositories.
  repoNotSelected('repo_not_selected'),

  /// The owner's installation is suspended.
  installationSuspended('installation_suspended'),

  /// The workspace's accountable person can no longer read the repository,
  /// so automation (which is bounded by them) has nothing to act with.
  ownerCannotSee('owner_cannot_see'),

  /// Nobody accountable for the workspace is signed in to this forge.
  ownerNotSignedIn('owner_not_signed_in'),

  /// A GitLab or Bitbucket repository has no automation token (its own or
  /// the workspace's) that can read it, so work with no person behind it
  /// is paused there until an admin adds one.
  automationTokenMissing('automation_token_missing'),

  /// The repository's owner/name now names a different repository on the
  /// forge than the one linked (its durable id differs: the original was
  /// deleted or moved and another created at that path). Nothing is minted,
  /// pushed or sent for it until an admin relinks it.
  repoReplaced('repo_replaced'),

  /// The last attempt failed for a reason that should pass (an outage, a
  /// rate limit). Shown, never blocking.
  transient('transient');

  const RepoAccessState(this.wire);

  /// The wire spelling.
  final String wire;

  /// Whether automation with no acting person must stop for this repository.
  /// A person acting on their own sign-in is never stopped by this record:
  /// their own forge access decides.
  bool get blocksAutomation => this != transient;

  /// Parses [wire]; null for anything unknown.
  static RepoAccessState? fromWire(String? wire) {
    for (final s in values) {
      if (s.wire == wire) {
        return s;
      }
    }
    return null;
  }
}

/// One repository the server cannot (fully) act on.
final class RepoAccessIssue {
  /// Creates a [RepoAccessIssue].
  const RepoAccessIssue({
    required this.forge,
    required this.owner,
    required this.name,
    required this.state,
    required this.since,
    required this.checkedAt,
    this.repoId,
    this.message = '',
    this.installUrl,
  });

  /// Decodes one persisted entry; null when it is malformed.
  static RepoAccessIssue? fromJson(Map<String, dynamic> json) {
    final state = RepoAccessState.fromWire(json['state'] as String?);
    final owner = json['owner'] as String?;
    final name = json['name'] as String?;
    final since = DateTime.tryParse(json['since'] as String? ?? '');
    if (state == null || owner == null || name == null || since == null) {
      return null;
    }
    return RepoAccessIssue(
      forge: ForgeHost.fromWire(json['forge'] as String?),
      owner: owner,
      name: name,
      repoId: json['repo_id'] as String?,
      state: state,
      since: since,
      checkedAt:
          DateTime.tryParse(json['checked_at'] as String? ?? '') ?? since,
      message: json['message'] as String? ?? '',
      installUrl: json['install_url'] as String?,
    );
  }

  /// The repository's forge.
  final ForgeHost forge;

  /// The repository's owner (GitLab: the full group path).
  final String owner;

  /// The repository's name.
  final String name;

  /// The linked repo row's id, when the writer knew it.
  final String? repoId;

  /// Why the server cannot act on it.
  final RepoAccessState state;

  /// When the repository entered [state].
  final DateTime since;

  /// When the state was last confirmed.
  final DateTime checkedAt;

  /// A person-readable explanation from the writer (never a token or URL
  /// with credentials in it).
  final String message;

  /// Where an admin installs the App or picks repositories, for
  /// [RepoAccessState.appNotInstalled] and [RepoAccessState.repoNotSelected].
  final String? installUrl;

  /// `owner/name`.
  String get fullName => '$owner/$name';

  /// Wire form. Also the persisted form.
  Map<String, dynamic> toJson() => {
    'forge': forge.wire,
    'owner': owner,
    'name': name,
    'repo_full_name': fullName,
    'repo_id': ?repoId,
    'state': state.wire,
    'since': since.toUtc().toIso8601String(),
    'checked_at': checkedAt.toUtc().toIso8601String(),
    if (message.isNotEmpty) 'message': message,
    'install_url': ?installUrl,
  };
}

typedef _RepoKey = ({String forge, String owner, String name});

_RepoKey _key(ForgeHost forge, String owner, String name) =>
    (forge: forge.wire, owner: owner.toLowerCase(), name: name.toLowerCase());

/// Per-workspace access records, persisted in each workspace's own database
/// (`caches` row [cacheKind]/[cacheKey]) and loaded lazily on first use.
class RepoAccessRegistry {
  /// Creates a [RepoAccessRegistry] over a lookup that resolves the
  /// workspace's own cache DAO per call (never cached here).
  RepoAccessRegistry({required this._cacheFor, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Cache kind of the persisted record.
  static const cacheKind = RepoAccessCacheKinds.repoAccess;

  /// Cache key (one row per workspace).
  static const cacheKey = 'v1';

  final CacheDao Function(String workspaceId) _cacheFor;
  final DateTime Function() _now;
  final Map<String, Map<_RepoKey, RepoAccessIssue>> _byWorkspace = {};
  final Map<String, Future<Map<_RepoKey, RepoAccessIssue>>> _loading = {};
  final Map<String, StreamController<List<RepoAccessIssue>>> _changes = {};

  Future<Map<_RepoKey, RepoAccessIssue>> _load(String workspaceId) {
    final loaded = _byWorkspace[workspaceId];
    if (loaded != null) {
      return Future.value(loaded);
    }
    return _loading.putIfAbsent(workspaceId, () async {
      final map = <_RepoKey, RepoAccessIssue>{};
      try {
        final raw = await _cacheFor(
          workspaceId,
        ).read(workspaceId, cacheKind, cacheKey);
        if (raw != null) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            for (final e in decoded) {
              if (e is Map) {
                final issue = RepoAccessIssue.fromJson(
                  e.cast<String, dynamic>(),
                );
                if (issue != null) {
                  map[_key(issue.forge, issue.owner, issue.name)] = issue;
                }
              }
            }
          }
        }
      } on Object catch (e) {
        // A corrupt or unreadable row starts empty; the next write replaces
        // it. Probes re-establish every state within one sweep.
        CcHostLog.warning(
          'repo access: the records of $workspaceId could not be read; '
          'starting empty until the next sweep (${e.runtimeType})',
        );
      }
      _byWorkspace[workspaceId] = map;
      unawaited(_loading.remove(workspaceId));
      return map;
    });
  }

  Future<void> _persist(String workspaceId) async {
    final map = _byWorkspace[workspaceId] ?? const {};
    final list = issuesSorted(map.values);
    _changes[workspaceId]?.add(list);
    await _cacheFor(workspaceId).put(
      workspaceId,
      cacheKind,
      cacheKey,
      jsonEncode([for (final i in list) i.toJson()]),
    );
  }

  /// [issues] sorted by full name, for stable frames.
  static List<RepoAccessIssue> issuesSorted(Iterable<RepoAccessIssue> issues) =>
      issues.toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

  /// Records that [owner]/[name] is in [state]. Keeps the original `since`
  /// while the state is unchanged, so "since" means since it broke.
  Future<void> record(
    String workspaceId, {
    required ForgeHost forge,
    required String owner,
    required String name,
    required RepoAccessState state,
    String? repoId,
    String message = '',
    String? installUrl,
  }) async {
    final map = await _load(workspaceId);
    final key = _key(forge, owner, name);
    final previous = map[key];
    final now = _now();
    final next = RepoAccessIssue(
      forge: forge,
      owner: owner,
      name: name,
      repoId: repoId ?? previous?.repoId,
      state: state,
      since: previous != null && previous.state == state ? previous.since : now,
      checkedAt: now,
      message: message,
      installUrl: installUrl,
    );
    final changed =
        previous == null ||
        previous.state != next.state ||
        previous.message != next.message ||
        previous.installUrl != next.installUrl ||
        previous.repoId != next.repoId;
    map[key] = next;
    if (changed) {
      await _persist(workspaceId);
    }
  }

  /// Records that the server reached [owner]/[name]: clears any issue.
  /// Returns true when an issue was cleared.
  Future<bool> recordReachable(
    String workspaceId, {
    required ForgeHost forge,
    required String owner,
    required String name,
  }) async {
    final map = await _load(workspaceId);
    if (map.remove(_key(forge, owner, name)) == null) {
      return false;
    }
    await _persist(workspaceId);
    return true;
  }

  /// The issue on [owner]/[name], or null when the server can act on it.
  Future<RepoAccessIssue?> issueFor(
    String workspaceId, {
    required ForgeHost forge,
    required String owner,
    required String name,
  }) async => (await _load(workspaceId))[_key(forge, owner, name)];

  /// Every issue in [workspaceId], sorted.
  Future<List<RepoAccessIssue>> issues(String workspaceId) async =>
      issuesSorted((await _load(workspaceId)).values);

  /// The issues of [workspaceId], live: the current list first, then every
  /// change.
  Stream<List<RepoAccessIssue>> watch(String workspaceId) =>
      Stream.multi((out) {
        // Listen before reading: a write landing during the read is
        // delivered, and the read itself reflects the newest in-memory state
        // when it completes, so nothing older overtakes it.
        final sub = _changeStream(workspaceId).listen(out.add);
        unawaited(issues(workspaceId).then(out.add, onError: out.addError));
        out.onCancel = sub.cancel;
      });

  /// [workspaceId]'s change stream; the controller lives until
  /// [forgetWorkspace] closes it.
  Stream<List<RepoAccessIssue>> _changeStream(String workspaceId) => _changes
      .putIfAbsent(
        workspaceId,
        StreamController<List<RepoAccessIssue>>.broadcast,
      )
      .stream;

  /// Drops the record of one repository (unlinked).
  Future<void> forgetRepo(
    String workspaceId, {
    required ForgeHost forge,
    required String owner,
    required String name,
  }) async {
    final map = await _load(workspaceId);
    if (map.remove(_key(forge, owner, name)) != null) {
      await _persist(workspaceId);
    }
  }

  /// Drops every record of [workspaceId] [drop] accepts (the identity that
  /// produced them changed, so they say nothing about the next attempt).
  Future<void> forgetWhere(
    String workspaceId,
    bool Function(RepoAccessIssue issue) drop,
  ) async {
    final map = await _load(workspaceId);
    final before = map.length;
    map.removeWhere((_, issue) => drop(issue));
    if (map.length != before) {
      await _persist(workspaceId);
    }
  }

  /// Re-reads [workspaceId]'s records from its database and tells every
  /// watcher. For when the database file was replaced underneath (a
  /// restore): what is in memory then describes the file that is gone.
  ///
  /// Watchers stay subscribed, unlike [forgetWorkspace]: the workspace is
  /// still there.
  Future<void> reload(String workspaceId) async {
    // A read of the replaced file that is still in flight would land after
    // this one and put the old records back.
    await _loading[workspaceId]?.catchError(
      (Object _) => <_RepoKey, RepoAccessIssue>{},
    );
    _byWorkspace.remove(workspaceId);
    final map = await _load(workspaceId);
    _changes[workspaceId]?.add(issuesSorted(map.values));
  }

  /// Drops every in-memory record of [workspaceId] (deleted). The persisted
  /// row goes with the workspace's database.
  void forgetWorkspace(String workspaceId) {
    _byWorkspace.remove(workspaceId);
    unawaited(_changes.remove(workspaceId)?.close());
  }
}
