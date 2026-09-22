import 'dart:async';
import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
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

class _Clock {
  DateTime now = DateTime.utc(2026, 1, 1);

  void advance(Duration by) {
    now = now.add(by);
  }
}
