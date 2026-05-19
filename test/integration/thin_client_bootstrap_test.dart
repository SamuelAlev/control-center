@TestOn('!windows')
@Tags(['integration'])
library;

import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/cc_server_process.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

/// Verifies the THIN-CLIENT BOOT FLIP's auth path end-to-end: the desktop does
/// NOT pre-seed the database (it no longer opens it). Instead it spawns
/// `cc_server` with a one-time device id + PSK in the environment; the server
/// provisions that as an active paired device on boot, and the desktop connects
/// over loopback with the same credentials. This exercises exactly what
/// `startThinClientBackend()` does (minus path_provider), so it proves the
/// bootstrap-provisioning code in `cc_server_runtime` actually authenticates.
///
/// Runs the server from source via the repo's fvm-pinned Dart SDK; skipped (not
/// failed) when that SDK is absent so it never blocks CI.
void main() {
  final repoRoot = Directory.current.path;
  final dartExe = '$repoRoot/.fvm/flutter_sdk/bin/dart';
  final hasSdk = File(dartExe).existsSync() &&
      File('$repoRoot/apps/cc_server/bin/cc_server.dart').existsSync();

  test(
    'desktop spawns cc_server, server provisions the bootstrap device, '
    'desktop connects over loopback with no pre-seeded DB',
    () async {
      final tmp = Directory.systemTemp.createTempSync('thin_boot');
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'desktop-thin-local';
      const psk = 'thin-boot-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-thin';

      // Seed ONLY a workspace (so the scoped read has something) — but NOT the
      // paired device or PSK: those come from the server's env-based bootstrap
      // provisioning, which is the code path under test.
      final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
      await seed.workspaceDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Thin'),
        ),
      );
      await seed.close();

      // Spawn the REAL cc_server with the bootstrap credentials in the env —
      // exactly as startThinClientBackend() does.
      final server = CcServerLauncher.resolve(
        dataDir: tmp.path,
        repoRoot: repoRoot,
        port: 0,
        environment: const {
          'CC_BOOTSTRAP_DEVICE_ID': deviceId,
          'CC_BOOTSTRAP_PSK': psk,
        },
      );
      expect(server, isNotNull, reason: 'resolver found no runnable cc_server');
      final endpoint = await server!.start(
        timeout: const Duration(seconds: 90),
      );
      addTearDown(server.stop);

      // Connect with the bootstrap credentials. This only succeeds if the server
      // provisioned the device (active) + wrote the PSK on boot.
      final client = await connectRemoteRpc(
        uri: endpoint.rpcUri,
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);

      // Auth succeeded if we got here. Exercise a scoped read to confirm the
      // session is live (tickets.list is the op fork_a proves end-to-end). The
      // server is stateless, so the client carries the workspace into the call.
      client.activeWorkspaceId = workspaceId;
      final data = await client.call('tickets.list', const {});
      expect(data['tickets'], isA<List<dynamic>>());
    },
    skip: hasSdk ? false : 'fvm Dart SDK not present — integration test skipped',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
