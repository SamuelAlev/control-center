import 'package:control_center/core/domain/events/domain_event_bus.dart';

/// Fired when an activity is logged in the system.
class ActivityLogged implements DomainEvent {
  /// Creates an [ActivityLogged] event.
  const ActivityLogged({
    required this.id,
    required this.actorType,
    this.actorId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    this.workspaceId,
    this.runId,
    required this.occurredAt,
  });

  /// Unique identifier for this log entry.
  final String id;
  /// Type of actor performing the action (e.g. "user", "agent").
  final String actorType;
  /// Identifier of the actor, if known.
  final String? actorId;
  /// The action performed (e.g. "created", "deleted").
  final String action;
  /// Type of entity the action was performed on.
  final String entityType;
  /// Identifier of the entity, if applicable.
  final String? entityId;
  /// Additional context about the activity.
  final String? details;
  /// Workspace this entry is scoped to, when known.
  final String? workspaceId;
  /// Run id that produced this entry, when applicable.
  final String? runId;

  @override
  final DateTime occurredAt;
}

/// Fired when a worktree is merged.
class WorktreeMerged implements DomainEvent {
  /// Creates a [WorktreeMerged] event.
  const WorktreeMerged({
    required this.workspaceId,
    required this.sourceBranch,
    required this.targetBranch,
    this.mergedBy,
    required this.occurredAt,
  });

  /// Identifier of the workspace.
  final String workspaceId;
  /// The branch that was merged from.
  final String sourceBranch;
  /// The branch that was merged into.
  final String targetBranch;
  /// The user or system that performed the merge, if known.
  final String? mergedBy;

  @override
  final DateTime occurredAt;
}

/// Fired when a budget threshold is crossed.
class BudgetThresholdCrossed implements DomainEvent {
  /// Creates a [BudgetThresholdCrossed] event.
  const BudgetThresholdCrossed({
    required this.scopeType,
    required this.scopeId,
    required this.spentCents,
    required this.budgetCents,
    required this.isHardStop,
    required this.occurredAt,
  });

  /// Scope of the budget (e.g. "workspace", "user").
  final String scopeType;
  /// Identifier within the scope.
  final String scopeId;
  /// Amount spent in cents.
  final int spentCents;
  /// Budget limit in cents.
  final int budgetCents;
  /// Whether this is a hard stop or a warning.
  final bool isHardStop;

  @override
  final DateTime occurredAt;
}
