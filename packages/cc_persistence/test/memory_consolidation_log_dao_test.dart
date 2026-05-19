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

  Future<void> pass({
    required String id,
    required String ws,
    DateTime? startedAt,
    int factsCreated = 0,
  }) => db.memoryConsolidationLogDao.insertPass(
    MemoryConsolidationLogTableCompanion.insert(
      id: id,
      workspaceId: ws,
      factsCreated: Value(factsCreated),
      startedAt: startedAt == null ? const Value.absent() : Value(startedAt),
    ),
  );

  group('MemoryConsolidationLogDao', () {
    test('getByWorkspace is workspace-scoped, newest first', () async {
      await pass(
        id: 'p-1',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 1, 0, 1),
      );
      await pass(
        id: 'p-2',
        ws: 'w-1',
        startedAt: DateTime.utc(2025, 1, 1, 0, 2),
      );
      await pass(id: 'p-3', ws: 'w-2');

      final rows = await db.memoryConsolidationLogDao.getByWorkspace('w-1');
      expect(rows, hasLength(2));
      // newest startedAt first
      expect(rows.first.id, 'p-2');
      // foreign workspace is isolated
      expect(
        await db.memoryConsolidationLogDao.getByWorkspace('w-2'),
        hasLength(1),
      );
    });
  });
}
