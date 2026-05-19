// The windowing widgets (Window / WindowController) live in
// Flutter's experimental, @internal windowing library. They are unlocked at
// runtime by building with `--dart-define=FLUTTER_ENABLED_FEATURE_FLAGS=windowing`
// (see ENABLE the flag in the run/build commands). This is the one place that
// reaches into the internal API; keep it contained here.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui' show AppExitType;

import 'package:control_center/app/control_center_app.dart';
import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/app/window_placement.dart';
import 'package:control_center/core/observability/sentry_bootstrap.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/focus_mode/presentation/screens/focus_pill_window.dart';
import 'package:control_center/features/focus_mode/providers/focus_mode_providers.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_toolbar_controller.dart';
import 'package:control_center/features/meetings/presentation/screens/meeting_toolbar_window.dart';
import 'package:control_center/features/soundscape/presentation/notifiers/soundscape_mini_player_controller.dart';
import 'package:control_center/features/soundscape/presentation/screens/soundscape_mini_player_window.dart';
import 'package:control_center/shared/widgets/foreground_ticker_gate.dart';
import 'package:flutter/src/widgets/_window.dart'
    show Window, WindowController, WindowControllerDelegate;
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
/// "Reported frame time is older than the last one; clamping" forever and the
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
class _QuitOnCloseDelegate extends WindowControllerDelegate {
  @override
  void onWindowCloseRequested(WindowController controller) {
    // `cancelable` so any `onExitRequested` handler (stops the spawned server)
    // runs and can veto; in this app it always approves, so the process exits.
    WidgetsBinding.instance.exitApplication(AppExitType.cancelable);
  }
}

/// Root of the application's native multi-window tree.
///
/// Each entry is a [Window] backed by its own platform window in this
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
    final soundscapeOpen = ref.watch(soundscapeMiniPlayerControllerProvider);
    return ViewCollection(
      views: [
        const PrimaryWindow(),
        if (focusCompact) const FocusPillWindow(),
        if (toolbarOpen) const MeetingToolbarWindow(),
        if (soundscapeOpen) const SoundscapeMiniPlayerWindow(),
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
  final WindowController _controller = WindowController(
    // Shared with the restore path so the size the window is CREATED at and
    // the size it falls back to when there is nothing saved cannot drift
    // apart. Both are clamped to the display before the window is shown (see
    // `styleWindowOnShow`), so a laptop smaller than this never opens a window
    // taller than its screen.
    size: defaultMainWindowSize,
    constraints: BoxConstraints(
      minWidth: mainWindowMinSize.width,
      minHeight: mainWindowMinSize.height,
    ),
    title: primaryWindowTitle,
    // Closing the main window quits the app (and stops the spawned server)
    // rather than leaving a headless engine running with no windows.
    delegate: _QuitOnCloseDelegate(),
  );

  @override
  void initState() {
    super.initState();
    // The controller's field initializer above has already created AND shown
    // the native window (synchronously, during this State's construction), so
    // by initState the window exists with a black content layer and is waiting
    // for its first present. The post-frame log below then tells us whether
    // the frame that should carry that present completed — a window that is
    // still black after it logs is losing presents engine-side (see
    // `WindowVisibilityGuard`, which nudges a freshly shown main window for
    // exactly this reason).
    AppLog.i('window', 'primary window: controller created, awaiting frames');
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AppLog.i('window', 'primary window: first frame completed'),
    );
  }

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Window(
      controller: _controller,
      // Mute every ticker in the main window while the app is backgrounded:
      // frames scheduled into an unpresentable macOS surface accumulate native
      // GPU memory (the idle 60GB leak). The always-on-top HUD windows stay
      // ungated — they are meant to be watched while the operator is in
      // another app.
      child: ForegroundTickerGate(
        child: sentryReportingActive
            ? SentryWidget(child: const ControlCenterApp())
            : const ControlCenterApp(),
      ),
    );
  }
}

/// Renders [app] in a standalone native window for the pre-app server-setup
/// screen, shown before the main [AppWindows] tree exists (the desktop has no
/// server connection yet, so the full app cannot boot).
///
/// Must go through a [Window], exactly like [PrimaryWindow]: the macOS
/// runner is headless (no `MainFlutterWindow`), so a plain `runApp` into the
/// implicit view paints onto a surface that is never presented and the screen
/// never appears. Once the user resolves the setup, the bootstrap runs
/// `runWidget` again with the main [AppWindows] tree, which replaces this
/// window.
void runServerSetupWindow(Widget app) {
  runWidget(ViewCollection(views: [_ServerSetupWindow(app: app)]));
}

/// Shows [error] in a native window when the desktop bootstrap threw before it
/// could put ANY window on screen.
///
/// Everything the desktop does before `runWidget` — preferences, the keychain,
/// resolving/spawning `cc_server` — happens while the app owns no window. A
/// throw there used to be completely silent: `PlatformDispatcher.onError`
/// logged it to a terminal nobody is looking at, the engine kept its run loop
/// alive, and the operator was left with a process that is "running" and a
/// screen with nothing on it. `ErrorWidget.builder` cannot help — it only
/// replaces a widget inside a tree that was already mounted.
///
/// So the bootstrap's last act on failure is to become a window that says what
/// broke. Deliberately dependency-light (no Riverpod, no theme, no l10n, no
/// server): whatever failed may be exactly the thing those would need.
void runBootFailureWindow(Object error, StackTrace stack) {
  runWidget(
    ViewCollection(views: [_BootFailureWindow(error: error, stack: stack)]),
  );
}

class _BootFailureWindow extends StatefulWidget {
  const _BootFailureWindow({required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  State<_BootFailureWindow> createState() => _BootFailureWindowState();
}

class _BootFailureWindowState extends State<_BootFailureWindow> {
  final WindowController _controller = WindowController(
    size: const Size(620, 420),
    constraints: const BoxConstraints(minWidth: 420, minHeight: 300),
    title: bootFailureWindowTitle,
    delegate: _QuitOnCloseDelegate(),
  );

  @override
  void dispose() {
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hardcoded colors, matching the `ErrorWidget.builder` fallback in the
    // bootstrap: a failure this early must not depend on the design tokens or
    // the font settings, which are themselves loaded during boot.
    const background = Color(0xFFFCFBF9);
    const danger = Color(0xFFDC2626);
    const muted = Color(0xFF3D3D3D);
    return Window(
      controller: _controller,
      child: WidgetsApp(
        color: background,
        debugShowCheckedModeBanner: false,
        builder: (context, _) => Container(
          color: background,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Control Center could not start',
                style: TextStyle(
                  color: danger,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '${widget.error}\n\n${widget.stack}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single [Window] hosting the pre-app server-setup [app].
class _ServerSetupWindow extends StatefulWidget {
  const _ServerSetupWindow({required this.app});

  final Widget app;

  @override
  State<_ServerSetupWindow> createState() => _ServerSetupWindowState();
}

class _ServerSetupWindowState extends State<_ServerSetupWindow> {
  final WindowController _controller = WindowController(
    size: const Size(600, 720),
    constraints: const BoxConstraints(minWidth: 460, minHeight: 520),
    title: serverSetupWindowTitle,
    // Closing the pre-app setup window (before any main window exists) quits the
    // app rather than orphaning a headless engine with no windows.
    delegate: _QuitOnCloseDelegate(),
  );

  @override
  void dispose() {
    // This State is unmounted as the root view swaps from the server-setup
    // window to the main app, so `dispose()` runs while the widget tree is
    // locked (inside the build/finalize phase). Destroying the native window
    // synchronously here makes `WindowController.destroy()` schedule
    // focus teardown that trips "applyFocusChangesIfNeeded() should not be
    // called during the build phase". Defer the destroy to after the frame,
    // when the tree is unlocked and focus can be applied safely.
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.destroy());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Window(controller: _controller, child: widget.app);
}
