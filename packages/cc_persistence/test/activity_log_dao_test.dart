import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> entry({
    required String id,
    required String ws,
    required String action,
    required String entityType,
    String entityId = 'e-1',
    DateTime? createdAt,
  }) => db.activityLogDao.insertEntry(
    ActivityLogTableCompanion.insert(
      id: id,
      workspaceId: Value(ws),
      actorType: 'agent',
      action: action,
      entityType: entityType,
      entityId: Value(entityId),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  group('ActivityLogDao workspace isolation', () {
    test('watchForEntity is scoped by (ws, entityType, entityId)', () async {
      await entry(id: '1', ws: 'w-1', action: 'open', entityType: 'ticket');
      await entry(
        id: '2',
        ws: 'w-1',
        action: 'open',
        entityType: 'ticket',
        entityId: 'e-2',
      );
      await entry(id: '3', ws: 'w-1', action: 'open', entityType: 'goal');
      await entry(id: '4', ws: 'w-2', action: 'open', entityType: 'ticket');

      final rows = await db.activityLogDao
          .watchForEntity('w-1', 'ticket', 'e-1')
          .first;
      expect(rows, hasLength(1));
      expect(rows.first.id, '1');
    });

    test('watchRecent is workspace-scoped', () async {
      await entry(id: '1', ws: 'w-1', action: 'a', entityType: 'ticket');
      await entry(id: '2', ws: 'w-2', action: 'a', entityType: 'ticket');

      final rows = await db.activityLogDao.watchRecent('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.workspaceId, 'w-1');
    });

    test('watchForEntity honours the limit cap', () async {
      for (var i = 0; i < 5; i++) {
        await entry(id: '$i', ws: 'w-1', action: 'a', entityType: 'ticket');
      }
      final rows = await db.activityLogDao
          .watchForEntity('w-1', 'ticket', 'e-1', limit: 2)
          .first;
      expect(rows, hasLength(2));
    });

    test('deleteOlderThan removes only rows before the cutoff', () async {
      final old = DateTime.utc(2020, 1, 1);
      final recent = DateTime.utc(2030, 1, 1);
      await entry(
        id: '1',
        ws: 'w-1',
        action: 'a',
        entityType: 'ticket',
        createdAt: old,
      );
      await entry(
        id: '2',
        ws: 'w-1',
        action: 'a',
        entityType: 'ticket',
        createdAt: recent,
      );

      final deleted = await db.activityLogDao.deleteOlderThan(
        DateTime.utc(2025, 1, 1),
      );
      expect(deleted, 1);
      final remaining = await db.activityLogDao.watchRecent('w-1').first;
      expect(remaining, hasLength(1));
      expect(remaining.first.id, '2');
    });
  });
}
