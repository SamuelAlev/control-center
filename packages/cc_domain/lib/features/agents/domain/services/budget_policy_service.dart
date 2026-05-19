import 'dart:async';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';

/// Encapsulates a budget enforcement decision — why an invocation was blocked.
class BudgetBlock {
  /// Creates a budget block with a [reason], optional [scopeType] and [scopeId].
  const BudgetBlock({
    required this.reason,
    this.scopeType,
    this.scopeId,
  });
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
  /// and [monthlyBudgetCents], plus optional thresholds and tracking fields.
  const BudgetPolicy({
    required this.id,
    required this.scopeType,
    required this.scopeId,
    required this.monthlyBudgetCents,
    this.softThresholdPercent = 80,
    this.hardStopEnabled = true,
    this.spentCents = 0,
    this.status = 'active',
    this.periodStart,
    this.periodEnd,
    this.createdAt,
  });

  /// Unique identifier for this policy.
  final String id;
  /// Type of scope this policy applies to (e.g. "agent", "workspace").
  final String scopeType;
  /// Identifier of the scope this policy governs.
  final String scopeId;
  /// Monthly budget in cents (0 or negative means unlimited).
  final int monthlyBudgetCents;
  /// Percentage of budget at which a soft threshold warning fires.
  final int softThresholdPercent;
  /// Whether to hard-stop invocations when the budget is exhausted.
  final bool hardStopEnabled;
  /// Total cents spent in the current billing period.
  final int spentCents;
  /// Current status of this budget policy ('active', 'paused', etc.).
  final String status;
  /// Start of the current billing period.
  final DateTime? periodStart;
  /// End of the current billing period.
  final DateTime? periodEnd;
  /// When this policy was created.
  final DateTime? createdAt;

  /// Whether this policy has no spending limit.
  bool get isUnlimited => monthlyBudgetCents <= 0;

  /// Whether the budget has been fully consumed.
  bool get isExhausted =>
      spentCents >= monthlyBudgetCents && monthlyBudgetCents > 0;

  /// Whether spending has crossed the soft threshold.
  bool get isNearLimit =>
      monthlyBudgetCents > 0 &&
      spentCents >= (monthlyBudgetCents * softThresholdPercent ~/ 100);

  /// Cents remaining before the budget is exhausted.
  int get remainingCents => monthlyBudgetCents - spentCents;

  /// Percentage of the budget that has been spent (0–100).
  int get spentPercent {
    if (monthlyBudgetCents <= 0) {
      return 0;
    }
    return ((spentCents * 100) ~/ monthlyBudgetCents).clamp(0, 100);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPolicy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          scopeType == other.scopeType &&
          scopeId == other.scopeId &&
          monthlyBudgetCents == other.monthlyBudgetCents &&
          softThresholdPercent == other.softThresholdPercent &&
          hardStopEnabled == other.hardStopEnabled &&
          spentCents == other.spentCents &&
          status == other.status &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    scopeType,
    scopeId,
    monthlyBudgetCents,
    softThresholdPercent,
    hardStopEnabled,
    spentCents,
    status,
    periodStart,
    periodEnd,
    createdAt,
  );

  /// Returns a copy of this policy with the given fields replaced.
  BudgetPolicy copyWith({
    String? id,
    String? scopeType,
    String? scopeId,
    int? monthlyBudgetCents,
    int? softThresholdPercent,
    bool? hardStopEnabled,
    int? spentCents,
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
      scopeType: scopeType ?? this.scopeType,
      scopeId: scopeId ?? this.scopeId,
      monthlyBudgetCents: monthlyBudgetCents ?? this.monthlyBudgetCents,
      softThresholdPercent: softThresholdPercent ?? this.softThresholdPercent,
      hardStopEnabled: hardStopEnabled ?? this.hardStopEnabled,
      spentCents: spentCents ?? this.spentCents,
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
    required AgentRunLogRepository agentRunLogRepository,
    required AgentRepository agentRepository,
    required DomainEventBus eventBus,
  })  : _agentRunLogRepository = agentRunLogRepository,
        _agentRepository = agentRepository,
        _eventBus = eventBus;

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
    final agent = await _agentRepository.getById(agentId);
    if (agent == null) {
      CcDomainLog.warning('$_tag: Agent not found: $agentId');
      return BudgetBlock(
        reason: 'agent_not_found',
        scopeType: 'agent',
        scopeId: agentId,
      );
    }

    if (agent.monthlyBudgetCents <= 0) {
      return null;
    }

    final spent = await _currentMonthSpentCents(agent.workspaceId, agentId);

    if (spent >= agent.monthlyBudgetCents) {
      CcDomainLog.warning('$_tag: Budget exhausted for $agentId: $spent / ${agent.monthlyBudgetCents} cents');
      _eventBus.publish(BudgetThresholdCrossed(
        scopeType: 'agent',
        scopeId: agentId,
        spentCents: spent,
        budgetCents: agent.monthlyBudgetCents,
        isHardStop: true,
        occurredAt: DateTime.now(),
      ));
      return BudgetBlock(
        reason: 'budget_exhausted',
        scopeType: 'agent',
        scopeId: agentId,
      );
    }

    final thresholdAmount = agent.monthlyBudgetCents * 80 ~/ 100;
    if (spent >= thresholdAmount) {
      CcDomainLog.warning('$_tag: Budget near limit for $agentId: $spent / ${agent.monthlyBudgetCents} cents');
      _eventBus.publish(BudgetThresholdCrossed(
        scopeType: 'agent',
        scopeId: agentId,
        spentCents: spent,
        budgetCents: agent.monthlyBudgetCents,
        isHardStop: false,
        occurredAt: DateTime.now(),
      ));
    }

    return null;
  }

  /// Returns the percentage of the monthly budget spent by [agentId] (0–100).
  Future<int> getSpentPercent(String agentId) async {
    final agent = await _agentRepository.getById(agentId);
    if (agent == null || agent.monthlyBudgetCents <= 0) {
      return 0;
    }

    final spent = await _currentMonthSpentCents(agent.workspaceId, agentId);
    return ((spent * 100) ~/ agent.monthlyBudgetCents).clamp(0, 100);
  }

  Future<int> _currentMonthSpentCents(
    String workspaceId,
    String agentId,
  ) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final logs =
        await _agentRunLogRepository.watchByAgent(workspaceId, agentId).first;

    return logs
        .where(
          (log) =>
              log.startedAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) ||
              log.startedAt.isAtSameMomentAs(monthStart),
        )
        .fold<int>(0, (sum, log) => sum + log.cost.estimatedCostCents);
  }
}
