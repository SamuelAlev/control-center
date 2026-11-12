import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';
import '../../../../fakes/fake_agent_run_log_repository.dart';

void main() {
  group('BudgetPolicy', () {
    test(
      'isUnlimited when monthlyBudgetMicros is zero',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 0,
        );
        expect(policy.isUnlimited, isTrue);
      },
    );

    test(
      'isUnlimited when monthlyBudgetMicros is negative',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: -1000000,
        );
        expect(policy.isUnlimited, isTrue);
      },
    );

    test(
      'isExhausted when spent >= budget and budget > 0',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          spentMicros: 10000000,
        );
        expect(policy.isExhausted, isTrue);
      },
    );

    test(
      'isExhausted when spent exceeds budget',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 5000000,
          spentMicros: 8000000,
        );
        expect(policy.isExhausted, isTrue);
      },
    );

    test(
      'isExhausted is false when budget is 0',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 0,
          spentMicros: 9990000,
        );
        expect(policy.isExhausted, isFalse);
      },
    );

    test(
      'isNearLimit when spent >= soft threshold',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          softThresholdPercent: 80,
          spentMicros: 8000000,
        );
        expect(policy.isNearLimit, isTrue);
      },
    );

    test(
      'isNearLimit is false when spent < soft threshold',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          softThresholdPercent: 80,
          spentMicros: 7990000,
        );
        expect(policy.isNearLimit, isFalse);
      },
    );

    test(
      'isNearLimit with non-default threshold',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          softThresholdPercent: 50,
          spentMicros: 5000000,
        );
        expect(policy.isNearLimit, isTrue);
      },
    );

    test(
      'isExhausted is false when spent < budget',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          spentMicros: 5000000,
        );
        expect(policy.isExhausted, isFalse);
      },
    );

    test(
      'remainingMicros = budget - spent',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          spentMicros: 3000000,
        );
        expect(policy.remainingMicros, 7000000);
      },
    );

    test('spentPercent clamps 0-100', timeout: const Timeout.factor(2), () {
      const over = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 1000000,
        spentMicros: 5000000,
      );
      expect(over.spentPercent, 100);

      const normal = BudgetPolicy(
        id: 'p2',
        scopeType: 'agent',
        scopeId: 'a2',
        monthlyBudgetMicros: 2000000,
        spentMicros: 500000,
      );
      expect(normal.spentPercent, 25);
    });

    test(
      'spentPercent is 0 when budget is unlimited',
      timeout: const Timeout.factor(2),
      () {
        const policy = BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 0,
          spentMicros: 99990000,
        );
        expect(policy.spentPercent, 0);
      },
    );

    test('equality and hashCode', timeout: const Timeout.factor(2), () {
      const a = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 10000000,
      );
      const b = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 10000000,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when values differ', timeout: const Timeout.factor(2), () {
      const a = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 10000000,
      );
      const b = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 20000000,
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith replaces fields', timeout: const Timeout.factor(2), () {
      const original = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetMicros: 10000000,
      );
      final updated = original.copyWith(spentMicros: 5000000);
      expect(updated.spentMicros, 5000000);
      expect(updated.id, 'p1');
      expect(updated.monthlyBudgetMicros, 10000000);
    });

    test(
      'copyWith can clear nullable fields',
      timeout: const Timeout.factor(2),
      () {
        final withDate = const BudgetPolicy(
          id: 'p1',
          scopeType: 'agent',
          scopeId: 'a1',
          monthlyBudgetMicros: 10000000,
          periodStart: null,
        ).copyWith(periodStart: DateTime(2025, 6, 1));
        expect(withDate.periodStart, isNotNull);

        final cleared = withDate.copyWith(removePeriodStart: true);
        expect(cleared.periodStart, isNull);
      },
    );
  });

  group('BudgetBlock', () {
    test(
      'carries reason and optional scope',
      timeout: const Timeout.factor(2),
      () {
        const block = BudgetBlock(
          reason: 'budget_exhausted',
          scopeType: 'agent',
          scopeId: 'a1',
        );
        expect(block.reason, 'budget_exhausted');
        expect(block.scopeType, 'agent');
        expect(block.scopeId, 'a1');
      },
    );

    test('scope fields are optional', timeout: const Timeout.factor(2), () {
      const block = BudgetBlock(reason: 'agent_not_found');
      expect(block.scopeType, isNull);
      expect(block.scopeId, isNull);
    });
  });

  group('BudgetEnforcementService', () {
    late FakeAgentRepository agentRepo;
    late FakeAgentRunLogRepository runLogRepo;
    late DomainEventBus eventBus;
    late BudgetEnforcementService service;

    setUp(() {
      agentRepo = FakeAgentRepository();
      runLogRepo = FakeAgentRunLogRepository();
      eventBus = DomainEventBus();
      service = BudgetEnforcementService(
        agentRunLogRepository: runLogRepo,
        agentRepository: agentRepo,
        eventBus: eventBus,
      );
    });

    tearDown(() => eventBus.dispose());

    Agent makeAgent({int monthlyBudgetMicros = 10000000}) => Agent(
      id: 'agent-1',
      name: 'Test',
      title: 'Test',
      agentMdPath: '/p.md',
      workspaceId: 'ws-1',
      skills: AgentSkills([]),
      monthlyBudgetMicros: monthlyBudgetMicros,
      createdAt: DateTime(2025, 1, 1),
    );

    AgentRunLog makeLog({int costMicros = 0, DateTime? startedAt}) =>
        AgentRunLog(
          id: 'log-${DateTime.now().microsecondsSinceEpoch}',
          agentId: 'agent-1',
          startedAt: startedAt ?? DateTime.now(),
          status: RunStatus.completed,
          cost: RunCost(costMicros: costMicros),
        );

    test(
      'returns block when agent not found',
      timeout: const Timeout.factor(2),
      () async {
        final block = await service.checkInvocationBlock(
          agentId: 'missing',
          workspaceId: 'ws-1',
        );
        expect(block, isNotNull);
        expect(block!.reason, 'agent_not_found');
      },
    );

    test(
      'returns null when agent has unlimited budget (0)',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 0));
        final block = await service.checkInvocationBlock(
          agentId: 'agent-1',
          workspaceId: 'ws-1',
        );
        expect(block, isNull);
      },
    );

    test(
      'returns block when budget exhausted',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 5000000));
        runLogRepo.seed(makeLog(costMicros: 6000000));

        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        final block = await service.checkInvocationBlock(
          agentId: 'agent-1',
          workspaceId: 'ws-1',
        );
        expect(block, isNotNull);
        expect(block!.reason, 'budget_exhausted');

        // Allow stream to deliver
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isTrue);
      },
    );

    test(
      'many sub-cent runs exhaust a one-cent budget',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 10000));
        // Each run costs 0.3 cents; a cents total would count each as zero.
        for (var i = 0; i < 4; i++) {
          runLogRepo.seed(
            AgentRunLog(
              id: 'sub-cent-$i',
              agentId: 'agent-1',
              startedAt: DateTime.now(),
              status: RunStatus.completed,
              cost: const RunCost(costMicros: 3000),
            ),
          );
        }

        final block = await service.checkInvocationBlock(
          agentId: 'agent-1',
          workspaceId: 'ws-1',
        );
        expect(block, isNotNull);
        expect(block!.reason, 'budget_exhausted');
      },
    );

    test(
      'publishes warning event when near 80% but does not block',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 10000000));
        runLogRepo.seed(makeLog(costMicros: 8500000));

        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        final block = await service.checkInvocationBlock(
          agentId: 'agent-1',
          workspaceId: 'ws-1',
        );
        expect(block, isNull);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, hasLength(1));
        expect(events.first.isHardStop, isFalse);
      },
    );

    test(
      'no events when spend is well below threshold',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 10000000));
        runLogRepo.seed(makeLog(costMicros: 1000000));

        final events = <BudgetThresholdCrossed>[];
        eventBus.on<BudgetThresholdCrossed>().listen(events.add);

        await service.checkInvocationBlock(
          agentId: 'agent-1',
          workspaceId: 'ws-1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(events, isEmpty);
      },
    );

    test(
      'getSpentPercent returns 0 for unknown agent',
      timeout: const Timeout.factor(2),
      () async {
        final pct = await service.getSpentPercent('ws-1', 'missing');
        expect(pct, 0);
      },
    );

    test(
      'getSpentPercent returns 0 for unlimited budget',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 0));
        runLogRepo.seed(makeLog(costMicros: 5000000));

        final pct = await service.getSpentPercent('ws-1', 'agent-1');
        expect(pct, 0);
      },
    );

    test(
      'getSpentPercent returns clamped percentage',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 2000000));
        runLogRepo.seed(makeLog(costMicros: 1000000));

        final pct = await service.getSpentPercent('ws-1', 'agent-1');
        expect(pct, 50);
      },
    );

    test(
      'getSpentPercent clamps to 100 when over budget',
      timeout: const Timeout.factor(2),
      () async {
        await agentRepo.upsert(makeAgent(monthlyBudgetMicros: 1000000));
        runLogRepo.seed(makeLog(costMicros: 3000000));

        final pct = await service.getSpentPercent('ws-1', 'agent-1');
        expect(pct, 100);
      },
    );
  });
}
