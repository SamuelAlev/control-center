import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds an in-memory [WorkspaceDatabase] for cc_server_core tests — one
/// workspace's data (agents, spaces, tickets, memory, pipelines, repos, the
/// code graph).
///
/// Mirrors cc_persistence's test helper: points SQLite's temp directory at the
/// system temp dir and skips the `sqlite_vector` extension (vector search is
/// unavailable in tests, which never exercise it).
WorkspaceDatabase createTestDatabase({String workspaceId = 'test-workspace'}) {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  return WorkspaceDatabase.forTesting(
    NativeDatabase.memory(),
    workspaceId: workspaceId,
  );
}

/// Builds an in-memory [GlobalDatabase] — the server-wide half (workspace
/// registry, users, preferences, paired devices, newsfeed, fleet queue).
GlobalDatabase createTestGlobalDatabase() {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  return GlobalDatabase.forTesting(NativeDatabase.memory());
}

/// Builds a [WorkspaceDatabaseManager] handing out IN-MEMORY workspace
/// databases — what almost every service and repository takes now.
///
/// Each workspace gets an independent database, which is the production shape: a
/// write in one is invisible from the other. Register the workspaces the code
/// under test will touch with [seedTestWorkspace], because fan-out reads the
/// registry rather than the set of databases handed out so far.
WorkspaceDatabaseManager createTestWorkspaceDatabases({
  GlobalDatabase? global,
}) {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  // Holding several `WorkspaceDatabase` instances at once is the whole point of
  // the manager, so drift's duplicate-instance warning is pure noise here: it
  // warns about two databases sharing ONE executor and every workspace gets its
  // own. Left on, it buries real failures under a stack trace per workspace.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return WorkspaceDatabaseManager(
    dataDir: Directory.systemTemp.path,
    global: global ?? createTestGlobalDatabase(),
    executorFactory: (_) => NativeDatabase.memory(),
  );
}

/// Registers [workspaceId] in [global]'s registry and materialises its database.
Future<void> seedTestWorkspace(
  GlobalDatabase global,
  WorkspaceDatabaseManager workspaces,
  String workspaceId, {
  String name = 'Test workspace',
}) async {
  await global.workspaceRegistryDao.upsertWorkspace(
    WorkspacesTableCompanion(
      id: Value(workspaceId),
      name: Value(name),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  );
  await workspaces.create(workspaceId);
}

/// Opens the REAL on-disk databases under [dataDir] — `global.db` plus the
/// per-workspace files — for tests that seed a data directory a server will then
/// boot against.
///
/// Distinct from the in-memory helpers above: the point here is that the seed and
/// the server under test read the SAME files, so the seed has to go through the
/// same connections production uses.
///
/// The caller owns closing both halves and must do so before booting the server
/// (SQLite tolerates concurrent openers, but leaving a WAL writer open across the
/// boot makes failures confusing to read).
SeedDatabases openSeedDatabases(String dataDir) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final global = GlobalDatabase(openGlobalDatabase(dataDir: dataDir));
  return SeedDatabases(
    global: global,
    workspaces: WorkspaceDatabaseManager(dataDir: dataDir, global: global),
  );
}

/// Both halves of an on-disk data directory, opened for seeding.
class SeedDatabases {
  /// Wraps [global] and [workspaces].
  const SeedDatabases({required this.global, required this.workspaces});

  /// The server-global database (`global.db`).
  final GlobalDatabase global;

  /// The per-workspace databases under `workspaces/`.
  final WorkspaceDatabaseManager workspaces;

  /// Closes both halves. Call before booting a server against the same data
  /// directory, so the boot is not racing a WAL writer the test still holds.
  Future<void> close() async {
    await workspaces.closeAll();
    await global.close();
  }
}
