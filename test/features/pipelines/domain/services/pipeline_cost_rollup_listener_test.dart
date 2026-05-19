import 'dart:async';

import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:test/test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────

class FakeTicketRepository implements TicketRepository {

  FakeTicketRepository(this.tickets, {this.throwOnForAgent = false});
  final List<Ticket> tickets;
  final bool throwOnForAgent;

  @override
  Future<List<Ticket>> forAgent(
    String workspaceId,
    String agentId,
  ) async {
    if (throwOnForAgent) {
      throw Exception('simulated repository error');
    }
    return tickets
        .where(
          (t) =>
              t.workspaceId == workspaceId &&
              t.assignedAgentId == agentId,
        )
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePipelineRunRepository implements PipelineRunRepository {
  final Map<String, List<int>> costIncrements = {};

  @override
  Future<void> incrementCost(String runId, int cents, int tokens) async {
    costIncrements[runId] = [cents, tokens];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Helpers ──────────────────────────────────────────────────────────────

Ticket _ticket({
  required String id,
  String workspaceId = 'ws-1',
  String? agentId,
  String? pipelineRunId,
}) =>
    Ticket(
      id: id,
      workspaceId: workspaceId,
      title: 'Test',
      status: TicketStatus.open,
      assignedAgentId: agentId,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

AgentRunLog _log({
  required String id,
  String agentId = 'agent-1',
  int costCents = 100,
  int tokens = 500,
}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      workspaceId: 'ws-1',
      status: RunStatus.completed,
      startedAt: DateTime(2026),
      completedAt: DateTime(2026),
      cost: RunCost(estimatedCostCents: costCents, inputTokens: tokens),
    );

AgentRunCompleted _event({
  String agentId = 'agent-1',
  String? workspaceId = 'ws-1',
}) =>
    AgentRunCompleted(
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: 'conv-1',
      occurredAt: DateTime(2026),
    );

void main() {
  group('PipelineCostRollupListener', () {
    late DomainEventBus eventBus;
    late FakeAgentRunLogRepository logRepo;
    late FakeTicketRepository ticketRepo;
    late FakePipelineRunRepository runRepo;

    setUp(() {
      eventBus = DomainEventBus();
      logRepo = FakeAgentRunLogRepository();
      ticketRepo = FakeTicketRepository([]);
      runRepo = FakePipelineRunRepository();
    });

    PipelineCostRollupListener listener0() => PipelineCostRollupListener(
          eventBus: eventBus,
          ticketRepository: ticketRepo,
          runLogRepository: logRepo,
          runRepository: runRepo,
        );

    test('start() subscribes to event bus', () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      // Give async handler time to run.
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isNotEmpty);
      expect(runRepo.costIncrements['pr-1'], [100, 500]);
    });

    test(
        'AgentRunCompleted with workspaceId and matching tickets increments costs',
        () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1', costCents: 200, tokens: 1000));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements['pr-1'], [200, 1000]);
    });

    test('AgentRunCompleted with null workspaceId skips (no fan-out)',
        () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event(workspaceId: null));

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('AgentRunCompleted with no pipeline-tracked tickets skips', () async {
      // Ticket exists but has no pipelineRunId.
      ticketRepo = FakeTicketRepository([
        _ticket(id: 't-1', agentId: 'agent-1'),
      ]);
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('AgentRunCompleted with multiple pipeline runs increments each',
        () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
        _ticket(
          id: 't-2',
          agentId: 'agent-1',
          pipelineRunId: 'pr-2',
        ),
        // Duplicate runId — should be deduped via .toSet().
        _ticket(
          id: 't-3',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1', costCents: 50, tokens: 100));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      // Two unique runs, each incremented.
      expect(runRepo.costIncrements.length, 2);
      expect(runRepo.costIncrements['pr-1'], [50, 100]);
      expect(runRepo.costIncrements['pr-2'], [50, 100]);
    });

    test('Uses most recent completed log\'s cost', () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(
        _log(id: 'log-old', costCents: 10, tokens: 50).copyWith(
          completedAt: DateTime(2026, 1, 1),
        ),
      );
      logRepo.seed(
        _log(id: 'log-recent', costCents: 999, tokens: 888).copyWith(
          completedAt: DateTime(2026, 6, 1),
        ),
      );

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      // Should use log-recent's cost (most recent completedAt).
      expect(runRepo.costIncrements['pr-1'], [999, 888]);
    });

    test('Zero cost + zero tokens skips increment', () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1', costCents: 0, tokens: 0));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('Missing completed log skips', () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      // No logs seeded at all.

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('Non-AgentRunCompleted events are ignored', () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1'));
      final listener = listener0();
      listener.start();

      // Publish a DomainEvent that is NOT AgentRunCompleted.
      eventBus.publish(const _OtherEvent());

      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('dispose() unsubscribes (events after dispose not processed)',
        () async {
      ticketRepo = FakeTicketRepository([
        _ticket(
          id: 't-1',
          agentId: 'agent-1',
          pipelineRunId: 'pr-1',
        ),
      ]);
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      // Process one event to confirm it works.
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);
      expect(runRepo.costIncrements['pr-1'], [100, 500]);

      // Reset and dispose.
      runRepo.costIncrements.clear();
      listener.dispose();

      // Publish after dispose.
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('Error in handler caught and logged (doesn\'t crash)', () async {
      ticketRepo = FakeTicketRepository([], throwOnForAgent: true);
      final listener = listener0();
      listener.start();

      // This should NOT throw — the error is caught internally.
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      // Test passes if we get here without an unhandled exception.
      expect(runRepo.costIncrements, isEmpty);
    });
  });
}

// Minimal DomainEvent impl for testing non-AgentRunCompleted events.
class _OtherEvent implements DomainEvent {
  const _OtherEvent();

  @override
  DateTime get occurredAt => DateTime(2026);
}
