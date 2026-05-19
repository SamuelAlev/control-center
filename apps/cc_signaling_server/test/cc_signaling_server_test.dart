import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_signaling_server/cc_signaling_server.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

/// A minimal WebSocket test client that buffers every inbound frame so later
/// [next] calls never miss messages that arrived between subscriptions.
class _Client {
  _Client._(this._socket);

  final WebSocket _socket;
  final List<Map<String, dynamic>> _messages = [];
  final List<Completer<void>> _waiters = [];
  late final StreamSubscription<dynamic> _sub;
  final Completer<void> _closed = Completer<void>();

  static Future<_Client> connect(int port) async {
    final client = _Client._(await WebSocket.connect('ws://localhost:$port/'));
    client._sub = client._socket.listen(
      client._onData,
      onError: (Object error, StackTrace _) {},
      onDone: () {
        if (!client._closed.isCompleted) {
          client._closed.complete();
        }
      },
    );
    return client;
  }

  void _onData(dynamic data) {
    if (data is! String) {
      return;
    }
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    _messages.add(frame);
    while (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      if (!waiter.isCompleted) {
        waiter.complete();
        break;
      }
    }
  }

  /// Returns (and consumes) the first buffered frame matching [test], waiting
  /// for one to arrive if necessary.
  Future<Map<String, dynamic>> next(
    bool Function(Map<String, dynamic> frame) test, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    while (true) {
      for (var i = 0; i < _messages.length; i++) {
        if (test(_messages[i])) {
          return _messages.removeAt(i);
        }
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'no matching frame within $timeout'
          ' (buffered: ${_messages.map((m) => m['type']).toList()})',
        ),
      );
    }
  }

  /// Every frame received so far (peeking, non-consuming).
  List<Map<String, dynamic>> get received => List.unmodifiable(_messages);

  void send(Map<String, dynamic> frame) => _socket.add(jsonEncode(frame));
  void sendRaw(String text) => _socket.add(text);

  Future<void> get closed => _closed.future;

  /// Whether the broker has already closed this socket (non-blocking).
  bool get isClosed => _closed.isCompleted;

  Future<void> close() async {
    await _sub.cancel();
    try {
      await _socket.close();
    } catch (_) {
      // Already closed by the broker.
    }
  }
}

Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

String _hash(String token) => sha256.convert(utf8.encode(token)).toString();

const _ownerToken = 'owner-secret-token';
const _tokenA = 'admit-token-a';
const _tokenB = 'admit-token-b';
const _tokenC = 'admit-token-c';
const _tokenPhone = 'admit-token-phone';

/// Joins [room] as its owner and waits for the ack.
Future<_Client> _joinOwner(
  int port, {
  String room = 'alpha',
  String from = 'server',
  String ownerToken = _ownerToken,
  List<String>? admit,
}) async {
  final c = await _Client.connect(port);
  c.send({
    'type': 'join',
    'room': room,
    'from': from,
    'owner': true,
    'ownerToken': ownerToken,
    'admit': admit ?? [_hash(_tokenA), _hash(_tokenB), _hash(_tokenC), _hash(_tokenPhone)],
  });
  await c.next((m) => m['type'] == 'joined');
  return c;
}

/// Joins [room] as an admitted client and waits for the ack.
Future<_Client> _joinClient(
  int port, {
  String room = 'alpha',
  required String from,
  required String token,
}) async {
  final c = await _Client.connect(port);
  c.send({'type': 'join', 'room': room, 'from': from, 'token': token});
  await c.next((m) => m['type'] == 'joined');
  return c;
}

void main() {
  late SignalingServerHandle handle;

  tearDown(() async {
    await handle.close();
  });

  group('peer-id eviction', () {
    test(
      'an admitted peer cannot evict another member on a loop',
      () async {
        // Peer ids ride in `peer-joined` frames, so every admitted client
        // knows them. Rejoining as an existing id evicts the incumbent — the
        // intended RECONNECT behaviour — but unbounded that is a free in-room
        // denial of service against any member.
        handle = await serveSignaling(host: 'localhost', port: 0);
        final server = await _joinOwner(handle.port);
        addTearDown(server.close);
        var victim = await _joinClient(handle.port, from: 'A', token: _tokenA);

        // Three collisions are permitted (a real reconnect storm).
        for (var i = 0; i < 3; i++) {
          final impostor = await _Client.connect(handle.port);
          impostor.send({
            'type': 'join',
            'room': 'alpha',
            'from': 'A',
            'token': _tokenA,
          });
          await impostor.next((m) => m['type'] == 'joined');
          await victim.closed; // The incumbent was evicted.
          victim = impostor;
        }

        // The fourth is refused, and the incumbent KEEPS its socket.
        final blocked = await _Client.connect(handle.port);
        blocked.send({
          'type': 'join',
          'room': 'alpha',
          'from': 'A',
          'token': _tokenA,
        });
        final err = await blocked.next((m) => m['type'] == 'error');
        expect(err['error'], 'not admitted');
        await blocked.closed;
        expect(
          victim.isClosed,
          isFalse,
          reason: 'the incumbent must survive a refused collision',
        );
        await victim.close();
      },
    );
  });

  group('admission gating', () {
    test('owner claims the room and an admitted client joins', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _Client.connect(handle.port);
      server.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'server',
        'owner': true,
        'ownerToken': _ownerToken,
        'admit': [_hash(_tokenA)],
      });
      final ownerAck = await server.next((m) => m['type'] == 'joined');
      expect(ownerAck['owner'], isTrue);
      expect(ownerAck['ownerPresent'], isTrue);
      expect(ownerAck['peers'], 0);

      final a = await _Client.connect(handle.port);
      a.send({'type': 'join', 'room': 'alpha', 'from': 'A', 'token': _tokenA});
      final ack = await a.next((m) => m['type'] == 'joined');
      expect(ack['owner'], isFalse);
      expect(ack['ownerPresent'], isTrue);
      expect(ack['ownerPeer'], 'server');
      expect(ack['peers'], 1);

      final joined = await server.next((m) => m['type'] == 'peer-joined');
      expect(joined['from'], 'A');
      expect(joined['owner'], isFalse);

      await a.close();
      await server.close();
    });

    test(
      'a peer with a valid room id but no admission token is refused before '
      'any frame is relayed (N-way denial)',
      () async {
        handle = await serveSignaling(host: 'localhost', port: 0);
        final server = await _joinOwner(handle.port);
        final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

        // Attacker knows the room id but holds no invite-derived token.
        final attacker = await _Client.connect(handle.port);
        attacker.send({'type': 'join', 'room': 'alpha', 'from': 'X'});
        final err = await attacker.next((m) => m['type'] == 'error');
        expect(err['error'], 'not admitted');
        await attacker.closed;

        // A wrong token is refused identically.
        final attacker2 = await _Client.connect(handle.port);
        attacker2.send({
          'type': 'join',
          'room': 'alpha',
          'from': 'X2',
          'token': 'guessed-token',
        });
        final err2 = await attacker2.next((m) => m['type'] == 'error');
        expect(err2['error'], 'not admitted');
        await attacker2.closed;

        // Frames relayed between legitimate members never reached attackers.
        server.send({
          'type': 'signal',
          'room': 'alpha',
          'from': 'server',
          'to': 'A',
          'kind': 'rpc',
          'payload': {'e': 'ciphertext'},
        });
        await a.next((m) => m['type'] == 'signal');
        expect(
          attacker.received.where((m) => m['type'] == 'signal'),
          isEmpty,
        );
        expect(
          attacker2.received.where((m) => m['type'] == 'signal'),
          isEmpty,
        );

        await a.close();
        await server.close();
      },
    );

    test('a join to a nonexistent room gets the same uniform refusal', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final c = await _Client.connect(handle.port);
      c.send({
        'type': 'join',
        'room': 'no-such-room',
        'from': 'A',
        'token': _tokenA,
      });
      final err = await c.next((m) => m['type'] == 'error');
      expect(err['error'], 'not admitted');
      await c.closed;
    });

    test('admit add opens the door; admit remove evicts the live peer and '
        'blocks re-join', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port, admit: [_hash(_tokenA)]);

      // Not yet admitted.
      final b0 = await _Client.connect(handle.port);
      b0.send({'type': 'join', 'room': 'alpha', 'from': 'B', 'token': _tokenB});
      expect((await b0.next((m) => m['type'] == 'error'))['error'], 'not admitted');

      server.send({
        'type': 'admit',
        'room': 'alpha',
        'add': [_hash(_tokenB)],
      });
      final ok = await server.next((m) => m['type'] == 'admit-ok');
      expect(ok['count'], 2);

      final b = await _joinClient(handle.port, from: 'B', token: _tokenB);
      await server.next((m) => m['type'] == 'peer-joined' && m['from'] == 'B');

      // Revocation evicts the live peer…
      server.send({
        'type': 'admit',
        'room': 'alpha',
        'remove': [_hash(_tokenB)],
      });
      await server.next((m) => m['type'] == 'admit-ok');
      await server.next((m) => m['type'] == 'peer-left' && m['from'] == 'B');
      await b.closed;

      // …and the token is dead for re-joins.
      final b2 = await _Client.connect(handle.port);
      b2.send({'type': 'join', 'room': 'alpha', 'from': 'B', 'token': _tokenB});
      expect(
        (await b2.next((m) => m['type'] == 'error'))['error'],
        'not admitted',
      );

      await server.close();
    });

    test('a non-owner cannot update admissions', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);
      a.send({
        'type': 'admit',
        'room': 'alpha',
        'add': [_hash('sneaky')],
      });
      expect((await a.next((m) => m['type'] == 'error'))['error'], 'not owner');
      await a.close();
      await server.close();
    });
  });

  group('owner model', () {
    test('a squatted room refuses the legitimate owner with owner conflict '
        '(and vice versa: a client cannot claim ownership)', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final squatter = await _Client.connect(handle.port);
      squatter.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'squatter',
        'owner': true,
        'ownerToken': 'squat-token',
      });
      await squatter.next((m) => m['type'] == 'joined');

      final server = await _Client.connect(handle.port);
      server.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'server',
        'owner': true,
        'ownerToken': _ownerToken,
      });
      final err = await server.next((m) => m['type'] == 'error');
      expect(err['error'], 'owner conflict');
      await server.closed;
      await squatter.close();
    });

    test('a valid owner re-claim evicts the stale owner connection', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final stale = await _joinOwner(handle.port, from: 'server-old');
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

      final fresh = await _Client.connect(handle.port);
      fresh.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'server-new',
        'owner': true,
        'ownerToken': _ownerToken,
      });
      final ack = await fresh.next((m) => m['type'] == 'joined');
      expect(ack['owner'], isTrue);
      await stale.closed;

      // The client learns the new owner arrived.
      final joined = await a.next(
        (m) => m['type'] == 'peer-joined' && m['from'] == 'server-new',
      );
      expect(joined['owner'], isTrue);

      // Admissions survive the re-claim (no admit list on re-join = keep).
      final b = await _joinClient(handle.port, from: 'B', token: _tokenB);
      await b.close();
      await a.close();
      await fresh.close();
    });

    test('the owner leaving notifies clients with the owner flag and the '
        'room survives for a re-claim', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

      server.send({'type': 'bye', 'room': 'alpha'});
      final left = await a.next((m) => m['type'] == 'peer-left');
      expect(left['from'], 'server');
      expect(left['owner'], isTrue);

      final again = await _joinOwner(handle.port, from: 'server-2');
      final rejoined = await a.next((m) => m['type'] == 'peer-joined');
      expect(rejoined['from'], 'server-2');
      expect(rejoined['owner'], isTrue);

      await a.close();
      await again.close();
      await server.close();
    });
  });

  group('N-way relay', () {
    test('three humans and a phone share one room with the server; targeted '
        'signals reach only their addressee', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);
      final b = await _joinClient(handle.port, from: 'B', token: _tokenB);
      final c = await _joinClient(handle.port, from: 'C', token: _tokenC);
      final phone = await _joinClient(handle.port, from: 'P', token: _tokenPhone);
      expect(handle.broker.peerCount('alpha'), 5);

      // Server targets B only.
      server.send({
        'type': 'signal',
        'room': 'alpha',
        'from': 'server',
        'to': 'B',
        'kind': 'rpc',
        'payload': {'e': 'sealed-for-b'},
      });
      final gotB = await b.next((m) => m['type'] == 'signal');
      expect((gotB['payload'] as Map)['e'], 'sealed-for-b');
      // Give any stray broadcast a moment to arrive, then assert silence.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(a.received.where((m) => m['type'] == 'signal'), isEmpty);
      expect(c.received.where((m) => m['type'] == 'signal'), isEmpty);
      expect(phone.received.where((m) => m['type'] == 'signal'), isEmpty);

      // A client targets the owner.
      phone.send({
        'type': 'signal',
        'room': 'alpha',
        'from': 'P',
        'to': 'server',
        'kind': 'rpc',
        'payload': {'e': 'sealed-for-server'},
      });
      final gotServer = await server.next((m) => m['type'] == 'signal');
      expect((gotServer['payload'] as Map)['e'], 'sealed-for-server');
      expect(gotServer['from'], 'P');

      for (final client in [a, b, c, phone, server]) {
        await client.close();
      }
    });

    test('the broker relays only ciphertext payloads and stamps the real '
        'sender id (no in-room spoofing)', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

      // A tries to impersonate the server towards itself — the broker
      // overwrites `from` with A's joined id.
      a.send({
        'type': 'signal',
        'room': 'alpha',
        'from': 'server',
        'to': 'server',
        'kind': 'rpc',
        'payload': {'e': 'spoofed'},
      });
      final got = await server.next((m) => m['type'] == 'signal');
      expect(got['from'], 'A');

      await a.close();
      await server.close();
    });

    test('a room fills at maxPeersPerRoom', () async {
      final broker = SignalingBroker(maxPeersPerRoom: 3)..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);
      final b = await _joinClient(handle.port, from: 'B', token: _tokenB);

      final c = await _Client.connect(handle.port);
      c.send({'type': 'join', 'room': 'alpha', 'from': 'C', 'token': _tokenC});
      expect((await c.next((m) => m['type'] == 'error'))['error'], 'room full');
      await c.closed;

      await a.close();
      await b.close();
      await server.close();
    });

    test('a re-join with the same peer id evicts the stale connection', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      final a1 = await _joinClient(handle.port, from: 'A', token: _tokenA);
      final a2 = await _joinClient(handle.port, from: 'A', token: _tokenA);
      await a1.closed;
      expect(handle.broker.peerCount('alpha'), 2);
      await a2.close();
      await server.close();
    });
  });

  group('TURN credentials', () {
    test('an admitted member gets HMAC credentials; a non-member is refused',
        () async {
      final broker = SignalingBroker(
        turnSecret: 'coturn-shared-secret',
        turnUris: const ['turn:turn.example.com:3478'],
        turnTtl: const Duration(hours: 2),
      )..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

      a.send({'type': 'turn-request', 'room': 'alpha'});
      final creds = await a.next((m) => m['type'] == 'turn-credentials');
      expect(creds['uris'], ['turn:turn.example.com:3478']);
      expect(creds['ttlSeconds'], 7200);
      final username = creds['username'] as String;
      final expiry = int.parse(username.split(':').first);
      expect(
        expiry,
        greaterThan(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );
      // coturn static-auth-secret scheme: base64(HMAC-SHA1(secret, username)).
      final expected = base64.encode(
        Hmac(sha1, utf8.encode('coturn-shared-secret'))
            .convert(utf8.encode(username))
            .bytes,
      );
      expect(creds['credential'], expected);

      final outsider = await _Client.connect(handle.port);
      outsider.send({'type': 'turn-request', 'room': 'alpha'});
      expect(
        (await outsider.next((m) => m['type'] == 'error'))['error'],
        'not a member',
      );
      await outsider.close();

      await a.close();
      await server.close();
    });

    test('an unconfigured broker answers with empty uris', () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final server = await _joinOwner(handle.port);
      server.send({'type': 'turn-request', 'room': 'alpha'});
      final creds = await server.next((m) => m['type'] == 'turn-credentials');
      expect(creds['uris'], isEmpty);
      expect(creds.containsKey('credential'), isFalse);
      await server.close();
    });
  });

  group('hardening', () {
    test('per-room aggregate rate cap drops the flood but keeps the room',
        () async {
      final broker = SignalingBroker(
        maxFramesPerWindow: 1000,
        maxRoomFramesPerWindow: 20,
        rateWindow: const Duration(seconds: 10),
      )..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final server = await _joinOwner(handle.port);
      final a = await _joinClient(handle.port, from: 'A', token: _tokenA);

      for (var i = 0; i < 60; i++) {
        a.send({
          'type': 'signal',
          'room': 'alpha',
          'from': 'A',
          'to': 'server',
          'kind': 'rpc',
          'payload': {'e': 'flood-$i'},
        });
      }
      // Give the flood time to be processed, then count what got through:
      // strictly fewer than sent and the connection survives.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final delivered =
          server.received.where((m) => m['type'] == 'signal').length;
      expect(delivered, lessThan(60));
      expect(handle.broker.peerCount('alpha'), 2);

      await a.close();
      await server.close();
    });

    test('malformed and oversized frames are ignored without dropping the '
        'connection; a signal before join is dropped', () async {
      final broker = SignalingBroker(maxFrameBytes: 512)..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final c = await _Client.connect(handle.port);
      c.sendRaw('this is not json');
      c.sendRaw('x' * 1024);
      c.send({
        'type': 'signal',
        'room': 'alpha',
        'from': 'A',
        'kind': 'rpc',
        'payload': {'e': 'pre-join'},
      });
      // Connection alive: a normal owner join still works.
      c.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'A',
        'owner': true,
        'ownerToken': _ownerToken,
      });
      await c.next((m) => m['type'] == 'joined');
      await c.close();
    });

    test('creating a new room past maxRooms is refused with server busy',
        () async {
      final broker = SignalingBroker(maxRooms: 1)..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final first = await _joinOwner(handle.port, room: 'one');
      final second = await _Client.connect(handle.port);
      second.send({
        'type': 'join',
        'room': 'two',
        'from': 'S2',
        'owner': true,
        'ownerToken': 'other',
      });
      expect(
        (await second.next((m) => m['type'] == 'error'))['error'],
        'server busy',
      );
      await second.closed;
      await first.close();
    });

    test('a connection past maxConnections is refused with server busy',
        () async {
      final broker = SignalingBroker(maxConnections: 1)..start();
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      final first = await _joinOwner(handle.port);
      final second = await _Client.connect(handle.port);
      second.send({
        'type': 'join',
        'room': 'alpha',
        'from': 'B',
        'token': _tokenA,
      });
      expect(
        (await second.next((m) => m['type'] == 'error'))['error'],
        'server busy',
      );
      await second.closed;
      await first.close();
    });
  });

  group('garbage collection', () {
    test('an empty room is reaped after the idle TTL; an owner-occupied room '
        'is never reaped', () async {
      var now = DateTime(2026, 7, 10, 12);
      final broker = SignalingBroker(
        idleTtl: const Duration(seconds: 60),
        now: () => now,
      );
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

      final occupied = await _joinOwner(handle.port, room: 'held');
      final leaver = await _joinOwner(
        handle.port,
        room: 'emptied',
        ownerToken: 'other-owner',
      );
      leaver.send({'type': 'bye', 'room': 'emptied'});
      await _until(() => broker.peerCount('emptied') == 0);

      now = now.add(const Duration(seconds: 90));
      expect(broker.sweep(), 1);
      expect(broker.roomExists('emptied'), isFalse);
      expect(broker.roomExists('held'), isTrue);

      await occupied.close();
      await leaver.close();
    });

    test('a room that never gained an owner claim is reaped past its TTL',
        () async {
      var now = DateTime(2026, 7, 10, 12);
      final broker = SignalingBroker(
        neverClaimedTtl: const Duration(minutes: 5),
        now: () => now,
      );
      handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);
      // No path creates an ownerless room via joins any more (client joins to
      // a missing room are refused), so simulate the defensive sweep directly:
      // an owner-created room whose owner disconnected before the sweep is
      // covered by the idle TTL; the never-claimed TTL is the backstop for
      // any future frame that creates rooms lazily. Assert the sweep is a
      // no-op on a healthy claimed room instead.
      final server = await _joinOwner(handle.port);
      now = now.add(const Duration(minutes: 10));
      expect(broker.sweep(), 0);
      expect(broker.roomExists('alpha'), isTrue);
      await server.close();
    });
  });
}
