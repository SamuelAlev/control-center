import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cost_rollup_listener.dart';
import 'package:test/test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────

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

AgentRunLog _log({
  required String id,
  String agentId = 'agent-1',
  String? pipelineRunId = 'pr-1',
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
      pipelineRunId: pipelineRunId,
      cost: RunCost(estimatedCostCents: costCents, inputTokens: tokens),
    );

AgentRunCompleted _event({
  String? runId = 'log-1',
  String agentId = 'agent-1',
  String? workspaceId = 'ws-1',
}) =>
    AgentRunCompleted(
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: 'conv-1',
      runId: runId,
      occurredAt: DateTime(2026),
    );

void main() {
  group('PipelineCostRollupListener', () {
    late DomainEventBus eventBus;
    late FakeAgentRunLogRepository logRepo;
    late FakePipelineRunRepository runRepo;

    setUp(() {
      eventBus = DomainEventBus();
      logRepo = FakeAgentRunLogRepository();
      runRepo = FakePipelineRunRepository();
    });

    PipelineCostRollupListener listener0() => PipelineCostRollupListener(
          eventBus: eventBus,
          runLogRepository: logRepo,
          runRepository: runRepo,
        );

    test('start() subscribes and rolls up the named run\'s cost', () async {
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements['pr-1'], [100, 500]);
    });

    test('increments the exact run log\'s cost (no fan-out, no heuristic)',
        () async {
      logRepo.seed(_log(id: 'log-1', costCents: 200, tokens: 1000));

      listener0().start();
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements['pr-1'], [200, 1000]);
    });

    test('event with null runId skips', () async {
      logRepo.seed(_log(id: 'log-1'));

      listener0().start();
      eventBus.publish(_event(runId: null));
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('run log with no pipelineRunId skips', () async {
      logRepo.seed(_log(id: 'log-1', pipelineRunId: null));

      listener0().start();
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('zero cost + zero tokens skips increment', () async {
      logRepo.seed(_log(id: 'log-1', costCents: 0, tokens: 0));

      listener0().start();
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('missing run log skips', () async {
      // No log seeded for the event's runId.
      listener0().start();
      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('non-AgentRunCompleted events are ignored', () async {
      logRepo.seed(_log(id: 'log-1'));
      listener0().start();

      eventBus.publish(const _OtherEvent());
      await Future<void>.delayed(Duration.zero);

      expect(runRepo.costIncrements, isEmpty);
    });

    test('dispose() unsubscribes (events after dispose not processed)',
        () async {
      logRepo.seed(_log(id: 'log-1'));

      final listener = listener0();
      listener.start();

      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);
      expect(runRepo.costIncrements['pr-1'], [100, 500]);

      runRepo.costIncrements.clear();
      listener.dispose();

      eventBus.publish(_event());
      await Future<void>.delayed(Duration.zero);

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
