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

final _psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));
const _room = 'room-relay';

/// The fake broker forwards owner records without interpreting or sealing them.
/// This exercises the raw adapter independently of the secure channel above it.
class _OwnerSide {
  _OwnerSide(this.broker) {
    broker.frames.listen((frame) {
      if (frame['type'] == 'signal' && frame['kind'] == 'rpc') {
        final payload = frame['payload'];
        if (payload is Map<String, dynamic>) {
          incoming.add(payload);
        }
      }
    });
  }

  final _Broker broker;
  final incoming = <Map<String, dynamic>>[];

  void send(Map<String, dynamic> record) => broker.sendToLast({
    'type': 'signal',
    'from': 'owner-peer',
    'kind': 'rpc',
    'payload': record,
  });
}

Future<void> _flush() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Waits until [condition] holds, with a real wall-clock deadline. Delivery
/// through the fake broker rides real loopback sockets, which need real
/// event-loop turns — a fixed pump count flakes on a loaded runner.
Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      return; // Let the following expect produce the failure with context.
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late _Broker broker;

  tearDown(() async {
    await broker.close();
  });

  _OwnerSide ownerPresentBroker() => _OwnerSide(broker);

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
        // Raw transport is open even before any application records arrive.

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
        // Hello rides the same loopback WebSocket as the join; a fixed
        // `_flush()` of zero-delay turns misses it on a loaded macos-26
        // runner (packages dart OS job).
        await _until(() => hello != null);

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
      // The owner need not open a data-plane session to announce presence.

      // The connect future resolves only after the owner joins. Subscribe to
      // the broker's join frames BEFORE starting the connect: `sendToLast`
      // targets the most-recently-ACCEPTED socket, so pushing `peer-joined`
      // before the client's upgrade completed sent it nowhere (dropped) on a
      // slow runner and the client died at ownerWait.
      final clientJoined = broker.frames
          .firstWhere((f) => f['type'] == 'join')
          .timeout(const Duration(seconds: 5));
      final connectFuture = RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-2',
        psk: _psk,
        ownerWait: const Duration(seconds: 3),
      );
      await clientJoined;
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
      'routes raw records to the owner and back without transforming them',
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
        // Encryption belongs to SecureRpcChannel, not this broker adapter.
        const outbound = {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'};
        await channel.send(outbound);
        await _until(() => owner.incoming.isNotEmpty);
        expect(owner.incoming.single, outbound);

        final clientGot = channel.incoming.first.timeout(
          const Duration(seconds: 5),
        );
        const inbound = {
          'jsonrpc': '2.0',
          'method': 'notifications/pong',
          'params': {'ok': true},
        };
        owner.send(inbound);
        expect(await clientGot, inbound);
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

    test('buffers a received record until a listener attaches', () async {
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
        deviceId: 'dev-8',
        psk: _psk,
      );
      addTearDown(channel.close);
      // Same-socket ordering makes peer-left a barrier: when close arrives,
      // the earlier owner record has already been buffered without a listener.
      final closed = channel.state
          .firstWhere((state) => state == RemoteChannelState.closed)
          .timeout(const Duration(seconds: 5));
      broker.sendToLast(const {
        'type': 'signal',
        'from': 'owner-peer',
        'kind': 'rpc',
        'payload': {'method': 'buffered/hello'},
      });
      broker.sendToLast(const {'type': 'peer-left', 'from': 'owner-peer'});
      await closed;
      final received = channel.incoming.first.timeout(
        const Duration(seconds: 5),
      );
      expect(await received, {'method': 'buffered/hello'});
    });
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

    test(
      'owner close delivers its last queued record before incoming done',
      () async {
        broker = await _Broker.start(
          onJoin: (_) async => const {
            'type': 'joined',
            'ownerPresent': true,
            'ownerPeer': 'owner-peer',
          },
        );
        final channel = await RelayClientChannel.connect(
          signalingUrl: 'ws://127.0.0.1:${broker.port}/',
          room: _room,
          deviceId: 'dev-final',
          psk: _psk,
        );
        addTearDown(channel.close);
        final received = channel.incoming.toList();
        broker.sendToLast(const {
          'type': 'signal',
          'from': 'owner-peer',
          'kind': 'rpc',
          'payload': {'type': 'secure', 'c': 'final-record'},
        });
        broker.sendToLast(const {
          'type': 'signal',
          'from': 'owner-peer',
          'kind': 'close',
        });
        expect(await received.timeout(const Duration(seconds: 5)), [
          {'type': 'secure', 'c': 'final-record'},
        ]);
        expect(channel.isOpen, isFalse);
      },
    );

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
      // The peer-left rides a real loopback socket, so a fixed pump count
      // flakes on a loaded runner — the reason [_until] exists.
      await _until(() => states.contains(RemoteChannelState.closed));
      expect(channel.isOpen, isFalse);
      expect(states, contains(RemoteChannelState.closed));
    });

    test('ignores signals from peers other than the owner', () async {
      broker = await _Broker.start(
        onJoin: (frame) async => const {
          'type': 'joined',
          'ownerPresent': true,
          'ownerPeer': 'owner-peer',
        },
      );
      final owner = ownerPresentBroker();
      final channel = await RelayClientChannel.connect(
        signalingUrl: 'ws://127.0.0.1:${broker.port}/',
        room: _room,
        deviceId: 'dev-12',
        psk: _psk,
      );
      addTearDown(channel.close);
      final received = <Map<String, dynamic>>[];
      channel.incoming.listen(received.add);
      broker.sendToLast(const {
        'type': 'signal',
        'from': 'other-peer',
        'kind': 'rpc',
        'payload': {'foreign': true},
      });
      owner.send({'owner': true});
      await _until(() => received.isNotEmpty);
      expect(received, [
        {'owner': true},
      ]);
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
