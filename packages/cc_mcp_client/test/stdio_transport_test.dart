import 'dart:io';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

/// Spawn the child via the Dart binary actually running the tests rather than a
/// bare `dart` on PATH — this repo pins its SDK via fvm, so `dart` is not
/// guaranteed to resolve in every shell.
final String _dart = Platform.resolvedExecutable;

void main() {
  group('StdioTransport + McpClient (real subprocess)', () {
    late McpClient client;

    setUp(() {
      final config = McpServerConfig.stdio(
        name: 'fake',
        command: _dart,
        args: ['run', _fixtureServerPath()],
      );
      client = McpClient(StdioTransport(config));
    });

    tearDown(() async {
      await client.close();
    });

    test('initializes, lists tools and calls a tool', () async {
      final caps = await client.initialize(
        timeout: const Duration(seconds: 30),
      );
      expect(caps.tools, isTrue);
      expect(client.serverName, 'fake-stdio');

      final tools = await client.listTools();
      expect(tools.map((t) => t.name), containsAll(['echo', 'add']));

      final echo = await client.callTool('echo', {'text': 'hello world'});
      expect(echo['isError'], isFalse);
      final content = echo['content'] as List;
      expect((content.first as Map)['text'], 'hello world');

      final add = await client.callTool('add', {'a': 2, 'b': 3});
      expect(((add['content'] as List).first as Map)['text'], '5');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('ConnectionManager bridges a stdio server into local tools', () {
    test('bridged tools are namespaced and callable', () async {
      final manager = ConnectionManager(
        transportFactory: (config) async => StdioTransport(config),
      );
      addTearDown(manager.shutdown);

      await manager.connectAll([
        McpServerConfig.stdio(
          name: 'fake',
          command: _dart,
          args: ['run', _fixtureServerPath()],
        ),
      ]);

      // `connectAll` returns on the STARTUP GATE, not on the slowest server —
      // that is the point of the gate, and `dart run` is comfortably slower
      // than it. A real client waits for `toolsChanged`; this waits for the
      // same signal by polling the status it drives.
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (manager.statuses.single.lifecycle !=
              McpServerLifecycle.connected &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      final statuses = manager.statuses;
      expect(statuses.single.lifecycle, McpServerLifecycle.connected);
      expect(statuses.single.toolCount, 2);

      final tools = manager.tools;
      final echoTool = tools.firstWhere((t) => t.name == 'mcp__fake__echo');
      expect(echoTool.remoteTool.name, 'echo');

      final result = await echoTool.call({'text': 'bridged'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, 'bridged');
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

/// Absolute path to the fake stdio MCP server fixture.
///
/// Resolved rather than written relative to the CWD: `dart test
/// packages/cc_mcp_client` from the repo root and `dart test` from the package
/// root have different working directories, and the relative form made the
/// subprocess fail to start — which surfaced as "transport closed before
/// response", i.e. as a transport bug rather than a missing file.
String _fixtureServerPath() {
  const leaf = 'test/fixtures/fake_stdio_mcp_server.dart';
  var dir = Directory.current;
  while (true) {
    for (final candidate in [
      '${dir.path}/$leaf',
      '${dir.path}/packages/cc_mcp_client/$leaf',
    ]) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate $leaf from ${Directory.current.path}');
    }
    dir = parent;
  }
}
