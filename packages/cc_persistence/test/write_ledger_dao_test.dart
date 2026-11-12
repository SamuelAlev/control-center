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

  Future<bool> claim({
    required String ws,
    required String key,
    String op = 'create',
    DateTime? createdAt,
  }) => db.writeLedgerDao.claim(
    WriteLedgerTableCompanion.insert(
      workspaceId: ws,
      idempotencyKey: key,
      opName: op,
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  group('WriteLedgerDao', () {
    test('claim + find is keyed by (workspace, key)', () async {
      expect(await claim(ws: 'w-1', key: 'k-1'), isTrue);
      final row = await db.writeLedgerDao.find('w-1', 'k-1');
      expect(row?.opName, 'create');
      expect(row?.resultJson, isNull);
      // different workspace: not found
      expect(await db.writeLedgerDao.find('w-2', 'k-1'), isNull);
      expect(await db.writeLedgerDao.find('w-1', 'missing'), isNull);
    });

    test('a second claim of one key reports that it did not insert', () async {
      expect(await claim(ws: 'w-1', key: 'k-1', op: 'first'), isTrue);
      expect(await claim(ws: 'w-1', key: 'k-1', op: 'second'), isFalse);
      expect((await db.writeLedgerDao.find('w-1', 'k-1'))?.opName, 'first');
      // The same key in another workspace is a separate claim.
      expect(await claim(ws: 'w-2', key: 'k-1'), isTrue);
    });

    test('complete stores the result once; release never drops it', () async {
      await claim(ws: 'w-1', key: 'k-1');
      final at = DateTime.utc(2026, 1, 1);
      expect(
        await db.writeLedgerDao.complete('w-1', 'k-1', '{"a":1}', at),
        isTrue,
      );
      expect(
        await db.writeLedgerDao.complete('w-1', 'k-1', '{"a":2}', at),
        isFalse,
      );
      expect(await db.writeLedgerDao.release('w-1', 'k-1'), 0);
      expect(
        (await db.writeLedgerDao.find('w-1', 'k-1'))?.resultJson,
        '{"a":1}',
      );
    });

    test('release frees an unfinished claim for the next caller', () async {
      await claim(ws: 'w-1', key: 'k-1');
      expect(await db.writeLedgerDao.release('w-1', 'k-1'), 1);
      expect(await claim(ws: 'w-1', key: 'k-1'), isTrue);
    });

    test('dropUnfinished keeps completed rows', () async {
      await claim(ws: 'w-1', key: 'done');
      await db.writeLedgerDao.complete('w-1', 'done', '{}', DateTime.now());
      await claim(ws: 'w-1', key: 'stuck');
      expect(await db.writeLedgerDao.dropUnfinished('w-1'), 1);
      expect(await db.writeLedgerDao.find('w-1', 'done'), isNotNull);
      expect(await db.writeLedgerDao.find('w-1', 'stuck'), isNull);
    });

    test('deleteOlderThan prunes entries created before the cutoff', () async {
      await claim(ws: 'w-1', key: 'k-1', createdAt: DateTime.utc(2020, 1, 1));
      await claim(ws: 'w-1', key: 'k-2', createdAt: DateTime.utc(2030, 1, 1));
      final deleted = await db.writeLedgerDao.deleteOlderThan(
        DateTime.utc(2025, 1, 1),
      );
      expect(deleted, 1);
      expect(await db.writeLedgerDao.find('w-1', 'k-1'), isNull);
      expect(await db.writeLedgerDao.find('w-1', 'k-2'), isNotNull);
    });
  });
}
