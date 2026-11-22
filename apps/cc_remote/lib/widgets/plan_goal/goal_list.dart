import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/widgets/plan_goal/goal_create.dart';
import 'package:cc_remote/widgets/plan_goal/goal_detail.dart';
import 'package:cc_remote/widgets/plan_goal/goal_hold_line.dart';
import 'package:cc_remote/widgets/plan_goal/schedule_create.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Which creation form the goals screen shows.
enum PhoneGoalsForm { goal, schedule }

/// Workspace or conversation goal inventory: goals that wait for a person
/// first, then live goals, then ended ones. Each row says what the goal is
/// doing in words. The header starts a goal or a schedule ("Repeat") and
/// opens the schedules list.
class PhoneGoalsList extends StatelessWidget {
  const PhoneGoalsList({
    super.key,
    required this.goals,
    required this.workspaceId,
    required this.conversationId,
    required this.writable,
    required this.form,
    required this.onForm,
  });

  final List<GoalRunView> goals;
  final String workspaceId;
  final String? conversationId;
  final bool writable;
  final PhoneGoalsForm? form;
  final ValueChanged<PhoneGoalsForm> onForm;

  static int _rank(GoalRunView v) => goalNeedsPerson(v.goal)
      ? 0
      : v.goal.status.isTerminal
      ? 2
      : 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final sorted = [...goals]
      ..sort((a, b) {
        final priority = _rank(a).compareTo(_rank(b));
        return priority != 0
            ? priority
            : b.goal.updatedAt.compareTo(a.goal.updatedAt);
      });
    Widget toggle(PhoneGoalsForm which, String label) => CcButton(
      size: CcButtonSize.lg,
      variant: form == which
          ? CcButtonVariant.primary
          : CcButtonVariant.secondary,
      onPressed: () => onForm(which),
      child: Text(form == which ? l10n.cancel : label),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.mobileGoalsTitle,
          style: CcTypography.title.copyWith(color: t.textPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (writable) toggle(PhoneGoalsForm.goal, l10n.mobileGoalCreate),
            if (writable) toggle(PhoneGoalsForm.schedule, l10n.goalRepeat),
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.ghost,
              icon: AppIcons.repeat,
              onPressed: () => context.push(
                remoteWorkspaceLocation('/schedules', workspaceId),
              ),
              child: Text(l10n.goalSchedules),
            ),
          ],
        ),
        if (writable && form == PhoneGoalsForm.goal) ...[
          const SizedBox(height: 16),
          PhoneGoalCreate(
            key: ValueKey('goal:$workspaceId:${conversationId ?? ''}'),
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
        ],
        if (writable && form == PhoneGoalsForm.schedule) ...[
          const SizedBox(height: 16),
          PhoneScheduleCreate(
            key: ValueKey('schedule:$workspaceId:${conversationId ?? ''}'),
            workspaceId: workspaceId,
            conversationId: conversationId,
          ),
        ],
        const SizedBox(height: 20),
        if (sorted.isEmpty) ...[
          const SizedBox(height: 48),
          CcEmptyState(
            icon: AppIcons.circleDot,
            message: l10n.mobileGoalsEmpty,
            description: l10n.mobileGoalsEmptyDescription,
          ),
        ],
        for (final view in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GoalRow(view: view, workspaceId: workspaceId),
          ),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.view, required this.workspaceId});

  final GoalRunView view;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final goal = view.goal;
    final caption = CcTypography.caption.copyWith(color: t.textSecondary);
    return CcCard(
      interactive: true,
      semanticLabel: inertText(goal.userText, singleLine: true),
      onPressed: () => context.push(
        remoteWorkspaceLocation(
          '/goals/${Uri.encodeComponent(goal.id)}',
          workspaceId,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            inertText(goal.userText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: CcTypography.body.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CcBadge(
                label: phoneGoalStatus(l10n, goal.status),
                variant: phoneGoalStatusVariant(goal.status),
              ),
              Text(
                goal.maxRuns == null
                    ? l10n.goalSegmentsNoCap(goal.runCount)
                    : l10n.goalSegments(goal.runCount, goal.maxRuns!),
                style: caption,
              ),
              Text(shortDate(context, goal.updatedAt), style: caption),
            ],
          ),
          if (goalHoldSentence(context, goal) != null) ...[
            const SizedBox(height: 8),
            GoalHoldLine(goal: goal, compact: true),
          ],
        ],
      ),
    );
  }
}
