import 'dart:async';
import 'dart:convert';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('sseTransformer', () {
    test('parses event/data/id frames split by blank lines', () async {
      const raw = 'event: endpoint\n'
          'data: /mcp\n'
          '\n'
          ': heartbeat\n'
          '\n'
          'data: {"jsonrpc":"2.0","id":1}\n'
          '\n';
      final events = await Stream<List<int>>.value(utf8.encode(raw))
          .transform(sseTransformer())
          .toList();
      expect(events, hasLength(2));
      expect(events[0].event, 'endpoint');
      expect(events[0].data, '/mcp');
      expect(events[1].data, '{"jsonrpc":"2.0","id":1}');
    });

    test('joins multi-line data per the SSE spec', () async {
      const raw = 'data: line1\ndata: line2\n\n';
      final events = await Stream<List<int>>.value(utf8.encode(raw))
          .transform(sseTransformer())
          .toList();
      expect(events.single.data, 'line1\nline2');
    });
  });

  group('BridgedMcpTool', () {
    test('namespaces and sanitises the tool name', () {
      expect(
        BridgedMcpTool.bridgedName('my-server', 'do.thing'),
        'mcp__my-server__do_thing',
      );
      expect(BridgedMcpTool.isBridgedName('mcp__x__y'), isTrue);
      expect(BridgedMcpTool.isBridgedName('list_workspaces'), isFalse);
    });

    test('converts a remote text result into a CallResult', () async {
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'echo',
          description: 'd',
          inputSchema: {'type': 'object'},
        ),
        invoker: (server, name, args) async => {
          'content': [
            {'type': 'text', 'text': 'hi ${args['who']}'},
          ],
          'isError': false,
        },
      );
      final result = await tool.call({'who': 'bob'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, 'hi bob');
    });

    test('propagates remote errors', () async {
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'x',
          description: 'd',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => {
          'content': [
            {'type': 'text', 'text': 'kaboom'},
          ],
          'isError': true,
        },
      );
      final result = await tool.call({});
      expect(result.isError, isTrue);
      expect(result.content.first.text, 'kaboom');
    });

    test('external tools default to exec tier (untrusted)', () {
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'x',
          description: 'd',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => const {},
      );
      expect(tool.toolApproval(const {}).tier, CapabilityTier.exec);
      expect(tool.requiresApproval, isTrue);
    });
  });

  group('McpServerConfig', () {
    test('origin strips path and query', () {
      final config = McpServerConfig.http(
        name: 'h',
        url: 'https://api.example.com/v1/mcp?x=1',
      );
      expect(config.origin, 'https://api.example.com');
    });

    test('validity checks transport-specific fields', () {
      expect(
        McpServerConfig.stdio(name: 's', command: '').isValid,
        isFalse,
      );
      expect(
        McpServerConfig.http(name: 'h', url: 'not a url').isValid,
        isFalse,
      );
      expect(
        McpServerConfig.http(name: 'h', url: 'https://x/mcp').isValid,
        isTrue,
      );
    });
  });
}
