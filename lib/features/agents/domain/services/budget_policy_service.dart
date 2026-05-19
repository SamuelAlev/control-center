import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/observability_events.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/utils/app_log.dart';

class BudgetBlock {
  const BudgetBlock({
    required this.reason,
    this.scopeType,
    this.scopeId,
  });

  final String reason;
  final String? scopeType;
  final String? scopeId;
}

class BudgetPolicy {
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

  final String id;
  final String scopeType;
  final String scopeId;
  final int monthlyBudgetCents;
  final int softThresholdPercent;
  final bool hardStopEnabled;
  final int spentCents;
  final String status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? createdAt;

  bool get isUnlimited => monthlyBudgetCents <= 0;

  bool get isExhausted =>
      spentCents >= monthlyBudgetCents && monthlyBudgetCents > 0;

  bool get isNearLimit =>
      monthlyBudgetCents > 0 &&
      spentCents >= (monthlyBudgetCents * softThresholdPercent ~/ 100);

  int get remainingCents => monthlyBudgetCents - spentCents;

  int get spentPercent {
    if (monthlyBudgetCents <= 0) return 0;
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

class BudgetEnforcementService {
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

  Future<BudgetBlock?> checkInvocationBlock({
    required String agentId,
    required String workspaceId,
    String? ticketId,
  }) async {
    final agent = await _agentRepository.getById(agentId);
    if (agent == null) {
      AppLog.w(_tag, 'Agent not found: $agentId');
      return BudgetBlock(
        reason: 'agent_not_found',
        scopeType: 'agent',
        scopeId: agentId,
      );
    }

    if (agent.monthlyBudgetCents <= 0) return null;

    final spent = await _currentMonthSpentCents(agentId);

    if (spent >= agent.monthlyBudgetCents) {
      AppLog.w(_tag, 'Budget exhausted for $agentId: $spent / ${agent.monthlyBudgetCents} cents');
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
      AppLog.w(_tag, 'Budget near limit for $agentId: $spent / ${agent.monthlyBudgetCents} cents');
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

  Future<int> getSpentPercent(String agentId) async {
    final agent = await _agentRepository.getById(agentId);
    if (agent == null || agent.monthlyBudgetCents <= 0) return 0;

    final spent = await _currentMonthSpentCents(agentId);
    return ((spent * 100) ~/ agent.monthlyBudgetCents).clamp(0, 100);
  }

  Future<int> _currentMonthSpentCents(String agentId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final logs = await _agentRunLogRepository.watchByAgent(agentId).first;

    return logs
        .where(
          (log) =>
              log.startedAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) ||
              log.startedAt.isAtSameMomentAs(monthStart),
        )
        .fold<int>(0, (sum, log) => sum + log.cost.estimatedCostCents);
  }
}
