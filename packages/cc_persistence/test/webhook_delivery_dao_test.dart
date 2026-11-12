import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
    await seedPipelineTrigger(db, 'trig-1');
    await seedPipelineTrigger(db, 'trig-2');
    await seedPipelineRun(db, 'run-1');
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
  });

  group('WebhookDeliveryDao.claim', () {
    WebhookDeliveriesTableCompanion delivery(
      String id, {
      String triggerId = 'trig-1',
      String? dedupeKey = 'abc',
    }) => WebhookDeliveriesTableCompanion.insert(
      id: id,
      workspaceId: 'w-1',
      triggerId: triggerId,
      status: 'queued',
      signatureStatus: 'valid',
      dedupeKey: Value(dedupeKey),
    );

    Future<void> setStatus(String id, String status) =>
        db.webhookDeliveryDao.updateDelivery(
          id,
          WebhookDeliveriesTableCompanion(status: Value(status)),
        );

    test(
      'a key in flight or dispatched is held; a failed one is not',
      () async {
        final dao = db.webhookDeliveryDao;
        expect(await dao.claim(delivery('d-1')), isTrue);
        // In flight: the identical delivery is not claimed (and not recorded).
        expect(await dao.claim(delivery('d-2')), isFalse);
        expect(await dao.getById('w-1', 'd-2'), isNull);

        await setStatus('d-1', 'failed');
        // The provider's retry of a failed dispatch claims the key again.
        expect(await dao.claim(delivery('d-3')), isTrue);

        await setStatus('d-3', 'dispatched');
        expect(await dao.claim(delivery('d-4')), isFalse);
      },
    );

    test(
      'keys are per trigger, and a delivery without one is never held',
      () async {
        final dao = db.webhookDeliveryDao;
        expect(await dao.claim(delivery('d-1')), isTrue);
        expect(await dao.claim(delivery('d-2', triggerId: 'trig-2')), isTrue);
        expect(await dao.claim(delivery('d-3', dedupeKey: null)), isTrue);
        expect(await dao.claim(delivery('d-4', dedupeKey: null)), isTrue);
      },
    );

    test('rejected and ignored rows hold no key', () async {
      final dao = db.webhookDeliveryDao;
      await record(
        id: 'r-1',
        ws: 'w-1',
        triggerId: 'trig-1',
        status: 'rejected',
        dedupeKey: 'abc',
      );
      await record(
        id: 'i-1',
        ws: 'w-1',
        triggerId: 'trig-1',
        status: 'ignored',
        dedupeKey: 'abc',
      );
      expect(await dao.claim(delivery('d-1')), isTrue);
    });

    test('of concurrent identical claims exactly one wins', () async {
      final dao = db.webhookDeliveryDao;
      final results = await Future.wait([
        for (var i = 0; i < 8; i++) dao.claim(delivery('d-$i')),
      ]);
      expect(results.where((won) => won), hasLength(1));
    });
  });

  group('WebhookDeliveryDao retention', () {
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
