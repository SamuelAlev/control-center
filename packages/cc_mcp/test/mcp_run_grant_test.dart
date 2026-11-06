import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_http_server.dart';
import 'package:cc_mcp/src/mcp_request_handler.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// A tool that reaches the host and reports the space it was told to act on.
class _HostTool extends McpTool {
  final List<Map<String, dynamic>> calls = [];

  @override
  String get name => 'host_tool';

  @override
  String get description => 'Reaches the host.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'space_id': {'type': 'string'},
    },
  };

  @override
  Set<String> get forcedScopeKeys => const {'space_id'};

  @override
  Set<String> get requiredScopeKeys => const {'workspace_id', 'space_id'};

  @override
  bool get requiresRunGrant => true;

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    calls.add(arguments);
    return CallResult.success('ok');
  }
}

void main() {
  late _HostTool tool;
  late McpHttpServer server;
  late int port;

  setUp(() async {
    tool = _HostTool();
    final dispatcher = McpToolDispatcher(registry: McpToolRegistry([tool]));
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = probe.port;
    await probe.close();
    server = McpHttpServer(
      port: port,
      dispatcher: dispatcher,
      handler: McpRequestHandler(
        config: const McpConfig(enabled: true),
        dispatcher: dispatcher,
        attestRun: (secret) => secret == 'run-a'
            ? const McpCallScope(
                workspaceId: 'ws-a',
                spaceId: 'space-a',
                attested: true,
              )
            : null,
      ),
    );
    await server.start();
  });

  tearDown(() => server.stop());

  Future<Map<String, dynamic>> call(
    Map<String, String> headers, {
    Map<String, dynamic> arguments = const {},
  }) async {
    final client = HttpClient();
    try {
      final request = await client.post('127.0.0.1', port, '/mcp');
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      request.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'tools/call',
          'params': {'name': 'host_tool', 'arguments': arguments},
        }),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['result'] as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  test('identity headers alone do not reach a host tool', () async {
    final result = await call({
      'X-CC-Workspace-Id': 'ws-b',
      'X-CC-Space-Id': 'space-b',
    });

    expect(result['isError'], isTrue);
    expect(tool.calls, isEmpty);
  });

  test('no headers at all do not let the arguments choose', () async {
    final result = await call(
      const {},
      arguments: {'workspace_id': 'ws-b', 'space_id': 'space-b'},
    );

    expect(result['isError'], isTrue);
    expect(tool.calls, isEmpty);
  });

  test('a secret that names no run proves nothing', () async {
    final result = await call({
      McpCallScope.runGrantHeader: 'guessed',
      'X-CC-Workspace-Id': 'ws-a',
      'X-CC-Space-Id': 'space-a',
    });

    expect(result['isError'], isTrue);
    expect(tool.calls, isEmpty);
  });

  test('a run acts on its own space whatever else it claims', () async {
    final result = await call(
      {
        McpCallScope.runGrantHeader: 'run-a',
        'X-CC-Workspace-Id': 'ws-b',
        'X-CC-Space-Id': 'space-b',
      },
      arguments: {'workspace_id': 'ws-b', 'space_id': 'space-b'},
    );

    expect(result['isError'], isNot(isTrue));
    expect(tool.calls.single['workspace_id'], 'ws-a');
    expect(tool.calls.single['space_id'], 'space-a');
  });
}
