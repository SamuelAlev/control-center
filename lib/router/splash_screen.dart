import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/window_drag_area.dart';
import 'package:flutter/material.dart';

/// Neutral loading screen shown while the router waits for the onboarding
/// gate to resolve. Avoids flashing the onboarding flow when the user has
/// already completed it.
///
/// Draggable in full, for the same reason `OnboardingScaffold` is: the primary
/// window is not system-movable and the app's own title bar lives inside the
/// shell, which this screen renders outside of. The wait here is not always
/// brief — a cold start waits on the local server's ready banner — so a window
/// pinned where it happens to be is a real cost.
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return WindowDragArea(
      moveWindowManually: true,
      child: Scaffold(
        backgroundColor: ds.bgPrimary,
        body: const Center(child: CcSpinner()),
      ),
    );
  }
}
