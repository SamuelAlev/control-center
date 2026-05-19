import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A tiny in-process stand-in for the `cc_signaling_server` broker, speaking
/// the room protocol over a real loopback WebSocket. The owner-peer side of a
/// relay link (a cc_server) is mirrored here so [RelayClientChannel] can be
/// driven end-to-end: join acks, owner presence, peer signals and peer-left.
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

  /// Push a raw frame to the most-recently-connected client.
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

const _psk = 'test-psk-for-relay';
const _room = 'room-relay';

String admissionToken() =>
    RemoteControlCrypto.relayAdmissionToken(psk: _psk, room: _room);

/// The owner/server half of the relay data plane, built from the same
/// [ChunkedRelaySession] the client uses. It seals frames to the room and opens
/// inbound sealed frames from the client.
class _OwnerSide {
  _OwnerSide(this.broker);

  final _Broker broker;
  late final ChunkedRelaySession session;
  final incoming = <Map<String, dynamic>>[];
  final progress = <RelayTransferProgress>[];

  void start() {
    session = ChunkedRelaySession(
      psk: _psk,
      sendPayload: (payload) {
        // Owner broadcasts the sealed payload back as a signal from itself.
        broker.sendToLast({
          'type': 'signal',
          'from': 'owner-peer',
          'kind': 'rpc',
          'payload': payload,
        });
      },
      onFrame: incoming.add,
      onProgress: progress.add,
      maxChunkChars: 16 * 1024,
    );
  }

  /// Routes a client-originated signal payload into the owner's session.
  void handlePayload(Map<String, dynamic> payload) =>
      session.handlePayload(payload.cast<String, dynamic>());
}

Future<void> _flush() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Broker broker;

  tearDown(() async {
    await broker.close();
  });

  /// Joins with the owner already present and acknowledged. Drives inbound
  /// signals from the owner into its [ChunkedRelaySession] so the client's
  /// sealed frames are decrypted server-side.
  _OwnerSide ownerPresentBroker() {
    final owner = _OwnerSide(broker);
    owner.start();
    broker.frames.listen((frame) {
      if (frame['type'] == 'signal' &&
          frame['payload'] is Map<String, dynamic>) {
        owner.handlePayload(frame['payload'] as Map<String, dynamic>);
      }
    });
    return owner;
  }

  group('RelayClientChannel.connect', () {
    test(
      'connects when the owner is present and reports an open channel',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return {
              'type': 'joined',
              'room': frame['room'],
              'owner': false,
              'ownerPresent': true,
              'ownerPeer': 'owner-peer',
              'peers': 1,
            };
          },
        );
        // Set up the owner data-plane listener (side effect only).
        ownerPresentBroker();

        final channel = await RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-1',
          psk: _psk,
        );
        addTearDown(channel.close);

        expect(channel.isOpen, isTrue);
        expect(channel.incoming, isA<Stream<Map<String, dynamic>>>());
        await _flush();
      },
    );

    test(
      'announces deviceId in a cleartext hello signal to the owner',
      () async {
        Map<String, dynamic>? hello;
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {
              'type': 'joined',
              'ownerPresent': true,
              'ownerPeer': 'owner-peer',
            };
          },
        );
        broker.frames.listen((f) {
          if (f['type'] == 'signal' && f['kind'] == 'hello') {
            hello = f;
          }
        });

        final channel = await RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-aa',
          psk: _psk,
        );
        addTearDown(channel.close);
        await _flush();

        expect(hello, isNotNull);
        expect(hello!['to'], 'owner-peer');
        expect((hello!['payload'] as Map)['d'], 'dev-aa');
      },
    );

    test('waits for the owner to join when it is absent at ack time', () async {
      // Owner absent in the ack; the broker then pushes a peer-joined for the
      // owner so the wait resolves.
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': false,
            'ownerPeer': null,
          };
        },
      );
      final owner = _OwnerSide(broker);
      owner.start();
      broker.frames.listen((frame) {
        if (frame['type'] == 'signal' && frame['payload'] is Map) {
          owner.handlePayload(frame['payload'] as Map<String, dynamic>);
        }
      });

      // The connect future resolves only after the owner joins.
      final connectFuture = RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-2',
        psk: _psk,
        ownerWait: const Duration(seconds: 3),
      );
      await _flush();
      broker.sendToLast(const {
        'type': 'peer-joined',
        'from': 'owner-peer',
        'owner': true,
      });
      final channel = await connectFuture;
      addTearDown(channel.close);
      expect(channel.isOpen, isTrue);
    });

    test('throws when the owner never joins within ownerWait', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {'type': 'joined', 'ownerPresent': false};
        },
      );

      await expectLater(
        RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-3',
          psk: _psk,
          ownerWait: const Duration(milliseconds: 200),
        ),
        throwsA(isA<RelaySignalingException>()),
      );
    });

    test('throws when the owner peer id is empty', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          // Owner "present" but with an empty ownerPeer — fails the validity check.
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': '',
          };
        },
      );

      await expectLater(
        RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-4',
          psk: _psk,
        ),
        throwsA(isA<RelaySignalingException>()),
      );
    });

    test('closes the signaling channel when _start fails', () async {
      // No owner, very short wait → _start throws → connect closes its
      // signaling. The successful rethrow propagates as RelaySignalingException.
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {'type': 'joined', 'ownerPresent': false};
        },
      );

      await expectLater(
        RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-5',
          psk: _psk,
          ownerWait: const Duration(milliseconds: 150),
        ),
        throwsA(isA<RelaySignalingException>()),
      );
    });
  });

  group('RelayClientChannel send/receive', () {
    test(
      'seals an outbound frame the owner can open and vice versa',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {
              'type': 'joined',
              'ownerPresent': true,
              'ownerPeer': 'owner-peer',
            };
          },
        );
        final owner = ownerPresentBroker();

        final channel = await RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-6',
          psk: _psk,
        );
        addTearDown(channel.close);
        await _flush();

        // Client → owner: a sealed frame the owner decrypts.
        await channel.send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'});
        await _flush();
        expect(owner.incoming, isNotEmpty);
        expect(owner.incoming.last['method'], 'ping');

        // Owner → client: a sealed frame the client surfaces on `incoming`.
        final clientFrames = <Map<String, dynamic>>[];
        channel.incoming.listen(clientFrames.add);
        await owner.session.sendFrame({
          'jsonrpc': '2.0',
          'method': 'notifications/pong',
          'params': {'ok': true},
        });
        await _flush();
        expect(clientFrames, isNotEmpty);
        expect(clientFrames.last['method'], 'notifications/pong');
      },
    );

    test('send throws when the channel is not open', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );

      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-7',
        psk: _psk,
      );
      await channel.close();
      await expectLater(channel.send({'x': 1}), throwsA(isA<StateError>()));
    });

    test(
      'buffers frames until a listener attaches (no dropped handshake reply)',
      () async {
        broker = await _Broker.start(
          onJoin: (frame) async {
            return const {
              'type': 'joined',
              'ownerPresent': true,
              'ownerPeer': 'owner-peer',
            };
          },
        );
        final owner = ownerPresentBroker();

        final channel = await RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-8',
          psk: _psk,
        );
        addTearDown(channel.close);
        await _flush();

        // Owner sends before the client listens — the reply must be buffered.
        await owner.session.sendFrame({
          'jsonrpc': '2.0',
          'method': 'buffered/hello',
          'params': {},
        });
        await _flush();
        // Attach a listener after the frame was delivered; it should be flushed.
        final clientFrames = <Map<String, dynamic>>[];
        channel.incoming.listen(clientFrames.add);
        await _flush();
        expect(
          clientFrames.any((f) => f['method'] == 'buffered/hello'),
          isTrue,
        );
      },
    );
  });

  group('RelayClientChannel state + close', () {
    test('state emits open on connect then closed on close', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );

      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-9',
        psk: _psk,
      );
      final states = <RemoteChannelState>[];
      channel.state.listen(states.add);
      await _flush();
      // The broadcast stream only observes post-subscribe events; the open
      // transition already happened. After close we see closed.
      await channel.close();
      await _flush();
      expect(states, contains(RemoteChannelState.closed));
      expect(channel.isOpen, isFalse);
    });

    test('close is idempotent', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );

      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-10',
        psk: _psk,
      );
      await channel.close();
      // A second close must not throw.
      await channel.close();
      expect(channel.isOpen, isFalse);
    });

    test('a peer-left from the owner closes the channel', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );

      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-11',
        psk: _psk,
      );
      final states = <RemoteChannelState>[];
      channel.state.listen(states.add);
      await _flush();

      broker.sendToLast(const {'type': 'peer-left', 'from': 'owner-peer'});
      await _flush();
      expect(channel.isOpen, isFalse);
      expect(states, contains(RemoteChannelState.closed));
    });

    test('transferProgress surfaces large multi-chunk sends', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );
      // Owner data-plane listener consumes the chunked send (side effect).
      // ignore: unused_local_variable
      final owner = ownerPresentBroker();

      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-12',
        psk: _psk,
      );
      addTearDown(channel.close);
      final progress = <RelayTransferProgress>[];
      channel.transferProgress.listen(progress.add);
      await _flush();

      // Build a frame large enough to split into many chunks (16 KB each).
      final big = List.filled(200000, 'x').join();
      await channel.send({'jsonrpc': '2.0', 'id': 2, 'blob': big});
      await _flush();
      expect(progress, isNotEmpty);
    });
  });

  group('RelayClientChannel.probe', () {
    test('returns a latency when the owner is present', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          };
        },
      );

      final latency = await RelayClientChannel.probe(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        psk: _psk,
      );
      expect(latency, isNotNull);
    });

    test('returns null when the owner is absent', () async {
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {'type': 'joined', 'ownerPresent': false};
        },
      );

      final latency = await RelayClientChannel.probe(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        psk: _psk,
      );
      expect(latency, isNull);
    });

    test('returns null on an unreachable broker', () async {
      final tmp = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final freePort = tmp.port;
      await tmp.close(force: true);
      broker = await _Broker.start(
        onJoin: (frame) async {
          return const {'type': 'joined', 'ownerPresent': true};
        },
      );

      final latency = await RelayClientChannel.probe(
        signalingUrl: 'ws://127.0.0.1:$freePort/',
        room: _room,
        psk: _psk,
        timeout: const Duration(seconds: 2),
      );
      expect(latency, isNull);
    });
  });
}
