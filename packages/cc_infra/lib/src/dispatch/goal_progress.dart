import 'dart:collection';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/worktree_fingerprint_port.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/dispatch/goal_activity.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// What one segment changed, as the server observed it (never as the agent
/// reported it): the plan's section 8 with amendment A2.
class GoalProgress {
  /// Creates the observation.
  const GoalProgress({
    required this.progressed,
    required this.fingerprint,
    required this.activityDigest,
    required this.checklistDigest,
    required this.reasons,
  });

  /// Whether the segment made progress.
  final bool progressed;

  /// The worktree fingerprint after the segment (to store as
  /// `lastFingerprint`); null without a worktree.
  final String? fingerprint;

  /// The digest to store as `lastActivityDigest`: this segment's, or the
  /// previous one when this segment made no state-changing call.
  final String? activityDigest;

  /// The checklist after the segment (for the segment's progress mark);
  /// null without a checklist.
  final String? checklistDigest;

  /// What counted, for the log and the tests: `worktree`, `checklist`,
  /// `tools`.
  final List<String> reasons;
}

/// Observes a segment's progress, counting only what the segment itself
/// did:
///
/// - the worktree fingerprint ([WorktreeFingerprintPort]) differs from the
///   goal's `lastFingerprint` and the segment made at least one successful
///   state-changing call (the worktree is the space's, which other agents
///   change too; a segment whose calls were not recorded, the server having
///   restarted in between, is not held against this);
/// - an item of the conversation's checklist was completed or added during
///   the segment, and the segment's own calls include a successful
///   checklist write when its calls were recorded (a checklist row does not
///   record which run wrote it);
/// - a state-changing tool call succeeded and the segment's state-changing
///   calls differ from the previous segment's (`lastActivityDigest`).
///
/// Any one is progress, except that a segment that made no tool call at all
/// never is. Whether the state reached was seen before is the supervisor's
/// to decide (`GoalProgressMarks`).
class GoalProgressObserver {
  /// Creates the observer.
  GoalProgressObserver({
    required this.fingerprints,
    required this.todos,
    required this.activity,
    required this.mcpClassesOf,
  });

  /// The conversation's worktree fingerprint.
  final WorktreeFingerprintPort fingerprints;

  /// The conversation's checklist; null where none is kept.
  final TodoRepository? todos;

  /// The runs' tool calls.
  final RunToolActivity activity;

  /// The MCP registry's effect classes of a first-party tool; null when it
  /// does not know the name.
  final Set<ActionClass>? Function(String bareName) mcpClassesOf;

  /// The most segment-start checklist snapshots kept.
  static const int _maxSnapshots = 256;

  final LinkedHashMap<String, List<TodoItem>> _checklistAtStart =
      LinkedHashMap();

  /// The worktree fingerprint of [goal]'s conversation now (stored when the
  /// goal starts, so its first segment is compared against the worktree it
  /// started from).
  Future<String?> fingerprintOf(AgentGoalRun goal) async {
    try {
      return await fingerprints.fingerprint(
        workspaceId: goal.workspaceId,
        conversationId: goal.conversationId,
      );
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: fingerprint failed: $e');
      return null;
    }
  }

  /// The digest of [goal]'s checklist now (null without one): the start's
  /// part of the goal's first progress mark.
  Future<String?> checklistDigestOf(AgentGoalRun goal) async {
    final items = await _checklist(goal);
    return items == null ? null : _digestOf(items);
  }

  /// Remembers [goal]'s checklist as segment [runId] starts.
  Future<void> segmentStarted(AgentGoalRun goal, String runId) async {
    final items = await _checklist(goal);
    if (items == null) {
      return;
    }
    _checklistAtStart[_key(goal.workspaceId, runId)] = items;
    while (_checklistAtStart.length > _maxSnapshots) {
      _checklistAtStart.remove(_checklistAtStart.keys.first);
    }
  }

  /// Observes segment [runId] of [goal] (the goal as read before the
  /// segment's outcome is written), which started at [runStartedAt].
  Future<GoalProgress> observe(
    AgentGoalRun goal, {
    required String runId,
    required DateTime? runStartedAt,
  }) async {
    final calls = activity.take(workspaceId: goal.workspaceId, runId: runId);
    final segmentActivity = calls == null
        ? null
        : SegmentActivity.of(calls, mcpClassesOf: mcpClassesOf);
    final fingerprint = await fingerprintOf(goal);
    final items = await _checklist(goal);
    final reasons = <String>[];
    if (fingerprint != null &&
        fingerprint != goal.lastFingerprint &&
        (segmentActivity == null || segmentActivity.anySucceededChange)) {
      reasons.add('worktree');
    }
    final before = _checklistAtStart.remove(_key(goal.workspaceId, runId));
    final wroteChecklist =
        calls == null ||
        calls.any((c) => c.ok && bareToolName(c.name) == checklistWriteTool);
    if (items != null &&
        wroteChecklist &&
        _completedOrAdded(before, items, runStartedAt)) {
      reasons.add('checklist');
    }
    if (segmentActivity?.progressAgainst(goal.lastActivityDigest) ?? false) {
      reasons.add('tools');
    }
    // A2: a segment that called no tool at all changed nothing itself.
    final silent = segmentActivity != null && !segmentActivity.anyCall;
    return GoalProgress(
      progressed: !silent && reasons.isNotEmpty,
      fingerprint: fingerprint ?? goal.lastFingerprint,
      activityDigest: segmentActivity?.digest ?? goal.lastActivityDigest,
      checklistDigest: items == null ? null : _digestOf(items),
      reasons: silent ? const [] : reasons,
    );
  }

  /// The tool that writes the conversation's checklist.
  static const String checklistWriteTool = 'todo_write';

  /// Whether an item of [now] was completed or added since [before] (the
  /// checklist as the segment started) or, without it (the server restarted
  /// meanwhile), after [runStartedAt]. A reworded, reordered or reopened
  /// item is neither.
  static bool _completedOrAdded(
    List<TodoItem>? before,
    List<TodoItem> now,
    DateTime? runStartedAt,
  ) {
    if (before != null) {
      final was = {for (final item in before) item.content: item.status};
      return now.any(
        (item) =>
            !was.containsKey(item.content) ||
            (item.status == TodoStatus.completed &&
                was[item.content] != TodoStatus.completed),
      );
    }
    final since = runStartedAt;
    return since != null &&
        now.any(
          (item) =>
              !item.createdAt.isBefore(since) ||
              (item.status == TodoStatus.completed &&
                  !item.updatedAt.isBefore(since)),
        );
  }

  Future<List<TodoItem>?> _checklist(AgentGoalRun goal) async {
    final repo = todos;
    if (repo == null) {
      return null;
    }
    try {
      return await repo.list(goal.workspaceId, goal.conversationId);
    } on Object catch (e) {
      CcInfraLog.warning('goal ${goal.id}: checklist read failed: $e');
      return null;
    }
  }

  static String _digestOf(List<TodoItem> items) => canonicalHash([
    for (final item in items) [item.content, item.status.name],
  ]);

  static String _key(String workspaceId, String runId) =>
      '$workspaceId\u0000$runId';
}
