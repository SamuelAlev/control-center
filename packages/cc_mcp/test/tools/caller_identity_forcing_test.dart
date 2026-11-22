import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/governance/domain/services/heartbeat_monitor_service.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart'
    show PairRateLimiter;
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/mcp_script_surface.dart' show hiddenScopeParams;
import 'package:cc_mcp/src/tools/add_review_node_tool.dart';
import 'package:cc_mcp/src/tools/confirm_review_node_tool.dart';
import 'package:cc_mcp/src/tools/dismiss_review_node_tool.dart';
import 'package:cc_mcp/src/tools/get_my_notes_tool.dart';
import 'package:cc_mcp/src/tools/governance_runtime_tools.dart';
import 'package:cc_mcp/src/tools/record_observation_tool.dart';
import 'package:cc_mcp/src/tools/request_peer_review_tool.dart';
import 'package:cc_mcp/src/tools/resolve_review_node_tool.dart';
import 'package:cc_mcp/src/tools/send_message_tool.dart';
import 'package:cc_mcp/src/tools/submit_reviewer_verdict_tool.dart';
import 'package:cc_mcp/src/tools/update_my_notes_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// An argument that names the CALLER is the run's own agent: forced from the
/// trusted call scope (a model-supplied value is replaced) and hidden from the
/// model's schema wherever the run can supply it. A person's own MCP client
/// has no scope, so their call keeps the value they pass.
void main() {
  final messaging = _Messaging();
  final memory = _Memory();
  final status = _Status();

  /// Each tool, and the argument that names its caller.
  final cases = <(McpTool, String)>[
    (SendSpaceMessageTool(repository: messaging), 'sender_id'),
    (AddReviewNodeTool(repository: messaging), 'sender_id'),
    (SubmitReviewerVerdictTool(repository: messaging), 'reviewer_id'),
    (
      RequestPeerReviewTool(
        agents: _Agents(),
        messaging: messaging,
        service: _Workflow(),
        peerAsks: PeerKit().service,
        rateLimiter: PairRateLimiter(),
      ),
      'requester_id',
    ),
    (AgentHeartbeatTool(service: _Heartbeats()), 'agent_id'),
    (GetMyNotesTool(repository: memory), 'agent_id'),
    (UpdateMyNotesTool(repository: memory), 'agent_id'),
    (RecordObservationTool(repository: memory), 'agent_id'),
    (ConfirmReviewNodeTool(repository: messaging), 'agent_id'),
    (DismissReviewNodeTool(status: status), 'agent_id'),
    (ResolveReviewNodeTool(status: status), 'agent_id'),
  ];

  const run = McpCallScope(
    workspaceId: 'ws-1',
    agentId: 'agent-a',
    conversationId: 'conv-1',
    attested: true,
  );

  for (final (tool, key) in cases) {
    group('${tool.name}.$key', () {
      test('is declared by the tool', () {
        expect(
          (tool.inputSchema['properties'] as Map).containsKey(key),
          isTrue,
        );
      });

      test("a model's value is replaced by the calling agent", () {
        final scoped = run.apply(
          {'workspace_id': 'ws-other', key: 'agent-evil'},
          tool.inputSchema,
          force: tool.forcedScopeKeys,
        );
        expect(scoped[key], 'agent-a');
        expect(scoped['workspace_id'], 'ws-1');
      });

      test('a run with no agent cannot name one: the value is dropped', () {
        final scoped = const McpCallScope(workspaceId: 'ws-1').apply(
          {key: 'agent-evil'},
          tool.inputSchema,
          force: tool.forcedScopeKeys,
        );
        expect(scoped.containsKey(key), isFalse);
      });

      test("a person's call (no scope) keeps the value they pass", () {
        final args = {'workspace_id': 'ws-1', key: 'agent-c'};
        expect(
          const McpCallScope().apply(
            args,
            tool.inputSchema,
            force: tool.forcedScopeKeys,
          ),
          args,
        );
      });

      test("is hidden from the run's schema", () {
        expect(hiddenScopeParams(tool, run), contains(key));
      });
    });
  }

  test('an agent_id that names a target stays the model\'s choice', () {
    // `consolidate_memory`, ticket assignment and the like keep `agent_id`
    // as a target: only tools that force it hide it.
    final target = _TargetTool();
    final scoped = run.apply({'agent_id': 'agent-b'}, target.inputSchema);
    expect(scoped['agent_id'], 'agent-b');
    expect(hiddenScopeParams(target, run), isNot(contains('agent_id')));
  });

  test('send_message posts as the calling agent, not the named one', () async {
    final tool = SendSpaceMessageTool(repository: messaging);
    final result = await tool.run(
      run.apply(
        {
          'workspace_id': 'ws-1',
          'space_id': 'space-1',
          'content': 'Done reviewing.',
          'sender_id': 'agent-evil',
        },
        tool.inputSchema,
        force: tool.forcedScopeKeys,
      ),
    );
    expect(result.isError, isFalse, reason: result.content.first.text);
    expect(messaging.lastSenderId, 'agent-a');
  });
}

class _TargetTool extends McpTool {
  @override
  String get name => 'target_tool';

  @override
  String get description => 'Acts on another agent.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'agent_id': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('ok');
}

class _Messaging implements MessagingRepository {
  String? lastSenderId;

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async => true;

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    lastSenderId = senderId;
    return id ?? 'm1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Memory implements AgentWorkingMemoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Status implements ReviewFindingStatusPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Heartbeats implements HeartbeatMonitorService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workflow implements TicketWorkflowService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
