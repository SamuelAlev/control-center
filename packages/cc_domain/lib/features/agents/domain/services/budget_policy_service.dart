import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/money.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/governance/domain/services/budget_forecast.dart';

/// Encapsulates a budget enforcement decision — why an invocation was blocked.
class BudgetBlock {
  /// Creates a budget block with a [reason], optional [scopeType] and [scopeId].
  const BudgetBlock({required this.reason, this.scopeType, this.scopeId});

  /// Human-readable reason the invocation was blocked.
  final String reason;

  /// Type of scope the budget applies to (e.g. "agent", "workspace").
  final String? scopeType;

  /// Identifier of the scope the budget applies to.
  final String? scopeId;
}

/// A budget policy defining spending limits and thresholds for a scope.
class BudgetPolicy {
  /// Creates a budget policy with required [id], [scopeType], [scopeId],
  /// and [monthlyBudgetMicros], plus optional thresholds and tracking fields.
  const BudgetPolicy({
    required this.id,
    required this.scopeType,
    required this.scopeId,
    required this.monthlyBudgetMicros,
    this.workspaceId = '',
    this.softThresholdPercent = 80,
    this.hardStopEnabled = true,
    this.spentMicros = 0,
    this.status = 'active',
    this.periodStart,
    this.periodEnd,
    this.createdAt,
  });

  /// Unique identifier for this policy.
  final String id;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// Type of scope this policy applies to (e.g. "agent", "workspace").
  final String scopeType;

  /// Identifier of the scope this policy governs.
  final String scopeId;

  /// Monthly budget in micro-dollars (0 or negative means unlimited).
  final int monthlyBudgetMicros;

  /// Percentage of budget at which a soft threshold warning fires.
  final int softThresholdPercent;

  /// Whether to hard-stop invocations when the budget is exhausted.
  final bool hardStopEnabled;

  /// Total micro-dollars spent in the current billing period.
  final int spentMicros;

  /// Current status of this budget policy ('active', 'paused', etc.).
  final String status;

  /// Start of the current billing period.
  final DateTime? periodStart;

  /// End of the current billing period.
  final DateTime? periodEnd;

  /// When this policy was created.
  final DateTime? createdAt;

  /// Whether this policy has no spending limit.
  bool get isUnlimited => monthlyBudgetMicros <= 0;

  /// Whether the budget has been fully consumed.
  bool get isExhausted =>
      spentMicros >= monthlyBudgetMicros && monthlyBudgetMicros > 0;

  /// Whether spending has crossed the soft threshold.
  bool get isNearLimit =>
      monthlyBudgetMicros > 0 &&
      spentMicros >= (monthlyBudgetMicros * softThresholdPercent ~/ 100);

  /// Micro-dollars remaining before the budget is exhausted.
  int get remainingMicros => monthlyBudgetMicros - spentMicros;

  /// Percentage of the budget that has been spent (0–100).
  int get spentPercent {
    if (monthlyBudgetMicros <= 0) {
      return 0;
    }
    return ((spentMicros * 100) ~/ monthlyBudgetMicros).clamp(0, 100);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPolicy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          scopeType == other.scopeType &&
          scopeId == other.scopeId &&
          monthlyBudgetMicros == other.monthlyBudgetMicros &&
          softThresholdPercent == other.softThresholdPercent &&
          hardStopEnabled == other.hardStopEnabled &&
          spentMicros == other.spentMicros &&
          status == other.status &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    scopeType,
    scopeId,
    monthlyBudgetMicros,
    softThresholdPercent,
    hardStopEnabled,
    spentMicros,
    status,
    periodStart,
    periodEnd,
    createdAt,
  );

  /// Returns a copy of this policy with the given fields replaced.
  BudgetPolicy copyWith({
    String? id,
    String? workspaceId,
    String? scopeType,
    String? scopeId,
    int? monthlyBudgetMicros,
    int? softThresholdPercent,
    bool? hardStopEnabled,
    int? spentMicros,
    String? status,
    DateTime? periodStart,
    bool removePeriodStart = false,
    DateTime? periodEnd,
    bool removePeriodEnd = false,
    DateTime? createdAt,
    bool removeCreatedAt = false,
  }) {
    return BudgetPolicy(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      monthlyBudgetMicros: monthlyBudgetMicros ?? this.monthlyBudgetMicros,
      softThresholdPercent: softThresholdPercent ?? this.softThresholdPercent,
      hardStopEnabled: hardStopEnabled ?? this.hardStopEnabled,
      spentMicros: spentMicros ?? this.spentMicros,
      status: status ?? this.status,
      periodStart: removePeriodStart ? null : (periodStart ?? this.periodStart),
      periodEnd: removePeriodEnd ? null : (periodEnd ?? this.periodEnd),
      createdAt: removeCreatedAt ? null : (createdAt ?? this.createdAt),
    );
  }
}

/// Service that enforces budget policies by checking whether agent invocations
/// should be blocked due to budget exhaustion or threshold crossings.
class BudgetEnforcementService {
  /// Creates a budget enforcement service with the required repositories
  /// and event bus.
  BudgetEnforcementService({
    required this._agentRunLogRepository,
    required this._agentRepository,
    required this._eventBus,
  });

  final AgentRunLogRepository _agentRunLogRepository;
  final AgentRepository _agentRepository;
  final DomainEventBus _eventBus;

  static const _tag = 'BudgetEnforcementService';

  /// Checks whether an agent invocation should be blocked due to budget
  /// constraints. Returns a [BudgetBlock] if blocked, or `null` if allowed.
  Future<BudgetBlock?> checkInvocationBlock({
    required String agentId,
    required String workspaceId,
    String? ticketId,
  }) async {
    final agent = await _agentRepository.getById(workspaceId, agentId);
    if (agent == null) {
      CcDomainLog.warning('$_tag: Agent not found: $agentId');
      return BudgetBlock(
        reason: 'agent_not_found',
        scopeType: 'agent',
        scopeId: agentId,
      );
    }

    if (agent.monthlyBudgetMicros <= 0) {
      return null;
    }

    final spent = await _currentMonthSpentMicros(agent.workspaceId, agentId);

    if (spent >= agent.monthlyBudgetMicros) {
      CcDomainLog.warning(
        '$_tag: Budget exhausted for $agentId: ${formatUsdMicros(spent)} / ${formatUsdMicros(agent.monthlyBudgetMicros)}',
      );
      _eventBus.publish(
        BudgetThresholdCrossed(
          workspaceId: agent.workspaceId,
          scopeType: 'agent',
          scopeId: agentId,
          spentMicros: spent,
          budgetMicros: agent.monthlyBudgetMicros,
          isHardStop: true,
          occurredAt: DateTime.now(),
        ),
      );
      return BudgetBlock(
        reason: 'budget_exhausted',
        scopeType: 'agent',
        scopeId: agentId,
      );
    }

    final thresholdAmount = agent.monthlyBudgetMicros * 80 ~/ 100;
    if (spent >= thresholdAmount) {
      CcDomainLog.warning(
        '$_tag: Budget near limit for $agentId: ${formatUsdMicros(spent)} / ${formatUsdMicros(agent.monthlyBudgetMicros)}',
      );
      _eventBus.publish(
        BudgetThresholdCrossed(
          workspaceId: agent.workspaceId,
          scopeType: 'agent',
          scopeId: agentId,
          spentMicros: spent,
          budgetMicros: agent.monthlyBudgetMicros,
          isHardStop: false,
          occurredAt: DateTime.now(),
        ),
      );
    }

    return null;
  }

  /// Returns the percentage of the monthly budget spent by [agentId] (0–100)
  /// within [workspaceId], which scopes the agent lookup.
  Future<int> getSpentPercent(String workspaceId, String agentId) async {
    final agent = await _agentRepository.getById(workspaceId, agentId);
    if (agent == null || agent.monthlyBudgetMicros <= 0) {
      return 0;
    }

    final spent = await _currentMonthSpentMicros(agent.workspaceId, agentId);
    return ((spent * 100) ~/ agent.monthlyBudgetMicros).clamp(0, 100);
  }

  /// Returns the micro-dollars [agentId] has spent in the current UTC calendar month.
  /// Shared with the governance layer (incident logging + auto-pause).
  Future<int> currentMonthSpentMicros(String workspaceId, String agentId) =>
      _currentMonthSpentMicros(workspaceId, agentId);

  /// Projects [agentId]'s month-end spend from its recent burn rate (FINDINGS
  /// §16.1), so a warning can fire *before* the hard-stop lands mid-task.
  /// Returns a forecast with an unlimited (budget 0) result when the agent has
  /// no monthly budget. [lookbackDays] sets the burn-rate window.
  Future<BudgetForecast> forecast(
    String workspaceId,
    String agentId, {
    int lookbackDays = 7,
  }) async {
    final agent = await _agentRepository.getById(workspaceId, agentId);
    final budgetMicros = agent?.monthlyBudgetMicros ?? 0;
    final logs = await _agentRunLogRepository
        .watchByAgent(workspaceId, agentId)
        .first;
    return forecastBudget(
      spend: [
        for (final l in logs)
          SpendPoint(at: l.startedAt, costMicros: l.cost.costMicros),
      ],
      now: DateTime.now(),
      budgetMicros: budgetMicros,
      lookbackDays: lookbackDays,
    );
  }

  Future<int> _currentMonthSpentMicros(
    String workspaceId,
    String agentId,
  ) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final logs = await _agentRunLogRepository
        .watchByAgent(workspaceId, agentId)
        .first;

    return logs
        .where(
          (log) =>
              log.startedAt.isAfter(
                monthStart.subtract(const Duration(seconds: 1)),
              ) ||
              log.startedAt.isAtSameMomentAs(monthStart),
        )
        .fold<int>(0, (sum, log) => sum + log.cost.costMicros);
  }
}
