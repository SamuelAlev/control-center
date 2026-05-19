import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

CcServerConfig configFor(String dataDir) =>
    CcServerConfig.resolve(['--data-dir', dataDir, '--port', '1']);

void main() {
  group('pairDevice', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('pair_device_test');
    });

    tearDown(() {
      if (tmp.existsSync()) {
        tmp.deleteSync(recursive: true);
      }
    });

    Future<GlobalDatabase> openDb() async =>
        GlobalDatabase(openGlobalDatabase(dataDir: tmp.path));

    test('a fresh data dir pairs WITHOUT creating a workspace', () async {
      final result = await pairDevice(config: configFor(tmp.path));
      expect(result.deviceId, 'web-client');
      expect(result.psk, isNotEmpty);

      final db = await openDb();
      try {
        // Onboarding owns first-workspace creation — pairing must stay out.
        expect(await db.workspaceRegistryDao.getAll(), isEmpty);
        final device = await db.pairedDeviceDao.getById('web-client');
        expect(device, isNotNull);
        expect(device!.status, PairedDeviceStatus.active);
        expect(device.workspaceId, isNull);
        // The owner is still minted and bound to the device.
        expect(device.userId, isNotNull);
      } finally {
        await db.close();
      }
    });

    test('an existing workspace is bound, never duplicated', () async {
      final seed = await openDb();
      await seed.workspaceRegistryDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value('ws-existing'),
          name: Value('Mine'),
        ),
      );
      await seed.close();

      await pairDevice(config: configFor(tmp.path));

      final db = await openDb();
      try {
        final workspaces = await db.workspaceRegistryDao.getAll();
        expect(workspaces.map((w) => w.id), ['ws-existing']);
        final device = await db.pairedDeviceDao.getById('web-client');
        expect(device!.workspaceId, 'ws-existing');
      } finally {
        await db.close();
      }
    });

    test('re-running rotates the PSK and still creates no workspace', () async {
      final first = await pairDevice(config: configFor(tmp.path));
      final second = await pairDevice(config: configFor(tmp.path));
      expect(second.psk, isNot(first.psk));

      final db = await openDb();
      try {
        expect(await db.workspaceRegistryDao.getAll(), isEmpty);
      } finally {
        await db.close();
      }
    });
  });
}
