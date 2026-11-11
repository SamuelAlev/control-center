import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_http_server.dart';
import 'package:cc_mcp/src/mcp_request_handler.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/list_workspaces_tool.dart';
import 'package:test/test.dart';

/// The MCP HTTP surface answers only an agent run (its secret, from loopback)
/// or the server owner (the token), and a run acts only in its own workspace.
/// Requests a web page in a browser on this machine could make are refused
/// before any credential is looked at.
void main() {
  const token = 'owner-token';
  late McpHttpServer server;
  late int port;
  late _Probe probe;
  late _GlobalTool global;

  setUp(() async {
    probe = _Probe();
    global = _GlobalTool();
    final dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        probe,
        global,
        ListWorkspacesTool(repository: _Workspaces(['ws-a', 'ws-b'])),
      ]),
    );
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = socket.port;
    await socket.close();
    server = McpHttpServer(
      port: port,
      handler: McpRequestHandler(
        token: token,
        dispatcher: dispatcher,
        attestRun: (secret) => secret == 'run-a'
            ? const McpCallScope(
                workspaceId: 'ws-a',
                agentId: 'agent-a',
                attested: true,
              )
            : null,
        publicHosts: () => ['cc.example.com'],
      ),
    );
    await server.start();
  });

  tearDown(() => server.stop());

  Future<(int, Map<String, dynamic>?)> send({
    String method = 'POST',
    Map<String, String> headers = const {},
    Object? body,
    ContentType? contentType,
    String? host,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:$port/mcp'),
      );
      if (host != null) {
        request.headers.host = host;
      }
      request.headers.contentType = contentType ?? ContentType.json;
      headers.forEach(request.headers.set);
      if (body != null) {
        request.write(body is String ? body : jsonEncode(body));
      }
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      final decoded = text.isEmpty ? null : jsonDecode(text);
      return (
        response.statusCode,
        decoded is Map<String, dynamic> ? decoded : null,
      );
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> toolsCall(String name, Map<String, dynamic> args) => {
    'jsonrpc': '2.0',
    'id': 1,
    'method': 'tools/call',
    'params': {'name': name, 'arguments': args},
  };

  group('credentials', () {
    test('a request without one is refused, from loopback too', () async {
      final (status, _) = await send(body: toolsCall('probe', {}));
      expect(status, HttpStatus.unauthorized);
      expect(probe.calls, isEmpty);
    });

    test('caller-written scope headers are no credential', () async {
      final (status, _) = await send(
        headers: {'X-CC-Workspace-Id': 'ws-a', 'X-CC-Agent-Id': 'agent-a'},
        body: toolsCall('probe', {'workspace_id': 'ws-a'}),
      );
      expect(status, HttpStatus.unauthorized);
      expect(probe.calls, isEmpty);
    });

    test('a secret that names no run is refused even with the token', () async {
      final (status, _) = await send(
        headers: {
          McpCallScope.runGrantHeader: 'guessed',
          'Authorization': 'Bearer $token',
        },
        body: toolsCall('probe', {}),
      );
      expect(status, HttpStatus.unauthorized);
    });

    test('the token carries no scope: arguments pass through', () async {
      final (status, _) = await send(
        headers: {'Authorization': 'Bearer $token'},
        body: toolsCall('probe', {'workspace_id': 'ws-b'}),
      );
      expect(status, HttpStatus.ok);
      expect(probe.calls.single['workspace_id'], 'ws-b');
    });
  });

  group('an agent run', () {
    test('naming another workspace runs in its own', () async {
      final (status, reply) = await send(
        headers: {McpCallScope.runGrantHeader: 'run-a'},
        body: toolsCall('probe', {'workspace_id': 'ws-b'}),
      );
      expect(status, HttpStatus.ok);
      expect((reply!['result'] as Map)['isError'], isNot(isTrue));
      expect(probe.calls.single['workspace_id'], 'ws-a');
    });

    test('lists only its own workspace', () async {
      final (_, reply) = await send(
        headers: {McpCallScope.runGrantHeader: 'run-a'},
        body: toolsCall('list_workspaces', {}),
      );
      final text =
          (((reply!['result'] as Map)['content'] as List).single as Map)['text']
              as String;
      final listed = (jsonDecode(text) as Map)['workspaces'] as List;
      expect([for (final w in listed) (w as Map)['id']], ['ws-a']);
    });

    test('the owner still lists every workspace', () async {
      final (_, reply) = await send(
        headers: {'Authorization': 'Bearer $token'},
        body: toolsCall('list_workspaces', {}),
      );
      final text =
          (((reply!['result'] as Map)['content'] as List).single as Map)['text']
              as String;
      expect((jsonDecode(text) as Map)['count'], 2);
    });

    test('cannot call a tool that names no workspace', () async {
      final (status, reply) = await send(
        headers: {McpCallScope.runGrantHeader: 'run-a'},
        body: toolsCall('global_tool', {}),
      );
      expect(status, HttpStatus.ok);
      expect((reply!['result'] as Map)['isError'], isTrue);
      expect(global.calls, 0);
    });
  });

  group('browser hardening', () {
    test('a foreign Origin is refused and gets no CORS headers', () async {
      final client = HttpClient();
      try {
        final request = await client.openUrl(
          'OPTIONS',
          Uri.parse('http://127.0.0.1:$port/mcp'),
        );
        request.headers
          ..set('Origin', 'https://evil.example')
          ..set('Access-Control-Request-Method', 'POST');
        final response = await request.close();
        expect(response.statusCode, HttpStatus.forbidden);
        expect(response.headers.value('access-control-allow-origin'), isNull);
        await response.drain<void>();
      } finally {
        client.close();
      }

      final (status, _) = await send(
        headers: {
          'Origin': 'https://evil.example',
          'Authorization': 'Bearer $token',
        },
        body: toolsCall('probe', {}),
      );
      expect(status, HttpStatus.forbidden);
      expect(probe.calls, isEmpty);
    });

    test('an opaque Origin is refused', () async {
      final (status, _) = await send(
        headers: {'Origin': 'null', 'Authorization': 'Bearer $token'},
        body: toolsCall('probe', {}),
      );
      expect(status, HttpStatus.forbidden);
    });

    test('a rebound Host is refused, the public host is not', () async {
      final (rebound, _) = await send(
        host: 'evil.example',
        headers: {'Authorization': 'Bearer $token'},
        body: toolsCall('probe', {}),
      );
      expect(rebound, HttpStatus.forbidden);

      final (otherPort, _) = await send(
        host: '127.0.0.1:${port + 1}',
        headers: {'Authorization': 'Bearer $token'},
        body: toolsCall('probe', {}),
      );
      expect(otherPort, HttpStatus.forbidden);
      expect(probe.calls, isEmpty);

      final (public, _) = await send(
        host: 'cc.example.com',
        headers: {'Authorization': 'Bearer $token'},
        body: toolsCall('probe', {}),
      );
      expect(public, HttpStatus.ok);
    });

    test('a POST that is not JSON is refused', () async {
      final (status, _) = await send(
        contentType: ContentType.text,
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode(toolsCall('probe', {})),
      );
      expect(status, HttpStatus.unsupportedMediaType);
      expect(probe.calls, isEmpty);
    });
  });
}

/// Records what it was called with; takes a workspace.
class _Probe extends McpTool {
  final List<Map<String, dynamic>> calls = [];

  @override
  String get name => 'probe';

  @override
  String get description => 'Records its arguments.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    calls.add(arguments);
    return CallResult.success('ok');
  }
}

/// A tool that names no workspace, like the newsfeed tools.
class _GlobalTool extends McpTool {
  int calls = 0;

  @override
  String get name => 'global_tool';

  @override
  String get description => 'Reads something every workspace shares.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {},
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    calls++;
    return CallResult.success('ok');
  }
}

class _Workspaces implements WorkspaceRepository {
  _Workspaces(this.ids);

  final List<String> ids;

  @override
  Stream<List<Workspace>> watchAll() => Stream.value([
    for (final id in ids)
      Workspace(
        id: id,
        name: id,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
