import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_mcp/src/tools/send_to_agent_tool.dart';
import 'package:test/test.dart';

void main() {
  const workspaceId = 'ws-1';

  late _FakeAgentRepository agents;
  late _FakeMessagingRepository messaging;
  late _FakeMessagingPort port;
  late SendToAgentTool tool;

  setUp(() {
    agents = _FakeAgentRepository();
    messaging = _FakeMessagingRepository();
    port = _FakeMessagingPort();
    tool = SendToAgentTool(
      agents: agents,
      messaging: messaging,
      messagingPort: port,
      rateLimiter: PairRateLimiter(),
    );
    agents.add(
      Agent(
        id: 'agent-b',
        name: 'reviewer',
        title: 'Reviewer',
        agentMdPath: '$workspaceId/agents/reviewer/AGENTS.md',
        workspaceId: workspaceId,
        skills: AgentSkills(const []),
        createdAt: DateTime(2025),
      ),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'to_agent_id': 'agent-b',
      'message': 'hello',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('wakes the recipient and does not checkout repos', () async {
    final result = await tool.run({
      'workspace_id': workspaceId,
      'to_agent_id': 'agent-b',
      'from_agent_id': 'agent-a',
      'message': 'Please look at the cast.',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['recipient_agent_id'], 'agent-b');
    expect(body['delivery_status'], 'woken');
    expect(port.lastAgentId, 'agent-b');
    expect(messaging.createSpaceCalled, isTrue);
    expect(messaging.createdWithRepoIds, isEmpty);
  });
}

class _FakeAgentRepository implements AgentRepository {
  final List<Agent> _agents = [];

  void add(Agent agent) => _agents.add(agent);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessagingRepository implements MessagingRepository {
  List<String>? createdWithRepoIds;
  bool createSpaceCalled = false;

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => const [];

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    dynamic mode,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async {
    createSpaceCalled = true;
    createdWithRepoIds = repoIds;
    return Space(
      id: 'dm-1',
      name: name,
      workspaceId: workspaceId,
      kind: kind,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

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
  }) async => id ?? 'm1';

  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessagingPort implements MessagingPort {
  String? lastAgentId;

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    dynamic wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    dynamic outputContractMode,
  }) async {
    lastAgentId = agentId;
    return 'run-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
