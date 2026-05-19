import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// [SlackSocketModeClient]: the envelope protocol and the reconnect policy.
///
/// Socket Mode's contract is unforgiving in three specific ways, and each one
/// has a test here because the failure mode is silent: acking late duplicates
/// every slow dispatch, treating Slack's routine `disconnect` as a failure walks
/// the backoff up to 30s pauses, and retrying a rejected token hammers Slack
/// forever while the settings screen shows "connecting".
void main() {
  test('acks an envelope before running the handler', () async {
    final handled = Completer<void>();
    final gate = Completer<void>();
    final socket = _FakeSocket();
    final client = _client(
      socket,
      onEnvelope: (envelope) async {
        handled.complete();
        // A real dispatch takes minutes; the ack must already be out.
        await gate.future;
      },
    );

    await client.start();
    socket.push({
      'type': 'events_api',
      'envelope_id': 'e1',
      'payload': {
        'event_id': 'Ev1',
        'event': {'type': 'app_mention'},
      },
    });
    await handled.future;

    expect(socket.sent, [
      {'envelope_id': 'e1'},
    ]);
    gate.complete();
    await client.stop();
  });

  test('a redelivery reaches the handler with the same dedupe key', () async {
    final keys = <String>[];
    final attempts = <int>[];
    final socket = _FakeSocket();
    final client = _client(
      socket,
      onEnvelope: (envelope) async {
        keys.add(envelope.dedupeKey);
        attempts.add(envelope.retryAttempt);
      },
    );

    await client.start();
    // Slack's redelivery carries a NEW envelope id but the same event id, which
    // is why the bridge dedupes on the event and not on the envelope.
    socket.push({
      'type': 'events_api',
      'envelope_id': 'e1',
      'payload': {'event_id': 'Ev1'},
    });
    socket.push({
      'type': 'events_api',
      'envelope_id': 'e2',
      'retry_attempt': 1,
      'retry_reason': 'timeout',
      'payload': {'event_id': 'Ev1'},
    });
    await pumpEventQueue();

    expect(keys, ['Ev1', 'Ev1']);
    expect(attempts, [0, 1]);
    expect(socket.sent.map((f) => f['envelope_id']), ['e1', 'e2']);
    await client.stop();
  });

  test('control frames are not acked and never reach the handler', () async {
    var handled = 0;
    final socket = _FakeSocket();
    final client = _client(socket, onEnvelope: (_) async => handled++);

    await client.start();
    socket
      ..push({'type': 'hello', 'num_connections': 1})
      ..push({'type': 'events_api', 'payload': const {}});
    await pumpEventQueue();

    expect(handled, 0);
    expect(socket.sent, isEmpty);
    expect(client.state, ChatConnectionState.connected);
    await client.stop();
  });

  test('a disconnect refresh reconnects on a fresh url', () async {
    final sockets = <_FakeSocket>[];
    final client = _client(
      null,
      connector: (url) async {
        final socket = _FakeSocket(url: url);
        sockets.add(socket);
        return socket;
      },
    );

    await client.start();
    expect(sockets, hasLength(1));

    sockets.first.push({'type': 'disconnect', 'reason': 'refresh_requested'});
    await pumpEventQueue();

    // Reconnect is immediate (no backoff wait) and the old socket is released.
    expect(sockets, hasLength(2));
    expect(sockets.first.closed, isTrue);
    expect(client.isConnected, isTrue);
    expect(client.lastError, isNull);
    await client.stop();
  });

  test('link_disabled is terminal — Slack refuses the reconnect', () async {
    final sockets = <_FakeSocket>[];
    final client = _client(
      null,
      connector: (url) async {
        final socket = _FakeSocket(url: url);
        sockets.add(socket);
        return socket;
      },
    );

    await client.start();
    sockets.first.push({'type': 'disconnect', 'reason': 'link_disabled'});
    await pumpEventQueue();

    expect(sockets, hasLength(1));
    expect(client.state, ChatConnectionState.error);
    expect(client.lastError, 'link_disabled');
    await client.stop();
  });

  test('a dropped socket reconnects', () async {
    final sockets = <_FakeSocket>[];
    final client = _client(
      null,
      connector: (url) async {
        final socket = _FakeSocket(url: url);
        sockets.add(socket);
        return socket;
      },
    );

    await client.start();
    await sockets.first.drop();
    // First backoff step is ~500ms + jitter.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(sockets.length, greaterThanOrEqualTo(2));
    expect(client.isConnected, isTrue);
    await client.stop();
  });

  test('a rejected app token stops instead of retrying', () async {
    var connects = 0;
    final client = SlackSocketModeClient(
      workspaceId: 'ws-1',
      appToken: 'xapp-dead',
      api: _api(error: 'invalid_auth'),
      onEnvelope: (_) async {},
      connector: (url) async {
        connects++;
        return _FakeSocket(url: url);
      },
    );

    await client.start();
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(connects, 0);
    expect(client.state, ChatConnectionState.error);
    expect(client.lastError, 'invalid_auth');
    await client.stop();
  });

  test('a transient open failure keeps retrying', () async {
    var opens = 0;
    final dio = Dio()
      ..httpClientAdapter = _ScriptedAdapter(() {
        opens++;
        return opens == 1
            ? {'ok': false, 'error': 'ratelimited'}
            : {'ok': true, 'url': 'wss://slack.test/ws'};
      });
    final client = SlackSocketModeClient(
      workspaceId: 'ws-1',
      appToken: 'xapp-1',
      api: SlackApiClient(dio: dio, botToken: 'xoxb-1'),
      onEnvelope: (_) async {},
      connector: (url) async => _FakeSocket(url: url),
    );

    await client.start();
    expect(client.state, ChatConnectionState.error);
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(client.isConnected, isTrue);
    await client.stop();
  });

  test('a throwing handler does not take the connection down', () async {
    final socket = _FakeSocket();
    final client = _client(
      socket,
      onEnvelope: (_) async => throw StateError('bad event'),
    );

    await client.start();
    socket.push({
      'type': 'events_api',
      'envelope_id': 'e1',
      'payload': const {},
    });
    await pumpEventQueue();

    expect(client.isConnected, isTrue);
    expect(socket.sent, hasLength(1));
    await client.stop();
  });

  test('stop() closes the socket and does not reconnect', () async {
    final sockets = <_FakeSocket>[];
    final client = _client(
      null,
      connector: (url) async {
        final socket = _FakeSocket(url: url);
        sockets.add(socket);
        return socket;
      },
    );

    await client.start();
    await client.stop();
    expect(sockets.single.closed, isTrue);
    expect(client.state, ChatConnectionState.disconnected);

    // A drop after stop() must stay stopped.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    expect(sockets, hasLength(1));
  });

  group('SlackEnvelope', () {
    test('falls back through event id, trigger id, then envelope id', () {
      expect(
        SlackEnvelope.fromJson({
          'type': 'events_api',
          'envelope_id': 'env',
          'payload': {'event_id': 'Ev1', 'trigger_id': 'T1'},
        }).dedupeKey,
        'Ev1',
      );
      expect(
        SlackEnvelope.fromJson({
          'type': 'slash_commands',
          'envelope_id': 'env',
          'payload': {'trigger_id': 'T1'},
        }).dedupeKey,
        'T1',
      );
      expect(
        SlackEnvelope.fromJson({
          'type': 'interactive',
          'envelope_id': 'env',
          'payload': const {},
        }).dedupeKey,
        'env',
      );
    });

    test('reads the team id from either payload shape', () {
      expect(
        SlackEnvelope.fromJson({
          'payload': {'team_id': 'T9'},
        }).teamId,
        'T9',
      );
      expect(
        SlackEnvelope.fromJson({
          'payload': {
            'team': {'id': 'T9'},
          },
        }).teamId,
        'T9',
      );
    });
  });
}

SlackSocketModeClient _client(
  _FakeSocket? socket, {
  SlackEnvelopeHandler? onEnvelope,
  SlackSocketConnector? connector,
}) => SlackSocketModeClient(
  workspaceId: 'ws-1',
  appToken: 'xapp-1',
  api: _api(),
  onEnvelope: onEnvelope ?? (_) async {},
  connector: connector ?? (url) async => socket!..url = url,
);

SlackApiClient _api({String? error}) => SlackApiClient(
  dio: Dio()
    ..httpClientAdapter = _ScriptedAdapter(
      () => error != null
          ? {'ok': false, 'error': error}
          : {'ok': true, 'url': 'wss://slack.test/ws?ticket=${_ticket++}'},
    ),
  botToken: 'xoxb-1',
);

int _ticket = 0;

/// Answers every Slack call from one closure, so a test can flip the reply.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.body);

  final Map<String, dynamic> Function() body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body()),
    200,
    headers: const {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// An in-memory Socket Mode socket: tests push frames down and read acks back
/// without standing up a TLS WebSocket server.
class _FakeSocket implements SlackSocket {
  _FakeSocket({this.url});

  Uri? url;
  final _frames = StreamController<dynamic>();
  final List<Map<String, dynamic>> sent = [];
  bool closed = false;

  void push(Map<String, dynamic> frame) => _frames.add(jsonEncode(frame));

  /// The connection dying under us (network blip, laptop sleep).
  Future<void> drop() async {
    closed = true;
    await _frames.close();
  }

  @override
  Stream<dynamic> get messages => _frames.stream;

  @override
  bool get isOpen => !closed;

  @override
  void send(String message) =>
      sent.add(Map<String, dynamic>.from(jsonDecode(message) as Map));

  @override
  Future<void> close() async {
    closed = true;
    if (!_frames.isClosed) {
      await _frames.close();
    }
  }
}
