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
/// ## Lifetime
///
/// Databases are cached and stay open until [close]/[closeAll] or
/// [dropAndClose]. At the scale this product targets (a solo operator with a
/// handful of workspaces) there is no eviction: a closed-and-reopened database
/// would pay `quick_check` + FTS/trigger install + `vector_init` again for
/// nothing. [openCount] is logged past [softOpenLimit] so the day that
/// assumption stops holding is visible rather than mysterious.
///
/// If it ever does stop holding, the fix is one shared `DriftIsolate` serving
/// every workspace connection instead of one background isolate per file —
/// which is why [executorFactory] is injectable rather than hard-coded.
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
  WorkspaceDatabase of(String workspaceId) {
    final cached = _open[workspaceId];
    if (cached != null) {
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
    );
    _open[workspaceId] = db;
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

  /// Every workspace id the server knows about, from the `global.db` registry,
  /// **including soft-deleted ones** (their directories still exist and still
  /// need sweeping/backing up).
  ///
  /// The registry, not the filesystem, is the source of truth: a stray directory
  /// nobody registered must not be silently adopted. [orphanedDatabaseFiles]
  /// reports those instead.
  Future<List<String>> allWorkspaceIds() =>
      _global.workspaceRegistryDao.allIdsIncludingDeleted();

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
    await db?.close();
  }

  /// Closes every open workspace database. Called on server shutdown.
  Future<void> closeAll() async {
    final dbs = _open.values.toList(growable: false);
    _open.clear();
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
  /// failed import or a registry that lost a row, and both deserve a human.
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
