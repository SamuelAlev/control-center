import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/ask_user_tool.dart';
import 'package:test/test.dart';

class _RecordingPort implements AgentQuestionPort {
  _RecordingPort(this._answer);
  final AgentQuestionAnswer? _answer;
  AgentQuestionRequest? seen;

  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async {
    seen = request;
    return _answer;
  }
}

void main() {
  group('AskUserTool', () {
    test('refuses a question without a scoped conversation', () async {
      final port = _RecordingPort(null);
      final result = await AskUserTool(
        port: port,
      ).call({'workspace_id': 'ws1', 'question': 'Which?'});
      expect(result.isError, isTrue);
      expect(result.content.single.text, contains('space_id'));
      expect(port.seen, isNull);
    });

    test('refuses a missing conversation even with a valid space', () async {
      final port = _RecordingPort(null);
      final result = await AskUserTool(port: port).call({
        'workspace_id': 'ws1',
        'space_id': 'space1',
        'question': 'Which?',
      });
      expect(result.isError, isTrue);
      expect(result.content.single.text, contains('conversation_id'));
      expect(port.seen, isNull);
    });

    test(
      'dispatcher refuses a model-selected destination without a session',
      () async {
        final port = _RecordingPort(const AgentQuestionAnswer());
        final dispatcher = McpToolDispatcher(
          registry: McpToolRegistry([AskUserTool(port: port)]),
        );
        final result = await dispatcher.handleRequest(
          JsonRpcRequest(
            method: 'tools/call',
            params: {
              'name': 'ask_user',
              'arguments': {
                'workspace_id': 'ws-other',
                'space_id': 'space-other',
                'conversation_id': 'conv-other',
                'question': 'Which?',
              },
            },
            id: 1,
          ),
        );
        expect((result['result'] as Map)['isError'], isTrue);
        expect(port.seen, isNull);
      },
    );

    test(
      'dispatcher uses the session conversation despite conflicting args',
      () async {
        final port = _RecordingPort(const AgentQuestionAnswer());
        final dispatcher = McpToolDispatcher(
          registry: McpToolRegistry([AskUserTool(port: port)]),
        );
        final result = await dispatcher.handleScopedRequest(
          JsonRpcRequest(
            method: 'tools/call',
            params: {
              'name': 'ask_user',
              'arguments': {
                'workspace_id': 'ws-other',
                'space_id': 'space-other',
                'conversation_id': 'conv-standing',
                'agent_id': 'agent-other',
                'question': 'Which?',
              },
            },
            id: 2,
          ),
          scope: const McpCallScope(
            workspaceId: 'ws1',
            agentId: 'agent1',
            spaceId: 'space1',
            conversationId: 'conv-side',
          ),
        );
        expect((result['result'] as Map)['isError'], isFalse);
        expect(port.seen!.workspaceId, 'ws1');
        expect(port.seen!.spaceId, 'space1');
        expect(port.seen!.conversationId, 'conv-side');
        expect(port.seen!.askedByAgentId, 'agent1');
      },
    );

    test('a timeout is an error the agent can continue from', () async {
      final result = await AskUserTool(port: _RecordingPort(null)).call({
        'workspace_id': 'ws1',
        'space_id': 'space1',
        'conversation_id': 'conv-side',
        'question': 'Which?',
      });
      expect(result.isError, isTrue);
      expect(result.content.single.text, contains('timed out'));
    });
  });
}
