import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Builds an in-memory [WorkspaceDatabase] for tests — one workspace's data.
///
/// Most tests want this one: it is where agents, channels, tickets, memory,
/// pipelines, repos and the code graph live. [workspaceId] is the id the file
/// claims, and the value to pass to any DAO or repository method that still
/// takes one.
///
/// Mirrors the headless server's `openWorkspaceDatabase`, except this helper
/// itself does not register `sqlite_vector`. `beforeOpen`'s vector-index setup
/// degrades gracefully without it. A sibling test that calls
/// `openGlobalDatabase` may still have registered the extension as a
/// process-global SQLite auto-extension, in which case vector functions are
/// present on this connection too. Points SQLite's temp directory at the system
/// temp dir for scratch files.
///
/// Always construct test databases through these helpers rather than calling
/// `WorkspaceDatabase.forTesting(NativeDatabase.memory())` directly, so the
/// native setup stays in one place.
WorkspaceDatabase createTestDatabase({String workspaceId = 'test-workspace'}) {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  return WorkspaceDatabase.forTesting(
    NativeDatabase.memory(),
    workspaceId: workspaceId,
  );
}

/// Builds an in-memory [GlobalDatabase] for tests — the server-wide half.
///
/// Use this for the workspace registry, users/preferences/paired devices, the
/// newsfeed and the fleet queue. Everything else is in [createTestDatabase].
GlobalDatabase createTestGlobalDatabase() {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  return GlobalDatabase.forTesting(NativeDatabase.memory());
}

/// Builds a [WorkspaceDatabaseManager] handing out IN-MEMORY workspace
/// databases, for tests that exercise code taking the manager (every repository
/// does) or that need two workspaces to prove isolation.
///
/// Each workspace gets its own independent in-memory database, which is exactly
/// the production shape: a write in one is invisible to the other, so an
/// isolation test that passes here would also pass on disk.
///
/// [global] defaults to a fresh in-memory global database. Register any
/// workspace the code under test will touch with [seedTestWorkspace] —
/// `allWorkspaceIds()`, and therefore every `CrossWorkspaceQueries` fan-out,
/// reads the registry rather than the set of databases handed out so far.
WorkspaceDatabaseManager createTestWorkspaceDatabases({
  GlobalDatabase? global,
}) {
  sqlite3.sqlite3.tempDirectory = Directory.systemTemp.path;
  // Holding several `WorkspaceDatabase` instances at once is the whole point of
  // the manager, so drift's duplicate-instance warning is pure noise here: it
  // warns about two databases sharing ONE executor, and every workspace gets its
  // own. Left on, it buries real failures under a stack trace per workspace.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return WorkspaceDatabaseManager(
    dataDir: Directory.systemTemp.path,
    global: global ?? createTestGlobalDatabase(),
    executorFactory: (_) => NativeDatabase.memory(),
  );
}

/// Registers [workspaceId] in [global]'s registry and materialises its database,
/// so fan-out and any registry lookup can see it.
///
/// Tests that only touch one workspace's tables can skip this; tests that go
/// through a repository holding the manager, or that exercise cross-workspace
/// reads, need it.
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
