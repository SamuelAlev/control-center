import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/shared/editor/editor_tab.dart';

/// Max characters of a run label shown in the tab strip. Run summaries are
/// already clipped to 60 upstream; a strip needs far less.
const int kAgentActivityTabLabelMax = 28;

/// The dedupe/focus key for a run's activity tab — one tab per RUN.
String agentActivityDedupKey(String runId) => 'agentActivity:$runId';

/// Builds the editor tab for one agent run's activity timeline.
///
/// Every arg is a primitive String so the layout codec can round-trip it (it
/// drops a tab holding any non-primitive value — see `editor_layout_snapshot`).
/// [workspaceId] and [channelId] make the tab self-describing after a restore,
/// so it never has to reach for whatever conversation happens to be selected.
EditorTab agentActivityTab({
  required String workspaceId,
  required String channelId,
  required String runId,
  required String agentId,
  required String label,
  required String fallbackLabel,
}) {
  final trimmed = label.trim();
  final resolved = trimmed.isEmpty ? fallbackLabel : trimmed;
  return EditorTab(
    kind: MessagingTabKinds.agentActivity,
    label: resolved.length <= kAgentActivityTabLabelMax
        ? resolved
        : '${resolved.substring(0, kAgentActivityTabLabelMax - 1)}…',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.agentActivity),
    dedupKey: agentActivityDedupKey(runId),
    args: {
      'workspaceId': workspaceId,
      'channelId': channelId,
      'runId': runId,
      'agentId': agentId,
      // Kept so the strip reads correctly before any data lands and after a
      // restore even when the run row is gone.
      'label': resolved,
    },
  );
}
