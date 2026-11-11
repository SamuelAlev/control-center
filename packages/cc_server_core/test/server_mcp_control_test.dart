import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
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
      // Writing an agent's config starts the surface; without a main
      // listener that binds the companion, so keep it off the real 9020.
      companionPort: 8463,
    );
  });

  tearDown(() async {
    await control.dispose();
    tmp.deleteSync(recursive: true);
  });

  group('writeAgentMcpConfig', () {
    test('hands the agent its run secret and nothing else', () async {
      final target = File('${tmp.path}/agent/.mcp.json');
      final path = await control.writeAgentMcpConfig(
        target,
        runToken: 'run-secret',
      );
      expect(path, target.path);

      final server = _serverOf(target);
      expect(server['type'], 'http');
      expect(server['url'], startsWith('http://127.0.0.1:'));

      final headers = (server['headers'] as Map).cast<String, String>();
      expect(headers, {
        McpCallScope.runGrantHeader: 'run-secret',
        'X-CC-Toolset-Rev': registry.toolsetRevision,
      });
      // No bearer token, no caller-written scope.
      expect(target.readAsStringSync(), isNot(contains('Authorization')));
      expect(target.readAsStringSync(), isNot(contains('X-CC-Workspace-Id')));
      expect(
        target.readAsStringSync(),
        isNot(contains(await control.token())),
      );
      // The standard `.mcp.json` stays free of client-specific keys so
      // `claude --strict-mcp-config` never chokes on it.
      expect(server.containsKey('lifecycle'), isFalse);
    });

    test('a run without a secret gets no config at all', () async {
      final target = File('${tmp.path}/agent/.mcp.json');
      await control.writeAgentMcpConfig(target, runToken: 'run-secret');

      expect(await control.writeAgentMcpConfig(target, runToken: null), isNull);
      expect(target.existsSync(), isFalse);
      expect(await control.agentMcpServersForDispatch(runToken: ''), isNull);
    });

    test(
      'toolset revision header changes when the catalogue changes',
      () async {
        final target = File('${tmp.path}/agent/.mcp.json');
        await control.writeAgentMcpConfig(target, runToken: 'run-secret');
        final before = _revOf(target);

        registry.register(_StubTool('gamma'));
        await control.writeAgentMcpConfig(target, runToken: 'run-secret');
        expect(_revOf(target), isNot(before));
      },
    );
  });

  group('token', () {
    test('is minted at first start and stored owner-only', () async {
      final token = await control.token();
      expect(base64Url.decode(base64Url.normalize(token)), hasLength(32));
      final file = File('${tmp.path}/mcp_config.json');
      expect(
        (jsonDecode(file.readAsStringSync()) as Map)['token'],
        token,
      );
      if (!Platform.isWindows) {
        expect(file.statSync().mode & 0x1ff, 0x180); // 0600
      }
      // A second control over the same data dir reads the same token.
      final again = ServerMcpControl(
        dispatcher: McpToolDispatcher(registry: registry),
        dataDir: tmp.path,
      );
      expect(await again.token(), token);
    });

    test('a stored config without a token gets one', () async {
      File('${tmp.path}/mcp_config.json').writeAsStringSync(
        jsonEncode({'enabled': false}),
      );
      expect(await control.token(), isNotEmpty);
      expect((await control.status()).enabled, isFalse);
    });

    test('rotation replaces it on disk and in the mounted handler', () async {
      final main = _FakeMainServer(boundPort: 9030);
      control.attachMainServer(main);
      await control.start();
      final handler = main.mounted;
      final before = await control.token();

      final after = await control.rotateToken();
      expect(after, isNot(before));
      expect(await control.token(), after);
      expect(main.mounted, same(handler), reason: 'no remount on rotation');
      expect(
        (jsonDecode(File('${tmp.path}/mcp_config.json').readAsStringSync())
            as Map)['token'],
        after,
      );
      await control.dispose();
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
      await control.writeAgentMcpConfig(target, runToken: 'run-secret');
      expect(_serverOf(target)['url'], 'http://127.0.0.1:9030/mcp');
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
        request.headers
          ..contentType = ContentType.json
          ..set('Authorization', 'Bearer ${await tlsControl.token()}');
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
      await tlsControl.writeAgentMcpConfig(target, runToken: 'run-secret');
      expect(_serverOf(target)['url'], 'http://127.0.0.1:$companionPort/mcp');
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

Map<String, dynamic> _serverOf(File mcpJson) {
  final json = jsonDecode(mcpJson.readAsStringSync()) as Map<String, dynamic>;
  return ((json['mcpServers'] as Map)['control-center'] as Map)
      .cast<String, dynamic>();
}

String _revOf(File mcpJson) =>
    (_serverOf(mcpJson)['headers'] as Map)['X-CC-Toolset-Rev'] as String;
