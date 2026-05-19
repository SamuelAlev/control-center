@TestOn('!windows')
@Tags(['integration'])
library;

import 'dart:io';

import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:control_center/core/server/cc_server_process.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

/// Fork A end-to-end: the desktop's thin-client boot path against the REAL
/// `cc_server` binary. Seed the database the way a paired desktop would, spawn
/// `cc_server` as a child process via [CcServerProcess], connect a real
/// [RemoteRpcClient] over the loopback endpoint it reports, and read a seeded
/// ticket back over `repo/call`.
///
/// This proves the desktop CAN run as a thin client of a spawned local server —
/// the same cc_rpc/cc_data path the web build uses. It runs the server from
/// source through the repo's fvm-pinned Dart SDK; it is skipped (not failed)
/// when that SDK is not present (e.g. a CI image without the .fvm checkout), so
/// it never blocks the suite. The supervisor logic itself is covered
/// deterministically by test/core/server/cc_server_process_test.dart.
void main() {
  final repoRoot = Directory.current.path;
  final dartExe = '$repoRoot/.fvm/flutter_sdk/bin/dart';
  final hasSdk = File(dartExe).existsSync() &&
      File('$repoRoot/apps/cc_server/bin/cc_server.dart').existsSync();

  test(
    'desktop spawns cc_server and reads a seeded ticket over loopback RPC',
    () async {
      final tmp = Directory.systemTemp.createTempSync('fork_a');
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'desktop-thin-local';
      const psk = 'fork-a-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-fork-a';

      // --- Seed exactly as the desktop thin boot would (one-time, pre-spawn,
      // so there is never two-process access to the same SQLite file).
      final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
      await seed.workspaceDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Fork A'),
        ),
      );
      await DaoTicketRepository(seed.ticketDao).insert(
        Ticket(
          id: 'fa-1',
          workspaceId: workspaceId,
          title: 'Read over the spawned server',
          status: TicketStatus.open,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await seed.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('fork-a'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      // --- Spawn the REAL cc_server via the SAME resolver the thin desktop
      // uses (CcServerLauncher.resolve → built binary, else dev `dart run`).
      final server = CcServerLauncher.resolve(
        dataDir: tmp.path,
        repoRoot: repoRoot,
        port: 0,
      );
      expect(server, isNotNull, reason: 'resolver found no runnable cc_server');
      final endpoint = await server!.start(
        timeout: const Duration(seconds: 90),
      );
      addTearDown(server.stop);

      // --- Connect a real client over the loopback endpoint and read tickets.
      final client = await connectRemoteRpc(
        uri: endpoint.rpcUri,
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      client.activeWorkspaceId = workspaceId;

      final data = await client.call('tickets.list', const {});
      final tickets = (data['tickets'] as List).cast<Map<String, dynamic>>();

      expect(tickets, hasLength(1));
      expect(tickets.single['ticket_id'], 'fa-1');
      expect(tickets.single['title'], 'Read over the spawned server');
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: hasSdk ? false : 'fvm Dart SDK not present at $dartExe',
  );
}
