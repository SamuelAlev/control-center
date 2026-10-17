import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/relay/remote_relay_host.dart';
import 'package:cc_signaling_server/cc_signaling_server.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

const _deviceId = 'policy-device';
const _timeout = Duration(seconds: 3);
final _psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));

class _Secrets implements PairedDeviceSecretsPort {
  int readCount = 0;

  @override
  Future<String?> readPsk(String deviceId) async {
    readCount++;
    return deviceId == _deviceId ? _psk : null;
  }

  @override
  Future<bool> writePsk(String deviceId, String psk) async => false;

  @override
  Future<void> deletePsk(String deviceId) async {}
}

class _UnusedDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      {};
}

Future<ServerIdentity> _identity() async {
  final seed = await ServerIdentityCrypto.generateSeed();
  final public = await ServerIdentityCrypto.publicKeyFromSeed(seed);
  return ServerIdentity(
    serverId: 'test-server',
    seedB64: seed,
    publicKeyB64: public,
    fingerprint: ServerIdentityCrypto.fingerprintOf(public),
    relayRoom: RemoteControlCrypto.generateRoomCode(),
    relayOwnerToken: RemoteControlCrypto.generatePsk(),
    serverName: 'Policy test',
  );
}

void main() {
  late GlobalDatabase db;
  late ServerIdentity identity;
  final secrets = _Secrets();

  setUp(() async {
    secrets.readCount = 0;
    db = createTestGlobalDatabase();
    identity = await _identity();
  });
  tearDown(() async => db.close());

  Future<void> seedDevice({
    required DateTime pairedAt,
    DateTime? lastSeenAt,
  }) async {
    await db.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(_deviceId),
        userId: const Value('user-1'),
        label: const Value('Policy client'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        pairedAt: Value(pairedAt),
        lastSeenAt: Value(lastSeenAt),
      ),
    );
  }

  Future<void> deniedBeforePsk(
    Future<({int maxAgeMinutes, int idleTimeoutMinutes})> Function() policy,
  ) async {
    final lastSeen = (await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt;
    final (server, client) = InProcessRpcChannel.pair();
    final accepted = authenticatePairedPeer(
      server,
      devicesDao: db.pairedDeviceDao,
      secrets: secrets,
      identity: identity,
      sessionPolicy: policy,
      timeout: _timeout,
    );
    final connected = authenticateRemoteChannel(
      channel: client,
      deviceId: _deviceId,
      psk: _psk,
      timeout: _timeout,
    );
    await expectLater(connected, throwsA(isA<AuthRejectedException>()));
    expect(await accepted, isNull);
    expect(server.isOpen, isFalse);
    expect(client.isOpen, isFalse);
    expect(secrets.readCount, 0);
    expect((await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt, lastSeen);
  }

  test(
    'max-age refuses direct Noise admission without refreshing lastSeen',
    () async {
      final old = DateTime.now().subtract(const Duration(days: 2));
      await seedDevice(pairedAt: old, lastSeenAt: DateTime.now());
      await deniedBeforePsk(
        () async => (maxAgeMinutes: 60, idleTimeoutMinutes: 0),
      );
    },
  );

  test(
    'idle limit refuses direct Noise admission without reviving lastSeen',
    () async {
      final stale = DateTime.now().subtract(const Duration(hours: 2));
      await seedDevice(
        pairedAt: stale.subtract(const Duration(days: 1)),
        lastSeenAt: stale,
      );
      await deniedBeforePsk(
        () async => (maxAgeMinutes: 0, idleTimeoutMinutes: 30),
      );
    },
  );

  test(
    'policy tightened after Noise rejects and never revives lastSeen',
    () async {
      final stale = DateTime.now().subtract(const Duration(hours: 2));
      await seedDevice(
        pairedAt: stale.subtract(const Duration(days: 1)),
        lastSeenAt: stale,
      );
      final before = (await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt;
      final secondRead = Completer<void>();
      final releaseRead = Completer<void>();
      var reads = 0;
      Future<({int maxAgeMinutes, int idleTimeoutMinutes})> policy() async {
        if (++reads == 1) {
          return (maxAgeMinutes: 0, idleTimeoutMinutes: 0);
        }
        secondRead.complete();
        await releaseRead.future;
        return (maxAgeMinutes: 0, idleTimeoutMinutes: 30);
      }

      final (server, client) = InProcessRpcChannel.pair();
      final accepted = authenticatePairedPeer(
        server,
        devicesDao: db.pairedDeviceDao,
        secrets: secrets,
        identity: identity,
        sessionPolicy: policy,
        timeout: _timeout,
      );
      final connected = await connectSecureChannel(
        channel: client,
        deviceId: _deviceId,
        psk: _psk,
        timeout: _timeout,
      );
      await secondRead.future.timeout(_timeout);
      expect(connected.channel.isOpen, isTrue);
      releaseRead.complete();
      expect(await accepted, isNull);
      expect(reads, 2);
      expect(connected.channel.isOpen, isFalse);
      expect(client.isOpen, isFalse);
      expect((await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt, before);
    },
  );

  test('policy provider failure fails closed before PSK admission', () async {
    final stale = DateTime.now().subtract(const Duration(hours: 2));
    await seedDevice(pairedAt: stale, lastSeenAt: stale);
    final before = (await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt;
    await deniedBeforePsk(() async => throw StateError('settings unavailable'));
    expect((await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt, before);
  });

  test('relay host forwards the policy to its secure admission gate', () async {
    final stale = DateTime.now().subtract(const Duration(hours: 2));
    await seedDevice(
      pairedAt: stale.subtract(const Duration(days: 1)),
      lastSeenAt: stale,
    );
    final before = (await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt;
    final broker = await serveSignaling(host: 'localhost', port: 0);
    addTearDown(broker.close);
    final url = 'ws://localhost:${broker.port}/signal';
    var reads = 0;
    final host = RemoteRelayHost(
      signalingUrl: url,
      identity: identity,
      dispatcher: _UnusedDispatcher(),
      devicesDao: db.pairedDeviceDao,
      secrets: secrets,
      eventBus: DomainEventBus(),
      workspaceResolver: (_) async => [],
      sessionPolicy: () async {
        reads++;
        return (maxAgeMinutes: 0, idleTimeoutMinutes: 30);
      },
    );
    await host.start();
    addTearDown(host.stop);
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: identity.relayRoom,
      deviceId: _deviceId,
      psk: _psk,
    );
    addTearDown(client.close);
    await expectLater(
      authenticateRemoteChannel(
        channel: client,
        deviceId: _deviceId,
        psk: _psk,
        timeout: _timeout,
      ),
      throwsA(isA<AuthRejectedException>()),
    );
    expect(reads, greaterThanOrEqualTo(1));
    expect(host.sessionCount, 0);
    expect((await db.pairedDeviceDao.getById(_deviceId))!.lastSeenAt, before);
  });
}
