import 'dart:io' show Platform;

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
        args: ['run', 'test/fixtures/fake_stdio_mcp_server.dart'],
      );
      client = McpClient(StdioTransport(config));
    });

    tearDown(() async {
      await client.close();
    });

    test('initializes, lists tools, and calls a tool', () async {
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
          args: ['run', 'test/fixtures/fake_stdio_mcp_server.dart'],
        ),
      ]);

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
