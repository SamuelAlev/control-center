import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/agents/domain/services/agent_readiness_checker.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
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

/// Configurable agent repository. Returns [agent] when the id matches; null
/// otherwise. Leave [agent] null to simulate "not found" for any id.
class _FakeAgentRepo implements AgentRepository {
  _FakeAgentRepo({this.agent});
  final Agent? agent;

  @override
  Future<Agent?> getById(String id) async =>
      agent != null && id == agent!.id ? agent : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records dispatches so a test can assert whether the agent was started.
/// Also records [addAgentToChannel] calls and can be configured to throw on
/// [dispatchAgent] for testing the dispatch-failure path.
class _RecordingMessagingPort implements MessagingPort {
  final List<String> dispatchedTickets = [];
  final List<({String channelId, String agentId})> addedAgentToChannel = [];
  bool throwOnDispatch = false;

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {
    addedAgentToChannel.add((channelId: channelId, agentId: agentId));
  }

  @override
  Future<void> sendUserMessage(String channelId, String content) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  }) async {
    final now = DateTime.now();
    return Channel(
      id: 'chan-${name.hashCode.abs()}',
      name: name,
      isDm: false,
      mode: mode,
      workspaceId: workspaceId ?? '',
      createdAt: now,
      updatedAt: now,
    );
  }

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
    if (throwOnDispatch) {
      throw Exception('Simulated dispatch failure');
    }
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

  TicketDispatcher buildDispatcher(
    _FakeProvisioner provisioner, {
    Agent? agent,
  }) {
    final dispatcher = TicketDispatcher(
      eventBus: bus,
      ticketRepository: repo,
      ticketWorkflow: workflow,
      messagingPort: messaging,
      readinessChecker: AgentReadinessChecker(
        agentRepository: _FakeAgentRepo(agent: agent ?? readyAgent()),
      ),
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

  /// Builds a minimal [TicketAssigned] event for testing direct bus publishes.
  TicketAssigned fakeAssigned(String ticketId) => TicketAssigned(
        ticketId: ticketId,
        ticketTitle: 'Test ticket',
        assignedAgentId: agentId,
        workspaceId: workspaceId,
        occurredAt: DateTime.now(),
      );

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

  // ──── _onTicketAssigned: guard branches ─────────────────────────────────

  test('skips dispatch when ticket is not found', () async {
    const ticketId = 't-gone';
    buildDispatcher(_FakeProvisioner(() async {}));

    bus.publish(fakeAssigned(ticketId));
    await pumpUntil(() => repo.store.containsKey(ticketId));
    // Nothing should be stored — ticket never existed.
    expect(repo.store, isNot(contains(ticketId)));
    expect(messaging.dispatchedTickets, isEmpty);
  });

  test('skips dispatch when ticket is already terminal', () async {
    const ticketId = 't-done';
    // Pre-insert a done ticket directly (bypass createTicket → auto-assign).
    final now = DateTime.now();
    repo.store[ticketId] = Ticket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Done task',
      status: TicketStatus.done,
      assignedAgentId: agentId,
      channelId: 'chan-1',
      createdAt: now,
      updatedAt: now,
    );

    buildDispatcher(_FakeProvisioner(() async {}));

    bus.publish(fakeAssigned(ticketId));
    await pumpUntil(() => true, tries: 5); // just pump the event loop

    expect(messaging.dispatchedTickets, isEmpty);
  });

  test('skips dispatch when no agent is assigned (null on ticket and event)',
      () async {
    const ticketId = 't-no-agent';
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Unassigned work',
      channelId: 'chan-1',
    );

    await pumpUntil(() => true, tries: 5);
    // Ticket was created but createTicket didn't publish TicketAssigned because
    // assignedAgentId/assignedTeamId are both null. Publish one now without an
    // agent so the null-agent branch is hit.
    bus.publish(TicketAssigned(
      ticketId: ticketId,
      ticketTitle: 'Unassigned work',
      occurredAt: DateTime.now(),
    ));
    await pumpUntil(() => true, tries: 5);

    expect(messaging.dispatchedTickets, isEmpty);
  });

  test('does not dispatch the agent for a user-owned ticket', () async {
    const ticketId = 't-user';
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'User-owned',
      assignedAgentId: TicketCollaborator.userSentinel,
      channelId: 'chan-user',
    );

    await pumpUntil(() => repo.store[ticketId]?.channelId != null);

    // Channel should be attached but no agent dispatch.
    expect(repo.store[ticketId]!.channelId, isNotEmpty);
    expect(messaging.dispatchedTickets, isEmpty);
    // No addAgentToChannel for the user sentinel since isUser=true.
    expect(
      messaging.addedAgentToChannel,
      everyElement(isNot(
        predicate<({String channelId, String agentId})>(
          (e) => e.agentId == TicketCollaborator.userSentinel,
        ),
      )),
    );
  });

  test('fails the ticket when the assigned agent is not ready', () async {
    const ticketId = 't-not-ready';

    // Agent with no adapter — readiness check returns noAdapter.
    final badAgent = Agent(
      id: agentId,
      name: 'Worker',
      title: 'Worker',
      agentMdPath: '/agents/worker.md',
      workspaceId: workspaceId,
      skills: AgentSkills(const ['dart']),
      adapterId: '', // empty → noAdapter readiness
      createdAt: DateTime(2026),
    );

    buildDispatcher(_FakeProvisioner(() async {}), agent: badAgent);

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Doomed',
      assignedAgentId: agentId,
      channelId: 'chan-1',
    );

    await pumpUntil(() => repo.store[ticketId]?.isTerminal ?? false);

    expect(repo.store[ticketId]!.status, TicketStatus.failed);
    expect(repo.store[ticketId]!.errorMessage, isNotNull);
    expect(
      repo.store[ticketId]!.errorMessage!,
      contains('Assigned agent is not ready'),
    );
    expect(messaging.dispatchedTickets, isEmpty);
    // The readiness check fails before tryStart, but failTicket publishes
    // TicketFailed which sets status to failed. The channel should still be
    // attached (it's ensured before readiness check).
    expect(repo.store[ticketId]!.channelId, 'chan-1');
  });

  test('does not dispatch when tryStart returns false (duplicate assignment)',
      () async {
    const ticketId = 't-started';

    // Pre-insert an in-progress ticket — tryStart returns false for it.
    final now = DateTime.now();
    repo.store[ticketId] = Ticket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Already running',
      status: TicketStatus.inProgress,
      assignedAgentId: agentId,
      channelId: 'chan-1',
      createdAt: now,
      updatedAt: now,
    );

    buildDispatcher(_FakeProvisioner(() async {}));

    bus.publish(fakeAssigned(ticketId));
    await pumpUntil(() => true, tries: 5);

    expect(messaging.dispatchedTickets, isEmpty);
    // The ticket should stay inProgress, not fail or change.
    expect(repo.store[ticketId]!.status, TicketStatus.inProgress);
  });

  test('aborts dispatch when ticket becomes terminal during provisioning',
      () async {
    const ticketId = 't-terminal-mid';

    // The provisioner runs; after it returns, cancel the ticket externally
    // so the post-provision re-read sees it as terminal.
    buildDispatcher(_FakeProvisioner(() async {
      await workflow.cancelTicket(ticketId, workspaceId: workspaceId);
    }));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Terminal mid-provision',
      assignedAgentId: agentId,
      channelId: 'chan-1',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );

    await pumpUntil(() => repo.store[ticketId]?.isTerminal ?? false);

    expect(repo.store[ticketId]!.status, TicketStatus.cancelled);
    expect(messaging.dispatchedTickets, isEmpty);
  });

  // ──── dispatch failure recovery ─────────────────────────────────────────

  test('fails the ticket when dispatchAgent throws', () async {
    const ticketId = 't-boom';

    messaging.throwOnDispatch = true;
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Will blow up',
      assignedAgentId: agentId,
      channelId: 'chan-1',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );

    await pumpUntil(() => repo.store[ticketId]?.isTerminal ?? false);

    // Ticket should be failed, not left in_progress.
    expect(repo.store[ticketId]!.status, TicketStatus.failed);
    expect(repo.store[ticketId]!.errorMessage, isNotNull);
    expect(
      repo.store[ticketId]!.errorMessage!,
      contains('Dispatch failed'),
    );
    // No dispatch recorded (it threw before recording).
    expect(messaging.dispatchedTickets, isEmpty);
  });

  // ──── non-pipeline ticket: _buildSeed exercised ─────────────────────────

  test('dispatches a non-pipeline ticket with a generated seed', () async {
    const ticketId = 't-no-pipeline';

    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Review PR #42',
      description: 'Please review the changes in PR #42.',
      priority: TicketPriority.high,
      labels: ['review', 'urgent'],
      assignedAgentId: agentId,
      channelId: 'chan-np',
      delegatedByAgentId: 'delegator-1',
      expectedOutputSchema: {'type': 'object', 'properties': {'approved': {'type': 'bool'}}},
    );

    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);

    expect(messaging.dispatchedTickets, [ticketId]);
    expect(repo.store[ticketId]!.status, TicketStatus.inProgress);
  });

  // This test is intentionally not grouped with the one above — it exercises
  // the no-pipeline, no channel branch of _ensureChannel which calls
  // createGroup and gets channel from there.
  test(
      'dispatches a non-pipeline ticket without a pre-set channel '
      '(creates one)', () async {
    const ticketId = 't-np-no-chan';

    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Standalone task',
      assignedAgentId: agentId,
      // No channelId set — dispatcher creates one via createGroup.
    );

    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);

    expect(messaging.dispatchedTickets, [ticketId]);
    expect(repo.store[ticketId]!.status, TicketStatus.inProgress);
    // The channel should have been created and attached.
    expect(repo.store[ticketId]!.channelId, isNotEmpty);
  });

  // ──── _ensureChannel: existing channel + user ───────────────────────────

  test('reuses existing channel for a user ticket without adding agent',
      () async {
    const ticketId = 't-user-chan';
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'User with existing channel',
      assignedAgentId: TicketCollaborator.userSentinel,
      channelId: 'chan-existing',
    );

    await pumpUntil(() => repo.store[ticketId]?.channelId != null);

    // Channel is already present — should not try to add user to channel.
    expect(repo.store[ticketId]!.channelId, 'chan-existing');
    // No agent dispatch for user tickets.
    expect(messaging.dispatchedTickets, isEmpty);
    // No addAgentToChannel calls for user.
    expect(messaging.addedAgentToChannel, isEmpty);
  });

  // ──── _ensureChannel: agent added to existing channel ───────────────────

  test('adds agent to existing channel when channel already exists', () async {
    const ticketId = 't-agent-chan';
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Agent with existing channel',
      assignedAgentId: agentId,
      channelId: 'chan-existing',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );

    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);

    expect(messaging.dispatchedTickets, [ticketId]);
    // Agent should have been added to the existing channel.
    expect(
      messaging.addedAgentToChannel,
      contains(predicate<({String channelId, String agentId})>(
        (e) => e.channelId == 'chan-existing' && e.agentId == agentId,
      )),
    );
  });

  // ──── _buildSeed ──────────────────────────────────────────────────────

  group('_buildSeed', () {
    test('pipeline ticket dispatches description verbatim', () async {
      const ticketId = 't-seed-pipe';
      buildDispatcher(_FakeProvisioner(() async {}));

      await workflow.createTicket(
        id: ticketId,
        workspaceId: workspaceId,
        title: 'Pipeline Task',
        description: 'Step-specific instructions here.',
        assignedAgentId: agentId,
        channelId: 'chan-seed',
        pipelineRunId: 'run-1',
        pipelineStepId: 'step-1',
      );

      await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    });

    test('non-pipeline seed includes priority when set', () async {
      const ticketId = 't-seed-prio';
      buildDispatcher(_FakeProvisioner(() async {}));

      await workflow.createTicket(
        id: ticketId,
        workspaceId: workspaceId,
        title: 'Priority task',
        description: 'Urgent work needed.',
        assignedAgentId: agentId,
        channelId: 'chan-seed-p',
        priority: TicketPriority.urgent,
      );

      await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    });

    test('non-pipeline seed includes labels when present', () async {
      const ticketId = 't-seed-lbl';
      buildDispatcher(_FakeProvisioner(() async {}));

      await workflow.createTicket(
        id: ticketId,
        workspaceId: workspaceId,
        title: 'Labeled task',
        assignedAgentId: agentId,
        channelId: 'chan-seed-l',
        labels: ['frontend', 'bugfix'],
      );

      await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    });

    test('non-pipeline seed includes expected output schema', () async {
      const ticketId = 't-seed-schema';
      buildDispatcher(_FakeProvisioner(() async {}));

      await workflow.createTicket(
        id: ticketId,
        workspaceId: workspaceId,
        title: 'Schema task',
        assignedAgentId: agentId,
        channelId: 'chan-seed-s',
        expectedOutputSchema: {
          'type': 'object',
          'properties': {'result': {'type': 'string'}},
        },
      );

      await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    });

    test('non-pipeline seed includes delegatedBy info', () async {
      const ticketId = 't-seed-del';
      buildDispatcher(_FakeProvisioner(() async {}));

      await workflow.createTicket(
        id: ticketId,
        workspaceId: workspaceId,
        title: 'Delegated work',
        assignedAgentId: agentId,
        channelId: 'chan-seed-d',
        delegatedByAgentId: 'delegator-99',
      );

      await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    });
  });

  // ──── _ensureChannel: pipeline channel reuse ──────────────────────────

  test('sibling tickets in same pipeline run share one channel', () async {
    const ticketA = 't-pipe-a';
    const ticketB = 't-pipe-b';

    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketA,
      workspaceId: workspaceId,
      title: 'Pipeline ticket A',
      assignedAgentId: agentId,
      pipelineRunId: 'run-shared',
      pipelineStepId: 'step-1',
    );
    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    final channelA = repo.store[ticketA]!.channelId!;

    await workflow.createTicket(
      id: ticketB,
      workspaceId: workspaceId,
      title: 'Pipeline ticket B',
      assignedAgentId: agentId,
      pipelineRunId: 'run-shared',
      pipelineStepId: 'step-2',
    );
    await pumpUntil(
        () => messaging.dispatchedTickets.where((t) => t == ticketB).isNotEmpty);

    expect(repo.store[ticketB]!.channelId, channelA);
  });

  // ──── re-dispatch guard ───────────────────────────────────────────────

  test('second TicketAssigned for already-started ticket does not dispatch',
      () async {
    const ticketId = 't-dup';
    buildDispatcher(_FakeProvisioner(() async {}));

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Already running',
      assignedAgentId: agentId,
      channelId: 'chan-dup',
      pipelineRunId: 'run-1',
      pipelineStepId: 'step-1',
    );
    await pumpUntil(() => messaging.dispatchedTickets.isNotEmpty);
    final dispatchCount = messaging.dispatchedTickets.length;

    bus.publish(fakeAssigned(ticketId));
    await pumpUntil(() => true, tries: 10);

    expect(messaging.dispatchedTickets.length, dispatchCount);
  });

  // ──── dispose ─────────────────────────────────────────────────────────

  test('dispose stops listening for TicketAssigned events', () async {
    const ticketId = 't-post-dispose';

    final provisioner = _FakeProvisioner(() async {});
    final dispatcher = TicketDispatcher(
      eventBus: bus,
      ticketRepository: repo,
      ticketWorkflow: workflow,
      messagingPort: messaging,
      readinessChecker: AgentReadinessChecker(
        agentRepository: _FakeAgentRepo(agent: readyAgent()),
      ),
      repoProvisioner: provisioner,
    );
    dispatcher.start();
    dispatcher.dispose();

    await workflow.createTicket(
      id: ticketId,
      workspaceId: workspaceId,
      title: 'Post-dispose',
      assignedAgentId: agentId,
      channelId: 'chan-post',
    );
    await pumpUntil(() => true, tries: 10);

    expect(messaging.dispatchedTickets, isEmpty);
  });
}

