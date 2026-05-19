import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';

/// Smoke entrypoint: opens the REAL databases — `global.db` plus two
/// per-workspace directories — over the pure-Dart connections, with NO Flutter.
///
/// Two things this proves that no in-memory unit test can:
///
///  * The whole schema (both halves, every table, the migration strategy, FTS5,
///    the sync triggers, `vector_init`) compiles into a Flutter-free
///    `dart build cli` native binary and runs real SQLite I/O against real
///    files. That is the foundation of the headless server.
///  * **Workspace isolation actually holds on disk.** Two workspaces get two
///    directories, a row written to one is not visible from the other and each
///    keeps its own sync sequence. An in-memory test can assert the same thing,
///    but only here is it the production storage path doing it.
///
/// Not shipped; this is the de-risk artifact. Run with
/// `fvm dart run bin/cc_persistence_smoke.dart` from `packages/cc_persistence`.
Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('cc_persistence_smoke');
  void log(String message) => stdout.writeln(message);

  // openGlobalDatabase registers the sqlite_vector extension process-globally,
  // so `vector_init` on the memory-facts + code-graph tables succeeds (no
  // onWarn) when the native code asset is bundled; it still degrades gracefully
  // if the asset is missing.
  final global = GlobalDatabase(
    openGlobalDatabase(dataDir: tmp.path),
    onWarn: (tag, msg) => stdout.writeln('[warn] $tag: $msg'),
    onError: (tag, msg) => stderr.writeln('[error] $tag: $msg'),
  );
  final workspaces = WorkspaceDatabaseManager(
    dataDir: tmp.path,
    global: global,
    onWarn: (tag, msg) => stdout.writeln('[warn] $tag: $msg'),
    onError: (tag, msg) => stderr.writeln('[error] $tag: $msg'),
  );
  await workspaces.loadInstallId();

  var failures = 0;
  void check(String what, bool ok) {
    log('${ok ? 'ok  ' : 'FAIL'}  $what');
    if (!ok) {
      failures++;
    }
  }

  // Force the global connection open + run its full onCreate.
  final registered = await global.workspaceRegistryDao.getAll();
  log(
    'global.db OK schemaVersion=${global.schemaVersion} '
    'workspaces=${registered.length}',
  );

  // Two workspaces, each with its own directory.
  for (final (id, name) in [('ws-alpha', 'Alpha'), ('ws-beta', 'Beta')]) {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion(id: Value(id), name: Value(name)),
    );
    await workspaces.create(id);
  }
  check('global.db exists', File(globalDatabasePath(tmp.path)).existsSync());
  check('ws-alpha database exists', workspaces.existsOnDisk('ws-alpha'));
  check('ws-beta database exists', workspaces.existsOnDisk('ws-beta'));

  final alpha = workspaces.of('ws-alpha');
  final beta = workspaces.of('ws-beta');

  // A repo in each. Repos are workspace-scoped, so these are independent rows
  // even though a checkout could be shared.
  await alpha.repoDao.upsertRepo(
    ReposTableCompanion(
      id: const Value('r-alpha'),
      name: const Value('acme/alpha'),
      path: Value('${tmp.path}/alpha'),
      remoteOwner: const Value('acme'),
      remoteName: const Value('alpha'),
    ),
  );
  await beta.repoDao.upsertRepo(
    ReposTableCompanion(
      id: const Value('r-beta'),
      name: const Value('acme/beta'),
      path: Value('${tmp.path}/beta'),
      remoteOwner: const Value('acme'),
      remoteName: const Value('beta'),
    ),
  );

  // The isolation assertion, on real files.
  check(
    "alpha cannot see beta's repo",
    await alpha.repoDao.getById('r-beta') == null,
  );
  check(
    "beta cannot see alpha's repo",
    await beta.repoDao.getById('r-alpha') == null,
  );
  check(
    'alpha sees exactly its own repo',
    (await alpha.repoDao.getAll()).length == 1,
  );

  // Each database identifies itself, so an exported workspace can be validated.
  final meta = await alpha.select(alpha.workspaceMetaTable).getSingle();
  check('workspace_meta names its workspace', meta.workspaceId == 'ws-alpha');
  check('workspace_meta carries the install id', meta.installId.isNotEmpty);

  // Sync triggers fire per database and the sequences are independent.
  await alpha.messagingDao.insertChannel(
    const ChannelsTableCompanion(
      id: Value('c-alpha'),
      name: Value('general'),
      workspaceId: Value('ws-alpha'),
    ),
  );
  check(
    'alpha allocated a sync seq',
    await alpha.syncDao.currentSeq('ws-alpha') > 0,
  );
  check(
    "beta's sync seq is untouched",
    await beta.syncDao.currentSeq('ws-beta') == 0,
  );

  // Fan-out reaches every registered workspace.
  final perWorkspace = await CrossWorkspaceQueries(
    workspaces,
  ).fanOut((db) => db.repoDao.getAll());
  check('fan-out visited both workspaces', perWorkspace.length == 2);

  // The pre-auth routing index resolves and a miss stays a miss.
  await global.workspaceRouteDao.put(
    WorkspaceRouteKind.inviteCode,
    'hash-123',
    'ws-beta',
  );
  check(
    'route resolves to its workspace',
    await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'hash-123',
        ) ==
        'ws-beta',
  );
  check(
    'unknown route resolves to null',
    await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'nope',
        ) ==
        null,
  );

  // Deleting a workspace is removing its directory.
  await workspaces.dropAndClose('ws-beta');
  check(
    "dropped workspace's directory is gone",
    !Directory(workspaces.dirFor('ws-beta')).existsSync(),
  );
  check(
    "dropped workspace's routes are gone",
    await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'hash-123',
        ) ==
        null,
  );

  await workspaces.closeAll();
  await global.close();
  tmp.deleteSync(recursive: true);

  if (failures > 0) {
    stderr.writeln('cc_persistence smoke FAILED ($failures checks)');
    exit(1);
  }
  log('cc_persistence smoke OK');
}
