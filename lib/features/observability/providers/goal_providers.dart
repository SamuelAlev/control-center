import 'dart:convert';

import 'package:cc_domain/features/observability/domain/goal_budget.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/observability/providers/observability_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Goal Mode providers (PRD 06, feature #6) ─────────────────────────────────
//
// A goal carries an objective + an optional token budget. Its token consumption
// is tracked CLIENT-SIDE by summing `goalTokenDelta` (input + output +
// cacheWrite, excluding cacheRead) over every run started since the goal began,
// so the budget bar fills and flips to "budget-limited" at the threshold as
// agents run — without any new persisted surface. (Live in-dispatch steering of
// the running agent is wired separately in the dispatch service.)

/// The pure-domain goal budget tracker (steers the model to wrap up at 88%).
final goalBudgetTrackerProvider = Provider<GoalBudgetTracker>(
  (ref) => const GoalBudgetTracker(),
);

String _goalKey(String workspaceId) => 'observability_goal_$workspaceId';

/// Persisted goal *definition* (objective + budget + start time) for the active
/// workspace. Live token usage is layered on by [activeWorkspaceGoalProvider].
///
/// Scoped to the active workspace: [build] reads `activeWorkspaceIdProvider`, so
/// switching workspaces re-resolves to that workspace's own goal.
class WorkspaceGoalController extends Notifier<Goal?> {
  @override
  Goal? build() {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }
    final raw = ref
        .watch(appPreferencesProvider)
        .getString(_goalKey(workspaceId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final created = DateTime.fromMillisecondsSinceEpoch(
        (j['createdAtMs'] as num?)?.toInt() ?? 0,
      );
      return Goal(
        id: j['id'] as String? ?? '$workspaceId-goal',
        workspaceId: workspaceId,
        objective: j['objective'] as String? ?? '',
        status:
            GoalStatus.values.where((s) => s.name == j['status']).firstOrNull ??
            GoalStatus.active,
        tokenBudget: (j['tokenBudget'] as num?)?.toInt(),
        tokensUsed: 0,
        timeUsedSeconds: 0,
        createdAt: created,
        updatedAt: created,
      );
    } on Object {
      return null;
    }
  }

  /// Starts a new goal for the active workspace (replacing any existing one).
  Future<void> setGoal({required String objective, int? tokenBudget}) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final now = DateTime.now();
    final goal = Goal(
      id: 'goal-${now.microsecondsSinceEpoch}',
      workspaceId: workspaceId,
      objective: objective.trim(),
      status: GoalStatus.active,
      tokenBudget: tokenBudget,
      tokensUsed: 0,
      timeUsedSeconds: 0,
      createdAt: now,
      updatedAt: now,
    );
    state = goal;
    await ref
        .read(appPreferencesProvider)
        .setString(
          _goalKey(workspaceId),
          jsonEncode({
            'id': goal.id,
            'objective': goal.objective,
            'status': goal.status.name,
            'tokenBudget': goal.tokenBudget,
            'createdAtMs': goal.createdAt.millisecondsSinceEpoch,
          }),
        );
  }

  /// Drops the active workspace's goal.
  Future<void> clear() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    state = null;
    await ref.read(appPreferencesProvider).remove(_goalKey(workspaceId));
  }
}

/// The persisted goal definition for the active workspace (or null).
final workspaceGoalControllerProvider =
    NotifierProvider<WorkspaceGoalController, Goal?>(
      WorkspaceGoalController.new,
    );

/// The active workspace's goal with LIVE token usage layered on from run logs
/// started since the goal began, and the status flipped to `budgetLimited`
/// once the budget is exhausted. Null when no goal is set.
final activeWorkspaceGoalProvider = Provider.autoDispose<Goal?>((ref) {
  final base = ref.watch(workspaceGoalControllerProvider);
  if (base == null) {
    return null;
  }
  final runs = ref.watch(workspaceRunLogsProvider);
  var used = 0;
  for (final run in runs) {
    if (run.startedAt.isBefore(base.createdAt)) {
      continue;
    }
    used += goalTokenDelta(
      input: run.cost.inputTokens,
      output: run.cost.outputTokens + run.cost.thoughtTokens,
      cacheWrite: run.cost.cachedWriteTokens,
    );
  }
  final budget = base.tokenBudget;
  final exhausted = budget != null && used >= budget;
  return base.copyWith(
    tokensUsed: used,
    timeUsedSeconds: DateTime.now().difference(base.createdAt).inSeconds,
    status: exhausted && base.status == GoalStatus.active
        ? GoalStatus.budgetLimited
        : base.status,
    updatedAt: DateTime.now(),
  );
});

/// Whether the active goal has crossed its steer threshold (≥88% of budget) and
/// the agent should be nudged to wrap up.
final goalShouldSteerProvider = Provider.autoDispose<bool>((ref) {
  final goal = ref.watch(activeWorkspaceGoalProvider);
  if (goal == null || goal.tokenBudget == null) {
    return false;
  }
  final tracker = ref.watch(goalBudgetTrackerProvider);
  final fraction = goal.budgetFraction ?? 0;
  return fraction >= tracker.steerThresholdFraction;
});
