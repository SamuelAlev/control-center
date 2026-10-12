import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

void main() {
  late LocalRpcServer server;
  late Directory tmp;
  late String code;
  late String routeId;
  late String psk;
  late String fingerprint;
  var active = true;
  var redemptions = 0;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cc_secure_invite_');
    final identity = await ServerIdentityStore.load(tmp.path);
    fingerprint = identity.fingerprint;
    code = RemoteControlCrypto.generatePsk();
    final hash = InvitePairingProof.codeHash(code);
    routeId = InvitePairingProof.routeIdFromHash(hash);
    psk = InvitePairingProof.pskFromHash(hash);
    active = true;
    redemptions = 0;
    server = LocalRpcServer(
      identity: identity,
      dispatcher: _Dispatcher(),
      devicesDao: _Devices(),
      secrets: _Secrets(),
      eventBus: DomainEventBus(),
      workspaceResolver: (_) async => const [],
      invitePskResolver: (route) async =>
          route == routeId && active ? psk : null,
      inviteRedeemer: (body, {remoteIp}) async {
        redemptions++;
        if (!active || body['code'] != code) {
          throw StateError('not redeemable');
        }
        active = false;
        return {'device_id': 'device-1', 'psk': 'new-secret-device-psk'};
      },
      address: InternetAddress.loopbackIPv4,
      port: 0,
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    await tmp.delete(recursive: true);
  });

  Future<SecureChannelConnection> dial({String? pin, String? route}) async {
    final raw = await WsClientChannel.connect(
      Uri.parse('ws://127.0.0.1:${server.boundPort}/invites/secure'),
    );
    return connectSecureChannel(
      channel: raw,
      deviceId: 'invite:${route ?? routeId}',
      psk: psk,
      pinnedFingerprint: pin,
      timeout: const Duration(seconds: 3),
    );
  }

  test(
    'authenticates a random invite, encrypts PSK, then consumes it',
    () async {
      final connected = await dial(pin: fingerprint);
      try {
        final answer = connected.channel.incoming.first;
        await connected.channel.send({
          'type': 'invite_redeem',
          'code': code,
          'platform': 'web',
        });
        final frame = await answer;
        expect(frame['type'], 'invite_redeemed');
        expect((frame['result'] as Map)['psk'], 'new-secret-device-psk');
        expect(redemptions, 1);
      } finally {
        await connected.channel.close();
      }
      await expectLater(dial(), throwsA(isA<SecureHandshakeException>()));
      expect(redemptions, 1);
    },
  );

  test('wrong route and changed server pin fail before redemption', () async {
    await expectLater(
      dial(route: '0' * 64),
      throwsA(isA<SecureHandshakeException>()),
    );
    await expectLater(
      dial(pin: 'different-fingerprint'),
      throwsA(isA<ServerIdentityMismatchException>()),
    );
    expect(redemptions, 0);
  });

  test('a plaintext POST cannot redeem a real invite', () async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:${server.boundPort}/invites/redeem'),
      );
      request.write('{"code":"$code"}');
      final response = await request.close();
      await response.drain<void>();
      expect(response.statusCode, HttpStatus.upgradeRequired);
      expect(redemptions, 0);
    } finally {
      client.close(force: true);
    }
  });
}

class _Dispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

class _Secrets implements PairedDeviceSecretsPort {
  @override
  Future<String?> readPsk(String deviceId) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Devices implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();
  @override
  Future<PairedDevicesTableData?> getById(String id) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
