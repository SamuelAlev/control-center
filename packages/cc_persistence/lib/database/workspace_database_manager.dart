// StreamQueryStore is the only signal drift exposes for "a watch is still
// attached". It is not in the public library; closing without it would drop
// a live query stream the next time this file went idle.
// ignore_for_file: implementation_imports, invalid_use_of_internal_member
import 'dart:async';
import 'dart:io';

import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';
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
class WorkspaceDatabaseManager {
  /// Creates a manager rooted at [dataDir].
  ///
  /// [_global] supplies the install id stamped into each new workspace database
  /// and is the registry consulted by [allWorkspaceIds]. [executorFactory] defaults
  /// to [openWorkspaceDatabase] and exists so tests can hand out in-memory
  /// executors (and so a future shared-isolate strategy is a one-line swap).
  /// [idleAfter] turns on idle closing; [clock] is the time source for that
  /// check (tests pass a fake).
  WorkspaceDatabaseManager({
    required String dataDir,
    required this._global,
    QueryExecutor Function(String workspaceId)? executorFactory,
    this.onWarn,
    this.onError,
    this.idleAfter,
    DateTime Function()? clock,
  }) : _dataDir = dataDir,
       _clock = clock ?? DateTime.now,
       executorFactory =
           executorFactory ??
           ((workspaceId) => openWorkspaceDatabase(
             dataDir: dataDir,
             workspaceId: workspaceId,
           )) {
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
  final Map<String, WorkspaceDatabase> _open = {};
  final Map<String, _WorkspaceLease> _leases = {};

  /// Idle files taken out of [_open] and not closed yet.
  ///
  /// [of] in that window puts the same instance back. Closing it while it
  /// was still cached handed the caller a connection this method then closed.
  final Map<String, ({WorkspaceDatabase db, _WorkspaceLease lease})> _closing =
      {};
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

  /// Builds the [QueryExecutor] for one workspace. Injectable for tests.
  final QueryExecutor Function(String workspaceId) executorFactory;

  /// Warning sink, forwarded to each [WorkspaceDatabase].
  final void Function(String tag, String message)? onWarn;

  /// Error sink, forwarded to each [WorkspaceDatabase].
  final void Function(String tag, String message)? onError;

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

  /// The database for [workspaceId], opening (lazily) or reusing as needed.
  ///
  /// Synchronous by design — see the class docs. Throws [ArgumentError] on an
  /// id that isn't a legal path segment, loudly, because the alternative is
  /// writing a workspace's data to a path an attacker chose.
  WorkspaceDatabase of(String workspaceId) => _resolve(workspaceId);

  WorkspaceDatabase _resolve(String workspaceId, {bool transient = false}) {
    final closing = _closing.remove(workspaceId);
    if (closing != null) {
      _reclaim(workspaceId, closing.db, closing.lease);
    }
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
    if (!isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'not a valid workspace id (must be a safe single path segment)',
      );
    }
    final lease = _WorkspaceLease(_clock);
    final watches = _LeaseStreamQueryStore();
    lease.watches = watches;
    final db = WorkspaceDatabase(
      DatabaseConnection(
        _ActivityExecutor(executorFactory(workspaceId), lease),
        streamQueries: watches,
      ),
      workspaceId: workspaceId,
      installId: _installId ?? 'unknown',
      onWarn: onWarn,
      onError: onError,
      skipIntegrityCheck: _integrityChecked.contains(workspaceId),
      onIntegrityChecked: () => _integrityChecked.add(workspaceId),
    );
    _open[workspaceId] = db;
    _leases[workspaceId] = lease;
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
          await close(workspaceId);
        }
      }
    }
  }

  /// Closes workspace files that have been idle for [idleAfter].
  ///
  /// A file is idle when nothing is watching it, no statement is in flight,
  /// and no [useTransiently] call is inside it. Live watches and open
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
      for (final id in _open.keys) {
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
        final lease = _leases.remove(id);
        _transientOnly.remove(id);
        if (db == null || lease == null) {
          continue;
        }
        _closing[id] = (db: db, lease: lease);
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
          _reclaim(id, closing.db, closing.lease);
          continue;
        }
        await closing.db.close();
      }
    } finally {
      _evicting = false;
    }
  }

  /// Puts [db] back in the open set. A second connection for the same id is
  /// left untouched.
  void _reclaim(String id, WorkspaceDatabase db, _WorkspaceLease lease) {
    final current = _open[id];
    if (current != null && !identical(current, db)) {
      return;
    }
    _open[id] = db;
    _leases[id] = lease;
    lease.touch();
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

  /// Every workspace id the server knows about, from the `global.db` registry,
  /// **including soft-deleted ones** (their directories still exist and still
  /// need sweeping/backing up).
  ///
  /// The registry, not the filesystem, is the source of truth: a stray directory
  /// nobody registered must not be silently adopted. [orphanedDatabaseFiles]
  /// reports those instead.
  Future<List<String>> allWorkspaceIds() =>
      _global.workspaceRegistryDao.allIdsIncludingDeleted();

  /// Every LIVE workspace id — what the read fan-outs use.
  ///
  /// Soft-deleted workspaces are excluded because opening their files pays a
  /// cold open to contribute rows the operator asked to stop seeing.
  Future<List<String>> liveWorkspaceIds() =>
      _global.workspaceRegistryDao.liveIds();

  /// Ids of currently-open databases.
  Iterable<String> get openIds => _open.keys;

  /// How many workspace databases are open.
  int get openCount => _open.length;

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

  /// Closes [workspaceId]'s database if open, releasing its isolate.
  Future<void> close(String workspaceId) async {
    final open = _open.remove(workspaceId);
    final closing = _closing.remove(workspaceId);
    _leases.remove(workspaceId);
    _transientOnly.remove(workspaceId);
    await open?.close();
    if (closing != null && !identical(closing.db, open)) {
      await closing.db.close();
    }
  }

  /// Closes every open workspace database. Called on server shutdown.
  Future<void> closeAll() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final dbs = <WorkspaceDatabase>[
      ..._open.values,
      for (final closing in _closing.values)
        if (!_open.values.contains(closing.db)) closing.db,
    ];
    _open.clear();
    _leases.clear();
    _closing.clear();
    _transientOnly.clear();
    for (final db in dbs) {
      await db.close();
    }
  }

  /// Closes [workspaceId] and DELETES its whole directory, then drops its
  /// pre-auth routes.
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
          break;
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

/// Recency and in-flight state for one open workspace file.
final class _WorkspaceLease {
  _WorkspaceLease(this._clock) : lastTouch = _clock();

  final DateTime Function() _clock;
  DateTime lastTouch;
  int _depth = 0;
  _LeaseStreamQueryStore? watches;

  /// True while a statement, transaction, or table watch is outstanding.
  bool get isHeld => _depth > 0 || (watches?.hasListeners ?? false);

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

      final sub = inner.listen(
        listener.add,
        onError: (Object error, StackTrace stack) {
          listener.addError(error, stack);
        },
        onDone: () {
          release();
          listener.close();
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
