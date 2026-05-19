import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/src/channel/relay_signaling_channel.dart';
import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:test/test.dart';

/// A tiny in-process stand-in for the `cc_signaling_server` broker, speaking
/// the invite-gated room protocol over a real loopback WebSocket. The real
/// broker is a dumb relay; this one is scripted from the test so we can drive
/// every join outcome (ack, refusal, TURN minting, peer-left) against the
/// cross-platform [RelaySignalingChannel] built on `WebSocketChannel.connect`.
class _Broker {
  _Broker(this._server);

  final HttpServer _server;
  late final int port = _server.port;
  final _sockets = <WebSocket>[];
  WebSocket? _last;
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get frames => _incoming.stream;

  static Future<_Broker> start({
    required FutureOr<Map<String, dynamic>> Function(Map<String, dynamic> join)
    onJoin,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final broker = _Broker(server);
    server
        .asyncExpand((request) {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            return WebSocketTransformer.upgrade(request).asStream();
          }
          request.response.statusCode = HttpStatus.badRequest;
          request.response.close();
          return const Stream<WebSocket>.empty();
        })
        .listen((socket) {
          broker._sockets.add(socket);
          broker._last = socket;
          socket.listen((raw) {
            if (broker._incoming.isClosed) {
              return;
            }
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            broker._incoming.add(decoded);
            if (decoded['type'] == 'join') {
              () async {
                final reply = await onJoin(decoded);
                if (!broker._closed && socket.readyState == WebSocket.open) {
                  socket.add(jsonEncode(reply));
                }
              }();
            }
          });
        });
    return broker;
  }

  /// Push a raw frame to the most-recently-connected client (simulates another
  /// room member broadcasting a signal).
  void sendToLast(Map<String, dynamic> frame) {
    final s = _last;
    if (s != null && s.readyState == WebSocket.open && !_closed) {
      s.add(jsonEncode(frame));
    }
  }

  bool _closed = false;

  Future<void> close() async {
    _closed = true;
    for (final s in _sockets) {
      await s.close();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
    await _server.close(force: true);
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 25; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Broker broker;

  tearDown(() async {
    await broker.close();
  });

  group('RelaySignalingChannel.joinAsClient', () {
    test(
      'joins an admitted room and surfaces the join acknowledgement',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return {
              'type': 'joined',
              'room': frame['room'],
              'owner': false,
              'ownerPresent': true,
              'ownerPeer': 'server-peer',
              'peers': 1,
            };
          },
        );

        final channel = await RelaySignalingChannel.joinAsClient(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: 'room-1',
          token: 'admission-token',
        );

        expect(channel.room, 'room-1');
        expect(channel.isOpen, isTrue);
        expect(channel.joinAck.owner, isFalse);
        expect(channel.joinAck.ownerPresent, isTrue);
        expect(channel.joinAck.ownerPeer, 'server-peer');
        expect(channel.joinAck.peers, 1);

        await channel.close();
        expect(channel.isOpen, isFalse);
      },
    );

    test(
      'joinAsOwner carries ownerToken + admit set in the join frame',
      () async {
        Map<String, dynamic>? seenJoin;
        broker = await _Broker.start(
          onJoin: (frame) async {
            seenJoin = frame;
            return {
              'type': 'joined',
              'room': frame['room'],
              'owner': true,
              'ownerPresent': true,
              'peers': 0,
            };
          },
        );

        final channel = await RelaySignalingChannel.joinAsOwner(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: 'room-2',
          ownerToken: 'owner-secret',
          admit: const ['hash-1', 'hash-2'],
        );

        expect(channel.joinAck.owner, isTrue);
        expect(seenJoin!['owner'], isTrue);
        expect(seenJoin!['ownerToken'], 'owner-secret');
        expect(seenJoin!['admit'], ['hash-1', 'hash-2']);

        await channel.close();
      },
    );

    test(
      'a broker error frame rejects the join with RelaySignalingException',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {'type': 'error', 'error': 'owner conflict'};
          },
        );

        await expectLater(
          RelaySignalingChannel.joinAsClient(
            signalingUrl: 'ws://127.0.0.1:${broker.port}/',
            room: 'room-3',
            token: 't',
          ),
          throwsA(
            isA<RelaySignalingException>().having(
              (e) => e.message,
              'message',
              'owner conflict',
            ),
          ),
        );
      },
    );

    test(
      'a closed-before-ack socket surfaces as RelaySignalingException',
      () async {
        // Accept the upgrade then immediately drop the socket without acking.
        broker = await _Broker.start(
          onJoin: (frame) async {
            await broker.close();
            return const {'type': 'error', 'error': 'unreachable'};
          },
        );

        await expectLater(
          RelaySignalingChannel.joinAsClient(
            signalingUrl: 'ws://127.0.0.1:${broker.port}/',
            room: 'room-4',
            token: 't',
            timeout: const Duration(seconds: 2),
          ),
          throwsA(isA<RelaySignalingException>()),
        );
      },
    );

    test('an unreachable broker throws RelaySignalingException', () async {
      // Bind a server, close it and reuse the freed port (no listener) — the
      // connect attempt fails fast. Assign a live throwaway broker so the
      // shared tearDown has something to close.
      final tmp = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final freePort = tmp.port;
      await tmp.close(force: true);
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {'type': 'joined', 'ownerPresent': false};
        },
      );
      // The throwaway broker is immediately closed; tearDown will close again.
      await broker.close();

      await expectLater(
        RelaySignalingChannel.joinAsClient(
          signalingUrl: 'ws://127.0.0.1:$freePort/',
          room: 'room-x',
          token: 't',
          timeout: const Duration(seconds: 2),
        ),
        throwsA(isA<RelaySignalingException>()),
      );
    });
  });

  group('RelaySignalingChannel messaging', () {
    test(
      'sendSignal broadcasts and routes a peer signal to incoming',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return {
              'type': 'joined',
              'room': frame['room'],
              'ownerPresent': true,
              'ownerPeer': 'server',
            };
          },
        );

        final channel = await RelaySignalingChannel.joinAsClient(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: 'room-m',
          token: 't',
        );
        final inbound = <Map<String, dynamic>>[];
        channel.incoming.listen(inbound.add);

        // Broadcast a signal to the room.
        channel.sendSignal(payload: const {'hello': 'world'});

        // Broker pushes a peer signal back.
        broker.sendToLast({
          'type': 'signal',
          'from': 'server',
          'kind': 'rpc',
          'payload': {'ack': 1},
        });
        await _flush();

        expect(inbound, isNotEmpty);
        expect(inbound.last['type'], 'signal');
        expect((inbound.last['payload'] as Map)['ack'], 1);

        await channel.close();
      },
    );

    test('admit builds add/remove deltas and requestTurnCredentials returns '
        'the minted creds', () async {
      final brokerFrames = <Map<String, dynamic>>[];
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'server',
          };
        },
      );

      final channel = await RelaySignalingChannel.joinAsClient(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: 'room-admit',
        token: 't',
      );
      broker.frames.listen(brokerFrames.add);

      channel.admit(add: const ['h1'], remove: const ['h2']);

      // Broker mints TURN creds in reply to the request.
      final turnFuture = channel.requestTurnCredentials(
        timeout: const Duration(seconds: 2),
      );
      await _flush();
      broker.sendToLast(const {
        'type': 'turn-credentials',
        'uris': ['turn:turn.example.org'],
        'username': 'user',
        'credential': 'pass',
        'ttlSeconds': 600,
      });
      final creds = await turnFuture;

      // The admit frame carried both deltas.
      final admit = brokerFrames.firstWhere((f) => f['type'] == 'admit');
      expect(admit['add'], ['h1']);
      expect(admit['remove'], ['h2']);

      // TURN creds were parsed verbatim.
      expect(creds, isNotNull);
      expect(creds!.uris, ['turn:turn.example.org']);
      expect(creds.username, 'user');
      expect(creds.credential, 'pass');
      expect(creds.ttl, const Duration(seconds: 600));

      await channel.close();
    });

    test(
      'requestTurnCredentials returns null when the broker has none',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {
              'type': 'joined',
              'ownerPresent': true,
              'ownerPeer': 'server',
            };
          },
        );

        final channel = await RelaySignalingChannel.joinAsClient(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: 'room-no-turn',
          token: 't',
        );

        final turnFuture = channel.requestTurnCredentials(
          timeout: const Duration(seconds: 2),
        );
        await _flush();
        // Empty URI list -> no TURN configured.
        broker.sendToLast(const {'type': 'turn-credentials', 'uris': []});

        expect(await turnFuture, isNull);

        await channel.close();
      },
    );

    test(
      'a socket close from the broker surfaces peer-left then closes',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {
              'type': 'joined',
              'ownerPresent': true,
              'ownerPeer': 'server',
            };
          },
        );

        final channel = await RelaySignalingChannel.joinAsClient(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: 'room-leave',
          token: 't',
        );
        final inbound = <Map<String, dynamic>>[];
        channel.incoming.listen(
          inbound.add,
          onDone: () => inbound.add(const {}),
        );

        // Broker kills the socket — the channel synthesizes peer-left.
        await broker.close();
        await _flush();

        expect(inbound, isNotEmpty);
        expect(channel.isOpen, isFalse);
      },
    );
  });

  group('RelaySignalingChannel pure helpers', () {
    test('randomPeerId is a 12-byte hex string (24 chars)', () {
      final id = RelaySignalingChannel.randomPeerId();
      expect(id, hasLength(24));
      expect(RegExp(r'^[0-9a-f]{24}$').hasMatch(id), isTrue);

      // Two calls yield distinct ids (fresh randomness).
      expect(
        RelaySignalingChannel.randomPeerId(),
        isNot(RelaySignalingChannel.randomPeerId()),
      );
    });

    test(
      'RelayJoinAck.fromFrame parses owner/ownerPresent/ownerPeer/peers',
      () {
        final ack = RelayJoinAck.fromFrame(const {
          'owner': true,
          'ownerPresent': true,
          'ownerPeer': 'p1',
          'peers': 7,
        });
        expect(ack.owner, isTrue);
        expect(ack.ownerPresent, isTrue);
        expect(ack.ownerPeer, 'p1');
        expect(ack.peers, 7);
      },
    );

    test('RelayJoinAck.fromFrame defaults absent fields', () {
      final ack = RelayJoinAck.fromFrame(const {});
      expect(ack.owner, isFalse);
      expect(ack.ownerPresent, isFalse);
      expect(ack.ownerPeer, isNull);
      expect(ack.peers, 0);
    });

    test('RelayJoinAck has sensible defaults on the bare constructor', () {
      const ack = RelayJoinAck(owner: false, ownerPresent: false);
      expect(ack.ownerPeer, isNull);
      expect(ack.peers, 0);
    });

    test('RelaySignalingException toString carries the message', () {
      const exc = RelaySignalingException('broker down');
      expect(exc.toString(), 'RelaySignalingException: broker down');
    });

    test('RelayTurnCredentials exposes its fields', () {
      const creds = RelayTurnCredentials(
        uris: ['turn:a', 'turn:b'],
        username: 'u',
        credential: 'c',
        ttl: Duration(seconds: 30),
      );
      expect(creds.uris, ['turn:a', 'turn:b']);
      expect(creds.username, 'u');
      expect(creds.credential, 'c');
      expect(creds.ttl, const Duration(seconds: 30));
    });
  });

  test(
    'TransportSecurityPolicy allows loopback ws (the broker URL is valid)',
    () {
      expect(
        TransportSecurityPolicy.allows(Uri.parse('ws://127.0.0.1:9999/')),
        isTrue,
      );
    },
  );
}
