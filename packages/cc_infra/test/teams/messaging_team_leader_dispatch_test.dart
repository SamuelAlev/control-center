import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/teams/domain/ports/team_leader_dispatch_port.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_harness/context.dart' show plainToolForm;
import 'package:cc_infra/src/dispatch/ticket_settled_wakes.dart';
import 'package:cc_infra/src/teams/messaging_team_leader_dispatch.dart';
import 'package:test/test.dart';

import '../dispatch/peer_test_kit.dart';

class _Messaging implements MessagingPort {
  final List<String> created = [];
  final List<({String spaceId, String agentId, String? startedByRunId})>
  dispatched = [];

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {}

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
  }) async {
    final id = 'sp-routed-${created.length + 1}';
    created.add(id);
    return Space(
      id: id,
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

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
    required WakeContext wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    dispatched.add((
      spaceId: spaceId,
      agentId: agentId,
      startedByRunId: wakeContext.startedByRunId,
    ));
    return 'run-x';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tickets implements TicketRepository {
  final Map<String, Ticket> byId = {};

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final t = byId[id];
    return t?.workspaceId == workspaceId ? t : null;
  }

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    final stored = byId[ticket.id];
    if (expectedVersion != null && stored?.version != expectedVersion) {
      throw StateError('version conflict');
    }
    byId[ticket.id] = ticket.copyWith(version: ticket.version + 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A team's leader is dispatched in the ticket's routed space (created once
/// and recorded, then reused), and a member's finished run wakes the leader
/// in its own conversation, never in a new space.
void main() {
  late PeerKit kit;
  late _Messaging messaging;
  late _Tickets tickets;
  late MessagingTeamLeaderDispatch dispatch;

  setUp(() async {
    kit = PeerKit()
      ..agent('lead', 'Lina')
      ..agent('alice', 'Alice')
      ..conversation('c-lead', spaceId: 'sp-lead')
      ..conversation('c-alice', spaceId: 'sp-alice')
      ..run(
        'run-lead',
        agentId: 'lead',
        conversationId: 'c-lead',
        requester: 'user-1',
      );
    messaging = _Messaging();
    tickets = _Tickets()
      ..byId['T-1'] = Ticket(
        id: 'T-1',
        workspaceId: PeerKit.ws,
        title: 'Fix the header',
        status: TicketStatus.open,
        assignedTeamId: 'team-1',
        createdAt: kit.now,
        updatedAt: kit.now,
      );
    dispatch = MessagingTeamLeaderDispatch(
      messaging,
      tickets: tickets,
      agents: kit.agentRepository,
      conversations: kit.conversationRepository,
      facts: CompletionFacts(
        messages: kit.messageRepository,
        runLogs: kit.runLogRepository,
      ),
      clock: () => kit.now,
    )..sink = kit.queue.enqueue;
    await kit.start();
  });

  Future<void> route({String? startedByRunId}) => dispatch.dispatchLeader(
    workspaceId: PeerKit.ws,
    agentId: 'lead',
    prompt: 'Route T-1',
    reason: WakeReason.assignment,
    startedByRunId: startedByRunId,
    ticketId: 'T-1',
  );

  test('the routed space is created once, recorded, then reused', () async {
    await route();
    await route();
    expect(messaging.created, ['sp-routed-1']);
    expect(tickets.byId['T-1']!.spaceId, 'sp-routed-1');
    expect(messaging.dispatched.map((d) => d.spaceId), [
      'sp-routed-1',
      'sp-routed-1',
    ]);
  });

  test('the leader\'s run records the assigning run as its starter; a '
      'person\'s assignment carries none', () async {
    await route(startedByRunId: 'run-assigner');
    await route();
    expect(messaging.dispatched.map((d) => d.startedByRunId), [
      'run-assigner',
      null,
    ]);
  });

  test('a member finishing wakes the leader once in its own conversation, '
      'for whoever its run acted for, with no space created', () async {
    kit.runs['run-alice'] = AgentRunLog(
      id: 'run-alice',
      agentId: 'alice',
      workspaceId: PeerKit.ws,
      spaceId: 'sp-alice',
      conversationId: 'c-alice',
      startedAt: kit.now,
      completedAt: kit.now,
      status: RunStatus.completed,
      summary: 'Header fixed.',
    );
    kit.messages['run-alice'] = Message(
      id: 'run-alice',
      spaceId: 'sp-alice',
      conversationId: 'c-alice',
      senderId: 'alice',
      senderType: SenderType.agent,
      content: 'The header is fixed.',
      messageType: MessageType.text,
      createdAt: kit.now,
    );
    const settled = TeamMemberSettled(
      workspaceId: PeerKit.ws,
      teamId: 'team-1',
      leaderAgentId: 'lead',
      leaderConversationId: 'c-lead',
      leaderRunId: 'run-lead',
      memberAgentId: 'alice',
      memberRunId: 'run-alice',
      memberConversationId: 'c-alice',
      ticketId: 'T-1',
      endReason: 'completed',
    );
    await dispatch.wakeLeader(settled);
    await dispatch.wakeLeader(settled);
    await kit.deliver();
    final wake = kit.wakes.all(PeerKit.ws).single;
    expect(wake.reason, WakeReason.childCompleted);
    expect(wake.agentId, 'lead');
    expect(wake.conversationId, 'c-lead');
    expect(wake.requestedByUserId, 'user-1');
    expect(wake.payload, 'The header is fixed.');
    expect(wake.detail.status, 'completed');
    expect(wake.detail.ticketId, 'T-1');
    expect(wake.detail.fields[WakeFields.teamId], 'team-1');
    expect(wake.detail.fields[WakeFields.summary], 'Header fixed.');
    expect(messaging.created, isEmpty);
    expect(messaging.dispatched, isEmpty);
    expect(kit.dispatched.single.conversationId, 'c-lead');
    expect(
      wakeFirstLine(wake, forms: plainToolForm),
      startsWith('- [child-completed] Alice '),
    );
  });

  test('a leader conversation of another workspace wakes nobody', () async {
    kit.conversation('c-x', spaceId: 'sp-x', workspaceId: PeerKit.other);
    await dispatch.wakeLeader(
      const TeamMemberSettled(
        workspaceId: PeerKit.ws,
        teamId: 'team-1',
        leaderAgentId: 'lead',
        leaderConversationId: 'c-x',
        memberAgentId: 'alice',
        memberRunId: 'run-alice',
        endReason: 'completed',
      ),
    );
    expect(kit.wakes.all(PeerKit.ws), isEmpty);
    expect(kit.wakes.all(PeerKit.other), isEmpty);
  });
}
