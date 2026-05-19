import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/features/remote_control/data/signaling/signaling_client.dart';
import 'package:control_center/features/remote_control/data/signaling/signaling_message.dart';
import 'package:flutter_test/flutter_test.dart';

/// A throwaway WebSocket broker for exercising [SignalingClient] over real I/O.
///
/// It records every `join` frame, acks each with `joined`, can drop the live
/// socket to mimic a broker blip, and can relay an arbitrary frame to the
/// connected client. Just enough surface to assert the client's join/reconnect
/// behaviour without depending on the full `cc_signaling_server` package.
class _FakeBroker {
  _FakeBroker(this._server) {
    _server.listen(_onRequest);
  }

  final HttpServer _server;

  /// Every `join` frame received, in order (across reconnects).
  final List<Map<String, dynamic>> joins = [];

  WebSocket? _current;
  final List<Completer<void>> _joinWaiters = [];

  static Future<_FakeBroker> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeBroker(server);
  }

  Uri get url => Uri.parse('ws://127.0.0.1:${_server.port}/');

  Future<void> _onRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }
    // Echo the client's subprotocol so the handshake matches what the real
    // broker negotiates ('cc-signaling').
    // ignore: close_sinks — closed in [close]; the analyzer can't track it here.
    final socket = await WebSocketTransformer.upgrade(
      request,
      protocolSelector: (protocols) =>
          protocols.contains('cc-signaling') ? 'cc-signaling' : null,
    );
    _current = socket;
    socket.listen((dynamic data) {
      if (data is! String) {
        return;
      }
      final frame = jsonDecode(data) as Map<String, dynamic>;
      if (frame['type'] == 'join') {
        joins.add(frame);
        socket.add(jsonEncode({'type': 'joined', 'room': frame['room']}));
        for (final w in _joinWaiters) {
          if (!w.isCompleted) {
            w.complete();
          }
        }
        _joinWaiters.clear();
      }
    });
  }

  /// Resolves once at least [n] total `join` frames have been received.
  Future<void> awaitJoins(
    int n, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    while (joins.length < n) {
      final waiter = Completer<void>();
      _joinWaiters.add(waiter);
      await waiter.future.timeout(timeout);
    }
  }

  /// Closes the current client socket to mimic a broker-side drop.
  Future<void> dropCurrent() async {
    await _current?.close();
  }

  /// Relays [frame] to the connected client over the current socket.
  void relay(Map<String, dynamic> frame) => _current?.add(jsonEncode(frame));

  Future<void> close() async {
    try {
      await _current?.close();
    } catch (_) {
      // Already closed.
    }
    await _server.close(force: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBroker broker;

  setUp(() async {
    broker = await _FakeBroker.start();
  });

  tearDown(() async {
    await broker.close();
  });

  test('connect joins the room with the peer id', () async {
    final client = SignalingClient(url: broker.url, room: 'r1', peerId: 'desk');
    addTearDown(client.close);

    await client.connect();
    await broker.awaitJoins(1);

    expect(broker.joins.single['room'], 'r1');
    expect(broker.joins.single['from'], 'desk');
  });

  test(
    'auto-reconnects and re-joins after the broker drops the socket',
    () async {
      final client = SignalingClient(
        url: broker.url,
        room: 'r2',
        peerId: 'desk',
      );
      addTearDown(client.close);

      await client.connect();
      await broker.awaitJoins(1);

      // Broker blip: the socket drops. The client must reconnect and re-join the
      // SAME room with the SAME peer id, restoring its presence — without this a
      // phone can never reconnect after the desktop's signaling socket flaps.
      await broker.dropCurrent();
      await broker.awaitJoins(2);

      expect(broker.joins.length, greaterThanOrEqualTo(2));
      expect(broker.joins[1]['room'], 'r2');
      expect(broker.joins[1]['from'], 'desk');
    },
  );

  test('a broker drop is not surfaced to listeners as a peer-left', () async {
    final client = SignalingClient(url: broker.url, room: 'r3', peerId: 'desk');
    addTearDown(client.close);

    final events = <SignalingMessage>[];
    final sub = client.incoming.listen(events.add);
    addTearDown(sub.cancel);

    await client.connect();
    await broker.awaitJoins(1);
    await broker.dropCurrent();
    await broker.awaitJoins(2); // reconnected

    // A broker disconnect must NOT look like the phone leaving — that would
    // tear down a live RTC session that actually survives a broker blip.
    expect(
      events.where((e) => e.type == SignalingMessageType.peerLeft),
      isEmpty,
    );
  });

  test(
    'the incoming stream survives a reconnect and delivers later frames',
    () async {
      final client = SignalingClient(
        url: broker.url,
        room: 'r4',
        peerId: 'desk',
      );
      addTearDown(client.close);

      final peerLeft = Completer<SignalingMessage>();
      final sub = client.incoming.listen((m) {
        if (m.type == SignalingMessageType.peerLeft && !peerLeft.isCompleted) {
          peerLeft.complete(m);
        }
      });
      addTearDown(sub.cancel);

      await client.connect();
      await broker.awaitJoins(1);
      await broker.dropCurrent();
      await broker.awaitJoins(2); // reconnected on a fresh socket

      // A genuine peer-left over the new socket is still delivered.
      broker.relay({'type': 'peer-left', 'room': 'r4', 'from': 'PHONE'});
      final msg = await peerLeft.future.timeout(const Duration(seconds: 5));
      expect(msg.from, 'PHONE');
    },
  );

  test('close stops reconnection', () async {
    final client = SignalingClient(url: broker.url, room: 'r5', peerId: 'desk');

    await client.connect();
    await broker.awaitJoins(1);
    await client.close();

    // The drop happens after close; the client must not resurrect itself.
    await broker.dropCurrent();
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(broker.joins.length, 1);
  });
}
