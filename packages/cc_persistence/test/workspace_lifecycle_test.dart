import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/windows_safe_delete.dart';

/// A workspace's files over its life, on disk and through the server's own
/// connections: a deleted workspace stays deleted, and a damaged file stops
/// taking writes.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWorkspaceRepository workspaces;
  final damageReports = <(String, String)>[];

  WorkspaceDatabaseManager manager() => WorkspaceDatabaseManager(
    dataDir: tmp.path,
    global: global,
    onIntegrityFailure: (id, finding) => damageReports.add((id, finding)),
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_ws_lifecycle');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    global = GlobalDatabase.atDataDir(tmp.path);
    dbs = manager();
    workspaces = DaoWorkspaceRepository(global.workspaceRegistryDao, dbs);
    damageReports.clear();
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
    await deleteDirBestEffort(tmp);
  });

  Workspace workspace(String id) => Workspace(
    id: id,
    name: id,
    createdAt: DateTime(2026, 5, 18),
    updatedAt: DateTime(2026, 5, 18),
  );

  group('a deleted workspace', () {
    test('loses its directory and cannot be opened again', () async {
      await workspaces.upsert(workspace('w-1'));
      expect(dbs.existsOnDisk('w-1'), isTrue);

      await workspaces.delete('w-1');

      expect(Directory(dbs.dirFor('w-1')).existsSync(), isFalse);
      // The id is still in the hands of timers, caches and background
      // loops. None of them can bring an empty database back under it.
      expect(
        () => dbs.of('w-1'),
        throwsA(
          isA<DeletedWorkspaceException>().having(
            (e) => e.workspaceId,
            'workspaceId',
            'w-1',
          ),
        ),
      );
      expect(Directory(dbs.dirFor('w-1')).existsSync(), isFalse);
    });

    test('is out of every fan-out and every maintenance pass', () async {
      await workspaces.upsert(workspace('w-1'));
      await workspaces.upsert(workspace('w-2'));
      await workspaces.delete('w-1');

      expect(await dbs.liveWorkspaceIds(), ['w-2']);
      expect(
        await CrossWorkspaceQueries(dbs).fanOut((db) async => db.workspaceId),
        ['w-2'],
      );
    });

    test('is still refused after a restart, and what an earlier build '
        'left under its id is removed', () async {
      await workspaces.upsert(workspace('w-1'));
      await workspaces.delete('w-1');
      // What a stray open after the delete used to leave behind.
      Directory(dbs.dirFor('w-1')).createSync();
      File(dbs.pathFor('w-1')).writeAsStringSync('resurrected');
      await dbs.closeAll();

      dbs = manager();
      await dbs.loadDeletedWorkspaces();
      final removed = await dbs.removeFilesOfDeletedWorkspaces();

      expect(removed, ['w-1']);
      expect(Directory(dbs.dirFor('w-1')).existsSync(), isFalse);
      expect(() => dbs.of('w-1'), throwsA(isA<DeletedWorkspaceException>()));
      expect(dbs.isDeleted('w-1'), isTrue);
    });

    test('registered again under the same id starts empty', () async {
      await workspaces.upsert(workspace('w-1'));
      await dbs
          .of('w-1')
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'r-1', name: 'shop', path: '/src'),
          );
      await workspaces.delete('w-1');

      await workspaces.upsert(workspace('w-1'));

      expect(dbs.isDeleted('w-1'), isFalse);
      expect(await dbs.of('w-1').repoDao.getAll(), isEmpty);
    });
  });

  group('a damaged file', () {
    /// Overwrites the root page of one table of `w-1`'s file, the kind of
    /// damage a failing disk leaves.
    Future<void> damage() async {
      await workspaces.upsert(workspace('w-1'));
      await dbs
          .of('w-1')
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'r-1', name: 'shop', path: '/src'),
          );
      await dbs.close('w-1');
      final raw = sqlite3.sqlite3.open(dbs.pathFor('w-1'));
      final page =
          raw
                  .select(
                    'SELECT rootpage FROM sqlite_master '
                    "WHERE type = 'table' AND name = 'agent_run_logs'",
                  )
                  .single['rootpage']!
              as int;
      final pageSize =
          raw.select('PRAGMA page_size').single.values.single! as int;
      raw
        ..execute('PRAGMA wal_checkpoint(TRUNCATE)')
        ..close();
      final file = File(dbs.pathFor('w-1')).openSync(mode: FileMode.append);
      try {
        file
          ..setPositionSync((page - 1) * pageSize)
          ..writeFromSync(List<int>.filled(pageSize, 0xff));
      } finally {
        file.closeSync();
      }
      // A new process: nothing remembers having checked this file.
      dbs = manager();
      workspaces = DaoWorkspaceRepository(global.workspaceRegistryDao, dbs);
    }

    test('is reported once, stays readable and refuses writes', () async {
      await damage();

      final db = dbs.of('w-1');
      expect((await db.repoDao.getAll()).single.name, 'shop');

      expect(dbs.integrityFailure('w-1'), isNotNull);
      expect(damageReports, hasLength(1));
      expect(damageReports.single.$1, 'w-1');
      await expectLater(
        db.repoDao.upsertRepo(
          ReposTableCompanion.insert(id: 'r-2', name: 'api', path: '/api'),
        ),
        throwsA(anything),
      );
      expect((await db.repoDao.getAll()).map((r) => r.id), ['r-1']);
    });

    test('is checked again on every open, so a reopened connection is '
        'read-only too', () async {
      await damage();
      await dbs.of('w-1').repoDao.getAll();
      await dbs.close('w-1');

      final db = dbs.of('w-1');

      await expectLater(
        db.repoDao.upsertRepo(
          ReposTableCompanion.insert(id: 'r-2', name: 'api', path: '/api'),
        ),
        throwsA(anything),
      );
      expect(dbs.integrityFailures.keys, ['w-1']);
      // The owner hears about it once, not on every open.
      expect(damageReports, hasLength(1));
    });

    test('does not mark its neighbours', () async {
      await workspaces.upsert(workspace('w-2'));
      await damage();
      await dbs.of('w-1').repoDao.getAll();

      await dbs
          .of('w-2')
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'r-9', name: 'web', path: '/web'),
          );

      expect(dbs.integrityFailure('w-2'), isNull);
    });
  });

  group('snapshotTo', () {
    test('copies a workspace beside its live connection', () async {
      await workspaces.upsert(workspace('w-1'));
      await dbs
          .of('w-1')
          .repoDao
          .upsertRepo(
            ReposTableCompanion.insert(id: 'r-1', name: 'shop', path: '/src'),
          );
      final copy = '${tmp.path}/copy.db';

      await dbs.snapshotTo('w-1', copy);

      final raw = sqlite3.sqlite3.open(copy);
      addTearDown(raw.close);
      expect(raw.select('SELECT name FROM repos').single['name'], 'shop');
      expect(raw.select('PRAGMA quick_check').single.values.single, 'ok');
    });
  });
}
