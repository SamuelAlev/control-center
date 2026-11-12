import 'dart:io';
import 'dart:isolate';

import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Filename of the server-global database inside the data dir.
const globalDatabaseFileName = 'global.db';

/// Filename of a workspace's database inside its own directory.
const workspaceDatabaseFileName = 'workspace.db';

/// Filename of a workspace's code index inside its own directory.
///
/// Beside `workspace.db` so it is deleted with the workspace, and a file of
/// its own so snapshots and exports, which copy `workspace.db`, leave it out.
const codeIndexDatabaseFileName = 'code_index.db';

/// Directory, beside a database file, that holds the copies taken before a
/// schema upgrade.
const upgradeSnapshotDirectoryName = 'pre_upgrade';

/// How many extra connections serve reads on a workspace file.
///
/// One connection made every read wait behind every write: a snapshot, a bulk
/// delete or a backfill held up message reads in that workspace until it
/// ended. WAL lets readers proceed beside the one writer, so reads go to
/// their own connections.
const workspaceReadPoolSize = 2;

/// Opens the server-global database (`<dataDir>/global.db`), with no Flutter dependency.
///
/// This is the pure-Dart counterpart to a Flutter connection: the caller supplies an
/// explicit [dataDir] and the native `libsqlite3` is bundled by the `sqlite3` package's
/// build hook when the server is compiled with `dart build cli` — so the resulting binary
/// needs neither the Flutter engine nor a system sqlite.
/// This is the ONLY database boot opens.
/// Workspace databases open lazily, on first touch, through `WorkspaceDatabaseManager`.
///
/// The vector extension is deliberately not registered here: nothing in this
/// file is vector-indexed, and boot opens it before any workspace does.
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
    return NativeDatabase.createInBackground(
      File('${dir.path}${Platform.pathSeparator}$fileName'),
      setup: setupFileConnection,
    );
  });
}

/// Opens ONE workspace's database (`<dataDir>/<workspaceId>/workspace.db`).
///
/// Each workspace gets its own DIRECTORY, not just a file.
/// The database is the only thing in it today, but a workspace already accumulates other
/// on-disk state (worktrees, caches, exports) and giving it a folder means all of that
/// lives — and is deleted — together.
/// [workspaceId] MUST already be validated as a safe path segment — see
/// `WorkspaceDatabaseManager`, which is the only intended caller.
///
/// A missing vector extension fails the open: a required native library is
/// never something to degrade around.
QueryExecutor openWorkspaceDatabase({
  required String dataDir,
  required String workspaceId,
}) {
  return LazyDatabase(() async {
    final dir = Directory(workspaceDirPath(dataDir, workspaceId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    ensureVectorExtensionRegistered();
    return NativeDatabase.createInBackground(
      File(workspaceDatabasePath(dataDir, workspaceId)),
      setup: setupWorkspaceConnection,
      readPool: workspaceReadPoolSize,
    );
  });
}

/// Opens ONE workspace's code index (`<dataDir>/<workspaceId>/code_index.db`).
///
/// One pooled reader: the index is read by search and review and written by
/// the indexer, and a reader keeps a search from queueing behind an ingest
/// batch. [workspaceId] MUST already be validated as a safe path segment, as
/// for [openWorkspaceDatabase].
QueryExecutor openCodeIndexDatabase({
  required String dataDir,
  required String workspaceId,
}) {
  return LazyDatabase(() async {
    final dir = Directory(workspaceDirPath(dataDir, workspaceId));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    ensureVectorExtensionRegistered();
    return NativeDatabase.createInBackground(
      File(codeIndexDatabasePath(dataDir, workspaceId)),
      setup: setupCodeIndexConnection,
      readPool: 1,
    );
  });
}

/// Prepares a freshly opened file connection **before** drift runs its
/// migration, which the `beforeOpen` pragmas cannot do — they run *after*
/// `onCreate`, and never on a pooled reader.
///
/// `busy_timeout` first: everything below may need a lock another connection
/// of the pool holds for a moment.
///
/// Then, on a file nothing has built yet, `auto_vacuum`. With it, pages freed
/// by retention go back to the disk through `PRAGMA incremental_vacuum`
/// instead of sitting on the freelist forever. The mode is fixed when a
/// file's first table is created, and the vector extension creates its own
/// table the moment a connection opens, so asking is not always enough: when
/// the mode did not take, one `VACUUM` of the still-empty file applies it.
/// Only the connection that finds the file unbuilt does this. A pooled
/// reader opens after the writer built the file, and must not: setting the
/// mode takes the write lock.
///
/// WAL next, and that ordering is what keeps creating a workspace from being
/// pathological on Windows. The baseline builds several hundred schema
/// objects and, until WAL is on, every one of them is its own
/// rollback-journal transaction: create `workspace.db-journal`, sync, write,
/// sync, unlink, sync the directory. On APFS/ext4 that is sub-millisecond
/// noise; on NTFS it is hundreds of rounds of file-create/unlink metadata
/// work, each one a fresh file for the virus scanner to open, and the create
/// overran a 30s test timeout. In WAL the same statements append to one
/// already-open file.
///
/// Sent to the database isolate, so this must stay a top-level function that
/// captures nothing.
void setupFileConnection(sqlite3.Database db) {
  db.execute('PRAGMA busy_timeout = 5000');
  if (_pragma(db, 'user_version') == 0) {
    db.execute('PRAGMA auto_vacuum = 2');
    if (_pragma(db, 'auto_vacuum') != 2) {
      db.execute('VACUUM');
    }
  }
  db.execute('PRAGMA journal_mode = WAL');
  for (final pragma in connectionPragmas) {
    db.execute(pragma);
  }
}

int _pragma(sqlite3.Database db, String name) =>
    db.select('PRAGMA $name').single.values.single! as int;

/// [setupFileConnection] plus the vector context of each vector-indexed table
/// that already exists.
///
/// `vector_init` builds a per-connection, in-memory context. The writer gets
/// it again in `beforeOpen` (after a fresh file's tables exist); a pooled
/// reader runs no `beforeOpen`, so without this every KNN query that landed
/// on a reader would fail with "unable to retrieve context".
void setupWorkspaceConnection(sqlite3.Database db) {
  setupFileConnection(db);
  initVectorIndexes(db, workspaceVectorTables);
}

/// [setupFileConnection] with relaxed durability, plus the vector context of
/// `code_symbol_embeddings` once it exists.
///
/// `synchronous = OFF`: the code index is derived data. A power loss may
/// leave the file damaged, and a damaged code index is replaced by an empty
/// one that the indexer fills again; nothing a person wrote is at stake.
void setupCodeIndexConnection(sqlite3.Database db) {
  setupFileConnection(db);
  db.execute('PRAGMA synchronous = OFF');
  initVectorIndexes(db, codeIndexVectorTables);
}

/// Runs `vector_init` for each of [tables] that exists in [db].
void initVectorIndexes(sqlite3.Database db, List<String> tables) {
  for (final table in tables) {
    final exists = db.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    ).isNotEmpty;
    if (exists) {
      db.execute(vectorInitStatement(table));
    }
  }
}

/// Writes a consistent, defragmented copy of the database file at [source] to
/// [destination] with `VACUUM INTO`, on a connection of its own in a
/// background isolate.
///
/// The copy is one long read. Run on the database's serving connection it
/// would hold every statement queued behind it for seconds on a large file;
/// here it is a second WAL reader and nothing waits. [destination] must not
/// exist, and [source] must (the open never creates it).
///
/// The connection is opened read-write although it only reads: the vector
/// extension is a process-wide auto-extension that creates its own table on
/// every open, and a read-only open of a file that has not got that table
/// yet is refused.
Future<void> snapshotDatabaseFile({
  required String source,
  required String destination,
}) => Isolate.run(() {
  final db = sqlite3.sqlite3.open(source, mode: sqlite3.OpenMode.readWrite);
  try {
    db
      ..execute('PRAGMA busy_timeout = 5000')
      ..execute('VACUUM INTO ?', [destination]);
  } finally {
    db.close();
  }
});

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

/// Absolute path of [workspaceId]'s code index file.
String codeIndexDatabasePath(String dataDir, String workspaceId) =>
    '${workspaceDirPath(dataDir, workspaceId)}'
    '${Platform.pathSeparator}$codeIndexDatabaseFileName';

/// Absolute path of the server-global database file.
String globalDatabasePath(String dataDir) =>
    '$dataDir${Platform.pathSeparator}$globalDatabaseFileName';

/// Where copies of [workspaceId]'s database are written before an upgrade.
String workspaceUpgradeSnapshotDir(String dataDir, String workspaceId) =>
    '${workspaceDirPath(dataDir, workspaceId)}'
    '${Platform.pathSeparator}$upgradeSnapshotDirectoryName';

/// Where copies of the global database are written before an upgrade.
String globalUpgradeSnapshotDir(String dataDir) =>
    '$dataDir${Platform.pathSeparator}$upgradeSnapshotDirectoryName';
