import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show AuthException, UserDto;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/demo/demo_limits.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/redeem_capacity_exception.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// One live demo visitor's bookkeeping.
class DemoVisitor {
  /// Creates a visitor record.
  DemoVisitor({
    required this.workspaceId,
    required this.userId,
    required this.deviceId,
    required this.expiresAt,
    this.ip,
  });

  /// Rebuilds a record from [json].
  factory DemoVisitor.fromJson(Map<String, dynamic> json) => DemoVisitor(
    workspaceId: json['workspace_id'] as String,
    userId: json['user_id'] as String,
    deviceId: json['device_id'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    ip: json['ip'] as String?,
  );

  /// The workspace claimed by this visitor.
  final String workspaceId;

  /// The synthetic user provisioned for them.
  final String userId;

  /// The paired device their browser authenticates with.
  final String deviceId;

  /// When the workspace is reaped. Fixed at redemption, never extended.
  final DateTime expiresAt;

  /// The remote address that redeemed, for the per-IP cap.
  final String? ip;

  /// Serializes the record.
  Map<String, dynamic> toJson() => {
    'workspace_id': workspaceId,
    'user_id': userId,
    'device_id': deviceId,
    'expires_at': expiresAt.toIso8601String(),
    if (ip != null) 'ip': ip,
  };
}

/// Persisted demo bookkeeping: which workspaces are warm, which are claimed.
///
/// It lives in `<dataDir>/demo/state.json` rather than in the database because
/// `workspace_meta` is fixed-column self-identification and explicitly not a
/// settings table — adding a `demo_state` column would mean a product schema
/// migration for demo housekeeping. A JSON file next to the data is enough,
/// and boot reconciles it against the registry so a hard kill self-heals.
///
/// The file is written ATOMICALLY (temp file + rename) and is treated as a
/// HINT, never as the source of truth for what exists: the reconcile pass at
/// boot garbage-collects every registered workspace that neither the pool nor
/// a visitor owns, so a truncated or corrupt state file degrades to "every
/// visitor was reaped" instead of "every workspace leaks forever".
/// A seeded, unclaimed workspace waiting in the warm pool.
///
/// It carries WHEN it was seeded because the demo world is anchored to that
/// moment: the fixtures use relative markers (`@-3d`, `@-20h`) that the seeder
/// resolves to absolute timestamps once, at seed time. A workspace that sat
/// unclaimed for a day therefore hands its visitor a calendar week that ended
/// yesterday and a meeting "20 hours ago" that is really 44 — the demo looks
/// abandoned, which is the one thing it must never look.
class DemoWarmWorkspace {
  /// Creates a pool entry.
  const DemoWarmWorkspace({required this.workspaceId, required this.seededAt});

  /// Rebuilds an entry from [json].
  ///
  /// A bare string is a pre-stamp state file. It is read as seeded at the
  /// epoch — i.e. already stale — because the workspace it names could be
  /// arbitrarily old and there is no way to tell. Refreshing one workspace
  /// needlessly is free; handing out a week-old demo is not.
  factory DemoWarmWorkspace.fromJson(Object? json) {
    if (json is String) {
      return DemoWarmWorkspace(
        workspaceId: json,
        seededAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    final map = Map<String, dynamic>.from(json! as Map);
    return DemoWarmWorkspace(
      workspaceId: map['workspace_id'] as String,
      seededAt: DateTime.parse(map['seeded_at'] as String),
    );
  }

  /// The workspace id.
  final String workspaceId;

  /// When its fixtures were resolved to absolute timestamps.
  final DateTime seededAt;

  /// Serializes the entry.
  Map<String, dynamic> toJson() => {
    'workspace_id': workspaceId,
    'seeded_at': seededAt.toIso8601String(),
  };
}

/// The demo's persisted bookkeeping.
class DemoState {
  /// Creates state.
  DemoState({List<DemoWarmWorkspace>? pool, List<DemoVisitor>? visitors})
    : pool = pool ?? [],
      visitors = visitors ?? [];

  /// Rebuilds state from [json].
  factory DemoState.fromJson(Map<String, dynamic> json) => DemoState(
    pool: [
      for (final entry in json['pool'] as List? ?? const [])
        DemoWarmWorkspace.fromJson(entry),
    ],
    visitors: [
      for (final v in json['visitors'] as List? ?? const [])
        DemoVisitor.fromJson(Map<String, dynamic>.from(v as Map)),
    ],
  );

  /// Seeded workspaces waiting to be claimed.
  final List<DemoWarmWorkspace> pool;

  /// Claimed workspaces and their visitors.
  final List<DemoVisitor> visitors;

  /// Serializes the state.
  Map<String, dynamic> toJson() => {
    'pool': [for (final w in pool) w.toJson()],
    'visitors': [for (final v in visitors) v.toJson()],
  };
}

/// Seeds one workspace with the demo's fictional world.
typedef DemoWorkspaceSeed = Future<void> Function(String workspaceId);

/// Seeds the per-user, global-database lanes (the newsfeed) for one visitor.
typedef DemoUserSeed =
    Future<void> Function(String userId, String workspaceId);

/// The demo's front door and its reaper.
///
/// Redemption hands a visitor a **pre-seeded** workspace from a warm pool, a
/// synthetic user, a paired device and the same envelope the real invite flow
/// returns — so the web client needs no changes at all. A fixed TTL later, the
/// reaper takes it all back.
///
/// There is no global visitor cap: the door bounds per ADDRESS (concurrent
/// sessions and, at the HTTP layer, the redeem rate), not per head-count.
class DemoVisitorService {
  /// Creates the service.
  DemoVisitorService({
    required this.limits,
    required this.dataDir,
    required GlobalDatabase globalDb,
    required WorkspaceDatabaseManager workspaceDbs,
    required WorkspaceRepository workspaceRepository,
    required UserRepository userRepository,
    required WorkspaceMembershipRepository membershipRepository,
    required PairedDeviceSecretsPort secrets,
    required DomainEventBus eventBus,
    required DemoWorkspaceSeed seedWorkspace,
    required DemoUserSeed seedUser,
    required Future<Map<String, dynamic>> Function() describeDescriptor,
    required String Function() relayRoom,
    required String publicUrl,
    required String signalingUrl,
    void Function(String message)? log,
    DateTime Function()? now,
  }) : _globalDb = globalDb,
       _workspaceDbs = workspaceDbs,
       _workspaces = workspaceRepository,
       _users = userRepository,
       _members = membershipRepository,
       _secrets = secrets,
       _eventBus = eventBus,
       _seedWorkspace = seedWorkspace,
       _seedUser = seedUser,
       _describeDescriptor = describeDescriptor,
       _relayRoom = relayRoom,
       _publicUrl = publicUrl,
       _signalingUrl = signalingUrl,
       _log = log ?? _noopLog,
       _now = now ?? DateTime.now;

  static void _noopLog(String _) {}

  /// Operational bounds.
  final DemoLimits limits;

  /// The server's data directory.
  final String dataDir;

  final GlobalDatabase _globalDb;
  final WorkspaceDatabaseManager _workspaceDbs;
  final WorkspaceRepository _workspaces;
  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final PairedDeviceSecretsPort _secrets;
  final DomainEventBus _eventBus;
  final DemoWorkspaceSeed _seedWorkspace;
  final DemoUserSeed _seedUser;
  final Future<Map<String, dynamic>> Function() _describeDescriptor;
  final String Function() _relayRoom;
  final String _publicUrl;
  final String _signalingUrl;
  final void Function(String) _log;
  final DateTime Function() _now;

  static const _uuid = Uuid();

  DemoState _state = DemoState();
  Timer? _reaper;
  Future<void>? _fill;
  /// Serializes the front door. Redemption checks per-IP state and then spans
  /// seconds of awaits (an inline seed when the pool is dry, user + newsfeed
  /// writes); concurrent requests all passed the checks and each grew the
  /// demo past its bounds before any of them registered. One visitor at a
  /// time through the door also keeps the pool claim exact.
  Future<void> _door = Future<void>.value();
  bool _stopped = false;
  var _visitorSeq = 0;

  /// Cached disk-usage verdict, with the moment it was computed.
  ///
  /// Walking the whole data directory is O(files); doing it on every redeem
  /// put that cost in the request path and grew with the visitor count.
  bool _diskOver = false;
  DateTime _diskCheckedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Live visitors, oldest first.
  List<DemoVisitor> get visitors => List.unmodifiable(_state.visitors);

  /// Warm, unclaimed workspace ids.
  List<String> get pool =>
      List.unmodifiable([for (final w in _state.pool) w.workspaceId]);

  String get _stateDir => '$dataDir/demo';

  File get _stateFile => File('$_stateDir/state.json');

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Loads state, reconciles orphans and arms the reaper.
  ///
  /// Called AFTER the ready banner: the desktop kills a child that has not
  /// reported readiness in 20s, and seeding a pool is exactly the kind of work
  /// that would eat that budget.
  Future<void> start() async {
    await _load();
    await _reconcile();
    _reaper ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(_sweep()),
    );
    unawaited(_ensurePool());
  }

  /// Stops the reaper and reaps everything, so a clean shutdown leaves no
  /// half-owned workspaces behind.
  Future<void> stop() async {
    // Set FIRST: an in-flight pool fill is mid-seed against databases that are
    // about to close, and letting it run to completion turns a clean shutdown
    // into a page of "Channel was closed" noise.
    _stopped = true;
    _reaper?.cancel();
    _reaper = null;
    for (final visitor in [..._state.visitors]) {
      await _reap(visitor);
    }
    await _save();
  }

  // ── The door ─────────────────────────────────────────────────────────────

  /// Redeems a visitor and returns the SAME envelope shape the real invite
  /// flow returns, so the web client's existing auto-redeem path works
  /// untouched.
  ///
  /// [remoteIp] is used only for the per-IP concurrency cap. The whole
  /// redemption runs under the door lock, so a burst of concurrent requests
  /// is served one at a time rather than each observing pre-check state.
  Future<Map<String, dynamic>> redeem(
    Map<String, dynamic> body, {
    String? remoteIp,
  }) {
    final run = _door.then(
      (_) => _redeemLocked(body, remoteIp: remoteIp),
    );
    // A failed redemption must release the door for the next caller while its
    // error reaches its own caller.
    _door = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<Map<String, dynamic>> _redeemLocked(
    Map<String, dynamic> body, {
    String? remoteIp,
  }) async {
    if (_stopped) {
      throw const RedeemCapacityException(
        'The demo is shutting down. Please try again in a moment.',
      );
    }
    final code = body['code'];
    if (code is! String || code != limits.inviteCode) {
      throw const AuthException('Invite is invalid or expired');
    }

    await _sweep();

    if (remoteIp != null) {
      final fromIp = _state.visitors.where((v) => v.ip == remoteIp).length;
      if (fromIp >= limits.maxPerIp) {
        throw RedeemCapacityException(
          'You already have ${limits.maxPerIp} demo sessions open. '
          'Close one and try again.',
        );
      }
    }
    if (await _overDiskBudget()) {
      throw const RedeemCapacityException(
        'The demo is out of room right now. Please try again later.',
      );
    }

    final workspaceId = await _claimWorkspace();
    final now = _now();
    final handle = 'guest-${++_visitorSeq}-${_uuid.v4().substring(0, 4)}';
    final user = User(
      id: _uuid.v4(),
      handle: handle,
      displayName: 'Guest',
      createdAt: now,
      // A demo visitor never walks onboarding: they are dropped straight into a
      // furnished workspace, and an unset flag would strand them on the setup
      // gate the router holds until this is known.
      onboardingFinishedAt: now,
    );
    await _users.upsert(user);

    // Admin of their OWN sandbox. The boundary is the op registry, not the
    // role: `DemoProfile` already removed everything dangerous, and
    // `requireServerAdmin` still refuses them because they are not the
    // server owner.
    final member = WorkspaceMember(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      userId: user.id,
      role: WorkspaceRole.admin,
      joinedAt: now,
    );
    await _members.upsert(member);
    _eventBus.publish(
      WorkspaceMemberAdded(
        workspaceId: workspaceId,
        userId: user.id,
        role: WorkspaceRole.admin,
        occurredAt: now,
      ),
    );

    final deviceId = _uuid.v4();
    final psk = RemoteControlCrypto.generatePsk();
    final expiresAt = now.add(limits.ttl);
    await _globalDb.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: drift.Value(deviceId),
        userId: drift.Value(user.id),
        workspaceId: drift.Value(workspaceId),
        label: const drift.Value('Demo visitor (web)'),
        platform: const drift.Value('web'),
        pskRef: const drift.Value('file'),
        status: const drift.Value(PairedDeviceStatus.active),
        expiresAt: drift.Value(expiresAt),
      ),
    );
    await _secrets.writePsk(deviceId, psk);

    // The newsfeed is keyed by USER in the global database, so it is seeded per
    // visitor rather than per workspace — and reaped explicitly, because
    // dropping the workspace file cannot reach a global row.
    await _seedUser(user.id, workspaceId);

    _state.visitors.add(
      DemoVisitor(
        workspaceId: workspaceId,
        userId: user.id,
        deviceId: deviceId,
        expiresAt: expiresAt,
        ip: remoteIp,
      ),
    );
    await _save();
    unawaited(_ensurePool());
    _log(
      'demo: visitor ${user.handle} claimed $workspaceId '
      '(expires ${expiresAt.toIso8601String()})',
    );

    return {
      'device_id': deviceId,
      'psk': psk,
      'workspace_id': workspaceId,
      'role': WorkspaceRole.admin.wireName,
      'user': UserDto(
        id: user.id,
        handle: user.handle,
        displayName: user.displayName,
        email: user.email,
      ).toJson(),
      if (_publicUrl.isNotEmpty) 'server_url': _publicUrl,
      'descriptor': await _describeDescriptor(),
      'signaling_url': _signalingUrl,
      'room': _relayRoom(),
    };
  }

  // ── Pool ─────────────────────────────────────────────────────────────────

  /// Takes a warm workspace, seeding one inline if the pool ran dry.
  Future<String> _claimWorkspace() async {
    // The sweep runs every 60s, so an entry can go stale between sweeps and be
    // the very one at the head of the queue. Checking here as well means no
    // visitor can ever be handed a workspace older than the TTL, whatever the
    // timer happened to be doing.
    while (_state.pool.isNotEmpty) {
      final warm = _state.pool.removeAt(0);
      if (!_isStale(warm)) {
        return warm.workspaceId;
      }
      _log('demo: discarding stale warm workspace ${warm.workspaceId}');
      await _reapUnowned(warm.workspaceId);
    }
    _log('demo: pool empty, seeding inline (a visitor is waiting)');
    return _seedFreshWorkspace();
  }

  /// Whether [warm] has been sitting long enough that its fixtures have drifted.
  ///
  /// The window is the visitor TTL, which makes one invariant hold across the
  /// whole demo: **no demo database on disk is ever older than the TTL.** A
  /// claimed workspace is reaped at its TTL and an unclaimed one is refreshed
  /// on the same clock, so there is no path by which stale data reaches a
  /// screenshot.
  bool _isStale(DemoWarmWorkspace warm) =>
      _now().difference(warm.seededAt) >= limits.ttl;

  /// Tops the pool back up to [DemoLimits.poolSize], one workspace at a time.
  ///
  /// Serialized behind a single future: concurrent seeds contend on one SQLite
  /// connection, so filling two at once is slower than filling them in turn.
  Future<void> _ensurePool() {
    return _fill ??= () async {
      try {
        while (!_stopped && _state.pool.length < limits.poolSize) {
          if (await _overDiskBudget()) {
            _log('demo: disk budget reached, stopping pool fill');
            break;
          }
          final id = await _seedFreshWorkspace();
          _state.pool.add(
            DemoWarmWorkspace(workspaceId: id, seededAt: _now()),
          );
          await _save();
        }
      } on Object catch (e) {
        if (!_stopped) {
          _log('demo: pool fill failed: $e');
        }
      } finally {
        _fill = null;
      }
    }();
  }

  /// Creates and fully seeds one workspace, returning its id.
  Future<String> _seedFreshWorkspace() async {
    final id = _uuid.v4();
    await _workspaces.upsert(
      Workspace(
        id: id,
        name: kDemoWorkspaceName,
        createdAt: _now(),
        updatedAt: _now(),
      ),
    );
    // Seed directly rather than relying on the `WorkspaceCreated` listener:
    // that listener is `unawaited`, so the pool would race it and hand out a
    // half-furnished workspace.
    await _seedWorkspace(id);
    return id;
  }

  // ── Reaper ───────────────────────────────────────────────────────────────

  /// Reaps every expired visitor.
  Future<void> _sweep() async {
    final now = _now();
    final expired = _state.visitors
        .where((v) => !v.expiresAt.isAfter(now))
        .toList();

    // Unclaimed workspaces expire on the same clock as claimed ones. Without
    // this the pool was write-once: a workspace seeded at boot and never
    // claimed stayed on disk for the life of the process, and its fixtures —
    // resolved to absolute timestamps at seed time — aged with it.
    final stale = _state.pool.where(_isStale).toList();

    if (expired.isEmpty && stale.isEmpty) {
      return;
    }
    for (final visitor in expired) {
      await _reap(visitor);
    }
    for (final warm in stale) {
      _state.pool.removeWhere((w) => w.workspaceId == warm.workspaceId);
      _log('demo: refreshing stale warm workspace ${warm.workspaceId}');
      await _reapUnowned(warm.workspaceId);
    }
    await _save();
    unawaited(_ensurePool());
  }

  /// Takes back everything one visitor was given.
  ///
  /// Order matters. Dropping their subscriptions FIRST means the tab shows an
  /// honest unauthorized state instead of reading a database being deleted
  /// underneath it — and revoking the DEVICE is what actually closes the
  /// socket: `LocalRpcServer` watches `paired_devices` and drops any session
  /// whose device left the active set. Publishing `WorkspaceMemberRemoved`
  /// alone only drops subscriptions; the connection stays open.
  ///
  /// The visitor stays registered until teardown SUCCEEDS: a step that throws
  /// (a busy database, a file lock) used to unregister them permanently, so
  /// nothing ever retried and their device could outlive their workspace in
  /// active state. A failed reap is logged and retried by the next sweep.
  Future<void> _reap(DemoVisitor visitor) async {
    try {
      _eventBus.publish(
        WorkspaceMemberRemoved(
          workspaceId: visitor.workspaceId,
          userId: visitor.userId,
          occurredAt: _now(),
        ),
      );

      // Closes the socket (the paired-device watch), then removes the secret.
      await _globalDb.pairedDeviceDao.remove(visitor.deviceId);
      await _secrets.deletePsk(visitor.deviceId);

      // Deletes the directory AND the workspace_routes rows.
      await _workspaces.delete(visitor.workspaceId);
      await _workspaceDbs.dropAndClose(visitor.workspaceId);

      // Rows the workspace file cannot reach. `workspaceRepository.delete`
      // only SOFT-deletes the registry row; at demo scale that would accrete
      // thousands of tombstones in global.db, so it is hard-deleted here.
      await _deleteGlobalRowsFor(visitor);
      _state.visitors.removeWhere((v) => v.deviceId == visitor.deviceId);
      _log('demo: reaped ${visitor.workspaceId}');
    } on Object catch (e) {
      _log(
        'demo: reaping ${visitor.workspaceId} failed (will retry next sweep): '
        '$e',
      );
    }
  }

  /// Deletes the visitor's global-database rows: their newsfeed, preferences,
  /// user row and the workspace registry tombstone.
  Future<void> _deleteGlobalRowsFor(DemoVisitor visitor) async {
    await _deleteUserRows(visitor.userId);
    final db = _globalDb;
    await (db.delete(
      db.workspacesTable,
    )..where((t) => t.id.equals(visitor.workspaceId))).go();
  }

  // ── Boot reconcile + persistence ─────────────────────────────────────────

  /// Reconciles persisted state against reality after a restart.
  ///
  /// A hard kill (or a truncated state file) leaves workspaces that no state
  /// entry owns. On a demo host EVERY workspace is demo-owned, so the
  /// complement set — registered, neither pooled nor claimed — is garbage and
  /// is reaped here: directory dropped, registry row hard-deleted, any paired
  /// devices for it revoked, and the guest users those devices point at
  /// removed (the shared cast is spared by id). Surviving visitors keep their
  /// remaining time; expired ones are swept right after.
  Future<void> _reconcile() async {
    final registered = <String>{
      for (final w in await _workspaces.getAll()) w.id,
    };
    _state.pool.removeWhere((w) => !registered.contains(w.workspaceId));

    final owned = <String>{
      for (final w in _state.pool) w.workspaceId,
      for (final v in _state.visitors) v.workspaceId,
    };
    final orphans = registered.difference(owned).toList()..sort();
    if (orphans.isNotEmpty) {
      _log('demo: reaping ${orphans.length} unowned workspace(s) at boot');
      for (final workspaceId in orphans) {
        await _reapUnowned(workspaceId);
      }
    }

    final vanished = _state.visitors
        .where((v) => !registered.contains(v.workspaceId))
        .toList();
    for (final visitor in vanished) {
      _state.visitors.removeWhere((v) => v.deviceId == visitor.deviceId);
      await _deleteGlobalRowsFor(visitor);
    }
    await _sweep();
    await _save();
    _log(
      'demo: reconciled — ${_state.visitors.length} visitor(s), '
      '${_state.pool.length} warm workspace(s)',
    );
  }

  /// Deletes a workspace no state entry owns: its files, its registry row,
  /// any paired devices still pointing at it, and the guest users behind
  /// those devices.
  Future<void> _reapUnowned(String workspaceId) async {
    try {
      final db = _globalDb;
      final devices =
          await (db.select(
            db.pairedDevicesTable,
          )..where((t) => t.workspaceId.equals(workspaceId))).get();
      for (final device in devices) {
        await _globalDb.pairedDeviceDao.remove(device.id);
        await _secrets.deletePsk(device.id);
        // A demo guest's user row is unreachable the moment their device and
        // workspace go; the cast is shared across every workspace and spared.
        // `userId` is nullable on the row (a device can be paired before an
        // identity is bound), and a null one owns no user to delete.
        final userId = device.userId;
        if (userId != null && !isDemoCastMember(userId)) {
          await _deleteUserRows(userId);
        }
      }
      await _workspaces.delete(workspaceId);
      await _workspaceDbs.dropAndClose(workspaceId);
      await (db.delete(
        db.workspacesTable,
      )..where((t) => t.id.equals(workspaceId))).go();
    } on Object catch (e) {
      _log('demo: reaping unowned $workspaceId failed: $e');
    }
  }

  /// Deletes one user's global rows (newsfeed, preferences, the user). Used
  /// both for reaped visitors and for guests discovered behind an unowned
  /// workspace, whose [DemoVisitor] record no longer exists to drive it.
  Future<void> _deleteUserRows(String userId) async {
    final db = _globalDb;
    final feeds =
        await (db.select(
          db.rssFeedsTable,
        )..where((t) => t.userId.equals(userId))).get();
    for (final feed in feeds) {
      await (db.delete(
        db.rssArticlesTable,
      )..where((t) => t.feedId.equals(feed.id))).go();
    }
    await (db.delete(
      db.rssFeedsTable,
    )..where((t) => t.userId.equals(userId))).go();
    await (db.delete(
      db.userPreferencesTable,
    )..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.usersTable)..where((t) => t.id.equals(userId))).go();
  }

  Future<void> _load() async {
    try {
      if (!_stateFile.existsSync()) {
        return;
      }
      final decoded = jsonDecode(await _stateFile.readAsString());
      if (decoded is Map) {
        _state = DemoState.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on Object catch (e) {
      // A corrupt file must not stop the demo booting: the reconcile pass
      // below reaps every registered workspace this state does not own, which
      // is the correct recovery for "the bookkeeping is gone".
      _log('demo: could not read state.json ($e); starting fresh');
      _state = DemoState();
    }
  }

  /// Writes the state ATOMICALLY: a unique temp file first, then rename.
  ///
  /// A bare `writeAsString` interrupted by a crash leaves a truncated file;
  /// combined with "start fresh on corruption" that silently orphaned every
  /// claimed workspace. Rename is atomic on every filesystem the demo runs
  /// on, so readers see either the old or the new file, never a partial one.
  ///
  /// Serialized behind a lock with a UNIQUE temp name per save: saves fire
  /// concurrently (reconcile, sweep, pool fill, shutdown), and two writers
  /// sharing one `state.json.tmp` raced — the first rename consumed the
  /// second writer's file and the second rename failed with ENOENT.
  Future<void> _save() {
    final run = (_saveLock ?? Future<void>.value()).then((_) async {
      try {
        final dir = Directory(_stateDir);
        await dir.create(recursive: true);
        final tmp = File(
          '$_stateDir/state.json.${_now().microsecondsSinceEpoch}'
          '.${_saveSeq++}.tmp',
        );
        await tmp.writeAsString(jsonEncode(_state.toJson()));
        await tmp.rename(_stateFile.path);
      } on Object catch (e) {
        _log('demo: could not persist state.json: $e');
      }
    });
    // The chain head moves BEFORE the work runs, so a caller arriving mid-save
    // queues behind it; a failed save must not poison the ones after it.
    _saveLock = run;
    return run;
  }

  Future<void>? _saveLock;
  int _saveSeq = 0;

  /// Whether the data directory has grown past the configured budget.
  ///
  /// The verdict is cached for a minute: the walk is O(files in the data dir)
  /// and it used to run inline on every redemption, so the door got slower as
  /// the demo got fuller. The budget is a coarse brake, not accounting — a
  /// one-minute-stale answer is well inside its purpose.
  Future<bool> _overDiskBudget() async {
    final now = _now();
    if (now.difference(_diskCheckedAt) < const Duration(minutes: 1)) {
      return _diskOver;
    }
    _diskCheckedAt = now;
    _diskOver = await _measureDiskOverBudget();
    return _diskOver;
  }

  Future<bool> _measureDiskOverBudget() async {
    try {
      var total = 0;
      final dir = Directory(dataDir);
      if (!dir.existsSync()) {
        return false;
      }
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
          if (total > limits.diskBudgetBytes) {
            return true;
          }
        }
      }
      return false;
    } on Object {
      // A stat failure must not wedge the door shut.
      return false;
    }
  }
}
