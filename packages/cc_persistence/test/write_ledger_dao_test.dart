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

  Future<void> record({
    required String ws,
    required String key,
    String op = 'create',
    DateTime? createdAt,
  }) => db.writeLedgerDao.record(
    WriteLedgerTableCompanion.insert(
      workspaceId: ws,
      idempotencyKey: key,
      opName: op,
      resultJson: '{}',
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  group('WriteLedgerDao', () {
    test('record + find is keyed by (workspace, key)', () async {
      await record(ws: 'w-1', key: 'k-1');
      expect((await db.writeLedgerDao.find('w-1', 'k-1'))?.opName, 'create');
      // different workspace: not found
      expect(await db.writeLedgerDao.find('w-2', 'k-1'), isNull);
      expect(await db.writeLedgerDao.find('w-1', 'missing'), isNull);
    });

    test('record is idempotent on (workspace, key)', () async {
      await record(ws: 'w-1', key: 'k-1', op: 'first');
      // a second record with the same key is ignored (insert-or-ignore).
      await record(ws: 'w-1', key: 'k-1', op: 'second');
      expect((await db.writeLedgerDao.find('w-1', 'k-1'))?.opName, 'first');
    });

    test('deleteOlderThan prunes entries created before the cutoff', () async {
      await record(ws: 'w-1', key: 'k-1', createdAt: DateTime.utc(2020, 1, 1));
      await record(ws: 'w-1', key: 'k-2', createdAt: DateTime.utc(2030, 1, 1));
      final deleted = await db.writeLedgerDao.deleteOlderThan(
        DateTime.utc(2025, 1, 1),
      );
      expect(deleted, 1);
      expect(await db.writeLedgerDao.find('w-1', 'k-1'), isNull);
      expect(await db.writeLedgerDao.find('w-1', 'k-2'), isNotNull);
    });
  });
}
