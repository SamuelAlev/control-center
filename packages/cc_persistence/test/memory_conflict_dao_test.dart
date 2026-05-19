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

  Future<void> conflict({
    required String id,
    required String ws,
    String? resolution,
  }) => db.memoryConflictDao.upsert(
    MemoryConflictsTableCompanion.insert(
      id: id,
      workspaceId: ws,
      factAId: 'fa',
      factBId: 'fb',
      resolution: resolution == null ? const Value.absent() : Value(resolution),
    ),
  );

  group('MemoryConflictDao workspace isolation', () {
    test('getByWorkspace + watchByWorkspace are scoped', () async {
      await conflict(id: 'c-1', ws: 'w-1');
      await conflict(id: 'c-2', ws: 'w-2');
      expect(await db.memoryConflictDao.getByWorkspace('w-1'), hasLength(1));
      expect(
        await db.memoryConflictDao.watchByWorkspace('w-2').first,
        hasLength(1),
      );
    });

    test(
      'getUnresolved returns only conflicts with a null resolution',
      () async {
        await conflict(id: 'c-1', ws: 'w-1');
        await conflict(id: 'c-2', ws: 'w-1', resolution: 'kept_a');
        final unresolved = await db.memoryConflictDao.getUnresolved('w-1');
        expect(unresolved, hasLength(1));
        expect(unresolved.first.id, 'c-1');
      },
    );

    test('upsert replaces on conflict (same id PK)', () async {
      await conflict(id: 'c-1', ws: 'w-1');
      await conflict(id: 'c-1', ws: 'w-1', resolution: 'kept_b');
      final unresolved = await db.memoryConflictDao.getUnresolved('w-1');
      expect(unresolved, isEmpty);
    });
  });
}
