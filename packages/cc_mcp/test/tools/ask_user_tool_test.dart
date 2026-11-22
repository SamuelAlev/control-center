import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show JsonRpcRequest;
import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/ask_user_tool.dart';
import 'package:test/test.dart';

import '../code_mode_fakes.dart';
import 'result_note_expect.dart';

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

  group('AskUserTool from a script', () {
    test('resolves to the structured answer, carries the origin and holds '
        "the script's clock", () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(
          selectedLabels: ['Blue'],
          freeText: 'and red',
        ),
      );
      final tool = AskUserTool(port: port);
      expect(tool.waitsOnPerson, isTrue);
      expect(tool.outputSchema['required'], ['selected', 'text', 'skipped']);
      final dispatcher = McpToolDispatcher(registry: McpToolRegistry([tool]));
      final waits = <bool>[];
      final outcome = await dispatcher.callNested(
        runScope(),
        nestedRequest(
          'ask_user',
          arguments: {'question': 'Which colour?'},
          onPersonWait: waits.add,
        ),
        approvals: ScriptApprovalBudget(),
      );
      expect(outcome.status, NestedCallStatus.completed);
      expect(outcome.value, {
        'selected': ['Blue'],
        'text': 'and red',
        'skipped': false,
      });
      expectNotedObject(
        tool.resultNote,
        outcome.value,
        required: {'selected', 'text', 'skipped'},
      );
      expect(waits, [true, false]);
      expect(port.seen!.origin?.parentToolCallId, 'toolu_parent');
      expect(port.seen!.conversationId, 'conv-1');
    });

    test('a question nobody answers rejects', () async {
      final dispatcher = McpToolDispatcher(
        registry: McpToolRegistry([AskUserTool(port: _RecordingPort(null))]),
      );
      final outcome = await dispatcher.callNested(
        runScope(),
        nestedRequest('ask_user', arguments: {'question': 'Which?'}),
        approvals: ScriptApprovalBudget(),
      );
      expect(outcome.status, NestedCallStatus.failed);
      expect(outcome.errorMessage, startsWith('No answer'));
    });

    test('a direct call has no origin', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      final result = await AskUserTool(port: port).call({
        'workspace_id': 'ws1',
        'space_id': 'space1',
        'conversation_id': 'conv1',
        'question': 'Which?',
      });
      expect(result.isError, isFalse);
      expect(result.structured, {
        'selected': <String>[],
        'text': null,
        'skipped': true,
      });
      expect(port.seen!.origin, isNull);
    });
  });
}
