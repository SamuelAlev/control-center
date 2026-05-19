import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

/// Filename of the server-global database inside the data dir.
const globalDatabaseFileName = 'global.db';

/// Filename of a workspace's database inside its own directory.
const workspaceDatabaseFileName = 'workspace.db';

/// Opens the server-global database (`<dataDir>/global.db`), with no Flutter
/// dependency.
///
/// This is the pure-Dart counterpart to a Flutter connection: the caller
/// supplies an explicit [dataDir] and the native `libsqlite3` is bundled by the
/// `sqlite3` package's build hook when the server is compiled with `dart build
/// cli` — so the resulting binary needs neither the Flutter engine nor a system
/// sqlite.
///
/// This is the ONLY database boot opens. Workspace databases open lazily, on
/// first touch, through `WorkspaceDatabaseManager`.
///
/// The vector-search extension (`sqlite_vector`) is registered here even though
/// `global.db` itself has no vector columns: it is a process-global SQLite
/// auto-extension, so registering it once before the first connection makes it
/// available to every workspace connection opened later. If the asset is ever
/// unavailable, `WorkspaceDatabase` still degrades gracefully — its
/// `vector_init` calls warn and skip rather than crash.
QueryExecutor openGlobalDatabase({
  required String dataDir,
  String fileName = globalDatabaseFileName,
}) {
  return LazyDatabase(() async {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    // Keep sqlite's scratch files inside the data dir.
    sqlite3.sqlite3.tempDirectory = dir.path;
    _registerVectorExtension();
    return NativeDatabase.createInBackground(
      File('${dir.path}${Platform.pathSeparator}$fileName'),
    );
  });
}

/// Opens ONE workspace's database
/// (`<dataDir>/<workspaceId>/workspace.db`).
///
/// Each workspace gets its own DIRECTORY, not just a file. The database is the
/// only thing in it today, but a workspace already accumulates other on-disk
/// state (worktrees, caches, exports) and giving it a folder means all of that
/// lives — and is deleted — together.
///
/// Returns a [LazyDatabase], so calling this is cheap and synchronous-friendly:
/// the file is not touched, the schema is not built and `beforeOpen` does not
/// run until the first query. That is what lets `WorkspaceDatabaseManager.of()`
/// stay synchronous and keep every repository's `Stream`-returning signature
/// intact.
///
/// [workspaceId] MUST already be validated as a safe path segment — see
/// `WorkspaceDatabaseManager`, which is the only intended caller.
QueryExecutor openWorkspaceDatabase({
  required String dataDir,
  required String workspaceId,
}) {
  return LazyDatabase(() async {
    final dir = Directory(workspaceDirPath(dataDir, workspaceId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _registerVectorExtension();
    return NativeDatabase.createInBackground(
      File(workspaceDatabasePath(dataDir, workspaceId)),
    );
  });
}

/// Absolute path of [workspaceId]'s own directory inside [dataDir].
///
/// Everything that belongs to one workspace and only that workspace goes here,
/// so removing the workspace is removing this directory.
String workspaceDirPath(String dataDir, String workspaceId) =>
    '$dataDir${Platform.pathSeparator}$workspaceId';

/// Absolute path of [workspaceId]'s database file.
String workspaceDatabasePath(String dataDir, String workspaceId) =>
    '${workspaceDirPath(dataDir, workspaceId)}'
    '${Platform.pathSeparator}$workspaceDatabaseFileName';

/// Absolute path of the server-global database file.
String globalDatabasePath(String dataDir) =>
    '$dataDir${Platform.pathSeparator}$globalDatabaseFileName';

/// Registers the vector-search extension as a process-global SQLite
/// auto-extension so every connection opened afterwards has
/// `vector_init`/`vector_full_scan`.
///
/// Best-effort and idempotent: a missing or broken native asset must not block
/// the database.
void _registerVectorExtension() {
  try {
    sqlite3.sqlite3.loadSqliteVectorExtension();
  } on Object {
    // Extension unavailable on this build/platform — vector search degrades.
  }
}
