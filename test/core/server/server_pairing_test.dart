@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart' show WsRemoteTransport;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/invite_redeemer.dart'
    show InviteRejectedException;
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

class _PairedServer {
  _PairedServer(this.http, this.seed, this.publicKey);

  final HttpServer http;
  final String seed;
  final String publicKey;
  final channels = <WsRemoteTransport>[];
  String psk = RemoteControlCrypto.generatePsk();
  bool available = true;

  String get fingerprint => ServerIdentityCrypto.fingerprintOf(publicKey);
  String get url => 'ws://127.0.0.1:${http.port}/rpc';

  ServerEntry get entry => ServerEntry(
    descriptor: ConnectionDescriptor(
      serverId: 'saved-server',
      serverName: 'Saved server',
      fingerprint: fingerprint,
      paths: [LoopbackPath(port: http.port)],
    ),
    deviceId: 'saved-device',
  );

  static Future<_PairedServer> start() async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final server = _PairedServer(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      seed,
      await ServerIdentityCrypto.publicKeyFromSeed(seed),
    );
    server.http.listen(server._handle);
    return server;
  }

  Future<void> _handle(HttpRequest request) async {
    if (!available) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
    if (request.uri.path == '/healthz') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'serverId': entry.serverId,
          'serverName': entry.name,
          'fingerprint': fingerprint,
        }),
      );
      await request.response.close();
      return;
    }
    if (request.uri.path != '/rpc' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final channel = WsRemoteTransport(
      await WebSocketTransformer.upgrade(request),
    )..start();
    channels.add(channel);
    try {
      final accepted = await acceptSecureChannel(
        channel: channel,
        readPsk: (deviceId) async => deviceId == entry.deviceId ? psk : null,
        serverPublicKey: publicKey,
        signIdentity: (challenge) =>
            ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
        timeout: const Duration(seconds: 5),
      );
      accepted.channel.incoming.listen((frame) {
        final params = frame['params'] as Map?;
        final Map<String, dynamic> result;
        if (frame['method'] == 'initialize') {
          result = {'capabilities': <String, dynamic>{}};
        } else if (frame['method'] == 'repo/call' &&
            params?['op'] == 'identity.me') {
          result = {
            'data': {
              'user': {'id': 'saved-user'},
              'memberships': <dynamic>[],
            },
          };
        } else {
          return;
        }
        unawaited(
          accepted.channel.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': result,
          }),
        );
      });
      await accepted.channel.send({'type': 'approved'});
    } on SecureHandshakeException {
      await channel.close();
    }
  }

  Future<void> close() async {
    for (final channel in channels) {
      await channel.close();
    }
    await http.close(force: true);
  }
}

void main() {
  late _PairedServer server;
  late ServerConnectionStore store;

  setUp(() async {
    server = await _PairedServer.start();
    store = ServerConnectionStore(
      AppPreferences.inMemory(),
      SecureStore.inMemory(),
    );
    await store.upsertEntry(server.entry, psk: server.psk);
  });

  tearDown(() => server.close());

  Future<RemoteServerConnection> connect({
    String? url,
    String psk = '',
    String inviteCode = '',
    String deviceId = 'saved-device',
  }) => pairWithServer(
    store: store,
    rawUrl: url ?? server.url,
    platform: 'desktop',
    deviceId: deviceId,
    inviteCode: inviteCode,
    psk: psk,
  );

  test(
    'retries after an outage with the saved credential and identity',
    () async {
      final saved = store.entry(server.entry.serverId)!;
      server.available = false;
      await expectLater(connect(), throwsA(anything));
      expect(await store.readPsk(saved.serverId), server.psk);
      expect(store.entry(saved.serverId), saved);

      server.available = true;
      final connection = await connect(deviceId: 'unrelated-form-default');
      addTearDown(connection.dispose);

      final identity = await connection.client.call('identity.me', const {});
      expect(identity['user'], {'id': 'saved-user'});
      expect(connection.entry.deviceId, saved.deviceId);
      expect(connection.supervisor.pinnedFingerprint, saved.pinnedFingerprint);
      expect(store.entry(saved.serverId)!.pairedAt, saved.pairedAt);
      expect(await store.readPsk(saved.serverId), server.psk);
      expect(store.readMode(), ServerConnectionMode.remote);
      expect(store.readActiveServerId(), saved.serverId);
    },
  );

  test(
    'matches a normalized URL instead of borrowing the active server',
    () async {
      await store.upsertEntry(
        ServerEntry(
          descriptor: ConnectionDescriptor(
            serverId: 'other-server',
            serverName: 'Other server',
            fingerprint: 'other-pin',
            paths: const [LoopbackPath(port: 1)],
          ),
          deviceId: 'other-device',
        ),
        psk: RemoteControlCrypto.generatePsk(),
      );
      await store.setActiveServer('other-server');

      final connection = await connect(
        url: 'http://127.0.0.1:${server.http.port}',
      );
      addTearDown(connection.dispose);

      final identity = await connection.client.call('identity.me', const {});
      expect(identity['user'], {'id': 'saved-user'});
      expect(store.readActiveServerId(), server.entry.serverId);
    },
  );

  test('does not reuse credentials for a different RPC endpoint', () async {
    await expectLater(connect(url: '${server.url}/other'), throwsA(anything));

    expect(await store.readPsk(server.entry.serverId), server.psk);
    expect(store.readActiveServerId(), isNull);
  });

  test(
    'an explicit key replaces the saved credential after verification',
    () async {
      server.psk = RemoteControlCrypto.generatePsk();

      final connection = await connect(psk: server.psk);
      addTearDown(connection.dispose);

      final identity = await connection.client.call('identity.me', const {});
      expect(identity['user'], {'id': 'saved-user'});
      expect(await store.readPsk(server.entry.serverId), server.psk);
    },
  );

  test(
    'an explicit invite is not ignored in favor of saved credentials',
    () async {
      await expectLater(
        connect(inviteCode: 'invalid-invite'),
        throwsA(isA<InviteRejectedException>()),
      );

      expect(await store.readPsk(server.entry.serverId), server.psk);
      expect(store.readActiveServerId(), isNull);
    },
  );

  test('a saved identity pin is not replaced by a new health probe', () async {
    final saved = server.entry.withPin('0' * 64);
    await store.upsertEntry(saved);

    await expectLater(
      connect(),
      throwsA(isA<ServerIdentityMismatchException>()),
    );

    expect(store.entry(saved.serverId), saved);
    expect(await store.readPsk(saved.serverId), server.psk);
    expect(store.readActiveServerId(), isNull);
  });

  test(
    'a missing saved key keeps the pairing available for new credentials',
    () async {
      final saved = server.entry;
      await store.upsertEntry(saved, psk: '');

      await expectLater(connect(), throwsStateError);
      expect(store.entry(saved.serverId), saved);
      expect(await store.readPsk(saved.serverId), isNull);

      final connection = await connect(psk: server.psk);
      addTearDown(connection.dispose);
      expect(await store.readPsk(saved.serverId), server.psk);
    },
  );
}
