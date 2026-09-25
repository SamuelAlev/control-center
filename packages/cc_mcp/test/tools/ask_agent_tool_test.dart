import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_mcp/src/tools/ask_agent_tool.dart';
import 'package:cc_mcp/src/tools/pending_delegation_hops.dart';
import 'package:test/test.dart';

/// `ask_agent` blocks on the recipient's reply in the pair's DM space. The
/// ask and the dispatch both land in the space's STANDING conversation (its
/// own uuid — never the space id), so the reply watch must stream the space,
/// not a conversation keyed on the space id: the old `watchMessages(spaceId)`
/// watched a row that never exists and every question burned the whole
/// timeout even when the reply had landed seconds in.
void main() {
  const workspaceId = 'ws-1';

  late _FakeAgentRepository agents;
  late _FakeMessagingRepository messaging;
  late _FakeMessagingPort messagingPort;
  late AskAgentTool tool;
  late _FakeTickets tickets;

  late int? remainingBudget;
  late AutonomyLevel askerAutonomy;
  late AutonomyLevel recipientAutonomy;

  setUp(() {
    agents = _FakeAgentRepository();
    messaging = _FakeMessagingRepository();
    tickets = _FakeTickets();
    messagingPort = _FakeMessagingPort();
    remainingBudget = null;
    askerAutonomy = AutonomyLevel.actWithApproval;
    recipientAutonomy = AutonomyLevel.actWithApproval;
    tool = AskAgentTool(
      agents: agents,
      messaging: messaging,
      messagingPort: messagingPort,
      rateLimiter: PairRateLimiter(),
      service: TicketWorkflowService(
        repository: tickets,
        eventBus: DomainEventBus(),
        resolveEffectiveAutonomy:
            ({required workspaceId, required agentId, spaceId}) async =>
                agentId == 'agent-a' ? askerAutonomy : recipientAutonomy,
        resolveRemainingBudgetCents:
            ({required workspaceId, required agentId}) async => remainingBudget,
      ),
      pendingHops: PendingDelegationHops(),
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

  Future<Map<String, dynamic>> ask({int timeoutSeconds = 5}) async {
    final result = await tool.run({
      'workspace_id': workspaceId,
      'to_agent_id': 'agent-b',
      'message': 'Is the cast safe?',
      'from_agent_id': 'agent-a',
      'timeout_seconds': timeoutSeconds,
    });
    expect(result.isError, isFalse);
    return jsonDecode(result.content.first.text) as Map<String, dynamic>;
  }

  test('a reply in the DM space resolves as replied, not a timeout', () async {
    // The recipient answers from its dispatch — into the standing
    // conversation, like every dispatch that names no stream.
    messagingPort.onDispatched = (agentId, prompt) {
      messaging.post(
        senderId: 'agent-b',
        senderType: SenderType.agent,
        content: 'Yes — the payload is guarded upstream.',
      );
    };

    final answer = await ask();

    expect(answer['status'], 'replied');
    expect(answer['reply'], contains('guarded upstream'));
    expect(answer['recipient_agent_id'], 'agent-b');
  });

  test('no reply resolves to the structured pending result', () async {
    final answer = await ask(timeoutSeconds: 1);

    expect(answer['status'], 'timeout');
    expect(answer['recipient_agent_id'], 'agent-b');
    expect(answer['pending_message_id'], isNotEmpty);
  });

  test('the DM space checks out no repos', () async {
    await ask(timeoutSeconds: 1);

    expect(messaging.createSpaceCalled, isTrue);
    expect(
      messaging.createdWithRepoIds,
      isEmpty,
      reason:
          'An agent DM is a message channel. A null scope means EVERY '
          'workspace repo to the provisioner, so the first sentence one agent '
          'sent another copied the whole workspace onto disk.',
    );
  });
  test('autonomy ceiling and exhausted budget refuse before posting', () async {
    askerAutonomy = AutonomyLevel.proposeOnly;
    recipientAutonomy = AutonomyLevel.actFreely;
    final args = {
      'workspace_id': workspaceId,
      'from_agent_id': 'agent-a',
      'to_agent_id': 'agent-b',
      'message': 'Can you check?',
    };
    final autonomy = await tool.run(args);
    expect(autonomy.isError, isTrue);
    expect(autonomy.content.first.text, contains('ceiling'));
    askerAutonomy = recipientAutonomy;
    remainingBudget = 0;
    final budget = await tool.run(args);
    expect(budget.isError, isTrue);
    expect(budget.content.first.text, contains('budget'));
    expect(messaging._messages, isEmpty);
    expect(messagingPort.dispatchCount, 0);
  });

  test(
    'ticket ancestry consumes depth and foreign parent fails closed',
    () async {
      tickets.store['parent'] = Ticket(
        id: 'parent',
        workspaceId: workspaceId,
        title: 'Current ticket',
        assignedAgentId: 'agent-a',
        status: TicketStatus.open,
        delegationDepth: 3,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final args = {
        'workspace_id': workspaceId,
        'from_agent_id': 'agent-a',
        'to_agent_id': 'agent-b',
        'message': 'Need help',
        'parent_ticket_id': 'parent',
      };
      final depth = await tool.run(args);
      expect(depth.isError, isTrue);
      expect(depth.content.first.text, contains('depth'));
      tickets.store['parent'] = Ticket(
        id: 'parent',
        workspaceId: 'ws-other',
        title: 'Foreign ticket',
        assignedAgentId: 'agent-a',
        status: TicketStatus.open,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final foreign = await tool.run(args);
      expect(foreign.isError, isTrue);
      expect(foreign.content.first.text, contains('workspace'));
      expect(messaging._messages, isEmpty);
      expect(messagingPort.dispatchCount, 0);
    },
  );

  test('an active A→B ask refuses B→A without dispatching the cycle', () async {
    agents.add(
      Agent(
        id: 'agent-a',
        name: 'architect',
        title: 'Architect',
        agentMdPath: '$workspaceId/agents/architect/AGENTS.md',
        workspaceId: workspaceId,
        skills: AgentSkills(const []),
        createdAt: DateTime(2025),
      ),
    );
    final refused = Completer<bool>();
    messagingPort.onDispatched = (agentId, prompt) {
      () async {
        final result = await tool.run({
          'workspace_id': workspaceId,
          'from_agent_id': 'agent-b',
          'to_agent_id': 'agent-a',
          'message': 'Please answer me first',
        });
        refused.complete(
          result.isError && result.content.first.text.contains('cycle'),
        );
        messaging.post(
          senderId: 'agent-b',
          senderType: SenderType.agent,
          content: 'Answer sent',
        );
      }();
    };
    final answer = await ask();
    expect(answer['status'], 'replied');
    expect(await refused.future, isTrue);
    expect(messagingPort.dispatchCount, 1);
  });
}

class _FakeTickets implements TicketRepository {
  final Map<String, Ticket> store = {};

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final ticket = store[id];
    return ticket?.workspaceId == workspaceId ? ticket : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
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
  final _controller = StreamController<List<Message>>.broadcast();
  final List<Message> _messages = [];
  var _seq = 0;

  /// Simulates an agent answering: persists the message and emits the new
  /// space state on the space-wide watch, exactly as a real write would.
  void post({
    required String senderId,
    required SenderType senderType,
    required String content,
  }) {
    _messages.add(
      Message(
        id: 'm${++_seq}',
        spaceId: 'dm-1',
        conversationId: 'standing-1',
        senderId: senderId,
        senderType: senderType,
        content: content,
        messageType: MessageType.text,
        createdAt: DateTime(2026),
      ),
    );
    _controller.add(List.unmodifiable(_messages));
  }

  @override
  Stream<List<Message>> watchSpaceMessages(
    String workspaceId,
    String spaceId,
  ) async* {
    // Drift semantics: an initial snapshot, then live updates — a reply that
    // landed BEFORE the subscription (a synchronous recipient) is still seen.
    yield List.unmodifiable(_messages);
    yield* _controller.stream;
  }

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => List.unmodifiable(_messages);

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
    final messageId = id ?? 'm${++_seq}';
    _messages.add(
      Message(
        id: messageId,
        spaceId: spaceId,
        conversationId: conversationId ?? 'standing-1',
        senderId: senderId,
        senderType: SenderType.agent,
        content: content,
        messageType: MessageType.text,
        createdAt: DateTime(2026),
      ),
    );
    return messageId;
  }

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => const [];

  /// The repo scope the DM space was created with, so a test can pin that an
  /// agent-to-agent channel does not drag the workspace's checkouts onto disk.
  List<String>? createdWithRepoIds;
  bool createSpaceCalled = false;

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
  dynamic noSuchMethod(Invocation invocation) {}

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

class _FakeMessagingPort implements MessagingPort {
  /// Invoked by [dispatchAgent]: the test's chance to play the recipient.
  void Function(String agentId, String prompt)? onDispatched;

  int dispatchCount = 0;

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
    dispatchCount++;
    onDispatched?.call(agentId, prompt);
    return 'run-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}
