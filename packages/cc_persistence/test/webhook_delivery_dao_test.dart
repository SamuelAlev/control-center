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

  Future<void> record({
    required String id,
    required String ws,
    required String triggerId,
    String status = 'queued',
    String signatureStatus = 'valid',
    String? dedupeKey,
    DateTime? createdAt,
  }) => db.webhookDeliveryDao.record(
    WebhookDeliveriesTableCompanion.insert(
      id: id,
      workspaceId: ws,
      triggerId: triggerId,
      status: status,
      signatureStatus: signatureStatus,
      dedupeKey: dedupeKey == null ? const Value.absent() : Value(dedupeKey),
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  group('WebhookDeliveryDao workspace isolation', () {
    test('getById is workspace-scoped', () async {
      await record(id: 'wd-1', ws: 'w-1', triggerId: 'trig-1');
      expect((await db.webhookDeliveryDao.getById('w-1', 'wd-1'))?.id, 'wd-1');
      expect(await db.webhookDeliveryDao.getById('w-2', 'wd-1'), isNull);
      expect(await db.webhookDeliveryDao.getById('w-1', 'missing'), isNull);
    });

    test('forTrigger is workspace-scoped, newest first', () async {
      await record(
        id: 'wd-1',
        ws: 'w-1',
        triggerId: 'trig-1',
        createdAt: DateTime.utc(2025, 1, 1, 0, 1),
      );
      await record(
        id: 'wd-2',
        ws: 'w-1',
        triggerId: 'trig-1',
        createdAt: DateTime.utc(2025, 1, 1, 0, 2),
      );
      await record(
        id: 'wd-3',
        ws: 'w-2',
        triggerId: 'trig-1',
        createdAt: DateTime.utc(2025, 1, 1, 0, 3),
      );

      final rows = await db.webhookDeliveryDao.forTrigger('w-1', 'trig-1');
      expect(rows, hasLength(2));
      // newest first
      expect(rows.first.id, 'wd-2');
    });

    test('watchForWorkspace emits scoped rows', () async {
      await record(id: 'wd-1', ws: 'w-1', triggerId: 'trig-1');
      await record(id: 'wd-2', ws: 'w-2', triggerId: 'trig-1');
      final rows = await db.webhookDeliveryDao.watchForWorkspace('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'wd-1');
    });

    test('updateDelivery writes mutable fields', () async {
      await record(id: 'wd-1', ws: 'w-1', triggerId: 'trig-1');
      await db.webhookDeliveryDao.updateDelivery(
        'wd-1',
        const WebhookDeliveriesTableCompanion(
          status: Value('dispatched'),
          runId: Value('run-1'),
        ),
      );
      final row = await db.webhookDeliveryDao.getById('w-1', 'wd-1');
      expect(row?.status, 'dispatched');
      expect(row?.runId, 'run-1');
    });

    test(
      'existsByDedupeKey detects a prior delivery for (triggerId, key)',
      () async {
        await record(
          id: 'wd-1',
          ws: 'w-1',
          triggerId: 'trig-1',
          dedupeKey: 'abc',
        );
        expect(
          await db.webhookDeliveryDao.existsByDedupeKey('trig-1', 'abc'),
          isTrue,
        );
        expect(
          await db.webhookDeliveryDao.existsByDedupeKey('trig-1', 'other'),
          isFalse,
        );
        expect(
          await db.webhookDeliveryDao.existsByDedupeKey('other-trig', 'abc'),
          isFalse,
        );
      },
    );

    test('deleteOlderThan removes rows created before the cutoff', () async {
      await record(
        id: 'wd-1',
        ws: 'w-1',
        triggerId: 'trig-1',
        createdAt: DateTime.utc(2020, 1, 1),
      );
      await record(
        id: 'wd-2',
        ws: 'w-1',
        triggerId: 'trig-1',
        createdAt: DateTime.utc(2030, 1, 1),
      );
      final deleted = await db.webhookDeliveryDao.deleteOlderThan(
        DateTime.utc(2025, 1, 1),
      );
      expect(deleted, 1);
      expect(
        await db.webhookDeliveryDao.forTrigger('w-1', 'trig-1'),
        hasLength(1),
      );
    });
  });
}
