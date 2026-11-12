import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/windows_safe_delete.dart';

/// [DatabaseRetentionService] against real files: what it hands back to the
/// file system, which upgrade copies it keeps, and the workspaces it must
/// leave alone.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWorkspaceRepository workspaces;
  final warnings = <String>[];

  WorkspaceDatabaseManager manager() => WorkspaceDatabaseManager(
    dataDir: tmp.path,
    global: global,
    onWarn: (tag, message) => warnings.add('$tag: $message'),
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_retention_files');
    sqlite3.sqlite3.tempDirectory = tmp.path;
    global = GlobalDatabase.atDataDir(tmp.path);
    dbs = manager();
    workspaces = DaoWorkspaceRepository(global.workspaceRegistryDao, dbs);
    warnings.clear();
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

  DatabaseRetentionService service({List<String>? errors}) =>
      DatabaseRetentionService(
        workspaces: dbs,
        global: global,
        dataDir: tmp.path,
        onError: errors?.add,
      );

  /// Old executions of one trigger, one slot each, with ids long enough
  /// that a few hundred of them are most of the file.
  Future<void> seedOldCronExecutions(String workspaceId, int count) async {
    final db = dbs.of(workspaceId);
    final old = DateTime.now().subtract(const Duration(days: 365));
    await seedPipelineTrigger(db, 'trigger');
    await db.batch((batch) {
      for (var i = 0; i < count; i++) {
        final slot = old.subtract(Duration(minutes: i));
        batch.insert(
          db.cronExecutionsTable,
          CronExecutionsTableCompanion(
            id: Value('$workspaceId-$i-${'x' * 2000}'),
            workspaceId: Value(workspaceId),
            triggerId: const Value('trigger'),
            plannedAt: Value(slot),
            createdAt: Value(slot),
          ),
        );
      }
    });
  }

  test('a pruned workspace file shrinks on disk', () async {
    await workspaces.upsert(workspace('w-1'));
    // Each sweep hands back a bounded number of pages; this stays under it.
    await seedOldCronExecutions('w-1', 500);
    final db = dbs.of('w-1');
    await db.checkpoint();
    final path = dbs.pathFor('w-1');
    final before = File(path).lengthSync();

    await service().runOnce();

    final after = File(path).lengthSync();
    expect(
      after,
      lessThan(before ~/ 2),
      reason:
          'the deleted rows freed most of the file; without the incremental '
          'vacuum the file keeps its size and only reuses the pages later',
    );
  });

  group('pre_upgrade copies', () {
    File copyAt(String dir, String name, Duration age) {
      Directory(dir).createSync(recursive: true);
      return File('$dir${Platform.pathSeparator}$name')
        ..writeAsStringSync('copy')
        ..setLastModifiedSync(DateTime.now().subtract(age));
    }

    test('older than the window are removed beside both databases, the '
        'newest kept however old', () async {
      await workspaces.upsert(workspace('w-1'));
      final wsDir = workspaceUpgradeSnapshotDir(tmp.path, 'w-1');
      final globalDir = globalUpgradeSnapshotDir(tmp.path);
      final wsOldest = copyAt(wsDir, 'v1.a.db', const Duration(days: 90));
      final wsOld = copyAt(wsDir, 'v2.b.db', const Duration(days: 60));
      final wsRecent = copyAt(wsDir, 'v3.c.db', const Duration(days: 2));
      final globalOld = copyAt(globalDir, 'v1.a.db', const Duration(days: 90));
      final globalNewest = copyAt(
        globalDir,
        'v2.b.db',
        const Duration(days: 45),
      );

      await service().runOnce();

      expect(wsOldest.existsSync(), isFalse);
      expect(wsOld.existsSync(), isFalse);
      expect(wsRecent.existsSync(), isTrue);
      expect(globalOld.existsSync(), isFalse);
      expect(
        globalNewest.existsSync(),
        isTrue,
        reason: 'the newest copy is the only way back, at any age',
      );
    });
  });

  group('a read-only workspace', () {
    /// Overwrites the root page of one table of `w-1`'s file, the kind of
    /// damage a failing disk leaves, and starts a new manager that has not
    /// checked it yet.
    Future<void> damage() async {
      await workspaces.upsert(workspace('w-1'));
      await seedOldCronExecutions('w-1', 3);
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
      await dbs.closeAll();
      dbs = manager();
      workspaces = DaoWorkspaceRepository(global.workspaceRegistryDao, dbs);
    }

    test('is skipped by the sweep with one log line, its neighbours '
        'pruned', () async {
      await workspaces.upsert(workspace('w-2'));
      await seedOldCronExecutions('w-2', 3);
      await damage();
      final errors = <String>[];

      final deleted = await service(errors: errors).runOnce();

      expect(deleted, 3, reason: "w-2's rows; w-1 takes no writes");
      expect(errors, isEmpty);
      expect(dbs.integrityFailure('w-1'), isNotNull);
      final skips = warnings.where((w) => w.contains('skipped read-only'));
      expect(skips, hasLength(1));
      expect(skips.single, contains('w-1'));
      expect(skips.single, isNot(contains('w-2')));
      final w1 = await dbs
          .of('w-1')
          .select(dbs.of('w-1').cronExecutionsTable)
          .get();
      expect(w1, hasLength(3));
    });

    test('is left out of a background writer\'s fan-out, not a '
        'reader\'s', () async {
      await workspaces.upsert(workspace('w-2'));
      await damage();
      final cross = CrossWorkspaceQueries(dbs);

      Future<String> read(WorkspaceDatabase db) async {
        await db.customSelect('SELECT 1').get();
        return db.workspaceId;
      }

      final writerSees = await cross.fanOut(
        read,
        backgroundWriter: 'test writer',
      );
      final readerSees = await cross.fanOut(read);

      expect(writerSees, ['w-2']);
      expect(readerSees..sort(), ['w-1', 'w-2']);
      expect(
        warnings.where((w) => w.contains('test writer skipped')),
        hasLength(1),
      );
    });
  });

  test('the hourly refresh never opens a closed workspace', () async {
    await workspaces.upsert(workspace('w-1'));
    await dbs.closeAll();

    await service().refreshStatistics();

    expect(dbs.openIds, isEmpty);
  });
}
