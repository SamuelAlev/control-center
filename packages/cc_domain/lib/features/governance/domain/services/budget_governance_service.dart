import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
import 'package:cc_domain/features/governance/domain/repositories/budget_policy_repository.dart';
import 'package:uuid/uuid.dart';

/// The outcome of a budget governance evaluation.
enum BudgetOutcome {
  /// Spend is comfortably below the soft threshold.
  ok,

  /// Spend crossed the soft threshold; a warning incident was recorded.
  softWarning,

  /// Spend exhausted the budget; a hard incident was recorded and the agent was
  /// auto-paused.
  hardStop,
}

/// The decision returned by [BudgetGovernanceService.evaluateAgent].
class BudgetDecision {
  /// Creates a [BudgetDecision].
  const BudgetDecision({
    required this.outcome,
    required this.spentMicros,
    required this.budgetMicros,
    this.incident,
  });

  /// What the evaluation concluded.
  final BudgetOutcome outcome;

  /// Micro-dollars spent in the current window.
  final int spentMicros;

  /// The budget ceiling (0 means unlimited — outcome is always [BudgetOutcome.ok]).
  final int budgetMicros;

  /// The incident recorded, when one was raised.
  final BudgetIncident? incident;

  /// Whether the agent was hard-stopped (and thus auto-paused).
  bool get isHardStop => outcome == BudgetOutcome.hardStop;
}

/// Enforces budgets with durable incidents and hard-stop auto-pause.
///
/// On a hard stop the offending agent's lifecycle status flips to `paused`
/// (it stops being dispatchable) and a hard [BudgetIncident] is recorded. A
/// soft-threshold crossing records a warning incident without pausing. Cost is
/// the per-agent monthly spend; the effective ceiling is the agent's linked
/// [BudgetPolicy] (when set) or its own `monthlyBudgetMicros`.
class BudgetGovernanceService {
  /// Creates a [BudgetGovernanceService].
  BudgetGovernanceService({
    required AgentRepository agentRepository,
    required this._enforcement,
    required BudgetPolicyRepository budgetRepository,
    this._eventBus,
    ActivityLogger? activityLogger,
  }) : _agents = agentRepository,
       _budgets = budgetRepository,
       _audit = activityLogger;

  final AgentRepository _agents;
  final BudgetEnforcementService _enforcement;
  final BudgetPolicyRepository _budgets;
  final DomainEventBus? _eventBus;
  final ActivityLogger? _audit;

  static const _uuid = Uuid();
  static const _tag = 'BudgetGovernanceService';

  /// Evaluates [agentId] against its effective budget. Records an incident and
  /// auto-pauses the agent on a hard stop; records a warning on a soft crossing.
  Future<BudgetDecision> evaluateAgent({
    required String workspaceId,
    required String agentId,
  }) async {
    final agent = await _agents.getById(workspaceId, agentId);
    if (agent == null || agent.workspaceId != workspaceId) {
      return const BudgetDecision(
        outcome: BudgetOutcome.ok,
        spentMicros: 0,
        budgetMicros: 0,
      );
    }

    // Resolve the effective ceiling + soft threshold from a linked policy or
    // the agent's own monthly budget.
    var budgetMicros = agent.monthlyBudgetMicros;
    var softPercent = 80;
    var hardStopEnabled = true;
    String? policyId;
    final policyRef = agent.budgetPolicyId;
    if (policyRef != null) {
      final policy = await _budgets.getPolicyById(workspaceId, policyRef);
      if (policy != null) {
        budgetMicros = policy.monthlyBudgetMicros;
        softPercent = policy.softThresholdPercent;
        hardStopEnabled = policy.hardStopEnabled;
        policyId = policy.id;
      }
    }

    if (budgetMicros <= 0) {
      return BudgetDecision(
        outcome: BudgetOutcome.ok,
        spentMicros: 0,
        budgetMicros: budgetMicros,
      );
    }

    final spent = await _enforcement.currentMonthSpentMicros(
      workspaceId,
      agentId,
    );

    if (spent >= budgetMicros && hardStopEnabled) {
      final incident = await _recordIncident(
        workspaceId: workspaceId,
        policyId: policyId,
        agentId: agentId,
        spent: spent,
        budget: budgetMicros,
        isHardStop: true,
        reason: 'budget_exhausted',
      );
      await _pauseAgent(agent);
      _eventBus?.publish(
        BudgetThresholdCrossed(
          workspaceId: workspaceId,
          scopeType: 'agent',
          scopeId: agentId,
          spentMicros: spent,
          budgetMicros: budgetMicros,
          isHardStop: true,
          occurredAt: DateTime.now(),
        ),
      );
      CcDomainLog.warning(
        '$_tag: hard stop for $agentId (${formatUsdMicros(spent)}/${formatUsdMicros(budgetMicros)}) — paused',
      );
      return BudgetDecision(
        outcome: BudgetOutcome.hardStop,
        spentMicros: spent,
        budgetMicros: budgetMicros,
        incident: incident,
      );
    }

    final softMicros = budgetMicros * softPercent ~/ 100;
    if (spent >= softMicros) {
      final incident = await _recordIncident(
        workspaceId: workspaceId,
        policyId: policyId,
        agentId: agentId,
        spent: spent,
        budget: budgetMicros,
        isHardStop: false,
        reason: 'soft_threshold',
      );
      _eventBus?.publish(
        BudgetThresholdCrossed(
          workspaceId: workspaceId,
          scopeType: 'agent',
          scopeId: agentId,
          spentMicros: spent,
          budgetMicros: budgetMicros,
          isHardStop: false,
          occurredAt: DateTime.now(),
        ),
      );
      return BudgetDecision(
        outcome: BudgetOutcome.softWarning,
        spentMicros: spent,
        budgetMicros: budgetMicros,
        incident: incident,
      );
    }

    return BudgetDecision(
      outcome: BudgetOutcome.ok,
      spentMicros: spent,
      budgetMicros: budgetMicros,
    );
  }

  Future<BudgetIncident> _recordIncident({
    required String workspaceId,
    required String? policyId,
    required String agentId,
    required int spent,
    required int budget,
    required bool isHardStop,
    required String reason,
  }) async {
    final incident = BudgetIncident(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      policyId: policyId,
      scopeType: 'agent',
      scopeId: agentId,
      spentMicros: spent,
      budgetMicros: budget,
      isHardStop: isHardStop,
      reason: reason,
      triggeredAt: DateTime.now(),
    );
    await _budgets.recordIncident(incident);
    _audit?.log(
      actorType: 'system',
      action: isHardStop ? 'budget_hard_stop' : 'budget_soft_warning',
      entityType: 'agent',
      entityId: agentId,
      workspaceId: workspaceId,
      details: '${formatUsdMicros(spent)}/${formatUsdMicros(budget)}',
    );
    return incident;
  }

  Future<void> _pauseAgent(Agent agent) async {
    if (agent.lifecycleStatus == AgentLifecycleStatus.paused) {
      return;
    }
    await _agents.upsert(
      agent.copyWith(lifecycleStatus: AgentLifecycleStatus.paused),
    );
  }
}
