import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_infra/src/rigs/qmp_client.dart';
import 'package:test/test.dart';

/// A `QmpSocket` driven entirely from the test, so the input path is exercised
/// without a hypervisor. Without the seam the ordering that makes a ctrl-click
/// a ctrl-click could only be checked by booting a VM and looking at it.
class _FakeQmpSocket implements QmpSocket {
  _FakeQmpSocket({this.greets = true}) {
    _incoming = StreamController<List<int>>.broadcast(
      onListen: () {
        if (!greets) {
          return;
        }
        // A broadcast controller drops what is added before anyone listens, and
        // QEMU's greeting is the first thing on the wire — pushing it from
        // `onListen` is what makes a reconnect's handshake reachable.
        scheduleMicrotask(() => _push({
          'QMP': {
            'version': {'qemu': {'major': 9}},
          },
        }));
      },
    );
  }

  late final StreamController<List<int>> _incoming;
  final Completer<void> _done = Completer<void>();

  /// Whether this socket sends QEMU's `QMP` greeting when the client attaches.
  final bool greets;

  /// Commands the client sent, decoded, in order.
  final List<Map<String, dynamic>> sent = [];

  /// Whether commands are answered at all. False leaves them in flight, which
  /// is the only way to have a pending command when the socket dies.
  bool answers = true;

  /// Returns an error description for a command that should fail, or null to
  /// let it succeed.
  String? Function(Map<String, dynamic> command)? errorFor;

  /// Returns the `return` payload for a command, or null for an empty one.
  Map<String, dynamic>? Function(Map<String, dynamic> command)? returnFor;

  @override
  Stream<List<int>> get stream => _incoming.stream;

  @override
  Future<void> get done => _done.future;

  @override
  void write(String data) {
    for (final line in const LineSplitter().convert(data)) {
      if (line.trim().isEmpty) {
        continue;
      }
      final decoded = jsonDecode(line) as Map<String, dynamic>;
      sent.add(decoded);
      if (!answers) {
        continue;
      }
      final failure = errorFor?.call(decoded);
      // Answer on a later microtask, as QEMU would.
      scheduleMicrotask(() {
        _push({
          'id': decoded['id'],
          if (failure == null)
            'return': returnFor?.call(decoded) ?? <String, dynamic>{}
          else
            'error': {'class': 'GenericError', 'desc': failure},
        });
      });
    }
  }

  /// Pushes an unsolicited event, as QEMU does for `SHUTDOWN`/`RESET`/`STOP`.
  void pushEvent(Map<String, dynamic> event) => _push(event);

  /// Kills the socket from the QEMU side — the case the client cannot tell
  /// from a deliberate close unless it tracks the difference itself.
  void kill() {
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  void _push(Map<String, dynamic> message) {
    if (_incoming.isClosed) {
      return;
    }
    _incoming.add(utf8.encode('${jsonEncode(message)}\n'));
  }

  @override
  Future<void> close() async {
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
    if (!_done.isCompleted) {
      _done.complete();
    }
  }

  @override
  void destroy() {}
}

/// Lets every pending microtask and short timer run.
Future<void> _settle([int millis = 5]) =>
    Future<void>.delayed(Duration(milliseconds: millis));

/// Flattens every `input-send-event` the client sent into readable atoms, so a
/// failure names the event that was out of order rather than dumping JSON.
List<String> _inputTrace(List<Map<String, dynamic>> sent) => [
  for (final command in sent)
    if (command['execute'] == 'input-send-event')
      for (final event
          in ((command['arguments'] as Map)['events'] as List)
              .cast<Map<String, dynamic>>())
        _describe(event),
];

String _describe(Map<String, dynamic> event) {
  final data = event['data'] as Map<String, dynamic>;
  return switch (event['type']) {
    'key' =>
      '${(data['down'] as bool) ? 'key-down' : 'key-up'} '
          '${(data['key'] as Map)['data']}',
    'btn' =>
      '${(data['down'] as bool) ? 'btn-down' : 'btn-up'} ${data['button']}',
    'abs' => 'abs ${data['axis']}=${data['value']}',
    _ => 'unknown ${event['type']}',
  };
}

void main() {
  group('held-modifier clicks', () {
    test('a modifier is held DOWN across the button press and release', () async {
      // The regression this pins: modifiers were sent as a complete
      // press-and-release chord BEFORE the click, so ctrl was already up by
      // the time the button went down and ctrl+click was a plain click that
      // reported success.
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);

      await client.clickWithModifiers(
        RigMouseButton.left,
        modifierKeys: ['ctrl'],
      );

      expect(_inputTrace(socket.sent), [
        'key-down ctrl',
        'btn-down left',
        'btn-up left',
        'key-up ctrl',
      ]);
      await client.close();
    });

    test('several modifiers release in reverse press order', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);

      await client.clickWithModifiers(
        RigMouseButton.right,
        modifierKeys: ['ctrl', 'shift'],
      );

      expect(_inputTrace(socket.sent), [
        'key-down ctrl',
        'key-down shift',
        'btn-down right',
        'btn-up right',
        'key-up shift',
        'key-up ctrl',
      ]);
      await client.close();
    });

    test('a double click keeps the modifier down for BOTH clicks', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);

      await client.clickWithModifiers(
        RigMouseButton.left,
        modifierKeys: ['shift'],
        clicks: 2,
      );

      expect(_inputTrace(socket.sent), [
        'key-down shift',
        'btn-down left',
        'btn-up left',
        'btn-down left',
        'btn-up left',
        'key-up shift',
      ]);
      await client.close();
    });

    test('the modifier is released even when the click fails', () async {
      // A modifier left down stays down for the life of the VM, and every
      // later keystroke in that guest silently becomes a different chord.
      final socket = _FakeQmpSocket()
        ..errorFor = (command) {
          final events = (command['arguments'] as Map?)?['events'];
          final isButton =
              events is List && events.any((e) => (e as Map)['type'] == 'btn');
          return isButton ? 'no pointer device' : null;
        };
      final client = QmpClient.over(socket);

      await expectLater(
        client.clickWithModifiers(
          RigMouseButton.left,
          modifierKeys: ['ctrl'],
        ),
        throwsA(
          isA<QmpException>().having(
            (e) => e.message,
            'message',
            contains('no pointer device'),
          ),
        ),
      );
      expect(
        _inputTrace(socket.sent),
        containsAllInOrder(['key-down ctrl', 'key-up ctrl']),
      );
      await client.close();
    });

    test('no modifiers means no key events at all', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);

      await client.clickWithModifiers(
        RigMouseButton.middle,
        modifierKeys: const [],
      );

      expect(_inputTrace(socket.sent), ['btn-down middle', 'btn-up middle']);
      await client.close();
    });
  });

  group('key primitives', () {
    test('holdKeys sends qcode key events with down: true', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);
      await client.holdKeys(['alt']);
      final events =
          ((socket.sent.single['arguments'] as Map)['events'] as List).single
              as Map;
      expect(events['type'], 'key');
      expect((events['data'] as Map)['down'], isTrue);
      expect((events['data'] as Map)['key'] as Map, {
        'type': 'qcode',
        'data': 'alt',
      });
      await client.close();
    });

    test('an empty key list sends nothing', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);
      await client.holdKeys(const []);
      await client.releaseKeys(const []);
      expect(socket.sent, isEmpty);
      await client.close();
    });
  });

  group('liveness', () {
    test('ping reports QEMU own run state', () async {
      final socket = _FakeQmpSocket()
        ..returnFor = (command) => command['execute'] == 'query-status'
            ? {'status': 'paused', 'running': false}
            : null;
      final client = QmpClient.over(socket);
      expect(await client.ping(), 'paused');
      expect(socket.sent.single['execute'], 'query-status');
      await client.close();
    });
  });

  group('reconnect', () {
    /// A policy that hands out [replacements] in order, then fails.
    QmpReconnectPolicy policyOver(
      List<_FakeQmpSocket> replacements, {
      Duration window = const Duration(seconds: 2),
      Duration handshakeTimeout = const Duration(seconds: 2),
      void Function()? onDial,
    }) {
      var index = 0;
      return QmpReconnectPolicy(
        connect: () async {
          onDial?.call();
          if (index >= replacements.length) {
            throw const QmpException('nothing listening on the QMP socket');
          }
          return replacements[index++];
        },
        backoff: const [Duration(milliseconds: 1)],
        window: window,
        handshakeTimeout: handshakeTimeout,
      );
    }

    test('a dead socket redials and replays the capability handshake', () async {
      // The regression this pins: a QMP socket dying while QEMU lives left the
      // rig `ready` and every action failing "QMP socket is closed" forever.
      final first = _FakeQmpSocket();
      final second = _FakeQmpSocket();
      final client = QmpClient.over(first, reconnect: policyOver([second]));

      first.kill();
      await client.connectionStates.firstWhere(
        (s) => s == QmpConnectionState.connected,
      );

      expect(
        second.sent.first['execute'],
        'qmp_capabilities',
        reason: 'A fresh QMP socket refuses every command until the handshake '
            'runs, so a reconnect that skips it answers nothing.',
      );
      await client.stop();
      expect(second.sent.last['execute'], 'stop');
      expect(client.isConnected, isTrue);
      await client.close();
    });

    test('an in-flight command fails saying a reconnect is under way', () async {
      final first = _FakeQmpSocket()..answers = false;
      final second = _FakeQmpSocket();
      final client = QmpClient.over(first, reconnect: policyOver([second]));

      final inFlight = client.execute('query-status');
      await _settle();
      first.kill();

      await expectLater(
        inFlight,
        throwsA(
          isA<QmpException>().having(
            (e) => e.message,
            'message',
            contains('reconnect is in progress'),
          ),
        ),
      );
      await client.connectionStates.firstWhere(
        (s) => s == QmpConnectionState.connected,
      );
      await client.close();
    });

    test('a command issued mid-reconnect fails fast, not silently', () async {
      // Queueing would be worse: an action that waits for a socket is
      // indistinguishable from a hung guest.
      final first = _FakeQmpSocket();
      final client = QmpClient.over(
        first,
        reconnect: policyOver([], window: const Duration(milliseconds: 200)),
      );
      first.kill();
      await _settle();
      expect(client.connectionState, QmpConnectionState.reconnecting);
      expect(client.isConnected, isFalse);
      await expectLater(
        client.execute('stop'),
        throwsA(
          isA<QmpException>().having(
            (e) => e.message,
            'message',
            contains('reconnect is in progress'),
          ),
        ),
      );
      await client.close();
    });

    test('the state stream reports connected → reconnecting → connected',
        () async {
      final first = _FakeQmpSocket();
      final second = _FakeQmpSocket();
      final client = QmpClient.over(first, reconnect: policyOver([second]));
      final states = <QmpConnectionState>[];
      final sub = client.connectionStates.listen(states.add);
      await _settle();

      first.kill();
      await client.connectionStates.firstWhere(
        (s) => s == QmpConnectionState.connected,
      );
      await _settle();

      expect(states, [
        QmpConnectionState.connected,
        QmpConnectionState.reconnecting,
        QmpConnectionState.connected,
      ]);
      await sub.cancel();
      await client.close();
    });

    test('an exhausted window ends in the terminal closed state', () async {
      final first = _FakeQmpSocket();
      final client = QmpClient.over(
        first,
        reconnect: policyOver([], window: const Duration(milliseconds: 10)),
      );
      final states = <QmpConnectionState>[];
      final sub = client.connectionStates.listen(states.add);
      await _settle();

      first.kill();
      await _settle(120);

      expect(client.connectionState, QmpConnectionState.closed);
      expect(states, [
        QmpConnectionState.connected,
        QmpConnectionState.reconnecting,
        QmpConnectionState.closed,
      ]);
      await expectLater(
        client.execute('stop'),
        throwsA(
          isA<QmpException>().having(
            (e) => e.message,
            'message',
            contains('closed'),
          ),
        ),
      );
      await sub.cancel();
      await client.close();
    });

    test('a deliberate close never redials', () async {
      // Otherwise every teardown resurrects the client it just tore down.
      var dials = 0;
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(
        socket,
        reconnect: policyOver([_FakeQmpSocket()], onDial: () => dials++),
      );

      await client.close();
      await _settle(20);

      expect(dials, 0);
      expect(client.connectionState, QmpConnectionState.closed);
    });

    test('a close DURING a reconnect stops the redial', () async {
      var dials = 0;
      final first = _FakeQmpSocket();
      final client = QmpClient.over(
        first,
        reconnect: policyOver(
          [],
          window: const Duration(seconds: 5),
          onDial: () => dials++,
        ),
      );
      first.kill();
      await _settle();
      await client.close();
      final dialsAtClose = dials;
      await _settle(30);

      expect(client.connectionState, QmpConnectionState.closed);
      expect(dials, dialsAtClose);
    });

    test('a machine we asked to quit is not redialled', () async {
      // Otherwise every ordinary teardown spends the reconnect window failing
      // against a hypervisor we killed on purpose, and logs a warning for it.
      var dials = 0;
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(
        socket,
        reconnect: policyOver([_FakeQmpSocket()], onDial: () => dials++),
      );

      await client.quit();
      socket.kill();
      await _settle(20);

      expect(dials, 0);
      expect(client.connectionState, QmpConnectionState.closed);
    });

    test('a SHUTDOWN event means the death that follows is not a blip',
        () async {
      var dials = 0;
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(
        socket,
        reconnect: policyOver([_FakeQmpSocket()], onDial: () => dials++),
      );

      socket.pushEvent({'event': 'SHUTDOWN'});
      await _settle();
      socket.kill();
      await _settle(20);

      expect(dials, 0);
      expect(client.connectionState, QmpConnectionState.closed);
    });

    test('without a policy a dead socket is terminal, as before', () async {
      final socket = _FakeQmpSocket();
      final client = QmpClient.over(socket);
      socket.kill();
      await _settle();
      expect(client.connectionState, QmpConnectionState.closed);
      await expectLater(client.execute('stop'), throwsA(isA<QmpException>()));
    });

    test('a socket that never greets is not adopted', () async {
      // A QMP socket that accepts but never greets is QEMU mid-start (or
      // something else entirely on that path); handshaking against it would
      // hand back a client that answers nothing.
      final first = _FakeQmpSocket();
      final silent = _FakeQmpSocket(greets: false);
      final good = _FakeQmpSocket();
      final client = QmpClient.over(
        first,
        reconnect: policyOver(
          [silent, good],
          handshakeTimeout: const Duration(milliseconds: 30),
        ),
      );

      first.kill();
      await client.connectionStates.firstWhere(
        (s) => s == QmpConnectionState.connected,
      );

      expect(silent.sent, isEmpty);
      expect(good.sent.first['execute'], 'qmp_capabilities');
      await client.close();
    });

    test('the events stream survives a reconnect', () async {
      // A consumer that has to resubscribe after every blink is a consumer
      // that silently stops receiving events.
      final first = _FakeQmpSocket();
      final second = _FakeQmpSocket();
      final client = QmpClient.over(first, reconnect: policyOver([second]));
      final seen = <String>[];
      final sub = client.events.listen((e) => seen.add('${e['event']}'));

      first.kill();
      await client.connectionStates.firstWhere(
        (s) => s == QmpConnectionState.connected,
      );
      second.pushEvent({'event': 'RESET'});
      await _settle();

      expect(seen, ['RESET']);
      await sub.cancel();
      await client.close();
    });
  });
}
