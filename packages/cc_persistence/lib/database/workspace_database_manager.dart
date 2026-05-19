import 'dart:io';

import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';

/// Hands out per-workspace databases — one directory, one database, per
/// workspace (`<dataDir>/<workspaceId>/workspace.db`).
///
/// This is the seam the whole split hangs on. Every repository that touches
/// workspace-scoped data holds a manager instead of a DAO and resolves its DAO
/// per call: `_dbs.of(workspaceId).agentDao`. Because the repository methods
/// already took a required `workspaceId` (a rule this codebase enforced long
/// before the split), that resolution is mechanical and the workspace can never
/// be inferred or defaulted.
///
/// ## `of()` is synchronous, on purpose
///
/// It returns a [WorkspaceDatabase] over a `LazyDatabase`, so constructing one
/// touches no disk: the file open, schema creation and `beforeOpen` all happen
/// on the first query. Had `of()` been async, every `Stream`-returning
/// repository method in the codebase would have had to become
/// `Stream.fromFuture(...).asyncExpand(...)` — a few hundred call sites made
/// worse for no benefit. Opening is still lazy; it is just lazy one level down.
///
/// ## Lifetime: a workspace someone is USING stays open; a fan-out's is not
///
/// A database opened to serve a workspace-scoped request stays open until
/// [close]/[closeAll]/[dropAndClose] — that workspace is in use, and a
/// closed-and-reopened one would pay FTS/trigger install and `vector_init`
/// again for nothing (and its live drift `.watch()` subscriptions would die).
///
/// A database opened only to answer a CROSS-workspace question is different,
/// and is what [useTransiently] exists for. The first all-workspace read used
/// to open every workspace file — including soft-deleted ones — and leave them
/// all resident for the process's lifetime, each holding a background isolate
/// and an 8 MB page cache, so one dashboard load made a ten-workspace install
/// pay ten cold opens and keep ten connections for a list it rendered once.
/// [useTransiently] closes the file afterwards **if this call is what opened
/// it and nothing else has claimed it since** — so a workspace a person is
/// actually in is never closed out from under them, and the sweep that merely
/// visited it does not pin it.
///
/// The integrity check is the reason that would otherwise be a bad trade:
/// `quick_check` is 2.8s on a large file and it ran on EVERY open, so
/// close-and-reopen would turn a dashboard refresh into a multi-second stall.
/// It is a statement about the FILE, not about the connection, so it now runs
/// once per file per process ([_integrityChecked]) and a reopen skips it.
///
/// [openCount] is logged past [softOpenLimit] so the day the "handful of
/// workspaces" assumption stops holding is visible rather than mysterious. If
/// it does, the next step is one shared `DriftIsolate` serving every workspace
/// connection instead of one background isolate per file — which is why
/// [executorFactory] is injectable rather than hard-coded.
class WorkspaceDatabaseManager {
  /// Creates a manager rooted at [dataDir].
  ///
  /// [global] supplies the install id stamped into each new workspace database
  /// and is the registry consulted by [allWorkspaceIds]. [executorFactory] defaults
  /// to [openWorkspaceDatabase] and exists so tests can hand out in-memory
  /// executors (and so a future shared-isolate strategy is a one-line swap).
  WorkspaceDatabaseManager({
    required String dataDir,
    required GlobalDatabase global,
    QueryExecutor Function(String workspaceId)? executorFactory,
    this.onWarn,
    this.onError,
  }) : _dataDir = dataDir,
       _global = global,
       executorFactory =
           executorFactory ??
           ((workspaceId) => openWorkspaceDatabase(
             dataDir: dataDir,
             workspaceId: workspaceId,
           ));

  final String _dataDir;
  final GlobalDatabase _global;
  final Map<String, WorkspaceDatabase> _open = {};
  String? _installId;

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
    final cached = _open[workspaceId];
    if (cached != null) {
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
    final db = WorkspaceDatabase(
      executorFactory(workspaceId),
      workspaceId: workspaceId,
      installId: _installId ?? 'unknown',
      onWarn: onWarn,
      onError: onError,
      skipIntegrityCheck: _integrityChecked.contains(workspaceId),
      onIntegrityChecked: () => _integrityChecked.add(workspaceId),
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
    final db = _open.remove(workspaceId);
    _transientOnly.remove(workspaceId);
    await db?.close();
  }

  /// Closes every open workspace database. Called on server shutdown.
  Future<void> closeAll() async {
    final dbs = _open.values.toList(growable: false);
    _open.clear();
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
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException catch (e) {
        onWarn?.call(
          'WorkspaceDatabaseManager',
          'could not delete ${dir.path}: $e',
        );
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
