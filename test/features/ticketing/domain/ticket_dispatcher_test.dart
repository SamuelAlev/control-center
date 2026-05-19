import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/agents/domain/services/agent_readiness_checker.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_dispatcher.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TicketRepository] with optimistic locking on [update] (so the
/// workflow service's version-checked writes are exercised). Unused query
/// methods route through [noSuchMethod] and throw if ever hit.
class _FakeTicketRepo implements TicketRepository {
  final Map<String, Ticket> store = {};

  @override
  Future<void> insert(Ticket ticket) async => store[ticket.id] = ticket;

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    store[ticket.id] = ticket;
  }

  @override
  Future<Ticket?> getById(String id) async => store[id];

  @override
  Future<List<Ticket>> forPipelineRun(String w, String runId) async => store
      .values
      .where((t) => t.workspaceId == w && t.pipelineRunId == runId)
      .toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal agent repository returning one preconfigured agent by id.
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo(this.agent);
  final Agent agent;

  @override
  Future<Agent?> getById(String id) async => id == agent.id ? agent : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records dispatches so a test can assert whether the agent was started.
class _RecordingMessagingPort implements MessagingPort {
  final List<String> dispatchedTickets = [];

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {}

  @override
  Future<void> sendUserMessage(String channelId, String content) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async =>
      throw UnsupportedError('createGroup not expected in this test');

  @override
  Future<void> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    WakeContext? wakeContext,
    String? parentMessageId,
  }) async {
    dispatchedTickets.add(ticketId ?? '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs [onProvision] inside [ensureConversationWorkspace] to simulate work
/// (a repo clone) happening — and, in the race test, the pipeline being
/// stopped — while provisioning is in flight.
class _FakeProvisioner implements RepoWorkspaceProvisionerPort {
  _FakeProvisioner(this.onProvision);
  final Future<void> Function() onProvision;

  @override
  Future<String> ensureConversationWorkspace({
    required String workspaceId,
    required String channelId,
    required String fallbackDir,
    String? agentConfigDir,
    String? ticketId,
    String? ticketKey,
    String? ticketTitle,
    String branchType = 'feature',
  }) async {
    await onProvision();
    return fallbackDir;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTicketRepo repo;
  late DomainEventBus bus;
  late TicketWorkflowService workflow;
  late _RecordingMessagingPort messaging;

  const workspaceId = 'w';
  const agentId = 'agent-1';

  Agent readyAgent() => Agent(
        id: agentId,
        name: 'Worker',
        title: 'Worker',
        agentMdPath: '/agents/worker.md',
        workspaceId: workspaceId,
        skills: AgentSkills(const ['dart']),
        adapterId: 'claude-code',
        createdAt: DateTime(2026),
      );

  TicketDispatcher buildDispatcher(_FakeProvisioner provisioner) {
    final dispatcher = TicketDispatcher(
      eventBus: bus,
      ticketRepository: repo,
      ticketWorkflow: workflow,
      messagingPort: messaging,
      readinessChecker:
          AgentReadinessChecker(agentRepository: _FakeAgentRepo(readyAgent())),
      repoProvisioner: provisioner,
    );
    dispatcher.start();
    addTearDown(dispatcher.dispose);
    return dispatcher;
  }

  setUp(() {
    repo = _FakeTicketRepo();
    bus = DomainEventBus();
    workflow = TicketWorkflowService(repository: repo, eventBus: bus);
    messaging = _RecordingMessagingPort();
  });

  // Pumps the microtask/event queue until [predicate] holds or [tries] runs
  // out, so the asynchronous TicketAssigned handler can run to completion.
  Future<void> pumpUntil(bool Function() predicate, {int tries = 50}) async {
    for (var i = 0; i < tries && !predicate(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  test(
      'does NOT dispatch the agent when the pipeline cancels the ticket while '
      'the repo is being provisioned (clone-vs-stop race)', () async {
    const ticketId = 't-race';

    // The provisioner stands in for the repo clone: while it runs, the user
    // stops the pipeline — which (via PipelineEngine.cancel) cancels the
    // ticket. We reproduce that by cancelling the ticket mid-provision.
    buildDispatcher(_FakeProvisioner(() async {
      await workflow.cancelTicket(ticketId, workspaceId: workspaceId);
    }));

    // Creating an assigned ticket publishes TicketAssigned → the dispatcher
    // runs. Pre-set channelId so it reuses a channel instead of creating one.
    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Indexed work',
      assignedAgentId: agentId,
      channelId: 'chan-1',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );

    await pumpUntil(() => repo.store[ticketId]?.isTerminal ?? false);

    expect(repo.store[ticketId]!.status, TicketStatus.cancelled);
    expect(
      messaging.dispatchedTickets,
      isEmpty,
      reason: 'A cancelled pipeline must not dispatch its agent.',
    );
  });

  test('dispatches the agent normally when provisioning completes uncancelled',
      () async {
    const ticketId = 't-ok';

    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Indexed work',
      assignedAgentId: agentId,
      channelId: 'chan-1',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );

    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);

    expect(messaging.dispatchedTickets, [ticketId]);
    expect(repo.store[ticketId]!.status, TicketStatus.inProgress);
  });
}
