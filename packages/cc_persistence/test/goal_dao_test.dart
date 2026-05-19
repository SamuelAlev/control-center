import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed({
    required String id,
    required String ws,
    String? parentGoalId,
    String title = 'G',
    int progress = 0,
  }) => db.goalDao.upsert(
    GoalsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      parentGoalId: parentGoalId == null
          ? const Value.absent()
          : Value(parentGoalId),
      title: title,
      progress: Value(progress),
    ),
  );

  group('GoalDao workspace isolation', () {
    test('getByWorkspace returns scoped rows', () async {
      await seed(id: 'g-1', ws: 'w-1');
      await seed(id: 'g-2', ws: 'w-2');
      final rows = await db.goalDao.getByWorkspace('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'g-1');
    });

    test('watchByWorkspace emits scoped rows', () async {
      await seed(id: 'g-1', ws: 'w-1');
      final rows = await db.goalDao.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await seed(id: 'g-1', ws: 'w-1', title: 'first');
      await seed(id: 'g-1', ws: 'w-1', title: 'second', progress: 50);
      final row = await db.goalDao.getById('w-1', 'g-1');
      expect(row?.title, 'second');
      expect(row?.progress, 50);
    });

    test('getById is workspace-scoped', () async {
      await seed(id: 'g-1', ws: 'w-1');
      expect((await db.goalDao.getById('w-1', 'g-1'))?.id, 'g-1');
      expect(await db.goalDao.getById('w-2', 'g-1'), isNull);
      expect(await db.goalDao.getById('w-1', 'missing'), isNull);
    });

    test('childrenOf lists direct children', () async {
      await seed(id: 'g-1', ws: 'w-1');
      await seed(id: 'g-2', ws: 'w-1', parentGoalId: 'g-1');
      await seed(id: 'g-3', ws: 'w-1', parentGoalId: 'g-1');
      final rows = await db.goalDao.childrenOf('w-1', 'g-1');
      expect(rows.map((r) => r.id).toSet(), {'g-2', 'g-3'});
    });

    test(
      'deleteById is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seed(id: 'g-1', ws: 'w-1');
        expect(await db.goalDao.deleteById('w-2', 'g-1'), 0);
        expect(await db.goalDao.getById('w-1', 'g-1'), isNotNull);
        expect(await db.goalDao.deleteById('w-1', 'g-1'), 1);
        expect(await db.goalDao.getById('w-1', 'g-1'), isNull);
      },
    );
  });
}
