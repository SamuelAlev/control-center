import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/observability_events.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/features/agents/data/services/cost_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_run_log_repository.dart';

void main() {
  group('CostTracker', () {
    late FakeAgentRunLogRepository runLogRepo;
    late DomainEventBus eventBus;
    late CostTracker tracker;

    setUp(() {
      runLogRepo = FakeAgentRunLogRepository();
      eventBus = DomainEventBus();
      tracker = CostTracker(
        runLogRepo: runLogRepo,
        eventBus: eventBus,
      );
    });

    tearDown(() => eventBus.dispose());

    AgentRunLog makeLog({
      String id = 'log-1',
      String agentId = 'agent-1',
      int costCents = 0,
      DateTime? startedAt,
    }) =>
        AgentRunLog(
          id: id,
          agentId: agentId,
          startedAt: startedAt ?? DateTime.now(),
          status: RunStatus.completed,
          cost: RunCost(estimatedCostCents: costCents),
        );

    group('recordUsage', () {
      test('computes cost and updates run log', timeout: const Timeout.factor(2), () async {
        final log = makeLog();
        runLogRepo.seed(log);

        await tracker.recordUsage(
          runLogId: 'log-1',
          inputTokens: 1000,
          outputTokens: 500,
        );

        final updated = await runLogRepo.getById('log-1');
        expect(updated, isNotNull);
        // cost = (1000 * 0.000003 + 500 * 0.000015) * 100 = (0.003 + 0.0075) * 100 = 1.05 → round to 1
        expect(updated!.cost.estimatedCostCents, 1);
        expect(updated.cost.inputTokens, 1000);
        expect(updated.cost.outputTokens, 500);
      });

      test('computes cost with custom token prices', timeout: const Timeout.factor(2), () async {
        final log = makeLog();
        runLogRepo.seed(log);

        await tracker.recordUsage(
          runLogId: 'log-1',
          inputTokens: 100,
          outputTokens: 100,
          costPerInputToken: 0.01,
          costPerOutputToken: 0.03,
        );

        final updated = await runLogRepo.getById('log-1');
        // cost = (100 * 0.01 + 100 * 0.03) * 100 = (1 + 3) * 100 = 400
        expect(updated!.cost.estimatedCostCents, 400);
      });

      test('is no-op when run log not found', timeout: const Timeout.factor(2), () async {
        await tracker.recordUsage(
          runLogId: 'missing',
          inputTokens: 1000,
          outputTokens: 500,
        );
        // Should not throw
      });

      test('preserves other fields on the run log', timeout: const Timeout.factor(2), () async {
        final log = makeLog().copyWith(
          summary: 'original summary',
        );
        runLogRepo.seed(log);

        await tracker.recordUsage(
          runLogId: 'log-1',
          inputTokens: 500,
          outputTokens: 250,
        );

        final updated = await runLogRepo.getById('log-1');
        expect(updated!.summary, 'original summary');
        expect(updated.agentId, 'agent-1');
      });
    });

    group('getMonthlySpendForAgent', () {
      test('sums cost for agent runs this month', timeout: const Timeout.factor(2), () async {
        runLogRepo.seed(makeLog(id: 'l1', costCents: 100, agentId: 'agent-1'));
        runLogRepo.seed(makeLog(id: 'l2', costCents: 200, agentId: 'agent-1'));
        runLogRepo.seed(makeLog(id: 'l3', costCents: 300, agentId: 'agent-2'));

        final spend = await tracker.getMonthlySpendForAgent('agent-1');
        expect(spend, 300);
      });

      test('excludes runs from previous months', timeout: const Timeout.factor(2), () async {
        final now = DateTime.now();
        final lastMonth = DateTime(now.year, now.month - 1, 15);
        runLogRepo.seed(makeLog(id: 'l-old', costCents: 500, startedAt: lastMonth));
        runLogRepo.seed(makeLog(id: 'l-new', costCents: 100));

        final spend = await tracker.getMonthlySpendForAgent('agent-1');
        expect(spend, 100);
      });

      test('returns 0 for agent with no runs', timeout: const Timeout.factor(2), () async {
        final spend = await tracker.getMonthlySpendForAgent('agent-1');
        expect(spend, 0);
      });
    });

    group('getMonthlySpendTotal', () {
      test('sums cost across all agents this month', timeout: const Timeout.factor(2), () async {
        runLogRepo.seed(makeLog(id: 'l1', costCents: 100, agentId: 'a1'));
        runLogRepo.seed(makeLog(id: 'l2', costCents: 200, agentId: 'a2'));

        final spend = await tracker.getMonthlySpendTotal();
        expect(spend, 300);
      });

      test('returns 0 for no runs', timeout: const Timeout.factor(2), () async {
        final spend = await tracker.getMonthlySpendTotal();
        expect(spend, 0);
      });
    });

    group('checkBudget', () {
      test('publishes hard stop event at 100%', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 1000,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isTrue);
        expect(events.first.spentCents, 1000);
        expect(events.first.budgetCents, 1000);
      });

      test('publishes hard stop event above 100%', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 1500,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isTrue);
      });

      test('publishes warning event at 80%', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 800,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isFalse);
      });

      test('publishes no event below 80%', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 700,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);
      });

      test('does nothing when budgetCents is 0', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 999999,
          budgetCents: 0,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);
      });

      test('does nothing when budgetCents is negative', timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 100,
          budgetCents: -1,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);
      });

      test('does not publish when eventBus is null', timeout: const Timeout.factor(2), () {
        final noBusTracker = CostTracker(runLogRepo: runLogRepo);
        // Should not throw
        noBusTracker.checkBudget(
          spentCents: 1000,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );
      });

      test('only publishes hard stop (not warning) at exactly 100%',
          timeout: const Timeout.factor(2), () async {
        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        tracker.checkBudget(
          spentCents: 1000,
          budgetCents: 1000,
          scopeType: 'agent',
          scopeId: 'a1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isTrue);
      });
    });
  });
}
