import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';

/// A node in the organizational goal hierarchy (company → team → agent → task).
///
/// A goal cascades from a parent: the company mission is the root
/// ([parentGoalId] is null), team objectives report to it, agent goals to a
/// team and tasks to an agent goal. Progress aggregates upward from task
/// completion. Every goal belongs to exactly one workspace.
class OrgGoal {
  /// Creates an [OrgGoal].
  OrgGoal({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.level,
    this.parentGoalId,
    this.description,
    this.status = OrgGoalStatus.active,
    this.ownerAgentId,
    this.teamId,
    this.targetTicketId,
    this.progress = 0,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (title.isEmpty) {
      throw ArgumentError('Goal title must not be empty');
    }
    if (progress < 0 || progress > 100) {
      throw ArgumentError('progress must be 0..100');
    }
  }

  /// Unique goal identifier.
  final String id;

  /// Owning workspace (the isolation boundary).
  final String workspaceId;

  /// Short goal title.
  final String title;

  /// Level of this goal in the hierarchy.
  final OrgGoalLevel level;

  /// Parent goal id, or null for the company mission (the root).
  final String? parentGoalId;

  /// Optional longer description.
  final String? description;

  /// Lifecycle status.
  final OrgGoalStatus status;

  /// Owning agent (agent/task-level goals), if any.
  final String? ownerAgentId;

  /// Owning team (team-level goals), if any.
  final String? teamId;

  /// Ticket realizing this goal (task-level goals), if any.
  final String? targetTicketId;

  /// Completion percentage (0–100).
  final int progress;

  /// When the goal was created.
  final DateTime createdAt;

  /// When the goal was last updated.
  final DateTime updatedAt;

  /// Whether this is the company-mission root.
  bool get isRoot => parentGoalId == null;

  /// Whether this goal is fully achieved.
  bool get isAchieved => status == OrgGoalStatus.achieved || progress >= 100;

  /// Returns a copy with the given fields replaced.
  OrgGoal copyWith({
    String? id,
    String? workspaceId,
    String? title,
    OrgGoalLevel? level,
    String? parentGoalId,
    bool removeParentGoalId = false,
    String? description,
    bool removeDescription = false,
    OrgGoalStatus? status,
    String? ownerAgentId,
    bool removeOwnerAgentId = false,
    String? teamId,
    bool removeTeamId = false,
    String? targetTicketId,
    bool removeTargetTicketId = false,
    int? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrgGoal(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      level: level ?? this.level,
      parentGoalId: removeParentGoalId
          ? null
          : (parentGoalId ?? this.parentGoalId),
      description: removeDescription ? null : (description ?? this.description),
      status: status ?? this.status,
      ownerAgentId: removeOwnerAgentId
          ? null
          : (ownerAgentId ?? this.ownerAgentId),
      teamId: removeTeamId ? null : (teamId ?? this.teamId),
      targetTicketId: removeTargetTicketId
          ? null
          : (targetTicketId ?? this.targetTicketId),
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          level == other.level &&
          parentGoalId == other.parentGoalId &&
          description == other.description &&
          status == other.status &&
          ownerAgentId == other.ownerAgentId &&
          teamId == other.teamId &&
          targetTicketId == other.targetTicketId &&
          progress == other.progress &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    level,
    parentGoalId,
    description,
    status,
    ownerAgentId,
    teamId,
    targetTicketId,
    progress,
    createdAt,
    updatedAt,
  );
}
