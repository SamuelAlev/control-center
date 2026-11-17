import 'dart:async';
import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show TableUpdate, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  test('closes an idle workspace and keeps one with a live watch', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final clock = _Clock();
    final global = createTestGlobalDatabase();
    final manager = WorkspaceDatabaseManager(
      dataDir: Directory.systemTemp.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory(),
      idleAfter: const Duration(seconds: 45),
      clock: () => clock.now,
    );
    addTearDown(() async {
      await manager.closeAll();
      await global.close();
    });

    final idleDb = manager.of('ws-idle');
    await idleDb.customSelect('SELECT 1').get();
    clock.advance(const Duration(seconds: 44));
    await manager.evictIdle();
    expect(manager.openCount, 1, reason: 'still inside the idle window');

    clock.advance(const Duration(seconds: 2));
    await manager.evictIdle();
    expect(manager.openCount, 0);

    final watched = manager.of('ws-live');
    final stream = watched.select(watched.workspaceMetaTable).watch();
    final subscription = stream.listen((_) {});
    await stream.first;
    clock.advance(const Duration(hours: 1));
    await manager.evictIdle();
    expect(manager.openIds, contains('ws-live'));

    await subscription.cancel();
    // Drift keeps the watch's table subscription for one event-queue turn
    // after the last listener cancels.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    clock.advance(const Duration(hours: 1));
    await manager.evictIdle();
    expect(manager.openCount, 0);
  });

  group('watchWithoutHolding', () {
    late _Clock clock;
    late GlobalDatabase global;
    late WorkspaceDatabaseManager manager;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      clock = _Clock();
      global = createTestGlobalDatabase();
      manager = WorkspaceDatabaseManager(
        dataDir: Directory.systemTemp.path,
        global: global,
        executorFactory: (_) => NativeDatabase.memory(),
        idleAfter: const Duration(seconds: 45),
        clock: () => clock.now,
      );
      addTearDown(() async {
        await manager.closeAll();
        await global.close();
      });
    });

    Stream<String?> installIds(
      String workspaceId,
    ) => manager.watchWithoutHolding<String?>(
      workspaceId,
      tables: (db) => [db.workspaceMetaTable],
      read: (db) async =>
          (await db.select(db.workspaceMetaTable).getSingleOrNull())?.installId,
    );

    test('reads now and after each write to its tables, and lets the file '
        'close in between', () async {
      final seen = <String?>[];
      final subscription = installIds('ws-quiet').listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      expect(seen, isNotEmpty);

      await _stamp(manager, 'ws-quiet', 'first');
      await pumpEventQueue();
      expect(seen.last, 'first');

      // Still listening, and the file closes all the same.
      clock.advance(const Duration(seconds: 46));
      await manager.evictIdle();
      expect(manager.openCount, 0);

      // The next write opens it again, and is heard.
      await _stamp(manager, 'ws-quiet', 'second');
      await pumpEventQueue();
      expect(seen.last, 'second');
    });

    test('ignores writes to other tables and to other workspaces', () async {
      final seen = <String?>[];
      final subscription = installIds('ws-mine').listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();
      final before = seen.length;
      expect(before, greaterThan(0));

      manager.of('ws-mine').notifyUpdates({const TableUpdate('repos')});
      await _stamp(manager, 'ws-other', 'elsewhere');
      await pumpEventQueue();

      expect(seen, hasLength(before));
    });

    test(
      'a failed read is an error, and the next write is still read',
      () async {
        var fail = true;
        final seen = <Object?>[];
        final errors = <Object>[];
        final subscription = manager
            .watchWithoutHolding<String?>(
              'ws-flaky',
              tables: (db) => [db.workspaceMetaTable],
              read: (db) async {
                if (fail) {
                  throw StateError('not now');
                }
                return (await db
                        .select(db.workspaceMetaTable)
                        .getSingleOrNull())
                    ?.installId;
              },
            )
            .listen(seen.add, onError: errors.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        expect(errors.single, isStateError);
        expect(seen, isEmpty);

        fail = false;
        await _stamp(manager, 'ws-flaky', 'recovered');
        await pumpEventQueue();
        expect(seen.last, 'recovered');
        expect(errors, hasLength(1));
      },
    );

    test('stops reading once cancelled', () async {
      var reads = 0;
      final subscription = manager
          .watchWithoutHolding<int>(
            'ws-done',
            tables: (db) => [db.workspaceMetaTable],
            read: (db) async => ++reads,
          )
          .listen((_) {});
      await pumpEventQueue();
      expect(reads, 1);

      await subscription.cancel();
      await _stamp(manager, 'ws-done', 'unheard');
      await pumpEventQueue();
      expect(reads, 1);
    });
  });

  group('describeOpen', () {
    test('names the tables a live watch reads, then what last ran', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final clock = _Clock();
      final global = createTestGlobalDatabase();
      final manager = WorkspaceDatabaseManager(
        dataDir: Directory.systemTemp.path,
        global: global,
        executorFactory: (_) => NativeDatabase.memory(),
        idleAfter: const Duration(seconds: 45),
        clock: () => clock.now,
      );
      addTearDown(() async {
        await manager.closeAll();
        await global.close();
      });

      final db = manager.of('ws-seen');
      final subscription = db
          .select(db.workspaceMetaTable)
          .watch()
          .listen((_) {});
      await pumpEventQueue();
      expect(
        manager.describeOpen()['ws-seen'],
        contains('watched: ${db.workspaceMetaTable.actualTableName}'),
      );

      await subscription.cancel();
      await pumpEventQueue();
      await db.customSelect('SELECT 42').get();
      clock.advance(const Duration(seconds: 5));
      expect(
        manager.describeOpen()['ws-seen'],
        allOf(startsWith('quiet for 5s'), contains('SELECT 42')),
      );

      // Named for a minute, so a poller shows and a one-off does not linger.
      clock.advance(const Duration(minutes: 2));
      expect(manager.describeOpen()['ws-seen'], 'quiet for 125s');
    });
  });

  test('does not close a workspace inside useTransiently', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final clock = _Clock();
    final global = createTestGlobalDatabase();
    final manager = WorkspaceDatabaseManager(
      dataDir: Directory.systemTemp.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory(),
      idleAfter: const Duration(seconds: 45),
      clock: () => clock.now,
    );
    addTearDown(() async {
      await manager.closeAll();
      await global.close();
    });

    final release = Completer<void>();
    final pending = manager.useTransiently<void>('ws-fanout', (db) async {
      await db.customSelect('SELECT 1').get();
      await release.future;
    });
    await Future<void>.delayed(Duration.zero);
    expect(manager.openCount, 1);

    clock.advance(const Duration(hours: 1));
    await manager.evictIdle();
    expect(manager.openCount, 1);

    release.complete();
    await pending;
    expect(manager.openCount, 0);
  });

  test('of during eviction reclaims the same database', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final clock = _Clock();
    final global = createTestGlobalDatabase();
    final manager = WorkspaceDatabaseManager(
      dataDir: Directory.systemTemp.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory(),
      idleAfter: const Duration(seconds: 45),
      clock: () => clock.now,
    );
    addTearDown(() async {
      await manager.closeAll();
      await global.close();
    });

    final original = manager.of('ws-race');
    await original.customSelect('SELECT 1').get();
    clock.advance(const Duration(seconds: 46));

    final evicting = manager.evictIdle();
    final again = manager.of('ws-race');
    expect(identical(again, original), isTrue);
    await evicting;
    expect(manager.openIds, contains('ws-race'));
    await again.customSelect('SELECT 1').get();
    expect(identical(manager.of('ws-race'), original), isTrue);
  });

  test('a statement started during eviction keeps the file', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final clock = _Clock();
    final global = createTestGlobalDatabase();
    final manager = WorkspaceDatabaseManager(
      dataDir: Directory.systemTemp.path,
      global: global,
      executorFactory: (_) => NativeDatabase.memory(),
      idleAfter: const Duration(seconds: 45),
      clock: () => clock.now,
    );
    addTearDown(() async {
      await manager.closeAll();
      await global.close();
    });

    final original = manager.of('ws-stmt');
    await original.customSelect('SELECT 1').get();
    clock.advance(const Duration(seconds: 46));

    final evicting = manager.evictIdle();
    final query = original.customSelect('SELECT 1').get();
    await evicting;
    expect(manager.openIds, contains('ws-stmt'));
    expect(await query, isNotEmpty);
    expect(identical(manager.of('ws-stmt'), original), isTrue);
  });
}

/// Writes [installId] into [workspaceId]'s one meta row: a write to the
/// table the tests above watch, through whichever connection is open for it.
/// Opening a file writes that row too, so a watch of it may read more than
/// once per stamp; the tests look at what was read last.
Future<void> _stamp(
  WorkspaceDatabaseManager manager,
  String workspaceId,
  String installId,
) async {
  final db = manager.of(workspaceId);
  final written = await db
      .update(db.workspaceMetaTable)
      .write(WorkspaceMetaTableCompanion(installId: Value(installId)));
  expect(written, 1);
}

class _Clock {
  DateTime now = DateTime.utc(2026, 1, 1);

  void advance(Duration by) {
    now = now.add(by);
  }
}
