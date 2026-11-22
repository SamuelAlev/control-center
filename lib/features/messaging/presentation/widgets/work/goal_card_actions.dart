import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The goal controls a card offers, each one server call. A refusal shows its
// sentence by `data.kind` (`goal_not_yours`, `goal_not_in_review`, …); success
// needs no local state, the next watch tick shows it.

/// Pauses [goal] (`agentGoalRuns.pause`).
Future<void> goalCardPause(
  BuildContext context,
  WidgetRef ref,
  AgentGoalRun goal,
) => _run(
  context,
  () => ref
      .read(agentGoalRunRepositoryProvider)
      .pauseGoal(goal.workspaceId, goal.id),
);

/// Resumes [goal]; [raiseCostCapMicros] raises its budget first.
Future<void> goalCardResume(
  BuildContext context,
  WidgetRef ref,
  AgentGoalRun goal, {
  int? raiseCostCapMicros,
}) => _run(
  context,
  () => ref
      .read(agentGoalRunRepositoryProvider)
      .resumeGoal(
        goal.workspaceId,
        goal.id,
        raiseCostCapMicros: raiseCostCapMicros,
      ),
);

/// Stops [goal] for good (`agentGoalRuns.cancel`).
Future<void> goalCardCancel(
  BuildContext context,
  WidgetRef ref,
  AgentGoalRun goal,
) => _run(
  context,
  () => ref
      .read(agentGoalRunRepositoryProvider)
      .cancelGoal(goal.workspaceId, goal.id),
);

/// Closes a goal waiting for review as done on the person's word, after
/// they confirm that nothing verified it (`agentGoalRuns.approveCompletion`).
Future<void> goalCardApprove(
  BuildContext context,
  WidgetRef ref,
  AgentGoalRun goal,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.goalCardApproveTitle,
      content: Text(l10n.goalCardApproveBody),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.goalCardApproveConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await _run(
    context,
    () => ref
        .read(agentGoalRunRepositoryProvider)
        .approveCompletion(goal.workspaceId, goal.id),
  );
}

Future<void> _run(BuildContext context, Future<Object?> Function() call) async {
  try {
    await call();
  } on Object catch (e) {
    if (context.mounted) {
      showWorkFailure(context, e);
    }
  }
}
