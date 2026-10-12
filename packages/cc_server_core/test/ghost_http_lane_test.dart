import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/booted_rpc.dart';
import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// The media byte endpoints verify membership for a CLIENT-SUPPLIED workspace
/// id. That lookup reads `workspace_members`, which lives in the workspace's
/// OWN database — so resolving it opens (and therefore CREATES) the file. The
/// `repo/call` + `sub/subscribe` chokepoints run the registry existence gate
/// first for exactly this reason; the HTTP lane must too.
void main() {
  if (!hostHasServerNatives) {
    return;
  }

  test('/workspace/logo with an unregistered workspace id materialises no '
      'ghost database', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_ghost_http');
    await stageServerNatives(tmp.path);
    addTearDown(() => deleteDirBestEffort(tmp));

    const deviceId = 'logo-device';
    final psk = RemoteControlCrypto.generatePsk();

    final seed = openSeedDatabases(tmp.path);
    await seed.global.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(deviceId),
        label: Value('logo lane'),
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

    // The stale id a client keeps in `active_workspace_id` after a data-dir
    // reset: this server has never registered it.
    const ghostId = 'ws-http-ghost';
    final sig = RemoteControlCrypto.signProxyTarget(
      'workspace-logo:$ghostId',
      psk,
    );

    final client = await connectBootedServer(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final uri = Uri(
      path: '/workspace/logo',
      queryParameters: {'w': ghostId, 'd': deviceId, 's': sig},
    );
    final response = await client.resources.request('GET', uri);
    await response.body.drain<void>();
    expect(response.statusCode, HttpStatus.forbidden);

    // A raw HTTP request must not bypass the authenticated resource tunnel.
    final publicHttp = HttpClient();
    addTearDown(() => publicHttp.close(force: true));
    final publicResponse = await (await publicHttp.getUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}').resolveUri(uri),
    )).close();
    await publicResponse.drain<void>();
    expect(publicResponse.statusCode, HttpStatus.upgradeRequired);

    expect(
      Directory('${tmp.path}/$ghostId').existsSync(),
      isFalse,
      reason:
          'the membership lookup opened the named workspace database before '
          'anything checked the registry',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
