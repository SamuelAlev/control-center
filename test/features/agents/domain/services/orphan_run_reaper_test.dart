import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/process_control_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/agents/domain/services/orphan_run_reaper.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

class _FakeProcessControl implements ProcessControlPort {
  _FakeProcessControl(this._alivePids);
  final Set<int> _alivePids;

  @override
  bool isPidAlive(int pid) => _alivePids.contains(pid);

  @override
  Future<void> kill(int pid) async => _alivePids.remove(pid);
}

class _FakeTicketWorkflow implements TicketWorkflowService {
  final List<String> failedTicketIds = [];

  @override
  Future<void> failTicket(
    String ticketId,
    String errorMessage, {
    required String workspaceId,
    bool force = false,
  }) async {
    failedTicketIds.add(ticketId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeTicketRepository implements TicketRepository {
  final Map<String, Ticket> _tickets = {};

  void seed(Ticket t) => _tickets[t.id] = t;

  @override
  Future<Ticket?> getById(String workspaceId, String id) async => _tickets[id];

  @override
  Future<void> insert(Ticket ticket) async => _tickets[ticket.id] = ticket;

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async =>
      _tickets[ticket.id] = ticket;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRunLogRepoForBudget implements AgentRunLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => const [];
  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => const [];
  @override
  Stream<List<AgentRunLog>> watchByAgent(
    String workspaceId,
    String agentId,
  ) async* {
    yield [];
  }

  @override
  Future<List<AgentRunLog>> nonTerminal() async => [];

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) => Stream.value([]);

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchBySpace(
    String workspaceId,
    String conversationId,
  ) => const Stream.empty();

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String w,
    String c,
  ) async* {
    yield [];
  }

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(String w, String c) async* {
    yield [];
  }

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async => null;
  @override
  Future<void> upsert(AgentRunLog log) async {}
}

class _FakeAgentRepoForBudget implements AgentRepository {
  @override
  Stream<List<Agent>> watchAll() async* {
    yield [];
  }

  @override
  Stream<List<Agent>> watchByWorkspace(String w) async* {
    yield [];
  }

  @override
  Future<Agent?> getById(String workspaceId, String id) async => null;
  @override
  Future<Agent?> findByWorkspaceAndName(String w, String n) async => null;
  @override
  Future<void> upsert(Agent agent) async {}
  @override
  Future<void> delete(String workspaceId, String id) async {}
}

class _FakeEventBusForBudget extends DomainEventBus {}

class _FakeBudgetEnforcement extends BudgetEnforcementService {
  _FakeBudgetEnforcement({this.block})
    : super(
        agentRunLogRepository: _FakeRunLogRepoForBudget(),
        agentRepository: _FakeAgentRepoForBudget(),
        eventBus: _FakeEventBusForBudget(),
      );
  final BudgetBlock? block;
  bool checked = false;

  @override
  Future<BudgetBlock?> checkInvocationBlock({
    required String agentId,
    required String workspaceId,
    String? ticketId,
  }) async {
    checked = true;
    return block;
  }
}

/// Serves a scan snapshot taken before the runs finished on their own.
class _StaleScanRunLogs extends FakeAgentRunLogRepository {
  _StaleScanRunLogs(this._snapshot);
  final List<AgentRunLog> _snapshot;

  @override
  Future<List<AgentRunLog>> nonTerminal() async => _snapshot;
}

AgentRunLog _makeRun({
  String id = 'run-1',
  RunStatus status = RunStatus.running,
  int? pid,
  String? ticketId,
  String agentId = 'agent-1',
  int retryAttempt = 0,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: 'ws-1',
  ticketId: ticketId,
  startedAt: DateTime(2025, 6, 1),
  status: status,
  pid: pid,
  retry: RetryMeta(attempt: retryAttempt),
);

/// When the server under test started: every seeded run is older.
final _bootedAt = DateTime(2026, 7, 1);

Ticket _makeTicket({
  String id = 'ticket-1',
  TicketStatus status = TicketStatus.inProgress,
}) => Ticket(
  id: id,
  workspaceId: 'ws-1',
  title: 'Test Ticket',
  status: status,
  createdAt: DateTime(2025, 6, 1),
  updatedAt: DateTime(2025, 6, 1),
);

void main() {
  group('OrphanRunReaper', () {
    late FakeAgentRunLogRepository runLogRepo;
    late _FakeTicketRepository ticketRepo;
    late _FakeTicketWorkflow ticketWorkflow;
    late _FakeProcessControl processControl;
    late OrphanRunReaper reaper;

    setUp(() {
      runLogRepo = FakeAgentRunLogRepository();
      ticketRepo = _FakeTicketRepository();
      ticketWorkflow = _FakeTicketWorkflow();
      processControl = _FakeProcessControl({});
      reaper = OrphanRunReaper(
        runLogRepo: runLogRepo,
        ticketRepo: ticketRepo,
        ticketWorkflow: ticketWorkflow,
        processControl: processControl,
        eventBus: null,
        startedBefore: _bootedAt,
      );
    });

    test(
      'does nothing when no active runs exist',
      timeout: const Timeout.factor(2),
      () async {
        await reaper.reap();
        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test('never reaps a run this process started, whatever its pid says',
        () async {
      // A goal segment or pipeline step boot recovery just dispatched: its
      // harness row has no pid, and it is no orphan.
      final own = _makeRun(
        id: 'run-own',
        pid: null,
      ).copyWith(startedAt: _bootedAt.add(const Duration(seconds: 1)));
      runLogRepo.seed(own);

      await reaper.reap();

      final row = await runLogRepo.getById('ws-1', 'run-own');
      expect(row!.status, RunStatus.running);
      expect(row.completedAt, isNull);
    });

    test(
      'marks run failed when pid is null',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'run-null-pid', pid: null, ticketId: 't-1');
        runLogRepo.seed(run);
        ticketRepo.seed(_makeTicket(id: 't-1'));

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'run-null-pid');
        expect(updated, isNotNull);
        expect(updated!.status, RunStatus.error);
        expect(updated.errorFamily, RunErrorFamily.processLost);
        expect(updated.liveness, RunLiveness.dead);
      },
    );

    test(
      'a reaped run is announced once as serverStopped, for the person its '
      'row names',
      timeout: const Timeout.factor(2),
      () async {
        final bus = DomainEventBus();
        addTearDown(bus.dispose);
        final settled = <AgentRunSettled>[];
        bus.on<AgentRunSettled>().listen(settled.add);
        reaper = OrphanRunReaper(
          runLogRepo: runLogRepo,
          ticketRepo: ticketRepo,
          ticketWorkflow: ticketWorkflow,
          processControl: processControl,
          eventBus: bus,
          startedBefore: _bootedAt,
        );
        // The requester was recorded on the row at dispatch, before the
        // restart; nothing in memory knows it any more.
        runLogRepo
          ..seed(
            _makeRun(
              id: 'r-reaped',
              pid: null,
            ).copyWith(requestedByUserId: 'olga'),
          )
          ..seed(_makeRun(id: 'r-bot', pid: null));

        await reaper.reap();
        await reaper.reap();
        await Future<void>.delayed(Duration.zero);

        expect(settled, hasLength(2));
        final byRun = {for (final e in settled) e.runId: e};
        final reaped = byRun['r-reaped']!;
        expect(reaped.status, RunStatus.error);
        expect(reaped.endReason, RunEndReason.serverStopped);
        expect(reaped.requestedByUserId, 'olga');
        expect(byRun['r-bot']!.requestedByUserId, isNull);
        final row = await runLogRepo.getById('ws-1', 'r-reaped');
        expect(row!.endReason, RunEndReason.serverStopped);
        expect(row.requestedByUserId, 'olga');
      },
    );

    test(
      'fails backing ticket when pid is null',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r1', pid: null, ticketId: 't-1');
        runLogRepo.seed(run);
        ticketRepo.seed(_makeTicket(id: 't-1'));

        await reaper.reap();

        expect(ticketWorkflow.failedTicketIds, contains('t-1'));
      },
    );

    test(
      'marks run failed when process is not alive',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r2', pid: 12345);
        runLogRepo.seed(run);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r2');
        expect(updated!.status, RunStatus.error);
        expect(updated.errorFamily, RunErrorFamily.processLost);
      },
    );

    test(
      'does not mark failed when process is alive',
      timeout: const Timeout.factor(2),
      () async {
        processControl = _FakeProcessControl({99999});
        reaper = OrphanRunReaper(
          runLogRepo: runLogRepo,
          ticketRepo: ticketRepo,
          ticketWorkflow: ticketWorkflow,
          processControl: processControl,
          eventBus: null,
          startedBefore: _bootedAt,
        );

        final run = _makeRun(id: 'r3', pid: 99999);
        runLogRepo.seed(run);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r3');
        expect(updated!.status, RunStatus.running);
      },
    );

    test(
      'skips failing ticket when ticket is null',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r4', pid: null, ticketId: 't-missing');
        runLogRepo.seed(run);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r4');
        expect(updated!.status, RunStatus.error);
        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test(
      'skips failing ticket when ticket is terminal',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r5', pid: null, ticketId: 't-done');
        runLogRepo.seed(run);
        ticketRepo.seed(_makeTicket(id: 't-done', status: TicketStatus.done));

        await reaper.reap();

        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test(
      'skips failing ticket when ticketId is empty',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r6', pid: null, ticketId: '');
        runLogRepo.seed(run);

        await reaper.reap();

        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test(
      'handles multiple active runs',
      timeout: const Timeout.factor(2),
      () async {
        final run1 = _makeRun(id: 'r-a', pid: null, ticketId: 't-a');
        final run2 = _makeRun(id: 'r-b', pid: null, ticketId: 't-b');
        runLogRepo.seed(run1);
        runLogRepo.seed(run2);
        ticketRepo.seed(_makeTicket(id: 't-a'));
        ticketRepo.seed(_makeTicket(id: 't-b'));

        await reaper.reap();

        expect(ticketWorkflow.failedTicketIds, containsAll(['t-a', 't-b']));
      },
    );

    test(
      'leaves a run that finished after the scan untouched',
      timeout: const Timeout.factor(2),
      () async {
        final scanned = _makeRun(id: 'r-raced', pid: null, ticketId: 't-r');
        final repo = _StaleScanRunLogs([scanned]);
        final finishedAt = DateTime(2025, 6, 1, 0, 5);
        repo.seed(
          scanned.copyWith(
            status: RunStatus.completed,
            completedAt: finishedAt,
            summary: 'done',
          ),
        );
        ticketRepo.seed(_makeTicket(id: 't-r'));
        reaper = OrphanRunReaper(
          runLogRepo: repo,
          ticketRepo: ticketRepo,
          ticketWorkflow: ticketWorkflow,
          processControl: processControl,
          eventBus: null,
          startedBefore: _bootedAt,
        );

        await reaper.reap();

        final stored = await repo.getById('ws-1', 'r-raced');
        expect(stored!.status, RunStatus.completed);
        expect(stored.summary, 'done');
        expect(stored.completedAt, finishedAt);
        expect(stored.errorFamily, isNull);
        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test(
      'ignores non-running runs',
      timeout: const Timeout.factor(2),
      () async {
        final completedRun = _makeRun(
          id: 'r-completed',
          status: RunStatus.completed,
          pid: null,
        );
        runLogRepo.seed(completedRun);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r-completed');
        expect(updated!.status, RunStatus.completed);
      },
    );

    group('with budget enforcement', () {
      test(
        'recovery is skipped when budget blocks it',
        timeout: const Timeout.factor(2),
        () async {
          final budget = _FakeBudgetEnforcement(
            block: const BudgetBlock(
              reason: 'budget_exhausted',
              scopeType: 'agent',
              scopeId: 'agent-1',
            ),
          );
          reaper = OrphanRunReaper(
            runLogRepo: runLogRepo,
            ticketRepo: ticketRepo,
            ticketWorkflow: ticketWorkflow,
            processControl: processControl,
            eventBus: null,
            startedBefore: _bootedAt,
            budgetEnforcement: budget,
          );

          final run = _makeRun(id: 'r-budget', pid: 11111, retryAttempt: 0);
          runLogRepo.seed(run);

          await reaper.reap();

          final updated = await runLogRepo.getById('ws-1', 'r-budget');
          expect(updated!.status, RunStatus.error);
          expect(budget.checked, isTrue);
        },
      );

      test(
        'recovery proceeds when budget allows (block is null)',
        timeout: const Timeout.factor(2),
        () async {
          final budget = _FakeBudgetEnforcement(block: null);
          reaper = OrphanRunReaper(
            runLogRepo: runLogRepo,
            ticketRepo: ticketRepo,
            ticketWorkflow: ticketWorkflow,
            processControl: processControl,
            eventBus: null,
            startedBefore: _bootedAt,
            budgetEnforcement: budget,
          );

          final run = _makeRun(id: 'r-allow', pid: 11111, retryAttempt: 0);
          runLogRepo.seed(run);

          await reaper.reap();

          final updated = await runLogRepo.getById('ws-1', 'r-allow');
          expect(updated!.status, RunStatus.error);
          expect(budget.checked, isTrue);
        },
      );
    });

    test(
      'recovery skipped when retry count exceeds max',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(id: 'r-max-retry', pid: 11111, retryAttempt: 3);
        runLogRepo.seed(run);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r-max-retry');
        expect(updated!.status, RunStatus.error);
      },
    );

    test(
      'skips failing ticket when ticket not in repository',
      timeout: const Timeout.factor(2),
      () async {
        final run = _makeRun(
          id: 'r-no-ticket',
          pid: null,
          ticketId: 't-non-existent',
        );
        runLogRepo.seed(run);

        await reaper.reap();

        final updated = await runLogRepo.getById('ws-1', 'r-no-ticket');
        expect(updated!.status, RunStatus.error);
        expect(ticketWorkflow.failedTicketIds, isEmpty);
      },
    );

    test(
      'handles mix of dead and alive processes',
      timeout: const Timeout.factor(2),
      () async {
        processControl = _FakeProcessControl({88888});
        reaper = OrphanRunReaper(
          runLogRepo: runLogRepo,
          ticketRepo: ticketRepo,
          ticketWorkflow: ticketWorkflow,
          processControl: processControl,
          eventBus: null,
          startedBefore: _bootedAt,
        );

        final aliveRun = _makeRun(id: 'r-alive', pid: 88888);
        final deadRun = _makeRun(id: 'r-dead', pid: 99999);
        runLogRepo.seed(aliveRun);
        runLogRepo.seed(deadRun);

        await reaper.reap();

        final alive = await runLogRepo.getById('ws-1', 'r-alive');
        expect(alive!.status, RunStatus.running);

        final dead = await runLogRepo.getById('ws-1', 'r-dead');
        expect(dead!.status, RunStatus.error);
      },
    );
  });
}
