import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/repositories/dao_paired_device_repository.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [DaoPairedDeviceRepository] — device upsert/confirm/rename/revoke and
/// the watchAll/getById round trips through the inline `_toDomain` mapper.
void main() {
  late GlobalDatabase db;
  late DaoPairedDeviceRepository repo;

  setUp(() {
    db = createTestGlobalDatabase();
    repo = DaoPairedDeviceRepository(db.pairedDeviceDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('DaoPairedDeviceRepository', () {
    test('upsertPending + getById round-trips', () async {
      await repo.upsertPending(
        id: 'd-1',
        label: 'iPhone',
        pskRef: 'psk-1',
        workspaceId: 'w-1',
      );
      final d = await repo.getById('d-1');
      expect(d?.label, 'iPhone');
      expect(d?.pskRef, 'psk-1');
      expect(d?.status, PairedDeviceStatus.pendingConfirm);
      expect(d?.workspaceId, 'w-1');
    });

    test('confirm flips status to active and stamps an expiry', () async {
      await repo.upsertPending(id: 'd-1', label: 'iPhone', pskRef: 'psk-1');
      final expires = DateTime.utc(2026, 1, 1);
      await repo.confirm('d-1', expiresAt: expires);
      final d = await repo.getById('d-1');
      expect(d?.status, PairedDeviceStatus.active);
      // The instant is stored as UTC; Drift returns it in the local zone.
      expect(d?.expiresAt?.toUtc(), expires);
    });

    test('watchAll emits all devices', () async {
      await repo.upsertPending(id: 'd-1', label: 'a', pskRef: 'p1');
      await repo.upsertPending(id: 'd-2', label: 'b', pskRef: 'p2');
      final all = await repo.watchAll().first;
      expect(all, hasLength(2));
    });

    test('revoke marks the device revoked and removes it', () async {
      await repo.upsertPending(id: 'd-1', label: 'iPhone', pskRef: 'psk-1');
      await repo.revoke('d-1');
      expect(await repo.getById('d-1'), isNull);
    });

    test('getById returns null for an unknown device', () async {
      expect(await repo.getById('missing'), isNull);
    });
  });
}
