import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';

/// Repository for the organizational goal hierarchy. Every method is
/// workspace-scoped — `workspaceId` is required and never optional.
abstract interface class GoalRepository {
  /// Watches all goals for [workspaceId].
  Stream<List<OrgGoal>> watchByWorkspace(String workspaceId);

  /// Returns all goals for [workspaceId].
  Future<List<OrgGoal>> listByWorkspace(String workspaceId);

  /// Returns the direct children of [parentGoalId] within [workspaceId].
  Future<List<OrgGoal>> childrenOf(String workspaceId, String parentGoalId);

  /// Returns a single goal by [id] within [workspaceId], or null.
  Future<OrgGoal?> getById(String workspaceId, String id);

  /// Inserts or updates a goal.
  Future<void> upsert(OrgGoal goal);

  /// Deletes a goal by [id] within [workspaceId].
  Future<void> delete(String workspaceId, String id);
}
