import 'package:control_center/core/domain/events/domain_event_bus.dart';

class ActivityLogged implements DomainEvent {
  const ActivityLogged({
    required this.id,
    required this.actorType,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    required this.occurredAt,
  });

  final String id;
  final String actorType;
  final String? actorId;
  final String action;
  final String entityType;
  final String? entityId;
  final String? details;

  @override
  final DateTime occurredAt;
}

class WorktreeMerged implements DomainEvent {
  const WorktreeMerged({
    required this.workspaceId,
    required this.sourceBranch,
    required this.targetBranch,
    this.mergedBy,
    required this.occurredAt,
  });

  final String workspaceId;
  final String sourceBranch;
  final String targetBranch;
  final String? mergedBy;

  @override
  final DateTime occurredAt;
}

class BudgetThresholdCrossed implements DomainEvent {
  const BudgetThresholdCrossed({
    required this.scopeType,
    required this.scopeId,
    required this.spentCents,
    required this.budgetCents,
    required this.isHardStop,
    required this.occurredAt,
  });

  final String scopeType;
  final String scopeId;
  final int spentCents;
  final int budgetCents;
  final bool isHardStop;

  @override
  final DateTime occurredAt;
}
