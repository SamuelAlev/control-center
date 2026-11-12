// StreamQueryStore is the only signal drift exposes for "a watch is still
// attached". It is not in the public library; closing without it would drop
// a live query stream the next time this file went idle.
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_persistence/database/code_index/code_index_database.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';

/// Hands out per-workspace DBs at `<dataDir>/<workspaceId>/workspace.db`.
///
/// Repositories hold this manager and resolve DAOs per call
/// (`_dbs.of(workspaceId).agentDao`) — never cache a DAO (pins the first
/// workspace). [of] is sync over `LazyDatabase` so Stream repos stay sync.
/// In-use DBs stay open until [close]/[closeAll]/[dropAndClose]. When
/// [idleAfter] is set, a file with no live watch and no in-flight statement
/// is closed that long after its last statement; the next [of] reopens it
/// without repeating `quick_check`. [useTransiently] still closes
/// cross-workspace fan-out opens that nothing else claimed. `quick_check`
/// runs once per file per process ([_integrityChecked]). [openCount] past
/// [softOpenLimit] is logged; [executorFactory] is injectable for a future
/// shared DriftIsolate.
///
/// A workspace the registry marks deleted has no database: [of] refuses its
/// id ([DeletedWorkspaceException]) instead of creating an empty file under
/// it. A file whose `quick_check` failed stays readable and takes no writes
/// ([integrityFailure]).
///
/// Each workspace also has a code index, `code_index.db` beside its
/// database, handed out by [codeIndexOf]. The two open independently (search
/// does not open the workspace's data, a message read does not open the
/// index) but share one lease: activity on either keeps both open, and idle
/// closing, [close] and [dropAndClose] take both. A code index that is
/// damaged, foreign or newer than this build is replaced by an empty one
/// rather than refused or put in read-only mode.
class WorkspaceDatabaseManager {
  /// Creates a manager rooted at [dataDir].
  ///
  /// [_global] supplies the install id stamped into each new workspace database
  /// and is the registry consulted by [allWorkspaceIds]. [executorFactory] defaults
  /// to [openWorkspaceDatabase] and exists so tests can hand out in-memory
  /// executors (and so a future shared-isolate strategy is a one-line swap).
  /// [codeIndexExecutorFactory] does the same for [codeIndexOf]: it defaults
  /// to [openCodeIndexDatabase], or to in-memory executors when
  /// [executorFactory] was given. [idleAfter] turns on idle closing; [clock]
  /// is the time source for that check (tests pass a fake).
  WorkspaceDatabaseManager({
    required String dataDir,
    required this._global,
    QueryExecutor Function(String workspaceId)? executorFactory,
    QueryExecutor Function(String workspaceId)? codeIndexExecutorFactory,
    this.onWarn,
    this.onError,
    this.onIntegrityFailure,
    this.idleAfter,
    DateTime Function()? clock,
  }) : _dataDir = dataDir,
       _clock = clock ?? DateTime.now,
       _fileBacked = executorFactory == null,
       _codeIndexFileBacked =
           executorFactory == null && codeIndexExecutorFactory == null,
       executorFactory =
           executorFactory ??
           ((workspaceId) => openWorkspaceDatabase(
             dataDir: dataDir,
             workspaceId: workspaceId,
           )),
       codeIndexExecutorFactory =
           codeIndexExecutorFactory ??
           (executorFactory != null
               ? ((_) => NativeDatabase.memory())
               : ((workspaceId) => openCodeIndexDatabase(
                   dataDir: dataDir,
                   workspaceId: workspaceId,
                 ))) {
    final idle = idleAfter;
    if (idle != null) {
      final tick = idle < const Duration(seconds: 15)
          ? idle
          : const Duration(seconds: 15);
      _idleTimer = Timer.periodic(tick, (_) {
        unawaited(evictIdle());
      });
    }
  }

  final String _dataDir;
  final GlobalDatabase _global;

  /// Whether workspaces open real files under [_dataDir] (the default
  /// executor). Tests hand out in-memory executors, which have no file to
  /// copy before an upgrade.
  final bool _fileBacked;

  /// Whether code indexes open real files (the default executor), so a
  /// damaged one is replaced by deleting it.
  final bool _codeIndexFileBacked;
  final Map<String, WorkspaceDatabase> _open = {};
  final Map<String, CodeIndexDatabase> _openCodeIndexes = {};

  /// One per workspace with either file open, shared by both.
  final Map<String, _WorkspaceLease> _leases = {};

  /// Idle pairs taken out of [_open] / [_openCodeIndexes] and not closed yet.
  ///
  /// [of] or [codeIndexOf] in that window puts the same instances back.
  /// Closing them while they were still cached handed the caller a connection
  /// this method then closed.
  final Map<String, _ParkedFiles> _closing = {};
  final DateTime Function() _clock;
  Timer? _idleTimer;
  bool _evicting = false;
  String? _installId;

  /// How long a workspace file with no live watch and no in-flight statement
  /// stays open after its last statement.
  ///
  /// Null disables idle closing. Tests and short-lived CLI tools leave it
  /// null and tear the file down themselves. The long-running server sets it
  /// so a workspace touched once does not keep an isolate, a page cache and
  /// a mapping for the rest of the process. A live watch or an in-flight
  /// statement holds the file open regardless of this duration.
  final Duration? idleAfter;

  /// Workspaces whose ONLY opener so far is a cross-workspace read.
  ///
  /// Removed the moment an ordinary [of] resolves the same workspace, which is
  /// what makes the close in [useTransiently] safe against a real request
  /// arriving mid-fan-out: the workspace has been claimed, so it is no longer
  /// this call's to close.
  final Set<String> _transientOnly = {};

  /// In-flight [useTransiently] calls per workspace, so nested or concurrent
  /// fan-outs close the file once, after the last one finishes.
  final Map<String, int> _transientDepth = {};

  /// Files whose `PRAGMA quick_check` has already passed in this process.
  ///
  /// Keyed by workspace id, and deliberately NOT cleared by [close]: the check
  /// describes bytes on disk that only this process writes, so re-running it
  /// on reopen would re-pay seconds to re-derive an answer that cannot have
  /// changed. [dropAndClose] does clear it — that path deletes the file, so a
  /// workspace later re-created or re-imported under the same id is different
  /// bytes and gets checked again.
  final Set<String> _integrityChecked = {};

  /// Workspaces whose `quick_check` failed in this process, with SQLite's
  /// finding. Such a file keeps serving reads and takes no writes.
  final Map<String, String> _integrityFailures = {};

  /// Code indexes whose `quick_check` passed in this process. Like
  /// [_integrityChecked], cleared only by [dropAndClose].
  final Set<String> _codeIndexChecked = {};

  /// Ids the registry marks deleted. [of] refuses them.
  final Set<String> _deletedIds = {};

  /// Builds the [QueryExecutor] for one workspace. Injectable for tests.
  final QueryExecutor Function(String workspaceId) executorFactory;

  /// Builds the [QueryExecutor] for one workspace's code index. Injectable
  /// for tests.
  final QueryExecutor Function(String workspaceId) codeIndexExecutorFactory;

  /// Warning sink, forwarded to each [WorkspaceDatabase].
  final void Function(String tag, String message)? onWarn;

  /// Error sink, forwarded to each [WorkspaceDatabase].
  final void Function(String tag, String message)? onError;

  /// Called once per process for each workspace whose `quick_check` fails,
  /// with SQLite's finding, so the host can tell the server owner.
  final void Function(String workspaceId, String finding)? onIntegrityFailure;

  /// Number of open workspace databases past which [onWarn] fires.
  ///
  /// Not a hard cap — refusing to open a workspace would be worse than the
  /// memory it saves. It is a tripwire for the assumption in this class's docs.
  static const softOpenLimit = 32;

  /// A workspace id must be a safe single path segment, because it becomes a
  /// DIRECTORY name. Ids are uuids everywhere in the product; anything else is
  /// rejected rather than sanitised, so a caller can't smuggle `../` into a path
  /// or collide two workspaces onto one directory.
  static final _safeId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$');

  /// Whether [workspaceId] is a legal workspace id / filename.
  static bool isValidWorkspaceId(String workspaceId) =>
      _safeId.hasMatch(workspaceId) &&
      !workspaceId.contains('..') &&
      workspaceId != '.' &&
      workspaceId != '..';

  /// Caches the install id so new workspace databases can be stamped with it.
  ///
  /// Call once during boot, before any workspace is touched. Minting it here
  /// (rather than lazily inside [of], which is synchronous) is what keeps [of]
  /// free of async work.
  Future<void> loadInstallId() async {
    final existing = await _global.workspaceRouteDao.meta(
      GlobalDatabase.installIdKey,
    );
    if (existing != null) {
      _installId = existing;
      return;
    }
    // First boot: mint and persist. Derived from the clock + a hash of the data
    // dir so two installs on one machine differ.
    final minted =
        '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '-${_dataDir.hashCode.toUnsigned(32).toRadixString(36)}';
    await _global.workspaceRouteDao.setMeta(
      GlobalDatabase.installIdKey,
      minted,
    );
    _installId = minted;
  }

  /// Loads the ids the registry marks deleted, so [of] can refuse them
  /// without an asynchronous lookup.
  ///
  /// Call once during boot, before any workspace is touched, with
  /// [loadInstallId].
  Future<void> loadDeletedWorkspaces() async {
    final all = await _global.workspaceRegistryDao.allIdsIncludingDeleted();
    final live = (await _global.workspaceRegistryDao.liveIds()).toSet();
    _deletedIds
      ..clear()
      ..addAll(all.where((id) => !live.contains(id)));
  }

  /// Records that the registry now marks [workspaceId] deleted. Called by the
  /// code that soft-deletes the registry row, before it drops the files.
  void markDeleted(String workspaceId) => _deletedIds.add(workspaceId);

  /// Records that [workspaceId] is registered and live again.
  void markLive(String workspaceId) => _deletedIds.remove(workspaceId);

  /// Whether the registry marks [workspaceId] deleted.
  bool isDeleted(String workspaceId) => _deletedIds.contains(workspaceId);

  /// Removes what is left on disk under a deleted workspace's id.
  ///
  /// Deleting a workspace removes its directory. Anything found there later
  /// was written by something that opened the id after the delete, and a
  /// deleted workspace keeps no files. Returns the ids that had a directory.
  Future<List<String>> removeFilesOfDeletedWorkspaces() async {
    final removed = <String>[];
    for (final id in _deletedIds.toList()) {
      if (!isValidWorkspaceId(id)) {
        continue;
      }
      final dir = Directory(workspaceDirPath(_dataDir, id));
      if (!dir.existsSync()) {
        continue;
      }
      await dropAndClose(id);
      removed.add(id);
    }
    return removed;
  }

  /// SQLite's finding for [workspaceId] when its `quick_check` failed in this
  /// process, or null. A workspace with a finding is read-only: its
  /// connection refuses writes, and the gates above answer with a refusal
  /// people can read instead of letting the write fail in SQLite.
  String? integrityFailure(String workspaceId) =>
      _integrityFailures[workspaceId];

  /// Every workspace with a failed `quick_check` in this process.
  Map<String, String> get integrityFailures =>
      Map.unmodifiable(_integrityFailures);

  /// The database for [workspaceId], opening (lazily) or reusing as needed.
  ///
  /// Synchronous by design — see the class docs. Throws [ArgumentError] on an
  /// id that isn't a legal path segment, loudly, because the alternative is
  /// writing a workspace's data to a path an attacker chose. Throws
  /// [DeletedWorkspaceException] for an id the registry marks deleted: opening
  /// it would create an empty database under a workspace that no longer
  /// exists.
  WorkspaceDatabase of(String workspaceId) => _resolve(workspaceId);

  WorkspaceDatabase _resolve(String workspaceId, {bool transient = false}) {
    _reclaimParked(workspaceId);
    final cached = _open[workspaceId];
    if (cached != null) {
      _leases[workspaceId]?.touch();
      if (!transient) {
        // Claimed by a real workspace-scoped caller — an in-flight fan-out
        // must no longer treat this file as its own to close.
        _transientOnly.remove(workspaceId);
      }
      return cached;
    }
    _requireOpenable(workspaceId);
    final lease = _leases.putIfAbsent(
      workspaceId,
      () => _WorkspaceLease(_clock),
    )..touch();
    final watches = _LeaseStreamQueryStore();
    lease.workspaceWatches = watches;
    final db = WorkspaceDatabase(
      DatabaseConnection(
        _ActivityExecutor(executorFactory(workspaceId), lease),
        streamQueries: watches,
      ),
      workspaceId: workspaceId,
      installId: _installId ?? 'unknown',
      onWarn: onWarn,
      onError: onError,
      // A file that failed is checked again on every open: the check is what
      // puts a new connection in read-only mode.
      skipIntegrityCheck:
          _integrityChecked.contains(workspaceId) &&
          !_integrityFailures.containsKey(workspaceId),
      onIntegrityChecked: (failure) => _recordIntegrity(workspaceId, failure),
      upgradeSnapshotDirectory: _fileBacked
          ? workspaceUpgradeSnapshotDir(_dataDir, workspaceId)
          : null,
    );
    _open[workspaceId] = db;
    if (transient) {
      _transientOnly.add(workspaceId);
    }
    if (_open.length > softOpenLimit) {
      onWarn?.call(
        'WorkspaceDatabaseManager',
        '${_open.length} workspace databases open (soft limit $softOpenLimit) — '
            'each holds a background isolate and a page cache; consider a '
            'shared drift isolate',
      );
    }
    return db;
  }

  /// Throws unless [workspaceId] may be opened: a legal path segment the
  /// registry does not mark deleted.
  void _requireOpenable(String workspaceId) {
    if (!isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'not a valid workspace id (must be a safe single path segment)',
      );
    }
    if (_deletedIds.contains(workspaceId)) {
      throw DeletedWorkspaceException(workspaceId);
    }
  }

  /// The code index of [workspaceId] (`code_index.db` beside its database),
  /// opening (lazily) or reusing as needed.
  ///
  /// Synchronous and validated like [of], and refuses a deleted workspace the
  /// same way. Opening it does not open the workspace's database. The file is
  /// derived data: when its first open finds it damaged (`quick_check`, or
  /// SQLite failing to read it), written by another application, or written
  /// by a newer build, it is deleted and created again empty, with a warning,
  /// and the statement that opened it runs against the new file. The indexer
  /// then fills every partition again, since none has a checkpoint.
  CodeIndexDatabase codeIndexOf(String workspaceId) {
    _reclaimParked(workspaceId);
    final cached = _openCodeIndexes[workspaceId];
    if (cached != null) {
      _leases[workspaceId]?.touch();
      return cached;
    }
    _requireOpenable(workspaceId);
    final lease = _leases.putIfAbsent(
      workspaceId,
      () => _WorkspaceLease(_clock),
    )..touch();
    final watches = _LeaseStreamQueryStore();
    lease.codeIndexWatches = watches;
    final db = CodeIndexDatabase(
      DatabaseConnection(
        _ActivityExecutor(
          _ReplaceableExecutor(
            open: () => codeIndexExecutorFactory(workspaceId),
            discard: () => _deleteCodeIndexFiles(workspaceId),
            onReplaced: (reason) => onWarn?.call(
              'WorkspaceDatabaseManager',
              'code index of workspace $workspaceId could not be used '
                  '(${describeStorageError(reason) ?? reason}); replaced it '
                  'with an empty one, which the indexer fills again',
            ),
          ),
          lease,
        ),
        streamQueries: watches,
      ),
      workspaceId: workspaceId,
      onWarn: onWarn,
      skipIntegrityCheck: _codeIndexChecked.contains(workspaceId),
      onIntegrityChecked: () => _codeIndexChecked.add(workspaceId),
    );
    _openCodeIndexes[workspaceId] = db;
    return db;
  }

  /// Deletes [workspaceId]'s code index file and its sidecars, for a file
  /// that cannot be used. Nothing to delete for in-memory code indexes: the
  /// next executor is a fresh database already.
  Future<void> _deleteCodeIndexFiles(String workspaceId) async {
    if (!_codeIndexFileBacked) {
      return;
    }
    final path = codeIndexPathFor(workspaceId);
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      // The connection's isolate releases its handle a moment after the
      // close returns, and Windows refuses to unlink an open file.
      for (var attempt = 0; file.existsSync(); attempt++) {
        try {
          file.deleteSync();
        } on FileSystemException {
          if (attempt == 4) {
            rethrow;
          }
          await Future<void>.delayed(
            Duration(milliseconds: 50 * (attempt + 1)),
          );
        }
      }
    }
  }

  void _recordIntegrity(String workspaceId, String? failure) {
    _integrityChecked.add(workspaceId);
    if (failure == null) {
      _integrityFailures.remove(workspaceId);
      return;
    }
    final firstReport = !_integrityFailures.containsKey(workspaceId);
    _integrityFailures[workspaceId] = failure;
    if (firstReport) {
      onIntegrityFailure?.call(workspaceId, failure);
    }
  }

  /// Runs [body] against [workspaceId], then closes the file if this call is
  /// what opened it and nothing else has claimed it since.
  ///
  /// The seam for cross-workspace reads. Answering "show me every workspace's
  /// agents" should not leave every workspace's database resident — but it must
  /// also not close one that a person is working in, or one whose live
  /// subscriptions would die with the connection. So the close is conditional
  /// on this call having been the opener AND no ordinary [of] having resolved
  /// the same workspace in the meantime; when in doubt it keeps the file open,
  /// which is the safe direction to be wrong in.
  Future<T> useTransiently<T>(
    String workspaceId,
    Future<T> Function(WorkspaceDatabase db) body,
  ) async {
    // ALWAYS transient, even when the file is already open. Passing
    // `transient: false` for an open file would CLAIM it — and a second
    // fan-out arriving while the first still held the file did exactly that,
    // clearing the ownership the first one needed to close it, so the file
    // leaked for the process's lifetime. A cross-workspace read never claims;
    // only an ordinary `of()` does.
    final db = _resolve(workspaceId, transient: true);
    _transientDepth[workspaceId] = (_transientDepth[workspaceId] ?? 0) + 1;
    try {
      return await body(db);
    } finally {
      final remaining = (_transientDepth[workspaceId] ?? 1) - 1;
      if (remaining > 0) {
        _transientDepth[workspaceId] = remaining;
      } else {
        _transientDepth.remove(workspaceId);
        if (_transientOnly.remove(workspaceId)) {
          await _closeWorkspaceDatabase(workspaceId);
        }
      }
    }
  }

  /// Closes the workspace database a fan-out opened, leaving the code index
  /// alone: the fan-out did not open it, and somebody else may be using it.
  Future<void> _closeWorkspaceDatabase(String workspaceId) async {
    final db = _open.remove(workspaceId);
    if (_openCodeIndexes.containsKey(workspaceId)) {
      _leases[workspaceId]?.workspaceWatches = null;
    } else {
      _leases.remove(workspaceId);
    }
    await db?.close();
  }

  /// Closes workspace files that have been idle for [idleAfter], each
  /// workspace's database and code index together.
  ///
  /// A pair is idle when nothing is watching either file, no statement is in
  /// flight on either, and no [useTransiently] call is inside it. Live watches and open
  /// transactions keep their file. No-op when [idleAfter] is null. Safe to
  /// call while a previous pass is still closing files.
  ///
  /// The idle file is detached before the close. [of] in that gap reclaims
  /// the same instance, and a statement that starts on it does too. Closing
  /// the cached instance after [of] had already returned it killed the
  /// caller's database. [_integrityChecked] is left alone: the next open of
  /// a file that really closed skips `quick_check`.
  Future<void> evictIdle() async {
    final idle = idleAfter;
    if (idle == null || _evicting) {
      return;
    }
    _evicting = true;
    try {
      final now = _clock();
      final victims = <String>[];
      for (final id in _leases.keys) {
        if (_isIdle(id, now, idle)) {
          victims.add(id);
        }
      }
      final parked = <String>[];
      for (final id in victims) {
        if (!_isIdle(id, _clock(), idle)) {
          continue;
        }
        final db = _open.remove(id);
        final codeIndex = _openCodeIndexes.remove(id);
        final lease = _leases.remove(id);
        _transientOnly.remove(id);
        if (lease == null || (db == null && codeIndex == null)) {
          continue;
        }
        _closing[id] = (db: db, codeIndex: codeIndex, lease: lease);
        parked.add(id);
      }
      // Lets an of() or a statement already queued on this event loop take
      // the lease before the close. Awaiting the close itself from inside
      // that caller would deadlock on this pass.
      await Future<void>.delayed(Duration.zero);
      for (final id in parked) {
        final closing = _closing.remove(id);
        if (closing == null) {
          continue;
        }
        if (_stillInUse(id, closing.lease, idle)) {
          _reclaim(id, closing);
          continue;
        }
        await closing.db?.close();
        await closing.codeIndex?.close();
      }
    } finally {
      _evicting = false;
    }
  }

  /// Puts [workspaceId]'s parked pair back in the open set, if idle closing
  /// parked it.
  void _reclaimParked(String workspaceId) {
    final parked = _closing.remove(workspaceId);
    if (parked != null) {
      _reclaim(workspaceId, parked);
    }
  }

  /// Puts [parked] back in the open set. Nothing can have opened [id] again
  /// while it was parked: every open reclaims the parked pair first.
  void _reclaim(String id, _ParkedFiles parked) {
    final db = parked.db;
    if (db != null) {
      _open[id] = db;
    }
    final codeIndex = parked.codeIndex;
    if (codeIndex != null) {
      _openCodeIndexes[id] = codeIndex;
    }
    _leases[id] = parked.lease;
    parked.lease.touch();
  }

  bool _stillInUse(String workspaceId, _WorkspaceLease lease, Duration idle) {
    if (_transientDepth.containsKey(workspaceId) || lease.isHeld) {
      return true;
    }
    return _clock().difference(lease.lastTouch) < idle;
  }

  bool _isIdle(String workspaceId, DateTime now, Duration idle) {
    if (_transientDepth.containsKey(workspaceId)) {
      return false;
    }
    final lease = _leases[workspaceId];
    if (lease == null || lease.isHeld) {
      return false;
    }
    return now.difference(lease.lastTouch) >= idle;
  }

  /// Every workspace id the registry has ever recorded, **including
  /// soft-deleted ones**.
  ///
  /// For bookkeeping only (telling a registered directory from a stray one in
  /// [orphanedDatabaseFiles]). Never a list of databases to open: a deleted
  /// workspace has no files, and [of] refuses its id. Anything that reads or
  /// maintains workspaces iterates [liveWorkspaceIds].
  Future<List<String>> allWorkspaceIds() =>
      _global.workspaceRegistryDao.allIdsIncludingDeleted();

  /// Every LIVE workspace id — what fan-outs, sweeps and snapshots iterate.
  Future<List<String>> liveWorkspaceIds() =>
      _global.workspaceRegistryDao.liveIds();

  /// Ids of currently-open databases.
  Iterable<String> get openIds => _open.keys;

  /// How many workspace databases are open.
  int get openCount => _open.length;

  /// Ids of workspaces whose code index is open.
  Iterable<String> get openCodeIndexIds => _openCodeIndexes.keys;

  /// Creates [workspaceId]'s directory + database eagerly, so a freshly created
  /// workspace has a real database (and its schema) before anything queries it.
  ///
  /// Idempotent: opening an existing database just runs `beforeOpen`.
  Future<WorkspaceDatabase> create(String workspaceId) async {
    final db = of(workspaceId);
    // Any query forces the LazyDatabase to open, which runs onCreate/beforeOpen.
    await db.customSelect('SELECT 1').get();
    return db;
  }

  /// Writes a consistent copy of [workspaceId]'s database to [destination]
  /// (which must not exist).
  ///
  /// A file on disk is copied on a connection of its own, so requests in that
  /// workspace do not queue behind the copy. An in-memory database (tests)
  /// has only its own connection.
  Future<void> snapshotTo(String workspaceId, String destination) async {
    if (_fileBacked && existsOnDisk(workspaceId)) {
      // Opening first makes sure the file is at the declared schema and that
      // the copy starts from a file this process has checked.
      await of(workspaceId).customSelect('SELECT 1').get();
      await snapshotDatabaseFile(
        source: pathFor(workspaceId),
        destination: destination,
      );
      return;
    }
    await of(workspaceId).backupTo(destination);
  }

  /// Closes [workspaceId]'s database and code index if open, releasing their
  /// isolates.
  Future<void> close(String workspaceId) async {
    final open = _open.remove(workspaceId);
    final codeIndex = _openCodeIndexes.remove(workspaceId);
    final closing = _closing.remove(workspaceId);
    _leases.remove(workspaceId);
    _transientOnly.remove(workspaceId);
    await open?.close();
    await codeIndex?.close();
    if (closing != null) {
      if (!identical(closing.db, open)) {
        await closing.db?.close();
      }
      if (!identical(closing.codeIndex, codeIndex)) {
        await closing.codeIndex?.close();
      }
    }
  }

  /// Closes every open workspace database and code index. Called on server
  /// shutdown.
  Future<void> closeAll() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final dbs = <GeneratedDatabase>{
      ..._open.values,
      ..._openCodeIndexes.values,
      for (final closing in _closing.values) ...[
        ?closing.db,
        ?closing.codeIndex,
      ],
    };
    _open.clear();
    _openCodeIndexes.clear();
    _leases.clear();
    _closing.clear();
    _transientOnly.clear();
    for (final db in dbs) {
      await db.close();
    }
  }

  /// Closes [workspaceId]'s database and code index and DELETES its whole
  /// directory (both files with it), then drops its pre-auth routes.
  ///
  /// This is what makes deleting a workspace cheap: it is removing a directory,
  /// not cascading forty foreign keys through a database shared with every other
  /// workspace. Taking the directory rather than just `workspace.db` is
  /// deliberate — the `-wal`/`-shm` sidecars and anything else the workspace
  /// accumulated go with it, so nothing is left to be re-adopted by a workspace
  /// that later reuses the id.
  ///
  /// The registry row is the caller's business (it is soft-deleted, so the
  /// workspace stays visible as "deleted" even though its data is gone).
  Future<void> dropAndClose(String workspaceId) async {
    await close(workspaceId);
    // The file is about to be deleted, so a workspace later created or
    // imported under this id is different bytes and must be checked again.
    _integrityChecked.remove(workspaceId);
    _integrityFailures.remove(workspaceId);
    _codeIndexChecked.remove(workspaceId);
    final dir = Directory(workspaceDirPath(_dataDir, workspaceId));
    // Retry before giving up. [close] above returns once drift has been asked
    // to close, but the underlying file handle is released by the background
    // isolate a moment later — and Windows refuses to unlink a file that is
    // still open, so the FIRST delete loses that race routinely. Swallowing
    // that exception meant the directory survived: on Windows the demo
    // reaper's workspaces were never actually reclaimed, only forgotten, and
    // the storage grew without bound behind a warning nobody reads. POSIX
    // unlinks an open file happily and takes the first attempt.
    for (var attempt = 0; attempt < 5; attempt++) {
      if (!dir.existsSync()) {
        break;
      }
      try {
        dir.deleteSync(recursive: true);
        break;
      } on FileSystemException catch (e) {
        if (attempt == 4) {
          onWarn?.call(
            'WorkspaceDatabaseManager',
            'could not delete ${dir.path} after ${attempt + 1} attempts: $e',
          );
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
      }
    }
    await _global.workspaceRouteDao.removeAllForWorkspace(workspaceId);
  }

  /// Absolute path of [workspaceId]'s own directory.
  ///
  /// Callers that need to put other per-workspace state on disk should hang it
  /// here, so it is deleted with the workspace.
  String dirFor(String workspaceId) => workspaceDirPath(_dataDir, workspaceId);

  /// Absolute path of [workspaceId]'s database file (it may not exist yet).
  /// See [dirFor] for the directory that holds it.
  String pathFor(String workspaceId) =>
      workspaceDatabasePath(_dataDir, workspaceId);

  /// Absolute path of [workspaceId]'s code index file (it may not exist yet).
  String codeIndexPathFor(String workspaceId) =>
      codeIndexDatabasePath(_dataDir, workspaceId);

  /// Whether [workspaceId] has a database on disk.
  bool existsOnDisk(String workspaceId) =>
      File(workspaceDatabasePath(_dataDir, workspaceId)).existsSync();

  /// Workspace databases on disk that no registry row claims.
  ///
  /// Reported rather than deleted or adopted: an unclaimed database is either a
  /// failed import or a registry that lost a row and both deserve a human.
  ///
  /// A directory only counts if it actually contains a `workspace.db`, which is
  /// what keeps the server's other data-dir folders (`backups/`, `models/`,
  /// `code-server/`) from being mistaken for workspaces.
  Future<List<String>> orphanedDatabaseFiles() async {
    final root = Directory(_dataDir);
    if (!root.existsSync()) {
      return const [];
    }
    final known = (await allWorkspaceIds()).toSet();
    final orphans = <String>[];
    for (final entity in root.listSync()) {
      if (entity is! Directory) {
        continue;
      }
      final id = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (known.contains(id) || !isValidWorkspaceId(id)) {
        continue;
      }
      final db = File(
        '${entity.path}${Platform.pathSeparator}$workspaceDatabaseFileName',
      );
      if (db.existsSync()) {
        orphans.add(db.path);
      }
    }
    return orphans;
  }
}

/// A workspace's database and code index while idle closing has taken them
/// out of the open set and not closed them yet.
typedef _ParkedFiles = ({
  WorkspaceDatabase? db,
  CodeIndexDatabase? codeIndex,
  _WorkspaceLease lease,
});

/// Recency and in-flight state for one workspace's open files: its database
/// and its code index share one, so activity on either holds both.
final class _WorkspaceLease {
  _WorkspaceLease(this._clock) : lastTouch = _clock();

  final DateTime Function() _clock;
  DateTime lastTouch;
  int _depth = 0;
  _LeaseStreamQueryStore? workspaceWatches;
  _LeaseStreamQueryStore? codeIndexWatches;

  /// True while a statement, transaction, or table watch is outstanding on
  /// either file.
  bool get isHeld =>
      _depth > 0 ||
      (workspaceWatches?.hasListeners ?? false) ||
      (codeIndexWatches?.hasListeners ?? false);

  void touch() => lastTouch = _clock();

  void enter() {
    _depth++;
    touch();
  }

  void leave() {
    if (_depth > 0) {
      _depth--;
    }
    touch();
  }
}

/// Counts listeners on drift's table-update stream.
///
/// Every `select.watch()` and every `tableUpdates()` listen subscribes here,
/// so a quiet screen that is still subscribed keeps the file open. The count
/// drops when the last listener cancels, after drift's one-turn grace.
final class _LeaseStreamQueryStore extends StreamQueryStore {
  int _listeners = 0;

  bool get hasListeners => _listeners > 0;

  @override
  Stream<Set<TableUpdate>> updatesForSync(TableUpdateQuery query) {
    final inner = super.updatesForSync(query);
    return Stream<Set<TableUpdate>>.multi((listener) {
      _listeners++;
      var released = false;
      void release() {
        if (released) {
          return;
        }
        released = true;
        _listeners--;
      }

      // Drift invalidates a watch's cached row inside the table-update
      // listener, before the write future completes. `Stream.multi`'s
      // controller delivers `add` on a later event-queue turn, so
      // `await write; await watch().first` reads the pre-write snapshot.
      // Sync delivery keeps that invalidation on the write's stack.
      final sub = inner.listen(
        listener.addSync,
        onError: (Object error, StackTrace stack) {
          listener.addErrorSync(error, stack);
        },
        onDone: () {
          release();
          listener.closeSync();
        },
      );
      listener.onCancel = () {
        release();
        return sub.cancel();
      };
    }, isBroadcast: true);
  }
}

/// Forwards a [QueryExecutor] and holds [_lease] for each in-flight call.
final class _ActivityExecutor implements QueryExecutor {
  _ActivityExecutor(this._inner, this._lease, {this._onClose});

  final QueryExecutor _inner;
  final _WorkspaceLease _lease;
  void Function()? _onClose;

  Future<T> _track<T>(Future<T> future) {
    _lease.enter();
    return future.whenComplete(_lease.leave);
  }

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) =>
      _track(_inner.ensureOpen(user));

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _track(_inner.runSelect(statement, args));

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _track(_inner.runInsert(statement, args));

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _track(_inner.runUpdate(statement, args));

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _track(_inner.runDelete(statement, args));

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _track(_inner.runCustom(statement, args));

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _track(_inner.runBatched(statements));

  @override
  TransactionExecutor beginTransaction() {
    _lease.enter();
    try {
      return _ActivityTransaction(_inner.beginTransaction(), _lease.leave);
    } catch (_) {
      _lease.leave();
      rethrow;
    }
  }

  @override
  QueryExecutor beginExclusive() {
    _lease.enter();
    try {
      return _ActivityExecutor(
        _inner.beginExclusive(),
        _lease,
        onClose: _lease.leave,
      );
    } catch (_) {
      _lease.leave();
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    try {
      await _inner.close();
    } finally {
      final hook = _onClose;
      _onClose = null;
      hook?.call();
    }
  }
}

/// The code index's executor: opens the file, and when that open refuses it
/// (damaged, foreign, newer than this build) discards it and opens a fresh
/// one, once.
///
/// The open is where the decision belongs: [WorkspaceDatabaseManager.codeIndexOf]
/// is synchronous, and the first statement is what opens the file. Doing it
/// here means that statement simply runs against the new, empty file.
final class _ReplaceableExecutor implements QueryExecutor {
  _ReplaceableExecutor({
    required QueryExecutor Function() open,
    required this._discard,
    required this._onReplaced,
  }) : _openExecutor = open,
       _inner = open();

  final QueryExecutor Function() _openExecutor;
  final Future<void> Function() _discard;
  final void Function(Object reason) _onReplaced;
  QueryExecutor _inner;
  bool _ready = false;
  Future<bool>? _opening;

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    if (_ready) {
      return _inner.ensureOpen(user);
    }
    // Concurrent first statements wait for the same open, so a file is
    // never discarded under a connection another statement is opening.
    return _opening ??= _openOrReplace(user).whenComplete(() {
      _opening = null;
    });
  }

  Future<bool> _openOrReplace(QueryExecutorUser user) async {
    try {
      final opened = await _inner.ensureOpen(user);
      _ready = true;
      return opened;
    } on Object catch (error) {
      final reason = _reasonToReplace(user, error);
      if (reason == null) {
        rethrow;
      }
      try {
        await _inner.close();
      } on Object {
        // The connection is being thrown away with its file.
      }
      await _discard();
      if (user is CodeIndexDatabase) {
        user.clearRefusal();
      }
      _inner = _openExecutor();
      _onReplaced(reason);
      final opened = await _inner.ensureOpen(user);
      _ready = true;
      return opened;
    }
  }

  /// Why the file that failed to open should be replaced, or null when the
  /// failure is not about the file (a full disk, a busy lock).
  static Object? _reasonToReplace(QueryExecutorUser user, Object error) {
    if (user is CodeIndexDatabase) {
      final refusal = user.refusal;
      if (refusal != null) {
        return refusal;
      }
    }
    if (error is DatabaseNewerThanBinaryException ||
        error is ForeignDatabaseFileException ||
        error is CodeIndexDamagedException ||
        storageFailureOf(error) == StorageFailure.damaged) {
      return error;
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _inner.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _inner.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _inner.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _inner.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _inner.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _inner.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() => _inner.beginTransaction();

  @override
  QueryExecutor beginExclusive() => _inner.beginExclusive();

  @override
  Future<void> close() => _inner.close();
}

/// Holds [_leave] from [beginTransaction] until the transaction ends.
final class _ActivityTransaction implements TransactionExecutor {
  _ActivityTransaction(this._inner, this._leave);

  final TransactionExecutor _inner;
  final void Function() _leave;
  var _finished = false;

  void _finish() {
    if (_finished) {
      return;
    }
    _finished = true;
    _leave();
  }

  @override
  bool get supportsNestedTransactions => _inner.supportsNestedTransactions;

  @override
  SqlDialect get dialect => _inner.dialect;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) => _inner.ensureOpen(user);

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) => _inner.runSelect(statement, args);

  @override
  Future<int> runInsert(String statement, List<Object?> args) =>
      _inner.runInsert(statement, args);

  @override
  Future<int> runUpdate(String statement, List<Object?> args) =>
      _inner.runUpdate(statement, args);

  @override
  Future<int> runDelete(String statement, List<Object?> args) =>
      _inner.runDelete(statement, args);

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) =>
      _inner.runCustom(statement, args);

  @override
  Future<void> runBatched(BatchedStatements statements) =>
      _inner.runBatched(statements);

  @override
  TransactionExecutor beginTransaction() => _inner.beginTransaction();

  @override
  QueryExecutor beginExclusive() => _inner.beginExclusive();

  @override
  Future<void> send() => _inner.send().whenComplete(_finish);

  @override
  Future<void> rollback() => _inner.rollback().whenComplete(_finish);

  @override
  Future<void> close() => _inner.close().whenComplete(_finish);
}
