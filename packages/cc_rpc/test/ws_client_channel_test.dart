import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/channel/secure_channel_handshake.dart';
import 'package:cc_rpc/src/channel/ws_client_channel.dart';
import 'package:cc_rpc/src/client/remote_channel_auth.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';
import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:test/test.dart';

/// The server half is a real loopback WebSocket. Only the application handler
/// differs between raw transport tests and tests that run the secure handshake.
class _SocketServer {
  _SocketServer._(this._server) {
    _server.listen((request) async {
      if (request.uri.path != '/rpc' ||
          !WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      final channel = _ServerSocketChannel(socket);
      _channels.add(channel);
      paths.add(request.uri.path);
      onConnection(channel);
    });
  }

  static Future<_SocketServer> start() async =>
      _SocketServer._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final List<_ServerSocketChannel> _channels = [];
  final List<String> paths = [];
  void Function(_ServerSocketChannel) onConnection = (_) {};
  bool _closed = false;

  Uri get uri => Uri.parse('ws://127.0.0.1:${_server.port}/rpc');

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final channel in _channels) {
      await channel.close();
    }
    await _server.close(force: true);
  }
}

class _ServerSocketChannel implements RemoteRpcChannelPort {
  _ServerSocketChannel(this._socket) {
    _socket.listen(
      (data) {
        if (data is! String) return;
        wireFrames.add(data);
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) _incoming.add(decoded);
        } on FormatException {
          // This fixture only observes client writes; the client adapter
          // separately rejects malformed records arriving from the server.
        }
      },
      onDone: _markClosed,
      onError: (Object _) => _markClosed(),
    );
  }

  final WebSocket _socket;
  final wireFrames = <String>[];
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();
  bool _open = true;

  void _markClosed() {
    if (!_open) return;
    _open = false;
    _state.add(RemoteChannelState.closed);
  }

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_open) throw StateError('Server socket closed');
    _socket.add(jsonEncode(frame));
  }

  void sendMalformed(String data) => _socket.add(data);

  Future<void>? _closing;

  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _markClosed();
    await _socket.close();
    await _incoming.close();
    await _state.close();
  }
}

void main() {
  late _SocketServer server;

  setUp(() async {
    server = await _SocketServer.start();
  });
  tearDown(() async {
    await server.close();
  });

  group('WsClientChannel over a real loopback socket', () {
    test('enforces the TLS-or-loopback invariant for off-loopback ws', () {
      expect(
        () => WsClientChannel.connect(Uri.parse('ws://192.168.50.50:9/rpc')),
        throwsA(isA<InsecureTransportException>()),
      );
    });

    test(
      'routes frames through /rpc and delivers replies in socket order',
      () async {
        final received = <Map<String, dynamic>>[];
        server.onConnection = (peer) {
          peer.incoming.listen((frame) {
            received.add(frame);
            unawaited(
              peer.send({
                'jsonrpc': '2.0',
                'id': frame['id'],
                'result': {'handled': received.length},
              }),
            );
          });
        };
        final channel = await WsClientChannel.connect(server.uri);
        final replies = channel.incoming
            .take(2)
            .toList()
            .timeout(const Duration(seconds: 5));
        final incomingDone = Completer<void>();
        channel.incoming.listen((_) {}, onDone: incomingDone.complete);
        await channel.send({'jsonrpc': '2.0', 'id': 1, 'method': 'repo/call'});
        await channel.send({'jsonrpc': '2.0', 'id': 2, 'method': 'repo/call'});

        expect((await replies).map((frame) => frame['result']['handled']), [
          1,
          2,
        ]);
        expect(received.map((frame) => frame['id']), [1, 2]);
        expect(server.paths, ['/rpc']);
        expect(channel.isOpen, isTrue);

        final closed = channel.state.firstWhere(
          (state) => state == RemoteChannelState.closed,
        );
        await channel.close();
        await closed.timeout(const Duration(seconds: 5));
        await incomingDone.future.timeout(const Duration(seconds: 5));
        expect(channel.isOpen, isFalse);
        await expectLater(
          channel.send({'jsonrpc': '2.0', 'id': 3, 'method': 'repo/call'}),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('buffers a reply delivered before a listener attaches', () async {
      final sent = Completer<void>();
      server.onConnection = (peer) {
        unawaited(
          peer
              .send({
                'jsonrpc': '2.0',
                'id': 'early',
                'result': {'ready': true},
              })
              .then((_) => sent.complete()),
        );
      };
      final channel = await WsClientChannel.connect(server.uri);
      await sent.future.timeout(const Duration(seconds: 5));
      // Let the socket delivery finish before subscribing, not after a guessed
      // number of event-loop turns.
      final reply = await channel.incoming.first.timeout(
        const Duration(seconds: 5),
      );
      expect(reply['id'], 'early');
      expect(reply['result'], {'ready': true});
      await channel.close();
    });

    test('unread raw records have a bounded pre-listener buffer', () async {
      final connected = Completer<_ServerSocketChannel>();
      server.onConnection = connected.complete;
      final channel = await WsClientChannel.connect(server.uri);
      final closed = channel.state.firstWhere(
        (state) => state == RemoteChannelState.closed,
      );
      final peer = await connected.future;
      for (var i = 0; i <= 64; i++) {
        await peer.send({'id': i});
      }
      await closed.timeout(const Duration(seconds: 5));
      expect(channel.isOpen, isFalse);
    });

    test('a raw record over 64 KiB aborts the channel', () async {
      final connected = Completer<_ServerSocketChannel>();
      server.onConnection = connected.complete;
      final channel = await WsClientChannel.connect(server.uri);
      final received = channel.incoming.toList();
      await (await connected.future).send({'c': 'x' * (64 * 1024)});
      expect(await received.timeout(const Duration(seconds: 5)), isEmpty);
      expect(channel.isOpen, isFalse);
    });

    test('outbound raw records over 64 KiB are rejected', () async {
      final channel = await WsClientChannel.connect(server.uri);
      await expectLater(
        channel.send({'c': 'x' * (64 * 1024)}),
        throwsA(isA<StateError>()),
      );
      expect(channel.isOpen, isTrue);
      await channel.close();
    });

    test(
      'malformed raw JSON aborts without delivering another record',
      () async {
        final connected = Completer<_ServerSocketChannel>();
        server.onConnection = connected.complete;
        final channel = await WsClientChannel.connect(server.uri);
        final received = channel.incoming.toList();
        (await connected.future).sendMalformed('{not json');
        expect(await received.timeout(const Duration(seconds: 5)), isEmpty);
        expect(channel.isOpen, isFalse);
      },
    );

    test('server EOF delivers the last decoded record before done', () async {
      final connected = Completer<_ServerSocketChannel>();
      server.onConnection = connected.complete;
      final channel = await WsClientChannel.connect(server.uri);
      final received = channel.incoming.toList();
      final peer = await connected.future;
      final finalFrame = {'id': 8, 'record': 'x' * 60000};
      await peer.send(finalFrame);
      await peer.close();
      expect(await received.timeout(const Duration(seconds: 5)), [finalFrame]);
      expect(channel.isOpen, isFalse);
    });

    test('surfaces closed when the server drops the socket', () async {
      // The client can finish connecting before the server's upgrade handler
      // registers the socket; closing then would drop nothing, since
      // HttpServer.close does not reach upgraded sockets.
      final accepted = Completer<void>();
      server.onConnection = (_) => accepted.complete();
      final channel = await WsClientChannel.connect(server.uri);
      await accepted.future.timeout(const Duration(seconds: 10));
      final closed = channel.state.firstWhere(
        (state) => state == RemoteChannelState.closed,
      );
      await server.close();
      await closed.timeout(const Duration(seconds: 10));
      expect(channel.isOpen, isFalse);
      await channel.close();
    });
  });

  group('connectRemoteRpc', () {
    late String seed;
    late String publicKey;
    late String fingerprint;
    final psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));

    setUp(() async {
      seed = await ServerIdentityCrypto.generateSeed();
      publicKey = await ServerIdentityCrypto.publicKeyFromSeed(seed);
      fingerprint = ServerIdentityCrypto.fingerprintOf(publicKey);
    });

    test('initializes and routes RPC only through encrypted records', () async {
      final requests = <Map<String, dynamic>>[];
      late _ServerSocketChannel raw;
      late Future<SecureChannelConnection> accepted;
      server.onConnection = (peer) {
        raw = peer;
        accepted =
            acceptSecureChannel(
              channel: peer,
              readPsk: (deviceId) async => deviceId == 'dev-1' ? psk : null,
              serverPublicKey: publicKey,
              signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
                seedB64: seed,
                nonce: challenge,
              ),
              timeout: const Duration(seconds: 5),
            ).then((connection) async {
              connection.channel.incoming.listen((frame) {
                requests.add(frame);
                final method = frame['method'];
                if (method == 'initialize') {
                  unawaited(
                    connection.channel.send({
                      'jsonrpc': '2.0',
                      'id': frame['id'],
                      'result': {'capabilities': <String, dynamic>{}},
                    }),
                  );
                } else if (method == 'session/list_workspaces') {
                  unawaited(
                    connection.channel.send({
                      'jsonrpc': '2.0',
                      'id': frame['id'],
                      'result': {
                        'workspaces': [
                          {'id': 'workspace-1', 'name': 'Test'},
                        ],
                      },
                    }),
                  );
                }
              });
              await connection.channel.send({'type': 'approved'});
              return connection;
            });
      };
      final client = await connectRemoteRpc(
        uri: server.uri,
        deviceId: 'dev-1',
        psk: psk,
        pinnedFingerprint: fingerprint,
        timeout: const Duration(seconds: 5),
        requestTimeout: const Duration(seconds: 5),
      );
      expect(await client.listWorkspaces(), [
        {'id': 'workspace-1', 'name': 'Test'},
      ]);
      final serverConnection = await accepted;
      expect(serverConnection.deviceId, 'dev-1');
      expect(serverConnection.serverFingerprint, fingerprint);
      expect(client.isOpen, isTrue);
      expect(requests.first['method'], 'initialize');
      expect(requests.last['method'], 'session/list_workspaces');
      expect(server.paths, ['/rpc']);
      // All post-handshake frames are sealed even on a direct loopback socket.
      expect(raw.wireFrames.first, contains('secure_hello'));
      expect(raw.wireFrames.skip(1), isNotEmpty);
      for (final wire in raw.wireFrames.skip(1)) {
        final frame = jsonDecode(wire) as Map<String, dynamic>;
        expect(frame['type'], 'secure');
        expect(wire, isNot(contains('initialize')));
        expect(wire, isNot(contains('workspace-1')));
      }
      await client.close();
      await serverConnection.channel.close();
    });

    test(
      'refuses an unpaired device rather than falling back to raw RPC',
      () async {
        late Future<SecureChannelConnection> accepted;
        server.onConnection = (peer) {
          accepted = acceptSecureChannel(
            channel: peer,
            readPsk: (_) async => null,
            serverPublicKey: publicKey,
            signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
              seedB64: seed,
              nonce: challenge,
            ),
            timeout: const Duration(seconds: 5),
          );
          unawaited(accepted.then<void>((_) {}, onError: (Object _) {}));
        };
        await expectLater(
          connectRemoteRpc(
            uri: server.uri,
            deviceId: 'unknown-device',
            psk: psk,
            pinnedFingerprint: fingerprint,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<AuthRejectedException>()),
        );
        await expectLater(accepted, throwsA(isA<SecureHandshakeException>()));
      },
    );

    test('rejects an incorrect pairing credential', () async {
      late Future<SecureChannelConnection> accepted;
      server.onConnection = (peer) {
        accepted = acceptSecureChannel(
          channel: peer,
          readPsk: (deviceId) async => deviceId == 'dev-1' ? psk : null,
          serverPublicKey: publicKey,
          signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
            seedB64: seed,
            nonce: challenge,
          ),
          timeout: const Duration(seconds: 5),
        );
        unawaited(accepted.then<void>((_) {}, onError: (Object _) {}));
      };
      await expectLater(
        connectRemoteRpc(
          uri: server.uri,
          deviceId: 'dev-1',
          psk: base64Url.encode(List<int>.generate(32, (i) => i + 40)),
          pinnedFingerprint: fingerprint,
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<AuthRejectedException>()),
      );
      await expectLater(accepted, throwsA(isA<SecureHandshakeException>()));
    });

    test('refuses a changed pinned server identity', () async {
      late Future<SecureChannelConnection> accepted;
      server.onConnection = (peer) {
        accepted = acceptSecureChannel(
          channel: peer,
          readPsk: (_) async => psk,
          serverPublicKey: publicKey,
          signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
            seedB64: seed,
            nonce: challenge,
          ),
          timeout: const Duration(seconds: 5),
        );
        unawaited(accepted.then<void>((_) {}, onError: (Object _) {}));
      };
      await expectLater(
        connectRemoteRpc(
          uri: server.uri,
          deviceId: 'dev-1',
          psk: psk,
          pinnedFingerprint: '0' * 64,
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<ServerIdentityMismatchException>()),
      );
      await expectLater(accepted, throwsA(isA<SecureHandshakeException>()));
    });
  });
}
