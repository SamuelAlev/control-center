import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [PairedDeviceDao] against an in-memory database. Devices are
/// CROSS-WORKSPACE BY DESIGN (a paired phone spans every workspace), so these
/// queries are intentionally unscoped — this test covers the full lifecycle:
/// upsert → list/watch → confirm/re-approve → status/heartbeat → revoke.
void main() {
  late GlobalDatabase db;

  setUp(() {
    db = createTestGlobalDatabase();
  });

  tearDown(() async => db.close());

  Future<void> insertDevice(
    String id, {
    String? userId,
    String status = PairedDeviceStatus.pendingConfirm,
    DateTime? pairedAt,
  }) => db.pairedDeviceDao.upsert(
    PairedDevicesTableCompanion.insert(
      id: id,
      userId: userId == null ? const Value.absent() : Value(userId),
      label: id,
      pskRef: 'psk-$id',
      status: Value(status),
      pairedAt: pairedAt == null ? const Value.absent() : Value(pairedAt),
    ),
  );

  group('PairedDeviceDao reads', () {
    test('getAll returns every device', () async {
      await insertDevice('d-1');
      await insertDevice('d-2');
      final all = await db.pairedDeviceDao.getAll();
      expect(all.length, 2);
    });

    test('getById returns the device or null', () async {
      await insertDevice('d-1');
      expect((await db.pairedDeviceDao.getById('d-1'))?.id, 'd-1');
      expect(await db.pairedDeviceDao.getById('missing'), isNull);
    });

    test(
      'getForUser returns only the user devices, newest-paired first',
      () async {
        final early = DateTime(2026, 1, 1);
        final late = DateTime(2026, 2, 1);
        await insertDevice('d-old', userId: 'u-1', pairedAt: early);
        await insertDevice('d-new', userId: 'u-1', pairedAt: late);
        await insertDevice('d-other', userId: 'u-2', pairedAt: late);
        final forUser = await db.pairedDeviceDao.getForUser('u-1');
        expect(forUser.map((d) => d.id), ['d-new', 'd-old']);
      },
    );

    test('watchAll orders most-recently-paired first', () async {
      await insertDevice('d-1', pairedAt: DateTime(2026, 1, 1));
      await insertDevice('d-2', pairedAt: DateTime(2026, 2, 1));
      final all = await db.pairedDeviceDao.watchAll().first;
      expect(all.first.id, 'd-2');
    });
  });

  group('PairedDeviceDao status filtering', () {
    test('watchActive returns only active devices', () async {
      await insertDevice('d-active', status: PairedDeviceStatus.active);
      await insertDevice(
        'd-pending',
        status: PairedDeviceStatus.pendingConfirm,
      );
      await insertDevice('d-revoked', status: PairedDeviceStatus.revoked);
      final active = await db.pairedDeviceDao.watchActive().first;
      expect(active.map((d) => d.id), ['d-active']);
    });

    test('watchConnectable returns active + pending devices', () async {
      await insertDevice('d-active', status: PairedDeviceStatus.active);
      await insertDevice(
        'd-pending',
        status: PairedDeviceStatus.pendingConfirm,
      );
      await insertDevice('d-revoked', status: PairedDeviceStatus.revoked);
      final connectable = await db.pairedDeviceDao.watchConnectable().first;
      expect(connectable.map((d) => d.id).toSet(), {'d-active', 'd-pending'});
    });
  });

  group('PairedDeviceDao mutations', () {
    test('upsert replaces on conflict', () async {
      await insertDevice('d-1');
      await db.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion.insert(
          id: 'd-1',
          label: 'renamed',
          pskRef: 'psk-2',
        ),
      );
      final device = await db.pairedDeviceDao.getById('d-1');
      expect(device?.label, 'renamed');
      expect(device?.pskRef, 'psk-2');
    });

    test('setStatus updates the status', () async {
      await insertDevice('d-1');
      await db.pairedDeviceDao.setStatus('d-1', PairedDeviceStatus.active);
      expect(
        (await db.pairedDeviceDao.getById('d-1'))?.status,
        PairedDeviceStatus.active,
      );
    });

    test('confirm sets status active and the expiry', () async {
      await insertDevice('d-1');
      final expires = DateTime(2026, 12, 31);
      await db.pairedDeviceDao.confirm('d-1', expiresAt: expires);
      final device = await db.pairedDeviceDao.getById('d-1');
      expect(device?.status, PairedDeviceStatus.active);
      expect(device?.expiresAt, expires);
    });

    test(
      'requireReapproval drops to pendingConfirm with a fresh expiry',
      () async {
        await insertDevice('d-1', status: PairedDeviceStatus.active);
        final expires = DateTime(2026, 12, 31);
        await db.pairedDeviceDao.requireReapproval('d-1', expiresAt: expires);
        final device = await db.pairedDeviceDao.getById('d-1');
        expect(device?.status, PairedDeviceStatus.pendingConfirm);
        expect(device?.expiresAt, expires);
      },
    );

    test('setRemoteFingerprint pins the fingerprint (TOFU)', () async {
      await insertDevice('d-1');
      await db.pairedDeviceDao.setRemoteFingerprint('d-1', 'abc123');
      expect(
        (await db.pairedDeviceDao.getById('d-1'))?.remoteFingerprint,
        'abc123',
      );
    });

    test('markSeen records the connect timestamp', () async {
      await insertDevice('d-1');
      final now = DateTime(2026, 7, 1, 9);
      await db.pairedDeviceDao.markSeen('d-1', now);
      expect((await db.pairedDeviceDao.getById('d-1'))?.lastSeenAt, now);
    });

    test('setUserId binds a device to its owner', () async {
      await insertDevice('d-1');
      await db.pairedDeviceDao.setUserId('d-1', 'u-1');
      expect((await db.pairedDeviceDao.getById('d-1'))?.userId, 'u-1');
    });

    test('remove deletes the device', () async {
      await insertDevice('d-1');
      await db.pairedDeviceDao.remove('d-1');
      expect(await db.pairedDeviceDao.getById('d-1'), isNull);
    });

    test('watchForUser emits only that user devices', () async {
      await insertDevice('d-1', userId: 'u-1');
      await insertDevice('d-2', userId: 'u-2');
      final forUser = await db.pairedDeviceDao.watchForUser('u-1').first;
      expect(forUser.map((d) => d.id), ['d-1']);
    });
  });
}
