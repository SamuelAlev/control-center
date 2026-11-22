import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_message_limits.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/tools/ask_agent_tool.dart';
import 'package:cc_mcp/src/tools/consult_agent_tool.dart';
import 'package:cc_mcp/src/tools/delegate_task_tool.dart';
import 'package:cc_mcp/src/tools/request_peer_review_tool.dart';
import 'package:cc_mcp/src/tools/send_to_agent_tool.dart';
import 'package:test/test.dart';

import 'peer_tool_kit.dart';

/// The kit the current test delivers through.
late PeerKit _kit;

const _ws = 'ws-1';

/// `consult_agent`, `request_peer_review` and `send_to_agent` hand work to
/// another agent like `ask_agent` does, so they pass the same gate (depth,
/// cycle, autonomy ceiling, budget) and the same shared pair rate limit,
/// before anything is posted; a refusal spends no rate slot. Every peer text
/// is capped at [maxPeerMessageChars].
void main() {
  late _Agents agents;
  late _Messaging messaging;
  late PairRateLimiter limiter;
  late int? budget;
  late AutonomyLevel askerAutonomy;
  late AutonomyLevel recipientAutonomy;

  setUp(() async {
    agents = _Agents();
    messaging = _Messaging();
    _kit = PeerKit()
      ..agent('agent-a', 'planner')
      ..agent('agent-b', 'expert')
      ..conversation('c-sp-a', spaceId: 'sp-a')
      ..run('run-a', agentId: 'agent-a', conversationId: 'c-sp-a');
    limiter = PairRateLimiter(maxPerWindow: 1);
    budget = null;
    askerAutonomy = AutonomyLevel.actWithApproval;
    recipientAutonomy = AutonomyLevel.actWithApproval;
    await _kit.start();
  });

  TicketWorkflowService service() => TicketWorkflowService(
    repository: _NoTickets(),
    eventBus: DomainEventBus(),
    resolveEffectiveAutonomy:
        ({required workspaceId, required agentId, spaceId}) async =>
            agentId == 'agent-a' ? askerAutonomy : recipientAutonomy,
    resolveRemainingBudgetMicros:
        ({required workspaceId, required agentId}) async => budget,
  );

  /// Each gated tool, and its call from `agent-a` to `agent-b`.
  final cases =
      <
        String,
        (McpTool Function(), Map<String, dynamic> Function(String text))
      >{
        'consult_agent': (
          () => ConsultAgentTool(
            agents: agents,
            messaging: messaging,
            service: service(),
            peerAsks: _kit.service,
            rateLimiter: limiter,
          ),
          (text) => {
            'workspace_id': _ws,
            'space_id': 'plan-1',
            'topic': 'security',
            'question': text,
            'agent_id': 'agent-a',
            'to_agent_id': 'agent-b',
          },
        ),
        'request_peer_review': (
          () => RequestPeerReviewTool(
            agents: agents,
            messaging: messaging,
            service: service(),
            peerAsks: _kit.service,
            rateLimiter: limiter,
          ),
          (text) => {
            'workspace_id': _ws,
            'space_id': 'review-1',
            'node_message_id': 'node-1',
            'requester_id': 'agent-a',
            'target_agent_id': 'agent-b',
            'question': text,
          },
        ),
        'send_to_agent': (
          () => SendToAgentTool(
            agents: agents,
            messaging: messaging,
            rateLimiter: limiter,
            service: service(),
            peerAsks: _kit.service,
          ),
          (text) => {
            'workspace_id': _ws,
            'from_agent_id': 'agent-a',
            'to_agent_id': 'agent-b',
            'message': text,
          },
        ),
      };

  void expectNothingPosted() {
    expect(messaging.posted, isEmpty);
    expect(messaging.spacesCreated, 0);
    expect(messaging.participantsAdded, isEmpty);
    expect(_kit.dispatched, isEmpty);
  }

  for (final MapEntry(key: name, value: (build, call)) in cases.entries) {
    group(name, () {
      Future<CallResult> run([String text = 'Which index do we keep?']) =>
          (build() as McpScopedTool).callForRun(
            call(text),
            runScope(
              agentId: 'agent-a',
              runId: 'run-a',
              conversationId: 'c-sp-a',
            ),
          );

      /// A pending ask [asker] made of agent-a, answered by run-a.
      Future<void> askedBy(String asker, {List<String> chain = const []}) =>
          _kit.asks.insert(
            PeerAsk(
              id: 'ask-$asker',
              workspaceId: _ws,
              askerAgentId: asker,
              askerConversationId: 'c-$asker',
              askerSpaceId: 'sp-$asker',
              recipientAgentId: 'agent-a',
              recipientConversationId: 'c-sp-a',
              dispatchedRunId: 'run-a',
              questionHash: 'h-$asker',
              chain: chain,
              createdAt: _kit.now,
              expiresAt: _kit.now.add(const Duration(hours: 24)),
            ),
          );

      test('passes the gate and posts', () async {
        final result = await run();
        expect(result.isError, isFalse, reason: result.content.first.text);
        expect(messaging.posted, isNotEmpty);
      });

      test('a chain past the depth cap is refused before posting', () async {
        // agent-z asked agent-a, on behalf of agent-y, on behalf of agent-x.
        await askedBy('agent-z', chain: ['agent-x', 'agent-y']);
        final result = await run();
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('depth'));
        expectNothingPosted();
      });

      test('a cycle is refused before posting', () async {
        await askedBy('agent-b');
        final result = await run();
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('cycle'));
        expectNothingPosted();
      });

      test('the autonomy ceiling is refused before posting', () async {
        askerAutonomy = AutonomyLevel.proposeOnly;
        recipientAutonomy = AutonomyLevel.actFreely;
        final result = await run();
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('ceiling'));
        expectNothingPosted();
      });

      test('an exhausted budget is refused before posting', () async {
        budget = 0;
        final result = await run();
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('budget'));
        expectNothingPosted();
      });

      test('the shared pair rate limit refuses the next call', () async {
        expect((await run()).isError, isFalse);
        messaging.posted.clear();
        final started = _kit.dispatched.length;
        final second = await run('A different question?');
        expect(second.isError, isTrue);
        expect(second.content.first.text, contains('Rate limited'));
        expect(messaging.posted, isEmpty);
        expect(_kit.dispatched, hasLength(started));
      });

      test('a refused call spends no rate slot', () async {
        budget = 0;
        expect((await run()).isError, isTrue);
        budget = null;
        final result = await run();
        expect(result.isError, isFalse, reason: result.content.first.text);
      });

      test('a text over the limit is refused with the limit and where the '
          'content belongs, before anything else', () async {
        final result = await run('x' * (maxPeerMessageChars + 1));
        expect(result.isError, isTrue);
        final text = result.content.first.text;
        expect(text, contains('$maxPeerMessageChars'));
        expect(text, contains('file or a ticket'));
        expectNothingPosted();
        expect(
          (await run('x' * maxPeerMessageChars)).isError,
          isFalse,
          reason: 'the limit itself fits',
        );
      });

      test('the description says when not to message', () {
        expect(
          build().description,
          contains(
            'Message another agent only with a question that blocks you or a '
            'decision it must make, and send it to the one agent that can '
            'answer. Never send status, progress or completion notes: your '
            'result reaches whoever started you without a message.',
          ),
        );
      });
    });
  }

  group('a call with no calling agent (a person) is no agent hand-off', () {
    test('consult_agent posts without the gate', () async {
      budget = 0;
      final result = await cases['consult_agent']!.$1().run(
        {...cases['consult_agent']!.$2('Which index?')}..remove('agent_id'),
      );
      expect(result.isError, isFalse, reason: result.content.first.text);
      expect(_kit.dispatched.single.agentId, 'agent-b');
    });

    test('send_to_agent posts without the gate', () async {
      budget = 0;
      final result = await cases['send_to_agent']!.$1().run(
        {...cases['send_to_agent']!.$2('Which index?')}
          ..remove('from_agent_id'),
      );
      expect(result.isError, isFalse, reason: result.content.first.text);
      expect(_kit.dispatched.single.agentId, 'agent-b');
    });
  });

  test('consult_agent counts the rationale into the limit', () async {
    final result = await cases['consult_agent']!.$1().run({
      ...cases['consult_agent']!.$2('q' * 10000),
      'rationale': 'r' * 10000,
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('$maxPeerMessageChars'));
  });

  test('ask_agent refuses a message over the limit before posting', () async {
    final tool = AskAgentTool(
      agents: agents,
      messaging: messaging,
      rateLimiter: limiter,
      service: service(),
      peerAsks: _kit.service,
    );
    final result = await tool.run({
      'workspace_id': _ws,
      'from_agent_id': 'agent-a',
      'to_agent_id': 'agent-b',
      'message': 'x' * (maxPeerMessageChars + 1),
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('$maxPeerMessageChars'));
    expectNothingPosted();
  });

  test('delegate_task refuses a rendered brief over the limit', () async {
    final tool = DelegateTaskTool(service: service(), peerAsks: _kit.service);
    final result = await tool.run({
      'workspace_id': _ws,
      'title': 'Index audit',
      'from_agent_id': 'agent-a',
      'to_agent_id': 'agent-b',
      'description': 'd' * (maxPeerMessageChars - 10),
      'done_means': ['Every index has an owner'],
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('The brief is'));
    expect(result.content.first.text, contains('$maxPeerMessageChars'));
  });
}

class _NoTickets implements TicketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Agents implements AgentRepository {
  final List<Agent> _agents = [
    for (final (id, name) in [('agent-a', 'planner'), ('agent-b', 'expert')])
      Agent(
        id: id,
        name: name,
        title: 'Engineer',
        agentMdPath: '$_ws/agents/$name/AGENTS.md',
        workspaceId: _ws,
        skills: AgentSkills(const []),
        createdAt: DateTime(2025),
      ),
  ];

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    for (final a in _agents) {
      if (a.id == id && a.workspaceId == workspaceId) {
        return a;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _Messaging implements MessagingRepository {
  final List<String> posted = [];
  final List<String> participantsAdded = [];
  int spacesCreated = 0;

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      workspaceId == _ws;

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => const [];

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async => participantsAdded.add(principalId);

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
    spacesCreated++;
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
  }) async {
    posted.add(content);
    final messageId = id ?? 'm${posted.length}';
    _kit.conversation('c-$spaceId', spaceId: spaceId, workspaceId: workspaceId);
    _kit.messages[messageId] = Message(
      id: messageId,
      spaceId: spaceId,
      conversationId: 'c-$spaceId',
      senderId: senderId,
      senderType: SenderType.agent,
      content: content,
      messageType: MessageType.text,
      createdAt: _kit.now,
    );
    return messageId;
  }

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      _kit.messages[messageId];

  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
