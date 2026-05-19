import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// First-run regression: a FRESH data dir (zero workspaces; the identity
/// bootstrap mints the first user at boot) must let the connected client run
/// the whole onboarding flow WITHOUT a server restart.
///
/// Guards the `workspace.upsert` create path: the creating principal becomes
/// the workspace owner (ownerUserId + an owner membership row) in the same op.
/// Before that fix the freshly created workspace had no members, so
/// `session/list_workspaces` stayed empty and every workspace-scoped op the
/// creator issued next was denied with "Not a member of this workspace" until
/// the next boot's `IdentityBootstrap` backfill repaired it.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; '
          'cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test(
    'fresh server: creating the first workspace makes it usable immediately',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_fresh');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'web-test-device';
      const psk = 'test-psk-please-and-thank-you-0123456789';

      // Seed ONLY an orphan paired device (no workspace, no user) — the state
      // of a brand-new install. Boot mints the owner and binds the device.
      final seed = openSeedDatabases(tmp.path);
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          label: Value('fresh-boot test'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();

      // The onboarding gate's inputs on a fresh server: no workspaces yet.
      expect(await client.listWorkspaces(), isEmpty);
      final snapshot = await client
          .subscribe('workspace.watchAll', const {})
          .first
          .timeout(const Duration(seconds: 10));
      expect(snapshot['workspaces'], isEmpty);

      // Create the first workspace exactly the way onboarding does.
      final created = await client.call('workspace.upsert', {
        'workspace': {'id': 'ws-fresh', 'name': 'Fresh'},
      });
      expect(created['workspace_id'], 'ws-fresh');

      // The creator is a member: the membership-scoped session list sees it…
      final visible = await client.listWorkspaces();
      expect(visible.map((w) => w['id']), contains('ws-fresh'));

      // …the row carries the creator as owner…
      final all = await client
          .subscribe('workspace.watchAll', const {})
          .first
          .timeout(const Duration(seconds: 10));
      final row = (all['workspaces'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((w) => w['id'] == 'ws-fresh');
      expect(row['owner_user_id'], isNotNull);

      // …and workspace-scoped ops work immediately (no restart needed).
      client.activeWorkspaceId = 'ws-fresh';
      final tickets = await client.call('tickets.list', const {});
      expect(tickets['tickets'], isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'stale workspace id is refused without materialising a ghost database',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_ghost');
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'ghost-test-device';
      const psk = 'test-psk-please-and-thank-you-0123456789';

      // Same fresh-install state as above: an orphan paired device, no user,
      // no workspace. The client below acts as one whose persisted active
      // workspace id predates the data-dir reset — the id is stale: nothing
      // on this server ever registered it.
      final seed = openSeedDatabases(tmp.path);
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          label: Value('ghost-id test'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();

      // A workspace-scoped op naming an unregistered workspace is refused as
      // not-found BEFORE the membership lookup — that lookup opens the named
      // workspace's database, and opening CREATES the file.
      await expectLater(
        client.call('tickets.list', const {'workspace_id': 'ws-ghost'}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.notFound,
          ),
        ),
      );

      // A workspace-scoped subscription is refused the same way: the
      // subscribe ack lands first, then the refusal arrives as the stream's
      // first (error) event — its handler never ran.
      await expectLater(
        client.subscribe('tickets.watchForWorkspace', const {
          'workspace_id': 'ws-ghost',
        }).first,
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.notFound,
          ),
        ),
      );

      // The point of the gate: no ghost workspace database was materialised
      // (previously each request created `<dataDir>/ws-ghost/workspace.db`).
      expect(Directory('${tmp.path}/ws-ghost').existsSync(), isFalse);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
