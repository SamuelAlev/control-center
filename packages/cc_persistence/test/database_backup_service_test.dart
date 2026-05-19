@TestOn('!windows')
library;

// POSIX-only: the real-file backup flow (drift open/close/reopen of
// workspace files + VACUUM INTO) hangs on the Windows CI runner's
// first DB query (30s test timeout, then 'Can't re-open a database
// after closing it' from teardown). Needs on-machine debugging; the
// in-memory executor suites still cover the schema on Windows.

import 'dart:convert';
import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// [AppDatabaseBackupService] backs the `server.backupNow` RPC op.
///
/// Splitting the database changed what a backup IS: persistence is now a set of
/// files, so a snapshot is a timestamped DIRECTORY holding `global.db`, one
/// `<id>/workspace.db` per workspace and a `manifest.json` that says what was
/// captured. The manifest is the part that matters most — without it a restore
/// cannot tell a complete snapshot from one that died halfway.
///
/// The split also bought two operations a single file could not offer and both
/// are the same `VACUUM INTO`: exporting one workspace as one file and adopting
/// such a file back.
void main() {
  // A snapshot legitimately holds several WorkspaceDatabase instances at once
  // (the live ones plus the reopened copies); drift's duplicate-instance warning
  // is about sharing ONE executor, which never happens here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager workspaces;
  final warnings = <String>[];

  /// Fixed clock so snapshot directory names are assertable.
  var now = DateTime.utc(2026, 7, 5, 12, 34, 56);

  AppDatabaseBackupService service({String? backupsDir, String? exportsDir}) =>
      AppDatabaseBackupService(
        global: global,
        workspaces: workspaces,
        backupsDir: backupsDir ?? '${tmp.path}/backups',
        exportsDir: exportsDir,
        now: () => now,
        onWarn: warnings.add,
      );

  Future<void> seedWorkspace(String id, {required String agentName}) async {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: id, name: 'WS $id'),
    );
    final db = await workspaces.create(id);
    await db.agentDao.upsert(
      AgentsTableCompanion.insert(
        id: 'a-$id',
        name: agentName,
        title: 't',
        agentMdPath: '/a.md',
        workspaceId: id,
        skills: '',
      ),
    );
  }

  setUp(() async {
    warnings.clear();
    now = DateTime.utc(2026, 7, 5, 12, 34, 56);
    tmp = Directory.systemTemp.createTempSync('db_backup_service');
    global = GlobalDatabase(NativeDatabase(File('${tmp.path}/global.db')));
    // In-process executor, not the default createInBackground isolate: the
    // per-database background isolate handshake is unreliable on the Windows
    // CI runner (first query hangs → 30s test timeout), and nothing under
    // test here is executor-specific — the files, VACUUM INTO and the
    // manifest are identical either way.
    workspaces = WorkspaceDatabaseManager(
      dataDir: tmp.path,
      global: global,
      executorFactory: (id) =>
          NativeDatabase(File(workspaceDatabasePath(tmp.path, id))),
    );
    await workspaces.loadInstallId();
  });

  tearDown(() async {
    await workspaces.closeAll();
    await global.close();
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  group('backupNow', () {
    test('writes a snapshot directory holding every database file', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      await seedWorkspace('ws2', agentName: 'Grace');

      final path = await service().backupNow();

      // A timestamped directory with a filesystem-safe name (no ':' or '.').
      expect(Directory(path).existsSync(), isTrue);
      expect(path, contains('2026-07-05T12-34-56'));
      expect(path.split(Platform.pathSeparator).last, isNot(contains(':')));
      expect(File('$path/global.db').existsSync(), isTrue);
      expect(File('$path/ws1/workspace.db').existsSync(), isTrue);
      expect(File('$path/ws2/workspace.db').existsSync(), isTrue);
      expect(
        File('$path/${AppDatabaseBackupService.manifestFileName}').existsSync(),
        isTrue,
      );
    });

    test(
      'the manifest records the schema versions and every captured file',
      () async {
        await seedWorkspace('ws1', agentName: 'Ada');

        final path = await service().backupNow();
        final manifest =
            jsonDecode(
                  File(
                    '$path/${AppDatabaseBackupService.manifestFileName}',
                  ).readAsStringSync(),
                )
                as Map<String, Object?>;

        expect(manifest['version'], 1);
        expect(manifest['created_at'], '2026-07-05T12:34:56.000Z');
        final globalEntry = manifest['global']! as Map<String, Object?>;
        expect(globalEntry['file'], 'global.db');
        expect(globalEntry['schema_version'], global.schemaVersion);
        expect(globalEntry['bytes'], greaterThan(0));

        final entries = (manifest['workspaces']! as List<Object?>)
            .cast<Map<String, Object?>>();
        expect(entries, hasLength(1));
        expect(entries.single['workspace_id'], 'ws1');
        expect(entries.single['file'], 'ws1/workspace.db');
        expect(
          entries.single['bytes'],
          greaterThan(0),
          reason: 'a zero-byte entry is how a half-written snapshot is spotted',
        );
        expect(manifest['skipped_workspaces'], isEmpty);
      },
    );

    test(
      'a registered workspace with no file yet is skipped, not fatal',
      () async {
        await seedWorkspace('ws1', agentName: 'Ada');
        // Registered but never written to, so no file exists.
        await global.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion.insert(id: 'untouched', name: 'Untouched'),
        );

        final path = await service().backupNow();
        final manifest =
            jsonDecode(
                  File(
                    '$path/${AppDatabaseBackupService.manifestFileName}',
                  ).readAsStringSync(),
                )
                as Map<String, Object?>;

        expect(manifest['skipped_workspaces'], <String>['untouched']);
        expect(manifest['workspaces']! as List<Object?>, hasLength(1));
        expect(
          warnings.any((w) => w.contains('untouched')),
          isTrue,
          reason: 'what a backup did NOT capture must be visible, not implicit',
        );
      },
    );

    test('the snapshot is a real, independent, reopenable database', () async {
      await seedWorkspace('ws1', agentName: 'Ada');

      final path = await service().backupNow();
      await workspaces.closeAll();
      await global.close();

      final restoredGlobal = GlobalDatabase(
        NativeDatabase(File('$path/global.db')),
      );
      addTearDown(restoredGlobal.close);
      final ws = await restoredGlobal.workspaceRegistryDao.getById('ws1');
      expect(ws, isNotNull);
      expect(ws!.name, 'WS ws1');

      final restoredWorkspace = WorkspaceDatabase(
        NativeDatabase(File('$path/ws1/workspace.db')),
        workspaceId: 'ws1',
      );
      addTearDown(restoredWorkspace.close);
      final agents = await restoredWorkspace.agentDao.getAll();
      expect(agents.map((a) => a.name), <String>['Ada']);
    });

    test('two backups produce two distinct snapshot directories', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final svc = service();

      final first = await svc.backupNow();
      now = now.add(const Duration(seconds: 1));
      final second = await svc.backupNow();

      expect(first, isNot(second));
      expect(Directory(first).existsSync(), isTrue);
      expect(Directory(second).existsSync(), isTrue);
    });
  });

  group('listBackups', () {
    test('reports nothing before a backup has ever been taken', () async {
      expect(await service().listBackups(), isEmpty);
    });

    test('describes each snapshot, newest first', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      await seedWorkspace('ws2', agentName: 'Grace');
      final svc = service();

      final older = await svc.backupNow();
      now = now.add(const Duration(minutes: 5));
      final newer = await svc.backupNow();

      final listed = await svc.listBackups();

      expect(listed.map((s) => s.path), [newer, older]);
      final first = listed.first;
      expect(first.complete, isTrue);
      expect(first.createdAt, DateTime.utc(2026, 7, 5, 12, 39, 56));
      expect(first.bytes, greaterThan(0));
      expect(
        first.workspaces.map((w) => w.workspaceId).toList()..sort(),
        <String>['ws1', 'ws2'],
      );
      // The per-workspace path is what `importWorkspace` takes back — that is
      // what makes restoring a workspace the existing import op.
      final ws1 = first.workspaces.firstWhere((w) => w.workspaceId == 'ws1');
      expect(File(ws1.path).existsSync(), isTrue);
      expect(ws1.bytes, greaterThan(0));
    });

    test('the exports lane is never reported as a snapshot', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final svc = service();
      await svc.backupNow();
      // Exports default to a directory INSIDE the backups directory, so a
      // listing that walked children blindly would count a pile of exported
      // files as a backup nobody took.
      await svc.exportWorkspace('ws1');

      final listed = await svc.listBackups();

      expect(listed, hasLength(1));
      expect(listed.single.path.endsWith('exports'), isFalse);
    });

    test('a snapshot whose manifest is gone is listed as incomplete', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final svc = service();
      final path = await svc.backupNow();
      File('$path/${AppDatabaseBackupService.manifestFileName}').deleteSync();

      final listed = await svc.listBackups();

      expect(listed, hasLength(1));
      final snapshot = listed.single;
      expect(snapshot.complete, isFalse);
      expect(snapshot.createdAt, isNull);
      // Still restorable one workspace at a time — the layout says what the
      // manifest no longer can, and hiding it is how an operator comes to
      // believe they have no backup when they have most of one.
      expect(snapshot.workspaces.map((w) => w.workspaceId), <String>['ws1']);
    });

    test('a snapshot missing a file the manifest names is incomplete', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      await seedWorkspace('ws2', agentName: 'Grace');
      final svc = service();
      final path = await svc.backupNow();
      File('$path/ws2/workspace.db').deleteSync();

      final snapshot = (await svc.listBackups()).single;

      expect(snapshot.complete, isFalse);
      expect(snapshot.workspaces.map((w) => w.workspaceId), <String>['ws1']);
    });

    test('records the workspaces the backup could not capture', () async {
      // Registered but never written to, so it has no file — `backupNow`
      // records it as skipped rather than failing the whole snapshot.
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-empty', name: 'Empty'),
      );
      await seedWorkspace('ws1', agentName: 'Ada');
      final svc = service();
      await svc.backupNow();

      final snapshot = (await svc.listBackups()).single;

      expect(snapshot.skippedWorkspaceIds, <String>['ws-empty']);
      expect(snapshot.workspaces.map((w) => w.workspaceId), <String>['ws1']);
    });
  });

  group('exportWorkspace', () {
    test('writes one workspace as one file', () async {
      await seedWorkspace('ws1', agentName: 'Ada');

      final path = await service().exportWorkspace('ws1');

      expect(File(path).existsSync(), isTrue);
      expect(path, endsWith('.db'));
      expect(path, contains('ws1-2026-07-05T12-34-56'));

      final exported = WorkspaceDatabase(
        NativeDatabase(File(path)),
        workspaceId: 'ws1',
      );
      addTearDown(exported.close);
      expect((await exported.agentDao.getAll()).map((a) => a.name), <String>[
        'Ada',
      ]);
    });

    test('rejects an id that is not a safe path segment', () async {
      expect(() => service().exportWorkspace('../escape'), throwsArgumentError);
    });

    test('refuses to export a workspace that has no file', () async {
      await global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'untouched', name: 'Untouched'),
      );
      expect(() => service().exportWorkspace('untouched'), throwsStateError);
    });
  });

  group('importWorkspace', () {
    test('adopts an exported file back over the live one', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final exported = await service().exportWorkspace('ws1');

      // Diverge the live workspace after the export.
      await workspaces.of('ws1').agentDao.deleteById('a-ws1');
      expect(await workspaces.of('ws1').agentDao.getAll(), isEmpty);

      final id = await service().importWorkspace(
        workspaceId: 'ws1',
        sourcePath: exported,
      );

      expect(id, 'ws1');
      expect(
        (await workspaces.of('ws1').agentDao.getAll()).map((a) => a.name),
        <String>['Ada'],
        reason: 'the imported file must be what the manager now serves',
      );
    });

    test('importing under a different id is allowed but warned about', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final exported = await service().exportWorkspace('ws1');
      warnings.clear();

      await service().importWorkspace(
        workspaceId: 'ws-clone',
        sourcePath: exported,
      );

      expect(
        warnings.any((w) => w.contains('ws1') && w.contains('ws-clone')),
        isTrue,
        reason:
            'duplicating a workspace is legitimate, but a file silently serving '
            'a workspace it does not claim to be is not',
      );
      expect(
        (await workspaces.of('ws-clone').agentDao.getAll()).map((a) => a.name),
        <String>['Ada'],
      );
    });

    test(
      'rejects a file that is not a Control Center workspace database',
      () async {
        final bogus = File('${tmp.path}/not-a-db.db')
          ..writeAsStringSync('nope');
        expect(
          () => service().importWorkspace(
            workspaceId: 'ws1',
            sourcePath: bogus.path,
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects a source path that does not exist', () async {
      expect(
        () => service().importWorkspace(
          workspaceId: 'ws1',
          sourcePath: '${tmp.path}/missing.db',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an id that is not a safe path segment', () async {
      await seedWorkspace('ws1', agentName: 'Ada');
      final exported = await service().exportWorkspace('ws1');
      expect(
        () =>
            service().importWorkspace(workspaceId: 'a/b', sourcePath: exported),
        throwsArgumentError,
      );
    });
  });
}
