import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

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

  /// Workspace this entry is scoped to, or null for a server-wide action.
  ///
  /// The second deliberate exception to "workspaceId is required" (see
  /// `ExternalPrDetected` for the first): a server-wide action — boot, an
  /// install-level setting change — genuinely has no workspace, and
  /// `activity_log` rows live in a per-workspace database file, so there is no
  /// default file such a row could go to. `ActivityLogPersister` therefore
  /// DROPS a workspace-less event with a warning rather than misfiling it,
  /// which keeps the gap visible instead of writing an audit row into an
  /// arbitrary workspace.
  final String? workspaceId;

  /// Run id that produced this entry, when applicable.
  final String? runId;

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
