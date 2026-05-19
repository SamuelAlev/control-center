import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_first_run_note.dart';
import 'package:control_center/features/demo/presentation/widgets/demo_tour_panel.dart';
import 'package:control_center/features/demo/providers/demo_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The demo's shell-level surfaces: the first-run note, then the guided tour.
///
/// Mounted once in `ControlCenterLayout` and positioned like the banner rail,
/// so it follows the visitor across every route instead of belonging to one
/// screen. Against a real server this is two boolean reads and a
/// `SizedBox.shrink`, which is why it can sit in the shell unconditionally.
///
/// The note comes first and the tour only appears once it is dismissed: two
/// stacked panels on a visitor's very first frame is a wall, not a welcome.
class DemoShellOverlay extends ConsumerWidget {
  /// Creates the overlay.
  const DemoShellOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isDemoServerProvider)) {
      return const SizedBox.shrink();
    }
    final dismissals = ref.watch(demoShellDismissalsProvider);
    final noteDone = dismissals.contains(kDemoFirstRunNoteId);
    final tourDone = dismissals.contains(kDemoTourId);
    if (noteDone && tourDone) {
      return const SizedBox.shrink();
    }

    // The tour deep-links into workspace-prefixed routes, so it needs the
    // active workspace. Before one is resolved (splash, the picker) there is
    // nothing to link to and nothing to show.
    final workspaceId = context.currentWorkspaceId;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!noteDone)
                  const DemoFirstRunNote()
                else if (workspaceId != null && workspaceId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: DemoTourPanel(workspaceId: workspaceId),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
