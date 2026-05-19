import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/retry_meta.dart';
import 'package:control_center/features/agents/domain/services/budget_policy_service.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/stranded_ticket_reconciler.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeTicketRepository implements TicketRepository {
  final Map<String, Ticket> _store = {};

  final Set<String> _throwForAgents = {};
  set throwForAgents(Set<String> value) {
    _throwForAgents
      ..clear()
      ..addAll(value);
  }

  /// If set, `forAgent` returns this ticket for *every* agent.
  Ticket? _duplicateTicket;
  set duplicateTicket(Ticket? t) => _duplicateTicket = t;

  void _put(Ticket t) {
    _store[t.id] = t;
  }

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async {
    if (_throwForAgents.contains(agentId)) {
      throw Exception('Simulated failure for $agentId');
    }
    if (_duplicateTicket != null) {
      return [_duplicateTicket!];
    }
    return _store.values
        .where((t) =>
            t.workspaceId == workspaceId && t.assignedAgentId == agentId)
        .toList();
  }

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {
    _store[ticket.id] = ticket;
  }

  @override
  Future<void> insert(Ticket ticket) async {
    _store[ticket.id] = ticket;
  }

  @override
  Future<void> upsertMirror(Ticket ticket) async {
    _store[ticket.id] = ticket;
  }

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {
    _store.remove(ticketId);
  }

  @override
  Future<Ticket?> getById(String id) async => _store[id];

  @override
  Future<Ticket?> getByExternal(
          TicketProvider provider, String externalKey) async =>
      null;

  @override
  Future<List<Ticket>> forPipelineRun(
          String workspaceId, String pipelineRunId) async =>
      [];

  @override
  Future<List<Ticket>> forPipelineStep(
          String workspaceId,
          String pipelineRunId,
          String pipelineStepId) async =>
      [];

  @override
  Future<List<Ticket>> childrenOf(
          String workspaceId, String parentTicketId) async =>
      [];

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      Stream.value([]);

  @override
  Stream<List<Ticket>> watchByStatus(
          String workspaceId, TicketStatus status) =>
      Stream.value([]);

  @override
  Stream<List<Ticket>> watchByAssignee(
          String workspaceId, String agentId) =>
      Stream.value([]);

  @override
  Stream<List<Ticket>> watchForPipelineRun(
          String workspaceId, String pipelineRunId) =>
      Stream.value([]);

  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) async {}

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) async {}

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      Stream.value([]);

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) async =>
      [];
}

class FakeAgentRepository implements AgentRepository {

  FakeAgentRepository(this._agents);
  final List<Agent> _agents;

  @override
  Stream<List<Agent>> watchAll() => Stream.value(List.unmodifiable(_agents));

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(_agents.where((a) => a.workspaceId == workspaceId).toList());

  @override
  Future<Agent?> getById(String id) async =>
      _agents.cast<Agent?>().firstWhere((a) => a!.id == id, orElse: () => null);

  @override
  Future<Agent?> findByWorkspaceAndName(
          String workspaceId, String name) async =>
      null;

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String id) async {}
}

class FakeAgentRunLogRepository implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async => null;


  FakeAgentRunLogRepository(this._logs);
  final List<AgentRunLog> _logs;

  @override
  Stream<List<AgentRunLog>> watchAll() =>
      Stream.value(List.unmodifiable(_logs));

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      Stream.value(_logs.where((l) => l.agentId == agentId).toList());

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
          String workspaceId, String conversationId) =>
      Stream.value([]);

  @override
  Future<AgentRunLog?> getById(String id) async => null;

  @override
  Future<void> upsert(AgentRunLog log) async {}
}

class _FakeTicketWorkflowService extends TicketWorkflowService {
  _FakeTicketWorkflowService()
      : super(
          repository: FakeTicketRepository(),
          eventBus: DomainEventBus(),
        );

  final List<_TransitionCall> transitionCalls = [];

  @override
  Future<void> transitionStatus(
    String ticketId,
    TicketStatus target, {
    required String workspaceId,
    bool force = false,
  }) async {
    transitionCalls.add(_TransitionCall(ticketId, target, workspaceId, force: force));
  }

  void reset() => transitionCalls.clear();
}

class _TransitionCall {
  const _TransitionCall(
      this.ticketId, this.target, this.workspaceId, {required this.force});
  final String ticketId;
  final TicketStatus target;
  final String workspaceId;
  final bool force;
}

class FakeBudgetEnforcementService extends BudgetEnforcementService {

  FakeBudgetEnforcementService()
      : super(
          agentRunLogRepository: FakeAgentRunLogRepository([]),
          agentRepository: FakeAgentRepository([]),
          eventBus: DomainEventBus(),
        );
  BudgetBlock? _nextBlock;
  Object? _nextError;

  void setReturn(BudgetBlock? block) {
    _nextBlock = block;
    _nextError = null;
  }

  void setError(Object error) {
    _nextError = error;
    _nextBlock = null;
  }

  @override
  Future<BudgetBlock?> checkInvocationBlock({
    required String agentId,
    required String workspaceId,
    String? ticketId,
  }) async {
    if (_nextError != null) {
      throw _nextError!;
    }
    return _nextBlock;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 6, 10, 12, 0);

Ticket makeTicket({
  required String id,
  required String workspaceId,
  required String agentId,
  TicketStatus status = TicketStatus.inProgress,
}) =>
    Ticket(
      id: id,
      workspaceId: workspaceId,
      title: 'Test ticket $id',
      status: status,
      assignedAgentId: agentId,
      createdAt: _now,
      updatedAt: _now,
    );

Agent makeAgent({
  required String id,
  required String workspaceId,
  String name = 'test-agent',
}) =>
    Agent(
      id: id,
      name: name,
      title: 'Test Agent',
      agentMdPath: '/fake/agent.md',
      workspaceId: workspaceId,
      skills: AgentSkills(const []),
      createdAt: _now,
    );

AgentRunLog makeRunLog({
  required String id,
  required String agentId,
  required String ticketId,
  RunStatus status = RunStatus.error,
  int retryAttempt = 0,
  String? parentRunId,
  String? workspaceId,
  DateTime? startedAt,
  RunErrorFamily? errorFamily,
}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      ticketId: ticketId,
      workspaceId: workspaceId,
      status: status,
      retry: RetryMeta(attempt: retryAttempt, parentRunId: parentRunId),
      startedAt: startedAt ?? _now,
      errorFamily: errorFamily,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const ws = 'ws-1';
  const agentId = 'agent-1';

  group('StrandedTicketReconciler.reconcile', () {
    test('skips terminal tickets', () async {
      final ticketRepo = FakeTicketRepository();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final terminalTicket = makeTicket(
          id: 't-done',
          workspaceId: ws,
          agentId: agentId,
          status: TicketStatus.done);
      final cancelledTicket = makeTicket(
          id: 't-cancelled',
          workspaceId: ws,
          agentId: agentId,
          status: TicketStatus.cancelled);
      final failedTicket = makeTicket(
          id: 't-failed',
          workspaceId: ws,
          agentId: agentId,
          status: TicketStatus.failed);

      ticketRepo._put(terminalTicket);
      ticketRepo._put(cancelledTicket);
      ticketRepo._put(failedTicket);

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();

      expect(await ticketRepo.getById('t-done'), same(terminalTicket));
      expect(await ticketRepo.getById('t-cancelled'), same(cancelledTicket));
      expect(await ticketRepo.getById('t-failed'), same(failedTicket));
    }, timeout: const Timeout.factor(2));

    test('does not process tickets whose assigned agent is not in the system',
        () async {
      // The reconciler only fetches tickets via forAgent for agents in the
      // agent list. A ticket assigned to an agent that has been removed is
      // never seen — it is not re-dispatched or escalated.
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();

      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: 'deleted-agent');
      ticketRepo._put(ticket);

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([makeAgent(id: agentId, workspaceId: ws)]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: workflow,
      );

      await sut.reconcile();

      expect(workflow.transitionCalls, isEmpty);
      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.inProgress);
    }, timeout: const Timeout.factor(2));

    test('re-dispatches (sets status to open) when ticket has no runs',
        () async {
      final ticketRepo = FakeTicketRepository();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();

      final updated = await ticketRepo.getById('t-1');
      expect(updated!.status, TicketStatus.open);
    }, timeout: const Timeout.factor(2));

    test(
        'handles failed run with retries < max — re-dispatches '
        '(sets status to open)', () async {
      final ticketRepo = FakeTicketRepository();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 1,
      );

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();

      final updated = await ticketRepo.getById('t-1');
      expect(updated!.status, TicketStatus.open);
    }, timeout: const Timeout.factor(2));

    test('escalates to blocked when retries exhausted on failed run',
        () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 3,
      );

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
      );

      await sut.reconcile();

      expect(workflow.transitionCalls, hasLength(1));
      final call = workflow.transitionCalls.first;
      expect(call.ticketId, 't-1');
      expect(call.target, TicketStatus.blocked);
    }, timeout: const Timeout.factor(2));

    test('escalates when in-progress run has exhausted retries', () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final agent = makeAgent(id: agentId, workspaceId: ws);

      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.running,
        retryAttempt: 5,
      );

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
      );

      await sut.reconcile();

      expect(workflow.transitionCalls, hasLength(1));
      final call = workflow.transitionCalls.first;
      expect(call.ticketId, 't-1');
      expect(call.target, TicketStatus.blocked);
    }, timeout: const Timeout.factor(2));

    test(
        'in-progress run with retries < max does nothing '
        '(does not touch ticket)', () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final agent = makeAgent(id: agentId, workspaceId: ws);

      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.running,
        retryAttempt: 1,
      );

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
      );

      await sut.reconcile();

      expect(workflow.transitionCalls, isEmpty);
      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.inProgress);
    }, timeout: const Timeout.factor(2));

    test(
        'budget block prevents re-dispatch and escalates to blocked '
        'instead', () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final budget = FakeBudgetEnforcementService();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 0,
      );

      budget.setReturn(const BudgetBlock(reason: 'budget_exhausted'));

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
        budgetEnforcement: budget,
      );

      await sut.reconcile();

      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.inProgress);
      expect(workflow.transitionCalls, hasLength(1));
      final call = workflow.transitionCalls.first;
      expect(call.ticketId, 't-1');
      expect(call.target, TicketStatus.blocked);
    }, timeout: const Timeout.factor(2));

    test(
        'budget check returning null allows re-dispatch '
        '(status set to open)', () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final budget = FakeBudgetEnforcementService();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 0,
      );

      budget.setReturn(null);

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
        budgetEnforcement: budget,
      );

      await sut.reconcile();

      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.open);
      expect(workflow.transitionCalls, isEmpty);
    }, timeout: const Timeout.factor(2));

    test(
        'budget check error does not escalate or re-dispatch '
        '(no-op on that ticket)', () async {
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final budget = FakeBudgetEnforcementService();
      final agent = makeAgent(id: agentId, workspaceId: ws);
      final ticket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: agentId);
      ticketRepo._put(ticket);

      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 0,
      );

      budget.setError(Exception('DB down'));

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
        budgetEnforcement: budget,
      );

      await sut.reconcile();

      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.inProgress);
      expect(workflow.transitionCalls, isEmpty);
    }, timeout: const Timeout.factor(2));

    test(
        'errors in per-agent processing do not crash the whole reconcile',
        () async {
      final ticketRepo = FakeTicketRepository();
      final agent1 = makeAgent(id: 'agent-1', workspaceId: ws);
      final agent2 = makeAgent(id: 'agent-2', workspaceId: ws);

      final ticket1 =
          makeTicket(id: 't-1', workspaceId: ws, agentId: 'agent-1');
      ticketRepo._put(ticket1);

      final ticket2 =
          makeTicket(id: 't-2', workspaceId: ws, agentId: 'agent-2');
      ticketRepo._put(ticket2);

      ticketRepo.throwForAgents = {'agent-1'};

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent1, agent2]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();

      final stored2 = await ticketRepo.getById('t-2');
      expect(stored2!.status, TicketStatus.open);
      final stored1 = await ticketRepo.getById('t-1');
      expect(stored1!.status, TicketStatus.inProgress);
    }, timeout: const Timeout.factor(2));

    test('skips duplicate tickets across agents', () async {
      final ticketRepo = FakeTicketRepository();
      final agent1 = makeAgent(id: 'agent-1', workspaceId: ws);
      final agent2 = makeAgent(id: 'agent-2', workspaceId: ws);

      final sharedTicket =
          makeTicket(id: 't-1', workspaceId: ws, agentId: 'agent-1');
      ticketRepo._put(sharedTicket);
      ticketRepo.duplicateTicket = sharedTicket;

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent1, agent2]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();

      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.open);
    }, timeout: const Timeout.factor(2));

    test(
        'does not escalate when canTransitionTo(blocked) '
        'returns false (ticket is backlog)', () async {
      // backlog cannot transition to blocked. The ticket is assigned to an
      // existing agent with exhausted error runs — the reconciler reaches
      // _escalateToBlocked, which checks canTransitionTo and skips the
      // transition when it returns false.
      final ticketRepo = FakeTicketRepository();
      final workflow = _FakeTicketWorkflowService();
      final agent = makeAgent(id: agentId, workspaceId: ws);

      final backlogTicket = makeTicket(
        id: 't-1',
        workspaceId: ws,
        agentId: agentId,
        status: TicketStatus.backlog,
      );
      ticketRepo._put(backlogTicket);

      // Exhausted error run so _escalateToBlocked is reached.
      final runLog = makeRunLog(
        id: 'run-1',
        agentId: agentId,
        ticketId: 't-1',
        status: RunStatus.error,
        retryAttempt: 3,
      );

      final sut = StrandedTicketReconciler(
        ticketRepo: ticketRepo,
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([runLog]),
        ticketWorkflow: workflow,
      );

      await sut.reconcile();

      expect(workflow.transitionCalls, isEmpty);
      final stored = await ticketRepo.getById('t-1');
      expect(stored!.status, TicketStatus.backlog);
    }, timeout: const Timeout.factor(2));

    test('reconcile with no agents completes without error', () async {
      final sut = StrandedTicketReconciler(
        ticketRepo: FakeTicketRepository(),
        agentRepo: FakeAgentRepository([]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();
    }, timeout: const Timeout.factor(2));

    test('reconcile with no tickets for any agent completes without error',
        () async {
      final agent = makeAgent(id: agentId, workspaceId: ws);

      final sut = StrandedTicketReconciler(
        ticketRepo: FakeTicketRepository(),
        agentRepo: FakeAgentRepository([agent]),
        runLogRepo: FakeAgentRunLogRepository([]),
        ticketWorkflow: _FakeTicketWorkflowService(),
      );

      await sut.reconcile();
    }, timeout: const Timeout.factor(2));
  });
}
