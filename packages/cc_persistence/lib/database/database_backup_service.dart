import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// [DatabaseBackupPort] via SQLite `VACUUM INTO`.
///
/// Snapshot is a timestamped directory mirroring the live data dir
/// (`manifest.json`, `global.db`, `<workspaceId>/workspace.db`). Safe on live
/// WAL; fresh dir each time. Manifest records schema versions/sizes.
/// [exportWorkspace]/[importWorkspace] are single-file VACUUM INTO.
class AppDatabaseBackupService implements DatabaseBackupPort {
  /// Creates a backup service writing into [backupsDir].
  ///
  /// [exportsDir] receives single-workspace exports (defaults to a sibling of
  /// [backupsDir]). [_now] is a test seam.
  AppDatabaseBackupService({
    required this._global,
    required this._workspaces,
    required String backupsDir,
    String? exportsDir,
    this._now = DateTime.now,
    this._onWarn,
  }) : _backupsDir = backupsDir,
       _exportsDir =
           exportsDir ?? '$backupsDir${Platform.pathSeparator}exports';

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _workspaces;
  final String _backupsDir;
  final String _exportsDir;
  final DateTime Function() _now;
  final void Function(String message)? _onWarn;

  /// Filename of the manifest inside a snapshot directory.
  static const manifestFileName = 'manifest.json';

  /// Schema version recorded for the per-workspace files in the manifest.
  ///
  /// Read from a live workspace database when the snapshot contains one, so it
  /// cannot drift from the class; the fallback covers a snapshot of an install
  /// whose workspaces have never been touched.
  int get _workspaceSchemaVersion {
    // CROSS-WORKSPACE BY DESIGN: the manifest records ONE schema version for
    // the whole snapshot, and every workspace file in an install shares it, so
    // any already-open workspace answers the question. Not routed through
    // CrossWorkspaceQueries because that helper opens every workspace to run a
    // read, and this needs no read at all — only a version number off a
    // database the process already holds.
    final open = _workspaces.openIds;
    return open.isEmpty ? 1 : _workspaces.of(open.first).schemaVersion;
  }

  @override
  Future<String> backupNow() async {
    final dir = Directory(
      '$_backupsDir${Platform.pathSeparator}${_timestamp()}',
    );
    await dir.create(recursive: true);

    final globalPath = '${dir.path}${Platform.pathSeparator}global.db';
    await _global.backupTo(globalPath);

    final entries = <Map<String, Object?>>[];
    final skipped = <String>[];
    // CROSS-WORKSPACE BY DESIGN: a backup is the snapshot of an INSTALL, so it
    // covers every workspace by definition. Enumerated directly rather than via
    // CrossWorkspaceQueries because the unit of work here is a FILE
    // (`VACUUM INTO` per database), not a query to fan out — the helper's
    // signatures all hand you an open `WorkspaceDatabase` to read from.
    for (final id in await _workspaces.allWorkspaceIds()) {
      if (!_workspaces.existsOnDisk(id)) {
        // A registered workspace that was never touched has no file yet. Record
        // it as skipped rather than failing the whole backup, so the manifest
        // still says what was and wasn't captured.
        skipped.add(id);
        continue;
      }
      final wsDir = Directory('${dir.path}${Platform.pathSeparator}$id');
      await wsDir.create(recursive: true);
      final path =
          '${wsDir.path}${Platform.pathSeparator}$workspaceDatabaseFileName';
      try {
        await _workspaces.of(id).backupTo(path);
        entries.add({
          'workspace_id': id,
          'file': '$id/$workspaceDatabaseFileName',
          'bytes': File(path).lengthSync(),
        });
      } on Object catch (e) {
        skipped.add(id);
        _onWarn?.call('backup of workspace $id failed: $e');
      }
    }
    if (skipped.isNotEmpty) {
      _onWarn?.call(
        'backup skipped ${skipped.length} workspace(s): ${skipped.join(', ')}',
      );
    }

    final manifest = <String, Object?>{
      'version': 1,
      'created_at': _now().toUtc().toIso8601String(),
      'global': {
        'file': 'global.db',
        'schema_version': _global.schemaVersion,
        'bytes': File(globalPath).lengthSync(),
      },
      'workspace_schema_version': _workspaceSchemaVersion,
      'workspaces': entries,
      'skipped_workspaces': skipped,
    };
    await File(
      '${dir.path}${Platform.pathSeparator}$manifestFileName',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
    return dir.path;
  }

  @override
  Future<List<BackupSnapshot>> listBackups() async {
    final root = Directory(_backupsDir);
    if (!root.existsSync()) {
      return const [];
    }
    final snapshots = <BackupSnapshot>[];
    for (final entity in root.listSync(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final name = entity.path.split(Platform.pathSeparator).last;
      // The exports lane lives under the backups directory by default. It is a
      // pile of single-workspace files, not a snapshot, and listing it as one
      // would report an install as having backups it does not have. A snapshot
      // directory is always a timestamp, so the name check cannot collide.
      if (entity.path == _exportsDir || name == 'exports') {
        continue;
      }
      snapshots.add(_readSnapshot(entity, name));
    }
    // The directory name IS the UTC timestamp, fixed-width and zero-padded, so
    // a reverse lexicographic sort is chronological — and it still orders a
    // snapshot whose manifest could not be read, which a `createdAt` sort
    // would strand at one end.
    snapshots.sort((a, b) => b.name.compareTo(a.name));
    return snapshots;
  }

  /// Reads one snapshot directory, tolerating every way it can be broken.
  ///
  /// Nothing here throws: an unreadable snapshot is reported as incomplete,
  /// because the operator's question is "what do I have?" and a listing that
  /// fails on the first damaged entry answers it for nobody.
  BackupSnapshot _readSnapshot(Directory dir, String name) {
    final sep = Platform.pathSeparator;
    final manifest = _readManifest(File('${dir.path}$sep$manifestFileName'));
    final skipped = manifest?['skipped_workspaces'];
    final entries = manifest?['workspaces'];
    var complete =
        manifest != null &&
        skipped is List &&
        skipped.isEmpty &&
        entries is List;

    final workspaces = <BackupSnapshotWorkspace>[];
    if (manifest != null) {
      for (final entry in entries is List ? entries : const []) {
        if (entry is! Map) {
          complete = false;
          continue;
        }
        final id = entry['workspace_id'];
        final relative = entry['file'];
        if (id is! String || relative is! String) {
          complete = false;
          continue;
        }
        final file = File('${dir.path}$sep${relative.replaceAll('/', sep)}');
        if (!file.existsSync()) {
          // Missing entry: exclude it from the individually restorable set.
          complete = false;
          continue;
        }
        final bytes = file.lengthSync();
        if (bytes == 0 || entry['bytes'] != bytes) {
          complete = false;
        }
        workspaces.add(
          BackupSnapshotWorkspace(
            workspaceId: id,
            path: file.path,
            bytes: bytes,
          ),
        );
      }
      final globalEntry = manifest['global'];
      final globalFile = globalEntry is Map ? globalEntry['file'] : null;
      final global = File('${dir.path}${sep}global.db');
      if (globalFile != 'global.db' ||
          !global.existsSync() ||
          global.lengthSync() == 0 ||
          globalEntry is! Map ||
          globalEntry['bytes'] != global.lengthSync()) {
        complete = false;
      }
    } else {
      // No readable manifest. The per-workspace files are still adoptable one
      // by one, so recover what the layout itself says rather than reporting
      // an empty snapshot.
      for (final child in dir.listSync(followLinks: false)) {
        if (child is! Directory) {
          continue;
        }
        final file = File('${child.path}$sep$workspaceDatabaseFileName');
        if (!file.existsSync()) {
          continue;
        }
        workspaces.add(
          BackupSnapshotWorkspace(
            workspaceId: child.path.split(sep).last,
            path: file.path,
            bytes: file.lengthSync(),
          ),
        );
      }
    }

    return BackupSnapshot(
      path: dir.path,
      name: name,
      createdAt: manifest == null
          ? null
          : DateTime.tryParse(
              manifest['created_at'] is String
                  ? manifest['created_at'] as String
                  : '',
            ),
      bytes: _directoryBytes(dir),
      workspaces: workspaces,
      skippedWorkspaceIds: [
        for (final id in skipped is List ? skipped : const [])
          if (id is String) id,
      ],
      complete: complete,
    );
  }

  /// The snapshot's manifest, or null when it is absent or not JSON we know.
  Map<String, Object?>? _readManifest(File file) {
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, Object?> ? decoded : null;
    } on Object {
      return null;
    }
  }

  /// Bytes on disk under [dir], which is what an operator deciding whether to
  /// keep a snapshot is actually asking about — not the manifest's own sum,
  /// which describes the files it MEANT to write.
  int _directoryBytes(Directory dir) {
    var total = 0;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += entity.lengthSync();
        } on Object {
          // A file that vanished mid-walk contributes nothing; a size is not
          // worth failing a listing over.
        }
      }
    }
    return total;
  }

  @override
  Future<String> exportWorkspace(String workspaceId) async {
    if (!WorkspaceDatabaseManager.isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'invalid');
    }
    if (!_workspaces.existsOnDisk(workspaceId)) {
      throw StateError(
        'workspace $workspaceId has no database file to export '
        '(it has never been written to)',
      );
    }
    final dir = Directory(_exportsDir);
    await dir.create(recursive: true);
    final path =
        '${dir.path}${Platform.pathSeparator}'
        '$workspaceId-${_timestamp()}.db';
    await _workspaces.of(workspaceId).backupTo(path);
    return path;
  }

  @override
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
  }) async {
    if (!WorkspaceDatabaseManager.isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'invalid');
    }
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'no such file');
    }
    final meta = _readWorkspaceMeta(sourcePath);
    if (meta == null) {
      throw ArgumentError.value(
        sourcePath,
        'sourcePath',
        'not a Control Center workspace database (no workspace_meta row)',
      );
    }
    final ourInstall = await _global.workspaceRouteDao.meta(
      GlobalDatabase.installIdKey,
    );
    if (ourInstall != null && meta.installId != ourInstall) {
      _onWarn?.call(
        'importing workspace database from another install '
        '(${meta.installId}); its paired devices and user ids belong to that '
        'install and will not resolve here',
      );
    }

    // Snapshot before touching the live directory. A byte copy of a WAL
    // database loses uncheckpointed writes; VACUUM INTO incorporates them.
    final staging = await Directory.systemTemp.createTemp('cc-import-');
    try {
      final stagedPath = '${staging.path}${Platform.pathSeparator}workspace.db';
      sqlite.Database? snapshot;
      try {
        snapshot = sqlite.sqlite3.open(
          sourcePath,
          mode: sqlite.OpenMode.readOnly,
        );
        snapshot.execute('VACUUM INTO ?', [stagedPath]);
      } finally {
        snapshot?.close();
      }
      if (meta.workspaceId != workspaceId) {
        _rekeyWorkspace(stagedPath, meta.workspaceId, workspaceId);
        _onWarn?.call(
          'importing workspace database that records workspace '
          '${meta.workspaceId} as workspace $workspaceId',
        );
      }
      final routes = _routesInSnapshot(stagedPath);
      for (final route in routes) {
        final owner = await _global.workspaceRouteDao.resolve(
          route.kind,
          route.key,
        );
        if (owner != null && owner != workspaceId) {
          throw StateError(
            'cannot import workspace $workspaceId: ${route.kind.wireName} '
            '${route.key} already belongs to $owner',
          );
        }
      }
      await _adoptWorkspace(workspaceId, stagedPath, routes);
      return workspaceId;
    } finally {
      await staging.delete(recursive: true);
    }
  }

  Future<void> _adoptWorkspace(
    String workspaceId,
    String stagedPath,
    List<({WorkspaceRouteKind kind, String key})> routes,
  ) async {
    // dropAndClose must fail before copy if even one WAL sidecar survives.
    await _workspaces.dropAndClose(workspaceId);
    final target = File(_workspaces.pathFor(workspaceId));
    await target.parent.create(recursive: true);
    await File(stagedPath).copy(target.path);

    // Reinstall triggers and rebuild FTS before making pre-auth keys visible.
    final db = await _workspaces.create(workspaceId);
    await db.rebuildFtsIndexes();
    await _global.transaction(() async {
      for (final route in routes) {
        await _global.workspaceRouteDao.put(route.kind, route.key, workspaceId);
      }
    });
  }

  /// The route keys written by repositories for rows in this workspace file.
  /// Include the reserved space/isolated-repo kinds, not just today's inbound
  /// invite, webhook, ticket and run readers.
  List<({WorkspaceRouteKind kind, String key})> _routesInSnapshot(String path) {
    final db = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      final routes = <({WorkspaceRouteKind kind, String key})>[];
      void add(WorkspaceRouteKind kind, String sql) {
        for (final row in db.select(sql)) {
          routes.add((kind: kind, key: row.values.first! as String));
        }
      }

      add(
        WorkspaceRouteKind.inviteCode,
        'SELECT code_hash FROM workspace_invites '
        'WHERE used_at IS NULL AND revoked_at IS NULL',
      );
      add(
        WorkspaceRouteKind.webhookToken,
        "SELECT webhook_token FROM pipeline_triggers "
        "WHERE webhook_token IS NOT NULL AND webhook_token <> ''",
      );
      add(WorkspaceRouteKind.pipelineRun, 'SELECT id FROM pipeline_runs');
      add(WorkspaceRouteKind.space, 'SELECT id FROM spaces');
      add(
        WorkspaceRouteKind.ticketExternalKey,
        "SELECT provider || ':' || external_key FROM tickets "
        'WHERE external_key IS NOT NULL',
      );
      add(WorkspaceRouteKind.isolatedRepo, 'SELECT id FROM isolated_repos');
      return routes;
    } finally {
      db.close();
    }
  }

  /// A cloned snapshot must identify its new workspace in every scoped row.
  /// Update only the staging file; the exported source is never modified.
  void _rekeyWorkspace(String path, String oldId, String newId) {
    final db = sqlite.sqlite3.open(path);
    try {
      db.execute('PRAGMA foreign_keys = OFF');
      db.execute('BEGIN IMMEDIATE');
      try {
        // Reinstalled on open; avoid populating a bogus change feed while
        // rewriting historical rows to their new workspace identity.
        final syncTriggers = db.select(
          "SELECT name FROM sqlite_master WHERE type = 'trigger' "
          "AND name LIKE 'trg_sync_%'",
        );
        for (final row in syncTriggers) {
          final name = (row['name'] as String).replaceAll('"', '""');
          db.execute('DROP TRIGGER "$name"');
        }
        for (final row in db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' AND sql NOT LIKE 'CREATE VIRTUAL TABLE%'",
        )) {
          final name = (row['name'] as String).replaceAll('"', '""');
          if (db
              .select('PRAGMA table_info("$name")')
              .any((column) => column['name'] == 'workspace_id')) {
            db.execute(
              'UPDATE "$name" SET workspace_id = ? WHERE workspace_id = ?',
              [newId, oldId],
            );
          }
        }
        db.execute('COMMIT');
      } on Object {
        db.execute('ROLLBACK');
        rethrow;
      }
      // A WAL-mode source can leave staged writes in its own sidecar; the
      // target receives only workspace.db, so checkpoint before copying it.
      db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } finally {
      db.close();
    }
  }

  /// Reads `workspace_meta` straight out of [path] with a short-lived
  /// connection, so a candidate file is validated before anything is replaced.
  ///
  /// Deliberately raw sqlite rather than a drift class: this file is not (yet)
  /// one of our databases and opening it through a schema it might not match
  /// would fail in ways that say nothing useful. Read-only, so a malformed
  /// candidate cannot be modified by being inspected.
  _ImportedMeta? _readWorkspaceMeta(String path) {
    sqlite.Database? probe;
    try {
      probe = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
      final rows = probe.select(
        'SELECT workspace_id, install_id FROM workspace_meta LIMIT 1',
      );
      if (rows.isEmpty) {
        return null;
      }
      return _ImportedMeta(
        workspaceId: rows.first['workspace_id'] as String,
        installId: rows.first['install_id'] as String? ?? 'unknown',
      );
    } on Object {
      return null;
    } finally {
      probe?.close();
    }
  }

  /// Filesystem-safe UTC timestamp (no ':' or '.' — invalid on Windows).
  String _timestamp() => _now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
}

class _ImportedMeta {
  const _ImportedMeta({required this.workspaceId, required this.installId});
  final String workspaceId;
  final String installId;
}
