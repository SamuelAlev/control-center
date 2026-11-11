import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/identity/identity_bootstrap.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;

/// Opens the REAL on-disk databases under [dataDir] — `global.db` plus each
/// workspace's `<id>/workspace.db` — for integration tests that seed a data
/// directory a server process will then boot against.
///
/// The seed and the server under test read the SAME files, so the seed has to go
/// through the same connections production uses. Close it (see
/// [SeedDatabases.close]) BEFORE spawning the server: SQLite tolerates
/// concurrent openers, but leaving a WAL writer open across the boot turns any
/// later failure into a confusing one.
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

  /// The server-global database (`global.db`): the workspace registry, identity,
  /// paired devices, the newsfeed, the fleet queue.
  final GlobalDatabase global;

  /// The per-workspace databases (`<workspaceId>/workspace.db`).
  final WorkspaceDatabaseManager workspaces;

  /// Registers [workspaceId] in the registry and materialises its database, so a
  /// booting server finds both the row and the file.
  ///
  /// [ownerUserId] records the workspace's owner; the booting server gives that
  /// user an owner membership.
  Future<void> seedWorkspace(
    String workspaceId, {
    required String name,
    String? ownerUserId,
  }) async {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion(
        id: Value(workspaceId),
        name: Value(name),
        ownerUserId: Value(ownerUserId),
      ),
    );
    await workspaces.create(workspaceId);
  }

  /// The server owner, minted and recorded the way first boot does it.
  /// Idempotent: the booting server reuses the record.
  Future<String> serverOwner() =>
      IdentityBootstrap(global: global, workspaces: workspaces).run();

  /// Closes both halves.
  Future<void> close() async {
    await workspaces.closeAll();
    await global.close();
  }
}
