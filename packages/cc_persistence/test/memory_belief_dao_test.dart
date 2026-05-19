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

  MemoryBeliefsTableCompanion belief({
    required String id,
    required String ws,
    double confidence = 0.5,
  }) => MemoryBeliefsTableCompanion.insert(
    id: id,
    workspaceId: ws,
    topic: 't',
    content: 'c',
    confidence: Value(confidence),
    clusterId: 'cl',
  );

  group('MemoryBeliefDao workspace isolation', () {
    test('getByWorkspace returns scoped rows, strongest-first', () async {
      await db.memoryBeliefDao.upsert(
        belief(id: 'b-1', ws: 'w-1', confidence: 0.2),
      );
      await db.memoryBeliefDao.upsert(
        belief(id: 'b-2', ws: 'w-1', confidence: 0.9),
      );
      await db.memoryBeliefDao.upsert(
        belief(id: 'b-3', ws: 'w-2', confidence: 0.9),
      );
      final rows = await db.memoryBeliefDao.getByWorkspace('w-1');
      expect(rows, hasLength(2));
      // strongest first
      expect(rows.first.id, 'b-2');
    });

    test('watchByWorkspace emits scoped rows', () async {
      await db.memoryBeliefDao.upsert(belief(id: 'b-1', ws: 'w-1'));
      final rows = await db.memoryBeliefDao.watchByWorkspace('w-1').first;
      expect(rows, hasLength(1));
    });

    test('upsert replaces on conflict (same id PK)', () async {
      await db.memoryBeliefDao.upsert(
        belief(id: 'b-1', ws: 'w-1', confidence: 0.1),
      );
      await db.memoryBeliefDao.upsert(
        belief(id: 'b-1', ws: 'w-1', confidence: 0.8),
      );
      final rows = await db.memoryBeliefDao.getByWorkspace('w-1');
      expect(rows.first.confidence, 0.8);
    });

    test(
      'replaceWorkspace wipes only the workspace then inserts the new set',
      () async {
        await db.memoryBeliefDao.upsert(belief(id: 'b-1', ws: 'w-1'));
        await db.memoryBeliefDao.upsert(belief(id: 'b-other', ws: 'w-2'));

        await db.memoryBeliefDao.replaceWorkspace('w-1', [
          belief(id: 'b-new-1', ws: 'w-1'),
          belief(id: 'b-new-2', ws: 'w-1'),
        ]);

        final rows = await db.memoryBeliefDao.getByWorkspace('w-1');
        expect(rows.map((r) => r.id).toSet(), {'b-new-1', 'b-new-2'});
        // foreign workspace untouched
        expect(await db.memoryBeliefDao.getByWorkspace('w-2'), hasLength(1));
      },
    );
  });
}
