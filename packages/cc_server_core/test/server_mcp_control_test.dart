import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_server_core/src/server_mcp_control.dart';
import 'package:test/test.dart';

/// Fake main-listener mount: records handler mounts and reports a fixed port.
class _FakeMainServer implements McpHostServer {
  _FakeMainServer({required this.boundPort, this.tls = false});

  @override
  final int boundPort;

  final bool tls;

  bool running = true;
  McpRequestHandler? mounted;

  @override
  bool get isRunning => running;

  @override
  bool get tlsInProcess => tls;

  @override
  set mcpHandler(McpRequestHandler? handler) => mounted = handler;
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

void main() {
  late Directory tmp;
  late McpToolRegistry registry;
  late ServerMcpControl control;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('mcp_control_test');
    registry = McpToolRegistry([_StubTool('alpha'), _StubTool('beta')]);
    control = ServerMcpControl(
      dispatcher: McpToolDispatcher(registry: registry),
      dataDir: tmp.path,
    );
  });

  tearDown(() {
    tmp.deleteSync(recursive: true);
  });

  group('writeAgentMcpConfig', () {
    test('stamps identity scope + toolset revision headers', () async {
      final target = File('${tmp.path}/agent/.mcp.json');
      final path = await control.writeAgentMcpConfig(
        target,
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
      );
      expect(path, target.path);

      final json =
          jsonDecode(target.readAsStringSync()) as Map<String, dynamic>;
      final server = ((json['mcpServers'] as Map)['control-center'] as Map)
          .cast<String, dynamic>();
      expect(server['type'], 'http');
      expect(server['url'], startsWith('http://127.0.0.1:'));

      final headers = (server['headers'] as Map).cast<String, String>();
      expect(headers['X-CC-Workspace-Id'], 'ws-1');
      expect(headers['X-CC-Agent-Id'], 'agent-1');
      expect(headers['X-CC-Conversation-Id'], 'conv-1');
      expect(headers['X-CC-Toolset-Rev'], registry.toolsetRevision);
      // The standard `.mcp.json` stays free of client-specific keys so
      // `claude --strict-mcp-config` never chokes on it.
      expect(server.containsKey('lifecycle'), isFalse);
    });

    test(
      'toolset revision header changes when the catalogue changes',
      () async {
        final target = File('${tmp.path}/agent/.mcp.json');
        await control.writeAgentMcpConfig(target, workspaceId: 'ws-1');
        final before = _revOf(target);

        registry.register(_StubTool('gamma'));
        await control.writeAgentMcpConfig(target, workspaceId: 'ws-1');
        expect(_revOf(target), isNot(before));
      },
    );

    test('writes a pi-specific twin with an eager lifecycle', () async {
      final target = File('${tmp.path}/agent/.mcp.json');
      await control.writeAgentMcpConfig(
        target,
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        conversationId: 'conv-1',
      );

      // pi merges `<cwd>/.pi/mcp.json` last (it wins per-server), so this twin
      // makes pi connect at session start and re-list tools fresh instead of
      // trusting its 7-day disk cache.
      final piConfig = File('${tmp.path}/agent/.pi/mcp.json');
      expect(piConfig.existsSync(), isTrue);
      final json =
          jsonDecode(piConfig.readAsStringSync()) as Map<String, dynamic>;
      final server = ((json['mcpServers'] as Map)['control-center'] as Map)
          .cast<String, dynamic>();
      expect(server['lifecycle'], 'eager');
      final headers = (server['headers'] as Map).cast<String, String>();
      expect(headers['X-CC-Workspace-Id'], 'ws-1');
      expect(headers['X-CC-Toolset-Rev'], registry.toolsetRevision);
    });

    test('omits identity headers when no scope is supplied', () async {
      final target = File('${tmp.path}/agent/.mcp.json');
      await control.writeAgentMcpConfig(target);
      final json =
          jsonDecode(target.readAsStringSync()) as Map<String, dynamic>;
      final server = ((json['mcpServers'] as Map)['control-center'] as Map)
          .cast<String, dynamic>();
      final headers = (server['headers'] as Map).cast<String, String>();
      expect(headers.containsKey('X-CC-Workspace-Id'), isFalse);
      expect(headers.containsKey('X-CC-Agent-Id'), isFalse);
      expect(headers.containsKey('X-CC-Conversation-Id'), isFalse);
      expect(headers['X-CC-Toolset-Rev'], isNotEmpty);
    });
  });

  group('single-port mount', () {
    late _FakeMainServer main;

    setUp(() {
      main = _FakeMainServer(boundPort: 9030);
      control.attachMainServer(main);
    });

    tearDown(() async {
      await control.dispose();
    });

    test(
      'start mounts the handler on the main listener, no companion',
      () async {
        await control.start();
        expect(main.mounted, isNotNull);

        final status = await control.status();
        expect(status.running, isTrue);
        expect(status.port, 9030);
      },
    );

    test('stop unmounts the handler', () async {
      await control.start();
      await control.stop();
      expect(main.mounted, isNull);
      expect((await control.status()).running, isFalse);
    });

    test('status reports not-running when the main listener is down', () async {
      await control.start();
      main.running = false;
      expect((await control.status()).running, isFalse);
    });

    test('agent MCP config points at the main listener port', () async {
      await control.start();
      final target = File('${tmp.path}/agent/.mcp.json');
      await control.writeAgentMcpConfig(target, workspaceId: 'ws-1');
      final json =
          jsonDecode(target.readAsStringSync()) as Map<String, dynamic>;
      final server = ((json['mcpServers'] as Map)['control-center'] as Map)
          .cast<String, dynamic>();
      expect(server['url'], 'http://127.0.0.1:9030/mcp');
    });

    test('token change applies live, without a restart', () async {
      await control.start();
      final handler = main.mounted;
      await control.setToken('secret');
      expect(main.mounted, same(handler), reason: 'no remount on token change');
      expect(handler!.hasToken, isTrue);
      expect((await control.status()).hasToken, isTrue);
    });
  });

  group('auto-start', () {
    late _FakeMainServer main;

    setUp(() {
      main = _FakeMainServer(boundPort: 9030);
      control.attachMainServer(main);
    });

    tearDown(() async {
      await control.dispose();
    });

    test('boot mounts the surface when no preference is persisted', () async {
      await control.startIfEnabled();
      expect(main.mounted, isNotNull);
      final status = await control.status();
      expect(status.running, isTrue);
      expect(status.enabled, isTrue);
    });

    test('boot respects an explicit opt-out', () async {
      File('${tmp.path}/mcp_config.json').writeAsStringSync(
        jsonEncode({'enabled': false}),
      );
      await control.startIfEnabled();
      expect(main.mounted, isNull);
      expect((await control.status()).running, isFalse);
    });

    test('the toggle is the only thing that writes the preference', () async {
      await control.setEnabled(enabled: false);
      expect(_persistedEnabled(tmp), isFalse);
      expect(main.mounted, isNull);

      // Session controls, a dispatch force-start and shutdown all leave the
      // opt-out on disk — only the toggle moves it.
      await control.start();
      await control.stop();
      await control.ensureRunningForDispatch();
      expect(main.mounted, isNotNull, reason: 'agents still get the surface');
      await control.dispose();
      expect(_persistedEnabled(tmp), isFalse);

      await control.startIfEnabled();
      expect(main.mounted, isNull);
    });

    test('re-enabling starts it and survives the next boot', () async {
      await control.setEnabled(enabled: false);
      await control.setEnabled(enabled: true);
      expect(main.mounted, isNotNull);
      expect(_persistedEnabled(tmp), isTrue);

      await control.dispose();
      await control.startIfEnabled();
      expect(main.mounted, isNotNull);
    });
  });

  group('TLS topology companion', () {
    // Unique per-suite companion port so the bind never collides with a
    // running dev instance on the real default (9020).
    const companionPort = 8461;
    late ServerMcpControl tlsControl;
    late _FakeMainServer main;

    setUp(() {
      tlsControl = ServerMcpControl(
        dispatcher: McpToolDispatcher(registry: registry),
        dataDir: tmp.path,
        companionPort: companionPort,
      );
      main = _FakeMainServer(boundPort: 443, tls: true);
      tlsControl.attachMainServer(main);
    });

    tearDown(() async {
      await tlsControl.dispose();
    });

    test('start mounts AND binds a plaintext loopback companion', () async {
      await tlsControl.start();
      expect(main.mounted, isNotNull);

      final status = await tlsControl.status();
      expect(status.running, isTrue);
      // Clients are pointed at the main TLS listener, not the companion.
      expect(status.port, 443);

      // The companion really answers MCP on its loopback port.
      final client = HttpClient();
      try {
        final request = await client.post('127.0.0.1', companionPort, '/mcp');
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'tools/call',
            'params': {
              'name': 'alpha',
              'arguments': {'workspace_id': 'ws-1'},
            },
            'id': 1,
          }),
        );
        final resp = await request.close();
        expect(resp.statusCode, 200);
        await resp.drain<void>();
      } finally {
        client.close();
      }
    });

    test('agent MCP config points at the loopback companion', () async {
      await tlsControl.start();
      final target = File('${tmp.path}/agent/.mcp.json');
      await tlsControl.writeAgentMcpConfig(target, workspaceId: 'ws-1');
      final json =
          jsonDecode(target.readAsStringSync()) as Map<String, dynamic>;
      final server = ((json['mcpServers'] as Map)['control-center'] as Map)
          .cast<String, dynamic>();
      expect(server['url'], 'http://127.0.0.1:$companionPort/mcp');
    });
  });

  group('standalone fallback (no main listener)', () {
    const companionPort = 8462;
    late ServerMcpControl standalone;

    setUp(() {
      standalone = ServerMcpControl(
        dispatcher: McpToolDispatcher(registry: registry),
        dataDir: tmp.path,
        companionPort: companionPort,
      );
    });

    tearDown(() async {
      await standalone.dispose();
    });

    test('start binds the loopback companion and status reflects it', () async {
      await standalone.start();
      final status = await standalone.status();
      expect(status.running, isTrue);
      expect(status.port, companionPort);
    });

    test('a legacy config with a port key loads, port ignored', () async {
      File('${tmp.path}/mcp_config.json').writeAsStringSync(
        jsonEncode({'port': 9999, 'enabled': true, 'token': 'abc'}),
      );
      final status = await standalone.status();
      expect(status.enabled, isTrue);
      expect(status.hasToken, isTrue);
      expect(status.port, companionPort);
    });
  });
}

/// The `enabled` flag as it sits on disk, or null when nothing was persisted.
bool? _persistedEnabled(Directory dataDir) {
  final file = File('${dataDir.path}/mcp_config.json');
  if (!file.existsSync()) {
    return null;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return json['enabled'] as bool?;
}

String _revOf(File mcpJson) {
  final json = jsonDecode(mcpJson.readAsStringSync()) as Map<String, dynamic>;
  final server = ((json['mcpServers'] as Map)['control-center'] as Map)
      .cast<String, dynamic>();
  return (server['headers'] as Map)['X-CC-Toolset-Rev'] as String;
}
