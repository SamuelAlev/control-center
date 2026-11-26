import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds the editor tab that hosts one durable supervised goal (`GoalPage`).
///
/// `dedupKey` is `goal:<goalId>`, so re-opening the same goal from the
/// conversation panel or a notification refocuses one tab instead of stacking
/// duplicates.
EditorTab goalTab({
  required String workspaceId,
  required String goalId,
  required String label,
  bool openContractEditor = false,
}) => EditorTab(
  kind: MessagingTabKinds.goal,
  label: label,
  icon: MessagingTabKinds.iconFor(MessagingTabKinds.goal),
  dedupKey: goalTabKey(goalId),
  args: {
    'workspaceId': workspaceId,
    'goalId': goalId,
    if (openContractEditor) 'openContractEditor': true,
  },
);

/// Opens [goalId] inside its space's editor tabs when hosted inside the
/// messaging IDE, or navigates to the space with `?tab=goal:<goalId>` from any
/// outer surface.
void openGoal(
  BuildContext context, {
  required String workspaceId,
  required String spaceId,
  required String goalId,
  String? title,
  bool openContractEditor = false,
}) {
  final opener = EditorTabOpenerScope.maybeOf(context);
  if (opener != null) {
    opener.open(
      goalTab(
        workspaceId: workspaceId,
        goalId: goalId,
        label: goalTabLabel(context, title),
        openContractEditor: openContractEditor,
      ),
    );
    return;
  }
  context.go(spaceRoute(workspaceId, spaceId, tab: goalTabKey(goalId)));
}

/// Tab-strip label for a goal: its objective sanitized to a single line and
/// clipped to a tab-sized string, falling back to the generic crumb when empty.
String goalTabLabel(BuildContext context, String? title) {
  final trimmed = title == null ? '' : inertText(title, singleLine: true).trim();
  if (trimmed.isEmpty) {
    return AppLocalizations.of(context).goalRecordCrumb;
  }
  const maxChars = 32;
  if (trimmed.length <= maxChars) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxChars).trimRight()}…';
}
