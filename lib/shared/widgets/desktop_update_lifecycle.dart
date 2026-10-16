import 'package:control_center/core/update/desktop_update_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps automatic desktop updates independent of login and shell routes.
///
/// Draws no controls. The surrounding provider scope owns the schedule and
/// releases its timers and native callbacks when the session is disposed.
class DesktopUpdateLifecycle extends ConsumerStatefulWidget {
  /// Starts background checks after the first frame without delaying startup.
  const DesktopUpdateLifecycle({
    required this.child,
    this.busyProbe,
    super.key,
  });

  /// The app or pre-connection setup surface.
  final Widget child;

  /// Whether an update prompt would interrupt work, such as a recording.
  final bool Function()? busyProbe;

  @override
  ConsumerState<DesktopUpdateLifecycle> createState() =>
      _DesktopUpdateLifecycleState();
}

class _DesktopUpdateLifecycleState
    extends ConsumerState<DesktopUpdateLifecycle> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(desktopUpdateProvider.notifier)
            .start(
              busyProbe: () => mounted && (widget.busyProbe?.call() ?? false),
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
