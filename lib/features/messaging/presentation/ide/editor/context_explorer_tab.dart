import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/widgets.dart';

/// Builds the editor tab that hosts the context explorer for one
/// (space, agent) pair.
///
/// `dedupKey` is the pair's identity, so re-opening the explorer from the
/// context meter refocuses one tab instead of stacking copies of the same
/// breakdown.
EditorTab contextExplorerTab({
  required String workspaceId,
  required String spaceId,
  required String agentId,
  required String label,
}) => EditorTab(
  kind: MessagingTabKinds.contextExplorer,
  label: label,
  icon: MessagingTabKinds.iconFor(MessagingTabKinds.contextExplorer),
  dedupKey: 'contextExplorer:$spaceId:$agentId',
  // The workspace rides along so a restored layout can be checked against the
  // active workspace before it renders (the same guard the artifact tab makes).
  args: {'workspaceId': workspaceId, 'spaceId': spaceId, 'agentId': agentId},
);

/// Opens the context explorer for ([spaceId], [agentId]) on a surface of its
/// own.
///
/// Inside the messaging IDE that is a new editor **tab** next to the
/// conversation the meter belongs to. On a surface with no host layout it
/// falls back to a modal, since the explorer has no route of its own: the
/// action must never dead-end on the button.
///
/// [agentName] labels the tab `Context · <name>`. Pass it whenever the space
/// holds more than one agent: the tabs are deduped per (space, agent), so two
/// of them can sit side by side, and a bare "Context" on both would make the
/// pair indistinguishable — the same reason the pane titles itself that way.
void openContextExplorer(
  BuildContext context, {
  required String workspaceId,
  required String spaceId,
  required String agentId,
  String? agentName,
}) {
  final title = AppLocalizations.of(context).contextExplorerTitle;
  final label = agentName == null || agentName.isEmpty
      ? title
      : '$title · $agentName';
  final opener = EditorTabOpenerScope.maybeOf(context);
  if (opener != null) {
    opener.open(
      contextExplorerTab(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: agentId,
        label: label,
      ),
    );
    return;
  }
  showCcDialog<void>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: label,
      maxWidth: 1100,
      onClose: () => Navigator.of(dialogContext).pop(),
      content: SizedBox(
        height: MediaQuery.sizeOf(dialogContext).height * 0.75,
        child: ContextExplorerPane(
          workspaceId: workspaceId,
          spaceId: spaceId,
          agentId: agentId,
        ),
      ),
    ),
  );
}
