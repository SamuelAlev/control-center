import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card.dart';
import 'package:control_center/features/todos/providers/goal_run_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The conversation's durable supervised goals, one [GoalCard] each. Hidden
/// entirely when the conversation has none: the section appears once a
/// `/goal` or `/loop` is standing.
class GoalsSection extends ConsumerWidget {
  /// Creates a [GoalsSection].
  const GoalsSection({
    super.key,
    required this.conversationId,
    required this.workspaceId,
  });

  /// The conversation whose goals are shown.
  final String conversationId;

  /// The active workspace.
  final String workspaceId;

  /// Terminal goals stay visible for a glance at what just finished, capped so
  /// history never crowds out the live goals.
  static const visibleTerminalGoals = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final views =
        ref
            .watch(conversationAgentGoalRunsProvider(conversationId))
            .asData
            ?.value ??
        const <GoalRunView>[];
    if (views.isEmpty) {
      return const SizedBox.shrink();
    }

    final live = views.where((v) => !v.goal.status.isTerminal).toList();
    final terminal = views.where((v) => v.goal.status.isTerminal).toList()
      ..sort((a, b) => b.goal.updatedAt.compareTo(a.goal.updatedAt));
    final visible = [...live, ...terminal.take(visibleTerminalGoals)];

    return CollapsibleSidebarSection(
      icon: AppIcons.target,
      label: l10n.generalSectionGoals,
      count: live.isEmpty ? null : '${live.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final view in visible)
            GoalCard(key: ValueKey(view.goal.id), view: view),
        ],
      ),
    );
  }
}
