import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/shared/editor/editor_tab.dart';

const int _maxLabelLength = 28;

/// Collision-free identity across spaces and workspaces, even for opaque ids
/// containing punctuation used by the URL tab key.
String agentShellOutputDedupKey({
  required String workspaceId,
  required String spaceId,
  required String outputId,
}) =>
    '${MessagingTabKinds.agentShellOutput}:'
    '${workspaceId.length}:$workspaceId:${spaceId.length}:$spaceId:$outputId';

/// A captured command's read-only output tab. Never restores after a restart.
EditorTab agentShellOutputTab({
  required AgentShellProcess process,
  required String fallbackLabel,
}) {
  final firstLine = process.command.split('\n').first.trim();
  final label = firstLine.isEmpty ? fallbackLabel : firstLine;
  return EditorTab(
    kind: MessagingTabKinds.agentShellOutput,
    label: label.length <= _maxLabelLength
        ? label
        : '${label.substring(0, _maxLabelLength - 1)}…',
    icon: MessagingTabKinds.iconFor(MessagingTabKinds.agentShellOutput),
    dedupKey: agentShellOutputDedupKey(
      workspaceId: process.workspaceId,
      spaceId: process.spaceId,
      outputId: process.outputId,
    ),
    args: {
      'workspaceId': process.workspaceId,
      'spaceId': process.spaceId,
      'outputId': process.outputId,
      'command': process.command,
    },
  );
}
