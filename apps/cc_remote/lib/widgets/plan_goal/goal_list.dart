import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/widgets/plan_goal/goal_create.dart';
import 'package:cc_remote/widgets/plan_goal/goal_detail.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Workspace or conversation goal inventory, sorted with live goals first.
class PhoneGoalsList extends StatelessWidget {
  const PhoneGoalsList({
    super.key,
    required this.goals,
    required this.workspaceId,
    required this.conversationId,
    required this.writable,
    required this.creating,
    required this.onToggleCreate,
  });

  final List<AgentGoalRun> goals;
  final String workspaceId;
  final String? conversationId;
  final bool writable;
  final bool creating;
  final VoidCallback onToggleCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final sorted = [...goals]
      ..sort((a, b) {
        final priority = (a.status.isTerminal ? 1 : 0).compareTo(
          b.status.isTerminal ? 1 : 0,
        );
        return priority != 0 ? priority : b.updatedAt.compareTo(a.updatedAt);
      });
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.mobileGoalsTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
            if (writable)
              CcButton(
                size: CcButtonSize.lg,
                variant: CcButtonVariant.secondary,
                onPressed: onToggleCreate,
                child: Text(creating ? l10n.cancel : l10n.mobileGoalCreate),
              ),
          ],
        ),
        if (creating && writable) ...[
          const SizedBox(height: 16),
          PhoneGoalCreate(
            key: ValueKey('$workspaceId:${conversationId ?? ''}'),
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
        for (final goal in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CcCard(
              interactive: true,
              semanticLabel: goal.userText,
              onPressed: () => context.push(
                remoteWorkspaceLocation(
                  '/goals/${Uri.encodeComponent(goal.id)}',
                  workspaceId,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.circleDot, size: 18, color: t.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.userText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            CcBadge(
                              label: phoneGoalStatus(l10n, goal.status),
                              variant: goal.status == AgentGoalStatus.active
                                  ? CcBadgeVariant.success
                                  : goal.status == AgentGoalStatus.failed
                                  ? CcBadgeVariant.danger
                                  : CcBadgeVariant.neutral,
                            ),
                            Text(
                              l10n.mobileGoalRuns(
                                numbers.format(goal.runCount),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: t.textSecondary,
                              ),
                            ),
                            Text(
                              shortDate(context, goal.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(AppIcons.chevronRight, size: 16, color: t.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
