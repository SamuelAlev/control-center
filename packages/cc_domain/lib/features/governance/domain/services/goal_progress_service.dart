import 'package:cc_domain/core/domain/services/activity_logger.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:uuid/uuid.dart';

/// Creates goals and keeps progress aggregated upward through the hierarchy.
///
/// A leaf goal's progress is set directly (or derived from its task); a parent
/// goal's progress is the rounded average of its children. Recomputing a goal
/// cascades up to the company mission so the whole tree stays consistent.
class GoalProgressService {
  /// Creates a [GoalProgressService].
  GoalProgressService({
    required GoalRepository repository,
    ActivityLogger? activityLogger,
  }) : _repository = repository,
       _audit = activityLogger;

  final GoalRepository _repository;
  final ActivityLogger? _audit;

  static const _uuid = Uuid();

  /// Creates a goal. Validates that [parentGoalId] (when given) exists in the
  /// same workspace, then recomputes the parent's progress.
  Future<OrgGoal> createGoal({
    required String workspaceId,
    required String title,
    required OrgGoalLevel level,
    String? parentGoalId,
    String? description,
    String? ownerAgentId,
    String? teamId,
    String? targetTicketId,
    int progress = 0,
    String? id,
  }) async {
    if (parentGoalId != null) {
      final parent = await _repository.getById(workspaceId, parentGoalId);
      if (parent == null) {
        throw NotFoundException('Parent goal $parentGoalId not found.');
      }
    }
    final now = DateTime.now();
    final goal = OrgGoal(
      id: id ?? _uuid.v4(),
      workspaceId: workspaceId,
      title: title,
      level: level,
      parentGoalId: parentGoalId,
      description: description,
      ownerAgentId: ownerAgentId,
      teamId: teamId,
      targetTicketId: targetTicketId,
      progress: progress.clamp(0, 100),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(goal);
    _audit?.log(
      actorType: 'system',
      action: 'goal_created',
      entityType: 'goal',
      entityId: goal.id,
      workspaceId: workspaceId,
      details: title,
    );
    if (parentGoalId != null) {
      await recompute(workspaceId, parentGoalId);
    }
    return goal;
  }

  /// Sets a leaf goal's progress directly and cascades the change upward.
  Future<void> setProgress(
    String workspaceId,
    String goalId,
    int progress,
  ) async {
    final goal = await _repository.getById(workspaceId, goalId);
    if (goal == null) {
      throw NotFoundException('Goal $goalId not found.');
    }
    final clamped = progress.clamp(0, 100);
    final updated = goal.copyWith(
      progress: clamped,
      status: clamped >= 100 ? OrgGoalStatus.achieved : goal.status,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    await _propagateUp(workspaceId, goal.parentGoalId);
  }

  /// Sets a goal's lifecycle status and cascades progress upward.
  Future<void> setStatus(
    String workspaceId,
    String goalId,
    OrgGoalStatus status,
  ) async {
    final goal = await _repository.getById(workspaceId, goalId);
    if (goal == null) {
      throw NotFoundException('Goal $goalId not found.');
    }
    final updated = goal.copyWith(
      status: status,
      progress: status == OrgGoalStatus.achieved ? 100 : goal.progress,
      updatedAt: DateTime.now(),
    );
    await _repository.upsert(updated);
    _audit?.log(
      actorType: 'system',
      action: 'goal_${status.name}',
      entityType: 'goal',
      entityId: goalId,
      workspaceId: workspaceId,
    );
    await _propagateUp(workspaceId, goal.parentGoalId);
  }

  /// Recomputes [goalId]'s progress from its children (rounded average) and
  /// cascades upward. A goal with no children keeps its directly-set progress.
  Future<void> recompute(String workspaceId, String goalId) async {
    final goal = await _repository.getById(workspaceId, goalId);
    if (goal == null) {
      return;
    }
    final children = await _repository.childrenOf(workspaceId, goalId);
    if (children.isEmpty) {
      await _propagateUp(workspaceId, goal.parentGoalId);
      return;
    }
    final avg =
        (children.fold<int>(0, (s, c) => s + c.progress) / children.length)
            .round()
            .clamp(0, 100);
    if (avg != goal.progress ||
        (avg >= 100 && goal.status != OrgGoalStatus.achieved)) {
      await _repository.upsert(
        goal.copyWith(
          progress: avg,
          status: avg >= 100 ? OrgGoalStatus.achieved : goal.status,
          updatedAt: DateTime.now(),
        ),
      );
    }
    await _propagateUp(workspaceId, goal.parentGoalId);
  }

  Future<void> _propagateUp(String workspaceId, String? parentGoalId) async {
    if (parentGoalId == null) {
      return;
    }
    await recompute(workspaceId, parentGoalId);
  }
}
