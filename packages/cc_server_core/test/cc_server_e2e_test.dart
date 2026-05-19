import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:drift/drift.dart' show Value;
import 'package:test/test.dart';

/// End-to-end proof of the pure-Dart server: seed a real database, boot the
/// actual [runCcServer] composition, connect a real RPC client through the full
/// PSK handshake, and read a seeded ticket back over `repo/call`.
void main() {
  test('RPC client reads a seeded ticket from the running pure-Dart cc_server',
      () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_e2e');
    addTearDown(() => tmp.deleteSync(recursive: true));

    const deviceId = 'web-test-device';
    const psk = 'test-psk-please-and-thank-you-0123456789';
    const workspaceId = 'ws-alpha';

    // --- Seed the server's DB + secrets exactly as a paired device would exist.
    final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
    await seed.workspaceDao.upsertWorkspace(
      const WorkspacesTableCompanion(
        id: Value(workspaceId),
        name: Value('Alpha'),
      ),
    );
    await DaoTicketRepository(seed.ticketDao).insert(
      Ticket(
        id: 't1',
        workspaceId: workspaceId,
        title: 'Seeded over the wire',
        status: TicketStatus.open,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await seed.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(deviceId),
        workspaceId: Value(workspaceId),
        label: Value('e2e'),
        pskRef: Value('file'),
        status: Value(PairedDeviceStatus.active),
      ),
    );
    await seed.close();
    await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

    // --- Boot the REAL pure-Dart server on an ephemeral loopback port.
    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    // --- Connect a real client through the PSK handshake and read tickets.
    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    await client.initialize();
    client.activeWorkspaceId = workspaceId;

    final data = await client.call('tickets.list', const {});
    final tickets = (data['tickets'] as List).cast<Map<String, dynamic>>();

    expect(tickets, hasLength(1));
    expect(tickets.single['ticket_id'], 't1');
    expect(tickets.single['title'], 'Seeded over the wire');
    expect(tickets.single['workspace_id'], workspaceId);
  });

  test(
    'an active device with no stored PSK is rejected fast with a clear message',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_denied_e2e');
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'unpaired-device';
      const workspaceId = 'ws-alpha';

      // Seed an ACTIVE device row but never write its PSK — exactly the server's
      // "row=active, psk=missing" state (a device that was registered but never
      // had a pairing key minted/stored for it).
      final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
      await seed.workspaceDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      await seed.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('unpaired'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      // The client must fail fast with the explicit "rejected" message (via the
      // server's `auth_denied` frame), NOT stall until the handshake timeout and
      // surface an opaque "Server did not complete auth".
      await expectLater(
        connectRemoteRpc(
          uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
          deviceId: deviceId,
          psk: 'whatever-the-user-typed-0123456789',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('rejected'),
          ),
        ),
      );
    },
  );

  test(
    'a fullClient mints a pairing and a SECOND client connects with it; a '
    'phone-tier device is denied pairing.mint (capability gate)',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_pair_e2e');
      addTearDown(() => tmp.deleteSync(recursive: true));

      const adminId = 'web-admin';
      const adminPsk = 'admin-psk-please-and-thank-you-0123456789';
      const phoneId = 'phone-device';
      const phonePsk = 'phone-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-alpha';

      final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
      await seed.workspaceDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      // A first-party web client (platform 'web' → fullClient) ...
      await seed.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(adminId),
          workspaceId: Value(workspaceId),
          label: Value('admin'),
          platform: Value('web'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      // ... and a phone (platform 'ios' → restricted).
      await seed.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(phoneId),
          workspaceId: Value(workspaceId),
          label: Value('phone'),
          platform: Value('ios'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      final secrets = FileSecretsStore(dataDir: tmp.path);
      await secrets.writePsk(adminId, adminPsk);
      await secrets.writePsk(phoneId, phonePsk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);
      final url = Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc');

      // The fullClient mints a pairing for a NEW desktop client.
      final admin = await connectRemoteRpc(
        uri: url,
        deviceId: adminId,
        psk: adminPsk,
      );
      addTearDown(admin.close);
      await admin.initialize();
      admin.activeWorkspaceId = workspaceId;

      final minted = await admin.call('pairing.mint', {
        'label': 'New laptop',
        'platform': 'desktop',
      });
      final newDeviceId = minted['device_id'] as String;
      final newPsk = minted['psk'] as String;
      expect(newDeviceId, isNotEmpty);
      expect(newPsk, isNotEmpty);
      expect(minted['platform'], 'desktop');

      // The newly-paired client connects to the SAME running server and drives
      // a working session.
      final second = await connectRemoteRpc(
        uri: url,
        deviceId: newDeviceId,
        psk: newPsk,
      );
      addTearDown(second.close);
      await second.initialize();
      second.activeWorkspaceId = workspaceId;
      final listed = await second.call('pairing.list', const {});
      final ids = (listed['devices'] as List)
          .map((d) => (d as Map)['device_id'])
          .toSet();
      expect(ids, containsAll(<String>[adminId, phoneId, newDeviceId]));

      // The phone (restricted) is DENIED pairing.mint by the capability gate,
      // even though it authenticated and is bound to a workspace.
      final phone = await connectRemoteRpc(
        uri: url,
        deviceId: phoneId,
        psk: phonePsk,
      );
      addTearDown(phone.close);
      await phone.initialize();
      phone.activeWorkspaceId = workspaceId;
      await expectLater(
        phone.call('pairing.mint', {'label': 'sneaky'}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.unauthorized,
          ),
        ),
      );
    },
  );

  test(
    'image proxy gates: rejects missing params, bad signatures, and SSRF targets',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_proxy_e2e');
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'web-proxy-device';
      const psk = 'proxy-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-alpha';

      final seed = AppDatabase(openServerDatabase(dataDir: tmp.path));
      await seed.workspaceDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      await seed.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('proxy'),
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

      final base = 'http://127.0.0.1:${server.rpc.boundPort}';
      final http = HttpClient();
      addTearDown(() => http.close(force: true));

      Future<int> statusOf(Uri uri) async {
        final resp = await (await http.getUrl(uri)).close();
        await resp.drain<void>();
        return resp.statusCode;
      }

      Uri proxyUri(String target, String signature) =>
          Uri.parse(base).replace(
            path: '/proxy/media',
            queryParameters: {
              'u': base64Url.encode(utf8.encode(target)),
              'd': deviceId,
              's': signature,
            },
          );

      // Missing the required query params → 400.
      expect(await statusOf(Uri.parse('$base/proxy/media')), 400);

      // A well-formed request whose signature does not match the PSK → 403
      // (the endpoint is not an open relay).
      expect(
        await statusOf(
          proxyUri('https://images.example.com/cover.jpg', 'not-the-signature'),
        ),
        403,
      );

      // A correctly-signed request whose TARGET is the cloud-metadata endpoint
      // is refused by the SSRF guard — even though auth passes → 403, and no
      // outbound fetch is made.
      const ssrf = 'http://169.254.169.254/latest/meta-data/';
      expect(
        await statusOf(
          proxyUri(ssrf, RemoteControlCrypto.signProxyTarget(ssrf, psk)),
        ),
        403,
      );
    },
  );
}
