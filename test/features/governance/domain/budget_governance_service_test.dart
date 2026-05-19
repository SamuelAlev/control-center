import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
import 'package:cc_domain/features/governance/domain/repositories/budget_policy_repository.dart';
import 'package:cc_domain/features/governance/domain/services/budget_governance_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_agent_repository.dart';
import '../../../fakes/fake_agent_run_log_repository.dart';

/// Spend stub — returns a fixed monthly spend so governance can be exercised
/// without seeding run-log cost rows.
class _StubEnforcement extends BudgetEnforcementService {
  _StubEnforcement(this._spent, AgentRepository agents)
    : super(
        agentRunLogRepository: FakeAgentRunLogRepository(),
        agentRepository: agents,
        eventBus: DomainEventBus(),
      );
  final int _spent;
  @override
  Future<int> currentMonthSpentCents(
    String workspaceId,
    String agentId,
  ) async => _spent;
}

class _FakeBudgetRepo implements BudgetPolicyRepository {
  final Map<String, BudgetPolicy> policies = {};
  final List<BudgetIncident> incidents = [];

  @override
  Future<void> recordIncident(BudgetIncident incident) async =>
      incidents.add(incident);

  @override
  Future<BudgetPolicy?> getPolicyById(String workspaceId, String id) async {
    final p = policies[id];
    return (p != null && p.workspaceId == workspaceId) ? p : null;
  }

  @override
  Future<void> upsertPolicy(BudgetPolicy policy) async =>
      policies[policy.id] = policy;

  @override
  Stream<List<BudgetPolicy>> watchPolicies(String workspaceId) =>
      Stream.value(policies.values.toList());

  @override
  Future<List<BudgetPolicy>> listPolicies(String workspaceId) async =>
      policies.values.toList();

  @override
  Future<BudgetPolicy?> getPolicyForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) async => null;

  @override
  Future<void> deletePolicy(String workspaceId, String id) async {}

  @override
  Stream<List<BudgetIncident>> watchIncidents(String workspaceId) =>
      Stream.value(incidents);

  @override
  Future<List<BudgetIncident>> incidentsForScope(
    String workspaceId,
    String scopeType,
    String scopeId,
  ) async => incidents
      .where((i) => i.scopeType == scopeType && i.scopeId == scopeId)
      .toList();
}

Agent _agent({int budget = 0, String? policyId}) => Agent(
  id: 'a1',
  name: 'a1',
  title: 'Agent',
  agentMdPath: '/tmp/a1.md',
  workspaceId: 'ws1',
  skills: AgentSkills(const []),
  monthlyBudgetCents: budget,
  budgetPolicyId: policyId,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late FakeAgentRepository agents;
  late _FakeBudgetRepo budgets;

  setUp(() {
    agents = FakeAgentRepository();
    budgets = _FakeBudgetRepo();
  });

  BudgetGovernanceService service(int spent) => BudgetGovernanceService(
    agentRepository: agents,
    enforcement: _StubEnforcement(spent, agents),
    budgetRepository: budgets,
  );

  test(
    'exceeding the monthly budget auto-pauses the agent + logs incident',
    () async {
      await agents.upsert(_agent(budget: 1000));
      final decision = await service(
        1200,
      ).evaluateAgent(workspaceId: 'ws1', agentId: 'a1');

      expect(decision.isHardStop, isTrue);
      expect(decision.incident, isNotNull);
      expect(decision.incident!.isHardStop, isTrue);
      expect(decision.incident!.reason, 'budget_exhausted');
      expect(budgets.incidents.length, 1);

      final paused = await agents.getById('ws1', 'a1');
      expect(paused!.lifecycleStatus, AgentLifecycleStatus.paused);
      expect(paused.isDispatchable, isFalse);
    },
  );

  test('crossing the soft threshold warns without pausing', () async {
    await agents.upsert(_agent(budget: 1000));
    final decision = await service(
      850,
    ).evaluateAgent(workspaceId: 'ws1', agentId: 'a1');

    expect(decision.outcome, BudgetOutcome.softWarning);
    expect(decision.incident!.isHardStop, isFalse);
    final agent = await agents.getById('ws1', 'a1');
    expect(agent!.lifecycleStatus, AgentLifecycleStatus.active);
  });

  test('well under budget is ok with no incident', () async {
    await agents.upsert(_agent(budget: 1000));
    final decision = await service(
      100,
    ).evaluateAgent(workspaceId: 'ws1', agentId: 'a1');
    expect(decision.outcome, BudgetOutcome.ok);
    expect(budgets.incidents, isEmpty);
  });

  test('an unlimited budget (0) is never enforced', () async {
    await agents.upsert(_agent(budget: 0));
    final decision = await service(
      999999,
    ).evaluateAgent(workspaceId: 'ws1', agentId: 'a1');
    expect(decision.outcome, BudgetOutcome.ok);
  });

  test('a linked budget policy supplies the effective ceiling', () async {
    budgets.policies['p1'] = const BudgetPolicy(
      id: 'p1',
      workspaceId: 'ws1',
      scopeType: 'agent',
      scopeId: 'a1',
      monthlyBudgetCents: 500,
    );
    await agents.upsert(_agent(policyId: 'p1'));
    final decision = await service(
      600,
    ).evaluateAgent(workspaceId: 'ws1', agentId: 'a1');
    expect(decision.isHardStop, isTrue);
    expect(decision.budgetCents, 500);
  });
}
