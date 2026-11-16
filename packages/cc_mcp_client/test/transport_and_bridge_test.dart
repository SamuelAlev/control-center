import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('sseTransformer', () {
    test('parses event/data/id frames split by blank lines', () async {
      const raw =
          'event: endpoint\n'
          'data: /mcp\n'
          '\n'
          ': heartbeat\n'
          '\n'
          'data: {"jsonrpc":"2.0","id":1}\n'
          '\n';
      final events = await Stream<List<int>>.value(
        utf8.encode(raw),
      ).transform(sseTransformer()).toList();
      expect(events, hasLength(2));
      expect(events[0].event, 'endpoint');
      expect(events[0].data, '/mcp');
      expect(events[1].data, '{"jsonrpc":"2.0","id":1}');
    });

    test('joins multi-line data per the SSE spec', () async {
      const raw = 'data: line1\ndata: line2\n\n';
      final events = await Stream<List<int>>.value(
        utf8.encode(raw),
      ).transform(sseTransformer()).toList();
      expect(events.single.data, 'line1\nline2');
    });
  });

  group('a public-only server', () {
    late HttpServer local;
    var hits = 0;

    setUp(() async {
      hits = 0;
      local = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      local.listen((request) {
        hits++;
        request.response
          ..statusCode = 200
          ..close();
      });
    });
    tearDown(() => local.close(force: true));

    McpServerConfig config({required bool publicOnly}) => McpServerConfig.http(
      name: 'ws',
      url: 'http://127.0.0.1:${local.port}/mcp',
    ).copyWith(publicOnly: publicOnly);

    test('is dialled through the injected factory, never directly', () async {
      final asked = <String>[];
      final transport = StreamableHttpTransport(
        config(publicOnly: true),
        publicOnlyConnection: (uri, _, _) {
          asked.add(uri.host);
          return Future.error(SocketException('refused ${uri.host}'));
        },
      );
      await transport.start();
      await expectLater(
        transport.send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}),
        throwsA(isA<McpTransportException>()),
      );
      expect(asked, ['127.0.0.1']);
      expect(hits, 0);
      await transport.close();
    });

    test('with no factory refuses every connection', () async {
      final transport = StreamableHttpTransport(config(publicOnly: true));
      await transport.start();
      await expectLater(
        transport.send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}),
        throwsA(isA<McpTransportException>()),
      );
      expect(hits, 0);
      await transport.close();
    });

    test('an approved one connects as configured', () async {
      final transport = StreamableHttpTransport(config(publicOnly: false));
      await transport.start();
      try {
        await transport.send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'});
      } on Object {
        // The stub answers with no body; reaching it is the point.
      }
      expect(hits, 1);
      await transport.close();
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

    test('a long name fits Claude Code\'s prefix and stays distinct', () {
      final a = BridgedMcpTool.bridgedName(
        'linear',
        'create_issue_with_attachments_and_labels',
      );
      final b = BridgedMcpTool.bridgedName(
        'linear',
        'create_issue_with_attachments_and_labelz',
      );
      expect(a.length, BridgedMcpTool.maxBridgedNameLength);
      expect(b.length, BridgedMcpTool.maxBridgedNameLength);
      expect(a, isNot(b));
      expect(a, startsWith('mcp__linear__create_issue'));
      // `mcp__control-center__` plus the name stays within the model API's 64.
      expect('mcp__control-center__$a'.length, lessThanOrEqualTo(64));
      expect(a, matches(RegExp(r'^[a-zA-Z0-9_-]+$')));
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

    test('strips ANSI escapes and control chars from result text', () async {
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'x',
          description: 'd',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => {
          'content': [
            // CSI colour codes + a NUL + a BEL wrapped around real text.
            {'type': 'text', 'text': '\x1B[31mred\x1B[0m\x00 text\x07'},
          ],
          'isError': false,
        },
      );
      final result = await tool.call(const {});
      expect(result.content.first.text, 'red text');
    });

    test('strips ANSI escapes from the bridged description', () {
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'x',
          description: '\x1B[1mDoes\x1B[0m a thing',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => const {},
      );
      expect(tool.description, '[srv] Does a thing');
    });

    test('caps unbounded external output with a truncation marker', () async {
      final huge = 'A' * (BridgedMcpTool.maxResultChars + 5000);
      final tool = BridgedMcpTool(
        serverName: 'srv',
        remoteTool: const McpRemoteTool(
          name: 'x',
          description: 'd',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => {
          'content': [
            {'type': 'text', 'text': huge},
          ],
          'isError': false,
        },
      );
      final result = await tool.call(const {});
      final text = result.content.first.text;
      expect(text.length, lessThan(huge.length));
      expect(text, contains('external output truncated'));
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
      expect(McpServerConfig.stdio(name: 's', command: '').isValid, isFalse);
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
