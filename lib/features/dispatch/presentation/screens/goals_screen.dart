import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goals_list.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';

/// Goals: every durable goal of the workspace, and one goal's page.
///
/// The list and a goal are sibling routes sharing one page, so the list
/// stays mounted under an open goal and Back returns to it as it was.
class GoalsScreen extends StatelessWidget {
  /// Creates the screen, showing goal [goalId] when given.
  const GoalsScreen({super.key, this.goalId, this.openContractEditor = false});

  /// The open goal, or null for the list.
  final String? goalId;

  /// Whether the link asked to open the goal's contract editor at once
  /// ([goalContractEditQuery]).
  final bool openContractEditor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final id = goalId;
    return PageWrapper(
      title: l10n.goalsTitle,
      subtitle: l10n.goalsSubtitle,
      child: IndexedStack(
        index: id == null ? 0 : 1,
        sizing: StackFit.expand,
        children: [
          GoalsList(workspaceId: workspaceId),
          if (id == null)
            const SizedBox.shrink()
          else
            GoalPage(
              key: ValueKey(id),
              workspaceId: workspaceId,
              goalId: id,
              openContractEditor: openContractEditor,
            ),
        ],
      ),
    );
  }
}
