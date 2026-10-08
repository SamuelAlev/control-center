import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_request_handler.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// A dispatcher whose `tools/call` finishes when the test says so, and which
/// keeps the abandonment signal each call was handed.
class _ControlledDispatcher extends McpToolDispatcher {
  _ControlledDispatcher() : super(registry: McpToolRegistry([]));

  final Completer<Map<String, dynamic>> result = Completer();
  final List<Future<void>?> abandonments = [];

  @override
  Future<Map<String, dynamic>> handleScopedRequest(
    JsonRpcRequest request, {
    McpCallScope? scope,
    Future<void>? abandoned,
  }) {
    abandonments.add(abandoned);
    return result.future;
  }

  void finish() => result.complete({
    'jsonrpc': '2.0',
    'id': 7,
    'result': {
      'content': [
        {'type': 'text', 'text': 'answered'},
      ],
    },
  });
}

const _streamAfter = Duration(milliseconds: 50);
const _heartbeat = Duration(milliseconds: 40);

Map<String, dynamic> _toolsCall({Object? progressToken}) => {
  'jsonrpc': '2.0',
  'id': 7,
  'method': 'tools/call',
  'params': {
    'name': 'ask_user',
    'arguments': <String, dynamic>{},
    if (progressToken != null) '_meta': {'progressToken': progressToken},
  },
};

Future<HttpClientResponse> _post(
  int port,
  Map<String, dynamic> body, {
  bool acceptsStream = true,
  String agentId = 'agent-1',
}) async {
  final client = HttpClient();
  try {
    final request = await client.post('127.0.0.1', port, '/mcp');
    request.headers
      ..contentType = ContentType.json
      ..set(
        HttpHeaders.acceptHeader,
        acceptsStream
            ? 'application/json, text/event-stream'
            : 'application/json',
      )
      ..set('X-CC-Agent-Id', agentId);
    request.write(jsonEncode(body));
    return await request.close();
  } finally {
    client.close();
  }
}

/// Completes with true once [future] completes, false if it has not within
/// [within].
Future<bool> _completes(
  Future<void>? future, {
  Duration within = const Duration(seconds: 2),
}) async {
  if (future == null) {
    return false;
  }
  return future.then((_) => true).timeout(within, onTimeout: () => false);
}

void main() {
  late HttpServer server;
  late _ControlledDispatcher dispatcher;

  setUp(() async {
    dispatcher = _ControlledDispatcher();
    final handler = McpRequestHandler(
      config: const McpConfig(enabled: true),
      dispatcher: dispatcher,
      streamAfter: _streamAfter,
      streamHeartbeat: _heartbeat,
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(handler.handle);
  });

  tearDown(() => server.close(force: true));

  test('a quick call answers with plain JSON', () async {
    dispatcher.finish();
    final response = await _post(server.port, _toolsCall());
    expect(response.headers.contentType?.mimeType, 'application/json');
    final body = jsonDecode(await response.transform(utf8.decoder).join());
    expect((body as Map)['id'], 7);
  });

  test(
    'a slow call streams progress, then the result, past the switch',
    () async {
      final responseFuture = _post(server.port, _toolsCall(progressToken: 3));
      await Future<void>.delayed(_streamAfter + _heartbeat * 3);
      dispatcher.finish();
      final response = await responseFuture;

      expect(response.headers.contentType?.mimeType, 'text/event-stream');
      final events = (await response.transform(utf8.decoder).join())
          .split('\n\n')
          .where((e) => e.startsWith('event: message'))
          .map(
            (e) =>
                jsonDecode(e.split('\n').last.substring('data: '.length))
                    as Map<String, dynamic>,
          )
          .toList();
      expect(events.first['method'], 'notifications/progress');
      expect((events.first['params'] as Map)['progressToken'], 3);
      expect(events.last['id'], 7);
      expect(events.last['result'], isNotNull);
      expect(await _completes(dispatcher.abandonments.single), isFalse);
    },
  );

  test('a client that does not accept a stream gets JSON however long the '
      'call runs', () async {
    final responseFuture = _post(
      server.port,
      _toolsCall(),
      acceptsStream: false,
    );
    await Future<void>.delayed(_streamAfter * 3);
    dispatcher.finish();
    final response = await responseFuture;
    expect(response.headers.contentType?.mimeType, 'application/json');
  });

  test(
    'hanging up on a streamed call tells the tool nobody is waiting',
    () async {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      );
      final body = jsonEncode(_toolsCall());
      socket.write(
        'POST /mcp HTTP/1.1\r\n'
        'Host: 127.0.0.1\r\n'
        'Content-Type: application/json\r\n'
        'Accept: application/json, text/event-stream\r\n'
        'Content-Length: ${utf8.encode(body).length}\r\n'
        '\r\n'
        '$body',
      );
      await socket.flush();
      final headersSeen = Completer<void>();
      socket.listen((bytes) {
        if (!headersSeen.isCompleted &&
            utf8.decode(bytes, allowMalformed: true).contains('event-stream')) {
          headersSeen.complete();
        }
      }, onError: (_) {});
      await headersSeen.future.timeout(const Duration(seconds: 2));

      expect(
        await _completes(
          dispatcher.abandonments.single,
          within: const Duration(milliseconds: 100),
        ),
        isFalse,
      );
      socket.destroy();
      expect(await _completes(dispatcher.abandonments.single), isTrue);
      dispatcher.finish();
    },
  );

  test('notifications/cancelled reaches the call it names, from the same '
      'caller only', () async {
    unawaited(_post(server.port, _toolsCall(), acceptsStream: false));
    await Future<void>.delayed(_streamAfter);
    final abandoned = dispatcher.abandonments.single;

    Map<String, dynamic> cancel() => {
      'jsonrpc': '2.0',
      'method': 'notifications/cancelled',
      'params': {'requestId': 7, 'reason': 'timeout'},
    };
    final other = await _post(server.port, cancel(), agentId: 'agent-2');
    expect(other.statusCode, HttpStatus.accepted);
    expect(
      await _completes(abandoned, within: const Duration(milliseconds: 100)),
      isFalse,
    );

    final own = await _post(server.port, cancel());
    expect(own.statusCode, HttpStatus.accepted);
    expect(await _completes(abandoned), isTrue);
    dispatcher.finish();
  });
}
