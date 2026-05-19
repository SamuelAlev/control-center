// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _EchoTool extends McpTool {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echoes back the message';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'message': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> call(Map<String, dynamic> arguments) async {
    final message = arguments['message'] as String? ?? '';
    return CallResult.success('echo: $message');
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final message = arguments['message'] as String? ?? '';
    return CallResult.success('echo: $message');
  }
}

class _FailingTool extends McpTool {
  @override
  String get name => 'failing';

  @override
  String get description => 'Always fails';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  Future<CallResult> call(Map<String, dynamic> arguments) async {
    throw Exception('intentional failure');
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    throw Exception('intentional failure');
  }
}

void main() {
  group('McpToolDispatcher', () {
    late McpToolDispatcher dispatcher;

    setUp(() {
      final registry = McpToolRegistry([_EchoTool(), _FailingTool()]);
      dispatcher = McpToolDispatcher(registry: registry);
    });

    group('initialize', () {
      test('returns server capabilities', () async {
        final request = JsonRpcRequest(
          method: 'initialize',
          params: {
            'clientInfo': {'name': 'test-client'},
          },
          id: 1,
        );

        final result = await dispatcher.handleRequest(request);
        expect(result['id'], 1);
        expect(result['result']['protocolVersion'], '2024-11-05');
        expect(result['result']['serverInfo']['name'], 'control-center');
        expect(result['result']['capabilities']['tools'], isNotNull);
      });

      test('returns instructions for unknown client', () async {
        final request = JsonRpcRequest(method: 'initialize', params: {}, id: 2);

        final result = await dispatcher.handleRequest(request);
        expect(result['result']['instructions'], isNotEmpty);
      });
    });

    group('tools/list', () {
      test('returns all tool definitions', () async {
        final request = JsonRpcRequest(method: 'tools/list', params: {});

        final result = await dispatcher.handleRequest(request);
        final tools = result['result']['tools'] as List<dynamic>;
        expect(tools, hasLength(2));
        expect(tools[0]['name'], isA<String>());
        expect(tools[0]['inputSchema'], isA<Map>());
      });
    });

    group('tools/call', () {
      test('calls a tool and returns result', () async {
        final request = JsonRpcRequest(
          method: 'tools/call',
          params: {
            'name': 'echo',
            'arguments': {'message': 'hello world'},
          },
          id: 3,
        );

        final result = await dispatcher.handleRequest(request);
        expect(result['id'], 3);
        final toolResult = result['result'] as Map<String, dynamic>;
        expect(toolResult['isError'], false);
        final content = toolResult['content'] as List<dynamic>;
        expect(content[0]['text'], 'echo: hello world');
      });

      test('returns error for unknown tool', () async {
        final request = JsonRpcRequest(
          method: 'tools/call',
          params: {'name': 'nonexistent', 'arguments': {}},
          id: 4,
        );

        final result = await dispatcher.handleRequest(request);
        expect(result['error'], isNotNull);
        expect(result['error']['code'], -32602);
      });

      test('returns error when tool throws', () async {
        final request = JsonRpcRequest(
          method: 'tools/call',
          params: {'name': 'failing', 'arguments': {}},
          id: 5,
        );

        final result = await dispatcher.handleRequest(request);
        final toolResult = result['result'] as Map<String, dynamic>;
        expect(toolResult['isError'], true);
        expect(
          toolResult['content'][0]['text'],
          contains('intentional failure'),
        );
      });

      test('returns error for missing tool name', () async {
        final request = JsonRpcRequest(
          method: 'tools/call',
          params: {'arguments': {}},
          id: 6,
        );

        final result = await dispatcher.handleRequest(request);
        expect(result['error'], isNotNull);
        expect(result['error']['code'], -32602);
      });
    });

    group('unknown method', () {
      test('returns method not found error', () async {
        final request = JsonRpcRequest(
          method: 'unknown/method',
          params: {},
          id: 7,
        );

        final result = await dispatcher.handleRequest(request);
        expect(result['error'], isNotNull);
        expect(result['error']['code'], -32601);
      });
    });

    group('notifications/initialized', () {
      test('returns empty result', () async {
        final request = JsonRpcRequest(
          method: 'notifications/initialized',
          params: {},
        );

        final result = await dispatcher.handleRequest(request);
        expect(result, isEmpty);
      });
    });
  });
}
