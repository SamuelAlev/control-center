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
import 'package:flutter_test/flutter_test.dart';
import '../helpers/seed_databases.dart';
import '../helpers/stage_server_natives.dart';

/// Fork A end-to-end: the desktop's thin-client boot path against the REAL
/// `cc_server` binary. Seed the database the way a paired desktop would, spawn
/// `cc_server` as a child process via [CcServerProcess], connect a real
/// [RemoteRpcClient] over the loopback endpoint it reports and read a seeded
/// ticket back over `repo/call`.
///
/// This proves the desktop CAN run as a thin client of a spawned local server —
/// the same cc_rpc/cc_data path the web build uses. It runs the server from
/// source through the repo's fvm-pinned Dart SDK; it is skipped (not failed)
/// when that SDK or the staged natives are not present (e.g. a CI image
/// without the .fvm checkout or a natives build), so it never blocks the
/// suite. The supervisor logic itself is covered deterministically by
/// test/core/server/cc_server_process_test.dart.
void main() {
  final repoRoot = Directory.current.path;
  // The SAME resolution the desktop uses, not a hardcoded `.fvm` path. This
  // test used to require `.fvm/flutter_sdk/bin/dart`, which no CI image has,
  // so it skipped on every CI run ever — the strongest proof that the desktop
  // can run as a thin client of a spawned local server never once executed
  // outside a developer's laptop.
  final dartExe = CcServerLauncher.devDartPath(repoRoot);
  final hasSdk =
      dartExe != null &&
      File('$repoRoot/apps/cc_server/bin/cc_server.dart').existsSync();

  // The dev-run path (`dart run apps/cc_server/bin/cc_server.dart`) needs the
  // repo's `build/natives` staging dir (or the `.cc_natives_prebuilt_dir`
  // pointer file): the cc_server BUILD HOOK refuses to build without it, so a
  // spawn on a runner without staged natives dies with exit 255 before the
  // ready banner. Skip in CI there (the e2e job stages them); locally the
  // hook's own actionable error is the loud failure the philosophy wants.
  final hookStagingAvailable =
      Directory('$repoRoot/build/natives').existsSync() ||
      File('$repoRoot/.cc_natives_prebuilt_dir').existsSync();
  final skipReason =
      !hasSdk
          ? 'no Dart SDK found to run cc_server from source'
          : !hookStagingAvailable && runningInCi
          ? 'natives not staged at build/natives on this CI runner; the '
              'cc_server build hook refuses to run without them (the e2e job '
              'stages them via scripts/natives/build_natives.sh)'
          : false;

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
      final seed = openSeedDatabases(tmp.path);
      await seed.seedWorkspace(workspaceId, name: 'Fork A');
      await DaoTicketRepository(
        seed.workspaces,
        seed.global.workspaceRouteDao,
      ).insert(
        Ticket(
          id: 'fa-1',
          workspaceId: workspaceId,
          title: 'Read over the spawned server',
          status: TicketStatus.open,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await seed.global.pairedDeviceDao.upsert(
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

      // --- The spawned server resolves natives from its --data-dir; without
      // staging, a source-run server fails its boot preflight (exit 255).
      await stageServerNatives(tmp.path);

      // --- Spawn the REAL cc_server via the SAME resolver the thin desktop
      // uses (CcServerLauncher.resolve → built binary, else dev `dart run`).
      final server = CcServerLauncher.resolve(
        dataDir: tmp.path,
        repoRoot: repoRoot,
        port: 0,
      );
      expect(server, isNotNull, reason: 'resolver found no runnable cc_server');
      final endpoint = await server!.start(
        // `dart run` from source compiles the whole server DAG before the
        // ready banner; a cold 2-core CI runner needs well over the default
        // 20s (observed >90s), so give the compile real room.
        timeout: const Duration(seconds: 150),
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
    timeout: const Timeout(Duration(minutes: 4)),
    skip: skipReason,
  );
}
