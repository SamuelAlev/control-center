// ignore_for_file: avoid_dynamic_calls

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// Records the arguments it was called with; declares the scoped ids in its
/// schema so [McpCallScope.apply] targets them.
class _ScopeProbeTool extends McpTool {
  Map<String, dynamic>? lastArgs;

  @override
  String get name => 'scope_probe';

  @override
  String get description => 'Records scoped arguments';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'agent_id': {'type': 'string'},
      'conversation_id': {'type': 'string'},
      'space_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    lastArgs = arguments;
    return CallResult.success('ok');
  }
}

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
        // Uncaught tool exceptions are sanitized — they can embed paths, SQL,
        // or auth detail and results serialize verbatim to remote callers.
        expect(
          toolResult['content'][0]['text'],
          'Internal error executing failing',
        );
        expect(
          toolResult['content'][0]['text'],
          isNot(contains('intentional failure')),
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

    group('scoped tools/call', () {
      test(
        'forces workspace_id and fills empty identity args from the scope',
        () async {
          final probe = _ScopeProbeTool();
          final scopedDispatcher = McpToolDispatcher(
            registry: McpToolRegistry([probe]),
          );

          await scopedDispatcher.handleScopedRequest(
            JsonRpcRequest(
              method: 'tools/call',
              params: {
                'name': 'scope_probe',
                'arguments': {
                  // A model-supplied FOREIGN workspace must be overridden —
                  // workspace_id is the isolation boundary.
                  'workspace_id': 'ws-foreign',
                  // An explicit agent_id is preserved (fill only when empty).
                  'agent_id': 'agent-explicit',
                },
              },
              id: 1,
            ),
            scope: const McpCallScope(
              workspaceId: 'ws-own',
              agentId: 'agent-own',
              conversationId: 'conv-1',
              spaceId: 'sp-1',
            ),
          );

          expect(probe.lastArgs!['workspace_id'], 'ws-own');
          expect(probe.lastArgs!['agent_id'], 'agent-explicit');
          expect(probe.lastArgs!['conversation_id'], 'conv-1');
          expect(probe.lastArgs!['space_id'], 'sp-1');
        },
      );

      test(
        'no scope means verbatim arguments (Inspector/user tooling path)',
        () async {
          final probe = _ScopeProbeTool();
          final scopedDispatcher = McpToolDispatcher(
            registry: McpToolRegistry([probe]),
          );

          await scopedDispatcher.handleRequest(
            JsonRpcRequest(
              method: 'tools/call',
              params: {
                'name': 'scope_probe',
                'arguments': {'workspace_id': 'ws-any'},
              },
              id: 2,
            ),
          );

          expect(probe.lastArgs!['workspace_id'], 'ws-any');
          expect(probe.lastArgs!.containsKey('agent_id'), isFalse);
        },
      );
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
