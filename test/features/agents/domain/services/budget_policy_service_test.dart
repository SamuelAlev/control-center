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
    test('isUnlimited when monthlyBudgetCents is zero',
        timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 0,
      );
      expect(policy.isUnlimited, isTrue);
    });

    test('isUnlimited when monthlyBudgetCents is negative',
        timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: -100,
      );
      expect(policy.isUnlimited, isTrue);
    });

    test('isExhausted when spent >= budget and budget > 0',
        timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        spentCents: 1000,
      );
      expect(policy.isExhausted, isTrue);
    });

    test('isExhausted when spent exceeds budget', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 500,
        spentCents: 800,
      );
      expect(policy.isExhausted, isTrue);
    });

    test('isExhausted is false when budget is 0', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 0,
        spentCents: 999,
      );
      expect(policy.isExhausted, isFalse);
    });

    test('isNearLimit when spent >= soft threshold', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        softThresholdPercent: 80,
        spentCents: 800,
      );
      expect(policy.isNearLimit, isTrue);
    });

    test('isNearLimit is false when spent < soft threshold',
        timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        softThresholdPercent: 80,
        spentCents: 799,
      );
      expect(policy.isNearLimit, isFalse);
    });

    test('isNearLimit with non-default threshold', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        softThresholdPercent: 50,
        spentCents: 500,
      );
      expect(policy.isNearLimit, isTrue);
    });

    test('isExhausted is false when spent < budget', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        spentCents: 500,
      );
      expect(policy.isExhausted, isFalse);
    });

    test('remainingCents = budget - spent', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        spentCents: 300,
      );
      expect(policy.remainingCents, 700);
    });

    test('spentPercent clamps 0-100', timeout: const Timeout.factor(2), () {
      const over = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 100,
        spentCents: 500,
      );
      expect(over.spentPercent, 100);

      const normal = BudgetPolicy(
        id: 'p2',
        scopeType: 'agent',
        scopeId: 'a2',
        monthlyBudgetCents: 200,
        spentCents: 50,
      );
      expect(normal.spentPercent, 25);
    });

    test('spentPercent is 0 when budget is unlimited', timeout: const Timeout.factor(2), () {
      const policy = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 0,
        spentCents: 9999,
      );
      expect(policy.spentPercent, 0);
    });

    test('equality and hashCode', timeout: const Timeout.factor(2), () {
      const a = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
      );
      const b = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when values differ', timeout: const Timeout.factor(2), () {
      const a = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
      );
      const b = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 2000,
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith replaces fields', timeout: const Timeout.factor(2), () {
      const original = BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
      );
      final updated = original.copyWith(spentCents: 500);
      expect(updated.spentCents, 500);
      expect(updated.id, 'p1');
      expect(updated.monthlyBudgetCents, 1000);
    });

    test('copyWith can clear nullable fields', timeout: const Timeout.factor(2), () {
      final withDate = const BudgetPolicy(
        id: 'p1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
        periodStart: null,
      ).copyWith(periodStart: DateTime(2025, 6, 1));
      expect(withDate.periodStart, isNotNull);

      final cleared = withDate.copyWith(removePeriodStart: true);
      expect(cleared.periodStart, isNull);
    });
  });

  group('BudgetBlock', () {
    test('carries reason and optional scope', timeout: const Timeout.factor(2), () {
      const block = BudgetBlock(
        reason: 'budget_exhausted',
        scopeType: 'agent',
        scopeId: 'a1',
      );
      expect(block.reason, 'budget_exhausted');
      expect(block.scopeType, 'agent');
      expect(block.scopeId, 'a1');
    });

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

    Agent makeAgent({int monthlyBudgetCents = 1000}) => Agent(
          id: 'agent-1',
          name: 'Test',
          title: 'Test',
          agentMdPath: '/p.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          monthlyBudgetCents: monthlyBudgetCents,
          createdAt: DateTime(2025, 1, 1),
        );

    AgentRunLog makeLog({
      int costCents = 0,
      DateTime? startedAt,
    }) =>
        AgentRunLog(
          id: 'log-${DateTime.now().microsecondsSinceEpoch}',
          agentId: 'agent-1',
          startedAt: startedAt ?? DateTime.now(),
          status: RunStatus.completed,
          cost: RunCost(estimatedCostCents: costCents),
        );

    test('returns block when agent not found', timeout: const Timeout.factor(2), () async {
      final block = await service.checkInvocationBlock(
        agentId: 'missing',
        workspaceId: 'ws-1',
      );
      expect(block, isNotNull);
      expect(block!.reason, 'agent_not_found');
    });

    test('returns null when agent has unlimited budget (0)',
        timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 0));
      final block = await service.checkInvocationBlock(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
      );
      expect(block, isNull);
    });

    test('returns block when budget exhausted', timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 500));
      runLogRepo.seed(makeLog(costCents: 600));

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
    });

    test('publishes warning event when near 80% but does not block',
        timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 1000));
      runLogRepo.seed(makeLog(costCents: 850));

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
    });

    test('no events when spend is well below threshold',
        timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 1000));
      runLogRepo.seed(makeLog(costCents: 100));

      final events = <BudgetThresholdCrossed>[];
      eventBus.on<BudgetThresholdCrossed>().listen(events.add);

      await service.checkInvocationBlock(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);
    });

    test('getSpentPercent returns 0 for unknown agent',
        timeout: const Timeout.factor(2), () async {
      final pct = await service.getSpentPercent('missing');
      expect(pct, 0);
    });

    test('getSpentPercent returns 0 for unlimited budget',
        timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 0));
      runLogRepo.seed(makeLog(costCents: 500));

      final pct = await service.getSpentPercent('agent-1');
      expect(pct, 0);
    });

    test('getSpentPercent returns clamped percentage', timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 200));
      runLogRepo.seed(makeLog(costCents: 100));

      final pct = await service.getSpentPercent('agent-1');
      expect(pct, 50);
    });

    test('getSpentPercent clamps to 100 when over budget',
        timeout: const Timeout.factor(2), () async {
      await agentRepo.upsert(makeAgent(monthlyBudgetCents: 100));
      runLogRepo.seed(makeLog(costCents: 300));

      final pct = await service.getSpentPercent('agent-1');
      expect(pct, 100);
    });
  });
}
