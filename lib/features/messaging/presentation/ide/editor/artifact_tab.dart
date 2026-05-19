import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/artifacts/presentation/widgets/artifact_detail_view.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_opener.dart';
import 'package:flutter/widgets.dart';

/// Builds the editor tab that hosts one artifact at full size.
///
/// `dedupKey` is the artifact's identity, so re-opening the same artifact from
/// the feed and from the sidebar refocuses one tab instead of stacking two
/// copies of the same document.
EditorTab artifactTab({
  required String workspaceId,
  required String workProductId,
  required String label,
}) => EditorTab(
  kind: MessagingTabKinds.artifact,
  label: label,
  icon: MessagingTabKinds.iconFor(MessagingTabKinds.artifact),
  dedupKey: 'artifact:$workProductId',
  // The workspace rides along so a restored layout can be checked against
  // the active workspace before it renders (the same guard the agent
  // activity tab makes).
  args: {'workspaceId': workspaceId, 'workProductId': workProductId},
);

/// Opens [workProductId] on a surface of its own.
///
/// Inside the messaging IDE that is a new editor **tab** next to the
/// conversation the artifact was published into — the preview in the feed stays
/// where it is. On a surface with no host layout (the PR workbench's chat tab, a
/// dialog) it falls back to a modal, since an artifact has no route of its own:
/// the action must never dead-end on the button.
void openArtifact(
  BuildContext context, {
  required String workspaceId,
  required String workProductId,
  String? title,
}) {
  final label = artifactTabLabel(context, title);
  final opener = EditorTabOpenerScope.maybeOf(context);
  if (opener != null) {
    opener.open(
      artifactTab(
        workspaceId: workspaceId,
        workProductId: workProductId,
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
        child: ArtifactDetailView(
          workProductId: workProductId,
          showHeader: false,
        ),
      ),
    ),
  );
}

/// Tab-strip label for an artifact: its title, clipped to a tab-sized string,
/// falling back to the generic noun while the row is still loading.
String artifactTabLabel(BuildContext context, String? title) {
  final trimmed = title?.trim() ?? '';
  if (trimmed.isEmpty) {
    return AppLocalizations.of(context).artifactTitleFallback;
  }
  const maxChars = 32;
  if (trimmed.length <= maxChars) {
    return trimmed;
  }
  return '${trimmed.substring(0, maxChars).trimRight()}…';
}
