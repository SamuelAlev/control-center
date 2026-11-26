/// A goal's status and what happens next, in words.
library;

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// A goal's status, as a tag label.
String goalStatusLabel(AppLocalizations l10n, AgentGoalStatus status) =>
    switch (status) {
      AgentGoalStatus.active => l10n.goalRunStatusActive,
      AgentGoalStatus.paused => l10n.goalRunStatusPaused,
      AgentGoalStatus.completed => l10n.goalRunStatusCompleted,
      AgentGoalStatus.failed => l10n.goalRunStatusFailed,
      AgentGoalStatus.cancelled => l10n.goalRunStatusCancelled,
      AgentGoalStatus.budgetExhausted => l10n.goalRunStatusBudgetExhausted,
    };

/// A goal's status, as a tag tone.
CcStatusTone goalStatusTone(AgentGoalStatus status) => switch (status) {
  AgentGoalStatus.active => CcStatusTone.positive,
  AgentGoalStatus.paused => CcStatusTone.caution,
  AgentGoalStatus.completed => CcStatusTone.neutral,
  AgentGoalStatus.failed ||
  AgentGoalStatus.budgetExhausted => CcStatusTone.negative,
  AgentGoalStatus.cancelled => CcStatusTone.neutral,
};

/// Whether [goal] still runs or may run again (active or paused).
bool goalIsOpen(AgentGoalRun goal) =>
    goal.status == AgentGoalStatus.active ||
    goal.status == AgentGoalStatus.paused;

/// What happens next to [goal], in one sentence; null once it ended.
String? goalNextSentence(BuildContext context, AgentGoalRun goal) {
  final l10n = AppLocalizations.of(context);
  if (!goalIsOpen(goal)) {
    return null;
  }
  final until = goal.holdUntil;
  return switch (goal.hold) {
    // The server sends when the doubling fallback looks again; what the
    // goal waits on may arrive sooner.
    GoalHold.waiting when until != null => l10n.goalNextWaitingFallback(
      workTimeLabel(context, until),
    ),
    GoalHold.waiting => l10n.goalNextWaiting,
    GoalHold.verifying => l10n.goalNextVerifying,
    GoalHold.limit => l10n.goalNextLimit,
    GoalHold.person => l10n.goalNextPerson,
    GoalHold.byPerson => l10n.goalNextByPerson,
    GoalHold.needsReview => l10n.goalNextNeedsReview,
    null when goal.status == AgentGoalStatus.paused => l10n.goalNextByPerson,
    null => l10n.goalNextWorking,
  };
}
