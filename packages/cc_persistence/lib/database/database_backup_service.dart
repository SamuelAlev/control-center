import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// [DatabaseBackupPort] backed by SQLite `VACUUM INTO`.
///
/// A snapshot is a timestamped DIRECTORY, because persistence is a set of files:
///
/// ```
/// backups/2026-07-28T09-12-33-000Z/
///   manifest.json
///   global.db
///   <workspaceId>/workspace.db   (one directory per workspace)
/// ```
///
/// The layout mirrors the live data dir exactly, so restoring is copying the
/// snapshot's contents back over it rather than translating a second format.
///
/// Every file is written with `VACUUM INTO`, which is safe on a live WAL
/// database, so a backup never has to stop the server. A fresh directory is used
/// every time so SQLite never has to overwrite an existing target.
///
/// The manifest is what makes the set restorable: it records the schema versions
/// and per-file sizes, so a restore can tell a complete snapshot from one that
/// died halfway. Rotation of old snapshots is a separate concern (a retention
/// job / the caller); this service only produces them.
///
/// Splitting the database also made two things possible that a single file could
/// not offer, and they are the same `VACUUM INTO`: [exportWorkspace] hands out
/// one workspace as one file, and [importWorkspace] adopts such a file back.
class AppDatabaseBackupService implements DatabaseBackupPort {
  /// Creates a backup service writing into [backupsDir].
  ///
  /// [exportsDir] receives single-workspace exports (defaults to a sibling of
  /// [backupsDir]). [now] is a test seam.
  AppDatabaseBackupService({
    required GlobalDatabase global,
    required WorkspaceDatabaseManager workspaces,
    required String backupsDir,
    String? exportsDir,
    DateTime Function() now = DateTime.now,
    void Function(String message)? onWarn,
  }) : _global = global,
       _workspaces = workspaces,
       _backupsDir = backupsDir,
       _exportsDir =
           exportsDir ?? '$backupsDir${Platform.pathSeparator}exports',
       _now = now,
       _onWarn = onWarn;

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
    if (meta.workspaceId != workspaceId) {
      // Legitimate — this is how a workspace is duplicated or restored under a
      // new id — but never silent, because the alternative is a file quietly
      // serving a workspace it does not claim to be.
      _onWarn?.call(
        'importing workspace database that records workspace '
        '${meta.workspaceId} as workspace $workspaceId',
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

    // Close and drop whatever is there before copying over it: an open drift
    // connection holds the file (and its -wal), so overwriting underneath it
    // would leave the running server reading a database that no longer exists.
    await _workspaces.dropAndClose(workspaceId);
    final target = File(_workspaces.pathFor(workspaceId));
    await target.parent.create(recursive: true);
    await source.copy(target.path);

    // Force an open so beforeOpen reinstalls the FTS/sync triggers and
    // vector_init, then rebuild the FTS indexes: the imported file's content
    // tables are populated but its index may be stale or absent.
    final db = await _workspaces.create(workspaceId);
    await db.rebuildFtsIndexes();
    return workspaceId;
  }

  /// Reads `workspace_meta` straight out of [path] with a short-lived
  /// connection, so a candidate file is validated before anything is replaced.
  ///
  /// Deliberately raw sqlite rather than a drift class: this file is not (yet)
  /// one of our databases, and opening it through a schema it might not match
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
