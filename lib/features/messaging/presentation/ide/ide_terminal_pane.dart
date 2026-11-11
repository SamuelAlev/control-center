import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_terminal_banner.dart';
import 'package:control_center/features/sandboxing/presentation/enclosed_terminal_start.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';

/// The body of a messaging IDE terminal tab: its claimed shell, the Start
/// button of a restored enclosed terminal, or a spinner while the claim lands
/// (see `IdeTerminalSessions`).
class IdeTerminalPane extends StatelessWidget {
  /// Creates the pane for [tab].
  const IdeTerminalPane({
    super.key,
    required this.tab,
    required this.controller,
    required this.awaitsStart,
    required this.onStart,
    required this.onOpenFresh,
  });

  /// The terminal tab.
  final EditorTab tab;

  /// The shell [tab] has claimed, or null while it has none.
  final TerminalSessionController? controller;

  /// Whether [tab] is a restored enclosed terminal waiting for a press.
  final bool awaitsStart;

  /// Starts a waiting enclosed terminal.
  final VoidCallback onStart;

  /// Opens a fresh terminal (a shell older than the environment lacks it).
  final VoidCallback onOpenFresh;

  @override
  Widget build(BuildContext context) {
    final claimed = controller;
    if (claimed != null) {
      final t = context.designSystem ?? DesignSystemTokens.light();
      final view = TerminalSessionView(
        controller: claimed,
        backgroundColor: t.bgPrimary,
      );
      // A shell older than the space's environment lacks its variables.
      return Column(
        children: [
          if (tab.args[kEnvironmentStartTerminalTabArg] == true)
            EnvironmentStartTerminalBanner(
              workspaceId: claimed.session.workspaceId,
              spaceId: claimed.session.spaceId,
              sessionId: claimed.session.attachSessionId,
            ),
          EnvironmentTerminalBanner(
            workspaceId: claimed.session.workspaceId,
            spaceId: claimed.session.spaceId,
            startedAt: claimed.startedAt,
            onOpenFresh: onOpenFresh,
          ),
          Expanded(child: view),
        ],
      );
    }
    if (awaitsStart) {
      return EnclosedTerminalStart(onStart: onStart);
    }
    return const Center(child: CcSpinner());
  }
}
