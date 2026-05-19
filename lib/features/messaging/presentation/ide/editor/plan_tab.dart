import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// The two plan flavours Plan Studio hosts: an agent-authored plan document
/// (`submit_plan`) or an orchestration proposal.
enum PlanTabKind {
  /// A plan-mode document.
  document('document'),

  /// An orchestration proposal.
  orchestration('orchestration');

  const PlanTabKind(this.wire);

  /// The value Plan Studio's route/args use.
  final String wire;
}

/// Builds the editor tab that hosts Plan Studio for one plan.
///
/// `dedupKey` is the plan's identity, so re-opening the same plan refocuses its
/// tab instead of stacking a second copy of the canvas.
EditorTab planStudioTab({
  required PlanTabKind kind,
  required String id,
  required String label,
}) => EditorTab(
  kind: MessagingTabKinds.plan,
  label: label,
  icon: MessagingTabKinds.iconFor(MessagingTabKinds.plan),
  dedupKey: 'plan:${kind.wire}:$id',
  args: {'planKind': kind.wire, 'planId': id},
);

/// Opens Plan Studio for one plan.
///
/// Inside the messaging IDE this is a new editor **tab** next to the
/// conversation that produced the plan — the plan stays where it was authored
/// instead of throwing the operator out to a global page. On a surface with no
/// host layout (the PR workbench's chat tab, a dialog) it falls back to the
/// standalone `/plans/<kind>/<id>` route, which remains a real deep link.
void openPlanStudio(
  BuildContext context, {
  required String workspaceId,
  required PlanTabKind kind,
  required String id,
  String? title,
}) {
  final opener = EditorTabOpenerScope.maybeOf(context);
  if (opener == null) {
    context.go(planStudioRoute(workspaceId, kind.wire, id));
    return;
  }
  opener.open(
    planStudioTab(kind: kind, id: id, label: planTabLabel(context, title)),
  );
}

/// Tab-strip label for a plan: its goal, clipped to a tab-sized string, falling
/// back to the generic studio title when the plan has no usable goal yet.
String planTabLabel(BuildContext context, String? title) {
  final trimmed = title?.trim() ?? '';
  if (trimmed.isEmpty) {
    return AppLocalizations.of(context).planStudioTitle;
  }
  const maxChars = 32;
  if (trimmed.length <= maxChars) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxChars).trimRight()}…';
}
