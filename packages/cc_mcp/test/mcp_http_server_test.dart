import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_http_server.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// Minimal dispatcher that returns predictable results without a real registry.
class _FakeDispatcher extends McpToolDispatcher {
  _FakeDispatcher({this.onHandleRequest}) : super(registry: _FakeRegistry());

  final FutureOr<Map<String, dynamic>> Function(JsonRpcRequest)?
  onHandleRequest;

  // The HTTP server routes through the scoped entrypoint, so the fake
  // intercepts here; the base handleRequest delegates to this too.
  @override
  Future<Map<String, dynamic>> handleScopedRequest(
    JsonRpcRequest request, {
    McpCallScope? scope,
  }) async {
    if (onHandleRequest != null) {
      return onHandleRequest!(request);
    }
    // Default: echo the method name and params
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {'method': request.method, 'echo': request.params},
    };
  }
}

/// Minimal fake registry so the dispatcher doesn't null-deref.
class _FakeRegistry extends McpToolRegistry {
  _FakeRegistry() : super([]);
}

/// Builds an McpConfig for testing.
McpConfig _testConfig({String? token}) {
  return McpConfig(token: token, enabled: true);
}

/// HTTP helper — sends a POST to `http://127.0.0.1:<port>/mcp` and returns the
/// raw [HttpClientResponse].
Future<HttpClientResponse> _post({
  required int port,
  required Map<String, dynamic> body,
  String? token,
}) async {
  final client = HttpClient();
  try {
    final request = await client.post('127.0.0.1', port, '/mcp');
    request.headers.contentType = ContentType(
      'application',
      'json',
      charset: 'utf-8',
    );
    if (token != null) {
      request.headers.set('Authorization', 'Bearer $token');
    }
    request.write(jsonEncode(body));
    return await request.close();
  } finally {
    client.close();
  }
}

/// HTTP helper — sends OPTIONS to `http://127.0.0.1:<port>/mcp`.
Future<HttpClientResponse> _options(int port) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(
      'OPTIONS',
      Uri.parse('http://127.0.0.1:$port/mcp'),
    );
    return await request.close();
  } finally {
    client.close();
  }
}

/// HTTP helper — sends GET to `http://127.0.0.1:<port>/<path>`.
Future<HttpClientResponse> _get(int port, String path) async {
  final client = HttpClient();
  try {
    final request = await client.get('127.0.0.1', port, path);
    return await request.close();
  } finally {
    client.close();
  }
}

/// Reads a response body as decoded JSON.
Future<Map<String, dynamic>> _readJson(HttpClientResponse response) async {
  final body = await response.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

void main() {
  // ---------------------------------------------------------------------------
  // Lifecycle & state tests (no real server needed for most)
  // ---------------------------------------------------------------------------
  group('lifecycle', () {
    test('isRunning starts false', () {
      final server = McpHttpServer(port: 8421, dispatcher: _FakeDispatcher());
      expect(server.isRunning, isFalse);
    });

    test('updateConfig changes active config', () {
      final server = McpHttpServer(port: 8423, dispatcher: _FakeDispatcher());
      server.handler.updateConfig(_testConfig());
      // Updating config doesn't restart; we verify no crash.
      expect(server.isRunning, isFalse);
    });

    test('start → stop → isRunning toggles', () async {
      final server = McpHttpServer(port: 8425, dispatcher: _FakeDispatcher());
      await server.start();
      expect(server.isRunning, isTrue);
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('stop when not running is a no-op', () async {
      final server = McpHttpServer(port: 8426, dispatcher: _FakeDispatcher());
      await server.stop(); // Should not throw
      expect(server.isRunning, isFalse);
    });

    test('onRunningChanged fires on start and stop', () async {
      final events = <bool>[];
      final server = McpHttpServer(
        port: 8427,
        dispatcher: _FakeDispatcher(),
        onRunningChanged: ({required bool running}) => events.add(running),
      );
      await server.start();
      await server.stop();
      expect(events, [true, false]);
    });

    test('double start is idempotent', () async {
      final server = McpHttpServer(port: 8428, dispatcher: _FakeDispatcher());
      await server.start();
      expect(server.isRunning, isTrue);
      await server.start(); // Should not throw
      expect(server.isRunning, isTrue);
      await server.stop();
    });
  });

  // ---------------------------------------------------------------------------
  // HTTP integration tests (real server on real port)
  // ---------------------------------------------------------------------------
  group('HTTP integration', () {
    // Each test gets a unique port via an incrementing counter to avoid
    // TIME_WAIT collisions on macOS.
    int nextPort = 8490;

    late McpHttpServer server;
    late int port;

    Future<void> startServer({
      String? token,
      _FakeDispatcher? dispatcher,
    }) async {
      port = nextPort++;
      server = McpHttpServer(
        port: port,
        config: _testConfig(token: token),
        dispatcher: dispatcher ?? _FakeDispatcher(),
      );
      await server.start();
    }

    tearDown(() async {
      await server.stop();
    });

    // ---- Route registration ----
    group('route registration', () {
      test('OPTIONS returns 204 with CORS headers', () async {
        await startServer();
        final resp = await _options(port);
        expect(resp.statusCode, 204);
        expect(resp.headers.value('access-control-allow-origin'), isNotNull);
        expect(resp.headers.value('access-control-allow-methods'), isNotNull);
      });

      test('GET /unknown returns 404 JSON', () async {
        await startServer();
        final resp = await _get(port, '/unknown');
        expect(resp.statusCode, 404);
        final body = await _readJson(resp);
        expect(body['error'], 'Not Found');
      });

      test('POST /mcp with valid JSON-RPC returns 200', () async {
        await startServer();
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
        );
        expect(resp.statusCode, 200);
        final body = await _readJson(resp);
        expect(body['result'], isA<Map>());
        expect(body['id'], 1);
      });

      test('POST /mcp dispatches initialize correctly', () async {
        final dispatcher = _FakeDispatcher(
          onHandleRequest: (req) async => {
            'jsonrpc': '2.0',
            'id': req.id,
            'result': {
              'protocolVersion': '2024-11-05',
              'serverInfo': {'name': 'test'},
            },
          },
        );
        await startServer(dispatcher: dispatcher);
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'initialize', 'id': 42},
        );
        expect(resp.statusCode, 200);
        final body = await _readJson(resp);
        expect(
          (body['result'] as Map<String, dynamic>)['protocolVersion'],
          '2024-11-05',
        );
        expect(body['id'], 42);
      });

      test('POST /mcp dispatches tools/call with tool name', () async {
        final dispatcher = _FakeDispatcher(
          onHandleRequest: (req) async => {
            'jsonrpc': '2.0',
            'id': req.id,
            'result': {
              'content': [
                {'type': 'text', 'text': 'ok'},
              ],
            },
          },
        );
        await startServer(dispatcher: dispatcher);
        final resp = await _post(
          port: port,
          body: {
            'jsonrpc': '2.0',
            'method': 'tools/call',
            'params': {
              'name': 'echo',
              'arguments': {'msg': 'hi'},
            },
            'id': 7,
          },
        );
        expect(resp.statusCode, 200);
        final body = await _readJson(resp);
        expect(
          (((body['result'] as Map<String, dynamic>)['content'] as List)[0]
              as Map<String, dynamic>)['text'],
          'ok',
        );
      });

      test('POST /mcp with empty result returns 202', () async {
        final dispatcher = _FakeDispatcher(
          onHandleRequest: (req) async => <String, dynamic>{},
        );
        await startServer(dispatcher: dispatcher);
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'notifications/initialized'},
        );
        expect(resp.statusCode, 202);
      });
    });

    // ---- Request parsing ----
    group('request parsing', () {
      test('empty body returns 400 with error', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          // Send empty body
          final resp = await request.close();
          expect(resp.statusCode, 400);
          final body = await _readJson(resp);
          expect(body['error'], 'Empty body');
        } finally {
          client.close();
        }
      });

      test('an over-cap body is refused, not buffered', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          final payload = '{"padding":"${'x' * (5 * 1024 * 1024)}"}';
          // Declaring the length lets the server refuse before reading a byte.
          request.contentLength = payload.length;
          request.write(payload);
          int? status;
          try {
            final resp = await request.close();
            status = resp.statusCode;
            await resp.drain<void>();
          } on HttpException {
            // Also acceptable: the server answered and closed while we were
            // still writing, so the client never saw the headers. What must
            // NOT happen is the body being accepted and buffered.
          }
          expect(status, anyOf(isNull, 413));

          // The listener survives the refusal and still serves normal traffic.
          final ok = await _post(
            port: port,
            body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
          );
          expect(ok.statusCode, 200);
          await ok.drain<void>();
        } finally {
          client.close(force: true);
        }
      });

      test('malformed JSON returns 400 with parse error', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          request.write('{not valid json{{{');
          final resp = await request.close();
          expect(resp.statusCode, 400);
          final body = await _readJson(resp);
          expect(body['jsonrpc'], '2.0');
          expect((body['error'] as Map<String, dynamic>)['code'], -32700);
          expect(
            (body['error'] as Map<String, dynamic>)['message'],
            'Parse error',
          );
        } finally {
          client.close();
        }
      });

      test('valid JSON but non-object returns 500', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          request.write('[1, 2, 3]'); // Valid JSON array, not object
          final resp = await request.close();
          expect(resp.statusCode, 500);
          final body = await _readJson(resp);
          expect(body['jsonrpc'], '2.0');
          expect((body['error'] as Map<String, dynamic>)['code'], -32603);
        } finally {
          client.close();
        }
      });

      // A frame with no `method` is bad DATA off the wire, not a bug in our
      // own code, so `JsonRpcRequest.fromJson` raises a FormatException (not
      // the constructor's ArgumentError) and the transport answers -32700 /
      // 400 rather than a 500 with a diagnostic id.
      test('missing method field → 400 parse error', () async {
        await startServer();
        final resp = await _post(port: port, body: {'jsonrpc': '2.0', 'id': 1});
        expect(resp.statusCode, 400);
        final body = await _readJson(resp);
        expect(body['jsonrpc'], '2.0');
        expect((body['error'] as Map<String, dynamic>)['code'], -32700);
        expect(
          (body['error'] as Map<String, dynamic>)['message'],
          contains('Parse error'),
        );
      });

      test('missing id is null (notification-style)', () async {
        await startServer();
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping'},
        );
        expect(resp.statusCode, 200);
        final body = await _readJson(resp);
        expect(body['id'], isNull);
      });
    });

    // ---- Response formatting ----
    group('response formatting', () {
      test('successful response has application/json content type', () async {
        await startServer();
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
        );
        expect(resp.statusCode, 200);
        expect(resp.headers.contentType!.mimeType, 'application/json');
      });

      test('error response has application/json content type', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          request.write('invalid');
          final resp = await request.close();
          expect(resp.headers.contentType!.mimeType, 'application/json');
        } finally {
          client.close();
        }
      });
    });

    // ---- Error response generation ----
    group('error response generation', () {
      test('dispatcher throws → 500 internal error, scrubbed', () async {
        final dispatcher = _FakeDispatcher(
          onHandleRequest: (req) async =>
              throw Exception('boom /Users/secret/path.db'),
        );
        await startServer(dispatcher: dispatcher);
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'failing', 'id': 1},
        );
        expect(resp.statusCode, 500);
        final body = await _readJson(resp);
        expect(body['jsonrpc'], '2.0');
        final message =
            (body['error'] as Map<String, dynamic>)['message'] as String;
        expect(message, contains('Internal error'));
        // The exception text used to be serialized verbatim, carrying paths,
        // SQL and auth detail to an HTTP client. Only a log-correlation id
        // may cross the boundary now.
        expect(message, isNot(contains('boom')));
        expect(message, isNot(contains('/Users/secret')));
        expect(message, contains('ref:'));
      });
    });

    // ---- Auth ----
    group('auth', () {
      test(
        'no token configured → request passes without auth header',
        () async {
          await startServer(token: null);
          final resp = await _post(
            port: port,
            body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
          );
          expect(resp.statusCode, 200);
        },
      );

      test(
        'GET /sse without a token returns 401 when one is configured',
        () async {
          // Regression: the SSE GET skipped auth entirely ("EventSource can't
          // send headers"), leaving an unauthenticated long-lived endpoint on a
          // surface whose whole non-loopback posture is "has a token".
          await startServer(token: 'secret');
          final resp = await _get(port, '/sse');
          expect(resp.statusCode, 401);
          await resp.drain<void>();
        },
      );

      test('GET /sse accepts the token as a query parameter', () async {
        await startServer(token: 'secret');
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('http://127.0.0.1:$port/sse?token=secret'),
          );
          final resp = await request.close();
          expect(resp.statusCode, 200);
          expect(resp.headers.contentType?.mimeType, 'text/event-stream');
          // The stream stays open by design; take the endpoint event and go.
          final first = await resp
              .transform(utf8.decoder)
              .take(1)
              .join()
              .timeout(const Duration(seconds: 5));
          expect(first, contains('endpoint'));
        } finally {
          client.close(force: true);
        }
      });

      test('GET /sse with a wrong query token returns 401', () async {
        await startServer(token: 'secret');
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            Uri.parse('http://127.0.0.1:$port/sse?token=nope'),
          );
          final resp = await request.close();
          expect(resp.statusCode, 401);
          await resp.drain<void>();
        } finally {
          client.close();
        }
      });

      test('token configured → missing auth header returns 401', () async {
        await startServer(token: 'secret');
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          // No Authorization header
          request.write(
            jsonEncode({'jsonrpc': '2.0', 'method': 'ping', 'id': 1}),
          );
          final resp = await request.close();
          expect(resp.statusCode, 401);
          final body = await _readJson(resp);
          expect(body['error'], 'Unauthorized');
        } finally {
          client.close();
        }
      });

      test('token configured → wrong bearer token returns 401', () async {
        await startServer(token: 'secret');
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          request.headers.set('Authorization', 'Bearer wrong');
          request.write(
            jsonEncode({'jsonrpc': '2.0', 'method': 'ping', 'id': 1}),
          );
          final resp = await request.close();
          expect(resp.statusCode, 401);
        } finally {
          client.close();
        }
      });

      test('token configured → correct bearer token passes', () async {
        await startServer(token: 'secret');
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
          token: 'secret',
        );
        expect(resp.statusCode, 200);
        final body = await _readJson(resp);
        expect(body['result'], isA<Map>());
      });

      test('token configured → CORS preflight OPTIONS bypasses auth', () async {
        await startServer(token: 'secret');
        // OPTIONS should skip auth check
        final resp = await _options(port);
        expect(resp.statusCode, 204);
      });
    });

    // ---- CORS ----
    group('CORS', () {
      test('CORS headers echo request Origin', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.post('127.0.0.1', port, '/mcp');
          request.headers.set('Origin', 'https://example.com');
          request.headers.contentType = ContentType(
            'application',
            'json',
            charset: 'utf-8',
          );
          request.write(
            jsonEncode({'jsonrpc': '2.0', 'method': 'ping', 'id': 1}),
          );
          final resp = await request.close();
          expect(
            resp.headers.value('access-control-allow-origin'),
            'https://example.com',
          );
        } finally {
          client.close();
        }
      });

      test('CORS headers fall back to * when no Origin', () async {
        await startServer();
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
        );
        expect(resp.headers.value('access-control-allow-origin'), '*');
      });

      test('CORS echoes Access-Control-Request-Headers', () async {
        await startServer();
        final client = HttpClient();
        try {
          final request = await client.openUrl(
            'OPTIONS',
            Uri.parse('http://127.0.0.1:$port/mcp'),
          );
          request.headers.set('Access-Control-Request-Headers', 'X-Custom');
          final resp = await request.close();
          expect(
            resp.headers.value('access-control-allow-headers'),
            'X-Custom',
          );
        } finally {
          client.close();
        }
      });

      test('CORS exposes Mcp-Session-Id', () async {
        await startServer();
        final resp = await _post(
          port: port,
          body: {'jsonrpc': '2.0', 'method': 'ping', 'id': 1},
        );
        expect(
          resp.headers.value('access-control-expose-headers'),
          'Mcp-Session-Id',
        );
      });
    });
  });

  group('dispatch identity scope (X-CC-* headers)', () {
    int nextPort = 8590;

    test(
      'headers force workspace_id and fill identity args end-to-end',
      () async {
        final probe = _ScopeProbeTool();
        final port = nextPort++;
        final server = McpHttpServer(
          port: port,
          dispatcher: McpToolDispatcher(registry: McpToolRegistry([probe])),
        );
        await server.start();
        try {
          final client = HttpClient();
          try {
            final request = await client.post('127.0.0.1', port, '/mcp');
            request.headers
              ..contentType = ContentType(
                'application',
                'json',
                charset: 'utf-8',
              )
              ..set('X-CC-Workspace-Id', 'ws-own')
              ..set('X-CC-Agent-Id', 'agent-1')
              ..set('X-CC-Conversation-Id', 'conv-1');
            request.write(
              jsonEncode({
                'jsonrpc': '2.0',
                'method': 'tools/call',
                'params': {
                  'name': 'scope_probe',
                  'arguments': {'workspace_id': 'ws-foreign'},
                },
                'id': 7,
              }),
            );
            final resp = await request.close();
            expect(resp.statusCode, 200);
            await resp.drain<void>();
          } finally {
            client.close();
          }
          expect(probe.lastArgs!['workspace_id'], 'ws-own');
          expect(probe.lastArgs!['agent_id'], 'agent-1');
          expect(probe.lastArgs!['conversation_id'], 'conv-1');
        } finally {
          await server.stop();
        }
      },
    );

    test('without headers, arguments pass through verbatim', () async {
      final probe = _ScopeProbeTool();
      final port = nextPort++;
      final server = McpHttpServer(
        port: port,
        dispatcher: McpToolDispatcher(registry: McpToolRegistry([probe])),
      );
      await server.start();
      try {
        final resp = await _post(
          port: port,
          body: {
            'jsonrpc': '2.0',
            'method': 'tools/call',
            'params': {
              'name': 'scope_probe',
              'arguments': {'workspace_id': 'ws-any'},
            },
            'id': 8,
          },
        );
        expect(resp.statusCode, 200);
        await resp.drain<void>();
        expect(probe.lastArgs!['workspace_id'], 'ws-any');
        expect(probe.lastArgs!.containsKey('agent_id'), isFalse);
      } finally {
        await server.stop();
      }
    });
  });

  group('tools/list_changed notification', () {
    test('notifyToolsListChanged reaches connected SSE clients', () async {
      const port = 8610;
      final server = McpHttpServer(port: port, dispatcher: _FakeDispatcher());
      await server.start();
      final client = HttpClient();
      try {
        final request = await client.get('127.0.0.1', port, '/sse');
        final resp = await request.close();
        expect(resp.statusCode, 200);

        final lines = resp
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .asBroadcastStream();
        // Handshake: the endpoint event arrives first.
        await lines
            .firstWhere((l) => l.contains('/mcp'))
            .timeout(const Duration(seconds: 5));

        final notification = lines
            .firstWhere((l) => l.contains('notifications/tools/list_changed'))
            .timeout(const Duration(seconds: 5));
        // Give the SSE handler a beat to register the connection server-side
        // before broadcasting.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        server.handler.notifyToolsListChanged();

        expect(await notification, contains('tools/list_changed'));
      } finally {
        client.close(force: true);
        await server.stop();
      }
    });
  });
}

/// Records the arguments it was called with; declares the scoped ids in its
/// schema so the dispatcher's scope injection targets them.
class _ScopeProbeTool extends McpTool {
  Map<String, dynamic>? lastArgs;

  @override
  String get name => 'scope_probe';

  @override
  String get description => 'Records scoped arguments';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'agent_id': {'type': 'string'},
      'conversation_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    lastArgs = arguments;
    return CallResult.success('ok');
  }
}
