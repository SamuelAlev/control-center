import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedules_list.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';

/// Schedules: every schedule, loop and watch of the workspace, and one
/// schedule's page. The list and a schedule are sibling routes sharing one
/// page, so the list stays mounted under an open schedule.
class SchedulesScreen extends StatelessWidget {
  /// Creates the screen, showing schedule [ruleId] when given.
  const SchedulesScreen({super.key, this.ruleId});

  /// The open schedule, or null for the list.
  final String? ruleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final id = ruleId;
    return PageWrapper(
      title: l10n.schedulesTitle,
      subtitle: l10n.schedulesSubtitle,
      child: IndexedStack(
        index: id == null ? 0 : 1,
        sizing: StackFit.expand,
        children: [
          SchedulesList(workspaceId: workspaceId),
          if (id == null)
            const SizedBox.shrink()
          else
            SchedulePage(
              key: ValueKey(id),
              workspaceId: workspaceId,
              ruleId: id,
            ),
        ],
      ),
    );
  }
}
