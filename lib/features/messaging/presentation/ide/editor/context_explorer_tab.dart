import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/context_explorer_pane.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/widgets.dart';

/// Builds the editor tab that hosts the context explorer for one
/// (space, conversation, agent) tuple. Re-opening the same conversation
/// refocuses its tab; another conversation gets its own inspection.
EditorTab contextExplorerTab({
  required String workspaceId,
  required String spaceId,
  required String conversationId,
  required String agentId,
  required String label,
}) => EditorTab(
  kind: MessagingTabKinds.contextExplorer,
  label: label,
  icon: MessagingTabKinds.iconFor(MessagingTabKinds.contextExplorer),
  dedupKey: 'contextExplorer:$spaceId:$conversationId:$agentId',
  // The workspace rides along so a restored layout can be checked against the
  // active workspace before it renders (the same guard the artifact tab makes).
  args: {
    'workspaceId': workspaceId,
    'spaceId': spaceId,
    'conversationId': conversationId,
    'agentId': agentId,
  },
);

/// Opens the context explorer for ([spaceId], [conversationId], [agentId]) on
/// a surface of its own.
///
/// Inside the messaging IDE that is a new editor tab next to the
/// conversation the meter belongs to. On a surface with no host layout it
/// falls back to a modal, since the explorer has no route of its own: the
/// action must never dead-end on the button.
///
/// [agentName] labels the tab `Context · <name>`. Pass it whenever the space
/// holds more than one agent: the name identifies whose window this is,
/// including when explorers for multiple agents sit side by side.
void openContextExplorer(
  BuildContext context, {
  required String workspaceId,
  required String spaceId,
  required String conversationId,
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
        conversationId: conversationId,
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
          conversationId: conversationId,
          agentId: agentId,
        ),
      ),
    ),
  );
}
