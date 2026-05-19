// The windowing widgets (RegularWindow / RegularWindowController) live in
// Flutter's experimental, @internal windowing library. They are unlocked at
// runtime by building with `--dart-define=FLUTTER_ENABLED_FEATURE_FLAGS=windowing`
// (see ENABLE the flag in the run/build commands). This is the one place that
// reaches into the internal API; keep it contained here.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show AppExitType;

import 'package:control_center/app/control_center_app.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/features/focus_mode/presentation/screens/focus_pill_window.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_toolbar_controller.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_toolbar_window.dart';
import 'package:flutter/src/widgets/_window.dart'
    show
        RegularWindow,
        RegularWindowController,
        RegularWindowControllerDelegate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryWidget;

/// Delegate that quits the whole application when its window is closed, instead
/// of just destroying the window.
///
/// The primary window (and the pre-app setup window) *are* the app: closing
/// either should terminate the process. With Flutter's native windowing the
/// runner is headless — a single `FlutterEngine` with no `MainFlutterWindow` —
/// so the default close behaviour (destroy the window, leave the engine
/// running) leaves a live engine with zero windows. On macOS that engine keeps
/// vsyncing against a surface that no longer exists, spamming
/// "Reported frame time is older than the last one; clamping" forever, and the
/// spawned `cc_server` orphans because the app never exits (its
/// `AppLifecycleListener.onExitRequested` teardown never fires).
///
/// Routing through [WidgetsBinding.exitApplication] (rather than destroying the
/// window) goes via the platform's app-exit path, which invokes
/// `onExitRequested` so the spawned server is stopped cleanly first. The
/// app-initiated exit also sidesteps the runner's
/// `applicationShouldTerminateAfterLastWindowClosed`, which is deliberately
/// `false` in DEBUG to keep hot restart alive. This hook never fires during a
/// hot restart: a restart tears the window down by unmounting the widget
/// (`State.dispose` → `controller.destroy()`), not through a user close
/// request, so hot restart keeps working.
class _QuitOnCloseDelegate extends RegularWindowControllerDelegate {
  @override
  void onWindowCloseRequested(RegularWindowController controller) {
    // `cancelable` so any `onExitRequested` handler (stops the spawned server)
    // runs and can veto; in this app it always approves, so the process exits.
    WidgetsBinding.instance.exitApplication(AppExitType.cancelable);
  }
}

/// Root of the application's native multi-window tree.
///
/// Each entry is a [RegularWindow] backed by its own platform window in this
/// single Dart isolate. The primary window is always present; the two floating
/// HUDs are added/removed reactively as their owning providers flip — adding a
/// window creates it, removing it destroys it. Because everything shares one
/// isolate and [ProviderContainer], the HUDs read Riverpod state directly with
/// no cross-engine IPC.
class AppWindows extends ConsumerWidget {
  /// Creates the [AppWindows] root.
  const AppWindows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusCompact = ref.watch(
      focusModeProvider.select((s) => s.compactMode),
    );
    final toolbarOpen = ref.watch(meetingToolbarControllerProvider);
    return ViewCollection(
      views: [
        const PrimaryWindow(),
        if (focusCompact) const FocusPillWindow(),
        if (toolbarOpen) const MeetingToolbarWindow(),
      ],
    );
  }
}

/// The main application window. Owns the regular window controller and renders
/// [ControlCenterApp] into it (wrapped in [SentryWidget] when crash reporting
/// is active).
class PrimaryWindow extends StatefulWidget {
  /// Creates the [PrimaryWindow].
  const PrimaryWindow({super.key});

  @override
  State<PrimaryWindow> createState() => _PrimaryWindowState();
}

class _PrimaryWindowState extends State<PrimaryWindow> {
  final RegularWindowController _controller = RegularWindowController(
    preferredSize: const Size(1440, 900),
    preferredConstraints: const BoxConstraints(minWidth: 1024, minHeight: 600),
    title: primaryWindowTitle,
    // Closing the main window quits the app (and stops the spawned server)
    // rather than leaving a headless engine running with no windows.
    delegate: _QuitOnCloseDelegate(),
  );

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RegularWindow(
      controller: _controller,
      child: sentryReportingActive
          ? SentryWidget(child: const ControlCenterApp())
          : const ControlCenterApp(),
    );
  }
}

/// Title of the transient pre-app server-setup window. Intentionally DISTINCT
/// from [primaryWindowTitle] so the window-chrome hooks keyed on title
/// (`styleWindowOnShow` / `persistWindowGeometry`) do not treat it as the
/// primary window: it must not inherit the hidden-title-bar / transparent chrome
/// (it needs an ordinary movable frame), and — critically — its geometry must
/// never be persisted over the real primary window's saved size/position.
const String _serverSetupWindowTitle = 'Control Center setup';

/// Renders [app] in a standalone native window for the pre-app server-setup
/// screen, shown before the main [AppWindows] tree exists (the desktop has no
/// server connection yet, so the full app cannot boot).
///
/// Must go through a [RegularWindow], exactly like [PrimaryWindow]: the macOS
/// runner is headless (no `MainFlutterWindow`), so a plain `runApp` into the
/// implicit view paints onto a surface that is never presented and the screen
/// never appears. Once the user resolves the setup, the bootstrap runs
/// `runWidget` again with the main [AppWindows] tree, which replaces this
/// window.
void runServerSetupWindow(Widget app) {
  runWidget(ViewCollection(views: [_ServerSetupWindow(app: app)]));
}

/// The single [RegularWindow] hosting the pre-app server-setup [app].
class _ServerSetupWindow extends StatefulWidget {
  const _ServerSetupWindow({required this.app});

  final Widget app;

  @override
  State<_ServerSetupWindow> createState() => _ServerSetupWindowState();
}

class _ServerSetupWindowState extends State<_ServerSetupWindow> {
  final RegularWindowController _controller = RegularWindowController(
    preferredSize: const Size(600, 720),
    preferredConstraints: const BoxConstraints(minWidth: 460, minHeight: 520),
    title: _serverSetupWindowTitle,
    // Closing the pre-app setup window (before any main window exists) quits the
    // app rather than orphaning a headless engine with no windows.
    delegate: _QuitOnCloseDelegate(),
  );

  @override
  void dispose() {
    // This State is unmounted as the root view swaps from the server-setup
    // window to the main app, so `dispose()` runs while the widget tree is
    // locked (inside the build/finalize phase). Destroying the native window
    // synchronously here makes `RegularWindowController.destroy()` schedule
    // focus teardown that trips "applyFocusChangesIfNeeded() should not be
    // called during the build phase". Defer the destroy to after the frame,
    // when the tree is unlocked and focus can be applied safely.
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RegularWindow(controller: _controller, child: widget.app);
}
