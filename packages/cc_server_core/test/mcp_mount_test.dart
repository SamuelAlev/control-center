import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_persistence/cc_persistence.dart' show PairedDevicesTableData;
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Proof of the single-port MCP topology: the MCP Streamable HTTP transport
/// (`POST /mcp`, `GET /sse`, OPTIONS preflight) rides the main cc_server
/// listener when a handler is mounted, 404s when none is, and a tokenless
/// surface never answers off-host clients (fail closed).
void main() {
  group('MCP mount on the main listener', () {
    late LocalRpcServer server;
    late int serverPort;
    late McpRequestHandler handler;

    setUp(() async {
      server = LocalRpcServer(
        dispatcher: _StubDispatcher(),
        devicesDao: _StubDevicesDao(),
        secrets: _StubSecrets(),
        eventBus: DomainEventBus(),
        workspaceResolver: (_) async => const [],
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      await server.start();
      serverPort = server.boundPort;
      handler = McpRequestHandler(
        config: const McpConfig(enabled: true),
        dispatcher: McpToolDispatcher(
          registry: McpToolRegistry([_StubTool('alpha')]),
        ),
      );
    });

    tearDown(() async {
      await server.stop();
    });

    Future<HttpClientResponse> post(Map<String, dynamic> body) async {
      final client = HttpClient();
      try {
        final request = await client.post('127.0.0.1', serverPort, '/mcp');
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
        return await request.close();
      } finally {
        client.close();
      }
    }

    test('POST /mcp is served by the mounted handler', () async {
      server.mcpHandler = handler;
      final resp = await post({
        'jsonrpc': '2.0',
        'method': 'tools/call',
        'params': {
          'name': 'alpha',
          'arguments': {'workspace_id': 'ws-1'},
        },
        'id': 1,
      });
      expect(resp.statusCode, 200);
      final json =
          jsonDecode(await resp.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      expect(json['id'], 1);
      expect(json['result'], isNotNull);
    });

    test('OPTIONS /mcp preflight is served by the mounted handler', () async {
      server.mcpHandler = handler;
      final client = HttpClient();
      try {
        final request = await client.openUrl(
          'OPTIONS',
          Uri.parse('http://127.0.0.1:$serverPort/mcp'),
        );
        final resp = await request.close();
        expect(resp.statusCode, 204);
        expect(resp.headers.value('access-control-allow-origin'), isNotNull);
        await resp.drain<void>();
      } finally {
        client.close();
      }
    });

    test('/mcp 404s once the handler is unmounted', () async {
      server.mcpHandler = handler;
      server.mcpHandler = null;
      final resp = await post({'jsonrpc': '2.0', 'method': 'ping', 'id': 1});
      await resp.drain<void>();
      expect(resp.statusCode, 404);
    });

    test('/mcp 404s when no handler was ever mounted', () async {
      final resp = await post({'jsonrpc': '2.0', 'method': 'ping', 'id': 1});
      await resp.drain<void>();
      expect(resp.statusCode, 404);
    });
  });

  group('mcpRemoteClientAllowed', () {
    final loopback = InternetAddress.loopbackIPv4;
    final lan = InternetAddress('192.168.1.20');

    test('loopback is always allowed', () {
      expect(mcpRemoteClientAllowed(remote: loopback, hasToken: false), isTrue);
      expect(mcpRemoteClientAllowed(remote: loopback, hasToken: true), isTrue);
    });

    test('off-host requires a bearer token (fail closed)', () {
      expect(mcpRemoteClientAllowed(remote: lan, hasToken: false), isFalse);
      expect(mcpRemoteClientAllowed(remote: lan, hasToken: true), isTrue);
    });

    test('unknown remote is treated as off-host', () {
      expect(mcpRemoteClientAllowed(remote: null, hasToken: false), isFalse);
      expect(mcpRemoteClientAllowed(remote: null, hasToken: true), isTrue);
    });
  });
}

/// Minimal no-op RPC dispatcher (the MCP routes never reach it).
class _StubDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async =>
      const {};
}

class _StubDevicesDao implements PairedDeviceDao {
  @override
  Stream<List<PairedDevicesTableData>> watchAll() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubSecrets implements PairedDeviceSecretsPort {
  @override
  Future<String?> readPsk(String deviceId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubTool extends McpTool {
  _StubTool(this.name);

  @override
  final String name;

  @override
  String get description => 'stub $name';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}
