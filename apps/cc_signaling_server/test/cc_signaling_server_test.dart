import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_signaling_server/cc_signaling_server.dart';
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

  void send(Map<String, dynamic> frame) => _socket.add(jsonEncode(frame));
  void sendRaw(String text) => _socket.add(text);

  Future<void> get closed => _closed.future;

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

void main() {
  late SignalingServerHandle handle;

  tearDown(() async {
    await handle.close();
  });

  test('two peers join: both ack joined and receive peer-joined', () async {
    handle = await serveSignaling(host: 'localhost', port: 0);
    final a = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'alpha', 'from': 'A'});
    final ackA = await a.next((m) => m['type'] == 'joined');
    expect(ackA['room'], 'alpha');
    expect(ackA.containsKey('from'), isFalse);

    final b = await _Client.connect(handle.port);
    b.send({'type': 'join', 'room': 'alpha', 'from': 'B'});
    final ackB = await b.next((m) => m['type'] == 'joined');
    expect(ackB['room'], 'alpha');

    // Symmetric peer-joined: both peers are notified the room is now shared.
    final aNotified = await a.next((m) => m['type'] == 'peer-joined');
    final bNotified = await b.next((m) => m['type'] == 'peer-joined');
    expect(aNotified['room'], 'alpha');
    expect(bNotified['room'], 'alpha');

    await a.close();
    await b.close();
  });

  test('signal frame is forwarded verbatim to the other peer', () async {
    handle = await serveSignaling(host: 'localhost', port: 0);
    final a = await _Client.connect(handle.port);
    final b = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'bravo', 'from': 'A'});
    b.send({'type': 'join', 'room': 'bravo', 'from': 'B'});
    await a.next((m) => m['type'] == 'joined');
    await b.next((m) => m['type'] == 'joined');
    // Drain the symmetric peer-joined frames so they don't sit in the buffer.
    await a.next((m) => m['type'] == 'peer-joined');
    await b.next((m) => m['type'] == 'peer-joined');

    final offer = <String, dynamic>{
      'type': 'signal',
      'room': 'bravo',
      'from': 'A',
      'kind': 'offer',
      'payload': <String, dynamic>{
        'sdp': 'v=0\r\no=- 4611732344 1 IN IP4 127.0.0.1\r\n',
        'type': 'offer',
      },
    };
    a.send(offer);

    final received = await b.next((m) => m['type'] == 'signal');
    expect(received, offer);

    await a.close();
    await b.close();
  });

  test(
    'a third peer joining a full room is rejected and disconnected',
    () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final a = await _Client.connect(handle.port);
      final b = await _Client.connect(handle.port);
      a.send({'type': 'join', 'room': 'charlie', 'from': 'A'});
      b.send({'type': 'join', 'room': 'charlie', 'from': 'B'});
      await a.next((m) => m['type'] == 'joined');
      await b.next((m) => m['type'] == 'joined');

      final c = await _Client.connect(handle.port);
      c.send({'type': 'join', 'room': 'charlie', 'from': 'C'});
      final error = await c.next((m) => m['type'] == 'error');
      expect(error['error'], 'room full');
      await c.closed.timeout(const Duration(seconds: 2));

      await a.close();
      await b.close();
      await c.close();
    },
  );

  test(
    'a re-join with the same peer id evicts the stale connection '
    'instead of hitting "room full"',
    () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      // First desktop connection joins the room.
      final d1 = await _Client.connect(handle.port);
      d1.send({'type': 'join', 'room': 'echo', 'from': 'DESK'});
      await d1.next((m) => m['type'] == 'joined');

      // The same logical peer re-joins (same id) — a transient second desktop
      // instance or a signaling reconnect. It must be admitted and the stale
      // socket dropped, rather than the newcomer bouncing off "room full".
      final d2 = await _Client.connect(handle.port);
      d2.send({'type': 'join', 'room': 'echo', 'from': 'DESK'});
      final ack = await d2.next((m) => m['type'] == 'joined');
      expect(ack['room'], 'echo');
      // The stale first connection is closed by the broker.
      await d1.closed.timeout(const Duration(seconds: 2));

      // A distinct peer (the phone) still finds a free slot and pairs normally.
      final phone = await _Client.connect(handle.port);
      phone.send({'type': 'join', 'room': 'echo', 'from': 'PHONE'});
      await phone.next((m) => m['type'] == 'joined');
      final phoneJoined = await phone.next((m) => m['type'] == 'peer-joined');
      final deskJoined = await d2.next((m) => m['type'] == 'peer-joined');
      expect(phoneJoined['room'], 'echo');
      expect(deskJoined['room'], 'echo');

      await d1.close();
      await d2.close();
      await phone.close();
    },
  );

  test('a disconnect notifies the remaining peer with peer-left', () async {
    handle = await serveSignaling(host: 'localhost', port: 0);
    final a = await _Client.connect(handle.port);
    final b = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'delta', 'from': 'A'});
    b.send({'type': 'join', 'room': 'delta', 'from': 'B'});
    await a.next((m) => m['type'] == 'joined');
    await b.next((m) => m['type'] == 'joined');
    await a.next((m) => m['type'] == 'peer-joined');
    await b.next((m) => m['type'] == 'peer-joined');

    await b.close();

    final left = await a.next((m) => m['type'] == 'peer-left');
    expect(left['room'], 'delta');
    // The leaver's id is named so the remaining peer can ignore a stale
    // peer-left from a superseded connection (a fast phone refresh).
    expect(left['from'], 'B');
    await a.close();
  });

  test(
    'the remaining peer can pair with a fresh joiner after the other left '
    '(phone-refresh reconnect)',
    () async {
      // Models the desktop staying in the room while the phone refreshes: the
      // old phone tab leaves, a new one joins, and the broker must re-fire
      // peer-joined to the desktop (and the new tab) because the room became
      // shared again. The desktop relies on this to answer a reconnecting phone
      // without being restarted.
      handle = await serveSignaling(host: 'localhost', port: 0);
      final desktop = await _Client.connect(handle.port);
      desktop.send({'type': 'join', 'room': 'foxtrot', 'from': 'DESK'});
      await desktop.next((m) => m['type'] == 'joined');

      // First phone tab connects.
      final phone1 = await _Client.connect(handle.port);
      phone1.send({'type': 'join', 'room': 'foxtrot', 'from': 'PHONE-1'});
      await phone1.next((m) => m['type'] == 'joined');
      await phone1.next((m) => m['type'] == 'peer-joined');
      await desktop.next((m) => m['type'] == 'peer-joined');

      // It refreshes: the old tab drops; the desktop is told who left.
      await phone1.close();
      final left = await desktop.next((m) => m['type'] == 'peer-left');
      expect(left['from'], 'PHONE-1');

      // The new tab (a distinct peer id) joins — and because the desktop stayed
      // in the room, both sides get peer-joined and can negotiate again.
      final phone2 = await _Client.connect(handle.port);
      phone2.send({'type': 'join', 'room': 'foxtrot', 'from': 'PHONE-2'});
      await phone2.next((m) => m['type'] == 'joined');
      final phone2Joined = await phone2.next((m) => m['type'] == 'peer-joined');
      final deskRejoined = await desktop.next((m) => m['type'] == 'peer-joined');
      expect(phone2Joined['room'], 'foxtrot');
      expect(deskRejoined['room'], 'foxtrot');

      await desktop.close();
      await phone2.close();
    },
  );

  test('an empty room is reaped after the idle TTL', () async {
    var now = DateTime.utc(2026, 1, 1);
    final broker = SignalingBroker(
      idleTtl: const Duration(seconds: 1),
      neverFilledTtl: const Duration(minutes: 5),
      now: () => now,
    );
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'ttl-empty', 'from': 'A'});
    await a.next((m) => m['type'] == 'joined');
    expect(broker.roomExists('ttl-empty'), isTrue);

    await a.close();
    // Wait for the broker to process the disconnect (room becomes empty).
    await _until(() => broker.peerCount('ttl-empty') == 0);
    expect(broker.roomExists('ttl-empty'), isTrue);

    now = now.add(const Duration(seconds: 2));
    final reaped = broker.sweep();
    expect(reaped, 1);
    expect(broker.roomExists('ttl-empty'), isFalse);
  });

  test('a never-filled room is reaped past the never-filled TTL', () async {
    var now = DateTime.utc(2026, 1, 1);
    final broker = SignalingBroker(
      idleTtl: const Duration(hours: 1),
      neverFilledTtl: const Duration(seconds: 1),
      now: () => now,
    );
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'ttl-lonely', 'from': 'A'});
    await a.next((m) => m['type'] == 'joined');
    expect(broker.roomExists('ttl-lonely'), isTrue);

    now = now.add(const Duration(seconds: 2));
    final reaped = broker.sweep();
    expect(reaped, greaterThanOrEqualTo(1));
    expect(broker.roomExists('ttl-lonely'), isFalse);
    // The lone peer's socket is closed by the garbage collector.
    await a.closed.timeout(const Duration(seconds: 2));
  });

  test(
    'malformed frames are ignored without dropping the connection',
    () async {
      handle = await serveSignaling(host: 'localhost', port: 0);
      final a = await _Client.connect(handle.port);
      a.send({'type': 'join', 'room': 'echo', 'from': 'A'});
      await a.next((m) => m['type'] == 'joined');

      // Garbage that must not crash the broker or close the socket.
      a.sendRaw('not json at all');
      a.sendRaw('{"type": "bogus"}');
      a.sendRaw('[1, 2, 3]');

      // The connection is still usable.
      final b = await _Client.connect(handle.port);
      b.send({'type': 'join', 'room': 'echo', 'from': 'B'});
      await a.next((m) => m['type'] == 'peer-joined');

      await a.close();
      await b.close();
    },
  );

  test('a signal from a peer that never joined is dropped', () async {
    handle = await serveSignaling(host: 'localhost', port: 0);
    final spy = await _Client.connect(handle.port);
    spy.send({
      'type': 'signal',
      'room': 'phantom',
      'from': 'X',
      'kind': 'offer',
      'payload': <String, dynamic>{'sdp': 'noop', 'type': 'offer'},
    });

    // Wire up a real member of the room and confirm it never receives the
    // unsignaled blob (the broker drops frames from unjoined peers).
    final member = await _Client.connect(handle.port);
    member.send({'type': 'join', 'room': 'phantom', 'from': 'M'});
    await member.next((m) => m['type'] == 'joined');

    expect(
      () => member
          .next((m) => m['type'] == 'signal')
          .timeout(const Duration(milliseconds: 500)),
      throwsA(isA<TimeoutException>()),
    );

    await spy.close();
    await member.close();
  });

  // --- Hardening (finding #15) -------------------------------------------

  test('creating a new room past maxRooms is refused with "server busy"',
      () async {
    final broker = SignalingBroker(maxRooms: 1);
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'room-1', 'from': 'A'});
    await a.next((m) => m['type'] == 'joined');

    // A second *distinct* room would exceed the cap → refused + disconnected.
    final b = await _Client.connect(handle.port);
    b.send({'type': 'join', 'room': 'room-2', 'from': 'B'});
    final err = await b.next((m) => m['type'] == 'error');
    expect(err['error'], 'server busy');
    await b.closed.timeout(const Duration(seconds: 2));

    await a.close();
    await b.close();
  });

  test('a connection past maxConnections is refused with "server busy"',
      () async {
    final broker = SignalingBroker(maxConnections: 1);
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'cap', 'from': 'A'});
    await a.next((m) => m['type'] == 'joined');
    await _until(() => broker.connectionCount == 1);

    final b = await _Client.connect(handle.port);
    final err = await b.next((m) => m['type'] == 'error');
    expect(err['error'], 'server busy');
    await b.closed.timeout(const Duration(seconds: 2));

    await a.close();
    await b.close();
  });

  test('an oversized frame is dropped before decode', () async {
    final broker = SignalingBroker(maxFrameBytes: 64);
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    // A join padded well past the cap is dropped — so no `joined` ack arrives.
    a.send({
      'type': 'join',
      'room': 'big',
      'from': 'A' * 200,
    });
    expect(
      () => a.next(
        (m) => m['type'] == 'joined',
        timeout: const Duration(milliseconds: 500),
      ),
      throwsA(isA<TimeoutException>()),
    );

    await a.close();
  });

  test('per-connection rate limit drops frames over the budget', () async {
    // Budget of 1 frame per connection: the join is admitted, the subsequent
    // signal is dropped, so the peer never receives it.
    final broker = SignalingBroker(
      maxFramesPerWindow: 1,
      rateWindow: const Duration(hours: 1),
    );
    handle = await serveSignaling(host: 'localhost', port: 0, broker: broker);

    final a = await _Client.connect(handle.port);
    final b = await _Client.connect(handle.port);
    a.send({'type': 'join', 'room': 'rate', 'from': 'A'}); // A frame #1 (ok)
    b.send({'type': 'join', 'room': 'rate', 'from': 'B'}); // B frame #1 (ok)
    await a.next((m) => m['type'] == 'joined');
    await b.next((m) => m['type'] == 'joined');
    await b.next((m) => m['type'] == 'peer-joined');

    // A's second frame is over budget → dropped → B never sees the signal.
    a.send({
      'type': 'signal',
      'room': 'rate',
      'from': 'A',
      'kind': 'offer',
      'payload': <String, dynamic>{'sdp': 'x', 'type': 'offer'},
    });
    expect(
      () => b.next(
        (m) => m['type'] == 'signal',
        timeout: const Duration(milliseconds: 500),
      ),
      throwsA(isA<TimeoutException>()),
    );

    await a.close();
    await b.close();
  });
}
