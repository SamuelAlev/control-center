/// A single audit-trail entry (domain view over the `activity_log` row), so
/// presentation can render the trail without importing the database layer.
class ActivityEntry {
  /// Creates an [ActivityEntry].
  const ActivityEntry({
    required this.id,
    required this.actorType,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.actorId,
    this.entityId,
    this.details,
    this.workspaceId,
    this.runId,
  });

  /// Unique id.
  final String id;

  /// Actor type (`agent` / `user` / `system`).
  final String actorType;

  /// The action performed (e.g. `ticket_assigned`, `run_completed`).
  final String action;

  /// Entity type acted on (`ticket` / `run` / `orchestration`).
  final String entityType;

  /// When it happened.
  final DateTime createdAt;

  /// Acting agent id, if any.
  final String? actorId;

  /// Entity id acted on, if any.
  final String? entityId;

  /// Optional details.
  final String? details;

  /// Workspace scope, if any.
  final String? workspaceId;

  /// Run id that produced this entry, if any.
  final String? runId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, createdAt);
}
